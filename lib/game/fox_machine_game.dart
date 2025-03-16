import 'package:flame/game.dart';
import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'dart:math' as math;
import 'package:flutter/material.dart';

import '../components/player.dart';
import '../components/obstacle.dart';
import '../components/collectible.dart';
import '../components/background.dart';
import '../constants/game_constants.dart';
import '../models/game_state.dart';

// Define the HUD overlay widget
class HUDOverlay extends StatelessWidget {
  final FoxMachineGame game;

  const HUDOverlay({super.key, required this.game});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Score display
          Text(
            'Score: ${game.score.toInt()}',
            style: const TextStyle(
              fontSize: 24,
              color: Colors.white,
              shadows: [
                Shadow(
                  blurRadius: 2.0,
                  color: Colors.black,
                  offset: Offset(1.0, 1.0),
                ),
              ],
              decoration: TextDecoration.none,
            ),
          ),

          // Robot mode indicator
          game.isRobotForm
              ? const Text(
                  'ROBOT MODE',
                  style: TextStyle(
                    fontSize: 20,
                    color: Colors.blue,
                    fontWeight: FontWeight.bold,
                    shadows: [
                      Shadow(
                        blurRadius: 2.0,
                        color: Colors.black,
                        offset: Offset(1.0, 1.0),
                      ),
                    ],
                    decoration: TextDecoration.none,
                  ),
                )
              : const SizedBox.shrink(),
        ],
      ),
    );
  }
}

// Define the game over overlay widget
class GameOverOverlay extends StatelessWidget {
  final Function onMainMenuPressed;
  final Function onRestartPressed;
  final int score;

