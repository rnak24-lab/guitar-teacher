import 'dart:math';
import 'dart:typed_data';
import 'package:audioplayers/audioplayers.dart';

/// Generates and plays pure sine-wave tones at specified frequencies.
/// Used by the Tuner to let users hear the target pitch for each string.
class ToneGenerator {
  static final ToneGenerator _instance = ToneGenerator._();
  factory ToneGenerator() => _instance;
  ToneGenerator._();

  final AudioPlayer _player = AudioPlayer();
  bool _isPlaying = false;
  bool get isPlaying => _isPlaying;

  /// Play a sine-wave tone at the given frequency (Hz) for [durationMs] ms.
  /// Default duration is 2 seconds. Volume envelope includes a short
  /// fade-in/fade-out to avoid clicks.
  Future<void> playTone(double frequency, {int durationMs = 2000}) async {
    await stop();

    const sampleRate = 44100;
    final numSamples = (sampleRate * durationMs / 1000).round();
    final fadeInSamples = (sampleRate * 0.02).round(); // 20ms fade-in
    final fadeOutSamples = (sampleRate * 0.05).round(); // 50ms fade-out

    // Generate 16-bit PCM samples
    final samples = Int16List(numSamples);
    for (int i = 0; i < numSamples; i++) {
      double amplitude = 0.6; // base amplitude

      // Fade-in envelope
      if (i < fadeInSamples) {
        amplitude *= i / fadeInSamples;
      }
      // Fade-out envelope
      if (i > numSamples - fadeOutSamples) {
        amplitude *= (numSamples - i) / fadeOutSamples;
      }

      final sample = (amplitude * sin(2 * pi * frequency * i / sampleRate) * 32767).round();
      samples[i] = sample.clamp(-32767, 32767);
    }

    // Build WAV file in memory
    final wavBytes = _buildWav(samples, sampleRate);

    _isPlaying = true;
    try {
      await _player.setSource(BytesSource(wavBytes, mimeType: 'audio/wav'));
      await _player.resume();

      // Listen for completion
      _player.onPlayerComplete.first.then((_) {
        _isPlaying = false;
      });
    } catch (e) {
      _isPlaying = false;
    }
  }

  /// Stop any currently playing tone.
  Future<void> stop() async {
    if (_isPlaying) {
      await _player.stop();
      _isPlaying = false;
    }
  }

  void dispose() {
    _player.dispose();
  }

  /// Build a minimal WAV file from 16-bit mono PCM samples.
  Uint8List _buildWav(Int16List samples, int sampleRate) {
    final dataSize = samples.length * 2; // 16-bit = 2 bytes per sample
    final fileSize = 44 + dataSize; // 44-byte header + data

    final buffer = ByteData(fileSize);
    int offset = 0;

    // RIFF header
    buffer.setUint8(offset++, 0x52); // R
    buffer.setUint8(offset++, 0x49); // I
    buffer.setUint8(offset++, 0x46); // F
    buffer.setUint8(offset++, 0x46); // F
    buffer.setUint32(offset, fileSize - 8, Endian.little);
    offset += 4;
    buffer.setUint8(offset++, 0x57); // W
    buffer.setUint8(offset++, 0x41); // A
    buffer.setUint8(offset++, 0x56); // V
    buffer.setUint8(offset++, 0x45); // E

    // fmt sub-chunk
    buffer.setUint8(offset++, 0x66); // f
    buffer.setUint8(offset++, 0x6D); // m
    buffer.setUint8(offset++, 0x74); // t
    buffer.setUint8(offset++, 0x20); // (space)
    buffer.setUint32(offset, 16, Endian.little); // sub-chunk size
    offset += 4;
    buffer.setUint16(offset, 1, Endian.little); // PCM format
    offset += 2;
    buffer.setUint16(offset, 1, Endian.little); // mono
    offset += 2;
    buffer.setUint32(offset, sampleRate, Endian.little);
    offset += 4;
    buffer.setUint32(offset, sampleRate * 2, Endian.little); // byte rate
    offset += 4;
    buffer.setUint16(offset, 2, Endian.little); // block align
    offset += 2;
    buffer.setUint16(offset, 16, Endian.little); // bits per sample
    offset += 2;

    // data sub-chunk
    buffer.setUint8(offset++, 0x64); // d
    buffer.setUint8(offset++, 0x61); // a
    buffer.setUint8(offset++, 0x74); // t
    buffer.setUint8(offset++, 0x61); // a
    buffer.setUint32(offset, dataSize, Endian.little);
    offset += 4;

    // Write PCM samples
    for (int i = 0; i < samples.length; i++) {
      buffer.setInt16(offset, samples[i], Endian.little);
      offset += 2;
    }

    return buffer.buffer.asUint8List();
  }
}
