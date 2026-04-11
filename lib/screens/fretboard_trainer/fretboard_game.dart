import 'dart:async';
import 'package:flutter/material.dart';
import '../../models/note.dart';
import '../../models/guitar_string.dart';
import '../../utils/music_theory.dart';

class FretboardGame extends StatefulWidget {
  final int seconds;
  final List<int> selectedStrings;
  final bool randomMode;

  const FretboardGame({
    super.key,
    required this.seconds,
    required this.selectedStrings,
    required this.randomMode,
  });

  @override
  State<FretboardGame> createState() => _FretboardGameState();
}

class _FretboardGameState extends State<FretboardGame> {
  late Map<String, dynamic> _currentQuestion;
  Timer? _timer;
  int _timeLeft = 0;
  int _score = 0;
  int _total = 0;
  bool _autoAdvance = false; // 자동 모드: 맞으면 넘김
  bool _showAnswer = false;

  @override
  void initState() {
    super.initState();
    _nextQuestion();
  }

  void _nextQuestion() {
    _currentQuestion = MusicTheory.generateQuestion(
      allowedStrings: widget.selectedStrings,
    );
    _timeLeft = widget.seconds;
    _showAnswer = false;
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        _timeLeft--;
        if (_timeLeft <= 0) {
          _total++;
          _nextQuestion();
        }
      });
    });
    setState(() {});
  }

  void _onFretTap(int fret) {
    final correctFrets = _currentQuestion['correctFrets'] as List<int>;
    if (correctFrets.contains(fret)) {
      _score++;
      _total++;
      if (_autoAdvance) {
        _nextQuestion();
      } else {
        setState(() => _showAnswer = true);
      }
    } else {
      _total++;
      setState(() => _showAnswer = true);
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final note = _currentQuestion['note'] as String;
    final stringNum = _currentQuestion['string'] as int;
    final openNote = _currentQuestion['openNote'] as String;
    final correctFrets = _currentQuestion['correctFrets'] as List<int>;
    final gs = GuitarString.standard[stringNum - 1];

    return Scaffold(
      appBar: AppBar(
        title: Text('프렛보드 연습 | 점수: $_score/$_total'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        actions: [
          Row(
            children: [
              const Text('자동', style: TextStyle(fontSize: 12)),
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
          // 타이머 바
          LinearProgressIndicator(
            value: _timeLeft / widget.seconds,
            backgroundColor: Colors.grey[300],
            valueColor: AlwaysStoppedAnimation(
              _timeLeft > widget.seconds * 0.3 ? Colors.blue : Colors.red,
            ),
            minHeight: 8,
          ),
          const SizedBox(height: 16),
          // 문제 표시
          Text(
            '${gs.label}에서',
            style: const TextStyle(fontSize: 16, color: Colors.grey),
          ),
          Text(
            note,
            style: const TextStyle(
              fontSize: 72,
              fontWeight: FontWeight.bold,
              color: Colors.blue,
            ),
          ),
          Text(
            '을(를) 찾으세요! ($_timeLeft초)',
            style: const TextStyle(fontSize: 16),
          ),
          const SizedBox(height: 16),
          // 프렛 버튼 (0~12)
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: GridView.builder(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 7,
                  crossAxisSpacing: 4,
                  mainAxisSpacing: 4,
                  childAspectRatio: 1.2,
                ),
                itemCount: 13,
                itemBuilder: (context, fret) {
                  final isCorrect = correctFrets.contains(fret);
                  final noteAtFret = Note.noteAtFret(openNote, fret);
                  Color bgColor = Colors.grey[100]!;
                  if (_showAnswer && isCorrect) {
                    bgColor = Colors.green[200]!;
                  }

                  return InkWell(
                    onTap: _showAnswer ? null : () => _onFretTap(fret),
                    child: Container(
                      decoration: BoxDecoration(
                        color: bgColor,
                        border: Border.all(color: Colors.grey[400]!),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            '$fret',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: fret == 0 ? Colors.red : Colors.black,
                            ),
                          ),
                          if (_showAnswer)
                            Text(
                              noteAtFret,
                              style: TextStyle(
                                fontSize: 11,
                                color: isCorrect ? Colors.green[800] : Colors.grey,
                              ),
                            ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
          if (_showAnswer)
            Padding(
              padding: const EdgeInsets.all(8),
              child: ElevatedButton(
                onPressed: _nextQuestion,
                child: const Text('다음 문제 →'),
              ),
            ),
          // 광고 배너 자리
          Container(
            height: 50,
            width: double.infinity,
            color: Colors.grey[200],
            child: const Center(child: Text('AD BANNER', style: TextStyle(color: Colors.grey, fontSize: 11))),
          ),
        ],
      ),
    );
  }
}
