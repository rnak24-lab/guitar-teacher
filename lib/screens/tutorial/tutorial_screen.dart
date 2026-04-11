import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Tutorial screen — shown on first launch, accessible from Settings/Home.
/// Introduces each feature with brief descriptions.
class TutorialScreen extends StatefulWidget {
  /// If true, this was shown automatically on first launch.
  final bool isFirstLaunch;

  const TutorialScreen({super.key, this.isFirstLaunch = false});

  /// Check if the tutorial has been shown before.
  static Future<bool> shouldShowOnFirstLaunch() async {
    final prefs = await SharedPreferences.getInstance();
    return !(prefs.getBool('tutorial_shown') ?? false);
  }

  /// Mark tutorial as shown.
  static Future<void> markAsShown() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('tutorial_shown', true);
  }

  @override
  State<TutorialScreen> createState() => _TutorialScreenState();
}

class _TutorialScreenState extends State<TutorialScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  static const List<_TutorialPage> _pages = [
    _TutorialPage(
      icon: Icons.waving_hand,
      title: 'Welcome to Guitar Educator!',
      description:
          'Learn the fretboard, scales, chords, and more.\n'
          'This quick tutorial will show you the main features.',
      color: Color(0xFF8B6914),
    ),
    _TutorialPage(
      icon: Icons.music_note,
      title: 'Note Finder',
      description:
          'Find notes on any string and fret.\n'
          'A random note is shown — tap the correct fret or play it on your guitar with the microphone!',
      color: Color(0xFF4A90D9),
    ),
    _TutorialPage(
      icon: Icons.layers,
      title: 'Octave Forms',
      description:
          'Learn the CAGED octave shapes.\n'
          'Visualize how the same note repeats across the fretboard in different octave patterns.',
      color: Color(0xFFE67E22),
    ),
    _TutorialPage(
      icon: Icons.piano,
      title: 'Chord Trainer',
      description:
          'Practice chord shapes with interactive diagrams.\n'
          'See finger positions and learn open and barre chords.',
      color: Color(0xFF27AE60),
    ),
    _TutorialPage(
      icon: Icons.queue_music,
      title: 'Scale Trainer',
      description:
          'Practice and quiz yourself on scales.\n'
          'Use the microphone to play notes — the app detects your pitch in real time!',
      color: Color(0xFF2980B9),
    ),
    _TutorialPage(
      icon: Icons.tune,
      title: 'Tuner',
      description:
          'Tune your guitar using the built-in chromatic tuner.\n'
          'Uses your microphone to detect pitch with autocorrelation technology.',
      color: Color(0xFF8E44AD),
    ),
    _TutorialPage(
      icon: Icons.timer,
      title: 'Metronome',
      description:
          'Keep time with the built-in metronome.\n'
          'Adjustable BPM, time signatures, and haptic feedback.',
      color: Color(0xFFC0392B),
    ),
    _TutorialPage(
      icon: Icons.auto_awesome,
      title: 'Auto Mode',
      description:
          'When you play the correct note, the app automatically advances to the next one.\n\n'
          'Enable "Auto" mode in Scale Practice, Scale Quiz, or Note Finder to use this feature.\n'
          'Just turn on the microphone and toggle Auto!',
      color: Color(0xFF16A085),
    ),
  ];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _onDone() {
    TutorialScreen.markAsShown();
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF121212) : Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            // Skip button
            Align(
              alignment: Alignment.topRight,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: TextButton(
                  onPressed: _onDone,
                  child: Text(
                    _currentPage == _pages.length - 1 ? 'Done' : 'Skip',
                    style: TextStyle(
                      fontSize: 16,
                      color: isDark ? Colors.grey[400] : Colors.grey[600],
                    ),
                  ),
                ),
              ),
            ),

            // Page content
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                itemCount: _pages.length,
                onPageChanged: (idx) => setState(() => _currentPage = idx),
                itemBuilder: (ctx, idx) {
                  final page = _pages[idx];
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 32),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Icon circle
                        Container(
                          width: 120,
                          height: 120,
                          decoration: BoxDecoration(
                            color: page.color.withValues(alpha: 0.15),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(page.icon, size: 56, color: page.color),
                        ),
                        const SizedBox(height: 32),
                        Text(
                          page.title,
                          style: TextStyle(
                            fontSize: 26,
                            fontWeight: FontWeight.bold,
                            color: isDark ? Colors.white : Colors.black87,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          page.description,
                          style: TextStyle(
                            fontSize: 16,
                            color: isDark ? Colors.grey[400] : Colors.grey[700],
                            height: 1.5,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),

            // Page indicators
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(_pages.length, (idx) {
                  final isActive = idx == _currentPage;
                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    width: isActive ? 24 : 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: isActive ? _pages[_currentPage].color : Colors.grey[400],
                      borderRadius: BorderRadius.circular(4),
                    ),
                  );
                }),
              ),
            ),

            // Navigation buttons
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
              child: Row(
                children: [
                  if (_currentPage > 0)
                    TextButton(
                      onPressed: () => _pageController.previousPage(
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeInOut,
                      ),
                      child: const Text('Back', style: TextStyle(fontSize: 16)),
                    ),
                  const Spacer(),
                  ElevatedButton(
                    onPressed: _currentPage == _pages.length - 1
                        ? _onDone
                        : () => _pageController.nextPage(
                            duration: const Duration(milliseconds: 300),
                            curve: Curves.easeInOut,
                          ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _pages[_currentPage].color,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: Text(
                      _currentPage == _pages.length - 1 ? 'Get Started' : 'Next',
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TutorialPage {
  final IconData icon;
  final String title;
  final String description;
  final Color color;

  const _TutorialPage({
    required this.icon,
    required this.title,
    required this.description,
    required this.color,
  });
}
