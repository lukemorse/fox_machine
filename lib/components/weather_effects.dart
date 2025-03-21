import 'dart:math' as math;
import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import '../game/fox_machine_game.dart';

/// Base class for all weather effects
abstract class WeatherEffect extends PositionComponent
    with HasGameRef<FoxMachineGame> {
  WeatherEffect({required super.priority});
}

/// Rain effect with falling raindrops
class RainEffect extends WeatherEffect {
  // Rain properties
  final List<_Raindrop> _raindrops = [];
  final int _maxRaindrops = 100;
  final math.Random _random = math.Random();

  // Rain colors and opacity
  final Paint _rainPaint = Paint()
    ..color = Colors.lightBlue.shade100.withOpacity(0.7)
    ..strokeWidth = 2.0
    ..strokeCap = StrokeCap.round;

  RainEffect() : super(priority: -95);

  @override
  Future<void> onLoad() async {
    size = Vector2(
      FoxMachineGame.designResolutionWidth,
      FoxMachineGame.designResolutionHeight,
    );

    // Initialize raindrops
    for (int i = 0; i < _maxRaindrops; i++) {
      _raindrops.add(_createRaindrop(randomizePosition: true));
    }

    return super.onLoad();
  }

  @override
  void update(double dt) {
    super.update(dt);

    // Update each raindrop
    for (int i = 0; i < _raindrops.length; i++) {
      final drop = _raindrops[i];

      // Move raindrop down and slightly to the right
      drop.position.y += drop.speed * dt;
      drop.position.x += drop.speed * 0.2 * dt; // Angled rain

      // Reset raindrop if it goes off screen
      if (drop.position.y > size.y || drop.position.x > size.x) {
        _raindrops[i] = _createRaindrop(randomizePosition: false);
      }
    }
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);

    // Draw each raindrop
    for (final drop in _raindrops) {
      // Calculate end point based on length
      final endX = drop.position.x + drop.length * 0.2;
      final endY = drop.position.y + drop.length;

      canvas.drawLine(
        Offset(drop.position.x, drop.position.y),
        Offset(endX, endY),
        _rainPaint,
      );
    }
  }

  _Raindrop _createRaindrop({required bool randomizePosition}) {
    final x = _random.nextDouble() * size.x;
    final y = randomizePosition
        ? _random.nextDouble() * size.y
        : -_random.nextDouble() * 50;

    return _Raindrop(
      position: Vector2(x, y),
      length: 10 + _random.nextDouble() * 15,
      speed: 300 + _random.nextDouble() * 200,
    );
  }
}

/// Cloud effect with drifting clouds
class CloudEffect extends WeatherEffect {
  // Cloud properties
  final List<_Cloud> _clouds = [];
  final int _maxClouds = 6;
  final math.Random _random = math.Random();

  CloudEffect() : super(priority: -96);

  @override
  Future<void> onLoad() async {
    size = Vector2(
      FoxMachineGame.designResolutionWidth,
      FoxMachineGame.designResolutionHeight,
    );

    // Initialize clouds
    for (int i = 0; i < _maxClouds; i++) {
      _clouds.add(_createCloud(randomizePosition: true));
    }

    return super.onLoad();
  }

  @override
  void update(double dt) {
    super.update(dt);

    // Update each cloud
    for (int i = 0; i < _clouds.length; i++) {
      final cloud = _clouds[i];

      // Move cloud horizontally
      cloud.position.x += cloud.speed * dt;

      // Reset cloud if it goes off screen
      if (cloud.position.x > size.x + cloud.width) {
        _clouds[i] = _createCloud(randomizePosition: false);
      }
    }
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);

