import 'dart:math';
import 'package:flame/components.dart';
import 'package:flame/collisions.dart';
import 'package:flame/particles.dart';
import 'package:flutter/material.dart';

import '../game/fox_machine_game.dart';
import '../constants/game_constants.dart';
import '../models/game_state.dart';

enum CollectibleType { berry, crystal, special }

class Collectible extends PositionComponent
    with CollisionCallbacks, HasGameRef<FoxMachineGame> {
  final CollectibleType type;
  late ShapeComponent shape;
  bool isCollected = false;
  final double groundLevel;

  // TODO: Replace shape component with Rive animations
  // Example:
  // late RiveComponent animation;

  Collectible({required this.type, required this.groundLevel})
      : super(size: Vector2(30, 30));

  static Collectible random({required double groundLevel}) {
    final random = Random();

    // Weight the probability to have more berries than crystals or special items
    final randomValue = random.nextDouble();

    CollectibleType randomType;
    if (randomValue < 0.7) {
      randomType = CollectibleType.berry;
    } else if (randomValue < 0.9) {
      randomType = CollectibleType.crystal;
    } else {
      randomType = CollectibleType.special;
    }

    return Collectible(type: randomType, groundLevel: groundLevel);
  }

  @override
  Future<void> onLoad() async {
    // Position at the right edge of the screen at a random height
    final random = Random();
    position = Vector2(
      FoxMachineGame.designResolutionWidth + size.x,
      groundLevel - random.nextDouble() * 200, // Vary height
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
      case CollectibleType.crystal:
        paint = Paint()..color = Colors.purple;
        shape = RectangleComponent(
          size: Vector2(25, 25),
          paint: paint,
        );
        // TODO: Load crystal animation from Rive
        // Example:
        // animation = await RiveComponent.load(
        //   'assets/animations/collectibles.riv',
        //   artboard: 'Crystal',
        //   stateMachines: ['Glowing'],
        //   size: Vector2(30, 30),
        // );
        break;
      case CollectibleType.special:
        paint = Paint()..color = Colors.yellow;
        shape = PolygonComponent(
          [
            Vector2(0, -15),
            Vector2(15, 15),
            Vector2(-15, 15),
          ],
          paint: paint,
        );
        // TODO: Load special collectible animation from Rive
        // Example:
        // animation = await RiveComponent.load(
        //   'assets/animations/collectibles.riv',
        //   artboard: 'Special',
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
      case CollectibleType.crystal:
        gameRef.score += 50;
        // Add crystal collection particle effect
        _addCollectionParticles(Colors.purple);
        break;
      case CollectibleType.special:
        gameRef.score += 100;
        // Add special collection particle effect
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
