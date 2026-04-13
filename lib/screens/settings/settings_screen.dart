import 'package:flutter/material.dart';
import '../../main.dart';
import '../../services/app_localizations.dart';
import '../../services/notification_service.dart';
import '../../providers/note_name_provider.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _reminderEnabled = false;
  int _reminderHour = 20;
  int _reminderMinute = 0;
  bool _streakEnabled = true;
  bool _comebackEnabled = true;
  String _noteSystem = NoteNameProvider().system;

  @override
  void initState() {
    super.initState();
    _loadReminderSettings();
  }

  Future<void> _loadReminderSettings() async {
    final s = await NotificationService().getSettings();
    final prefs = await NotificationService().getAllPreferences();
    if (mounted) {
      setState(() {
        _reminderEnabled = s.enabled;
        _reminderHour = s.hour;
        _reminderMinute = s.minute;
        _streakEnabled = prefs.streak;
        _comebackEnabled = prefs.comeback;
      });
    }
  }

  Future<void> _toggleReminder(bool enabled) async {
    setState(() => _reminderEnabled = enabled);
    await NotificationService().setReminder(
      enabled: enabled,
      hour: _reminderHour,
      minute: _reminderMinute,
    );
  }

  Future<void> _pickReminderTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: _reminderHour, minute: _reminderMinute),
    );
    if (picked != null) {
      setState(() {
        _reminderHour = picked.hour;
        _reminderMinute = picked.minute;
      });
      if (_reminderEnabled) {
        await NotificationService().setReminder(
          enabled: true,
          hour: picked.hour,
          minute: picked.minute,
        );
      }
    }
  }

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
          // Note name system (alphabet / solfege)
          ListTile(
            leading: const Icon(Icons.music_note),
            title: Text(tr('settings_note_system')),
            subtitle: Text(
              _noteSystem == 'solfege'
                  ? tr('settings_note_solfege')
                  : tr('settings_note_alphabet'),
            ),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _showNoteSystemDialog(context),
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
            subtitle: Text(tr('settings_vibration_on')),
            trailing: IconButton(
              icon: Icon(Icons.help_outline, size: 20, color: Colors.grey[400]),
              tooltip: tr('settings_vibration_desc'),
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    title: Row(
                      children: [
                        const Icon(Icons.vibration, size: 20),
                        const SizedBox(width: 8),
                        Text(tr('settings_vibration')),
                      ],
                    ),
                    content: Text(tr('settings_vibration_desc')),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(ctx),
                        child: const Text('OK'),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
          const Divider(),

          // === Practice Reminder ===
          _SectionHeader(title: tr('settings_reminder')),
          SwitchListTile(
            title: Text(tr('settings_daily_reminder')),
            subtitle: Text(
              _reminderEnabled
                  ? '${tr('settings_reminder_every_day')} ${_reminderHour.toString().padLeft(2, '0')}:${_reminderMinute.toString().padLeft(2, '0')}'
                  : tr('settings_off'),
            ),
            secondary: Icon(
              _reminderEnabled
                  ? Icons.notifications_active
                  : Icons.notifications_off_outlined,
            ),
            value: _reminderEnabled,
            onChanged: _toggleReminder,
          ),
          if (_reminderEnabled)
            ListTile(
              leading: const Icon(Icons.access_time),
              title: Text(tr('settings_reminder_time')),
              subtitle: Text(
                '${_reminderHour.toString().padLeft(2, '0')}:${_reminderMinute.toString().padLeft(2, '0')}',
              ),
              trailing: const Icon(Icons.chevron_right),
              onTap: _pickReminderTime,
            ),
          SwitchListTile(
            title: Text(tr('settings_streak_notif')),
            subtitle: Text(tr('settings_streak_notif_desc')),
            secondary: const Icon(Icons.local_fire_department),
            value: _streakEnabled,
            onChanged: (v) async {
              setState(() => _streakEnabled = v);
              await NotificationService().setStreakEnabled(v);
            },
          ),
          SwitchListTile(
            title: Text(tr('settings_comeback_notif')),
            subtitle: Text(tr('settings_comeback_notif_desc')),
            secondary: const Icon(Icons.waving_hand),
            value: _comebackEnabled,
            onChanged: (v) async {
              setState(() => _comebackEnabled = v);
              await NotificationService().setComebackEnabled(v);
            },
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
                NotificationService().refreshLocale();
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
          ListTile(
            leading: const Icon(Icons.privacy_tip_outlined),
            title: const Text('Privacy Policy'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const _PrivacyPolicyScreen()),
            ),
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

  void _showNoteSystemDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(tr('settings_note_system')),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _noteSystemOption(ctx, 'alphabet', tr('settings_note_alphabet'), 'C - D - E - F - G - A - B'),
            const SizedBox(height: 8),
            _noteSystemOption(ctx, 'solfege', tr('settings_note_solfege'), 'Do - Re - Mi - Fa - Sol - La - Si'),
          ],
        ),
      ),
    );
  }

  Widget _noteSystemOption(BuildContext ctx, String system, String label, String example) {
    final isSelected = _noteSystem == system;
    return ListTile(
      leading: Icon(
        isSelected ? Icons.check_circle : Icons.circle_outlined,
        color: isSelected ? const Color(0xFF8B6914) : null,
      ),
      title: Text(label),
      subtitle: Text(example, style: TextStyle(fontSize: 12, color: Colors.grey[500])),
      onTap: () async {
        await NoteNameProvider().setSystem(system);
        setState(() => _noteSystem = system);
        if (ctx.mounted) Navigator.pop(ctx);
      },
    );
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

class _PrivacyPolicyScreen extends StatelessWidget {
  const _PrivacyPolicyScreen();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Privacy Policy')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [
            Text(
              'Privacy Policy',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            Text(
              'Last updated: April 2025',
              style: TextStyle(fontSize: 13, color: Colors.grey),
            ),
            SizedBox(height: 20),
            _PolicySection(
              title: 'Data Collection',
              body: 'Guitar Educator does not collect any personal data. '
                  'We do not require account creation, and no personally '
                  'identifiable information is gathered.',
            ),
            _PolicySection(
              title: 'Local Storage',
              body: 'Your practice records and app preferences are stored '
                  'locally on your device only (using SharedPreferences). '
                  'This data never leaves your device.',
            ),
            _PolicySection(
              title: 'Network & Servers',
              body: 'No data is transmitted to external servers. '
                  'Guitar Educator operates entirely offline.',
            ),
            _PolicySection(
              title: 'Advertising',
              body: 'Guitar Educator uses Google AdMob to display ads. '
                  'AdMob may collect device identifiers and usage data '
                  'to serve personalized or non-personalized ads. '
                  'You can manage ad preferences in your device settings. '
                  'For more information, see Google\'s Privacy Policy.',
            ),
            _PolicySection(
              title: 'Contact',
              body: 'If you have any questions about this Privacy Policy, '
                  'please contact us at rnak24@gmail.com.',
            ),
          ],
        ),
      ),
    );
  }
}

class _PolicySection extends StatelessWidget {
  final String title;
  final String body;
  const _PolicySection({required this.title, required this.body});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
          const SizedBox(height: 6),
          Text(body, style: const TextStyle(fontSize: 14, height: 1.5)),
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
