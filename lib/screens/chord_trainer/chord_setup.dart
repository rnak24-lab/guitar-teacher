import 'package:flutter/material.dart';
import '../../services/app_localizations.dart';
import 'chord_game.dart';

class ChordSetup extends StatefulWidget {
  const ChordSetup({super.key});

  @override
  State<ChordSetup> createState() => _ChordSetupState();
}

class _ChordSetupState extends State<ChordSetup> {
  double _seconds = 5;
  String _difficulty = 'beginner';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(tr('chord_setup_title')),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(tr('chord_difficulty'), style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF5D3A00))),
            const SizedBox(height: 12),
            _DifficultyCard(
              title: tr('chord_beginner'),
              subtitle: tr('chord_beginner_desc'),
              selected: _difficulty == 'beginner',
              onTap: () => setState(() => _difficulty = 'beginner'),
            ),
            const SizedBox(height: 8),
            _DifficultyCard(
              title: tr('chord_intermediate'),
              subtitle: tr('chord_intermediate_desc'),
              selected: _difficulty == 'intermediate',
              onTap: () => setState(() => _difficulty = 'intermediate'),
            ),
            const SizedBox(height: 8),
            _DifficultyCard(
              title: tr('chord_advanced'),
              subtitle: tr('chord_advanced_desc'),
              selected: _difficulty == 'advanced',
              onTap: () => setState(() => _difficulty = 'advanced'),
            ),
            const SizedBox(height: 24),
            Text(tr('chord_change_time').replaceAll('{n}', '${_seconds.toInt()}'),
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF5D3A00))),
            Slider(
              value: _seconds, min: 1, max: 30, divisions: 29,
              label: '${_seconds.toInt()}s',
              activeColor: const Color(0xFF8B6914),
              onChanged: (v) => setState(() => _seconds = v),
            ),
            const Spacer(),
            SizedBox(
              width: double.infinity, height: 60,
              child: ElevatedButton(
                onPressed: () => Navigator.push(context,
                  MaterialPageRoute(builder: (_) => ChordGame(
                    seconds: _seconds.toInt(), difficulty: _difficulty))),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF8B6914), foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                child: Text(tr('start'), style: const TextStyle(fontSize: 24)),
              ),
            ),
            const SizedBox(height: 16),
            Container(height: 50, width: double.infinity, color: Colors.grey[200],
              child: const Center(child: Text('AD BANNER', style: TextStyle(color: Colors.grey, fontSize: 11)))),
          ],
        ),
      ),
    );
  }
}

class _DifficultyCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final bool selected;
  final VoidCallback onTap;

  const _DifficultyCard({required this.title, required this.subtitle, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFF8B6914).withValues(alpha: 0.15) : Colors.white,
          border: Border.all(color: selected ? const Color(0xFF8B6914) : Colors.grey[300]!, width: selected ? 2 : 1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              Text(subtitle, style: const TextStyle(color: Colors.grey)),
            ])),
            if (selected) const Icon(Icons.check_circle, color: Color(0xFF8B6914)),
          ],
        ),
      ),
    );
  }
}