    // Draw each cloud
    for (final cloud in _clouds) {
      final paint = Paint()..color = Colors.white.withOpacity(cloud.opacity);

      // Draw a simple cloud shape
      final cloudPath = Path();

      // Create the cloud shape using circles
      for (final circle in cloud.circles) {
        cloudPath.addOval(
          Rect.fromCircle(
            center: Offset(
              cloud.position.x + circle.x,
              cloud.position.y + circle.y,
            ),
            radius: circle.radius,
          ),
        );
      }

      canvas.drawPath(cloudPath, paint);
    }
  }

  _Cloud _createCloud({required bool randomizePosition}) {
    final width = 100 + _random.nextDouble() * 150;
    final height = 40 + _random.nextDouble() * 30;

    final x = randomizePosition
        ? _random.nextDouble() * size.x
        : -width - _random.nextDouble() * 200;

    final y = 50 + _random.nextDouble() * (size.y * 0.3);

    // Create circles for cloud shape
    List<_CloudCircle> circles = [];

    // Main circles
    circles.add(
        _CloudCircle(x: width * 0.5, y: height * 0.5, radius: height * 0.5));
    circles.add(
        _CloudCircle(x: width * 0.3, y: height * 0.4, radius: height * 0.4));
    circles.add(
        _CloudCircle(x: width * 0.7, y: height * 0.4, radius: height * 0.45));

    // Add some random small circles for variation
    for (int i = 0; i < 3; i++) {
      circles.add(_CloudCircle(
        x: _random.nextDouble() * width,
        y: height * (0.3 + _random.nextDouble() * 0.4),
        radius: height * (0.2 + _random.nextDouble() * 0.2),
      ));
    }

    return _Cloud(
      position: Vector2(x, y),
      width: width,
      height: height,
      speed: 20 + _random.nextDouble() * 30,
      opacity: 0.6 + _random.nextDouble() * 0.3,
      circles: circles,
    );
  }
}

/// Sun effect with rays
class SunEffect extends WeatherEffect {
  // Sun properties
  final math.Random _random = math.Random();
  late Vector2 _position;
  final double _baseRadius = 50.0;
  double _rayPhase = 0.0;

  SunEffect() : super(priority: -97);

  @override
  Future<void> onLoad() async {
    size = Vector2(
      FoxMachineGame.designResolutionWidth,
      FoxMachineGame.designResolutionHeight,
    );

    // Position the sun in the top portion of the screen
    _position = Vector2(
      size.x * 0.8,
      size.y * 0.2,
    );

    return super.onLoad();
  }

  @override
  void update(double dt) {
    super.update(dt);

    // Animate ray phase for pulsing effect
    _rayPhase += dt * 0.5;
    if (_rayPhase > math.pi * 2) {
      _rayPhase -= math.pi * 2;
    }
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);

    // Draw sun glow
    final glowPaint = Paint()
      ..shader = RadialGradient(
        colors: [
          Colors.yellow.shade300.withOpacity(0.7),
          Colors.yellow.shade100.withOpacity(0.1),
          Colors.transparent,
        ],
        stops: const [0.4, 0.8, 1.0],
      ).createShader(
        Rect.fromCircle(
          center: Offset(_position.x, _position.y),
          radius: _baseRadius * 2.5,
        ),
      );

    canvas.drawCircle(
      Offset(_position.x, _position.y),
      _baseRadius * 2.5,
      glowPaint,
    );

    // Draw sun rays
    final rayPaint = Paint()
      ..color = Colors.yellow.shade100.withOpacity(0.6)
      ..strokeWidth = 3.0;

    final rayCount = 12;
    final rayLength = _baseRadius * (1.2 + 0.3 * math.sin(_rayPhase));

    for (int i = 0; i < rayCount; i++) {
      final angle = (i / rayCount) * math.pi * 2;
      final startX = _position.x + _baseRadius * math.cos(angle);
      final startY = _position.y + _baseRadius * math.sin(angle);
      final endX = _position.x + (_baseRadius + rayLength) * math.cos(angle);
      final endY = _position.y + (_baseRadius + rayLength) * math.sin(angle);

      canvas.drawLine(
        Offset(startX, startY),
        Offset(endX, endY),
        rayPaint,
      );
    }

    // Draw sun circle
    final sunPaint = Paint()
      ..shader = RadialGradient(
        colors: [
          Colors.yellow.shade200,
          Colors.orange.shade300,
        ],
      ).createShader(
        Rect.fromCircle(
          center: Offset(_position.x, _position.y),
          radius: _baseRadius,
        ),
      );

    canvas.drawCircle(
      Offset(_position.x, _position.y),
      _baseRadius,
      sunPaint,
    );
  }
}

/// Helper class for raindrops
class _Raindrop {
  Vector2 position;
  double length;
  double speed;

  _Raindrop({
    required this.position,
    required this.length,
    required this.speed,
  });
}

/// Helper class for cloud circles
class _CloudCircle {
  double x;
  double y;
  double radius;

  _CloudCircle({
    required this.x,
    required this.y,
    required this.radius,
  });
}

/// Helper class for clouds
class _Cloud {
  Vector2 position;
  double width;
  double height;
  double speed;
  double opacity;
  List<_CloudCircle> circles;

  _Cloud({
    required this.position,
    required this.width,
    required this.height,
    required this.speed,
    required this.opacity,
    required this.circles,
  });
}
