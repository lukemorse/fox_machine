import 'package:flame_audio/flame_audio.dart';
import 'package:flutter/foundation.dart';
import '../constants/audio_constants.dart';
import '../constants/game_constants.dart';

/// Manages all game audio including background music and sound effects
class AudioService {
  // Singleton instance
  static final AudioService _instance = AudioService._internal();
  factory AudioService() => _instance;
  AudioService._internal();

  bool _audioInitialized = false;
  bool _isMuted = false; // For potential mute feature

  // Track current music for resuming
  String _currentMusic = '';
  bool _isMusicPaused = false;

  // Skip audio in debug mode
  final bool _skipAudioInDebugMode = GameConstants.debug && kDebugMode;

  /// Initialize audio system and preload sounds
  Future<void> initialize() async {
    if (_skipAudioInDebugMode) {
      debugPrint('AudioService: Skipping audio initialization in debug mode');
      _audioInitialized = true; // Mark as initialized without loading anything
      return;
    }

    debugPrint('AudioService: Initializing audio');
    try {
      // Preload music
      await FlameAudio.audioCache.loadAll([
        AudioConstants.mainBgMusic,
        AudioConstants.robotBgMusic,
        // Preload sound effects
        AudioConstants.swellUpSfx,
        AudioConstants.swellDownSfx,
      ]);
      _audioInitialized = true;
      debugPrint('AudioService: Audio initialized successfully');
    } catch (e, stackTrace) {
      // Better error handling - still don't crash but log more details
      debugPrint('AudioService: Error loading audio: $e');
      debugPrint('AudioService: Audio error stack trace: $stackTrace');

      // Still mark as initialized so we don't keep trying
      _audioInitialized = true;
      // Set mute so we don't try to play anything
      _isMuted = true;
      debugPrint('AudioService: Audio disabled due to initialization error');
    }
  }

  /// Play main background music
  void playMainMusic() {
    if (!_audioInitialized || _isMuted || _skipAudioInDebugMode) {
      return;
    }

    try {
      debugPrint('AudioService: Playing main music');
      FlameAudio.bgm.stop();
      FlameAudio.bgm.play(AudioConstants.mainBgMusic);
      _currentMusic = AudioConstants.mainBgMusic;
      _isMusicPaused = false;
    } catch (e) {
      debugPrint('AudioService: Error playing main music: $e');
      // Don't crash the game for audio issues
    }
  }

  /// Play robot background music
  void playRobotMusic() {
    if (!_audioInitialized || _isMuted || _skipAudioInDebugMode) {
      return;
    }

    try {
      debugPrint('AudioService: Playing robot music');
      FlameAudio.bgm.stop();
      FlameAudio.bgm.play(AudioConstants.robotBgMusic);
      _currentMusic = AudioConstants.robotBgMusic;
      _isMusicPaused = false;
    } catch (e) {
      debugPrint('AudioService: Error playing robot music: $e');
      // Don't crash the game for audio issues
    }
  }

  /// Pause currently playing music
  void pauseMusic() {
    if (!_audioInitialized ||
        _isMuted ||
        _isMusicPaused ||
        _skipAudioInDebugMode) {
      return;
    }

    try {
      debugPrint('AudioService: Pausing music');
      FlameAudio.bgm.pause();
      _isMusicPaused = true;
    } catch (e) {
      debugPrint('AudioService: Error pausing music: $e');
    }
  }

  /// Resume previously paused music
  void resumeMusic() {
    if (!_audioInitialized ||
        _isMuted ||
        !_isMusicPaused ||
        _skipAudioInDebugMode) {
      return;
    }

    try {
      debugPrint('AudioService: Resuming music');
      if (_currentMusic.isNotEmpty) {
        FlameAudio.bgm.resume();
      } else {
        // Fallback if no track was remembered
        playMainMusic();
      }
      _isMusicPaused = false;
    } catch (e) {
      debugPrint('AudioService: Error resuming music: $e');
    }
  }

  /// Stop all background music
  void stopMusic() {
    if (!_audioInitialized || _skipAudioInDebugMode) {
      return;
    }

    try {
      debugPrint('AudioService: Stopping music');
      FlameAudio.bgm.stop();
      _currentMusic = '';
      _isMusicPaused = false;
    } catch (e) {
      debugPrint('AudioService: Error stopping music: $e');
    }
  }

  /// Play a sound effect once
  void playSfx(String sfxName) {
    if (!_audioInitialized || _isMuted || _skipAudioInDebugMode) {
      return;
    }

    try {
      // Play at a higher volume (1.5x)
      FlameAudio.play(sfxName, volume: 1.5);
    } catch (e) {
      debugPrint('AudioService: Error playing sound effect: $e');
    }
  }

  /// Play swell up effect when morphing to robot
  /// Interrupts current music and transitions to robot music
  void playMorphToRobotSfx() async {
    if (!_audioInitialized || _isMuted || _skipAudioInDebugMode) {
      return;
    }

    try {
      debugPrint('AudioService: Playing morph to robot effect');
      // Stop current music immediately
      FlameAudio.bgm.stop();

      // Play swell up effect with higher volume
      FlameAudio.play(AudioConstants.swellUpSfx, volume: 1.5);
      await Future.delayed(const Duration(milliseconds: 1200));
      playRobotMusic();
    } catch (e) {
      debugPrint('AudioService: Error playing morph to robot effect: $e');
    }
  }

  /// Play swell down effect when morphing back to fox
  /// Interrupts current music and transitions to main music
  void playMorphToFoxSfx() async {
    if (!_audioInitialized || _isMuted || _skipAudioInDebugMode) {
      return;
    }

    try {
      debugPrint('AudioService: Playing morph to fox effect');
      // Stop current music immediately
      FlameAudio.bgm.stop();

      // Play swell down effect with higher volume
      FlameAudio.play(AudioConstants.swellDownSfx, volume: 1.5);
      await Future.delayed(const Duration(milliseconds: 1200));

      playMainMusic();
    } catch (e) {
      debugPrint('AudioService: Error playing morph to fox effect: $e');
    }
  }

  /// Toggle mute status
  void toggleMute() {
    _isMuted = !_isMuted;
    if (_isMuted) {
      stopMusic();
    }
  }

  /// Get current mute status
  bool get isMuted => _isMuted;
}
