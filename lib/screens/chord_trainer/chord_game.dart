import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import '../../models/chord.dart';
import '../../widgets/chord_diagram_widget.dart';
import '../../services/practice_record.dart';
import '../../services/app_localizations.dart';

class ChordGame extends StatefulWidget {
  final int seconds;
  final String difficulty;

  const ChordGame({super.key, required this.seconds, required this.difficulty});

  @override
  State<ChordGame> createState() => _ChordGameState();
}

class _ChordGameState extends State<ChordGame> {
  final _random = Random();
  late List<ChordData> _chords;
  late ChordData _currentChord;
  ChordData? _nextChord;
  Timer? _timer;
  int _timeLeft = 0;
  bool _paused = false;
  bool _showAnswer = false;
  final Stopwatch _stopwatch = Stopwatch();

  @override
  void initState() {
    super.initState();
    _chords = ChordData.byDifficulty(widget.difficulty);
    _stopwatch.start();
    _pickNext();
    _startTimer();
  }

  void _pickNext() {
    _currentChord = _chords[_random.nextInt(_chords.length)];
    _nextChord = _chords[_random.nextInt(_chords.length)];
    _timeLeft = widget.seconds;
    _showAnswer = false;
    setState(() {});
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (_paused) return;
      setState(() {
        _timeLeft--;
        if (_timeLeft <= 0) _pickNext();
      });
    });
  }

  void _togglePause() => setState(() => _paused = !_paused);
  void _toggleAnswer() => setState(() => _showAnswer = !_showAnswer);

  Future<void> _saveAndExit() async {
    _stopwatch.stop();
    _timer?.cancel();
    await PracticeRecord.saveSession(PracticeSession(
      type: 'chord',
      timestamp: DateTime.now(),
      durationSeconds: _stopwatch.elapsed.inSeconds,
    ));
    if (mounted) Navigator.pop(context);
  }

  @override
  void dispose() { _timer?.cancel(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAE5C8),
      appBar: AppBar(
        title: Text('${tr('chord_game_title')} ($_diffLabel)'),
        backgroundColor: const Color(0xFF8B6914),
        foregroundColor: Colors.white,
        leading: IconButton(icon: const Icon(Icons.close), onPressed: _saveAndExit),
        actions: [
          IconButton(icon: Icon(_paused ? Icons.play_arrow : Icons.pause),
            onPressed: _togglePause),
        ],
      ),
      body: Column(
        children: [
          if (!_paused)
            LinearProgressIndicator(
              value: _timeLeft / widget.seconds,
              backgroundColor: Colors.brown[100],
              valueColor: const AlwaysStoppedAnimation(Color(0xFF8B6914)),
              minHeight: 8,
            ),
          if (_paused)
            Container(height: 8, color: Colors.orange[200]),
          Expanded(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (_paused)
                    Text(tr('chord_pause'), style: const TextStyle(fontSize: 20, color: Colors.orange)),
                  const SizedBox(height: 8),
                  Text(_currentChord.name,
                    style: const TextStyle(fontSize: 100, fontWeight: FontWeight.bold, color: Color(0xFF5D3A00))),
                  Text(_currentChord.type, style: TextStyle(fontSize: 18, color: Colors.brown[400])),
                  const SizedBox(height: 8),
                  if (!_paused)
                    Text('$_timeLeft초', style: TextStyle(fontSize: 32,
                      color: _timeLeft > 2 ? Colors.brown : Colors.red)),
                  const SizedBox(height: 16),
                  // 코드 다이어그램
                  if (_showAnswer) ChordDiagramWidget(chord: _currentChord),
                  const SizedBox(height: 16),
                  OutlinedButton.icon(
                    onPressed: _toggleAnswer,
                    icon: Icon(_showAnswer ? Icons.visibility_off : Icons.visibility),
                    label: Text(_showAnswer ? tr('chord_hide_answer') : tr('chord_show_answer')),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF8B6914),
                      side: const BorderSide(color: Color(0xFF8B6914)),
                    ),
                  ),
                  const SizedBox(height: 16),
                  if (_nextChord != null)
                    Text(tr('chord_next').replaceAll('{name}', _nextChord!.name),
                      style: TextStyle(fontSize: 18, color: Colors.brown[300])),
                ],
              ),
            ),
          ),
          Container(height: 50, width: double.infinity, color: Colors.grey[200],
            child: const Center(child: Text('AD BANNER', style: TextStyle(color: Colors.grey, fontSize: 11)))),
        ],
      ),
    );
  }

  String get _diffLabel {
    switch (widget.difficulty) {
      case 'beginner': return tr('chord_beginner');
      case 'intermediate': return tr('chord_intermediate');
      case 'advanced': return tr('chord_advanced');
      default: return '';
    }
  }

}
