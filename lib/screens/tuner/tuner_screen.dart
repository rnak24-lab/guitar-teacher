import 'dart:async';
import 'dart:math';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:record/record.dart';

class TunerScreen extends StatefulWidget {
  const TunerScreen({super.key});

  @override
  State<TunerScreen> createState() => _TunerScreenState();
}

class _TunerScreenState extends State<TunerScreen> {
  // ── 표준 튜닝 주파수 ──
  static const Map<String, double> standardTuning = {
    '6E': 82.41,
    '5A': 110.00,
    '4D': 146.83,
    '3G': 196.00,
    '2B': 246.94,
    '1E': 329.63,
  };

  final List<String> _stringOrder = ['6E', '5A', '4D', '3G', '2B', '1E'];

  String _selectedString = '6E';
  double _detectedFrequency = 0;
  double _cents = 0;
  bool _isListening = false;
  bool _autoAdvance = false;
  int _currentStringIndex = 0;

  // ── 마이크 / 녹음 ──
  final AudioRecorder _recorder = AudioRecorder();
  StreamSubscription<RecordState>? _recorderStateSub;
  StreamSubscription<Uint8List>? _audioStreamSub;

  // PCM 설정 (모노 16-bit signed LE)
  static const int _sampleRate = 44100;
  static const int _bufferSize = 4096; // FFT window size

  // 오디오 버퍼 축적용
  final List<double> _audioBuffer = [];

  // 권한 상태
  bool _permissionDenied = false;

  @override
  void dispose() {
    _stopListening();
    _recorderStateSub?.cancel();
    _recorder.dispose();
    super.dispose();
  }

  // ── 마이크 권한 요청 ──
  Future<bool> _requestMicPermission() async {
    final status = await Permission.microphone.request();
    if (status.isGranted) {
      return true;
    }
    if (status.isPermanentlyDenied) {
      if (mounted) {
        _showPermissionDialog();
      }
    }
    return false;
  }

