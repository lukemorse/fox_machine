import 'dart:ui';
import 'dart:math' as math;
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
  late Paint _grassPaint;
  late List<Paint> _grassTuftPaints;
  late List<Rect> _groundTextureDots;

  // Random for variation
  final _random = math.Random();

  // Ground properties
  static const int groundSegments = 150; // Number of segments to draw
  final double segmentWidth = 10.0; // Width of each ground segment

  // Debug flag
  bool _debugGround = false; // Set to false to disable all debug prints

  // Components for layers to ensure proper rendering
  late RectangleComponent skyLayer;
  late RectangleComponent farTreesLayer;
  late RectangleComponent midTreesLayer;
  late GroundComponent groundComponent;

  BackgroundComponent() : super(priority: -100);

  @override
  Future<void> onLoad() async {
    size = Vector2(
      FoxMachineGame.designResolutionWidth,
      FoxMachineGame.designResolutionHeight,
    );

    // Create a textured ground paint with gradient
    _groundPaint = Paint()
      ..shader = material.LinearGradient(
        begin: material.Alignment.topCenter,
        end: material.Alignment.bottomCenter,
        colors: [
          material.Colors.brown.shade300, // Lighter soil at top
          material.Colors.brown.shade700, // Darker soil below
        ],
      ).createShader(Rect.fromLTWH(0, 0, 0, 300));

    // Darker outline for ground edge
    _groundOutlinePaint = Paint()
      ..color = material.Colors.brown.shade800 // Darker brown for outline
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    // Grass top layer
    _grassPaint = Paint()
      ..color = material.Colors.green.shade700
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0;

    // Different colors for grass tufts
    _grassTuftPaints = [
      Paint()..color = material.Colors.green.shade300,
      Paint()..color = material.Colors.green.shade600,
      Paint()..color = material.Colors.green.shade900,
    ];

    // Create texture dots for ground
    _groundTextureDots = [];
    for (int i = 0; i < 300; i++) {
      _groundTextureDots.add(
        Rect.fromCircle(
          center: Offset(
            _random.nextDouble() * size.x,
            size.y - _random.nextDouble() * 300,
          ),
          radius: 1 + _random.nextDouble() * 2,
        ),
      );
    }

    // Initialize ground points
    _groundPoints = [];
    _updateGroundPoints();

    if (_debugGround) {
      print(
          'BackgroundComponent: Ground points initialized: ${_groundPoints.length}');
    }

    // Create simple colored rectangles as background layers
    skyLayer = RectangleComponent(
      size: Vector2(FoxMachineGame.designResolutionWidth * 2,
          FoxMachineGame.designResolutionHeight),
      paint: Paint()..color = material.Colors.lightBlue.shade200,
      position: Vector2(0, 0),
      priority: -110, // Lower priority (renders below)
    );

    farTreesLayer = RectangleComponent(
      size: Vector2(FoxMachineGame.designResolutionWidth * 2,
          FoxMachineGame.designResolutionHeight * 0.4),
      paint: Paint()..color = material.Colors.green.shade900,
      position: Vector2(0, FoxMachineGame.designResolutionHeight * 0.6),
      priority: -105, // Middle priority
    );

    midTreesLayer = RectangleComponent(
      size: Vector2(FoxMachineGame.designResolutionWidth * 2,
          FoxMachineGame.designResolutionHeight * 0.3),
      paint: Paint()..color = material.Colors.green.shade700,
      position: Vector2(0, FoxMachineGame.designResolutionHeight * 0.7),
      priority: -102, // Higher priority (renders above other layers)
    );

    // Create a separate ground component with highest priority
    groundComponent = GroundComponent(
      gameRef: gameRef,
      groundPoints: _groundPoints,
      groundPaint: _groundPaint,
      groundOutlinePaint: _groundOutlinePaint,
      grassPaint: _grassPaint,
      grassTuftPaints: _grassTuftPaints,
      groundTextureDots: _groundTextureDots,
      random: _random,
      segmentWidth: segmentWidth,
      groundSegments: groundSegments,
      priority: -90, // Highest priority (renders on top)
      debugGround: _debugGround,
    );

    // Add all layers and keep references
    layers.add(skyLayer);
    layers.add(farTreesLayer);
    layers.add(midTreesLayer);

    add(skyLayer);
    add(farTreesLayer);
    add(midTreesLayer);
    add(groundComponent);

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
    }

    // Keep ground points updated as the terrain changes
    _updateGroundPoints();

    // Update ground component with new points
    groundComponent.updatePoints(_groundPoints, _groundTextureDots);
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

    // Update texture dots to move with terrain
    for (int i = 0; i < _groundTextureDots.length; i++) {
      final dot = _groundTextureDots[i];

      // Occasionally move a dot to maintain distribution as we scroll
      if (_random.nextDouble() < 0.01) {
        _groundTextureDots[i] = Rect.fromCircle(
          center: Offset(
            gameRef.size.x * (0.2 + _random.nextDouble() * 0.8),
            size.y - _random.nextDouble() * 300,
          ),
          radius: 1 + _random.nextDouble() * 2,
        );
      }
      // Otherwise just scroll it
      else if (dot.left < -10) {
        _groundTextureDots[i] = Rect.fromCircle(
          center: Offset(
            gameRef.size.x + _random.nextDouble() * 50,
            dot.center.dy,
          ),
          radius: dot.width / 2,
        );
      } else {
        // Move with the game speed
        _groundTextureDots[i] = Rect.fromCircle(
          center: Offset(
            dot.center.dx - gameRef.gameSpeed * gameRef.speedMultiplier * 0.016,
            dot.center.dy,
          ),
          radius: dot.width / 2,
        );
      }
    }
  }

  // TODO: Add methods to adjust background for different environments or time of day
  // Example:
  // void setNightMode() {
  //   skyLayer.triggerAnimation('NightTransition');
  //   // Adjust other layers accordingly
  // }
}

