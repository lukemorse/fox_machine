/// Constants used throughout the game application
class GameConstants {
  // Debug flags
  static bool debug = true; // Enable debug mode
  static bool debugLogging = true; // Enable verbose debug logging

  // Gameplay difficulty toggles
  static const bool enableCollectibleVisibilityEffects =
      true; // Set to false to make collectibles always visible

  // Game design resolution
  static const double designResolutionWidth = 1280.0;
  static const double designResolutionHeight = 720.0;

  // Game physics constants
  static const double gravity = 1500.0;
  static const double jumpForce = 600.0;

  // Spawn rates (in seconds)
  static const double obstacleSpawnRate = 1.5;
  static const double collectibleSpawnRateMin =
      3.0; // Minimum time between collectibles
  static const double collectibleSpawnRateMax =
      5.5; // Maximum time between collectibles

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

  // Energy system
  static const double maxEnergy = 100.0;
  static const double energyUsageRate =
      20.0; // Reduced from 40.0 - Energy used per second while holding jump
  static const double energyRegenRate =
      15.0; // Increased from 5.0 - Energy gained per second when not jumping
  static const double energyGainFromBerry = 5.0; // Energy gained from berry
  static const double energyGainFromEgg = 15.0; // Energy gained from egg
  static const double energyGainFromMushroom =
      40.0; // Energy gained from mushroom
  static const double energyPerJump =
      10.0; // Reduced from 20.0 - Energy used per jump
}
