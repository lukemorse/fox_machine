import 'package:flame/game.dart';
import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'dart:math' as math;
import 'package:flutter/material.dart';

import '../components/player.dart';
import '../components/obstacle.dart';
import '../components/collectible.dart';
import '../components/background.dart';
import '../models/game_state.dart';

// Define the full-screen menu overlay widget
class FullScreenMenuOverlay extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black.withOpacity(0.5),
      child: Center(
        child: Text(
          'Main Menu',
          style: TextStyle(fontSize: 48, color: Colors.white),
        ),
      ),
    );
  }
}

// Define the HUD overlay widget
class HUDOverlay extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      alignment: Alignment.topLeft,
      padding: EdgeInsets.all(10),
      child: Text(
        'Score: 0',
        style: TextStyle(fontSize: 24, color: Colors.white),
      ),
    );
  }
}

class FoxMachineGame extends FlameGame with TapDetector, HasCollisionDetection {
  // Game states
  GameState gameState = GameState.menu;

  // Game variables
  double score = 0;
  double distanceTraveled = 0;
  double gameSpeed = 300; // pixels per second
  double speedMultiplier = 1.0;
  bool isRobotForm = false;

  // For variable jump height
  bool isTapHeld = false;
  double tapHoldDuration = 0.0;
  double maxJumpHoldTime =
      0.5; // Maximum time to hold for highest jump (in seconds)
  double currentJumpPower = 0.0;

  // Viewport and scaling - using static constants so they can be accessed from components
  static const double designResolutionWidth = 1280.0;
  static const double designResolutionHeight = 720.0;
  static final Vector2 designResolution =
      Vector2(designResolutionWidth, designResolutionHeight);

  // Ground level position
  late double groundLevel;

  // Scaling factors for different device sizes
  late double scaleX;
  late double scaleY;

  // Components
  late Player player;
  late BackgroundComponent background;

  // For obstacle and collectible generation
  final double obstacleSpawnRate = 1.5; // in seconds
  double timeSinceLastObstacle = 0;

  final double collectibleSpawnRate = 2.0; // in seconds
  double timeSinceLastCollectible = 0;

  // Camera setup
  late CameraComponent gameCamera;
  late World gameWorld;

  FoxMachineGame() {
    // Create world
    gameWorld = World();

    // Create camera
    gameCamera = CameraComponent.withFixedResolution(
      width: designResolutionWidth,
      height: designResolutionHeight,
      world: gameWorld,
    );

    // Center the camera
    gameCamera.viewfinder.anchor = Anchor.center;
  }

  @override
  Future<void> onLoad() async {
    // Set ground level at 75% of screen height
    groundLevel = designResolutionHeight * 0.75;

    // Calculate scaling factors for different device sizes
    scaleX = size.x / designResolutionWidth;
    scaleY = size.y / designResolutionHeight;

    // Add world and camera
    add(gameWorld);
    add(gameCamera);

    // Center camera on world
    gameCamera.viewfinder.position =
        Vector2(designResolutionWidth / 2, designResolutionHeight / 2);

    // TODO: Initialize background music here using flame_audio
    // Example: FlameAudio.bgm.play('background_music.mp3');

    // Initialize overlay visibility based on initial game state
    if (gameState == GameState.menu) {
      overlays.add('menu');
    } else {
      overlays.add('hud');
    }

    // Add background
    background = await BackgroundComponent.create();
    gameWorld.add(background);

    // Add player
    player = Player(groundLevel: groundLevel);
    gameWorld.add(player);

    return super.onLoad();
  }

  @override
  Map<String, WidgetBuilder> get overlayBuilders => {
        'menu': (BuildContext context) {
          return FullScreenMenuOverlay(); // Ensure menu is full screen
        },
        'hud': (BuildContext context) {
          return HUDOverlay();
        },
      };

