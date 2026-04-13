import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../models/note.dart';
import '../../models/scale.dart';
import 'scale_practice.dart';
import 'scale_quiz.dart';
import '../../providers/note_name_provider.dart';

/// Circle-of-fourths order (confirmed 4/13): C F Bb Eb Ab Db Gb B E A D G C
const _circleOf4ths = ['C','F','Bb','Eb','Ab','Db','Gb','B','E','A','D','G'];

/// Circle-of-fifths order (confirmed 4/13): C G D A E B F# Db Ab Eb Bb F C
const _circleOf5ths = ['C','G','D','A','E','B','F#','Db','Ab','Eb','Bb','F'];

/// Display alias: F# is enharmonic to Gb – map for internal lookups
const _enharmonicMap = {'F#': 'Gb'};

class ScaleSetup extends StatefulWidget {
  const ScaleSetup({super.key});

  @override
  State<ScaleSetup> createState() => _ScaleSetupState();
}

class _ScaleSetupState extends State<ScaleSetup> {
  String _selectedRoot = 'C';
  String _selectedScale = 'Major (Ionian)';
  int _startFret = 0;
  int _endFret = 12;
  int _octave = 3; // default octave

  /// null = chromatic order, '4th' = circle of 4ths, '5th' = circle of 5ths
  String? _circleMode;

  /// Per-string enable/disable (1~6), all enabled by default
  final List<bool> _stringEnabled = List.filled(6, true);

  List<String> get _orderedNotes {
    if (_circleMode == '4th') return _circleOf4ths;
    if (_circleMode == '5th') return _circleOf5ths;
    return Note.allNotes;
  }

  /// Resolve enharmonic equivalents for internal use (e.g. F# -> Gb)
  String get _resolvedRoot => _enharmonicMap[_selectedRoot] ?? _selectedRoot;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    const accent = Color(0xFF8B6914);

    return Scaffold(
      appBar: AppBar(title: const Text('Scale Practice')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // ── Circle of 4ths / 5ths toggle ──
          Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Note Order',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 4,
                    children: [
                      _orderChip('Chromatic', null, accent),
                      _orderChip('4th Circle', '4th', accent),
                      _orderChip('5th Circle', '5th', accent),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),

          // ── Root note selector ──
          Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Root Note',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _orderedNotes.map((note) => ChoiceChip(
                      label: Text(NoteNameProvider().display(note),
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      selected: _selectedRoot == note,
                      selectedColor: accent,
                      labelStyle: TextStyle(
                        color: _selectedRoot == note ? Colors.white : null,
                      ),
                      onSelected: (v) => setState(() => _selectedRoot = note),
                    )).toList(),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),

