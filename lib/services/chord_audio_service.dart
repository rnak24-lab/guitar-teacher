import 'package:audioplayers/audioplayers.dart';

/// Service for playing chord sound previews.
/// Audio files should be placed in assets/audio/chords/ as MP3 or OGG.
/// Naming convention: chord name lowercase, e.g. c.mp3, am.mp3, fmaj7.mp3
class ChordAudioService {
  static final ChordAudioService _instance = ChordAudioService._();
  factory ChordAudioService() => _instance;
  ChordAudioService._();

  final AudioPlayer _player = AudioPlayer();
  bool _disposed = false;

  /// Attempts to play the chord sample for [chordName].
  /// Returns true if the file exists and playback started, false otherwise.
  Future<bool> playChord(String chordName) async {
    if (_disposed) return false;

    final fileName = _chordFileName(chordName);
    final assetPath = 'audio/chords/$fileName';

    try {
      await _player.stop();
      await _player.setSource(AssetSource(assetPath));
      await _player.resume();
      return true;
    } catch (_) {
      // Audio file not found or playback error — asset not yet available
      return false;
    }
  }

  /// Stop any currently playing chord preview.
  Future<void> stop() async {
    if (!_disposed) {
      await _player.stop();
    }
  }

  /// Check if a chord audio file is available.
  Future<bool> hasAudio(String chordName) async {
    final fileName = _chordFileName(chordName);
    final assetPath = 'audio/chords/$fileName';
    try {
      await _player.setSource(AssetSource(assetPath));
      return true;
    } catch (_) {
      return false;
    }
  }

  void dispose() {
    _disposed = true;
    _player.dispose();
  }

  /// Convert chord name to file name.
  /// Examples: C -> c.mp3, Am -> am.mp3, Fmaj7 -> fmaj7.mp3, Bb -> bb.mp3
  String _chordFileName(String chordName) {
    return '${chordName.toLowerCase().replaceAll('#', 'sharp').replaceAll('♯', 'sharp')}.mp3';
  }
}
