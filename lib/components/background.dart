import 'dart:ui';
import 'package:flame/components.dart';
import 'package:flutter/material.dart' as material;

import '../game/fox_machine_game.dart';
import '../models/game_state.dart';

/// Background component that includes both the sky and ground
class BackgroundComponent extends PositionComponent
    with HasGameRef<FoxMachineGame> {
  // List to keep track of background layers
  final List<RectangleComponent> layers = [];

  // TODO: Replace rectangle components with Rive animations for a more dynamic background
  // Example:
  // late RiveComponent skyLayer;
  // late RiveComponent farTreesLayer;
  // late RiveComponent midTreesLayer;
  // late RiveComponent groundLayer;

  // Store ground segments for efficient rendering
  late List<Vector2> _groundPoints;
  late Paint _groundPaint;
  late Paint _groundOutlinePaint;

  // Ground properties
  static const int groundSegments = 150; // Number of segments to draw
  final double segmentWidth = 10.0; // Width of each ground segment

  BackgroundComponent() : super(priority: -100);

  @override
  Future<void> onLoad() async {
    size = Vector2(
      FoxMachineGame.designResolutionWidth,
      FoxMachineGame.designResolutionHeight,
    );

    // Initialize ground visualization
    _groundPaint = Paint()
      ..color = const material.Color(0xFF8B5E3C) // Brown earth color
      ..style = PaintingStyle.fill;

    _groundOutlinePaint = Paint()
      ..color = const material.Color(0xFF654321) // Darker brown for outline
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    // Initialize ground points
    _updateGroundPoints();

    // Create simple colored rectangles as placeholder layers
    final skyLayer = RectangleComponent(
      size: Vector2(FoxMachineGame.designResolutionWidth * 2,
          FoxMachineGame.designResolutionHeight),
      paint: Paint()..color = material.Colors.lightBlue.shade200,
      position: Vector2(0, 0),
    );

    final farTreesLayer = RectangleComponent(
      size: Vector2(FoxMachineGame.designResolutionWidth * 2,
          FoxMachineGame.designResolutionHeight * 0.4),
      paint: Paint()..color = material.Colors.green.shade900,
      position: Vector2(0, FoxMachineGame.designResolutionHeight * 0.6),
    );

    final midTreesLayer = RectangleComponent(
      size: Vector2(FoxMachineGame.designResolutionWidth * 2,
          FoxMachineGame.designResolutionHeight * 0.3),
      paint: Paint()..color = material.Colors.green.shade700,
      position: Vector2(0, FoxMachineGame.designResolutionHeight * 0.7),
    );

    final groundLayer = RectangleComponent(
      size: Vector2(FoxMachineGame.designResolutionWidth * 2,
          FoxMachineGame.designResolutionHeight * 0.2),
      paint: Paint()..color = material.Colors.brown.shade600,
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

    // Keep ground points updated as the terrain changes
    _updateGroundPoints();
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);

    // Draw sky background
    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.x, size.y),
      Paint()..color = const material.Color(0xFF87CEEB), // Sky blue
    );

    // Draw ground path
    final groundPath = Path();

    // Start at the first point
    if (_groundPoints.isNotEmpty) {
      groundPath.moveTo(_groundPoints.first.x, _groundPoints.first.y);

      // Add all points along the ground
      for (final point in _groundPoints.skip(1)) {
        groundPath.lineTo(point.x, point.y);
      }

      // Close the path by drawing to the bottom corners
      groundPath.lineTo(_groundPoints.last.x, size.y);
      groundPath.lineTo(0, size.y);
      groundPath.close();

      // Fill the ground
      canvas.drawPath(groundPath, _groundPaint);

      // Draw the ground outline (just the top surface)
      final outlinePath = Path();
      outlinePath.moveTo(_groundPoints.first.x, _groundPoints.first.y);
      for (final point in _groundPoints.skip(1)) {
        outlinePath.lineTo(point.x, point.y);
      }
      canvas.drawPath(outlinePath, _groundOutlinePaint);
    }
  }

  // Update the ground points based on the current game state
  void _updateGroundPoints() {
    _groundPoints = [];

    // Create ground segments starting from left edge
    for (int i = 0; i <= groundSegments; i++) {
      final x = i * segmentWidth;
      final y = gameRef.getGroundLevelAt(x);
      _groundPoints.add(Vector2(x, y));
    }
  }

  // TODO: Add methods to adjust background for different environments or time of day
  // Example:
  // void setNightMode() {
  //   skyLayer.triggerAnimation('NightTransition');
  //   // Adjust other layers accordingly
  // }
}
