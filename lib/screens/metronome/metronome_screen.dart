import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class MetronomeScreen extends StatefulWidget {
  const MetronomeScreen({super.key});

  @override
  State<MetronomeScreen> createState() => _MetronomeScreenState();
}

class _MetronomeScreenState extends State<MetronomeScreen> with SingleTickerProviderStateMixin {
  int _bpm = 60;
  int _beatsPerMeasure = 4; // 박자 (2/4, 3/4, 4/4, 6/8)
  int _currentBeat = 0;
  bool _isPlaying = false;
  Timer? _timer;

  // 템포 이름
  String get _tempoName {
    if (_bpm < 40) return 'Grave';
    if (_bpm < 60) return 'Largo';
    if (_bpm < 66) return 'Larghetto';
    if (_bpm < 76) return 'Adagio';
    if (_bpm < 108) return 'Andante';
    if (_bpm < 120) return 'Moderato';
    if (_bpm < 156) return 'Allegro';
    if (_bpm < 176) return 'Vivace';
    if (_bpm < 200) return 'Presto';
    return 'Prestissimo';
  }

  final List<int> _timeSignatures = [2, 3, 4, 6];

  void _togglePlay() {
    setState(() {
      _isPlaying = !_isPlaying;
      if (_isPlaying) {
        _currentBeat = 0;
        _startTimer();
      } else {
        _timer?.cancel();
      }
    });
  }

  void _startTimer() {
    _timer?.cancel();
    final interval = Duration(milliseconds: (60000 / _bpm).round());
    _timer = Timer.periodic(interval, (_) {
      setState(() {
        _currentBeat = (_currentBeat + 1) % _beatsPerMeasure;
        // 강박(1박)은 높은 소리, 나머지는 낮은 소리
        if (_currentBeat == 0) {
          HapticFeedback.heavyImpact();
        } else {
          HapticFeedback.lightImpact();
        }
      });
    });
  }

  void _changeBpm(int delta) {
    setState(() {
      _bpm = (_bpm + delta).clamp(20, 300);
      if (_isPlaying) _startTimer();
    });
  }

  void _changeTimeSignature() {
    setState(() {
      final idx = _timeSignatures.indexOf(_beatsPerMeasure);
      _beatsPerMeasure = _timeSignatures[(idx + 1) % _timeSignatures.length];
      _currentBeat = 0;
      if (_isPlaying) _startTimer();
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Metronome'),
      ),
      body: Column(
        children: [
          const SizedBox(height: 20),
          // 비트 시각화
          Container(
            height: 160,
            margin: const EdgeInsets.symmetric(horizontal: 20),
            decoration: BoxDecoration(
              color: const Color(0xFF2A2A2A),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Center(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(_beatsPerMeasure, (i) {
                  final isActive = _isPlaying && _currentBeat == i;
                  final isDownbeat = i == 0;
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 100),
                      width: isActive ? 56 : 44,
                      height: isActive ? 56 : 44,
                      decoration: BoxDecoration(
                        color: isActive
                            ? (isDownbeat ? Colors.red : Colors.red[700])
                            : (isDownbeat ? Colors.red[900] : Colors.red[900]?.withValues(alpha: 0.5)),
                        shape: BoxShape.circle,
                        boxShadow: isActive ? [
                          BoxShadow(color: Colors.red.withValues(alpha: 0.6), blurRadius: 20),
                        ] : null,
                      ),
                      child: Center(
                        child: isDownbeat && isActive
                            ? const Text('>', style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold))
                            : null,
                      ),
                    ),
                  );
                }),
              ),
            ),
          ),
          const SizedBox(height: 20),
          // 박자 + 음표 선택
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // 박자 버튼
              GestureDetector(
                onTap: _changeTimeSignature,
                child: Container(
                  width: 140, height: 56,
                  decoration: BoxDecoration(
                    color: const Color(0xFF2A2A2A),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Center(
                    child: Text(
                      '$_beatsPerMeasure/4',
                      style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              // 음표 패턴
              Container(
                width: 140, height: 56,
                decoration: BoxDecoration(
                  color: const Color(0xFF2A2A2A),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Center(
                  child: Text('♩♩♩♩', style: TextStyle(color: Colors.white, fontSize: 24)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // 악센트 패턴
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 20),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            decoration: BoxDecoration(
              color: const Color(0xFF2A2A2A),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('-/-', style: TextStyle(color: Colors.grey[400], fontSize: 18)),
                Text('- -', style: TextStyle(color: Colors.grey[400], fontSize: 18)),
                Icon(Icons.replay, color: Colors.grey[400]),
              ],
            ),
          ),
          const Spacer(),
          // 템포 이름
          Text(_tempoName, style: const TextStyle(color: Colors.white, fontSize: 22)),
          const SizedBox(height: 8),
          // BPM 조절
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // BPM 표시 + 조절
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                decoration: BoxDecoration(
                  color: const Color(0xFF2A2A2A),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  children: [
                    Column(
                      children: [
                        Text('♩=', style: TextStyle(color: Colors.grey[400], fontSize: 16)),
                      ],
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '$_bpm',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 64,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Column(
                      children: [
                        _BpmButton(label: '+', onTap: () => _changeBpm(1), onLongPress: () => _changeBpm(5)),
                        const SizedBox(height: 8),
                        _BpmButton(label: '-', onTap: () => _changeBpm(-1), onLongPress: () => _changeBpm(-5)),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 20),
              // 재생 버튼
              GestureDetector(
                onTap: _togglePlay,
                child: Container(
                  width: 80, height: 80,
                  decoration: BoxDecoration(
                    color: const Color(0xFF3A3A3A),
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.grey[600]!, width: 2),
                  ),
                  child: Icon(
                    _isPlaying ? Icons.stop : Icons.play_arrow,
                    color: Colors.white,
                    size: 44,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          // BPM 슬라이더
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40),
            child: SliderTheme(
              data: SliderThemeData(
                activeTrackColor: Colors.red[700],
                inactiveTrackColor: Colors.grey[800],
                thumbColor: Colors.red,
              ),
              child: Slider(
                value: _bpm.toDouble(),
                min: 20, max: 300,
                onChanged: (v) {
                  setState(() {
                    _bpm = v.round();
                    if (_isPlaying) _startTimer();
                  });
                },
              ),
            ),
          ),
          const SizedBox(height: 8),
          // 볼륨 아이콘
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Padding(
                padding: const EdgeInsets.only(right: 20),
                child: Icon(Icons.volume_up, color: Colors.grey[500]),
              ),
            ],
          ),
          const SizedBox(height: 8),
          // 광고 배너
          Container(
            height: 50, width: double.infinity, color: Colors.grey[900],
            child: Center(child: Text('AD BANNER', style: TextStyle(color: Colors.grey[700], fontSize: 11))),
          ),
        ],
      ),
    );
  }
}

class _BpmButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  final VoidCallback onLongPress;

  const _BpmButton({required this.label, required this.onTap, required this.onLongPress});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      onLongPress: onLongPress,
      child: Container(
        width: 40, height: 40,
        decoration: BoxDecoration(
          color: const Color(0xFF444444),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Center(
          child: Text(label, style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
        ),
      ),
    );
  }
}
