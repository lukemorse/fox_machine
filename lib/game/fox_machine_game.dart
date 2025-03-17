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
import '../widgets/hud_overlay.dart';
import '../widgets/game_over_overlay.dart';

/// Main game class that handles game logic and state
class FoxMachineGame extends FlameGame with TapDetector, HasCollisionDetection {
  // Optional callback for navigating back to main menu
  Function? onMainMenuPressed;

  // Game states
  GameState gameState = GameState.playing; // Start directly in playing mode
  // Track initial pause state
  bool _initialPauseActive = true;
  double _initialPauseTimer = 0.0;
  final double _initialPauseDuration = 1.0; // 1 second pause

  // Game variables
  double score = 0;
  double distanceTraveled = 0;
  double gameSpeed = GameConstants.baseGameSpeed; // pixels per second
  double speedMultiplier = GameConstants.normalSpeedMultiplier;
  bool isRobotForm = false;

  // Robot form timer
  double _robotFormTimer = 0.0;
  bool _isRevertingFromRobotForm = false;

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
  late double baseGroundLevel;

  // Ground level generation parameters
  double _groundAmplitude = 40.0; // Height of terrain variations (increased)
  double _groundWavelength = 1200.0; // Length of terrain wave (increased)
  double _groundOffset = 0.0; // Scrolls with the game

  // Seed for terrain generation
  final int _terrainSeed = DateTime.now().millisecondsSinceEpoch;

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

  // For animation state
  double _animationTimer = 0.0;
  final double _animationDuration = 1.0; // 1 second animation

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
    baseGroundLevel = designResolutionHeight * 0.85;
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
      _player = Player(baseGroundLevel: baseGroundLevel);
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

    // Handle initial pause
    if (_initialPauseActive) {
      _initialPauseTimer += dt;
      if (_initialPauseTimer >= _initialPauseDuration) {
        _initialPauseActive = false;
      }
      return; // Skip regular game updates during initial pause
    }

    // Handle animation state
    if (gameState == GameState.animating) {
      _animationTimer += dt;
      if (_animationTimer >= _animationDuration) {
        // Animation finished, resume normal play
        gameState = GameState.playing;

        // Check if we need to complete reverting from robot form
        if (_isRevertingFromRobotForm) {
          _isRevertingFromRobotForm = false;
          isRobotForm = false;
          speedMultiplier = GameConstants.normalSpeedMultiplier;
        }
      }
      return; // Skip regular game updates during animation
    }

    if (gameState != GameState.playing) return;

    // Update robot form timer if active
    if (isRobotForm && !_isRevertingFromRobotForm) {
      _robotFormTimer -= dt;
      if (_robotFormTimer <= 0) {
        // Time's up, start the reversion animation
        _robotFormTimer = 0;
        _isRevertingFromRobotForm = true;

        // Enter animation state to pause the game while animation plays
        enterAnimatingState();

        // Start transition to normal form
        player.toggleRobotForm(false);
      }
    }

    // Update terrain offset to make it scroll with game
    _groundOffset += gameSpeed * speedMultiplier * dt;

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
    // Get the ground level at spawn position
    final spawnX = designResolutionWidth + 100; // Spawn off-screen
    final groundLevel = getGroundLevelAt(spawnX);

    final obstacle = Obstacle.random(groundLevel: groundLevel);
    gameWorld.add(obstacle);
  }

  void _spawnCollectible() {
    // Get the ground level at spawn position for proper placement
    final spawnX = designResolutionWidth + 100; // Spawn off-screen
    final groundLevel = getGroundLevelAt(spawnX);

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
    if (!isRobotForm) {
      // Entering robot form
      isRobotForm = true;
      _robotFormTimer = GameConstants.robotFormDuration;

      // Enter animation state
      enterAnimatingState();

      // Toggle player form
      player.toggleRobotForm(true);

      // Set appropriate speed multiplier
      speedMultiplier = GameConstants.robotSpeedMultiplier;
    } else {
      // Already in robot form, extend the duration
      _robotFormTimer = GameConstants.robotFormDuration;
    }
  }

  // Start animation state
  void enterAnimatingState() {
    gameState = GameState.animating;
    _animationTimer = 0.0;
  }

  void gameOver() {
    gameState = GameState.gameOver;

    // Make sure hud is removed first if it's active
    if (overlays.isActive('hud')) {
      overlays.remove('hud');
    }

    // Add the game over overlay after a longer delay to let all particles display
    Future.delayed(const Duration(milliseconds: 2000), () {
      // Add the game over overlay
      overlays.add('gameOver');
    });
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
    _robotFormTimer = 0.0;
    _isRevertingFromRobotForm = false;

    // Reset timers
    _initialPauseActive = true;
    _initialPauseTimer = 0.0;
    _animationTimer = 0.0;

    // Reset terrain offset
    _groundOffset = 0.0;

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
        _player = Player(baseGroundLevel: baseGroundLevel);
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
  }

  void resume() {
    gameState = GameState.playing;
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

  double getGroundLevelAt(double x) {
    // Create a smooth terrain using sine waves for simplicity
    // We can replace this with more complex algorithms like Perlin noise later
    final position = x + _groundOffset;

    // Primary wave - large rolling hills
    final primaryWave =
        math.sin(position / _groundWavelength * 2 * math.pi) * _groundAmplitude;

    // Secondary wave - smaller variations
    final secondaryWave =
        math.sin(position / (_groundWavelength / 5) * 2 * math.pi) *
            (_groundAmplitude * 0.3);

    // Tertiary wave - tiny variations
    final tertiaryWave =
        math.sin(position / (_groundWavelength / 20) * 2 * math.pi) *
            (_groundAmplitude * 0.1);

    // Combine waves and return
    return baseGroundLevel + primaryWave + secondaryWave + tertiaryWave;
  }
}
