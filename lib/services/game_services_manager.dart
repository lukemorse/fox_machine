import 'package:games_services/games_services.dart';
import 'package:flutter/foundation.dart';

/// Manages interactions with platform game services (Google Play Games / Apple Game Center)
class GameServicesManager {
  // Singleton instance
  static final GameServicesManager _instance = GameServicesManager._internal();
  factory GameServicesManager() => _instance;
  GameServicesManager._internal();

  bool _isSignedIn = false;
  bool _initialized = false;

  // Leaderboard IDs - replace these with your actual leaderboard IDs
  static const String _leaderboardID = 'fox_machine_high_scores';

  /// Initialize the game services
  Future<void> initialize() async {
    if (_initialized) return;

    try {
      // Try to sign in silently first
      await signIn();
      _initialized = true;
    } catch (e) {
      debugPrint('Error initializing GameServicesManager: $e');
      // Silent fail - don't interrupt gameplay if services can't be initialized
    }
  }

  /// Sign in to game services
  Future<void> signIn() async {
    try {
      await GamesServices.signIn();
      _isSignedIn = true;
    } catch (e) {
      debugPrint('Error signing in to game services: $e');
      _isSignedIn = false;
      rethrow;
    }
  }

  /// Submit score to leaderboard
  Future<void> submitScore(int score) async {
    if (!_isSignedIn) {
      try {
        // Try to sign in if not already signed in
        await signIn();
      } catch (e) {
        debugPrint('Could not sign in: $e');
        return;
      }
    }

    try {
      await GamesServices.submitScore(
        score: Score(
          androidLeaderboardID: _leaderboardID,
          iOSLeaderboardID: _leaderboardID,
          value: score,
        ),
      );
      debugPrint('Score submitted successfully: $score');
    } catch (e) {
      debugPrint('Error submitting score: $e');
    }
  }

  /// Show the leaderboard UI
  Future<void> showLeaderboard() async {
    if (!_isSignedIn) {
      try {
        // Try to sign in if not already signed in
        await signIn();
      } catch (e) {
        debugPrint('Could not sign in: $e');
        return;
      }
    }

    try {
      await GamesServices.showLeaderboards(
        androidLeaderboardID: _leaderboardID,
        iOSLeaderboardID: _leaderboardID,
      );
    } catch (e) {
      debugPrint('Error showing leaderboard: $e');
    }
  }

  /// Get current sign-in status
  bool get isSignedIn => _isSignedIn;
}
