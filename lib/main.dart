import 'package:flame/flame.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'routes/game_router.dart';
import 'theme/game_theme.dart';
import 'constants/game_constants.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Flame
  await Flame.device.fullScreen();
  await Flame.device.setLandscape();

  // Set preferred orientations to landscape
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
  ]);

  // Set full screen
  SystemChrome.setEnabledSystemUIMode(
    SystemUiMode.immersiveSticky,
  );

  // Debug settings - change to true for debugging visuals
  GameConstants.debug = false;
  // For detailed collision logs
  // GameConstants.debugCollisions = false;

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Fox Machine',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primaryColor: GameTheme.primaryColor,
        scaffoldBackgroundColor: GameTheme.backgroundColor,
        fontFamily: 'VT323',
        textTheme: TextTheme(
          headlineLarge: GameTheme.titleStyle,
          headlineMedium: GameTheme.headingStyle,
          bodyLarge: GameTheme.bodyStyle,
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: GameTheme.primaryButtonStyle,
        ),
      ),
      home: const GameNavigator(),
    );
  }
}
