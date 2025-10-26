import 'package:weather/weather.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter/foundation.dart';

/// A service for fetching weather data based on device location
class WeatherService {
  // OpenWeatherMap API key
  static const String _apiKey = '574d369863384022f8cd8d657b8ed46d';

  // Weather instance
  final WeatherFactory _wf = WeatherFactory(_apiKey);

  // Weather conditions
  static const int CLEAR = 0;
  static const int RAIN = 1;
  static const int CLOUDS = 2;

  // Flag to skip actual weather requests (useful for debugging)
  final bool _skipWeatherRequests = kDebugMode;

  /// Gets the current weather at the device location
  Future<int> getCurrentWeatherCondition() async {
    // In debug mode, skip the actual weather API requests
    if (_skipWeatherRequests) {
      debugPrint('WeatherService: Skipping real weather request in debug mode');
      return CLEAR;
    }

    try {
      debugPrint('WeatherService: Checking location permission');
      // Check location permission
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          // Return default weather if location is denied
          debugPrint('WeatherService: Location permission denied');
          return CLEAR;
        }
      }

      // Get current position
      Position? position;
      try {
        debugPrint('WeatherService: Getting current position');
        position = await Geolocator.getCurrentPosition();
      } catch (e) {
        debugPrint('WeatherService: Error getting position: $e');
        return CLEAR;
      }

      // Get weather at current location
      debugPrint('WeatherService: Fetching weather data');
      Weather weather = await _wf.currentWeatherByLocation(
        position.latitude,
        position.longitude,
      );

      // Determine weather condition
      final String mainCondition =
          weather.weatherMain?.toLowerCase() ?? 'clear';
      debugPrint('WeatherService: Weather condition: $mainCondition');

      if (mainCondition.contains('rain') ||
          mainCondition.contains('drizzle') ||
          mainCondition.contains('thunderstorm')) {
        return RAIN;
      } else if (mainCondition.contains('cloud')) {
        return CLOUDS;
      } else {
        return CLEAR;
      }
    } catch (e) {
      // Return default weather on error
      debugPrint('WeatherService: Error fetching weather: $e');
      return CLEAR;
    }
  }

  /// Gets weather by city name (fallback method)
  Future<int> getWeatherByCity(String city) async {
    // In debug mode, skip the actual weather API requests
    if (_skipWeatherRequests) {
      debugPrint('WeatherService: Skipping city weather request in debug mode');
      return CLEAR;
    }

    try {
      // Get weather for specified city
      Weather weather = await _wf.currentWeatherByCityName(city);

      // Determine weather condition
      final String mainCondition =
          weather.weatherMain?.toLowerCase() ?? 'clear';

      if (mainCondition.contains('rain') ||
          mainCondition.contains('drizzle') ||
          mainCondition.contains('thunderstorm')) {
        return RAIN;
      } else if (mainCondition.contains('cloud')) {
        return CLOUDS;
      } else {
        return CLEAR;
      }
    } catch (e) {
      // Return default weather on error
      debugPrint('WeatherService: Error fetching weather: $e');
      return CLEAR;
    }
  }
}