/// Separate component for ground rendering to ensure proper z-ordering
class GroundComponent extends PositionComponent
    with HasGameRef<FoxMachineGame> {
  List<Vector2> groundPoints;
  Paint groundPaint;
  Paint groundOutlinePaint;
  Paint grassPaint;
  List<Paint> grassTuftPaints;
  List<Rect> groundTextureDots;
  math.Random random;
  double segmentWidth;
  int groundSegments;
  bool debugGround;
  FoxMachineGame gameRef;

  GroundComponent({
    required this.gameRef,
    required this.groundPoints,
    required this.groundPaint,
    required this.groundOutlinePaint,
    required this.grassPaint,
    required this.grassTuftPaints,
    required this.groundTextureDots,
    required this.random,
    required this.segmentWidth,
    required this.groundSegments,
    required int priority,
    required this.debugGround,
  }) : super(priority: priority) {
    if (debugGround) {
      print('GroundComponent created with ${groundPoints.length} points');
    }
  }

  void updatePoints(List<Vector2> newPoints, List<Rect> newDots) {
    groundPoints = newPoints;
    groundTextureDots = newDots;
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);

    if (debugGround) {
      // Only log occasionally to avoid flooding
      if (DateTime.now().millisecondsSinceEpoch % 3000 < 20) {
        print('GroundComponent rendering with ${groundPoints.length} points');
      }
    }

    // Only proceed if we have ground points
    if (groundPoints.isEmpty) {
      print('ERROR: No ground points to render in GroundComponent!');
      return;
    }

    // Draw ground path
    final groundPath = Path();
    groundPath.moveTo(groundPoints.first.x, groundPoints.first.y);

    // Add all points along the ground
    for (final point in groundPoints.skip(1)) {
      groundPath.lineTo(point.x, point.y);
    }

    // Close the path by drawing to the bottom corners
    groundPath.lineTo(
        groundPoints.last.x, FoxMachineGame.designResolutionHeight);
    groundPath.lineTo(0, FoxMachineGame.designResolutionHeight);
    groundPath.close();

    // Fill the ground with gradient
    canvas.drawPath(groundPath, groundPaint);

    // Debug - draw a simple rectangle to verify paint operation
    if (debugGround) {
      canvas.drawRect(
        Rect.fromLTWH(
            0,
            FoxMachineGame.designResolutionHeight * 0.8,
            FoxMachineGame.designResolutionWidth,
            FoxMachineGame.designResolutionHeight * 0.2),
        Paint()..color = material.Colors.red.withOpacity(0.3),
      );
    }

    // Draw texture dots for ground
    final groundTexturePaint = Paint()
      ..color = material.Colors.brown.shade600.withOpacity(0.3)
      ..style = PaintingStyle.fill;

    for (final dot in groundTextureDots) {
      canvas.drawOval(dot, groundTexturePaint);
    }

    // Draw the ground outline (just the top surface)
    final outlinePath = Path();
    outlinePath.moveTo(groundPoints.first.x, groundPoints.first.y);
    for (final point in groundPoints.skip(1)) {
      outlinePath.lineTo(point.x, point.y);
    }
    canvas.drawPath(outlinePath, groundOutlinePaint);

    // Add grass along the top of the ground
    final grassPath = Path();
    grassPath.moveTo(groundPoints.first.x, groundPoints.first.y - 1);
    for (final point in groundPoints.skip(1)) {
      grassPath.lineTo(point.x, point.y - 1);
    }
    canvas.drawPath(grassPath, grassPaint);

    // Draw grass tufts along the path
    for (int i = 0; i < groundSegments; i += 5) {
      if (random.nextBool()) continue; // Skip some positions for variation

      final x = i * segmentWidth;
      final y = gameRef.getGroundLevelAt(x);

      // Randomize tuft properties
      final height = 3 + random.nextDouble() * 8;
      final width = 2 + random.nextDouble() * 4;
      final tilt = -0.2 + random.nextDouble() * 0.4;

      // Draw a simple grass tuft
      final tuftPath = Path();
      tuftPath.moveTo(x, y);
      tuftPath.quadraticBezierTo(
          x + width / 2 + tilt * height, y - height / 2, x + width, y);

      // Choose a random grass color
      final grassColorIndex = random.nextInt(grassTuftPaints.length);
      canvas.drawPath(tuftPath, grassTuftPaints[grassColorIndex]);
    }
  }
}
