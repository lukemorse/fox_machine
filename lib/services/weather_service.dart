import 'package:weather/weather.dart';
import 'package:geolocator/geolocator.dart';

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

  /// Gets the current weather at the device location
  Future<int> getCurrentWeatherCondition() async {
    try {
      // Check location permission
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          // Return default weather if location is denied
          return CLEAR;
        }
      }

      // Get current position
      Position? position;
      try {
        position = await Geolocator.getCurrentPosition();
      } catch (e) {
        print('Error fetching weather: $e');
        return CLEAR;
      }

      // Get weather at current location
      Weather weather = await _wf.currentWeatherByLocation(
        position.latitude,
        position.longitude,
      );

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
      print('Error fetching weather: $e');
      return CLEAR;
    }
  }

  /// Gets weather by city name (fallback method)
  Future<int> getWeatherByCity(String city) async {
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
      print('Error fetching weather: $e');
      return CLEAR;
    }
  }
}
