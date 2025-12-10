import 'dart:math';

import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:flame/particles.dart';
import 'package:flutter/material.dart';

import '../constants/game_constants.dart';
import '../game/fox_machine_game.dart';
import '../models/game_state.dart';

enum CollectibleType { mushroom }

class Collectible extends PositionComponent
    with CollisionCallbacks, HasGameReference<FoxMachineGame> {
  final CollectibleType type = CollectibleType.mushroom;
  late ShapeComponent shape;
  bool isCollected = false;
  final double groundLevel;

  // Track height offset from ground level
  final double _heightOffset;

  // Unique random values for less predictable movement
  final double _uniquePhaseOffset;
  final double _uniqueFrequencyOffset;
  final double _uniqueAmplitudeOffset;

  // Time-based oscillation value
  double _oscillationTime = 0;

  // Visibility control variables
  final bool _enableVisibilityEffects = GameConstants
      .enableCollectibleVisibilityEffects; // Based on game settings
  double _visibilityValue = 1.0; // 0.0 is invisible, 1.0 is fully visible
  double _visibilityChangeTimer = 0.0;
  final double _visibilityChangeInterval; // Time between visibility changes
  final bool _usesFadingEffect; // Whether this collectible fades or blinks

  Collectible({required this.groundLevel})
      : _heightOffset = 150.0 + Random().nextDouble() * 150.0,
        _uniquePhaseOffset = Random().nextDouble() * 2 * pi,
        _uniqueFrequencyOffset = 0.7 + Random().nextDouble() * 0.6, // 0.7-1.3
        _uniqueAmplitudeOffset = 0.8 + Random().nextDouble() * 0.4, // 0.8-1.2
        _visibilityChangeInterval = 1.0 + Random().nextDouble() * 1.5,
        _usesFadingEffect = Random().nextBool(),
        super(size: Vector2(30, 30));

  // Update visibility effect
  void _updateVisibility(double dt) {
    if (!_enableVisibilityEffects) {
      _visibilityValue = 1.0; // Always fully visible if effects disabled
      return;
    }

    _visibilityChangeTimer += dt;

    // Crystals (mushrooms) can become completely invisible briefly
    if (_usesFadingEffect) {
      // Complex fading pattern
      double fadeBase = 0.5 + (sin(_oscillationTime * 2.0) * 0.5);
      double fadeVariation = (cos(_oscillationTime * 3.5) * 0.3);
      _visibilityValue = (fadeBase + fadeVariation).clamp(0.0, 1.0);
    } else if (_visibilityChangeTimer >= _visibilityChangeInterval) {
      // Or can blink in and out
      _visibilityChangeTimer = 0;
      // Mushrooms can become completely invisible (0.0) or fully visible (1.0)
      _visibilityValue = Random().nextDouble() < 0.4 ? 0.0 : 1.0;
    }

    // Apply visibility to the shape
    shape.paint.color =
        shape.paint.color.withAlpha((_visibilityValue * 255).toInt());
  }

  static Collectible random({required double groundLevel}) {
    // Only one type now
    return Collectible(groundLevel: groundLevel);
  }

  @override
  Future<void> onLoad() async {
    // Position at the right edge of the screen with randomized horizontal offset
    double horizontalOffset = Random().nextDouble() * 300;

    position = Vector2(
      FoxMachineGame.designResolutionWidth + size.x + horizontalOffset,
      groundLevel - _heightOffset, // Float above ground level
    );

    // Keep mushrooms very high
    position.y -= 120.0;
    position.x += 200.0 + Random().nextDouble() * 150;

    // Set anchor to center
    anchor = Anchor.center;

    // Add a simple circular hitbox - make hitboxes slightly smaller
    add(CircleHitbox(
      radius: 10,
    )..debugMode = GameConstants.debug);

    // Create mushroom shape
    Paint paint = Paint()..color = Colors.purple;
    shape = RectangleComponent(
      size: Vector2(25, 25),
      paint: paint,
    );

    add(shape);

    // Apply initial visibility effect if enabled
    if (_enableVisibilityEffects) {
      // Start with full visibility
      _visibilityValue = 1.0;
      shape.paint.color = shape.paint.color.withOpacity(_visibilityValue);
    }

    return super.onLoad();
  }

  @override
  void update(double dt) {
    super.update(dt);

    if (game.gameState != GameState.playing || isCollected) return;

    // Update oscillation time - used for complex movement patterns
    _oscillationTime += dt;

    // Update visibility effects
    _updateVisibility(dt);

    // Move collectible towards player
    double moveSpeed = game.gameSpeed * game.speedMultiplier;

    // Mushroom moves faster
    moveSpeed *= 1.8;

    // Base horizontal movement with slight random variation
    double speedVariation =
        1.0 + (sin(_oscillationTime * 2) * 0.1); // ±10% speed variation
    position.x -= moveSpeed * dt * speedVariation;

    // Update y-position to follow the dynamic ground level while maintaining height offset
    double yPos = game.getGroundLevelAt(position.x) - _heightOffset;

    // Additional height
    yPos -= 120.0; // Keep mushrooms very high

    position.y = yPos;

    // Extremely complex and unpredictable movement for mushrooms

    // Vertical movement: multiple frequencies and amplitudes
    double mushFloat1 = sin((_oscillationTime * 3.2 * _uniqueFrequencyOffset) +
            _uniquePhaseOffset) *
        22 *
        _uniqueAmplitudeOffset;
    double mushFloat2 =
        cos((_oscillationTime * 1.9) + _uniquePhaseOffset * 1.5) * 18;
    double mushFloat3 =
        sin((_oscillationTime * 4.7) + _uniquePhaseOffset * 0.7) * 10;
    position.y += mushFloat1 + mushFloat2 + mushFloat3;

    // Horizontal zigzag: changes direction suddenly
    double zigzagPeriod = 1.0; // seconds per zigzag
    double zigzagPhase = (_oscillationTime % zigzagPeriod) / zigzagPeriod;

    // Triangular wave pattern for horizontal movement
    double triangleWave = 0;
    if (zigzagPhase < 0.5) {
      triangleWave = zigzagPhase * 2; // 0 to 1
    } else {
      triangleWave = 2 - zigzagPhase * 2; // 1 to 0
    }

    // Apply horizontal zigzag with variable amplitude
    position.x += (triangleWave * 2 - 1) * 5 * _uniqueAmplitudeOffset;

    // Random teleport-like movements occasionally (rare but surprising)
    if (_oscillationTime % 5 < 0.05) {
      // 5% of the time
      // Small random jumps in position
      position.y += (Random().nextDouble() * 30 - 15);
      position.x += (Random().nextDouble() * 20 - 10);
    }

    // Remove if off screen
    if (position.x < -size.x) {
      removeFromParent();
    }
  }

  void collect() {
    if (isCollected) return;

    isCollected = true;

    // Make fully visible when collected (for particle effects)
    _visibilityValue = 1.0;
    shape.paint.color = shape.paint.color.withAlpha(255);

    // Award points
    game.score += 50;
    // Add mushroom collection particle effect
    _addCollectionParticles(Colors.purple);

    // Simple visual effect - shrink shape
    shape.scale = Vector2.all(0.5);

    // Remove after brief animation
    Future.delayed(const Duration(milliseconds: 200), () {
      removeFromParent();
    });
  }

  // Helper method to add particle effects on collection
  void _addCollectionParticles(Color color) {
    final random = Random();
    const particleCount = 20;

    // Create particle component
    final particleComponent = ParticleSystemComponent(
      particle: Particle.generate(
        count: particleCount,
        lifespan: 0.5,
        generator: (i) {
          final speed = random.nextDouble() * 100 + 50;
          final angle = random.nextDouble() * 2 * pi;
          final offset = Vector2(cos(angle), sin(angle)) * speed;

          return AcceleratedParticle(
            acceleration: Vector2(0, 200),
            speed: offset,
            position: Vector2.zero(),
            child: ComputedParticle(
              renderer: (canvas, particle) {
                final paint = Paint()
                  ..color = color.withOpacity(
                      (1 - particle.progress) * random.nextDouble() * 0.5 + 0.5)
                  ..style = PaintingStyle.fill;

                final size =
                    (1 - particle.progress) * random.nextDouble() * 5 + 2;
                canvas.drawCircle(
                  Offset.zero,
                  size,
                  paint,
                );
              },
            ),
          );
        },
      ),
    );

    // Position the particle system at the collectible's position
    particleComponent.position = position.clone();

    // Add the particle system to the game world
    game.gameWorld.add(particleComponent);

    // Remove the particle system after it completes
    Future.delayed(const Duration(milliseconds: 800), () {
      if (particleComponent.isMounted) {
        particleComponent.removeFromParent();
      }
    });
  }
}
