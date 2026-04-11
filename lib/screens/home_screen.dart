import 'package:flutter/material.dart';
import 'fretboard_trainer/fretboard_setup.dart';
import 'octave_trainer/octave_setup.dart';
import 'chord_trainer/chord_setup.dart';
import 'scale_trainer/scale_setup.dart';
import 'tuner/tuner_screen.dart';
import 'metronome/metronome_screen.dart';
import 'practice_stats/practice_stats_screen.dart';
import 'settings/settings_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Guitar Teacher 🎸', style: TextStyle(fontSize: 22)),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () => Navigator.push(
              context, MaterialPageRoute(builder: (_) => const SettingsScreen())),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: GridView.count(
                crossAxisCount: 2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                children: [
                  _StageCard(icon: Icons.music_note, title: '프렛보드', subtitle: '음 위치 외우기',
                    color: const Color(0xFF4A90D9),
                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const FretboardSetup()))),
                  _StageCard(icon: Icons.layers, title: '옥타브 폼', subtitle: 'CAGED 5폼',
                    color: const Color(0xFFE67E22),
                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const OctaveSetup()))),
                  _StageCard(icon: Icons.piano, title: '코드 연습', subtitle: '코드 체인지',
                    color: const Color(0xFF27AE60),
                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ChordSetup()))),
                  _StageCard(icon: Icons.queue_music, title: '스케일', subtitle: '스케일 연습',
                    color: const Color(0xFF2980B9),
                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ScaleSetup()))),
                  _StageCard(icon: Icons.tune, title: '튜너', subtitle: '기타 튜닝',
                    color: const Color(0xFF8E44AD),
                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const TunerScreen()))),
                  _StageCard(icon: Icons.timer, title: '메트로놈', subtitle: 'BPM 연습',
                    color: const Color(0xFFC0392B),
                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const MetronomeScreen()))),
                  _StageCard(icon: Icons.bar_chart, title: '연습 기록', subtitle: '이번주 통계',
                    color: const Color(0xFF16A085),
                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const PracticeStatsScreen()))),
                  _StageCard(icon: Icons.settings, title: '설정', subtitle: '테마/언어',
                    color: Colors.grey,
                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SettingsScreen()))),
                ],
              ),
            ),
          ),
          Container(
            height: 60, width: double.infinity,
            color: isDark ? Colors.grey[900] : Colors.grey[200],
            child: Center(child: Text('AD BANNER PLACEHOLDER',
              style: TextStyle(color: isDark ? Colors.grey[700] : Colors.grey, fontSize: 12))),
          ),
        ],
      ),
    );
  }
}

class _StageCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  const _StageCard({required this.icon, required this.title, required this.subtitle, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: LinearGradient(
              begin: Alignment.topLeft, end: Alignment.bottomRight,
              colors: [color.withValues(alpha: 0.85), color],
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 44, color: Colors.white),
              const SizedBox(height: 6),
              Text(title, style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
              Text(subtitle, style: TextStyle(color: Colors.white.withValues(alpha: 0.8), fontSize: 12)),
            ],
          ),
        ),
      ),
    );
  }
}
