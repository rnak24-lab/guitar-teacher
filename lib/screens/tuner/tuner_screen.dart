import 'dart:math';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../services/pitch_detector.dart';
import '../../widgets/ad_banner_widget.dart';
import '../../data/tuning_presets.dart';
import '../../providers/note_name_provider.dart';
import '../../services/tone_generator.dart';

class TunerScreen extends StatefulWidget {
  const TunerScreen({super.key});

  @override
  State<TunerScreen> createState() => _TunerScreenState();
}

class _TunerScreenState extends State<TunerScreen> {
  // Tuning preset support
  TuningPreset _currentTuning = TuningPreset.all[0];
  late Map<String, double> _tuningMap;
  late List<String> _stringOrder;

  String _selectedString = '6E';
  double _detectedFrequency = 0;
  double _cents = 0;
  bool _autoAdvance = false;
  int _currentStringIndex = 0;

  // Tuner sensitivity (cents tolerance for "in tune")
  double _centsTolerance = 15.0;
  // Hold-to-confirm: track how long pitch stays in range
  DateTime? _inTuneSince;
  bool _showSuccess = false;
  static const _holdDuration = Duration(seconds: 2);

  // Tone generator for Play button
  final ToneGenerator _toneGenerator = ToneGenerator();

  // Shared pitch detector
  final PitchDetector _pitchDetector = PitchDetector();
  bool _permissionDenied = false;

  @override
  void initState() {
    super.initState();
    _applyTuning(_currentTuning);
    _loadTuningPreference();
    _pitchDetector.onPitchDetected = (freq, noteName, cents) {
      if (!mounted || _showSuccess) return;
      setState(() {
        _detectedFrequency = freq;
        _cents = PitchDetector.calculateCents(freq, _tuningMap[_selectedString]!);

        // Check if within tolerance
        if (_cents.abs() < _centsTolerance) {
          // Start or continue hold timer
          _inTuneSince ??= DateTime.now();
          final held = DateTime.now().difference(_inTuneSince!);
          if (held >= _holdDuration) {
            // Success!
            _showSuccess = true;
            if (_autoAdvance) {
              Future.delayed(const Duration(milliseconds: 800), () {
                if (mounted) {
                  setState(() => _showSuccess = false);
                  _advanceToNext();
                }
              });
            }
          }
        } else {
          // Out of range — reset hold
          _inTuneSince = null;
        }
      });
    };
  }

  @override
  void dispose() {
    _pitchDetector.dispose();
    _toneGenerator.dispose();
    super.dispose();
  }

  Future<void> _toggleListening() async {
    if (_pitchDetector.isListening) {
      await _pitchDetector.stopListening();
      setState(() {
        _detectedFrequency = 0;
        _cents = 0;
      });
    } else {
      final ok = await _pitchDetector.startListening();
      if (!ok) {
        setState(() => _permissionDenied = true);
        final isPermanent = await PitchDetector.isPermissionPermanentlyDenied();
        if (isPermanent && mounted) {
          _showPermissionDialog();
        }
      } else {
        setState(() => _permissionDenied = false);
      }
    }
    setState(() {});
  }

