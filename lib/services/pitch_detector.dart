import 'dart:async';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:record/record.dart';

/// Shared pitch detection service using Autocorrelation.
/// Extracted from TunerScreen for reuse in Scale Practice, Scale Quiz,
/// Note Finder, and any other screen that needs microphone pitch detection.
class PitchDetector {
  final AudioRecorder _recorder = AudioRecorder();
  StreamSubscription<Uint8List>? _audioStreamSub;

  // PCM settings (mono 16-bit signed LE)
  static const int sampleRate = 44100;
  static const int _bufferSize = 4096;

  final List<double> _audioBuffer = [];

  bool _isListening = false;
  bool get isListening => _isListening;

  /// Callback fired when a pitch is detected.
  /// Parameters: frequency (Hz), noteName, cents-off-from-nearest-note
  void Function(double frequency, String noteName, double cents)? onPitchDetected;

  /// Standard tuning open-string frequencies (for reference)
  static const Map<String, double> openStringFrequencies = {
    '6E': 82.41,
    '5A': 110.00,
    '4D': 146.83,
    '3G': 196.00,
    '2B': 246.94,
    '1E': 329.63,
  };

  /// All 12 note names
  static const List<String> _noteNames = [
    'C', 'Db', 'D', 'Eb', 'E', 'F', 'Gb', 'G', 'Ab', 'A', 'Bb', 'B'
  ];

  /// Request microphone permission. Returns true if granted.
  static Future<bool> requestMicPermission() async {
    final status = await Permission.microphone.request();
    return status.isGranted;
  }

  /// Check if permission was permanently denied
  static Future<bool> isPermissionPermanentlyDenied() async {
    final status = await Permission.microphone.status;
    return status.isPermanentlyDenied;
  }

  /// Start listening to the microphone.
  Future<bool> startListening() async {
    if (_isListening) return true;

    final granted = await requestMicPermission();
    if (!granted) return false;

    try {
      final stream = await _recorder.startStream(
        const RecordConfig(
          encoder: AudioEncoder.pcm16bits,
          sampleRate: sampleRate,
          numChannels: 1,
          autoGain: true,
          echoCancel: false,
          noiseSuppress: false,
        ),
      );

      _audioBuffer.clear();

      _audioStreamSub = stream.listen((data) {
        _processAudioData(data);
      });

      _isListening = true;
      return true;
    } catch (e) {
      debugPrint('PitchDetector: Audio stream error: $e');
      return false;
    }
  }

  /// Stop listening.
  Future<void> stopListening() async {
    _audioStreamSub?.cancel();
    _audioStreamSub = null;
    _audioBuffer.clear();

    if (await _recorder.isRecording()) {
      await _recorder.stop();
    }

    _isListening = false;
  }

  /// Dispose resources.
  void dispose() {
    stopListening();
    _recorder.dispose();
  }

  // ── PCM data processing ──
  void _processAudioData(Uint8List data) {
    final byteData = ByteData.sublistView(data);
    for (int i = 0; i < data.length - 1; i += 2) {
      final sample = byteData.getInt16(i, Endian.little) / 32768.0;
      _audioBuffer.add(sample);
    }

    while (_audioBuffer.length >= _bufferSize) {
      final window = _audioBuffer.sublist(0, _bufferSize);
      _audioBuffer.removeRange(0, _bufferSize ~/ 2); // 50% overlap

      final freq = detectPitch(window);
      if (freq > 0) {
        final noteInfo = frequencyToNote(freq);
        onPitchDetected?.call(freq, noteInfo['name'] as String, noteInfo['cents'] as double);
      }
    }
  }

  // ── Pitch detection (Autocorrelation) ──
  static double detectPitch(List<double> buffer) {
    // RMS check - skip silence
    double rms = 0;
    for (final s in buffer) {
      rms += s * s;
    }
    rms = sqrt(rms / buffer.length);
    if (rms < 0.01) return 0;

    final halfLen = buffer.length ~/ 2;
    final correlation = List<double>.filled(halfLen, 0);

    for (int lag = 0; lag < halfLen; lag++) {
      double sum = 0;
      for (int i = 0; i < halfLen; i++) {
        sum += buffer[i] * buffer[i + lag];
      }
      correlation[lag] = sum;
    }

    // Guitar range: ~60Hz to ~1400Hz (high frets on 1st string)
    final minLag = (sampleRate / 1400).round();
    final maxLag = min((sampleRate / 60).round(), halfLen - 1);

    double maxCorr = 0;
    int bestLag = 0;

    for (int lag = minLag; lag <= maxLag; lag++) {
      if (correlation[lag] > maxCorr) {
        maxCorr = correlation[lag];
        bestLag = lag;
      }
    }

    if (bestLag == 0 || maxCorr < correlation[0] * 0.2) return 0;

    // Parabolic interpolation for sub-sample accuracy
    if (bestLag > 0 && bestLag < halfLen - 1) {
      final a = correlation[bestLag - 1];
      final b = correlation[bestLag];
      final c = correlation[bestLag + 1];
      final delta = 0.5 * (a - c) / (a - 2 * b + c);
      return sampleRate / (bestLag + delta);
    }

    return sampleRate / bestLag.toDouble();
  }

