import 'package:flame/components.dart';
import 'package:flutter/material.dart';

import '../game/fox_machine_game.dart';
import '../models/game_state.dart';

class BackgroundComponent extends Component with HasGameRef<FoxMachineGame> {
  // List to keep track of background layers
  final List<RectangleComponent> layers = [];

  // TODO: Replace rectangle components with Rive animations for a more dynamic background
  // Example:
  // late RiveComponent skyLayer;
  // late RiveComponent farTreesLayer;
  // late RiveComponent midTreesLayer;
  // late RiveComponent groundLayer;

  @override
  Future<void> onLoad() async {
    // Create simple colored rectangles as placeholder layers
    final skyLayer = RectangleComponent(
      size: Vector2(FoxMachineGame.designResolutionWidth * 2,
          FoxMachineGame.designResolutionHeight),
      paint: Paint()..color = Colors.lightBlue.shade200,
      position: Vector2(0, 0),
    );

    final farTreesLayer = RectangleComponent(
      size: Vector2(FoxMachineGame.designResolutionWidth * 2,
          FoxMachineGame.designResolutionHeight * 0.4),
      paint: Paint()..color = Colors.green.shade900,
      position: Vector2(0, FoxMachineGame.designResolutionHeight * 0.6),
    );

    final midTreesLayer = RectangleComponent(
      size: Vector2(FoxMachineGame.designResolutionWidth * 2,
          FoxMachineGame.designResolutionHeight * 0.3),
      paint: Paint()..color = Colors.green.shade700,
      position: Vector2(0, FoxMachineGame.designResolutionHeight * 0.7),
    );

    final groundLayer = RectangleComponent(
      size: Vector2(FoxMachineGame.designResolutionWidth * 2,
          FoxMachineGame.designResolutionHeight * 0.2),
      paint: Paint()..color = Colors.brown.shade600,
      position: Vector2(0, FoxMachineGame.designResolutionHeight * 0.8),
    );

    // TODO: Load Rive animations for each background layer
    // Example:
    // skyLayer = await RiveComponent.load(
    //   'assets/animations/background.riv',
    //   artboard: 'Sky',
    //   stateMachines: ['Clouds'],
    //   size: Vector2(gameRef.size.x * 2, gameRef.size.y),
    //   position: Vector2(0, 0),
    // );
    //
    // farTreesLayer = await RiveComponent.load(
    //   'assets/animations/background.riv',
    //   artboard: 'FarTrees',
    //   stateMachines: ['Sway'],
    //   size: Vector2(gameRef.size.x * 2, gameRef.size.y * 0.4),
    //   position: Vector2(0, gameRef.size.y * 0.6),
    // );

    // Add all layers and keep references
    layers.add(skyLayer);
    layers.add(farTreesLayer);
    layers.add(midTreesLayer);
    layers.add(groundLayer);

    add(skyLayer);
    add(farTreesLayer);
    add(midTreesLayer);
    add(groundLayer);

    // TODO: Add ambient environmental sounds
    // Example:
    // FlameAudio.bgm.play('forest_ambience.mp3', volume: 0.5);

    return super.onLoad();
  }

  // Factory method for easier creation
  static Future<BackgroundComponent> create() async {
    return BackgroundComponent();
  }

  @override
  void update(double dt) {
    super.update(dt);

    // Move the background according to the game speed
    if (gameRef.gameState == GameState.playing) {
      // Move the layers at different speeds
      for (int i = 0; i < layers.length; i++) {
        final layer = layers[i];
        // Move faster the closer to the foreground
        final speed = gameRef.gameSpeed * (0.1 + (i * 0.2)) * dt;
        layer.position.x -= speed;

        // Reset position when off screen to create infinite scrolling effect
        if (layer.position.x <= -FoxMachineGame.designResolutionWidth) {
          layer.position.x = 0;
        }
      }

      // TODO: Update Rive animation speeds based on game speed
      // Example:
      // final speedFactor = gameRef.gameSpeed / 200; // Normalize to base speed
      // skyLayer.updateAnimation('speed', speedFactor * 0.1);
      // farTreesLayer.updateAnimation('speed', speedFactor * 0.3);
      // midTreesLayer.updateAnimation('speed', speedFactor * 0.6);
      // groundLayer.updateAnimation('speed', speedFactor);
    }
  }

  // TODO: Add methods to adjust background for different environments or time of day
  // Example:
  // void setNightMode() {
  //   skyLayer.triggerAnimation('NightTransition');
  //   // Adjust other layers accordingly
  // }
}
