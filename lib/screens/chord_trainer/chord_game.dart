import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import '../../models/chord.dart';

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

  @override
  void initState() {
    super.initState();
    _chords = ChordData.byDifficulty(widget.difficulty);
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

  @override
  void dispose() { _timer?.cancel(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAE5C8),
      appBar: AppBar(
        title: Text('코드 연습 (${_diffLabel})'),
        backgroundColor: const Color(0xFF8B6914),
        foregroundColor: Colors.white,
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
                    const Text('⏸ 일시정지', style: TextStyle(fontSize: 20, color: Colors.orange)),
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
                  if (_showAnswer) _buildChordDiagram(),
                  const SizedBox(height: 16),
                  // 정답보기 버튼
                  OutlinedButton.icon(
                    onPressed: _toggleAnswer,
                    icon: Icon(_showAnswer ? Icons.visibility_off : Icons.visibility),
                    label: Text(_showAnswer ? '정답 숨기기' : '정답 보기'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF8B6914),
                      side: const BorderSide(color: Color(0xFF8B6914)),
                    ),
                  ),
                  const SizedBox(height: 16),
                  if (_nextChord != null)
                    Text('다음: ${_nextChord!.name}',
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
      case 'beginner': return '초급';
      case 'intermediate': return '중급';
      case 'advanced': return '고급';
      default: return '';
    }
  }

  Widget _buildChordDiagram() {
    final frets = _currentChord.frets;
    final minFret = frets.where((f) => f > 0).fold<int>(99, (a, b) => a < b ? a : b);
    final maxFret = frets.fold<int>(0, (a, b) => a > b ? a : b);
    final startFret = minFret > 3 ? minFret : 1;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white, borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF8B6914)),
      ),
      child: Column(
        children: [
          if (startFret > 1)
            Text('${startFret}fr', style: const TextStyle(fontSize: 12, color: Colors.grey)),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: List.generate(6, (i) {
              final f = frets[i];
              final stringNum = 6 - i;
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 6),
                child: Column(
                  children: [
                    Text('$stringNum', style: const TextStyle(fontSize: 10, color: Colors.grey)),
                    const SizedBox(height: 4),
                    Container(
                      width: 36, height: 36,
                      decoration: BoxDecoration(
                        color: f == -1 ? Colors.grey[300]
                            : f == 0 ? Colors.green[300]
                            : const Color(0xFF8B6914),
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.brown[300]!, width: 1),
                      ),
                      child: Center(
                        child: Text(
                          f == -1 ? 'X' : f == 0 ? 'O' : '$f',
                          style: TextStyle(
                            color: f == -1 ? Colors.grey[600] : Colors.white,
                            fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }),
          ),
          if (_currentChord.barFret != null)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text('바레: ${_currentChord.barFret}프렛',
                style: const TextStyle(fontSize: 12, color: Colors.brown)),
            ),
        ],
      ),
    );
  }
}
