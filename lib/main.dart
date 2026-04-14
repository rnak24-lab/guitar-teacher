import 'package:flutter/material.dart';
import 'screens/home_screen.dart';
import 'screens/tutorial/tutorial_screen.dart';
import 'services/app_localizations.dart';
import 'services/notification_service.dart';
import 'services/ad_service.dart';
import 'providers/note_name_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await NotificationService().init();
    await NotificationService().restoreIfEnabled();
  } catch (_) {
    // Notification init may fail on some devices — don't block app launch
  }
  try {
    await AdService().init();
  } catch (_) {
    // Ad init failure should not block app launch
  }
  await NoteNameProvider().init();
  runApp(const GuitarTeacherApp());
}

class GuitarTeacherApp extends StatefulWidget {
  const GuitarTeacherApp({super.key});

  static GuitarTeacherAppState? of(BuildContext context) {
    return context.findAncestorStateOfType<GuitarTeacherAppState>();
  }

  @override
  State<GuitarTeacherApp> createState() => GuitarTeacherAppState();
}

class GuitarTeacherAppState extends State<GuitarTeacherApp> {
  bool _isDarkMode = false;
  final AppLocalizations _loc = AppLocalizations();

  bool get isDarkMode => _isDarkMode;

  void toggleDarkMode() {
    setState(() => _isDarkMode = !_isDarkMode);
  }

  void setLocale(String code) {
    setState(() => _loc.setLocale(code));
  }

  // Light theme - warm wood/apricot
  static final _lightTheme = ThemeData(
    brightness: Brightness.light,
    colorScheme: ColorScheme.fromSeed(
      seedColor: const Color(0xFF8B6914),
      surface: const Color(0xFFFAE5C8),
    ),
    scaffoldBackgroundColor: const Color(0xFFFAE5C8),
    useMaterial3: true,
    appBarTheme: const AppBarTheme(
      backgroundColor: Color(0xFFE8CFA8),  // slightly darker than apricot bg
      foregroundColor: Color(0xFF5D3A00),
      centerTitle: true,
      elevation: 0,
      scrolledUnderElevation: 0.5,
    ),
  );

  // Dark theme
  static final _darkTheme = ThemeData(
    brightness: Brightness.dark,
    colorScheme: ColorScheme.fromSeed(
      seedColor: const Color(0xFF8B6914),
      brightness: Brightness.dark,
    ),
    scaffoldBackgroundColor: const Color(0xFF121212),
    useMaterial3: true,
    appBarTheme: const AppBarTheme(
      backgroundColor: Color(0xFF1A1A1A),  // slightly darker than dark bg
      foregroundColor: Color(0xFFE8CFA8),
      centerTitle: true,
      elevation: 0,
      scrolledUnderElevation: 0.5,
    ),
  );

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Guitar Educator',
      debugShowCheckedModeBanner: false,
      theme: _lightTheme,
      darkTheme: _darkTheme,
      themeMode: _isDarkMode ? ThemeMode.dark : ThemeMode.light,
      home: const _FirstLaunchWrapper(child: RateAppWrapper(child: HomeScreen())),
    );
  }
}

/// Rate app dialog on exit
class RateAppWrapper extends StatelessWidget {
  final Widget child;
  const RateAppWrapper({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        final shouldExit = await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: Text(tr('rate_title')),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(tr('rate_body')),
                const SizedBox(height: 16),
                const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.star, color: Colors.amber, size: 32),
                    Icon(Icons.star, color: Colors.amber, size: 32),
                    Icon(Icons.star, color: Colors.amber, size: 32),
                    Icon(Icons.star, color: Colors.amber, size: 32),
                    Icon(Icons.star, color: Colors.amber, size: 32),
                  ],
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: Text(tr('later')),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: Text(tr('rate_now')),
              ),
            ],
          ),
        );
        if (shouldExit == true && context.mounted) {
          Navigator.pop(context);
        }
      },
      child: child,
    );
  }
}

/// Shows tutorial on first launch via SharedPreferences check.
class _FirstLaunchWrapper extends StatefulWidget {
  final Widget child;
  const _FirstLaunchWrapper({required this.child});

  @override
  State<_FirstLaunchWrapper> createState() => _FirstLaunchWrapperState();
}

class _FirstLaunchWrapperState extends State<_FirstLaunchWrapper> {
  @override
  void initState() {
    super.initState();
    _checkFirstLaunch();
  }

  Future<void> _checkFirstLaunch() async {
    final shouldShow = await TutorialScreen.shouldShowOnFirstLaunch();
    if (shouldShow && mounted) {
      // Small delay so the home screen renders first
      await Future.delayed(const Duration(milliseconds: 500));
      if (mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => const TutorialScreen(isFirstLaunch: true),
          ),
        );
      }
    }

    // Show notification consent dialog after a short delay
    // (after tutorial or on second launch if tutorial was shown)
    await Future.delayed(const Duration(milliseconds: 1500));
    if (mounted) {
      await NotificationService().showConsentDialog(context);
    }
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
