import 'package:flutter/material.dart';
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
        title: const Text('코드 연습 설정'),
        backgroundColor: const Color(0xFF8B6914),
        foregroundColor: Colors.white,
      ),
      backgroundColor: const Color(0xFFFAE5C8),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('🎯 난이도', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF5D3A00))),
            const SizedBox(height: 12),
            _DifficultyCard(
              title: '🟢 초급',
              subtitle: 'C, G, D, Am, Em 등 오픈코드',
              selected: _difficulty == 'beginner',
              onTap: () => setState(() => _difficulty = 'beginner'),
            ),
            const SizedBox(height: 8),
            _DifficultyCard(
              title: '🟡 중급',
              subtitle: 'F, Bb, Fmaj7 등 바레/하이코드',
              selected: _difficulty == 'intermediate',
              onTap: () => setState(() => _difficulty = 'intermediate'),
            ),
            const SizedBox(height: 8),
            _DifficultyCard(
              title: '🔴 고급',
              subtitle: 'Cm7, Db9, Bm7b5 등 재즈코드',
              selected: _difficulty == 'advanced',
              onTap: () => setState(() => _difficulty = 'advanced'),
            ),
            const SizedBox(height: 24),
            Text('⏱ 코드 변경: ${_seconds.toInt()}초',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF5D3A00))),
            Slider(
              value: _seconds, min: 1, max: 30, divisions: 29,
              label: '${_seconds.toInt()}초',
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
                  backgroundColor: const Color(0xFF8B6914),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                child: const Text('시작!', style: TextStyle(fontSize: 24)),
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
