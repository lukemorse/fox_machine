import 'dart:ui';
import 'dart:math' as math;
import 'package:flame/components.dart';
import 'package:flutter/material.dart' as material;
import 'package:flutter/foundation.dart';

import '../game/fox_machine_game.dart';
import '../models/game_state.dart';

/// Background component that includes both the sky and ground
class BackgroundComponent extends PositionComponent
    with HasGameRef<FoxMachineGame> {
  // List to keep track of background layers
  final List<RectangleComponent> layers = [];

  // Store ground segments for efficient rendering
  late final List<Vector2> _groundPoints;
  late final Paint _groundPaint;
  late final Paint _groundOutlinePaint;
  late final Paint _grassPaint;
  late final List<Paint> _grassTuftPaints;
  late final List<GroundTextureDot> _groundTextureDots;
  late final Paint _groundTexturePaint;

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
    try {
      debugPrint('BackgroundComponent: Starting onLoad');
      size = Vector2(
        FoxMachineGame.designResolutionWidth,
        FoxMachineGame.designResolutionHeight,
      );
      debugPrint('BackgroundComponent: Size set to ${size.x}x${size.y}');

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

      debugPrint('BackgroundComponent: Setting up ground texture');
      _groundTexturePaint = Paint()
        ..color = material.Colors.brown.shade600.withOpacity(0.3)
        ..style = PaintingStyle.fill;

      // Create texture dots for ground
      _groundTextureDots = List.generate(
        300,
        (_) => GroundTextureDot(
          center: Vector2(
            _random.nextDouble() * size.x,
            size.y - _random.nextDouble() * 300,
          ),
          radius: 1 + _random.nextDouble() * 2,
        ),
        growable: false,
      );

      // Initialize ground points
      _groundPoints = List.generate(
        groundSegments + 1,
        (i) {
          final x = i * segmentWidth;
          final y = gameRef.getGroundLevelAt(x);
          return Vector2(x, y);
        },
        growable: false,
      );

      debugPrint(
        'BackgroundComponent: Ground points initialized: ${_groundPoints.length}',
      );

      // Create simple colored rectangles as background layers
      debugPrint('BackgroundComponent: Creating sky layer');
      skyLayer = RectangleComponent(
        size: Vector2(
          FoxMachineGame.designResolutionWidth * 2,
          FoxMachineGame.designResolutionHeight,
        ),
        paint: Paint()..color = material.Colors.lightBlue.shade200,
        position: Vector2(0, 0),
        priority: -110, // Lower priority (renders below)
      );

      debugPrint('BackgroundComponent: Creating far trees layer');
      farTreesLayer = RectangleComponent(
        size: Vector2(
          FoxMachineGame.designResolutionWidth * 2,
          FoxMachineGame.designResolutionHeight * 0.4,
        ),
        paint: Paint()..color = material.Colors.green.shade900,
        position: Vector2(0, FoxMachineGame.designResolutionHeight * 0.6),
        priority: -105, // Middle priority
      );

      debugPrint('BackgroundComponent: Creating mid trees layer');
      midTreesLayer = RectangleComponent(
        size: Vector2(
          FoxMachineGame.designResolutionWidth * 2,
          FoxMachineGame.designResolutionHeight * 0.3,
        ),
        paint: Paint()..color = material.Colors.green.shade700,
        position: Vector2(0, FoxMachineGame.designResolutionHeight * 0.7),
        priority: -102, // Higher priority (renders above other layers)
      );

      debugPrint('BackgroundComponent: Creating ground component');
      // Create a separate ground component with highest priority
      groundComponent = GroundComponent(
        groundPoints: _groundPoints,
        groundPaint: _groundPaint,
        groundOutlinePaint: _groundOutlinePaint,
        grassPaint: _grassPaint,
        grassTuftPaints: _grassTuftPaints,
        groundTextureDots: _groundTextureDots,
        groundTexturePaint: _groundTexturePaint,
        random: _random,
        segmentWidth: segmentWidth,
        groundSegments: groundSegments,
        priority: -90, // Highest priority (renders on top)
        debugGround: _debugGround,
      );

      // Add all layers and keep references
      debugPrint('BackgroundComponent: Adding layers to component');
      layers.add(skyLayer);
      layers.add(farTreesLayer);
      layers.add(midTreesLayer);

      add(skyLayer);
      add(farTreesLayer);
      add(midTreesLayer);
      add(groundComponent);

      debugPrint('BackgroundComponent: onLoad completed successfully');
      return super.onLoad();
    } catch (e, stackTrace) {
      debugPrint('BackgroundComponent: Error in onLoad: $e');
      debugPrint('BackgroundComponent: Stack trace: $stackTrace');
      rethrow;
    }
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
    // Update existing ground vectors to avoid per-frame allocations
    for (int i = 0; i < _groundPoints.length; i++) {
      final x = i * segmentWidth;
      final y = gameRef.getGroundLevelAt(x);
      _groundPoints[i].setValues(x, y);
    }

    // Update texture dots to move with terrain
    final scrollDelta =
        gameRef.gameSpeed * gameRef.speedMultiplier * 0.016;

    for (final dot in _groundTextureDots) {
      // Occasionally reposition a dot to maintain distribution as we scroll
      if (_random.nextDouble() < 0.01) {
        dot.center.setValues(
          gameRef.size.x * (0.2 + _random.nextDouble() * 0.8),
          size.y - _random.nextDouble() * 300,
        );
        dot.radius = 1 + _random.nextDouble() * 2;
        continue;
      }
<<<<<<< HEAD
      // Otherwise just scroll it
      else if (dot.left < -10) {
        _groundTextureDots[i] = Rect.fromCircle(
          center: Offset(
            gameRef.size.x + _random.nextDouble() * 50,
            dot.center.dx, // Preserve Y relative position logic if needed, but here we just reset X
          ),
          radius: dot.width / 2,
        );
        // Reset Y to something random to avoid lines forming
        _groundTextureDots[i] = Rect.fromCircle(
          center: Offset(
             gameRef.size.x + _random.nextDouble() * 50,
             size.y - _random.nextDouble() * 300,
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
=======

      if (dot.center.x < -10) {
        dot.center.x = gameRef.size.x + _random.nextDouble() * 50;
        continue;
>>>>>>> 3c15283bb5552d44a448e7567e5a4f406967d97e
      }

      // Move with the game speed
      dot.center.x -= scrollDelta;
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
class GroundComponent extends PositionComponent {
  List<Vector2> groundPoints;
  final Paint groundPaint;
  final Paint groundOutlinePaint;
  final Paint grassPaint;
  final List<Paint> grassTuftPaints;
  List<GroundTextureDot> groundTextureDots;
  final Paint groundTexturePaint;
  final math.Random random;
  final double segmentWidth;
  final int groundSegments;
  final bool debugGround;

  GroundComponent({
    required this.groundPoints,
    required this.groundPaint,
    required this.groundOutlinePaint,
    required this.grassPaint,
    required this.grassTuftPaints,
    required this.groundTextureDots,
    required this.groundTexturePaint,
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

  void updatePoints(
    List<Vector2> newPoints,
    List<GroundTextureDot> newDots,
  ) {
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

    if (groundPoints.isEmpty) {
      print('ERROR: No ground points to render in GroundComponent!');
      return;
    }

    final groundPath = Path()
      ..moveTo(groundPoints.first.x, groundPoints.first.y);

    for (var i = 1; i < groundPoints.length; i++) {
      final point = groundPoints[i];
      groundPath.lineTo(point.x, point.y);
    }

    groundPath
      ..lineTo(
        groundPoints.last.x,
        FoxMachineGame.designResolutionHeight,
      )
      ..lineTo(0, FoxMachineGame.designResolutionHeight)
      ..close();

    canvas.drawPath(groundPath, groundPaint);

    if (debugGround) {
      canvas.drawRect(
        Rect.fromLTWH(
          0,
          FoxMachineGame.designResolutionHeight * 0.8,
          FoxMachineGame.designResolutionWidth,
          FoxMachineGame.designResolutionHeight * 0.2,
        ),
        Paint()..color = material.Colors.red.withOpacity(0.3),
      );
    }

    for (final dot in groundTextureDots) {
      canvas.drawCircle(
        Offset(dot.center.x, dot.center.y),
        dot.radius,
        groundTexturePaint,
      );
    }

    final outlinePath = Path()
      ..moveTo(groundPoints.first.x, groundPoints.first.y);
    for (var i = 1; i < groundPoints.length; i++) {
      final point = groundPoints[i];
      outlinePath.lineTo(point.x, point.y);
    }
    canvas.drawPath(outlinePath, groundOutlinePaint);

    final grassPath = Path()
      ..moveTo(groundPoints.first.x, groundPoints.first.y - 1);
    for (var i = 1; i < groundPoints.length; i++) {
      final point = groundPoints[i];
      grassPath.lineTo(point.x, point.y - 1);
    }
    canvas.drawPath(grassPath, grassPaint);

    for (int i = 0; i < groundSegments; i += 5) {
      if (random.nextBool()) continue;

      final point = groundPoints[i];
      final x = point.x;
      final y = point.y;

      final height = 3 + random.nextDouble() * 8;
      final width = 2 + random.nextDouble() * 4;
      final tilt = -0.2 + random.nextDouble() * 0.4;

      final tuftPath = Path()
        ..moveTo(x, y)
        ..quadraticBezierTo(
          x + width / 2 + tilt * height,
          y - height / 2,
          x + width,
          y,
        );

      final grassColorIndex = random.nextInt(grassTuftPaints.length);
      canvas.drawPath(tuftPath, grassTuftPaints[grassColorIndex]);
    }
  }
}

/// Represents a reusable textured dot for the ground background.
class GroundTextureDot {
  GroundTextureDot({
    required this.center,
    required this.radius,
  });

  final Vector2 center;
  double radius;
}
