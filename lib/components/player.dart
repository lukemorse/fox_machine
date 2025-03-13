import 'package:flame/components.dart';
import 'package:flame/collisions.dart';
import 'package:flame_rive/flame_rive.dart';
import 'package:flutter/material.dart' show Colors;
import 'dart:ui' show Paint;

import '../game/fox_machine_game.dart';
import '../constants/game_constants.dart';
import 'obstacle.dart';
import 'collectible.dart';
import '../models/game_state.dart';

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

    // Simple rectangular hitbox - 80% of the width, 70% of the height
    hitbox = RectangleHitbox(
      size: Vector2(size.x * 0.8, size.y * 0.7),
      // Position it to be centered horizontally and at the top portion of the player
      position: Vector2(0, -size.y * 0.7),
    )..debugMode = GameConstants.debug;
    add(hitbox);

    // Load Rive animation
    final artboard = await loadArtboard(RiveFile.asset('assets/rive/fox.riv'));
    normalFoxAnimation = RiveComponent(
      artboard: artboard,
      size: size,
    );

    // Add the normal fox animation
    add(normalFoxAnimation);

    // Set initial animation state to walking
    final controller = StateMachineController.fromArtboard(
      artboard,
      'State Machine 1',
    );
    artboard.addController(controller!);
    controller.findInput<double>('walk')!.value = 2;

    // TODO: Add inputs for jumping and falling states
    // Example:
    // controller.findInput<bool>('jump')!.value = false;
    // controller.findInput<bool>('fall')!.value = false;

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

    // Reset sliding state after some time
    if (isSliding) {
      // In a real implementation, we would handle sliding animation timing
      // For placeholder, we'll just reset after a short time
      Future.delayed(const Duration(milliseconds: 500), () {
        isSliding = false;

        // TODO: Return to running animation in Rive when slide completes
        // Example: normalFoxAnimation.triggerAnimation('run');
      });
    }

    // Adjust hitbox based on current state
    _adjustHitbox();
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
      );

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
      print('Error resetting animation: $e');
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

    if (GameConstants.debug && GameConstants.debugCollisions) {
      print('COLLISION: Player with ${other.runtimeType}');
    }

    // Simple collision logic
    if (other is Obstacle) {
      // Very simple jump check - if player is jumping and high enough, ignore collision
      if (isJumping && position.y < groundLevel - 50) {
        // Simple check - if we're significantly above ground level, we're jumping over
        if (GameConstants.debug && GameConstants.debugCollisions) {
          print('Ignoring obstacle - player is jumping high');
        }
        return;
      }

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

  // Method to adjust hitbox position for better collision detection
  void _adjustHitbox() {
    // Very simple adjustment - make hitbox flat when sliding
    if (isSliding) {
      hitbox.size = Vector2(size.x * 0.8, size.y * 0.4);
      hitbox.position = Vector2(0, -size.y * 0.4);
    } else {
      hitbox.size = Vector2(size.x * 0.8, size.y * 0.7);
      hitbox.position = Vector2(0, -size.y * 0.7);
    }
  }
}
