import 'package:flutter/material.dart';
import 'screens/home_screen.dart';

void main() {
  runApp(const GuitarTeacherApp());
}

class GuitarTeacherApp extends StatelessWidget {
  const GuitarTeacherApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Guitar Teacher',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
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
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF8B6914),
            foregroundColor: Colors.white,
          ),
        ),
      ),
      home: const RateAppWrapper(child: HomeScreen()),
    );
  }
}

/// 앱 종료 시 평점 유도
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
          builder: (context) => AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: const Text('앱을 잘 쓰고 계신가요? 🎸'),
            content: const Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('Guitar Teacher가 도움이 되셨다면\n평점을 남겨주세요!'),
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
                onPressed: () => Navigator.pop(context, true),
                child: const Text('나중에'),
              ),
              ElevatedButton(
                onPressed: () {
                  // TODO: 스토어 평점 페이지로 이동
                  Navigator.pop(context, true);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF8B6914),
                ),
                child: const Text('평점 남기기'),
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
