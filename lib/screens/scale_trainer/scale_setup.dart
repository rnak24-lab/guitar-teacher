import 'package:flutter/material.dart';
import '../../models/note.dart';
import '../../models/scale.dart';
import 'scale_practice.dart';
import 'scale_quiz.dart';

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

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(title: const Text('Scale Practice')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Root note selector
          Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Root Note', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: Note.allNotes.map((note) => ChoiceChip(
                      label: Text(note, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      selected: _selectedRoot == note,
                      selectedColor: const Color(0xFF8B6914),
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

          // Scale type selector
          Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Scale Type', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  ...ScaleData.allScales.map((scale) => RadioListTile<String>(
                    title: Text(scale.name),
                    subtitle: Text(_scaleFormula(scale)),
                    value: scale.name,
                    groupValue: _selectedScale,
                    activeColor: const Color(0xFF8B6914),
                    onChanged: (v) => setState(() => _selectedScale = v!),
                    dense: true,
                  )),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),

          // Fret range
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
                    values: RangeValues(_startFret.toDouble(), _endFret.toDouble()),
                    min: 0,
                    max: 15,
                    divisions: 15,
                    labels: RangeLabels('$_startFret', '$_endFret'),
                    activeColor: const Color(0xFF8B6914),
                    onChanged: (v) => setState(() {
                      _startFret = v.start.round();
                      _endFret = v.end.round();
                    }),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Mode buttons
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _openPractice,
                  icon: const Icon(Icons.visibility, size: 20),
                  label: const Text('Practice Mode', style: TextStyle(fontSize: 16)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF27AE60),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _openQuiz,
                  icon: const Icon(Icons.quiz, size: 20),
                  label: const Text('Quiz Mode', style: TextStyle(fontSize: 16)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFE67E22),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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

  String _scaleFormula(ScaleData scale) {
    return scale.notesForRoot(_selectedRoot).join(' - ');
  }

  void _openPractice() {
    Navigator.push(context, MaterialPageRoute(
      builder: (_) => ScalePractice(
        rootNote: _selectedRoot,
        scaleName: _selectedScale,
        startFret: _startFret,
        endFret: _endFret,
      ),
    ));
  }

  void _openQuiz() {
    Navigator.push(context, MaterialPageRoute(
      builder: (_) => ScaleQuiz(
        rootNote: _selectedRoot,
        scaleName: _selectedScale,
        startFret: _startFret,
        endFret: _endFret,
      ),
    ));
  }
}
