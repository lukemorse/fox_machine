import 'dart:math';

import 'package:flutter/foundation.dart';

/// Provides a lightweight pseudo-random weather simulation for the game.
class WeatherService {
  // Weather conditions
  static const int CLEAR = 0;
  static const int RAIN = 1;
  static const int CLOUDS = 2;

  // How often to refresh the generated weather condition.
  final Duration refreshInterval;

  // Random generator used for weather changes; seeded for reproducibility in tests.
  final Random _random;

  // Cached weather condition so the weather stays consistent for a while.
  int _cachedCondition = CLEAR;
  DateTime _lastUpdate = DateTime.fromMillisecondsSinceEpoch(0);

  WeatherService({
    Duration? refreshInterval,
    Random? random,
  })  : refreshInterval = refreshInterval ?? const Duration(minutes: 5),
        _random = random ?? Random();

  /// Returns a pseudo-random weather condition.
  Future<int> getCurrentWeatherCondition() async {
    final now = DateTime.now();
    if (now.difference(_lastUpdate) >= refreshInterval) {
      _cachedCondition = _generateCondition();
      _lastUpdate = now;

      if (kDebugMode) {
        debugPrint(
          'WeatherService: Generated new weather condition $_cachedCondition',
        );
      }
    } else if (kDebugMode) {
      debugPrint(
        'WeatherService: Reusing cached weather condition $_cachedCondition',
      );
    }

    return _cachedCondition;
  }

  /// Retained for API compatibility; returns the same simulated weather.
  Future<int> getWeatherByCity(String city) {
    if (kDebugMode) {
      debugPrint(
        'WeatherService: City lookup disabled, returning simulated weather for $city',
      );
    }
    return getCurrentWeatherCondition();
  }

  int _generateCondition() {
    final roll = _random.nextDouble();

    // Weighted distribution: 60% clear, 25% clouds, 15% rain.
    if (roll < 0.15) {
      return RAIN;
    } else if (roll < 0.40) {
      return CLOUDS;
    } else {
      return CLEAR;
    }
  }
}