  void _showPermissionDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Microphone Permission'),
        content: const Text(
          'The tuner needs microphone access to detect pitch.\n'
          'Please enable it in your device settings.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              openAppSettings();
            },
            child: const Text('Open Settings'),
          ),
        ],
      ),
    );
  }

  void _selectString(String key) {
    setState(() {
      _selectedString = key;
      _currentStringIndex = _stringOrder.indexOf(key);
      _inTuneSince = null;
      _showSuccess = false;
    });
  }

  void _advanceToNext() {
    if (_currentStringIndex < _stringOrder.length - 1) {
      setState(() {
        _currentStringIndex++;
        _selectedString = _stringOrder[_currentStringIndex];
      });
    }
  }

  void _applyTuning(TuningPreset preset) {
    _currentTuning = preset;
    _tuningMap = preset.toFrequencyMap();
    _stringOrder = preset.stringLabels;
    _selectedString = _stringOrder[0];
    _currentStringIndex = 0;
  }

  Future<void> _loadTuningPreference() async {
    final prefs = await SharedPreferences.getInstance();
    final name = prefs.getString('tuner_preset') ?? 'Standard';
    final preset = TuningPreset.byName(name);
    setState(() => _applyTuning(preset));
  }

  Future<void> _changeTuning(TuningPreset preset) async {
    setState(() => _applyTuning(preset));
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('tuner_preset', preset.name);
  }

  double get _targetFreq => _tuningMap[_selectedString]!;

  @override
  Widget build(BuildContext context) {
    final isListening = _pitchDetector.isListening;
    final inTune = isListening && _cents.abs() < _centsTolerance;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Tuner'),
        actions: [
          Row(
            children: [
              const Text('Auto', style: TextStyle(fontSize: 12)),
              Switch(
                value: _autoAdvance,
                onChanged: (v) => setState(() => _autoAdvance = v),
                activeColor: Colors.white,
              ),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          // ── Tuning preset selector ──
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFFF0E4CC),
                borderRadius: BorderRadius.circular(22),
                border: Border.all(color: const Color(0xFFD4A017), width: 1.5),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: _currentTuning.name,
                  isExpanded: true,
                  icon: const Icon(Icons.arrow_drop_down, color: Color(0xFFD4A017)),
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF3D2B1F),
                  ),
                  dropdownColor: const Color(0xFFF0E4CC),
                  items: TuningPreset.all.map((preset) {
                    return DropdownMenuItem<String>(
                      value: preset.name,
                      child: Text(
                        '${preset.name}  (${preset.notes.join("-")})',
                        style: const TextStyle(fontSize: 14),
                      ),
                    );
                  }).toList(),
                  onChanged: (name) {
                    if (name != null) {
                      _changeTuning(TuningPreset.byName(name));
                    }
                  },
                ),
              ),
            ),
          ),

          const SizedBox(height: 8),

          // String selection buttons
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: _stringOrder.map((s) {
              final isSelected = s == _selectedString;
              return GestureDetector(
                onTap: () => _selectString(s),
                child: Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: isSelected
                        ? Colors.purple[700]
                        : const Color(0xFF8B6914),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Center(
                    child: Text(
                      NoteNameProvider().display(s.substring(1)),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),

          const SizedBox(height: 12),

          // Play reference tone button
          GestureDetector(
            onTap: () async {
              if (_toneGenerator.isPlaying) {
                await _toneGenerator.stop();
                setState(() {});
              } else {
                final freq = _tuningMap[_selectedString]!;
                await _toneGenerator.playTone(freq);
                setState(() {});
              }
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              decoration: BoxDecoration(
                color: _toneGenerator.isPlaying
                    ? Colors.orange[700]
                    : const Color(0xFF5D3A00).withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: _toneGenerator.isPlaying
                      ? Colors.orange
                      : const Color(0xFF8B6914),
                  width: 1.5,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    _toneGenerator.isPlaying ? Icons.stop : Icons.volume_up,
                    size: 20,
                    color: _toneGenerator.isPlaying ? Colors.white : const Color(0xFF5D3A00),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    _toneGenerator.isPlaying
                        ? 'Stop'
                        : 'Play ${NoteNameProvider().display(_selectedString.substring(1))} (${_targetFreq.toStringAsFixed(1)} Hz)',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: _toneGenerator.isPlaying ? Colors.white : const Color(0xFF5D3A00),
                    ),
                  ),
                ],
              ),
            ),
          ),

          const Spacer(),

          // Permission denied notice
          if (_permissionDenied)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                children: [
                  const Icon(Icons.mic_off, size: 48, color: Colors.red),
                  const SizedBox(height: 8),
                  const Text(
                    'Microphone permission required',
                    style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.red),
                  ),
                  const SizedBox(height: 4),
                  TextButton(
                    onPressed: () => openAppSettings(),
                    child: const Text('Enable in Settings'),
                  ),
                ],
              ),
            ),

          // Tuner dial
          SizedBox(
            width: 260,
            height: 260,
            child: CustomPaint(
              painter:
                  _TunerDialPainter(cents: isListening ? _cents : 0),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      NoteNameProvider().display(_selectedString.substring(1)),
                      style: TextStyle(
                        fontSize: 64,
                        fontWeight: FontWeight.bold,
                        color: isListening
                            ? (inTune ? Colors.green : Colors.red)
                            : Colors.brown,
                      ),
                    ),
                    if (isListening && _detectedFrequency > 0) ...[
                      Text(
                        '${_detectedFrequency.toStringAsFixed(1)} Hz',
                        style: const TextStyle(
                            fontSize: 16, color: Colors.grey),
                      ),
                      Text(
                        'Target: ${_targetFreq.toStringAsFixed(1)} Hz',
                        style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[500]),
                      ),
                      const SizedBox(height: 4),
                      if (_showSuccess)
                        const Text(
                          'Perfect!',
                          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.green),
                        )
                      else
                        Text(
                          _cents.abs() < _centsTolerance
                              ? 'In Tune! Hold...'
                              : _cents > 0
                                  ? '${_cents.toStringAsFixed(0)}c sharp'
                                  : '${_cents.abs().toStringAsFixed(0)}c flat',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: inTune ? Colors.green : Colors.red,
                          ),
                        ),
                    ],
                    if (isListening && _detectedFrequency <= 0)
                      const Text(
                        'Detecting...',
                        style: TextStyle(
                            fontSize: 14, color: Colors.grey),
                      ),
                  ],
                ),
              ),
            ),
          ),

          const Spacer(),

          // Mic button
          GestureDetector(
            onTap: _toggleListening,
            child: Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: isListening ? Colors.red : Colors.purple[700],
                shape: BoxShape.circle,
              ),
              child: Icon(
                isListening ? Icons.mic_off : Icons.mic,
                color: Colors.white,
                size: 36,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            isListening ? 'Listening...' : 'Tap to start',
            style: const TextStyle(color: Colors.grey),
          ),
          if (_autoAdvance)
            const Text(
              'Auto: advances when in tune',
              style: TextStyle(color: Colors.purple, fontSize: 12),
            ),
          const SizedBox(height: 16),

          const AdBannerWidget(),
        ],
      ),
    );
  }
}

