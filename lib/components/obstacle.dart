import 'dart:math';
import 'package:flame/components.dart';
import 'package:flame/collisions.dart';
import 'package:flutter/material.dart';

import '../game/fox_machine_game.dart';
import '../constants/game_constants.dart';
import '../models/game_state.dart';

enum ObstacleType { tree, rock, river }

class Obstacle extends PositionComponent
    with CollisionCallbacks, HasGameRef<FoxMachineGame> {
  final ObstacleType type;
  late ShapeComponent shape;
  final double groundLevel;

  // Current ground level at obstacle's position
  double get currentGroundLevel => gameRef.getGroundLevelAt(position.x);

  // TODO: Replace shape component with Rive animations
  // Example:
  // late RiveComponent animation;

  Obstacle({required this.type, required this.groundLevel})
      : super(size: Vector2(60, 80));

  static Obstacle random({required double groundLevel}) {
    final random = Random();
    const types = ObstacleType.values;
    final randomType = types[random.nextInt(types.length)];

    return Obstacle(type: randomType, groundLevel: groundLevel);
  }

  @override
  Future<void> onLoad() async {
    // Position at the right edge of the screen
    position = Vector2(
      FoxMachineGame.designResolutionWidth + size.x,
      groundLevel, // Initial ground level at spawn position
    );

    // Set anchor to bottom center
    anchor = Anchor.bottomCenter;

    // Create a simple hitbox based on obstacle type
    ShapeHitbox hitbox;
    switch (type) {
      case ObstacleType.tree:
        // Simple tall rectangle for trees
        hitbox = RectangleHitbox(
          size: Vector2(30, 70),
          position: Vector2(0, -35), // Positioned up from bottom
        );
        break;
      case ObstacleType.rock:
        // Simple circle for rocks
        hitbox = CircleHitbox(
          radius: 25,
          position: Vector2(0, -25), // Positioned up from bottom
        );
        break;
      case ObstacleType.river:
        // Simple flat rectangle for rivers
        hitbox = RectangleHitbox(
          size: Vector2(60, 15),
          position: Vector2(0, -7.5), // Positioned up from bottom
        );
        break;
    }

    // Add debug visualization if enabled
    hitbox.debugMode = GameConstants.debug;
    add(hitbox);

    // Create different shapes based on obstacle type (placeholders)
    Paint paint;
    switch (type) {
      case ObstacleType.tree:
        paint = Paint()..color = Colors.green;
        shape = RectangleComponent(
          size: Vector2(30, 80),
          paint: paint,
        );
        // TODO: Load tree animation from Rive
        // Example:
        // animation = await RiveComponent.load(
        //   'assets/animations/obstacles.riv',
        //   artboard: 'Tree',
        //   stateMachines: ['Idle'],
        //   size: Vector2(30, 80),
        // );
        break;
      case ObstacleType.rock:
        paint = Paint()..color = Colors.grey;
        shape = CircleComponent(
          radius: 30,
          paint: paint,
        );
        // TODO: Load rock animation from Rive
        // Example:
        // animation = await RiveComponent.load(
        //   'assets/animations/obstacles.riv',
        //   artboard: 'Rock',
        //   stateMachines: ['Idle'],
        //   size: Vector2(60, 60),
        // );
        break;
      case ObstacleType.river:
        paint = Paint()..color = Colors.blue;
        shape = RectangleComponent(
          size: Vector2(60, 20),
          paint: paint,
        );
        // TODO: Load river animation from Rive
        // Example:
        // animation = await RiveComponent.load(
        //   'assets/animations/obstacles.riv',
        //   artboard: 'River',
        //   stateMachines: ['Flowing'],
        //   size: Vector2(60, 20),
        // );
        break;
    }

    add(shape);

    return super.onLoad();
  }

  @override
  void update(double dt) {
    super.update(dt);

    if (gameRef.gameState != GameState.playing) return;

    // Move obstacle towards player
    position.x -= gameRef.gameSpeed * gameRef.speedMultiplier * dt;

    // Update y-position to follow the ground level
    position.y = currentGroundLevel;

    // Remove if off screen
    if (position.x < -size.x) {
      removeFromParent();
    }
  }

  // Hide the obstacle (used when exploding)
  void hide() {
    shape.removeFromParent();
  }

  // TODO: Add destroy animation method
  // void playDestroyAnimation() {
  //   // Example:
  //   // animation.triggerAnimation('Destroy');
  //   // Wait for animation to complete then remove
  //   Future.delayed(Duration(milliseconds: 300), () {
  //     removeFromParent();
  //   });
  // }
}
