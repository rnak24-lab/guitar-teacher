import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../models/note.dart';
import '../../models/guitar_string.dart';
import '../../services/practice_record.dart';

/// Continuous "Play X" note finder - no start button, runs immediately
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

  // Animation
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(duration: const Duration(milliseconds: 400), vsync: this);
    _fadeAnimation = CurvedAnimation(parent: _fadeController, curve: Curves.easeInOut);
    _stopwatch.start();
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

    _fadeController.forward(from: 0);

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

    // Play sound if enabled
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
      _nextNote(); // auto-advance on correct
    } else {
      setState(() => _showAnswer = true);
      // Show answer briefly then move on
      Future.delayed(const Duration(seconds: 2), () {
        if (mounted) _nextNote();
      });
    }
  }

  void _toggleSettings() {
    setState(() => _showSettings = !_showSettings);
  }

  Future<void> _saveAndExit() async {
    _stopwatch.stop();
    _timer?.cancel();
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
    _fadeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final gs = GuitarString.standard.firstWhere((s) => s.number == _currentString);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Note Finder 🎵'),
        leading: IconButton(icon: const Icon(Icons.close), onPressed: _saveAndExit),
        actions: [
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

          // Main content: Play X card
          Expanded(
            flex: 3,
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // String indicator
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
                    // "Play X" big text
                    Text('Play', style: TextStyle(fontSize: 28, color: Colors.grey[500])),
                    Text(
                      _currentNote,
                      style: const TextStyle(fontSize: 120, fontWeight: FontWeight.bold, color: Color(0xFF4A90D9), height: 1.1),
                    ),
                    const SizedBox(height: 4),
                    // Timer countdown
                    Text(
                      '${_timeLeft}s',
                      style: TextStyle(fontSize: 24, color: _timeLeft > 2 ? Colors.grey[400] : Colors.red, fontWeight: FontWeight.w500),
                    ),
                    // Answer feedback
                    if (_showAnswer)
                      Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Text(
                          'Fret ${_correctFrets.join(", ")}',
                          style: TextStyle(fontSize: 20, color: Colors.green[600], fontWeight: FontWeight.bold),
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
                      // - button
                      _stepBtn(Icons.remove, () {
                        if (_seconds > 1) setState(() => _seconds--);
                      }),
                      // Current value
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        child: Text('${_seconds.toInt()}s',
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      ),
                      // + button
                      _stepBtn(Icons.add, () {
                        if (_seconds < 60) setState(() => _seconds++);
                      }),
                      const SizedBox(width: 8),
                      // Preset chips
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