          // ── Octave input ──
          Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Octave',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      // -/+ buttons
                      IconButton(
                        onPressed: _octave > 1
                            ? () => setState(() => _octave--)
                            : null,
                        icon: const Icon(Icons.remove_circle_outline),
                        color: accent,
                      ),
                      // Direct input field
                      SizedBox(
                        width: 60,
                        child: TextField(
                          controller: TextEditingController(text: '$_octave'),
                          keyboardType: TextInputType.number,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                              fontSize: 24, fontWeight: FontWeight.bold),
                          decoration: InputDecoration(
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                                vertical: 8, horizontal: 4),
                          ),
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                            LengthLimitingTextInputFormatter(1),
                          ],
                          onChanged: (v) {
                            final n = int.tryParse(v);
                            if (n != null && n >= 1 && n <= 8) {
                              setState(() => _octave = n);
                            }
                          },
                        ),
                      ),
                      IconButton(
                        onPressed: _octave < 8
                            ? () => setState(() => _octave++)
                            : null,
                        icon: const Icon(Icons.add_circle_outline),
                        color: accent,
                      ),
                      const SizedBox(width: 12),
                      Text(
                        '(${NoteNameProvider().display(_resolvedRoot)}$_octave)',
                        style: TextStyle(
                          fontSize: 16,
                          color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),

          // ── Scale type selector ──
          Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Scale Type',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  ...ScaleData.allScales.map((scale) => RadioListTile<String>(
                    title: Text(scale.name),
                    subtitle: Text(_scaleFormula(scale)),
                    value: scale.name,
                    groupValue: _selectedScale,
                    activeColor: accent,
                    onChanged: (v) => setState(() => _selectedScale = v!),
                    dense: true,
                  )),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),

          // ── Fret range ──
          Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Fret Range: $_startFret ~ $_endFret',
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  RangeSlider(
                    values: RangeValues(
                        _startFret.toDouble(), _endFret.toDouble()),
                    min: 0,
                    max: 15,
                    divisions: 15,
                    labels: RangeLabels('$_startFret', '$_endFret'),
                    activeColor: accent,
                    onChanged: (v) => setState(() {
                      _startFret = v.start.round();
                      _endFret = v.end.round();
                    }),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),

          // ── String enable/disable toggle ──
          Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Text('Strings',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      const Spacer(),
                      TextButton(
                        onPressed: () => setState(() {
                          final allOn = _stringEnabled.every((e) => e);
                          for (int i = 0; i < 6; i++) {
                            _stringEnabled[i] = !allOn;
                          }
                        }),
                        child: Text(_stringEnabled.every((e) => e) ? 'Deselect All' : 'Select All'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: List.generate(6, (i) {
                      final gs = ['1E','2B','3G','4D','5A','6E'];
                      return FilterChip(
                        label: Text(gs[i],
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: _stringEnabled[i] ? Colors.white : null,
                            )),
                        selected: _stringEnabled[i],
                        selectedColor: accent,
                        checkmarkColor: Colors.white,
                        onSelected: (v) {
                          setState(() => _stringEnabled[i] = v);
                          // Prevent all strings from being disabled
                          if (!_stringEnabled.any((e) => e)) {
                            setState(() => _stringEnabled[i] = true);
                          }
                        },
                      );
                    }),
                  ),
                  const SizedBox(height: 8),
                  // ── Preset buttons ──
                  Wrap(
                    spacing: 6,
                    runSpacing: 4,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      const Text('Presets: ', style: TextStyle(fontSize: 13, color: Colors.grey)),
                      _presetChip('High (1-3)', [true, true, true, false, false, false], accent),
                      _presetChip('Low (4-6)', [false, false, false, true, true, true], accent),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),

          // ── Mode buttons ──
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _openPractice,
                  icon: const Icon(Icons.visibility, size: 20),
                  label: const Text('Practice Mode',
                      style: TextStyle(fontSize: 16)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF27AE60),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _openQuiz,
                  icon: const Icon(Icons.quiz, size: 20),
                  label: const Text('Quiz Mode',
                      style: TextStyle(fontSize: 16)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFE67E22),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 60),
        ],
      ),
    );
  }

  Widget _presetChip(String label, List<bool> preset, Color accent) {
    final isActive = List.generate(6, (i) => _stringEnabled[i] == preset[i]).every((e) => e);
    return ActionChip(
      label: Text(label, style: TextStyle(fontSize: 12, color: isActive ? Colors.white : null)),
      backgroundColor: isActive ? accent : null,
      onPressed: () => setState(() {
        for (int i = 0; i < 6; i++) {
          _stringEnabled[i] = preset[i];
        }
      }),
    );
  }

  Widget _orderChip(String label, String? mode, Color accent) {
    final isActive = _circleMode == mode;
    return ChoiceChip(
      label: Text(label),
      selected: isActive,
      selectedColor: accent,
      labelStyle: TextStyle(
        color: isActive ? Colors.white : null,
        fontWeight: FontWeight.w600,
      ),
      onSelected: (_) => setState(() => _circleMode = mode),
    );
  }

  String _scaleFormula(ScaleData scale) {
    final nn = NoteNameProvider();
    return scale.notesForRoot(_resolvedRoot).map((n) => nn.display(n)).join(' - ');
  }

  void _openPractice() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ScalePractice(
          rootNote: _resolvedRoot,
          scaleName: _selectedScale,
          startFret: _startFret,
          endFret: _endFret,
          enabledStrings: List.from(_stringEnabled),
        ),
      ),
    );
  }

  void _openQuiz() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ScaleQuiz(
          rootNote: _resolvedRoot,
          scaleName: _selectedScale,
          startFret: _startFret,
          endFret: _endFret,
          enabledStrings: List.from(_stringEnabled),
        ),
      ),
    );
  }
}
