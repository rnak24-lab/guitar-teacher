import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import '../../models/scale.dart';
import '../../models/note.dart';
import '../../models/guitar_string.dart';
import '../../services/practice_record.dart';
import '../../services/pitch_detector.dart';
import '../../widgets/ad_banner_widget.dart';
import '../../services/ad_service.dart';
import '../../services/tone_generator.dart';
import '../../providers/note_name_provider.dart';

/// Circle-of-fourths order
const _quizCircleOf4ths = ['C','F','Bb','Eb','Ab','Db','Gb','B','E','A','D','G'];

/// Circle-of-fifths order
const _quizCircleOf5ths = ['C','G','D','A','E','B','F#','Db','Ab','Eb','Bb','F'];

/// Quiz Mode: Random scale quiz - identify/play scale notes
/// Now supports microphone input: play the note on guitar instead of tapping fret buttons.
/// Supports circle-of-4ths/5ths sequential quiz ordering.
class ScaleQuiz extends StatefulWidget {
  final String rootNote;
  final String scaleName;
  final int startFret;
  final int endFret;
  final List<bool>? enabledStrings;
  /// null = random, '4th' = circle of 4ths order, '5th' = circle of 5ths order
  final String? circleMode;

  const ScaleQuiz({
    super.key,
    required this.rootNote,
    required this.scaleName,
    required this.startFret,
    required this.endFret,
    this.enabledStrings,
    this.circleMode,
  });

  @override
  State<ScaleQuiz> createState() => _ScaleQuizState();
}

class _ScaleQuizState extends State<ScaleQuiz> {
  final _random = Random();
  late ScaleData _scale;
  late List<String> _scaleNotes;

  // Quiz state
  int _totalQuestions = 0;
  int _correctAnswers = 0;
  bool _showAnswer = false;
  bool _answered = false;
  String _questionNote = '';
  int _questionString = 1;
  List<int> _correctFrets = [];
  int? _selectedFret;
  final Stopwatch _stopwatch = Stopwatch();

  // ── Microphone / Auto mode ──
  final PitchDetector _pitchDetector = PitchDetector();
  bool _micEnabled = false;
  bool _autoMode = false;
  double _detectedFrequency = 0;
  String _detectedNote = '';
  String _pitchHint = ''; // 'low', 'high', or '' — guides user

  // ── Auto-advance timer (3-second quiz) ──
  bool _autoTimerEnabled = false;
  Timer? _autoTimer;
  int _autoTimeLeft = 3;

  // ── Circle-of-4ths/5ths sequential quiz ordering ──
  List<String>? _circleOrder;
  int _circleIndex = 0;

  // ── Play reference tone for unselected strings ──
  final ToneGenerator _toneGenerator = ToneGenerator();
  bool _isPlayingRefTone = false;

  @override
  void initState() {
    super.initState();
    _scale = ScaleData.byName(widget.scaleName);
    _scaleNotes = _scale.notesForRoot(widget.rootNote);
    _stopwatch.start();

    // Setup circle-of-4ths/5ths sequential ordering if specified
    if (widget.circleMode == '4th') {
      _circleOrder = _quizCircleOf4ths;
      _circleIndex = 0;
    } else if (widget.circleMode == '5th') {
      _circleOrder = _quizCircleOf5ths;
      _circleIndex = 0;
    }

    _pitchDetector.onPitchDetected = (freq, noteName, cents) {
      if (!mounted || _answered) return;
      setState(() {
        _detectedFrequency = freq;
        _detectedNote = noteName;
      });

      // Check if detected note matches any correct fret's note
      if (_micEnabled && !_answered) {
        bool matched = false;
        for (final fret in _correctFrets) {
          if (PitchDetector.isFrequencyMatch(
            freq,
            _questionString,
            fret,
            centsTolerance: 50,
            maxFret: widget.endFret,
          )) {
            matched = true;
            break;
          }
        }

        // Also accept: same note name match (any string/octave)
        if (!matched) {
          matched = PitchDetector.isNoteNameMatch(freq, _questionNote, centsTolerance: 50);
        }

        if (matched) {
          setState(() => _pitchHint = '');
          _handleCorrectMicAnswer();
        } else if (freq > 0 && _correctFrets.isNotEmpty) {
          // Show low/high hint based on closest correct fret frequency
          final targetFreq = PitchDetector.frequencyForStringFret(
            _questionString, _correctFrets.first,
          );
          final centsOff = PitchDetector.calculateCents(freq, targetFreq);
          setState(() {
            if (centsOff < -80) {
              _pitchHint = 'low';
            } else if (centsOff > 80) {
              _pitchHint = 'high';
            } else {
              _pitchHint = '';
            }
          });
        }
      }
    };

    _nextQuestion();
  }

