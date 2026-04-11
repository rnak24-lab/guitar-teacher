import 'dart:math';
import 'package:flutter/material.dart';

class TunerScreen extends StatefulWidget {
  const TunerScreen({super.key});

  @override
  State<TunerScreen> createState() => _TunerScreenState();
}

class _TunerScreenState extends State<TunerScreen> {
  static const Map<String, double> standardTuning = {
    '6E': 82.41, '5A': 110.00, '4D': 146.83,
    '3G': 196.00, '2B': 246.94, '1E': 329.63,
  };

  String _selectedString = '6E';
  double _detectedFrequency = 0;
  double _cents = 0;
  bool _isListening = false;
  bool _autoAdvance = false;
  int _currentStringIndex = 0;

  final List<String> _stringOrder = ['6E', '5A', '4D', '3G', '2B', '1E'];

  void _toggleListening() {
    setState(() {
      _isListening = !_isListening;
      if (_isListening) {
        // TODO: flutter_audio_capture 등으로 실제 마이크 연동
        _detectedFrequency = standardTuning[_selectedString]! + 2.5;
        _cents = 5.0;
      }
    });
  }

  void _selectString(String key) {
    setState(() {
      _selectedString = key;
      _currentStringIndex = _stringOrder.indexOf(key);
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

  double get _targetFreq => standardTuning[_selectedString]!;

  @override
  Widget build(BuildContext context) {
    final diff = _isListening ? _detectedFrequency - _targetFreq : 0.0;

    return Scaffold(
      backgroundColor: const Color(0xFFFAE5C8),
      appBar: AppBar(
        title: const Text('튜너'),
        backgroundColor: Colors.purple[700],
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
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: _stringOrder.map((s) {
              final isSelected = s == _selectedString;
              return GestureDetector(
                onTap: () => _selectString(s),
                child: Container(
                  width: 48, height: 48,
                  decoration: BoxDecoration(
                    color: isSelected ? Colors.purple[700] : const Color(0xFF8B6914),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Center(
                    child: Text(s.substring(1),
                      style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                  ),
                ),
              );
            }).toList(),
          ),
          const Spacer(),
          // 튜너 디스플레이
          SizedBox(
            width: 260, height: 260,
            child: CustomPaint(
              painter: _TunerDialPainter(cents: _isListening ? _cents : 0),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(_selectedString.substring(1),
                      style: TextStyle(fontSize: 64, fontWeight: FontWeight.bold,
                        color: _isListening ? (diff.abs() < 5 ? Colors.green : Colors.red) : Colors.brown)),
                    if (_isListening) ...[
                      Text('${_detectedFrequency.toStringAsFixed(1)} Hz',
                        style: const TextStyle(fontSize: 16, color: Colors.grey)),
                      Text(diff > 0 ? '▲ 높음' : diff < -1 ? '▼ 낮음' : '✓ 정확!',
                        style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold,
                          color: diff.abs() < 5 ? Colors.green : Colors.red)),
                    ],
                  ],
                ),
              ),
            ),
          ),
          const Spacer(),
          GestureDetector(
            onTap: _toggleListening,
            child: Container(
              width: 72, height: 72,
              decoration: BoxDecoration(
                color: _isListening ? Colors.red : Colors.purple[700],
                shape: BoxShape.circle,
              ),
              child: Icon(_isListening ? Icons.mic_off : Icons.mic, color: Colors.white, size: 36),
            ),
          ),
          const SizedBox(height: 8),
          Text(_isListening ? '듣는 중...' : '탭하여 시작', style: const TextStyle(color: Colors.grey)),
          if (_autoAdvance)
            const Text('자동: 맞으면 다음 줄로', style: TextStyle(color: Colors.purple, fontSize: 12)),
          const SizedBox(height: 16),
          Container(
            height: 50, width: double.infinity, color: Colors.grey[200],
            child: const Center(child: Text('AD BANNER', style: TextStyle(color: Colors.grey, fontSize: 11))),
          ),
        ],
      ),
    );
  }
}

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

    // 눈금
    for (int i = -5; i <= 5; i++) {
      final angle = (i / 5) * 1.2 - pi / 2;
      final s = radius - 15;
      final e = radius - 5;
      final p = Paint()
        ..color = i == 0 ? Colors.green : Colors.brown.withValues(alpha: 0.3)
        ..strokeWidth = i == 0 ? 3 : 1;
      canvas.drawLine(
        Offset(center.dx + s * cos(angle), center.dy + s * sin(angle)),
        Offset(center.dx + e * cos(angle), center.dy + e * sin(angle)), p);
    }

    // 바늘
    if (cents != 0) {
      final angle = (cents / 50).clamp(-1.0, 1.0) * 1.2 - pi / 2;
      final np = Paint()
        ..color = cents.abs() < 5 ? Colors.green : Colors.red
        ..strokeWidth = 3 ..strokeCap = StrokeCap.round;
      canvas.drawLine(center,
        Offset(center.dx + (radius - 30) * cos(angle), center.dy + (radius - 30) * sin(angle)), np);
    }
  }

  @override
  bool shouldRepaint(covariant _TunerDialPainter old) => old.cents != cents;
}
