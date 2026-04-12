import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest_all.dart' as tzdata;
import 'app_localizations.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._();
  factory NotificationService() => _instance;
  NotificationService._();

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  static const _channelId = 'practice_reminder';
  static const _channelName = 'Practice Reminder';
  static const _notifId = 100;

  // Pref keys
  static const _keyEnabled = 'reminder_enabled';
  static const _keyHour = 'reminder_hour';
  static const _keyMinute = 'reminder_minute';

  /// Localized notification body messages keyed by language code.
  static const Map<String, String> _localizedBody = {
    'ko': '오늘 기타 연습 했나요? 함께 연습해요!',
    'ja': '今日ギターの練習はしましたか？一緒に練習しましょう！',
    'zh': '今天练吉他了吗？一起来练习吧！',
    'vi': 'Hom nay ban da tap guitar chua? Hay cung tap nao!',
    'fr': 'Avez-vous pratique la guitare aujourd\'hui ? Jouons ensemble !',
    'es': 'Practicaste guitarra hoy? Toquemos juntos!',
    'en': 'Did you practice guitar today? Let\'s play together!',
  };

  /// Get the notification body in the current app language.
  String _getLocalizedBody() {
    final lang = AppLocalizations().locale;
    return _localizedBody[lang] ?? _localizedBody['en']!;
  }

  Future<void> init() async {
    tzdata.initializeTimeZones();

    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );
    const settings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );
    await _plugin.initialize(settings);
  }

  /// Read saved reminder settings.
  Future<({bool enabled, int hour, int minute})> getSettings() async {
    final prefs = await SharedPreferences.getInstance();
    return (
      enabled: prefs.getBool(_keyEnabled) ?? false,
      hour: prefs.getInt(_keyHour) ?? 20,
      minute: prefs.getInt(_keyMinute) ?? 0,
    );
  }

  /// Save and apply reminder settings.
  Future<void> setReminder({
    required bool enabled,
    required int hour,
    required int minute,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyEnabled, enabled);
    await prefs.setInt(_keyHour, hour);
    await prefs.setInt(_keyMinute, minute);

    if (enabled) {
      await _scheduleDailyNotification(hour, minute);
    } else {
      await _plugin.cancel(_notifId);
    }
  }

  Future<void> _scheduleDailyNotification(int hour, int minute) async {
    await _plugin.cancel(_notifId);

    final now = tz.TZDateTime.now(tz.local);
    var scheduled = tz.TZDateTime(tz.local, now.year, now.month, now.day, hour, minute);
    if (scheduled.isBefore(now)) {
      scheduled = scheduled.add(const Duration(days: 1));
    }

    final body = _getLocalizedBody();

    const androidDetails = AndroidNotificationDetails(
      _channelId,
      _channelName,
      channelDescription: 'Daily guitar practice reminder',
      importance: Importance.high,
      priority: Priority.high,
    );
    const iosDetails = DarwinNotificationDetails();
    const details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _plugin.zonedSchedule(
      _notifId,
      'Guitar Educator',
      body,
      scheduled,
      details,
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }

  /// Re-schedule on app start if enabled (picks current locale).
  Future<void> restoreIfEnabled() async {
    final s = await getSettings();
    if (s.enabled) {
      await _scheduleDailyNotification(s.hour, s.minute);
    }
  }

  /// Call when user changes app language so notification text updates.
  Future<void> refreshLocale() async {
    final s = await getSettings();
    if (s.enabled) {
      await _scheduleDailyNotification(s.hour, s.minute);
    }
  }
}