  @override
  void dispose() {
    _autoTimer?.cancel();
    _pitchDetector.dispose();
    _toneGenerator.dispose();
    super.dispose();
  }

  void _handleCorrectMicAnswer() {
    if (_answered) return;
    _answered = true;
    _correctAnswers++;
    _totalQuestions++;
    setState(() {});

    if (_autoMode) {
      Future.delayed(const Duration(milliseconds: 600), () {
        if (mounted) _nextQuestion();
      });
    }
  }

  void _startAutoTimer() {
    _autoTimer?.cancel();
    if (!_autoTimerEnabled) return;
    _autoTimeLeft = 3;
    _autoTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) { timer.cancel(); return; }
      setState(() => _autoTimeLeft--);
      if (_autoTimeLeft <= 0) {
        timer.cancel();
        if (!_answered) {
          // Time expired — show answer then move on
          setState(() { _showAnswer = true; _answered = true; });
          Future.delayed(const Duration(milliseconds: 800), () {
            if (mounted) _nextQuestion();
          });
        }
      }
    });
  }

  void _nextQuestion() {
    // In circle mode, use sequential root note ordering
    if (_circleOrder != null) {
      _questionNote = _circleOrder![_circleIndex % _circleOrder!.length];
      // Handle enharmonic: F# -> Gb for internal note matching
      const enharmonic = {'F#': 'Gb'};
      _questionNote = enharmonic[_questionNote] ?? _questionNote;
      _circleIndex++;
    } else {
      _questionNote = _scaleNotes[_random.nextInt(_scaleNotes.length)];
    }

    // Pick only from enabled strings
    final enabled = widget.enabledStrings ?? List.filled(6, true);
    final availableStrings = <int>[];
    for (int i = 0; i < 6; i++) {
      if (enabled[i]) availableStrings.add(i + 1);
    }
    if (availableStrings.isEmpty) availableStrings.addAll([1, 2, 3, 4, 5, 6]);
    _questionString = availableStrings[_random.nextInt(availableStrings.length)];
    final gs = GuitarString.standard.firstWhere((s) => s.number == _questionString);
    _correctFrets = [];
    for (int f = widget.startFret; f <= widget.endFret; f++) {
      if (Note.noteAtFret(gs.openNote, f) == _questionNote) {
        _correctFrets.add(f);
      }
    }
    if (_correctFrets.isEmpty) {
      _nextQuestion();
      return;
    }
    _selectedFret = null;
    _showAnswer = false;
    _answered = false;
    _detectedFrequency = 0;
    _detectedNote = '';
    _pitchHint = '';
    _isPlayingRefTone = false;
    if (!_micEnabled) _totalQuestions++;
    _startAutoTimer();
    setState(() {});
  }

  /// Play reference tone for the target note (for unselected-string play mode)
  Future<void> _playReferenceTone() async {
    if (_correctFrets.isEmpty) return;
    final freq = PitchDetector.frequencyForStringFret(
      _questionString, _correctFrets.first,
    );
    setState(() => _isPlayingRefTone = true);
    await _toneGenerator.playTone(freq, durationMs: 1500);
    if (mounted) setState(() => _isPlayingRefTone = false);
  }

  void _checkAnswer(int fret) {
    if (_answered) return;
    _selectedFret = fret;
    _answered = true;
    if (_correctFrets.contains(fret)) {
      _correctAnswers++;
    }
    if (_micEnabled && _autoMode && _correctFrets.contains(fret)) {
      Future.delayed(const Duration(milliseconds: 600), () {
        if (mounted) _nextQuestion();
      });
    }
    setState(() {});
  }

  void _toggleShowAnswer() {
    setState(() => _showAnswer = !_showAnswer);
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

  Future<void> _endQuiz() async {
    _stopwatch.stop();
    await _pitchDetector.stopListening();
    await PracticeRecord.saveSession(PracticeSession(
      type: 'scale',
      timestamp: DateTime.now(),
      durationSeconds: _stopwatch.elapsed.inSeconds,
    ));
    AdService().onPracticeComplete();
    if (mounted) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text('Quiz Complete!'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('$_correctAnswers / $_totalQuestions correct',
                style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Text('Accuracy: ${(_totalQuestions > 0 ? _correctAnswers / _totalQuestions * 100 : 0).toStringAsFixed(1)}%'),
              Text('Time: ${_stopwatch.elapsed.inMinutes}m ${_stopwatch.elapsed.inSeconds % 60}s'),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () { Navigator.pop(ctx); Navigator.pop(context); },
              child: const Text('Done'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(ctx);
                setState(() {
                  _totalQuestions = 0;
                  _correctAnswers = 0;
                  _stopwatch.reset();
                  _stopwatch.start();
                  _nextQuestion();
                });
              },
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isCorrect = _answered && (_correctFrets.contains(_selectedFret) ||
        (_micEnabled && _correctAnswers > 0 && _selectedFret == null));

    // For mic-only correct answers
    final isMicCorrect = _answered && _selectedFret == null && _micEnabled;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Quiz: ${widget.rootNote} ${widget.scaleName}',
          overflow: TextOverflow.ellipsis,
        ),
        actions: [
          // Auto-advance timer toggle (3-second quiz)
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('3s', style: TextStyle(fontSize: 11)),
              SizedBox(
                width: 40,
                child: FittedBox(
                  child: Switch(
                    value: _autoTimerEnabled,
                    onChanged: (v) {
                      setState(() => _autoTimerEnabled = v);
                      if (v) _startAutoTimer(); else _autoTimer?.cancel();
                    },
                    activeColor: Colors.orange,
                  ),
                ),
              ),
            ],
          ),
          // Mic auto toggle
          if (_micEnabled)
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('Auto', style: TextStyle(fontSize: 11)),
                SizedBox(
                  width: 40,
                  child: FittedBox(
                    child: Switch(
                      value: _autoMode,
                      onChanged: (v) => setState(() => _autoMode = v),
                      activeColor: Colors.green,
                    ),
                  ),
                ),
              ],
            ),
          TextButton(
            onPressed: _endQuiz,
            child: const Text('End', style: TextStyle(color: Colors.white, fontSize: 14)),
          ),
        ],
      ),
      body: Column(
        children: [
          // Score bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            color: isDark ? const Color(0xFF1E1E1E) : Colors.brown[50],
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Q$_totalQuestions', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                Row(
                  children: [
                    // Mic toggle button
                    IconButton(
                      icon: Icon(
                        _micEnabled ? Icons.mic : Icons.mic_off,
                        color: _micEnabled ? Colors.purple : Colors.grey,
                      ),
                      onPressed: _toggleMic,
                      tooltip: _micEnabled ? 'Disable microphone' : 'Enable microphone',
                      iconSize: 20,
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                    ),
                    const SizedBox(width: 8),
                    Text('$_correctAnswers / $_totalQuestions',
                      style: TextStyle(fontSize: 16, color: Colors.green[700])),
                  ],
                ),
              ],
            ),
          ),

          // Mic status bar
          if (_micEnabled)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              color: isMicCorrect
                  ? Colors.green.withValues(alpha: 0.15)
                  : Colors.purple.withValues(alpha: 0.08),
              child: Row(
                children: [
                  Icon(Icons.mic, size: 16, color: Colors.purple[400]),
                  const SizedBox(width: 6),
                  if (_detectedFrequency > 0) ...[
                    Text(
                      '$_detectedNote  ${_detectedFrequency.toStringAsFixed(0)}Hz',
                      style: TextStyle(fontSize: 13, color: Colors.purple[600]),
                    ),
                    if (_pitchHint.isNotEmpty) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: _pitchHint == 'low' ? Colors.blue.withValues(alpha: 0.15) : Colors.red.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              _pitchHint == 'low' ? Icons.arrow_downward : Icons.arrow_upward,
                              size: 14,
                              color: _pitchHint == 'low' ? Colors.blue : Colors.red,
                            ),
                            const SizedBox(width: 2),
                            Text(
                              _pitchHint == 'low' ? 'Too low' : 'Too high',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: _pitchHint == 'low' ? Colors.blue : Colors.red,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ] else
                    Text('Play the note on your guitar...', style: TextStyle(fontSize: 13, color: Colors.grey[500])),
                  if (_autoMode) ...[
                    const Spacer(),
                    const Text('AUTO', style: TextStyle(fontSize: 10, color: Colors.green, fontWeight: FontWeight.bold)),
                  ],
                ],
              ),
            ),

          // Circle mode indicator
          if (widget.circleMode != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              color: Colors.orange.withValues(alpha: 0.1),
              child: Row(
                children: [
                  Icon(Icons.loop, size: 14, color: Colors.orange[700]),
                  const SizedBox(width: 6),
                  Text(
                    widget.circleMode == '4th' ? 'Circle of 4ths Order' : 'Circle of 5ths Order',
                    style: TextStyle(fontSize: 12, color: Colors.orange[700], fontWeight: FontWeight.w600),
                  ),
                  const Spacer(),
                  Text('${(_circleIndex - 1) % (_circleOrder?.length ?? 12) + 1}/12',
                    style: TextStyle(fontSize: 12, color: Colors.orange[600])),
                ],
              ),
            ),

          // Question
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                Text('Where is', style: TextStyle(fontSize: 18, color: Colors.grey[600])),
                const SizedBox(height: 4),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(NoteNameProvider().display(_questionNote),
                      style: TextStyle(
                        fontSize: 64, fontWeight: FontWeight.bold,
                        color: isMicCorrect ? Colors.green : const Color(0xFF8B6914),
                      )),
                    const SizedBox(width: 8),
                    // Play reference tone button
                    IconButton(
                      onPressed: _isPlayingRefTone ? null : _playReferenceTone,
                      icon: Icon(
                        _isPlayingRefTone ? Icons.volume_up : Icons.play_circle_outline,
                        size: 32,
                        color: _isPlayingRefTone ? Colors.green : const Color(0xFF8B6914),
                      ),
                      tooltip: 'Play reference tone',
                    ),
                  ],
                ),
                Text('on String $_questionString?',
                  style: TextStyle(fontSize: 20, color: isDark ? Colors.grey[300] : Colors.brown[600])),
                if (_autoTimerEnabled && !_answered)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      '$_autoTimeLeft',
                      style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold,
                        color: _autoTimeLeft <= 1 ? Colors.red : Colors.orange),
                    ),
                  ),
                if (_micEnabled)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      'Tap a fret OR play the note',
                      style: TextStyle(fontSize: 12, color: Colors.grey[500], fontStyle: FontStyle.italic),
                    ),
                  ),
              ],
            ),
          ),
          // Fret buttons
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: GridView.builder(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 5,
                  crossAxisSpacing: 8,
                  mainAxisSpacing: 8,
                  childAspectRatio: 1.4,
                ),
                itemCount: widget.endFret - widget.startFret + 1,
                itemBuilder: (ctx, idx) {
                  final fret = widget.startFret + idx;
                  final isCorrectFret = _correctFrets.contains(fret);
                  final isSelected = _selectedFret == fret;

                  Color bgColor;
                  if (_answered) {
                    if (isCorrectFret && (_showAnswer || isSelected || isMicCorrect)) {
                      bgColor = Colors.green;
                    } else if (isSelected && !isCorrectFret) {
                      bgColor = Colors.red;
                    } else {
                      bgColor = isDark ? Colors.grey[800]! : Colors.grey[200]!;
                    }
                  } else {
                    bgColor = isDark ? Colors.grey[800]! : Colors.grey[200]!;
                  }

                  return Material(
                    color: bgColor,
                    borderRadius: BorderRadius.circular(12),
                    child: InkWell(
                      onTap: () => _checkAnswer(fret),
                      borderRadius: BorderRadius.circular(12),
                      child: Center(
                        child: Text(
                          '$fret',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: (_answered && (isCorrectFret && (_showAnswer || isSelected || isMicCorrect)) || (isSelected && !isCorrectFret))
                                ? Colors.white
                                : isDark ? Colors.white : Colors.brown[800],
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
          // Direct fret input (type answer instead of tapping)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Row(
              children: [
                Icon(Icons.keyboard, size: 18, color: Colors.grey[500]),
                const SizedBox(width: 8),
                Expanded(
                  child: SizedBox(
                    height: 40,
                    child: TextField(
                      enabled: !_answered,
                      keyboardType: TextInputType.number,
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      decoration: InputDecoration(
                        hintText: 'Type fret number...',
                        hintStyle: TextStyle(fontSize: 14, color: Colors.grey[400]),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        isDense: true,
                      ),
                      onSubmitted: (value) {
                        final fret = int.tryParse(value.trim());
                        if (fret != null && fret >= widget.startFret && fret <= widget.endFret) {
                          _checkAnswer(fret);
                        }
                      },
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Bottom controls
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _toggleShowAnswer,
                    icon: Icon(_showAnswer ? Icons.visibility_off : Icons.help_outline, size: 18),
                    label: Text(_showAnswer ? 'Hide Answer' : '? Answer'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF8B6914),
                      side: const BorderSide(color: Color(0xFF8B6914)),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _answered ? () => _nextQuestion() : null,
                    icon: const Icon(Icons.skip_next, size: 20),
                    label: const Text('Next', style: TextStyle(fontSize: 16)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF8B6914),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Result feedback
          if (_answered)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              color: (isCorrect || isMicCorrect) ? Colors.green[100] : Colors.red[100],
              child: Text(
                (isCorrect || isMicCorrect)
                    ? 'Correct!${_micEnabled && isMicCorrect ? " (Mic)" : ""}'
                    : 'Wrong! Correct frets: ${_correctFrets.join(", ")}',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16, fontWeight: FontWeight.bold,
                  color: (isCorrect || isMicCorrect) ? Colors.green[800] : Colors.red[800],
                ),
              ),
            ),
          const AdBannerWidget(),
        ],
      ),
    );
  }
}
