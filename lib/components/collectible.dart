import 'dart:math';
import 'package:flame/components.dart';
import 'package:flame/collisions.dart';
import 'package:flame/particles.dart';
import 'package:flutter/material.dart';

import '../game/fox_machine_game.dart';
import '../constants/game_constants.dart';
import '../models/game_state.dart';

enum CollectibleType { berry, mushroom, egg }

class Collectible extends PositionComponent
    with CollisionCallbacks, HasGameRef<FoxMachineGame> {
  final CollectibleType type;
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
  bool _enableVisibilityEffects = GameConstants
      .enableCollectibleVisibilityEffects; // Based on game settings
  double _visibilityValue = 1.0; // 0.0 is invisible, 1.0 is fully visible
  double _visibilityChangeTimer = 0.0;
  final double _visibilityChangeInterval; // Time between visibility changes
  final bool _usesFadingEffect; // Whether this collectible fades or blinks

  // TODO: Replace shape component with Rive animations
  // Example:
  // late RiveComponent animation;

  Collectible({required this.type, required this.groundLevel})
      : _heightOffset = _generateHeightOffset(type),
        _uniquePhaseOffset = Random().nextDouble() * 2 * pi,
        _uniqueFrequencyOffset = 0.7 + Random().nextDouble() * 0.6, // 0.7-1.3
        _uniqueAmplitudeOffset = 0.8 + Random().nextDouble() * 0.4, // 0.8-1.2
        _visibilityChangeInterval = _generateVisibilityInterval(type),
        _usesFadingEffect = Random().nextBool(),
        super(size: Vector2(30, 30));

  // Generate a visibility change interval based on collectible type
  static double _generateVisibilityInterval(CollectibleType type) {
    final random = Random();

    // Base timing varies by type
    switch (type) {
      case CollectibleType.berry:
        // Berries rarely change visibility - easier to see
        return 3.0 + random.nextDouble() * 3.0; // 3-6 seconds
      case CollectibleType.egg:
        // Eggs change visibility moderately
        return 2.0 + random.nextDouble() * 2.0; // 2-4 seconds
      case CollectibleType.mushroom:
        // Crystals (mushrooms) change visibility frequently - harder to track
        return 1.0 + random.nextDouble() * 1.5; // 1-2.5 seconds
    }
  }

  // Update visibility effect
  void _updateVisibility(double dt) {
    if (!_enableVisibilityEffects) {
      _visibilityValue = 1.0; // Always fully visible if effects disabled
      return;
    }

    _visibilityChangeTimer += dt;

    // Different visibility behaviors by type
    switch (type) {
      case CollectibleType.berry:
        // Berries just slightly fade (never completely invisible)
        if (_visibilityChangeTimer >= _visibilityChangeInterval) {
          _visibilityChangeTimer = 0;
          // Berries only fade to 60% opacity minimum
          _visibilityValue = 0.6 + Random().nextDouble() * 0.4; // 0.6-1.0
        }
        break;

      case CollectibleType.egg:
        // Eggs fade in and out moderately
        if (_usesFadingEffect) {
          // Gradual fading
          _visibilityValue = 0.3 + (sin(_oscillationTime * 1.2) * 0.7).abs();
        } else if (_visibilityChangeTimer >= _visibilityChangeInterval) {
          // Or discrete changes
          _visibilityChangeTimer = 0;
          // Eggs can go down to 30% opacity
          _visibilityValue = 0.3 + Random().nextDouble() * 0.7; // 0.3-1.0
        }
        break;

      case CollectibleType.mushroom:
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
        break;
    }

    // Apply visibility to the shape
    shape.paint.color = shape.paint.color.withOpacity(_visibilityValue);
  }

  // Generate a random height offset based on collectible type
  static double _generateHeightOffset(CollectibleType type) {
    final random = Random();

    // Base height varies by type
    double baseHeight;
    double variationRange;

    switch (type) {
      case CollectibleType.berry:
        baseHeight = 70.0;
        variationRange = 100.0;
        break;
      case CollectibleType.egg:
        baseHeight = 100.0;
        variationRange = 120.0;
        break;
      case CollectibleType.mushroom:
        baseHeight = 150.0;
        variationRange = 150.0;
        break;
    }

    // Even more variation in heights
    return baseHeight + random.nextDouble() * variationRange;
  }

  static Collectible random({required double groundLevel}) {
    final random = Random();

    // Make collectibles even rarer
    final randomValue = random.nextDouble();

    CollectibleType randomType;
    if (randomValue < 0.90) {
      randomType = CollectibleType.berry;
    } else if (randomValue < 0.98) {
      randomType = CollectibleType.egg;
    } else {
      // Only 2% chance to get a mushroom (previously 5%)
      randomType = CollectibleType.mushroom;
    }

    return Collectible(type: randomType, groundLevel: groundLevel);
  }

  @override
  Future<void> onLoad() async {
    // Position at the right edge of the screen with randomized horizontal offset
    double horizontalOffset = 0;

    // Add random horizontal offset for all types
    horizontalOffset = Random().nextDouble() * 300;

    position = Vector2(
      FoxMachineGame.designResolutionWidth + size.x + horizontalOffset,
      groundLevel - _heightOffset, // Float above ground level
    );

    // If it's a mushroom, place it even higher and further away
    if (type == CollectibleType.mushroom) {
      position.y -= 120.0; // Even higher base height
      position.x +=
          200.0 + Random().nextDouble() * 150; // Much further to the right
    } else if (type == CollectibleType.egg) {
      // Eggs also placed a bit higher
      position.y -=
          40.0 + Random().nextDouble() * 60; // Variable additional height
    }

    // Set anchor to center
    anchor = Anchor.center;

    // Add a simple circular hitbox - make hitboxes slightly smaller
    add(CircleHitbox(
      radius: type == CollectibleType.mushroom
          ? 10 // Even smaller for mushrooms!
          : 13, // Smaller hitbox = harder to collect
    )..debugMode = GameConstants.debug);

    // Create different shapes based on collectible type (placeholders)
    Paint paint;
    switch (type) {
      case CollectibleType.berry:
        paint = Paint()..color = Colors.red;
        shape = CircleComponent(
          radius: 15,
          paint: paint,
        );
        break;
      case CollectibleType.mushroom:
        paint = Paint()..color = Colors.purple;
        shape = RectangleComponent(
          size: Vector2(25, 25),
          paint: paint,
        );
        break;
      case CollectibleType.egg:
        paint = Paint()..color = Colors.yellow;
        shape = PolygonComponent(
          [
            Vector2(0, -15),
            Vector2(15, 15),
            Vector2(-15, 15),
          ],
          paint: paint,
        );
        break;
    }

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

    if (gameRef.gameState != GameState.playing || isCollected) return;

    // Update oscillation time - used for complex movement patterns
    _oscillationTime += dt;

    // Update visibility effects
    _updateVisibility(dt);

    // Move collectible towards player
    double moveSpeed = gameRef.gameSpeed * gameRef.speedMultiplier;

    // Make collectibles move faster based on type
    switch (type) {
      case CollectibleType.berry:
        moveSpeed *= 1.1; // 10% faster
        break;
      case CollectibleType.egg:
        moveSpeed *= 1.3; // 30% faster (previously 20%)
        break;
      case CollectibleType.mushroom:
        moveSpeed *= 1.8; // 80% faster (previously 50%)
        break;
    }

    // Base horizontal movement with slight random variation
    double speedVariation =
        1.0 + (sin(_oscillationTime * 2) * 0.1); // ±10% speed variation
    position.x -= moveSpeed * dt * speedVariation;

    // Update y-position to follow the dynamic ground level while maintaining height offset
    double yPos = gameRef.getGroundLevelAt(position.x) - _heightOffset;

    // Additional height for special collectibles
    if (type == CollectibleType.mushroom) {
      yPos -= 120.0; // Keep mushrooms very high
    } else if (type == CollectibleType.egg) {
      yPos -= 40.0; // Keep eggs moderately high
    }

    position.y = yPos;

    // Apply unique movement patterns based on collectible type
    if (type == CollectibleType.berry) {
      // Simple wavy pattern for berries with unique values
      double berryFloat = sin((_oscillationTime * 3 * _uniqueFrequencyOffset) +
              _uniquePhaseOffset) *
          10 *
          _uniqueAmplitudeOffset;
      position.y += berryFloat;

      // Occasional small horizontal jitter
      if (_oscillationTime % 2 < 0.1) {
        position.x += sin(_oscillationTime * 20) * 1.5;
      }
    } else if (type == CollectibleType.egg) {
      // More complex pattern for eggs
      // Combine two sine waves with different frequencies and random offsets
      double eggFloat1 = sin((_oscillationTime * 2.5 * _uniqueFrequencyOffset) +
              _uniquePhaseOffset) *
          12 *
          _uniqueAmplitudeOffset;
      double eggFloat2 =
          cos((_oscillationTime * 1.7) + _uniquePhaseOffset * 2) * 8;
      position.y += eggFloat1 + eggFloat2;

      // Add some horizontal movement - lissajous-like pattern
      position.x += sin(_oscillationTime * 1.3 + _uniquePhaseOffset) * 2.5;
    } else if (type == CollectibleType.mushroom) {
      // Extremely complex and unpredictable movement for mushrooms

      // Vertical movement: multiple frequencies and amplitudes
      double mushFloat1 = sin(
              (_oscillationTime * 3.2 * _uniqueFrequencyOffset) +
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
    shape.paint.color = shape.paint.color.withOpacity(1.0);

    // Award points based on type
    switch (type) {
      case CollectibleType.berry:
        gameRef.score += 10;
        // Add berry collection particle effect
        _addCollectionParticles(Colors.red);
        break;
      case CollectibleType.mushroom:
        gameRef.score += 50;
        // Add mushroom collection particle effect
        _addCollectionParticles(Colors.purple);
        break;
      case CollectibleType.egg:
        gameRef.score += 100;
        // Add egg collection particle effect
        _addCollectionParticles(Colors.yellow);
        break;
    }

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
    final particleCount = 20;

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
    gameRef.gameWorld.add(particleComponent);

    // Remove the particle system after it completes
    Future.delayed(const Duration(milliseconds: 800), () {
      if (particleComponent.isMounted) {
        particleComponent.removeFromParent();
      }
    });
  }
}
