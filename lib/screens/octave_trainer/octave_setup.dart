import 'package:flutter/material.dart';
import '../../models/note.dart';
import 'octave_game.dart';

class OctaveSetup extends StatefulWidget {
  const OctaveSetup({super.key});

  @override
  State<OctaveSetup> createState() => _OctaveSetupState();
}

class _OctaveSetupState extends State<OctaveSetup> {
  final Set<int> _selectedForms = {1, 2, 3, 4, 5};
  double _seconds = 10;
  String _selectedNote = 'C';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('옥타브 폼 연습'),
        backgroundColor: Colors.orange,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('🎵 음 선택 (또는 랜덤)', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                ChoiceChip(
                  label: const Text('랜덤'),
                  selected: _selectedNote == 'random',
                  onSelected: (_) => setState(() => _selectedNote = 'random'),
                ),
                ...Note.allNotes.map((note) => ChoiceChip(
                  label: Text(note),
                  selected: _selectedNote == note,
                  onSelected: (_) => setState(() => _selectedNote = note),
                )),
              ],
            ),
            const SizedBox(height: 24),
            const Text('📐 폼 선택', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: List.generate(5, (i) {
                final formNum = i + 1;
                final names = ['E폼', 'D폼', 'C폼', 'A폼', 'G폼'];
                return FilterChip(
                  label: Text('$formNum (${names[i]})'),
                  selected: _selectedForms.contains(formNum),
                  onSelected: (selected) {
                    setState(() {
                      if (selected) {
                        _selectedForms.add(formNum);
                      } else if (_selectedForms.length > 1) {
                        _selectedForms.remove(formNum);
                      }
                    });
                  },
                );
              }),
            ),
            const SizedBox(height: 24),
            const Text('⏱ 시간 설정', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            Slider(
              value: _seconds,
              min: 3,
              max: 30,
              divisions: 27,
              label: '${_seconds.toInt()}초',
              onChanged: (v) => setState(() => _seconds = v),
            ),
            const Spacer(),
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => OctaveGame(
                      selectedForms: _selectedForms.toList()..sort(),
                      seconds: _seconds.toInt(),
                      selectedNote: _selectedNote,
                    ),
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('시작!', style: TextStyle(fontSize: 20)),
              ),
            ),
            const SizedBox(height: 16),
            Container(
              height: 50,
              width: double.infinity,
              color: Colors.grey[200],
              child: const Center(child: Text('AD BANNER', style: TextStyle(color: Colors.grey, fontSize: 11))),
            ),
          ],
        ),
      ),
    );
  }
}
