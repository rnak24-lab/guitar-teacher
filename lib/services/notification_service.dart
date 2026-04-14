import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest_all.dart' as tzdata;
import 'package:permission_handler/permission_handler.dart';
import 'app_localizations.dart';
import 'practice_record.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._();
  factory NotificationService() => _instance;
  NotificationService._();

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  // Channel IDs
  static const _channelId = 'practice_reminder';
  static const _channelName = 'Practice Reminder';
  static const _streakChannelId = 'streak_notification';
  static const _streakChannelName = 'Streak Notification';
  static const _comebackChannelId = 'comeback_reminder';
  static const _comebackChannelName = 'Comeback Reminder';

  // Notification IDs
  static const _notifId = 100;
  static const _streakNotifId = 200;
  static const _comebackNotifId = 300;

  // Pref keys
  static const _keyEnabled = 'reminder_enabled';
  static const _keyHour = 'reminder_hour';
  static const _keyMinute = 'reminder_minute';
  static const _keyStreakEnabled = 'streak_notif_enabled';
  static const _keyComebackEnabled = 'comeback_notif_enabled';
  static const _keyLastOpenDate = 'last_app_open_date';
  static const _keyPermissionAsked = 'notification_permission_asked';

  // ── Localized messages ──

  static const Map<String, String> _localizedBody = {
    'ko': '오늘 기타 연습 했나요? 함께 연습해요!',
    'ja': '今日ギターの練習はしましたか？一緒に練習しましょう！',
    'zh': '今天练吉他了吗？一起来练习吧！',
    'vi': 'Hom nay ban da tap guitar chua? Hay cung tap nao!',
    'fr': 'Avez-vous pratiqué la guitare aujourd\'hui ? Jouons ensemble !',
    'es': '¿Practicaste guitarra hoy? ¡Toquemos juntos!',
    'en': 'Did you practice guitar today? Let\'s play together!',
  };

  static final Map<String, String Function(int)> _streakBody = {
    'ko': (d) => '$d일 연속 연습 중! 이 기세 이어가요',
    'ja': (d) => '$d日連続練習中！この調子で続けましょう',
    'zh': (d) => '连续练习$d天！继续保持',
    'vi': (d) => 'Tap lien tuc $d ngay! Hay giu vung nhip do',
    'fr': (d) => '$d jours consecutifs ! Continuez ainsi',
    'es': (d) => '$d dias seguidos practicando! Sigue asi!',
    'en': (d) => '$d-day streak! Keep up the momentum',
  };

  static final Map<String, String Function(int)> _comebackBody = {
    'ko': (d) => '$d일째 연습을 쉬셨네요. 잠깐 튜닝부터 시작해볼까요?',
    'ja': (d) => '$d日間練習をお休みですね。チューニングから始めませんか？',
    'zh': (d) => '已经$d天没练习了，从调音开始吧？',
    'vi': (d) => 'Da $d ngay chua tap roi. Bat dau tu viec len day nhe?',
    'fr': (d) => '$d jours sans pratiquer. On commence par l\'accordage ?',
    'es': (d) => '$d dias sin practicar. Empezamos afinando?',
    'en': (d) => "You've been away for $d days. Start with a quick tune-up?",
  };

  String _getLocalizedBody() {
    final lang = AppLocalizations().locale;
    return _localizedBody[lang] ?? _localizedBody['en']!;
  }

  String _getStreakBody(int days) {
    final lang = AppLocalizations().locale;
    final fn = _streakBody[lang] ?? _streakBody['en']!;
    return fn(days);
  }

  String _getComebackBody(int days) {
    final lang = AppLocalizations().locale;
    final fn = _comebackBody[lang] ?? _comebackBody['en']!;
    return fn(days);
  }

  // ── Init ──

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

  // ── Daily Reminder Settings ──

  Future<({bool enabled, int hour, int minute})> getSettings() async {
    final prefs = await SharedPreferences.getInstance();
    return (
      enabled: prefs.getBool(_keyEnabled) ?? false,
      hour: prefs.getInt(_keyHour) ?? 20,
      minute: prefs.getInt(_keyMinute) ?? 0,
    );
  }

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

  // ── Streak Notification ──

  Future<bool> isStreakEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keyStreakEnabled) ?? true; // default ON
  }

  Future<void> setStreakEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyStreakEnabled, enabled);
  }

  /// Show streak notification immediately when a practice session ends.
  /// Call this after saving a PracticeSession.
  Future<void> checkAndShowStreak() async {
    if (!(await isStreakEnabled())) return;

    final stats = await PracticeRecord.getWeeklyStats();
    final streak = stats.streak;

    // Only notify on milestones: 3, 5, 7, 10, 14, 21, 30, ...
    if (!_isStreakMilestone(streak)) return;

    final body = _getStreakBody(streak);

    final androidDetails = AndroidNotificationDetails(
      _streakChannelId,
      _streakChannelName,
      channelDescription: 'Practice streak achievements',
      importance: Importance.defaultImportance,
      priority: Priority.defaultPriority,
    );
    const iosDetails = DarwinNotificationDetails();
    final details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _plugin.show(_streakNotifId, 'Guitar Educator', body, details);
  }

  bool _isStreakMilestone(int streak) {
    return streak == 3 || streak == 5 || streak == 7 ||
           streak == 10 || streak == 14 || streak == 21 ||
           streak == 30 || (streak > 30 && streak % 10 == 0);
  }

  // ── Comeback (Inactivity) Reminder ──

  Future<bool> isComebackEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keyComebackEnabled) ?? true; // default ON
  }

  Future<void> setComebackEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyComebackEnabled, enabled);
    if (!enabled) {
      await _plugin.cancel(_comebackNotifId);
    }
  }

  /// Record the current date as last app-open date.
  Future<void> recordAppOpen() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyLastOpenDate, DateTime.now().toIso8601String());
  }

  /// Schedule a comeback reminder 3 days from now.
  /// Call on each app open; it resets the 3-day timer.
  Future<void> scheduleComebackReminder() async {
    if (!(await isComebackEnabled())) return;

    await _plugin.cancel(_comebackNotifId);

    final now = tz.TZDateTime.now(tz.local);
    // Schedule for 3 days later at 19:00
    final scheduled = tz.TZDateTime(
      tz.local, now.year, now.month, now.day + 3, 19, 0,
    );

    final body = _getComebackBody(3);

    final androidDetails = AndroidNotificationDetails(
      _comebackChannelId,
      _comebackChannelName,
      channelDescription: 'Reminds you to come back after inactivity',
      importance: Importance.defaultImportance,
      priority: Priority.defaultPriority,
    );
    const iosDetails = DarwinNotificationDetails();
    final details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _plugin.zonedSchedule(
      _comebackNotifId,
      'Guitar Educator',
      body,
      scheduled,
      details,
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
    );
  }

  // ── Restore / Refresh ──

  /// Re-schedule on app start if enabled (picks current locale).
  Future<void> restoreIfEnabled() async {
    final s = await getSettings();
    if (s.enabled) {
      await _scheduleDailyNotification(s.hour, s.minute);
    }
    // Always reset comeback timer on app open
    await recordAppOpen();
    await scheduleComebackReminder();
  }

  /// Call when user changes app language so notification text updates.
  Future<void> refreshLocale() async {
    final s = await getSettings();
    if (s.enabled) {
      await _scheduleDailyNotification(s.hour, s.minute);
    }
    // Re-schedule comeback with updated locale
    await scheduleComebackReminder();
  }

  /// Get all notification preferences for the settings screen.
  Future<({bool reminder, bool streak, bool comeback})> getAllPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    return (
      reminder: prefs.getBool(_keyEnabled) ?? false,
      streak: prefs.getBool(_keyStreakEnabled) ?? true,
      comeback: prefs.getBool(_keyComebackEnabled) ?? true,
    );
  }

  // ── Permission Request (Android 13+) ──

  /// Check if we already asked for notification permission.
  Future<bool> wasPermissionAsked() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keyPermissionAsked) ?? false;
  }

  /// Request notification permission. Returns true if granted.
  Future<bool> requestPermission() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyPermissionAsked, true);

    final status = await Permission.notification.request();
    return status.isGranted;
  }

  /// Show the first-launch notification consent dialog.
  /// Returns true if user accepted; false if declined.
  /// Automatically requests OS-level permission if accepted.
  Future<bool> showConsentDialog(BuildContext context) async {
    // Already asked? Skip.
    if (await wasPermissionAsked()) return true;

    final loc = AppLocalizations();
    final title = loc.t('notif_consent_title');
    final body = loc.t('notif_consent_body');
    final accept = loc.t('notif_consent_accept');
    final decline = loc.t('notif_consent_decline');

    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        icon: const Icon(Icons.notifications_active, size: 48, color: Color(0xFF8B6914)),
        title: Text(title, textAlign: TextAlign.center),
        content: Text(body, textAlign: TextAlign.center),
        actionsAlignment: MainAxisAlignment.center,
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(decline),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF8B6914),
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(accept),
          ),
        ],
      ),
    );

    if (result == true) {
      final granted = await requestPermission();
      if (granted) {
        // Auto-enable daily reminder at 20:00 as sensible default
        await setReminder(enabled: true, hour: 20, minute: 0);
      }
      return granted;
    } else {
      // User declined — mark as asked so we don't show again
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_keyPermissionAsked, true);
      return false;
    }
  }
}
