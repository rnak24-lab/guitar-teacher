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

/// Quiz Mode: Random scale quiz - identify/play scale notes
/// Now supports microphone input: play the note on guitar instead of tapping fret buttons.
class ScaleQuiz extends StatefulWidget {
  final String rootNote;
  final String scaleName;
  final int startFret;
  final int endFret;

  const ScaleQuiz({
    super.key,
    required this.rootNote,
    required this.scaleName,
    required this.startFret,
    required this.endFret,
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

  @override
  void initState() {
    super.initState();
    _scale = ScaleData.byName(widget.scaleName);
    _scaleNotes = _scale.notesForRoot(widget.rootNote);
    _stopwatch.start();

    _pitchDetector.onPitchDetected = (freq, noteName, cents) {
      if (!mounted || _answered) return;
      setState(() {
        _detectedFrequency = freq;
        _detectedNote = noteName;
      });

      // Check if detected note matches any correct fret's note
      // Using A/B frequency matching: same note name on any octave is accepted
      if (_micEnabled && !_answered) {
        // The question asks for _questionNote on String _questionString
        // Check if the played frequency matches the note at any correct fret
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
          _handleCorrectMicAnswer();
        }
      }
    };

    _nextQuestion();
  }

  @override
  void dispose() {
    _pitchDetector.dispose();
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

  void _nextQuestion() {
    _questionNote = _scaleNotes[_random.nextInt(_scaleNotes.length)];
    _questionString = _random.nextInt(6) + 1;
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
    if (!_micEnabled) _totalQuestions++;
    setState(() {});
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
        title: Text('Scale Quiz: ${widget.rootNote} ${widget.scaleName}'),
        actions: [
          // Auto toggle
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
          TextButton(
            onPressed: _endQuiz,
            child: const Text('End', style: TextStyle(color: Colors.white, fontSize: 16)),
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
                  if (_detectedFrequency > 0)
                    Text(
                      '$_detectedNote  ${_detectedFrequency.toStringAsFixed(0)}Hz',
                      style: TextStyle(fontSize: 13, color: Colors.purple[600]),
                    )
                  else
                    Text('Play the note on your guitar...', style: TextStyle(fontSize: 13, color: Colors.grey[500])),
                  if (_autoMode) ...[
                    const Spacer(),
                    const Text('AUTO', style: TextStyle(fontSize: 10, color: Colors.green, fontWeight: FontWeight.bold)),
                  ],
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
                Text(_questionNote,
                  style: TextStyle(
                    fontSize: 64, fontWeight: FontWeight.bold,
                    color: isMicCorrect ? Colors.green : const Color(0xFF8B6914),
                  )),
                Text('on String $_questionString?',
                  style: TextStyle(fontSize: 20, color: isDark ? Colors.grey[300] : Colors.brown[600])),
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
