import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import '../../models/scale.dart';
import '../../models/note.dart';
import '../../models/guitar_string.dart';
import '../../services/practice_record.dart';

/// Quiz Mode: Random scale quiz - identify/play scale notes
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
  int _questionIndex = 0;
  int _totalQuestions = 0;
  int _correctAnswers = 0;
  bool _showAnswer = false;
  bool _answered = false;
  String _questionNote = '';
  int _questionString = 1;
  List<int> _correctFrets = [];
  int? _selectedFret;
  final Stopwatch _stopwatch = Stopwatch();

  @override
  void initState() {
    super.initState();
    _scale = ScaleData.byName(widget.scaleName);
    _scaleNotes = _scale.notesForRoot(widget.rootNote);
    _stopwatch.start();
    _nextQuestion();
  }

  void _nextQuestion() {
    // Pick a random note from the scale
    _questionNote = _scaleNotes[_random.nextInt(_scaleNotes.length)];
    // Pick a random string
    _questionString = _random.nextInt(6) + 1;
    final gs = GuitarString.standard.firstWhere((s) => s.number == _questionString);
    _correctFrets = [];
    for (int f = widget.startFret; f <= widget.endFret; f++) {
      if (Note.noteAtFret(gs.openNote, f) == _questionNote) {
        _correctFrets.add(f);
      }
    }
    // If no valid frets, pick another question
    if (_correctFrets.isEmpty) {
      _nextQuestion();
      return;
    }
    _selectedFret = null;
    _showAnswer = false;
    _answered = false;
    _totalQuestions++;
    setState(() {});
  }

  void _checkAnswer(int fret) {
    if (_answered) return;
    _selectedFret = fret;
    _answered = true;
    if (_correctFrets.contains(fret)) {
      _correctAnswers++;
    }
    setState(() {});
  }

  void _toggleShowAnswer() {
    setState(() => _showAnswer = !_showAnswer);
  }

  Future<void> _endQuiz() async {
    _stopwatch.stop();
    await PracticeRecord.saveSession(PracticeSession(
      type: 'scale',
      timestamp: DateTime.now(),
      durationSeconds: _stopwatch.elapsed.inSeconds,
    ));
    if (mounted) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text('Quiz Complete! 🎸'),
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
    final isCorrect = _answered && _correctFrets.contains(_selectedFret);

    return Scaffold(
      appBar: AppBar(
        title: Text('Scale Quiz: ${widget.rootNote} ${widget.scaleName}'),
        actions: [
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
                Text('✅ $_correctAnswers / $_totalQuestions',
                  style: TextStyle(fontSize: 16, color: Colors.green[700])),
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
                  style: const TextStyle(fontSize: 64, fontWeight: FontWeight.bold, color: Color(0xFF8B6914))),
                Text('on String $_questionString?',
                  style: TextStyle(fontSize: 20, color: isDark ? Colors.grey[300] : Colors.brown[600])),
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
                    if (isCorrectFret && (_showAnswer || isSelected)) {
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
                            color: (_answered && (isCorrectFret && (_showAnswer || isSelected)) || (isSelected && !isCorrectFret))
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
                // ? help / show answer button
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
              color: isCorrect ? Colors.green[100] : Colors.red[100],
              child: Text(
                isCorrect ? '✅ Correct!' : '❌ Wrong! Correct frets: ${_correctFrets.join(", ")}',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16, fontWeight: FontWeight.bold,
                  color: isCorrect ? Colors.green[800] : Colors.red[800],
                ),
              ),
            ),
          // AD Banner
          Container(
            height: 50, width: double.infinity,
            color: isDark ? Colors.grey[900] : Colors.grey[200],
            child: Center(child: Text('AD BANNER',
              style: TextStyle(color: isDark ? Colors.grey[700] : Colors.grey, fontSize: 11))),
          ),
        ],
      ),
    );
  }
}