  @override
  void update(double dt) {
    super.update(dt);

    if (gameState != GameState.playing) return;

    // Update score and distance
    score += dt * 10;
    distanceTraveled += dt * gameSpeed * speedMultiplier;

    // Update jump power if tap is being held
    if (isTapHeld) {
      tapHoldDuration += dt;
      currentJumpPower = math.min(tapHoldDuration / maxJumpHoldTime, 1.0);
      player.updateJumpVelocity(currentJumpPower);
    }

    // Generate obstacles
    timeSinceLastObstacle += dt;
    if (timeSinceLastObstacle >= obstacleSpawnRate) {
      _spawnObstacle();
      timeSinceLastObstacle = 0;
    }

    // Generate collectibles
    timeSinceLastCollectible += dt;
    if (timeSinceLastCollectible >= collectibleSpawnRate) {
      _spawnCollectible();
      timeSinceLastCollectible = 0;
    }

    // Gradually increase game speed
    if (score > 0 && score % 500 == 0) {
      gameSpeed += 5;
    }
  }

  void _spawnObstacle() {
    final obstacle = Obstacle.random(groundLevel: groundLevel);
    gameWorld.add(obstacle);
  }

  void _spawnCollectible() {
    final collectible = Collectible.random(groundLevel: groundLevel);
    gameWorld.add(collectible);
  }

  @override
  void onTapDown(TapDownInfo info) {
    if (gameState == GameState.playing) {
      isTapHeld = true;
      tapHoldDuration = 0.0;
      player.jump();
    }
  }

  @override
  void onTapUp(TapUpInfo info) {
    if (gameState == GameState.playing) {
      isTapHeld = false;
      player.releaseJump();
    } else if (gameState == GameState.gameOver) {
      reset();
    }
  }

  @override
  void onTapCancel() {
    if (gameState == GameState.playing) {
      isTapHeld = false;
      player.releaseJump();
    }
  }

  void toggleRobotForm() {
    isRobotForm = !isRobotForm;
    player.toggleRobotForm(isRobotForm);
    speedMultiplier = isRobotForm ? 1.8 : 1.0;

    // TODO: Play transformation sound effect
    // Example: FlameAudio.play('transform.mp3');
  }

  void gameOver() {
    gameState = GameState.gameOver;
    overlays.remove('hud');
    overlays.add('gameOver');

    // TODO: Play game over sound effect
    // Example: FlameAudio.play('game_over.mp3');
    // TODO: Stop or change background music
  }

  void reset() {
    gameState = GameState.playing;
    score = 0;
    distanceTraveled = 0;
    gameSpeed = 300;
    speedMultiplier = 1.0;
    isRobotForm = false;
    isTapHeld = false;
    tapHoldDuration = 0.0;
    currentJumpPower = 0.0;

    // Remove all obstacles and collectibles
    gameWorld.children
        .whereType<Obstacle>()
        .forEach((obstacle) => obstacle.removeFromParent());
    gameWorld.children
        .whereType<Collectible>()
        .forEach((collectible) => collectible.removeFromParent());

    // Reset player
    player.reset();

    // TODO: Play game start sound effect
    // Example: FlameAudio.play('game_start.mp3');
    // TODO: Start or restart background music
  }

  void pause() {
    gameState = GameState.paused;

    // TODO: Pause background music
    // Example: FlameAudio.bgm.pause();
  }

  void resume() {
    gameState = GameState.playing;

    // TODO: Resume background music
    // Example: FlameAudio.bgm.resume();
  }

  // Helper method to convert design coordinates to actual screen coordinates
  Vector2 getScaledPosition(Vector2 designPosition) {
    return Vector2(
      designPosition.x * scaleX,
      designPosition.y * scaleY,
    );
  }

  // Helper method to convert actual screen coordinates to design coordinates
  Vector2 getDesignPosition(Vector2 actualPosition) {
    return Vector2(
      actualPosition.x / scaleX,
      actualPosition.y / scaleY,
    );
  }
}
