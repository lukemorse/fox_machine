import 'package:flame/components.dart';
import 'package:flame/collisions.dart';
import 'package:flame_rive/flame_rive.dart';
import 'package:flutter/material.dart';
import 'package:fox_machine/constants/game_constants.dart';
import 'package:fox_machine/services/audio_service.dart';

import '../game/fox_machine_game.dart';
import 'obstacle.dart';
import 'collectible.dart';
import '../models/game_state.dart';
import 'particle_explosion.dart';

/// The player character component
class Player extends PositionComponent
    with CollisionCallbacks, HasGameRef<FoxMachineGame> {
  // Access audio service through game reference
  AudioService get audioService => gameRef.audioService;

  StateMachineController? controller;
  RiveAnimationController? pausableController;

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

  // Visual properties
  double _opacity = 1.0;

  // Getter and setter for opacity
  double get opacity => _opacity;
  set opacity(double value) {
    _opacity = value;
    // When opacity is zero, make invisible
    if (value <= 0) {
      normalFoxAnimation.removeFromParent();
    }
  }

  // Ground level (baseline will be set during initialization)
  final double baseGroundLevel;

  // Current ground level at player's position
  double get currentGroundLevel => gameRef.getGroundLevelAt(position.x);

  // Rive animation components
  late RiveComponent normalFoxAnimation;

  // Reference to the hitbox for dynamic adjustments
  late RectangleHitbox hitbox;

  Player({required this.baseGroundLevel}) : super(size: Vector2(200, 200));

  @override
  Future<void> onLoad() async {
    // Set initial position - center horizontally, at ground level
    position =
        Vector2(FoxMachineGame.designResolutionWidth / 4, baseGroundLevel);

    // Set anchor to bottom center
    anchor = Anchor.bottomCenter;

    // Load Rive animation
    final artboard = await loadArtboard(RiveFile.asset('assets/rive/fox.riv'));
    normalFoxAnimation = RiveComponent(
      artboard: artboard,
      size: size,
      position: Vector2(0, 0),
    );

    // Add the normal fox animation
    add(normalFoxAnimation);

    // Set initial animation state to walking
    controller = StateMachineController.fromArtboard(
      artboard,
      'State Machine 1',
    );
    artboard.addController(controller!);
    _startFoxAnimation();

    // Simple rectangular hitbox centered on the character
    hitbox = RectangleHitbox(
      size: Vector2(80, 100), // Fixed size based on character
      position:
          Vector2(100, 100), // Center it in the Rive component's rectangle
      anchor: Anchor.center, // Use center anchor for the hitbox
    )..debugMode = GameConstants.debug;
    add(hitbox);

    return super.onLoad();
  }

  void _startFoxAnimation() async {
    _updateState(PlayerState.idle);
    await Future.delayed(const Duration(seconds: 1));
    _updateState(PlayerState.walk);
  }

  @override
  void update(double dt) {
    super.update(dt);

    // Check if game is paused
    if (gameRef.gameState == GameState.paused) {
      // Pause animation if needed
      pauseAnimation();
      return;
    } else {
      // Resume animation if needed
      resumeAnimation();
    }

    if (gameRef.gameState != GameState.playing) return;

    // Get current ground level at player's x position
    final groundLevel = currentGroundLevel;

    // Apply gravity if jumping
    if (isJumping) {
      yVelocity += gravity * dt;
      position.y += yVelocity * dt;

      // Check if landed
      if (position.y >= groundLevel) {
        position.y = groundLevel;
        isJumping = false;
        yVelocity = 0;
      }
    } else {
      // If not jumping, follow the ground level
      position.y = groundLevel;
    }
  }

  // Pause the animation when the game is paused
  void pauseAnimation() {
    if (controller != null) {
      controller!.isActive = false;
    }
  }

  // Resume animation when the game is unpaused
  void resumeAnimation() {
    if (controller != null) {
      controller!.isActive = true;
    }
  }

  void jump() {
    if (!isJumping) {
      isJumping = true;
      isJumpReleased = false;
      yVelocity = jumpSpeed;

      // Could add jump sound effect here
      // audioService.playSfx('jump.mp3');
    }
  }

  void slide() {
    if (!isSliding && !isJumping) {
      isSliding = true;
    }
  }

  void toggleRobotForm(bool isRobot) async {
    isRobotForm = isRobot;

    if (isRobotForm) {
      // Enhanced abilities
      jumpSpeed = -1100;
      maxJumpSpeed = -1500;
      minJumpSpeed = -1100;

      // Switch to robot form
      _updateState(PlayerState.morphToRobot);

      // Play morphing sound effect
      audioService.playMorphToRobotSfx();

      // After animation time, update to final state
      // This won't block since animation state is handled in main game
      Future.delayed(const Duration(seconds: 1), () {
        _updateState(PlayerState.robotWalk);
      });
    } else {
      // Reset abilities
      jumpSpeed = -900;
      maxJumpSpeed = -1300;
      minJumpSpeed = -900;

      // Switch to fox form
      _updateState(PlayerState.morphToFox);

      // Play morphing sound effect
      audioService.playMorphToFoxSfx();

      // After animation time, update to final state
      // This won't block since animation state is handled in main game
      Future.delayed(const Duration(seconds: 1), () {
        _updateState(PlayerState.walk);
      });
    }
  }

  void reset() {
    position.y = currentGroundLevel;
    isJumping = false;
    isSliding = false;
    yVelocity = 0;
    isJumpReleased = true;
    _opacity = 1.0; // Reset opacity

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

      // Add the normal fox animation
      add(normalFoxAnimation);

      // Set initial animation state to walking
      controller = StateMachineController.fromArtboard(
        artboard,
        'State Machine 1',
      );
      artboard.addController(controller!);
      _startFoxAnimation();
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
        // Create big explosion at player position with game over effect
        ParticleExplosion.createBigExplosion(
          position: position.clone(),
          world: gameRef.gameWorld,
          baseColor: Colors.red,
          size: 30.0,
          isGameOver: true, // Enable dramatic game over explosion
        );

        // Create explosion at obstacle position with game over effect
        ParticleExplosion.createBigExplosion(
          position: other.position.clone(),
          world: gameRef.gameWorld,
          baseColor: Colors.orange,
          size: 25.0,
          isGameOver: true, // Enable dramatic game over explosion
        );

        // Could add crash sound effect here
        // audioService.playSfx('crash.mp3');

        // Hide player and obstacle after a tiny delay to ensure particles appear
        Future.delayed(const Duration(milliseconds: 50), () {
          opacity = 0;
          other.hide();
        });

        // Game over
        gameRef.gameOver();
      } else {
        // In robot form, create a smaller explosion at obstacle (not game over)
        ParticleExplosion.createBigExplosion(
          position: other.position.clone(),
          world: gameRef.gameWorld,
          baseColor: Colors.blue,
          size: 20.0,
          isGameOver: false, // Regular explosion, not game over
        );

        // Could add smash sound effect here
        // audioService.playSfx('robot_smash.mp3');

        // Then hide and destroy obstacle
        Future.delayed(const Duration(milliseconds: 50), () {
          other.hide();
          other.removeFromParent();
        });
      }
    } else if (other is Collectible) {
      // Collect item
      other.collect();

      // Could add collect sound effect here
      // audioService.playSfx('collect.mp3');

      if (other.type == CollectibleType.crystal) {
        gameRef.toggleRobotForm();
      }
    }
  }

  void _updateState(PlayerState state) {
    controller?.findInput<double>('state')!.value = state.index.toDouble();
  }
}

enum PlayerState {
  idle,
  walk,
  morphToRobot,
  robotWalk,
  morphToFox,
}
