import 'package:flutter/material.dart';
import '../services/app_localizations.dart';
import '../widgets/ad_banner_widget.dart';
import 'fretboard_trainer/fretboard_setup.dart';
import 'octave_trainer/octave_setup.dart';
import 'chord_trainer/chord_setup.dart';
import 'scale_trainer/scale_setup.dart';
import 'tuner/tuner_screen.dart';
import 'metronome/metronome_screen.dart';
import 'practice_stats/practice_stats_screen.dart';
import 'settings/settings_screen.dart';
import 'tutorial/tutorial_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Text('${tr('app_title')} 🎸', style: const TextStyle(fontSize: 22)),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.help_outline),
            tooltip: 'Tutorial',
            onPressed: () => Navigator.push(
              context, MaterialPageRoute(builder: (_) => const TutorialScreen())),
          ),
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
                  _StageCard(icon: Icons.music_note, title: tr('home_fretboard'), subtitle: tr('home_fretboard_sub'),
                    color: const Color(0xFF4A90D9),
                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const FretboardSetup()))),
                  _StageCard(icon: Icons.layers, title: tr('home_octave'), subtitle: tr('home_octave_sub'),
                    color: const Color(0xFFE67E22),
                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const OctaveSetup()))),
                  _StageCard(icon: Icons.piano, title: tr('home_chord'), subtitle: tr('home_chord_sub'),
                    color: const Color(0xFF27AE60),
                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ChordSetup()))),
                  _StageCard(icon: Icons.queue_music, title: tr('home_scale'), subtitle: tr('home_scale_sub'),
                    color: const Color(0xFF2980B9),
                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ScaleSetup()))),
                  _StageCard(icon: Icons.tune, title: tr('home_tuner'), subtitle: tr('home_tuner_sub'),
                    color: const Color(0xFF8E44AD),
                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const TunerScreen()))),
                  _StageCard(icon: Icons.timer, title: tr('home_metronome'), subtitle: tr('home_metronome_sub'),
                    color: const Color(0xFFC0392B),
                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const MetronomeScreen()))),
                  _StageCard(icon: Icons.bar_chart, title: tr('home_record'), subtitle: tr('home_record_sub'),
                    color: const Color(0xFF16A085),
                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const PracticeStatsScreen()))),
                  _StageCard(icon: Icons.settings, title: tr('home_settings'), subtitle: tr('home_settings_sub'),
                    color: Colors.grey,
                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SettingsScreen()))),
                ],
              ),
            ),
          ),
          const AdBannerWidget(),
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
