import 'package:flame/components.dart';
import 'package:flame/collisions.dart';
import 'package:flame_rive/flame_rive.dart';
import 'package:flutter/material.dart' show Colors;
import 'dart:ui' show Paint, PaintingStyle;

import '../game/fox_machine_game.dart';
import '../constants/game_constants.dart';
import 'obstacle.dart';
import 'collectible.dart';
import '../models/game_state.dart';

/// The player character component
class Player extends PositionComponent
    with CollisionCallbacks, HasGameRef<FoxMachineGame> {
  // Movement variables
  double gravity = 1500;
  double jumpSpeed = -900;
  double maxJumpSpeed = -1300;
  double minJumpSpeed = -900;
  double yVelocity = 0;
  bool isJumping = false;
  bool isSliding = false;

  // For variable jump height
  bool isJumpReleased = true;

  // Character state
  bool isRobotForm = false;

  // Ground level (will be set during initialization)
  final double groundLevel;

  // Rive animation components
  late RiveComponent normalFoxAnimation;

  // Reference to the hitbox for dynamic adjustments
  late RectangleHitbox hitbox;

  Player({required this.groundLevel}) : super(size: Vector2(200, 200));

  @override
  Future<void> onLoad() async {
    // Set initial position - center horizontally, at ground level
    position = Vector2(FoxMachineGame.designResolutionWidth / 4, groundLevel);

    // Set anchor to bottom center
    anchor = Anchor.bottomCenter;

    // Add debug rectangle to visualize full component size (blue)
    if (GameConstants.debug) {
      final playerDebugRect = RectangleComponent(
        size: size,
        paint: Paint()
          ..color = Colors.blue.withOpacity(0.1) // Make it very transparent
          ..style = PaintingStyle.fill,
      );
      playerDebugRect.anchor = anchor;
      add(playerDebugRect);
    }

    // Load Rive animation
    final artboard = await loadArtboard(RiveFile.asset('assets/rive/fox.riv'));
    normalFoxAnimation = RiveComponent(
      artboard: artboard,
      size: size,
      position: Vector2(0, 0),
    );

    // Add debug rectangle to visualize Rive component (red)
    if (GameConstants.debug) {
      final riveDebugRect = RectangleComponent(
        size: normalFoxAnimation.size,
        paint: Paint()
          ..color = Colors.red.withOpacity(0.3)
          ..style = PaintingStyle.fill,
      );
      normalFoxAnimation.add(riveDebugRect);
    }

    // Add the normal fox animation
    add(normalFoxAnimation);

    // Set initial animation state to walking
    final controller = StateMachineController.fromArtboard(
      artboard,
      'State Machine 1',
    );
    artboard.addController(controller!);
    controller.findInput<double>('walk')!.value = 2;

    // Simple rectangular hitbox centered on the character
    hitbox = RectangleHitbox(
      size: Vector2(80, 100), // Fixed size based on character
      position:
          Vector2(100, 100), // Center it in the Rive component's red rectangle
      anchor: Anchor.center, // Use center anchor for the hitbox
    )..debugMode = GameConstants.debug;
    add(hitbox);

    return super.onLoad();
  }

  @override
  void update(double dt) {
    super.update(dt);

    if (gameRef.gameState != GameState.playing) return;

    // Apply gravity if jumping
    if (isJumping) {
      yVelocity += gravity * dt;
      position.y += yVelocity * dt;

      // Check if landed
      if (position.y >= groundLevel) {
        position.y = groundLevel;
        isJumping = false;
        yVelocity = 0;

        // TODO: Play landing sound effect
        // Example: FlameAudio.play('land.mp3');

        // TODO: Trigger landing animation in Rive
        // Example: normalFoxAnimation.triggerAnimation('land');
      }
    }
  }

  void jump() {
    if (!isJumping) {
      isJumping = true;
      isJumpReleased = false;
      yVelocity = jumpSpeed;

      // TODO: Play jump sound effect
      // Example: FlameAudio.play('jump.mp3');

      // TODO: Trigger jump animation in Rive
      // Example: normalFoxAnimation.triggerAnimation('jump');
    }
  }

  void slide() {
    if (!isSliding && !isJumping) {
      isSliding = true;

      // TODO: Play slide sound effect
      // Example: FlameAudio.play('slide.mp3');

      // TODO: Trigger slide animation in Rive
      // Example: normalFoxAnimation.triggerAnimation('slide');
    }
  }

  void toggleRobotForm(bool isRobot) {
    isRobotForm = isRobot;

    if (isRobotForm) {
      // Switch to robot form
      normalFoxAnimation.removeFromParent();
      // TODO: Add robot form animation

      // Enhanced abilities
      jumpSpeed = -1100;
      maxJumpSpeed = -1500;
      minJumpSpeed = -1100;

      // TODO: Play transformation sound effect
      // Example: FlameAudio.play('transform.mp3');

      // TODO: Add transformation visual effect and swap Rive animations
      // Example:
      // normalFoxAnimation.removeFromParent();
      // add(robotFoxAnimation);
      // add(TransformationEffect());
    } else {
      // Switch back to normal form
      // TODO: Add normal form animation back

      // Reset abilities
      jumpSpeed = -900;
      maxJumpSpeed = -1300;
      minJumpSpeed = -900;

      // TODO: Play transformation sound effect
      // Example: FlameAudio.play('transform_back.mp3');

      // TODO: Add transformation visual effect and swap Rive animations
      // Example:
      // robotFoxAnimation.removeFromParent();
      // add(normalFoxAnimation);
      // add(TransformationEffect());
    }
  }

  void reset() {
    position.y = groundLevel;
    isJumping = false;
    isSliding = false;
    yVelocity = 0;
    isJumpReleased = true;

    // Reset to normal form
    if (isRobotForm) {
      toggleRobotForm(false);
    }

    // A more reliable way to reset animations is to recreate the animation component
    _resetAnimation();
  }

  // Helper method to reset animation
  Future<void> _resetAnimation() async {
    try {
      // Remove the current animation component
      normalFoxAnimation.removeFromParent();

      // Recreate the animation component
      final artboard =
          await loadArtboard(RiveFile.asset('assets/rive/fox.riv'));
      normalFoxAnimation = RiveComponent(
        artboard: artboard,
        size: size,
        // Reset position to default
        position: Vector2(0, 0),
      );

      // Add debug rectangle to visualize Rive component (red)
      if (GameConstants.debug) {
        final riveDebugRect = RectangleComponent(
          size: normalFoxAnimation.size,
          paint: Paint()
            ..color = Colors.red.withOpacity(0.3)
            ..style = PaintingStyle.fill,
        );
        normalFoxAnimation.add(riveDebugRect);
      }

      // Add the normal fox animation
      add(normalFoxAnimation);

      // Set initial animation state to walking
      final controller = StateMachineController.fromArtboard(
        artboard,
        'State Machine 1',
      );
      artboard.addController(controller!);
      controller.findInput<double>('walk')!.value = 2;
    } catch (e) {
      // Silent fail - don't interrupt gameplay
    }
  }

  void updateJumpVelocity(double jumpPower) {
    // Apply jump power (between 0.0 and 1.0) to calculate jump velocity
    if (isJumping && !isJumpReleased) {
      // Calculate jump velocity based on jump power
      double calculatedJumpSpeed =
          minJumpSpeed - (maxJumpSpeed - minJumpSpeed) * jumpPower;
      yVelocity = calculatedJumpSpeed;
    }
  }

  void releaseJump() {
    isJumpReleased = true;
  }

  @override
  void onCollisionStart(
      Set<Vector2> intersectionPoints, PositionComponent other) {
    super.onCollisionStart(intersectionPoints, other);

    // Simple collision logic
    if (other is Obstacle) {
      if (!isRobotForm) {
        // Game over
        gameRef.gameOver();
      } else {
        // Destroy obstacle
        other.removeFromParent();
      }
    } else if (other is Collectible) {
      // Collect item
      other.collect();

      if (other.type == CollectibleType.crystal) {
        gameRef.toggleRobotForm();
      }
    }
  }
}
