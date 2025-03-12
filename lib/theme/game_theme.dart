import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

// Game theme class for consistent styling
class GameTheme {
  // Color scheme
  static const Color primaryColor = Color(0xFFFF9800); // Orange
  static const Color secondaryColor = Color(0xFF1A237E); // Deep Blue
  static const Color accentColor = Color(0xFF00BCD4); // Cyan
  static const Color backgroundColor = Color(0xFF000000); // Black
  static const Color textColor = Colors.white;
  static const Color scoreColor = Color(0xFFFFD54F); // Amber

  // Text styles
  static TextStyle get titleStyle => GoogleFonts.pressStart2p(
        fontSize: 48,
        color: primaryColor,
        shadows: const [
          Shadow(
            color: Color(0xFFFF5722),
            blurRadius: 15,
            offset: Offset(0, 0),
          ),
        ],
        decoration: TextDecoration.none,
      );

  static TextStyle get headingStyle => GoogleFonts.pressStart2p(
        fontSize: 32,
        color: textColor,
        decoration: TextDecoration.none,
      );

  static TextStyle get bodyStyle => TextStyle(
        fontFamily: 'Roboto',
        fontSize: 24,
        color: textColor,
        fontWeight: FontWeight.bold,
        decoration: TextDecoration.none,
      );

  static TextStyle get scoreStyle => TextStyle(
        fontFamily: 'Roboto',
        fontSize: 20,
        color: scoreColor,
        shadows: const [
          Shadow(
            blurRadius: 2.0,
            color: Colors.black,
            offset: Offset(1.0, 1.0),
          ),
        ],
        decoration: TextDecoration.none,
      );

  static TextStyle get robotModeStyle => TextStyle(
        fontFamily: 'Roboto',
        fontSize: 18,
        color: Colors.lightBlue,
        fontWeight: FontWeight.bold,
        shadows: const [
          Shadow(
            blurRadius: 2.0,
            color: Colors.black,
            offset: Offset(1.0, 1.0),
          ),
        ],
        decoration: TextDecoration.none,
      );

  static ButtonStyle get primaryButtonStyle => ElevatedButton.styleFrom(
        backgroundColor: primaryColor,
        textStyle: const TextStyle(
          fontFamily: 'Roboto',
          fontSize: 18,
          fontWeight: FontWeight.bold,
        ),
      );
}
