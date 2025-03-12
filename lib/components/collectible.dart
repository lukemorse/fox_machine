import 'dart:math';
import 'package:flame/components.dart';
import 'package:flame/collisions.dart';
import 'package:flutter/material.dart';

import '../game/fox_machine_game.dart';
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

    // Add hitbox for collision detection
    add(CircleHitbox(
      radius: size.x / 2,
      anchor: anchor,
    ));

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
        break;
      case CollectibleType.crystal:
        gameRef.score += 50;
        break;
      case CollectibleType.special:
        gameRef.score += 100;
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
}