  const GameOverOverlay({
    super.key,
    required this.onMainMenuPressed,
    required this.onRestartPressed,
    required this.score,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.8),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Game Over',
              style: TextStyle(
                fontSize: 30,
                color: Colors.red,
                fontWeight: FontWeight.bold,
                decoration: TextDecoration.none,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              'Score: $score',
              style: const TextStyle(
                fontSize: 24,
                color: Colors.white,
                decoration: TextDecoration.none,
              ),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                  ),
                  onPressed: () => onRestartPressed(),
                  child: const Text(
                    'Play Again',
                    style: TextStyle(
                      decoration: TextDecoration.none,
                    ),
                  ),
                ),
                const SizedBox(width: 20),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                  ),
                  onPressed: () => onMainMenuPressed(),
                  child: const Text(
                    'Main Menu',
                    style: TextStyle(
                      decoration: TextDecoration.none,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class FoxMachineGame extends FlameGame with TapDetector, HasCollisionDetection {
  // Optional callback for navigating back to main menu
  Function? onMainMenuPressed;

  // Game states
  GameState gameState = GameState.playing; // Start directly in playing mode

  // Game variables
  double score = 0;
  double distanceTraveled = 0;
  double gameSpeed = GameConstants.baseGameSpeed; // pixels per second
  double speedMultiplier = GameConstants.normalSpeedMultiplier;
  bool isRobotForm = false;

  // For variable jump height
  bool isTapHeld = false;
  double tapHoldDuration = 0.0;
  double maxJumpHoldTime = GameConstants
      .maxJumpHoldTime; // Maximum time to hold for highest jump (in seconds)
  double currentJumpPower = 0.0;

  // Viewport and scaling - using static constants so they can be accessed from components
  static const double designResolutionWidth =
      GameConstants.designResolutionWidth;
  static const double designResolutionHeight =
      GameConstants.designResolutionHeight;
  static final Vector2 designResolution =
      Vector2(designResolutionWidth, designResolutionHeight);

  // Ground level position
  late double groundLevel;

  // Scaling factors for different device sizes
  late double scaleX;
  late double scaleY;

  // Components
  Player? _player; // Private nullable player reference
  late BackgroundComponent background;
  bool _playerInitialized = false; // Track if player has been initialized

  // Player accessor with null safety
  Player get player {
    if (_player == null) {
      throw StateError('Player accessed before initialization');
    }
    return _player!;
  }

  // For obstacle and collectible generation
  final double obstacleSpawnRate =
      GameConstants.obstacleSpawnRate; // in seconds
  double timeSinceLastObstacle = 0;

  final double collectibleSpawnRate =
      GameConstants.collectibleSpawnRate; // in seconds
  double timeSinceLastCollectible = 0;

  // Camera setup
  late CameraComponent gameCamera;
  late World gameWorld;

  FoxMachineGame({this.onMainMenuPressed}) {
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

    // Set ground level directly in constructor
    groundLevel = designResolutionHeight * 0.85;
  }

  @override
  Future<void> onLoad() async {
    // Calculate scaling factors for different device sizes
    scaleX = size.x / designResolutionWidth;
    scaleY = size.y / designResolutionHeight;

    // Add world and camera
    add(gameWorld);
    add(gameCamera);

    // Center camera on world
    gameCamera.viewfinder.position =
        Vector2(designResolutionWidth / 2, designResolutionHeight / 2);

    // Add background
    background = await BackgroundComponent.create();
    gameWorld.add(background);

    // Clean up any potential duplicate player instances first
    final existingPlayers = gameWorld.children.whereType<Player>().toList();
    if (existingPlayers.isNotEmpty) {
      print(
          'Found ${existingPlayers.length} player(s) during game initialization');
      // Keep only the first one if multiple
      if (existingPlayers.length > 1) {
        for (int i = 1; i < existingPlayers.length; i++) {
          existingPlayers[i].removeFromParent();
        }
      }
      // Set our reference to the existing player
      _player = existingPlayers[0];
      _playerInitialized = true;
    } else {
      // No player exists, create a new one
      print("Creating new player in onLoad");
      _player = Player(groundLevel: groundLevel);
      gameWorld.add(_player!);
      _playerInitialized = true;
    }

    // Reset the game state
    reset(skipPlayerReset: true);

    // Start with the hud overlay
    overlays.add('hud');

    return super.onLoad();
  }

  @override
  Map<String, OverlayWidgetBuilder<FoxMachineGame>> get overlayBuilders => {
        'hud': (BuildContext context, FoxMachineGame game) =>
            HUDOverlay(game: game),
        'gameOver': (BuildContext context, FoxMachineGame game) =>
            GameOverOverlay(
              score: game.score.toInt(),
              onRestartPressed: () {
                game.restartFromGameOver();
              },
              onMainMenuPressed: () {
                // Go back to main menu if callback exists
                if (game.onMainMenuPressed != null) {
                  game.reset();
                  // Ensure the gameOver overlay is removed before going to main menu
                  if (game.overlays.isActive('gameOver')) {
                    game.overlays.remove('gameOver');
                  }
                  game.onMainMenuPressed!();
                }
              },
            ),
      };

  @override
  void update(double dt) {
    super.update(dt);

    if (gameState != GameState.playing) return;

    // Update score and distance
    score += dt * 10;
    distanceTraveled += dt * gameSpeed * speedMultiplier;

    // Force rebuild of HUD overlay to update score
    if (overlays.isActive('hud')) {
      overlays.remove('hud');
      overlays.add('hud');
    }

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
    speedMultiplier = isRobotForm
        ? GameConstants.robotSpeedMultiplier
        : GameConstants.normalSpeedMultiplier;

    // TODO: Play transformation sound effect
    // Example: FlameAudio.play('transform.mp3');
  }

  void gameOver() {
    gameState = GameState.gameOver;

    // Make sure hud is removed first if it's active
    if (overlays.isActive('hud')) {
      overlays.remove('hud');
    }

    // Add the game over overlay
    overlays.add('gameOver');

    // TODO: Play game over sound effect
    // Example: FlameAudio.play('game_over.mp3');
    // TODO: Stop or change background music
  }

  void reset({bool skipPlayerReset = false}) {
    gameState = GameState.playing;
    score = 0;
    distanceTraveled = 0;
    gameSpeed = GameConstants.baseGameSpeed;
    speedMultiplier = GameConstants.normalSpeedMultiplier;
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

    // Skip player handling if we're being called from onLoad
    if (!skipPlayerReset) {
      // Clean up any potential duplicate player instances
      final existingPlayers = gameWorld.children.whereType<Player>().toList();
      if (existingPlayers.length > 1) {
        print(
            'WARNING: Found ${existingPlayers.length} players in game world. Cleaning up duplicates.');
        // Keep only the first player
        for (int i = 1; i < existingPlayers.length; i++) {
          existingPlayers[i].removeFromParent();
        }
        // Update our reference to the remaining player
        _player = existingPlayers[0];
      }

      // Check if player exists
      if (existingPlayers.isEmpty) {
        // No player exists, create a new one
        print("Creating new player in reset");
        _player = Player(groundLevel: groundLevel);
        gameWorld.add(_player!);
        _playerInitialized = true;
      } else {
        // Update reference to first player and reset it
        _player = existingPlayers[0];
        _player!.reset();
      }
    } else if (_player != null) {
      // Just reset the player state without recreating
      _player!.reset();
    }

    // TODO: Play game start sound effect
    // Example: FlameAudio.play('game_start.mp3');
    // TODO: Start or restart background music
  }

  // This method can be called safely from the overlays after the game is initialized
  void restartFromGameOver() {
    reset();
    if (overlays.isActive('gameOver')) {
      overlays.remove('gameOver');
    }
    if (!overlays.isActive('hud')) {
      overlays.add('hud');
    }
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
