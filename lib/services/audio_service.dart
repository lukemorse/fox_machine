import 'package:flame_audio/flame_audio.dart';

/// Manages all game audio including background music and sound effects
class AudioService {
  // Singleton instance
  static final AudioService _instance = AudioService._internal();
  factory AudioService() => _instance;
  AudioService._internal();

  // Audio tracks
  static const String mainBgMusic = 'music/bg_music_main.mp3';
  static const String robotBgMusic = 'music/bg_music_robot.mp3';
  // TODO: Add game over music when available

  bool _audioInitialized = false;
  bool _isMuted = false; // For potential mute feature

  /// Initialize audio system and preload sounds
  Future<void> initialize() async {
    try {
      await FlameAudio.audioCache.loadAll([mainBgMusic, robotBgMusic]);
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
      FlameAudio.bgm.play(mainBgMusic);
    }
  }

  /// Play robot background music
  void playRobotMusic() {
    if (_audioInitialized && !_isMuted) {
      FlameAudio.bgm.stop();
      FlameAudio.bgm.play(robotBgMusic);
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