  void _showPermissionDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('마이크 권한 필요'),
        content: const Text(
          '기타 튜너를 사용하려면 마이크 권한이 필요합니다.\n'
          '설정에서 마이크 권한을 허용해주세요.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              openAppSettings();
            },
            child: const Text('설정으로 이동'),
          ),
        ],
      ),
    );
  }

  // ── 듣기 시작 / 중지 ──
  Future<void> _toggleListening() async {
    if (_isListening) {
      await _stopListening();
    } else {
      await _startListening();
    }
  }

  Future<void> _startListening() async {
    // 1. 권한 확인
    final granted = await _requestMicPermission();
    if (!granted) {
      setState(() => _permissionDenied = true);
      return;
    }
    setState(() => _permissionDenied = false);

    // 2. 오디오 스트림 시작
    try {
      final stream = await _recorder.startStream(
        const RecordConfig(
          encoder: AudioEncoder.pcm16bits,
          sampleRate: _sampleRate,
          numChannels: 1,
          autoGain: true,
          echoCancel: false,
          noiseSuppress: false,
        ),
      );

      _audioBuffer.clear();

      _audioStreamSub = stream.listen((data) {
        _processAudioData(data);
      });

      setState(() => _isListening = true);
    } catch (e) {
      debugPrint('Audio stream error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('마이크 시작 실패: $e')),
        );
      }
    }
  }

  Future<void> _stopListening() async {
    _audioStreamSub?.cancel();
    _audioStreamSub = null;
    _audioBuffer.clear();

    if (await _recorder.isRecording()) {
      await _recorder.stop();
    }

    if (mounted) {
      setState(() {
        _isListening = false;
        _detectedFrequency = 0;
        _cents = 0;
      });
    }
  }

  // ── PCM 데이터 처리 ──
  void _processAudioData(Uint8List data) {
    // 16-bit signed LE -> double samples [-1, 1]
    final byteData = ByteData.sublistView(data);
    for (int i = 0; i < data.length - 1; i += 2) {
      final sample = byteData.getInt16(i, Endian.little) / 32768.0;
      _audioBuffer.add(sample);
    }

    // 버퍼가 충분히 쌓이면 분석
    while (_audioBuffer.length >= _bufferSize) {
      final window = _audioBuffer.sublist(0, _bufferSize);
      _audioBuffer.removeRange(0, _bufferSize ~/ 2); // 50% overlap

      final freq = _detectPitch(window);
      if (freq > 0 && mounted) {
        setState(() {
          _detectedFrequency = freq;
          _cents = _calculateCents(freq, standardTuning[_selectedString]!);

          // 자동 진행: cents ±5 이내면 다음 줄로
          if (_autoAdvance && _cents.abs() < 5) {
            _advanceToNext();
          }
        });
      }
    }
  }

  // ── 피치 감지 (Autocorrelation 방식) ──
  // FFT보다 기타 음의 기본 주파수 감지에 더 정확함
  double _detectPitch(List<double> buffer) {
    // RMS 체크 - 소리가 너무 작으면 무시
    double rms = 0;
    for (final s in buffer) {
      rms += s * s;
    }
    rms = sqrt(rms / buffer.length);
    if (rms < 0.01) return 0; // 무음

    // Normalized autocorrelation
    final halfLen = buffer.length ~/ 2;
    final correlation = List<double>.filled(halfLen, 0);

    for (int lag = 0; lag < halfLen; lag++) {
      double sum = 0;
      for (int i = 0; i < halfLen; i++) {
        sum += buffer[i] * buffer[i + lag];
      }
      correlation[lag] = sum;
    }

    // 첫 번째 피크 이후 (lag=0은 항상 최대) -> 기본 주파수 영역에서 피크 찾기
    // 기타 최저음 E2=82.41Hz -> lag = 44100/82.41 = ~535
    // 기타 최고음(1E) = 329.63Hz -> lag = 44100/329.63 = ~134
    // 여유를 두고 60Hz ~ 400Hz 범위
    final minLag = (_sampleRate / 400).round(); // ~110
    final maxLag = min((_sampleRate / 60).round(), halfLen - 1); // ~735

    // 첫 zero-crossing 이후의 최대 피크 찾기
    double maxCorr = 0;
    int bestLag = 0;

    for (int lag = minLag; lag <= maxLag; lag++) {
      if (correlation[lag] > maxCorr) {
        maxCorr = correlation[lag];
        bestLag = lag;
      }
    }

    if (bestLag == 0 || maxCorr < correlation[0] * 0.2) return 0;

    // Parabolic interpolation for sub-sample accuracy
    if (bestLag > 0 && bestLag < halfLen - 1) {
      final a = correlation[bestLag - 1];
      final b = correlation[bestLag];
      final c = correlation[bestLag + 1];
      final delta = 0.5 * (a - c) / (a - 2 * b + c);
      return _sampleRate / (bestLag + delta);
    }

    return _sampleRate / bestLag.toDouble();
  }

  // ── 센트 계산 ──
  double _calculateCents(double detected, double target) {
    if (detected <= 0 || target <= 0) return 0;
    return 1200 * log(detected / target) / ln2;
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
    final inTune = _isListening && _cents.abs() < 5;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Tuner'),
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

          // ── 줄 선택 버튼 ──
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
                      s.substring(1),
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

          const Spacer(),

          // ── 권한 거부 안내 ──
          if (_permissionDenied)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                children: [
                  const Icon(Icons.mic_off, size: 48, color: Colors.red),
                  const SizedBox(height: 8),
                  const Text(
                    '마이크 권한이 필요합니다',
                    style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.red),
                  ),
                  const SizedBox(height: 4),
                  TextButton(
                    onPressed: () => openAppSettings(),
                    child: const Text('설정에서 권한 허용하기'),
                  ),
                ],
              ),
            ),

          // ── 튜너 다이얼 ──
          SizedBox(
            width: 260,
            height: 260,
            child: CustomPaint(
              painter:
                  _TunerDialPainter(cents: _isListening ? _cents : 0),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      _selectedString.substring(1),
                      style: TextStyle(
                        fontSize: 64,
                        fontWeight: FontWeight.bold,
                        color: _isListening
                            ? (inTune ? Colors.green : Colors.red)
                            : Colors.brown,
                      ),
                    ),
                    if (_isListening && _detectedFrequency > 0) ...[
                      Text(
                        '${_detectedFrequency.toStringAsFixed(1)} Hz',
                        style: const TextStyle(
                            fontSize: 16, color: Colors.grey),
                      ),
                      Text(
                        '목표: ${_targetFreq.toStringAsFixed(1)} Hz',
                        style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[500]),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _cents.abs() < 5
                            ? '정확!'
                            : _cents > 0
                                ? '${_cents.toStringAsFixed(0)}c 높음'
                                : '${_cents.abs().toStringAsFixed(0)}c 낮음',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: inTune ? Colors.green : Colors.red,
                        ),
                      ),
                    ],
                    if (_isListening && _detectedFrequency <= 0)
                      const Text(
                        '소리를 감지 중...',
                        style: TextStyle(
                            fontSize: 14, color: Colors.grey),
                      ),
                  ],
                ),
              ),
            ),
          ),

          const Spacer(),

          // ── 마이크 버튼 ──
          GestureDetector(
            onTap: _toggleListening,
            child: Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: _isListening ? Colors.red : Colors.purple[700],
                shape: BoxShape.circle,
              ),
              child: Icon(
                _isListening ? Icons.mic_off : Icons.mic,
                color: Colors.white,
                size: 36,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _isListening ? '듣는 중...' : '탭하여 시작',
            style: const TextStyle(color: Colors.grey),
          ),
          if (_autoAdvance)
            const Text(
              '자동: 맞으면 다음 줄로',
              style: TextStyle(color: Colors.purple, fontSize: 12),
            ),
          const SizedBox(height: 16),

          // ── 광고 배너 ──
          Container(
            height: 50,
            width: double.infinity,
            color: Colors.grey[200],
            child: const Center(
              child: Text(
                'AD BANNER',
                style: TextStyle(color: Colors.grey, fontSize: 11),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── 튜너 다이얼 페인터 ──
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

    // 눈금 (-50c ~ +50c)
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

    // 바늘
    if (cents != 0) {
      final angle = (cents / 50).clamp(-1.0, 1.0) * 1.2 - pi / 2;
      final np = Paint()
        ..color = cents.abs() < 5 ? Colors.green : Colors.red
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
