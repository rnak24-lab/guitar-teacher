import 'package:flutter/material.dart';
import '../../main.dart';
import '../../services/app_localizations.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final appState = GuitarTeacherApp.of(context);
    final isDark = appState?.isDarkMode ?? false;

    return Scaffold(
      appBar: AppBar(title: Text(tr('settings_title'))),
      body: ListView(
        children: [
          // === Display ===
          _SectionHeader(title: tr('settings_display')),
          SwitchListTile(
            title: Text(tr('settings_dark_mode')),
            subtitle: Text(isDark ? tr('settings_dark_on') : tr('settings_dark_off')),
            secondary: Icon(isDark ? Icons.dark_mode : Icons.light_mode),
            value: isDark,
            onChanged: (v) => appState?.toggleDarkMode(),
          ),
          const Divider(),

          // === Sound ===
          _SectionHeader(title: tr('settings_sound')),
          ListTile(
            leading: const Icon(Icons.volume_up),
            title: Text(tr('settings_metronome_vol')),
            subtitle: Text(tr('settings_vol_system')),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _showVolumeDialog(context),
          ),
          ListTile(
            leading: const Icon(Icons.vibration),
            title: Text(tr('settings_vibration')),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(tr('settings_vibration_on')),
                const SizedBox(height: 4),
                Text(
                  tr('settings_vibration_desc'),
                  style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                ),
              ],
            ),
            isThreeLine: true,
          ),
          const Divider(),

          // === Guitar Settings ===
          _SectionHeader(title: tr('settings_guitar')),
          ListTile(
            leading: const Icon(Icons.music_note),
            title: Text(tr('settings_tuning')),
            subtitle: Text(tr('settings_tuning_standard')),
            trailing: const Icon(Icons.chevron_right),
          ),
          const Divider(),

          // === Language ===
          _SectionHeader(title: tr('settings_language')),
          ...AppLocalizations.supportedLocales.entries.map((entry) {
            final isSelected = AppLocalizations().locale == entry.key;
            return ListTile(
              leading: Text(_flagEmoji(entry.key), style: const TextStyle(fontSize: 24)),
              title: Text(entry.value),
              trailing: isSelected
                  ? const Icon(Icons.check_circle, color: Color(0xFF8B6914))
                  : null,
              onTap: () {
                appState?.setLocale(entry.key);
                Navigator.pop(context);
                Navigator.push(context, MaterialPageRoute(builder: (_) => const SettingsScreen()));
              },
            );
          }),
          const Divider(),

          // === About ===
          _SectionHeader(title: tr('settings_info')),
          ListTile(
            leading: const Icon(Icons.info_outline),
            title: const Text('Guitar Educator'),
            subtitle: Text(tr('settings_version')),
          ),
          ListTile(
            leading: const Icon(Icons.star),
            title: Text(tr('settings_rate')),
            onTap: () {
              // TODO: Store link
            },
          ),
          ListTile(
            leading: const Icon(Icons.share),
            title: Text(tr('settings_share')),
            onTap: () {
              // TODO: Share function
            },
          ),
        ],
      ),
    );
  }

  String _flagEmoji(String code) {
    switch (code) {
      case 'en': return '🇺🇸';
      case 'ko': return '🇰🇷';
      case 'ja': return '🇯🇵';
      case 'zh': return '🇨🇳';
      case 'vi': return '🇻🇳';
      case 'fr': return '🇫🇷';
      case 'es': return '🇪🇸';
      default: return '🌐';
    }
  }

  void _showVolumeDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(tr('settings_metronome_vol')),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _volumeOption(ctx, Icons.volume_mute, tr('settings_vol_system'), true),
            _volumeOption(ctx, Icons.volume_down, tr('settings_vol_low'), false),
            _volumeOption(ctx, Icons.volume_up, tr('settings_vol_medium'), false),
            _volumeOption(ctx, Icons.volume_up_rounded, tr('settings_vol_high'), false),
          ],
        ),
      ),
    );
  }

  Widget _volumeOption(BuildContext ctx, IconData icon, String label, bool selected) {
    return ListTile(
      leading: Icon(icon, color: selected ? const Color(0xFF8B6914) : null),
      title: Text(label),
      trailing: selected ? const Icon(Icons.check, color: Color(0xFF8B6914)) : null,
      onTap: () => Navigator.pop(ctx),
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
