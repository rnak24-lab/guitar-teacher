import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class PracticeSession {
  final String type; // fretboard, octave, chord, scale, metronome
  final DateTime timestamp;
  final int durationSeconds;

  PracticeSession({
    required this.type,
    required this.timestamp,
    required this.durationSeconds,
  });

  Map<String, dynamic> toJson() => {
    'type': type,
    'timestamp': timestamp.toIso8601String(),
    'durationSeconds': durationSeconds,
  };

  factory PracticeSession.fromJson(Map<String, dynamic> json) => PracticeSession(
    type: json['type'],
    timestamp: DateTime.parse(json['timestamp']),
    durationSeconds: json['durationSeconds'] ?? 0,
  );
}

class PracticeGoal {
  final int dailyMinutes; // daily goal in minutes
  final DateTime createdAt;

  PracticeGoal({required this.dailyMinutes, required this.createdAt});

  Map<String, dynamic> toJson() => {
    'dailyMinutes': dailyMinutes,
    'createdAt': createdAt.toIso8601String(),
  };

  factory PracticeGoal.fromJson(Map<String, dynamic> json) => PracticeGoal(
    dailyMinutes: json['dailyMinutes'] ?? 30,
    createdAt: DateTime.parse(json['createdAt']),
  );
}

class WeeklyStats {
  final int totalSessions;
  final int totalMinutes;
  final int streak; // consecutive days practiced
  final Map<String, int> sessionsByType;
  final Map<String, int> minutesByType;

  WeeklyStats({
    required this.totalSessions,
    required this.totalMinutes,
    required this.streak,
    required this.sessionsByType,
    required this.minutesByType,
  });
}

class PracticeRecord {
  static const _key = 'practice_records';

  static Future<void> saveSession(PracticeSession session) async {
    final prefs = await SharedPreferences.getInstance();
    final records = await _loadAll(prefs);
    records.add(session);
    // Keep only last 90 days
    final cutoff = DateTime.now().subtract(const Duration(days: 90));
    records.removeWhere((r) => r.timestamp.isBefore(cutoff));
    await prefs.setString(_key, jsonEncode(records.map((r) => r.toJson()).toList()));
  }

  static Future<List<PracticeSession>> _loadAll(SharedPreferences prefs) async {
    final raw = prefs.getString(_key);
    if (raw == null) return [];
    final list = jsonDecode(raw) as List;
    return list.map((e) => PracticeSession.fromJson(e)).toList();
  }

  static Future<List<PracticeSession>> getAllSessions() async {
    final prefs = await SharedPreferences.getInstance();
    return _loadAll(prefs);
  }

  static Future<List<PracticeSession>> getWeekSessions() async {
    final all = await getAllSessions();
    final weekAgo = DateTime.now().subtract(const Duration(days: 7));
    return all.where((s) => s.timestamp.isAfter(weekAgo)).toList();
  }

  static Future<WeeklyStats> getWeeklyStats() async {
    final sessions = await getWeekSessions();
    final totalMinutes = sessions.fold<int>(0, (sum, s) => sum + s.durationSeconds) ~/ 60;

    // Calculate streak
    final allSessions = await getAllSessions();
    int streak = 0;
    final today = DateTime.now();
    for (int i = 0; i < 365; i++) {
      final day = today.subtract(Duration(days: i));
      final hasSession = allSessions.any((s) =>
          s.timestamp.year == day.year &&
          s.timestamp.month == day.month &&
          s.timestamp.day == day.day);
      if (hasSession) {
        streak++;
      } else {
        break;
      }
    }

    // Sessions and minutes by type
    final byType = <String, int>{};
    final minsByType = <String, int>{};
    for (final s in sessions) {
      byType[s.type] = (byType[s.type] ?? 0) + 1;
      minsByType[s.type] = (minsByType[s.type] ?? 0) + (s.durationSeconds ~/ 60);
    }

    return WeeklyStats(
      totalSessions: sessions.length,
      totalMinutes: totalMinutes,
      streak: streak,
      sessionsByType: byType,
      minutesByType: minsByType,
    );
  }

  /// Simulated percentile ranking based on practice time (no Firebase needed)
  static int estimatePercentile(WeeklyStats stats) {
    final mins = stats.totalMinutes;
    if (mins >= 300) return 1;  // 5+ hours/week => top 1%
    if (mins >= 180) return 5;  // 3+ hours => top 5%
    if (mins >= 120) return 10; // 2+ hours => top 10%
    if (mins >= 60) return 20;  // 1+ hour => top 20%
    if (mins >= 30) return 35;  // 30min => top 35%
    if (mins >= 15) return 50;  // 15min => top 50%
    if (mins >= 5) return 70;
    if (mins > 0) return 85;
    return 99;
  }

  // ── Goal management ──

  static const _goalKey = 'practice_goal';

  static Future<void> saveGoal(PracticeGoal goal) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_goalKey, jsonEncode(goal.toJson()));
  }

  static Future<PracticeGoal> getGoal() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_goalKey);
    if (raw == null) {
      return PracticeGoal(dailyMinutes: 30, createdAt: DateTime.now());
    }
    return PracticeGoal.fromJson(jsonDecode(raw));
  }

  // ── Calendar data: minutes per day ──

  static Future<Map<DateTime, int>> getDailyMinutesMap() async {
    final all = await getAllSessions();
    final map = <DateTime, int>{};
    for (final s in all) {
      final dayKey = DateTime(s.timestamp.year, s.timestamp.month, s.timestamp.day);
      map[dayKey] = (map[dayKey] ?? 0) + (s.durationSeconds ~/ 60);
    }
    return map;
  }

  /// Days that met the daily goal
  static Future<int> getGoalMetDays() async {
    final goal = await getGoal();
    final dailyMap = await getDailyMinutesMap();
    return dailyMap.values.where((mins) => mins >= goal.dailyMinutes).length;
  }

  // ── Growth trend: weekly totals for last 8 weeks ──

  static Future<List<int>> getWeeklyTrend() async {
    final all = await getAllSessions();
    final now = DateTime.now();
    final weeklyMins = List.filled(8, 0);
    for (final s in all) {
      final daysAgo = now.difference(s.timestamp).inDays;
      final weekIndex = daysAgo ~/ 7;
      if (weekIndex < 8) {
        weeklyMins[7 - weekIndex] += s.durationSeconds ~/ 60;
      }
    }
    return weeklyMins;
  }

  // ── Daily bar data for last 7 days ──

  static Future<List<int>> getDailyBarsLast7() async {
    final all = await getAllSessions();
    final now = DateTime.now();
    final daily = List.filled(7, 0);
    for (final s in all) {
      final daysAgo = now.difference(DateTime(s.timestamp.year, s.timestamp.month, s.timestamp.day)).inDays;
      if (daysAgo >= 0 && daysAgo < 7) {
        daily[6 - daysAgo] += s.durationSeconds ~/ 60;
      }
    }
    return daily;
  }
}
