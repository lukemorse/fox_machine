import 'package:flame_audio/flame_audio.dart';
import '../constants/audio_constants.dart';

/// Manages all game audio including background music and sound effects
class AudioService {
  // Singleton instance
  static final AudioService _instance = AudioService._internal();
  factory AudioService() => _instance;
  AudioService._internal();

  bool _audioInitialized = false;
  bool _isMuted = false; // For potential mute feature

  /// Initialize audio system and preload sounds
  Future<void> initialize() async {
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
    } catch (e) {
      // Silent fail - don't interrupt gameplay if audio can't be loaded
      print('Error loading audio: $e');
    }
  }

  /// Play main background music
  void playMainMusic() {
    if (_audioInitialized && !_isMuted) {
      FlameAudio.bgm.stop();
      FlameAudio.bgm.play(AudioConstants.mainBgMusic);
    }
  }

  /// Play robot background music
  void playRobotMusic() {
    if (_audioInitialized && !_isMuted) {
      FlameAudio.bgm.stop();
      FlameAudio.bgm.play(AudioConstants.robotBgMusic);
    }
  }

  /// Stop all background music
  void stopMusic() {
    if (_audioInitialized) {
      FlameAudio.bgm.stop();
    }
  }

  /// Play a sound effect once
  void playSfx(String sfxName) {
    if (_audioInitialized && !_isMuted) {
      FlameAudio.play(sfxName);
    }
  }

  /// Play swell up effect when morphing to robot
  /// Interrupts current music and transitions to robot music
  void playMorphToRobotSfx() async {
    if (_audioInitialized && !_isMuted) {
      // Stop current music immediately
      print('Stopping current music: ${DateTime.now()}');
      FlameAudio.bgm.stop();

      // Play swell up effect
      FlameAudio.play(AudioConstants.swellUpSfx);
      await Future.delayed(const Duration(milliseconds: 1200));
      playRobotMusic();
    }
  }

  /// Play swell down effect when morphing back to fox
  /// Interrupts current music and transitions to main music
  void playMorphToFoxSfx() async {
    if (_audioInitialized && !_isMuted) {
      // Stop current music immediately
      FlameAudio.bgm.stop();

      // Play swell down effect
      FlameAudio.play(AudioConstants.swellDownSfx);
      await Future.delayed(const Duration(milliseconds: 1200));

      playMainMusic();
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
