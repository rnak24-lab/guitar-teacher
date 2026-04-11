import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../models/note.dart';
import '../../models/octave_form.dart';
import '../../services/app_localizations.dart';
import '../../services/practice_record.dart';
import 'form_info_dialog.dart';

/// Continuous octave form practice with drag-to-reorder note sequence
class OctaveSetup extends StatefulWidget {
  const OctaveSetup({super.key});

  @override
  State<OctaveSetup> createState() => _OctaveSetupState();
}

class _OctaveSetupState extends State<OctaveSetup> with TickerProviderStateMixin {
  final _random = Random();

  // Note sequence modes
  bool _isRandom = false;
  List<String> _noteOrder = [..._recommendedOrder];
  int _currentIndex = 0;

  // Form selection
  final Set<int> _selectedForms = {1, 2, 3, 4, 5};

  // Timer
  double _seconds = 8;
  Timer? _timer;
  int _timeLeft = 8;

  // Current state
  String _currentNote = 'C';
  int _currentFormNum = 1;
  bool _showSettings = false;
  int _count = 0;
  final Stopwatch _stopwatch = Stopwatch();

  // Animation
  late AnimationController _fadeController;

  // Recommended orders (guitar-friendly)
  static const List<String> _recommendedOrder = [
    'C', 'F', 'Bb', 'Eb', 'Ab', 'Db', 'Gb', 'B', 'E', 'A', 'D', 'G'
  ]; // Circle of 4ths - natural guitar progression

  static const List<String> _chromaticOrder = [
    'C', 'Db', 'D', 'Eb', 'E', 'F', 'Gb', 'G', 'Ab', 'A', 'Bb', 'B'
  ];

