import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../models/note.dart';
import '../../models/guitar_string.dart';
import '../../services/practice_record.dart';
import '../../services/pitch_detector.dart';

/// Continuous "Play X" note finder - no start button, runs immediately
/// Now with microphone support + Auto mode.
class FretboardSetup extends StatefulWidget {
  const FretboardSetup({super.key});

  @override
  State<FretboardSetup> createState() => _FretboardSetupState();
}

class _FretboardSetupState extends State<FretboardSetup> with TickerProviderStateMixin {
  final _random = Random();

  // Settings (always visible at bottom)
  double _seconds = 5;
  final Set<int> _selectedStrings = {1, 2, 3, 4, 5, 6};
  bool _soundEnabled = true;
  bool _showSettings = false;

  // Current note state
  String _currentNote = '';
  int _currentString = 1;
  Timer? _timer;
  int _timeLeft = 5;
  int _score = 0;
  int _total = 0;
  bool _showAnswer = false;
  List<int> _correctFrets = [];
  final Stopwatch _stopwatch = Stopwatch();

  // Auto-reveal answer settings
  bool _autoRevealAnswer = false;
  int _autoRevealDelay = 2;
  Timer? _autoRevealTimer;

  // ── Microphone / Auto mode ──
  final PitchDetector _pitchDetector = PitchDetector();
  bool _micEnabled = false;
  bool _autoMode = false;
  double _detectedFrequency = 0;
  String _detectedNote = '';

  // Animation
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(duration: const Duration(milliseconds: 400), vsync: this);
    _fadeAnimation = CurvedAnimation(parent: _fadeController, curve: Curves.easeInOut);
    _stopwatch.start();

    _pitchDetector.onPitchDetected = (freq, noteName, cents) {
      if (!mounted || _showAnswer) return;
      setState(() {
        _detectedFrequency = freq;
        _detectedNote = noteName;
      });

      if (_micEnabled && !_showAnswer) {
        // Check if detected frequency matches the target note on the current string
        // A/B matching: any fret that produces the same note name is accepted
        bool matched = false;
        for (final fret in _correctFrets) {
          if (PitchDetector.isFrequencyMatch(
            freq,
            _currentString,
            fret,
            centsTolerance: 50,
          )) {
            matched = true;
            break;
          }
        }

        // Also accept generic note name match (any octave)
        if (!matched) {
          matched = PitchDetector.isNoteNameMatch(freq, _currentNote, centsTolerance: 50);
        }

        if (matched) {
          _score++;
          _total++;
          HapticFeedback.mediumImpact();
          if (_autoMode) {
            _nextNote();
          } else {
            setState(() => _showAnswer = true);
            Future.delayed(const Duration(seconds: 1), () {
              if (mounted) _nextNote();
            });
          }
        }
      }
    };

