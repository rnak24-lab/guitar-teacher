import 'package:flutter/material.dart';
import 'screens/home_screen.dart';

void main() {
  runApp(const GuitarTeacherApp());
}

class GuitarTeacherApp extends StatefulWidget {
  const GuitarTeacherApp({super.key});

  static _GuitarTeacherAppState? of(BuildContext context) {
    return context.findAncestorStateOfType<_GuitarTeacherAppState>();
  }

  @override
  State<GuitarTeacherApp> createState() => _GuitarTeacherAppState();
}

class _GuitarTeacherAppState extends State<GuitarTeacherApp> {
  bool _isDarkMode = false;

  bool get isDarkMode => _isDarkMode;

  void toggleDarkMode() {
    setState(() => _isDarkMode = !_isDarkMode);
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
      backgroundColor: Color(0xFF8B6914),
      foregroundColor: Colors.white,
      centerTitle: true,
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
      backgroundColor: Color(0xFF1E1E1E),
      foregroundColor: Colors.white,
      centerTitle: true,
    ),
  );

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Guitar Teacher',
      debugShowCheckedModeBanner: false,
      theme: _lightTheme,
      darkTheme: _darkTheme,
      themeMode: _isDarkMode ? ThemeMode.dark : ThemeMode.light,
      home: const RateAppWrapper(child: HomeScreen()),
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
            title: const Text('Enjoying Guitar Teacher? 🎸'),
            content: const Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('If you find this app helpful,\nplease rate us!'),
                SizedBox(height: 16),
                Row(
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
                child: const Text('Later'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: const Text('Rate Now'),
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
