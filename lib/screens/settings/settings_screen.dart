import 'package:flutter/material.dart';
import '../../main.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final appState = GuitarTeacherApp.of(context);
    final isDark = appState?.isDarkMode ?? false;

    return Scaffold(
      appBar: AppBar(title: const Text('설정')),
      body: ListView(
        children: [
          const _SectionHeader(title: '화면'),
          SwitchListTile(
            title: const Text('다크 모드'),
            subtitle: Text(isDark ? '어두운 화면' : '밝은 화면'),
            secondary: Icon(isDark ? Icons.dark_mode : Icons.light_mode),
            value: isDark,
            onChanged: (v) => appState?.toggleDarkMode(),
          ),
          const Divider(),
          const _SectionHeader(title: '소리'),
          const ListTile(
            leading: Icon(Icons.volume_up),
            title: Text('메트로놈 볼륨'),
            subtitle: Text('시스템 볼륨 사용'),
          ),
          const ListTile(
            leading: Icon(Icons.vibration),
            title: Text('진동 피드백'),
            subtitle: Text('켜짐'),
          ),
          const Divider(),
          const _SectionHeader(title: '기타 설정'),
          const ListTile(
            leading: Icon(Icons.music_note),
            title: Text('튜닝'),
            subtitle: Text('표준 (EADGBE)'),
            trailing: Icon(Icons.chevron_right),
          ),
          const ListTile(
            leading: Icon(Icons.straighten),
            title: Text('프렛 범위'),
            subtitle: Text('0 ~ 12프렛'),
            trailing: Icon(Icons.chevron_right),
          ),
          const Divider(),
          const _SectionHeader(title: '정보'),
          const ListTile(
            leading: Icon(Icons.info_outline),
            title: Text('Guitar Teacher'),
            subtitle: Text('v1.0.0 by Endolphin Studio'),
          ),
          ListTile(
            leading: const Icon(Icons.star),
            title: const Text('앱 평점 남기기'),
            onTap: () {
              // TODO: 스토어 링크
            },
          ),
          ListTile(
            leading: const Icon(Icons.share),
            title: const Text('앱 공유하기'),
            onTap: () {
              // TODO: 공유 기능
            },
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
      child: Text(title, style: TextStyle(
        fontSize: 14, fontWeight: FontWeight.bold,
        color: Theme.of(context).colorScheme.primary)),
    );
  }
}
