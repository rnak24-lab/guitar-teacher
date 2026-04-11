import 'package:flutter/material.dart';
import 'fretboard_game.dart';

class FretboardSetup extends StatefulWidget {
  const FretboardSetup({super.key});

  @override
  State<FretboardSetup> createState() => _FretboardSetupState();
}

class _FretboardSetupState extends State<FretboardSetup> {
  double _seconds = 5;
  final Set<int> _selectedStrings = {1, 2, 3, 4, 5, 6};
  bool _randomMode = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('프렛보드 연습 설정'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('⏱ 시간 설정 (초)', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            Slider(
              value: _seconds,
              min: 1,
              max: 30,
              divisions: 29,
              label: '${_seconds.toInt()}초',
              onChanged: (v) => setState(() => _seconds = v),
            ),
            Text('${_seconds.toInt()}초마다 새 음이 나옵니다', style: const TextStyle(color: Colors.grey)),
            const SizedBox(height: 24),
            const Text('🎸 줄 선택', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: List.generate(6, (i) {
                final stringNum = i + 1;
                final labels = ['1(E)', '2(B)', '3(G)', '4(D)', '5(A)', '6(E)'];
                return FilterChip(
                  label: Text(labels[i]),
                  selected: _selectedStrings.contains(stringNum),
                  onSelected: (selected) {
                    setState(() {
                      if (selected) {
                        _selectedStrings.add(stringNum);
                      } else if (_selectedStrings.length > 1) {
                        _selectedStrings.remove(stringNum);
                      }
                    });
                  },
                );
              }),
            ),
            const SizedBox(height: 24),
            const Text('🎲 모드', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            SwitchListTile(
              title: const Text('랜덤 음'),
              subtitle: Text(_randomMode ? '12음이 랜덤으로 나옵니다' : '음 순서를 직접 지정합니다'),
              value: _randomMode,
              onChanged: (v) => setState(() => _randomMode = v),
            ),
            const Spacer(),
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => FretboardGame(
                      seconds: _seconds.toInt(),
                      selectedStrings: _selectedStrings.toList()..sort(),
                      randomMode: _randomMode,
                    ),
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('시작!', style: TextStyle(fontSize: 20)),
              ),
            ),
            const SizedBox(height: 16),
            // 광고 배너 자리
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