  // ── Frequency to note name + cents ──
  /// Returns {'name': 'E', 'cents': -3.2, 'octave': 4, 'midiNote': 64}
  static Map<String, dynamic> frequencyToNote(double freq) {
    if (freq <= 0) return {'name': '', 'cents': 0.0, 'octave': 0, 'midiNote': 0};

    // MIDI note number (A4=440Hz, MIDI 69)
    final midiNote = 69 + 12 * log(freq / 440.0) / ln2;
    final roundedMidi = midiNote.round();
    final cents = (midiNote - roundedMidi) * 100;
    final noteIndex = roundedMidi % 12;
    final octave = (roundedMidi ~/ 12) - 1;
    final name = _noteNames[noteIndex];

    return {
      'name': name,
      'cents': cents,
      'octave': octave,
      'midiNote': roundedMidi,
    };
  }

  /// Calculate the frequency of a specific string+fret combination.
  /// stringNumber: 1-6 (1=high E, 6=low E)
  /// fret: 0-24
  static double frequencyForStringFret(int stringNumber, int fret) {
    const openFrequencies = {
      1: 329.63, // high E
      2: 246.94, // B
      3: 196.00, // G
      4: 146.83, // D
      5: 110.00, // A
      6: 82.41,  // low E
    };
    final openFreq = openFrequencies[stringNumber] ?? 329.63;
    return openFreq * pow(2, fret / 12.0);
  }

  /// Check if a detected frequency matches a target note on a specific string/fret.
  /// Uses ±50 cents tolerance.
  /// Also checks octave equivalents (e.g., same note name 12 frets apart).
  ///
  /// Returns true if the frequency is within tolerance of ANY fret on that string
  /// that produces the same note name.
  static bool isFrequencyMatch(
    double detectedFreq,
    int stringNumber,
    int targetFret, {
    double centsTolerance = 50.0,
    int maxFret = 24,
  }) {
    if (detectedFreq <= 0) return false;

    final targetNote = _noteNameAtFret(stringNumber, targetFret);

    // Find all frets on this string that produce the same note name
    final matchingFrets = <int>[];
    for (int f = 0; f <= maxFret; f++) {
      if (_noteNameAtFret(stringNumber, f) == targetNote) {
        matchingFrets.add(f);
      }
    }

    // Check if detected frequency is within tolerance of any matching fret
    for (final fret in matchingFrets) {
      final targetFreq = frequencyForStringFret(stringNumber, fret);
      final cents = 1200 * log(detectedFreq / targetFreq) / ln2;
      if (cents.abs() <= centsTolerance) {
        return true;
      }
    }

    return false;
  }

  /// Check if a detected frequency matches a target note NAME (any octave).
  /// Useful for scale practice where we only care about note name, not octave.
  static bool isNoteNameMatch(
    double detectedFreq,
    String targetNoteName, {
    double centsTolerance = 50.0,
  }) {
    if (detectedFreq <= 0) return false;

    final detected = frequencyToNote(detectedFreq);
    if (detected['name'] == targetNoteName) {
      // Check that cents are within tolerance of the nearest note
      return (detected['cents'] as double).abs() <= centsTolerance;
    }
    return false;
  }

  /// Get note name for a string+fret combination
  static String _noteNameAtFret(int stringNumber, int fret) {
    const openNotes = {1: 'E', 2: 'B', 3: 'G', 4: 'D', 5: 'A', 6: 'E'};
    final openNote = openNotes[stringNumber] ?? 'E';
    final startIdx = _noteNames.indexOf(openNote);
    return _noteNames[(startIdx + fret) % 12];
  }

  /// Calculate cents between detected and target frequency
  static double calculateCents(double detected, double target) {
    if (detected <= 0 || target <= 0) return 0;
    return 1200 * log(detected / target) / ln2;
  }
}
