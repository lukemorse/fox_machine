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

  // TODO: Replace shape component with Rive animations
  // Example:
  // late RiveComponent animation;

  Collectible({required this.type, required this.groundLevel})
      : _heightOffset = _generateHeightOffset(),
        super(size: Vector2(30, 30));

  // Generate a random height offset based on collectible type
  static double _generateHeightOffset() {
    final random = Random();

    // Generate a random height based on a normal-like distribution
    // centered about 100px above ground
    return 50.0 + random.nextDouble() * 100.0;
  }

  static Collectible random({required double groundLevel}) {
    final random = Random();

    // Weight the probability to have more berries than crystals or special items
    final randomValue = random.nextDouble();

    CollectibleType randomType;
    if (randomValue < 0.7) {
      randomType = CollectibleType.berry;
    } else if (randomValue < 0.9) {
      randomType = CollectibleType.mushroom;
    } else {
      randomType = CollectibleType.egg;
    }

    return Collectible(type: randomType, groundLevel: groundLevel);
  }

  @override
  Future<void> onLoad() async {
    // Position at the right edge of the screen
    position = Vector2(
      FoxMachineGame.designResolutionWidth + size.x,
      groundLevel - _heightOffset, // Float above ground level
    );

    // Set anchor to center
    anchor = Anchor.center;

    // Add a simple circular hitbox
    add(CircleHitbox(
      radius: 15, // Fixed size (half the component size)
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
        // TODO: Load berry animation from Rive
        // Example:
        // animation = await RiveComponent.load(
        //   'assets/animations/collectibles.riv',
        //   artboard: 'Berry',
        //   stateMachines: ['Idle'],
        //   size: Vector2(30, 30),
        // );
        break;
      case CollectibleType.mushroom:
        paint = Paint()..color = Colors.purple;
        shape = RectangleComponent(
          size: Vector2(25, 25),
          paint: paint,
        );
        // TODO: Load mushroom animation from Rive
        // Example:
        // animation = await RiveComponent.load(
        //   'assets/animations/collectibles.riv',
        //   artboard: 'Mushroom',
        //   stateMachines: ['Glowing'],
        //   size: Vector2(30, 30),
        // );
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
        // TODO: Load egg animation from Rive
        // Example:
        // animation = await RiveComponent.load(
        //   'assets/animations/collectibles.riv',
        //   artboard: 'Egg',
        //   stateMachines: ['Spinning'],
        //   size: Vector2(30, 30),
        // );
        break;
    }

    add(shape);

    return super.onLoad();
  }

  @override
  void update(double dt) {
    super.update(dt);

    if (gameRef.gameState != GameState.playing || isCollected) return;

    // Move collectible towards player
    position.x -= gameRef.gameSpeed * gameRef.speedMultiplier * dt;

    // Update y-position to follow the dynamic ground level while maintaining height offset
    position.y = gameRef.getGroundLevelAt(position.x) - _heightOffset;

    // Add a gentle floating animation for visual appeal
    final floatOffset =
        sin(gameRef.distanceTraveled / 100 + position.x / 50) * 5;
    position.y += floatOffset;

    // Remove if off screen
    if (position.x < -size.x) {
      removeFromParent();
    }
  }

  void collect() {
    if (isCollected) return;

    isCollected = true;

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

    // TODO: Play collection animation with Rive
    // Example:
    // animation.triggerAnimation('Collect');

    // Simple visual effect - shrink shape
    shape.scale = Vector2.all(0.5);

    // TODO: Play collection sound effect
    // Example:
    // FlameAudio.play('collect_${type.toString().split('.').last}.mp3');

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