// Tuner dial painter
class _TunerDialPainter extends CustomPainter {
  final double cents;
  _TunerDialPainter({required this.cents});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 10;

    final bgPaint = Paint()
      ..color = const Color(0xFF5D3A00).withValues(alpha: 0.15)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4;
    canvas.drawCircle(center, radius, bgPaint);

    for (int i = -5; i <= 5; i++) {
      final angle = (i / 5) * 1.2 - pi / 2;
      final s = radius - 15;
      final e = radius - 5;
      final p = Paint()
        ..color =
            i == 0 ? Colors.green : Colors.brown.withValues(alpha: 0.3)
        ..strokeWidth = i == 0 ? 3 : 1;
      canvas.drawLine(
        Offset(center.dx + s * cos(angle), center.dy + s * sin(angle)),
        Offset(center.dx + e * cos(angle), center.dy + e * sin(angle)),
        p,
      );
    }

    if (cents != 0) {
      final angle = (cents / 50).clamp(-1.0, 1.0) * 1.2 - pi / 2;
      final np = Paint()
        ..color = cents.abs() < 15 ? Colors.green : Colors.red
        ..strokeWidth = 3
        ..strokeCap = StrokeCap.round;
      canvas.drawLine(
        center,
        Offset(center.dx + (radius - 30) * cos(angle),
            center.dy + (radius - 30) * sin(angle)),
        np,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _TunerDialPainter old) =>
      old.cents != cents;
}
