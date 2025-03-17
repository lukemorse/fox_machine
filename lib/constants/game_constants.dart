/// Constants used throughout the game application
class GameConstants {
  // Debug flags
  static bool debug = false;

  // Game design resolution
  static const double designResolutionWidth = 1280.0;
  static const double designResolutionHeight = 720.0;

  // Game physics constants
  static const double gravity = 1500.0;
  static const double jumpForce = 600.0;

  // Spawn rates (in seconds)
  static const double obstacleSpawnRate = 1.5;
  static const double collectibleSpawnRate = 2.0;

  // Base game speed (pixels per second)
  static const double baseGameSpeed = 300.0;

  // Robot form speed multiplier
  static const double robotSpeedMultiplier = 1.8;
  static const double normalSpeedMultiplier = 1.0;

  // Robot form duration in seconds
  static const double robotFormDuration = 10.0;

  // Jump controls
  static const double maxJumpHoldTime =
      0.5; // Maximum time to hold for highest jump

  // Collision groups for debugging
  static const int playerGroup = 0x01;
  static const int obstacleGroup = 0x02;
  static const int collectibleGroup = 0x04;
}