  static const List<String> _sharpOrder = [
    'C', 'G', 'D', 'A', 'E', 'B', 'Gb', 'Db', 'Ab', 'Eb', 'Bb', 'F'
  ]; // Circle of 5ths

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(duration: const Duration(milliseconds: 350), vsync: this);
    _stopwatch.start();
    _advance();
  }

  void _advance() {
    final forms = _selectedForms.toList();
    if (forms.isEmpty) return;

    // Pick form
    _currentFormNum = forms[_random.nextInt(forms.length)];

    // Pick note
    if (_isRandom) {
      _currentNote = Note.allNotes[_random.nextInt(12)];
    } else {
      _currentNote = _noteOrder[_currentIndex % _noteOrder.length];
      _currentIndex++;
    }

    _timeLeft = _seconds.toInt();
    _count++;
    _fadeController.forward(from: 0);
    HapticFeedback.lightImpact();

    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      setState(() {
        _timeLeft--;
        if (_timeLeft <= 0) _advance();
      });
    });

    setState(() {});
  }

  void _skip() => _advance();

  Future<void> _saveAndExit() async {
    _stopwatch.stop();
    _timer?.cancel();
    await PracticeRecord.saveSession(PracticeSession(
      type: 'octave',
      timestamp: DateTime.now(),
      durationSeconds: _stopwatch.elapsed.inSeconds,
    ));
    if (mounted) Navigator.pop(context);
  }

  void _applyPreset(List<String> preset) {
    setState(() {
      _noteOrder = [...preset];
      _currentIndex = 0;
      _isRandom = false;
    });
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
    final form = OctaveForm.allForms[_currentFormNum - 1];

    return Scaffold(
      appBar: AppBar(
        title: Text('${tr('home_octave')} 🎹'),
        leading: IconButton(icon: const Icon(Icons.close), onPressed: _saveAndExit),
        actions: [
          // Help button
          IconButton(
            icon: const Icon(Icons.help_outline),
            onPressed: () => showDialog(context: context, builder: (_) => const FormInfoDialog()),
          ),
          // Count
          Center(child: Padding(
            padding: const EdgeInsets.only(right: 8),
            child: Text('#$_count', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          )),
          IconButton(
            icon: Icon(_showSettings ? Icons.expand_less : Icons.tune),
            onPressed: () => setState(() => _showSettings = !_showSettings),
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
              _timeLeft > _seconds * 0.3 ? Colors.orange : Colors.red),
            minHeight: 6,
          ),

          // Main display
          Expanded(
            child: FadeTransition(
              opacity: CurvedAnimation(parent: _fadeController, curve: Curves.easeInOut),
              child: GestureDetector(
                onTap: _skip,
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Form indicator
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.orange.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          'Form $_currentFormNum  •  ${form.cagedName}',
                          style: TextStyle(fontSize: 18, color: isDark ? Colors.orange[200] : Colors.orange[800]),
                        ),
                      ),
                      const SizedBox(height: 16),
                      // Big note
                      Text('Play', style: TextStyle(fontSize: 24, color: Colors.grey[500])),
                      Text(
                        _currentNote,
                        style: const TextStyle(fontSize: 120, fontWeight: FontWeight.bold, color: Colors.orange, height: 1.1),
                      ),
                      const SizedBox(height: 8),
                      // Timer
                      Text(
                        '${_timeLeft}s',
                        style: TextStyle(fontSize: 22, color: _timeLeft > 2 ? Colors.grey[400] : Colors.red),
                      ),
                      const SizedBox(height: 16),
                      Text('Tap to skip →', style: TextStyle(fontSize: 12, color: Colors.grey[400])),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // Collapsible settings
          if (_showSettings) _buildSettings(isDark),

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

  Widget _buildSettings(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : Colors.grey[100],
        border: Border(top: BorderSide(color: Colors.grey[300]!)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Timer
          Row(
            children: [
              const Icon(Icons.timer, size: 18),
              const SizedBox(width: 8),
              Text('${_seconds.toInt()}s', style: const TextStyle(fontWeight: FontWeight.bold)),
              Expanded(
                child: Slider(
                  value: _seconds, min: 3, max: 30, divisions: 27,
                  activeColor: Colors.orange,
                  onChanged: (v) => setState(() => _seconds = v),
                ),
              ),
            ],
          ),

          // Form chips
          const Text('Forms', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
          const SizedBox(height: 4),
          Wrap(
            spacing: 6,
            children: List.generate(5, (i) {
              final fn = i + 1;
              final names = ['E', 'D', 'C', 'A', 'G'];
              return FilterChip(
                label: Text('$fn(${names[i]})', style: const TextStyle(fontSize: 12)),
                selected: _selectedForms.contains(fn),
                visualDensity: VisualDensity.compact,
                onSelected: (sel) {
                  setState(() {
                    if (sel) {
                      _selectedForms.add(fn);
                    } else if (_selectedForms.length > 1) {
                      _selectedForms.remove(fn);
                    }
                  });
                },
              );
            }),
          ),
          const SizedBox(height: 8),

          // Note order mode
          Row(
            children: [
              const Text('Note Order', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
              const Spacer(),
              ChoiceChip(
                label: const Text('Custom', style: TextStyle(fontSize: 11)),
                selected: !_isRandom,
                visualDensity: VisualDensity.compact,
                onSelected: (_) => setState(() => _isRandom = false),
              ),
              const SizedBox(width: 4),
              ChoiceChip(
                label: const Text('Random', style: TextStyle(fontSize: 11)),
                selected: _isRandom,
                visualDensity: VisualDensity.compact,
                onSelected: (_) => setState(() { _isRandom = true; }),
              ),
            ],
          ),
          const SizedBox(height: 6),

          // Draggable note order (only when not random)
          if (!_isRandom) ...[
            SizedBox(
              height: 40,
              child: ReorderableListView(
                scrollDirection: Axis.horizontal,
                buildDefaultDragHandles: true,
                onReorder: (oldIdx, newIdx) {
                  setState(() {
                    if (newIdx > oldIdx) newIdx--;
                    final item = _noteOrder.removeAt(oldIdx);
                    _noteOrder.insert(newIdx, item);
                  });
                },
                children: _noteOrder.asMap().entries.map((e) {
                  final isCurrent = !_isRandom && ((_currentIndex - 1) % _noteOrder.length == e.key);
                  return Container(
                    key: ValueKey('${e.key}_${e.value}'),
                    margin: const EdgeInsets.symmetric(horizontal: 2),
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: isCurrent ? Colors.orange : (isDark ? Colors.grey[700] : Colors.grey[300]),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Center(
                      child: Text(e.value, style: TextStyle(
                        fontSize: 14, fontWeight: FontWeight.bold,
                        color: isCurrent ? Colors.white : null)),
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 8),

            // Preset buttons
            const Text('Presets', style: TextStyle(fontSize: 12, color: Colors.grey)),
            const SizedBox(height: 4),
            Wrap(
              spacing: 6,
              children: [
                _presetChip('⭐ Circle of 4ths', _recommendedOrder),
                _presetChip('Circle of 5ths', _sharpOrder),
                _presetChip('Chromatic', _chromaticOrder),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _presetChip(String label, List<String> preset) {
    final isActive = !_isRandom && _listEquals(_noteOrder, preset);
    return ActionChip(
      label: Text(label, style: TextStyle(fontSize: 11, color: isActive ? Colors.white : null)),
      backgroundColor: isActive ? Colors.orange : null,
      visualDensity: VisualDensity.compact,
      onPressed: () => _applyPreset(preset),
    );
  }

  bool _listEquals(List<String> a, List<String> b) {
    if (a.length != b.length) return false;
    for (int i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }
}