    _nextNote();
  }

  void _nextNote() {
    final strings = _selectedStrings.toList();
    if (strings.isEmpty) return;

    _currentString = strings[_random.nextInt(strings.length)];
    _currentNote = Note.allNotes[_random.nextInt(12)];

    final gs = GuitarString.standard.firstWhere((s) => s.number == _currentString);
    _correctFrets = Note.allFretsForNote(gs.openNote, _currentNote);

    _timeLeft = _seconds.toInt();
    _showAnswer = false;
    _autoRevealTimer?.cancel();
    _detectedFrequency = 0;
    _detectedNote = '';

    _fadeController.forward(from: 0);

    // Auto-reveal answer if enabled
    if (_autoRevealAnswer) {
      if (_autoRevealDelay == 0) {
        _showAnswer = true;
      } else {
        _autoRevealTimer = Timer(Duration(seconds: _autoRevealDelay), () {
          if (mounted) setState(() => _showAnswer = true);
        });
      }
    }

    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      setState(() {
        _timeLeft--;
        if (_timeLeft <= 0) {
          _total++;
          _nextNote();
        }
      });
    });

    if (_soundEnabled) {
      HapticFeedback.lightImpact();
    }

    setState(() {});
  }

  void _onFretTap(int fret) {
    if (_showAnswer) return;
    _total++;
    if (_correctFrets.contains(fret)) {
      _score++;
      HapticFeedback.mediumImpact();
      _nextNote();
    } else {
      setState(() => _showAnswer = true);
      Future.delayed(const Duration(seconds: 2), () {
        if (mounted) _nextNote();
      });
    }
  }

  Future<void> _toggleMic() async {
    if (_micEnabled) {
      await _pitchDetector.stopListening();
      setState(() {
        _micEnabled = false;
        _detectedFrequency = 0;
        _detectedNote = '';
      });
    } else {
      final ok = await _pitchDetector.startListening();
      if (ok) {
        setState(() => _micEnabled = true);
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Microphone permission required')),
          );
        }
      }
    }
  }

  void _toggleSettings() {
    setState(() => _showSettings = !_showSettings);
  }

  Future<void> _saveAndExit() async {
    _stopwatch.stop();
    _timer?.cancel();
    await _pitchDetector.stopListening();
    await PracticeRecord.saveSession(PracticeSession(
      type: 'fretboard',
      timestamp: DateTime.now(),
      durationSeconds: _stopwatch.elapsed.inSeconds,
    ));
    if (mounted) Navigator.pop(context);
  }

  Widget _stepBtn(IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 30, height: 30,
        decoration: BoxDecoration(
          color: Colors.grey[300],
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, size: 18, color: Colors.grey[700]),
      ),
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    _autoRevealTimer?.cancel();
    _fadeController.dispose();
    _pitchDetector.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final gs = GuitarString.standard.firstWhere((s) => s.number == _currentString);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Note Finder'),
        leading: IconButton(icon: const Icon(Icons.close), onPressed: _saveAndExit),
        actions: [
          // Mic toggle
          IconButton(
            icon: Icon(
              _micEnabled ? Icons.mic : Icons.mic_off,
              color: _micEnabled ? Colors.purple[300] : null,
            ),
            onPressed: _toggleMic,
            tooltip: _micEnabled ? 'Disable mic' : 'Enable mic',
          ),
          // Auto toggle (visible when mic is on)
          if (_micEnabled)
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('Auto', style: TextStyle(fontSize: 12)),
                Switch(
                  value: _autoMode,
                  onChanged: (v) => setState(() => _autoMode = v),
                  activeColor: Colors.green,
                ),
              ],
            ),
          // Score display
          Center(child: Padding(
            padding: const EdgeInsets.only(right: 8),
            child: Text('$_score/$_total', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          )),
          IconButton(
            icon: Icon(_showSettings ? Icons.expand_less : Icons.tune),
            onPressed: _toggleSettings,
          ),
        ],
      ),
      body: Column(
        children: [
          // Timer bar
          LinearProgressIndicator(
            value: _timeLeft / _seconds,
            backgroundColor: isDark ? Colors.grey[800] : Colors.grey[300],
            valueColor: AlwaysStoppedAnimation(
              _timeLeft > _seconds * 0.3 ? const Color(0xFF4A90D9) : Colors.red),
            minHeight: 6,
          ),

          // Mic status bar
          if (_micEnabled)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              color: Colors.purple.withValues(alpha: 0.08),
              child: Row(
                children: [
                  Icon(Icons.mic, size: 16, color: Colors.purple[400]),
                  const SizedBox(width: 6),
                  if (_detectedFrequency > 0)
                    Text(
                      '$_detectedNote  ${_detectedFrequency.toStringAsFixed(0)}Hz',
                      style: TextStyle(fontSize: 13, color: Colors.purple[600]),
                    )
                  else
                    Text('Play the note...', style: TextStyle(fontSize: 13, color: Colors.grey[500])),
                  if (_autoMode) ...[
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.green.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Text('AUTO', style: TextStyle(fontSize: 10, color: Colors.green, fontWeight: FontWeight.bold)),
                    ),
                  ],
                ],
              ),
            ),

          // Main content: Play X card
          Expanded(
            flex: 3,
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                      decoration: BoxDecoration(
                        color: const Color(0xFF4A90D9).withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        'String ${gs.number} (${gs.openNote})',
                        style: TextStyle(fontSize: 16, color: isDark ? Colors.blue[200] : const Color(0xFF4A90D9)),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text('Play', style: TextStyle(fontSize: 28, color: Colors.grey[500])),
                    Text(
                      _currentNote,
                      style: const TextStyle(fontSize: 160, fontWeight: FontWeight.bold, color: Color(0xFF4A90D9), height: 1.1),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${_timeLeft}s',
                      style: TextStyle(fontSize: 24, color: _timeLeft > 2 ? Colors.grey[400] : Colors.red, fontWeight: FontWeight.w500),
                    ),
                    if (_showAnswer)
                      Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Text(
                          'Fret ${_correctFrets.join(", ")}',
                          style: TextStyle(fontSize: 20, color: Colors.green[600], fontWeight: FontWeight.bold),
                        ),
                      ),
                    if (_micEnabled)
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(
                          'Tap a fret OR play the note on guitar',
                          style: TextStyle(fontSize: 12, color: Colors.grey[500], fontStyle: FontStyle.italic),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),

          // Fret selection grid
          Expanded(
            flex: 2,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: GridView.builder(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 7, crossAxisSpacing: 4, mainAxisSpacing: 4, childAspectRatio: 1.3,
                ),
                itemCount: 13,
                itemBuilder: (context, fret) {
                  final isCorrect = _correctFrets.contains(fret);
                  final noteAtFret = Note.noteAtFret(gs.openNote, fret);
                  Color bgColor = isDark ? const Color(0xFF2A2A2A) : Colors.grey[100]!;
                  if (_showAnswer && isCorrect) bgColor = Colors.green[300]!;

                  return Material(
                    color: bgColor,
                    borderRadius: BorderRadius.circular(10),
                    elevation: 1,
                    child: InkWell(
                      onTap: _showAnswer ? null : () => _onFretTap(fret),
                      borderRadius: BorderRadius.circular(10),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text('$fret', style: TextStyle(
                            fontSize: 20, fontWeight: FontWeight.bold,
                            color: fret == 0 ? Colors.red : (isDark ? Colors.white : Colors.black))),
                          if (_showAnswer)
                            Text(noteAtFret, style: TextStyle(
                              fontSize: 10, color: isCorrect ? Colors.green[800] : Colors.grey)),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ),

          // Collapsible settings panel
          if (_showSettings)
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E1E1E) : Colors.grey[100],
                border: Border(top: BorderSide(color: Colors.grey[300]!)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Time presets + stepper
                  Row(
                    children: [
                      const Icon(Icons.timer, size: 18),
                      const SizedBox(width: 6),
                      _stepBtn(Icons.remove, () {
                        if (_seconds > 1) setState(() => _seconds--);
                      }),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        child: Text('${_seconds.toInt()}s',
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      ),
                      _stepBtn(Icons.add, () {
                        if (_seconds < 60) setState(() => _seconds++);
                      }),
                      const SizedBox(width: 8),
                      ...[3, 5, 8, 10, 15].map((s) => Padding(
                        padding: const EdgeInsets.only(right: 4),
                        child: GestureDetector(
                          onTap: () => setState(() => _seconds = s.toDouble()),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: _seconds.toInt() == s
                                  ? const Color(0xFF8B6914) : Colors.grey[300],
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text('${s}s', style: TextStyle(
                              fontSize: 12, fontWeight: FontWeight.bold,
                              color: _seconds.toInt() == s ? Colors.white : Colors.grey[700])),
                          ),
                        ),
                      )),
                    ],
                  ),
                  // Strings
                  Wrap(
                    spacing: 6,
                    children: List.generate(6, (i) {
                      final sn = i + 1;
                      final labels = ['1E', '2B', '3G', '4D', '5A', '6E'];
                      return FilterChip(
                        label: Text(labels[i], style: const TextStyle(fontSize: 12)),
                        selected: _selectedStrings.contains(sn),
                        visualDensity: VisualDensity.compact,
                        onSelected: (sel) {
                          setState(() {
                            if (sel) { _selectedStrings.add(sn); }
                            else if (_selectedStrings.length > 1) { _selectedStrings.remove(sn); }
                          });
                        },
                      );
                    }),
                  ),
                  const SizedBox(height: 4),
                  // Sound toggle
                  Row(
                    children: [
                      Icon(_soundEnabled ? Icons.volume_up : Icons.volume_off, size: 18),
                      const SizedBox(width: 8),
                      const Text('Note Sound'),
                      const Spacer(),
                      Switch(
                        value: _soundEnabled,
                        activeColor: const Color(0xFF4A90D9),
                        onChanged: (v) => setState(() => _soundEnabled = v),
                      ),
                    ],
                  ),
                  // Auto-reveal answer setting
                  Row(
                    children: [
                      const Icon(Icons.auto_awesome, size: 18, color: Color(0xFF4A90D9)),
                      const SizedBox(width: 8),
                      const Text('Auto Reveal'),
                      Switch(
                        value: _autoRevealAnswer,
                        activeColor: const Color(0xFF4A90D9),
                        onChanged: (v) => setState(() => _autoRevealAnswer = v),
                      ),
                      if (_autoRevealAnswer) ...[
                        const Text('Delay:', style: TextStyle(fontSize: 12)),
                        const SizedBox(width: 4),
                        ...[0, 1, 2, 3].map((s) => Padding(
                          padding: const EdgeInsets.only(right: 4),
                          child: GestureDetector(
                            onTap: () => setState(() => _autoRevealDelay = s),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: _autoRevealDelay == s ? const Color(0xFF4A90D9) : Colors.grey[300],
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text('${s}s', style: TextStyle(
                                fontSize: 12, fontWeight: FontWeight.bold,
                                color: _autoRevealDelay == s ? Colors.white : Colors.grey[700])),
                            ),
                          ),
                        )),
                      ],
                    ],
                  ),
                ],
              ),
            ),

          // AD Banner
          Container(
            height: 50, width: double.infinity,
            color: isDark ? Colors.grey[900] : Colors.grey[200],
            child: Center(child: Text('AD BANNER', style: TextStyle(color: isDark ? Colors.grey[700] : Colors.grey, fontSize: 11))),
          ),
        ],
      ),
    );
  }
}
