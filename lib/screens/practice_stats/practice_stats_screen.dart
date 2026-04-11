import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/intl.dart';
import '../../services/practice_record.dart';

class PracticeStatsScreen extends StatefulWidget {
  const PracticeStatsScreen({super.key});

  @override
  State<PracticeStatsScreen> createState() => _PracticeStatsScreenState();
}

class _PracticeStatsScreenState extends State<PracticeStatsScreen> {
  WeeklyStats? _stats;
  List<PracticeSession>? _weekSessions;
  PracticeGoal? _goal;
  Map<DateTime, int>? _dailyMap;
  List<int>? _weeklyTrend;
  List<int>? _dailyBars;
  int _goalMetDays = 0;
  bool _loading = true;
  DateTime _focusedDay = DateTime.now();

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final stats = await PracticeRecord.getWeeklyStats();
    final sessions = await PracticeRecord.getWeekSessions();
    final goal = await PracticeRecord.getGoal();
    final dailyMap = await PracticeRecord.getDailyMinutesMap();
    final weeklyTrend = await PracticeRecord.getWeeklyTrend();
    final dailyBars = await PracticeRecord.getDailyBarsLast7();
    final goalMetDays = await PracticeRecord.getGoalMetDays();
    if (mounted) {
      setState(() {
        _stats = stats;
        _weekSessions = sessions;
        _goal = goal;
        _dailyMap = dailyMap;
        _weeklyTrend = weeklyTrend;
        _dailyBars = dailyBars;
        _goalMetDays = goalMetDays;
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primary = Theme.of(context).colorScheme.primary;
    final accent = const Color(0xFF16A085);

    return Scaffold(
      appBar: AppBar(title: const Text('Practice Record')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _stats == null
              ? const Center(child: Text('No data'))
              : RefreshIndicator(
                  onRefresh: _load,
                  child: ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      // 1) Goal progress card
                      _buildGoalCard(accent, isDark),
                      const SizedBox(height: 16),
                      // 2) Daily bar chart (last 7 days)
                      _buildDailyBarChart(accent, isDark),
                      const SizedBox(height: 16),
                      // 3) Growth trend line chart (8 weeks)
                      _buildGrowthTrendChart(accent, isDark),
                      const SizedBox(height: 16),
                      // 4) Calendar with stamps
                      _buildCalendarStamps(accent, isDark),
                      const SizedBox(height: 16),
                      // 5) Streak + summary
                      _buildStreakCard(isDark),
                      const SizedBox(height: 16),
                      // 6) Percentile card
                      _buildPercentileCard(primary),
                      const SizedBox(height: 16),
                      // 7) Practice by type
                      _buildTypeBreakdown(isDark),
                      const SizedBox(height: 16),
                      // 8) Recent sessions
                      _buildRecentSessions(isDark),
                      const SizedBox(height: 60),
                    ],
                  ),
                ),
    );
  }

  // ── 1) Goal progress ──

  Widget _buildGoalCard(Color accent, bool isDark) {
    final goalMins = _goal?.dailyMinutes ?? 30;
    final now = DateTime.now();
    final todayKey = DateTime(now.year, now.month, now.day);
    final todayMins = _dailyMap?[todayKey] ?? 0;
    final progress = (todayMins / goalMins).clamp(0.0, 1.0);

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text("Today's Goal",
                    style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : Colors.brown[800])),
                GestureDetector(
                  onTap: () => _showGoalDialog(),
                  child: Row(
                    children: [
                      Icon(Icons.edit, size: 16, color: accent),
                      const SizedBox(width: 4),
                      Text('${goalMins}min/day',
                          style: TextStyle(fontSize: 13, color: accent, fontWeight: FontWeight.w600)),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  width: 120,
                  height: 120,
                  child: CircularProgressIndicator(
                    value: progress,
                    strokeWidth: 10,
                    backgroundColor: Colors.grey[300],
                    valueColor: AlwaysStoppedAnimation(
                        progress >= 1.0 ? Colors.amber : accent),
                  ),
                ),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('$todayMins',
                        style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold)),
                    Text('/ ${goalMins}min',
                        style: TextStyle(fontSize: 13, color: Colors.grey[600])),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (progress >= 1.0)
              const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.check_circle, color: Colors.amber, size: 20),
                  SizedBox(width: 4),
                  Text('Goal achieved!',
                      style: TextStyle(
                          fontWeight: FontWeight.bold, color: Colors.amber)),
                ],
              ),
            const SizedBox(height: 8),
            Text('Goal met: $_goalMetDays days total',
                style: TextStyle(fontSize: 12, color: Colors.grey[500])),
          ],
        ),
      ),
    );
  }

  void _showGoalDialog() {
    final controller =
        TextEditingController(text: '${_goal?.dailyMinutes ?? 30}');
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Set Daily Goal'),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            labelText: 'Minutes per day',
            suffixText: 'min',
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel')),
          FilledButton(
            onPressed: () async {
              final mins = int.tryParse(controller.text);
              if (mins != null && mins > 0) {
                await PracticeRecord.saveGoal(
                    PracticeGoal(dailyMinutes: mins, createdAt: DateTime.now()));
                if (ctx.mounted) Navigator.pop(ctx);
                _load();
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  // ── 2) Daily bar chart (last 7 days) ──

  Widget _buildDailyBarChart(Color accent, bool isDark) {
    final bars = _dailyBars ?? List.filled(7, 0);
    final maxVal = bars.reduce((a, b) => a > b ? a : b).toDouble();
    final now = DateTime.now();

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Last 7 Days',
                style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : Colors.brown[800])),
            const SizedBox(height: 16),
            SizedBox(
              height: 180,
              child: BarChart(
                BarChartData(
                  maxY: maxVal > 0 ? maxVal * 1.2 : 30,
                  barTouchData: BarTouchData(
                    touchTooltipData: BarTouchTooltipData(
                      getTooltipItem: (group, groupIndex, rod, rodIndex) {
                        return BarTooltipItem(
                          '${rod.toY.toInt()}min',
                          const TextStyle(color: Colors.white, fontSize: 12),
                        );
                      },
                    ),
                  ),
                  titlesData: FlTitlesData(
                    leftTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false)),
                    rightTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false)),
                    topTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false)),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          final day =
                              now.subtract(Duration(days: 6 - value.toInt()));
                          return SideTitleWidget(
                            axisSide: meta.axisSide,
                            child: Text(
                              DateFormat.E().format(day),
                              style: const TextStyle(fontSize: 11),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                  gridData: const FlGridData(show: false),
                  borderData: FlBorderData(show: false),
                  barGroups: List.generate(7, (i) {
                    final goalMins = _goal?.dailyMinutes ?? 30;
                    final met = bars[i] >= goalMins;
                    return BarChartGroupData(
                      x: i,
                      barRods: [
                        BarChartRodData(
                          toY: bars[i].toDouble(),
                          color: met ? Colors.amber : accent,
                          width: 20,
                          borderRadius:
                              const BorderRadius.vertical(top: Radius.circular(6)),
                        ),
                      ],
                    );
                  }),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── 3) Growth trend (8 weeks line chart) ──

  Widget _buildGrowthTrendChart(Color accent, bool isDark) {
    final trend = _weeklyTrend ?? List.filled(8, 0);
    final maxVal = trend.reduce((a, b) => a > b ? a : b).toDouble();

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Growth Trend (8 Weeks)',
                style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : Colors.brown[800])),
            const SizedBox(height: 4),
            Text('Weekly practice time',
                style: TextStyle(fontSize: 12, color: Colors.grey[500])),
            const SizedBox(height: 16),
            SizedBox(
              height: 180,
              child: LineChart(
                LineChartData(
                  maxY: maxVal > 0 ? maxVal * 1.2 : 60,
                  minY: 0,
                  lineTouchData: LineTouchData(
                    touchTooltipData: LineTouchTooltipData(
                      getTooltipItems: (spots) => spots
                          .map((s) => LineTooltipItem(
                                '${s.y.toInt()}min',
                                const TextStyle(
                                    color: Colors.white, fontSize: 12),
                              ))
                          .toList(),
                    ),
                  ),
                  titlesData: FlTitlesData(
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 35,
                        getTitlesWidget: (value, meta) {
                          return Text('${value.toInt()}',
                              style: const TextStyle(fontSize: 10));
                        },
                      ),
                    ),
                    rightTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false)),
                    topTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false)),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          final weeksAgo = 7 - value.toInt();
                          return SideTitleWidget(
                            axisSide: meta.axisSide,
                            child: Text(
                              weeksAgo == 0 ? 'Now' : '${weeksAgo}w',
                              style: const TextStyle(fontSize: 10),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: false,
                    getDrawingHorizontalLine: (value) => FlLine(
                      color: Colors.grey.withValues(alpha: 0.2),
                      strokeWidth: 1,
                    ),
                  ),
                  borderData: FlBorderData(show: false),
                  lineBarsData: [
                    LineChartBarData(
                      spots: List.generate(
                          8, (i) => FlSpot(i.toDouble(), trend[i].toDouble())),
                      isCurved: true,
                      color: accent,
                      barWidth: 3,
                      dotData: FlDotData(
                        show: true,
                        getDotPainter: (spot, percent, barData, index) =>
                            FlDotCirclePainter(
                          radius: 4,
                          color: accent,
                          strokeWidth: 2,
                          strokeColor: Colors.white,
                        ),
                      ),
                      belowBarData: BarAreaData(
                        show: true,
                        color: accent.withValues(alpha: 0.15),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── 4) Calendar with stamps ──

  Widget _buildCalendarStamps(Color accent, bool isDark) {
    final goalMins = _goal?.dailyMinutes ?? 30;

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
              child: Text('Practice Calendar',
                  style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : Colors.brown[800])),
            ),
            TableCalendar(
              firstDay: DateTime.now().subtract(const Duration(days: 365)),
              lastDay: DateTime.now(),
              focusedDay: _focusedDay,
              calendarFormat: CalendarFormat.month,
              headerStyle: const HeaderStyle(
                formatButtonVisible: false,
                titleCentered: true,
              ),
              calendarStyle: CalendarStyle(
                todayDecoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.3),
                  shape: BoxShape.circle,
                ),
                todayTextStyle:
                    TextStyle(color: isDark ? Colors.white : Colors.black),
              ),
              onPageChanged: (day) => setState(() => _focusedDay = day),
              calendarBuilders: CalendarBuilders(
                defaultBuilder: (context, day, focusedDay) {
                  final dayKey = DateTime(day.year, day.month, day.day);
                  final mins = _dailyMap?[dayKey] ?? 0;
                  final metGoal = mins >= goalMins;
                  final practiced = mins > 0;

                  if (metGoal) {
                    // Gold stamp for goal met
                    return Container(
                      margin: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(
                        color: Colors.amber,
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Text(
                          '${day.day}',
                          style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 13),
                        ),
                      ),
                    );
                  } else if (practiced) {
                    // Light stamp for practiced but not met goal
                    return Container(
                      margin: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: accent.withValues(alpha: 0.25),
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Text(
                          '${day.day}',
                          style: TextStyle(
                              color: isDark ? Colors.white : Colors.black87,
                              fontSize: 13),
                        ),
                      ),
                    );
                  }
                  return null; // default rendering
                },
              ),
            ),
            const SizedBox(height: 8),
            // Legend
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _legendDot(Colors.amber, 'Goal met'),
                const SizedBox(width: 16),
                _legendDot(accent.withValues(alpha: 0.4), 'Practiced'),
                const SizedBox(width: 16),
                _legendDot(Colors.grey[300]!, 'No practice'),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _legendDot(Color color, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 4),
        Text(label, style: const TextStyle(fontSize: 11)),
      ],
    );
  }

  // ── 5) Streak card ──

  Widget _buildStreakCard(bool isDark) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            const Text('\u{1f525}', style: TextStyle(fontSize: 48)),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${_stats!.streak} Day Streak',
                    style: const TextStyle(
                        fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                  Text(
                    _stats!.streak > 7
                        ? 'Amazing dedication!'
                        : _stats!.streak > 3
                            ? 'Keep it up!'
                            : _stats!.streak > 0
                                ? 'Good start!'
                                : 'Start practicing today!',
                    style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                  ),
                ],
              ),
            ),
            Column(
              children: [
                Text('${_stats!.totalMinutes}',
                    style: const TextStyle(
                        fontSize: 28, fontWeight: FontWeight.bold)),
                Text('min/week',
                    style: TextStyle(fontSize: 11, color: Colors.grey[500])),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ── 6) Percentile card ──

  Widget _buildPercentileCard(Color primary) {
    final percentile = PracticeRecord.estimatePercentile(_stats!);
    return Card(
      elevation: 6,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            colors: [primary.withValues(alpha: 0.8), primary],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Column(
          children: [
            const Icon(Icons.emoji_events, size: 48, color: Colors.amber),
            const SizedBox(height: 8),
            Text(
              'Top $percentile%',
              style: const TextStyle(
                  fontSize: 36,
                  fontWeight: FontWeight.bold,
                  color: Colors.white),
            ),
            const SizedBox(height: 4),
            Text(
              'Among Guitar Learners This Week',
              style: TextStyle(
                  fontSize: 14, color: Colors.white.withValues(alpha: 0.9)),
            ),
          ],
        ),
      ),
    );
  }

  // ── 7) Practice by type ──

  Widget _buildTypeBreakdown(bool isDark) {
    final types = _stats!.sessionsByType;
    if (types.isEmpty) {
      return Card(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: const Padding(
          padding: EdgeInsets.all(20),
          child: Center(
              child: Text('No sessions this week.\nStart practicing!',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 16))),
        ),
      );
    }

    final typeLabels = {
      'fretboard': 'Fretboard',
      'octave': 'Octave',
      'chord': 'Chord',
      'scale': 'Scale',
      'metronome': 'Metronome',
    };

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('By Category',
                style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : Colors.brown[800])),
            const SizedBox(height: 12),
            ...types.entries.map((e) {
              final mins = _stats!.minutesByType[e.key] ?? 0;
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Row(
                  children: [
                    SizedBox(
                      width: 100,
                      child: Text(typeLabels[e.key] ?? e.key,
                          style: const TextStyle(fontSize: 14)),
                    ),
                    Expanded(
                      child: LinearProgressIndicator(
                        value: e.value /
                            (_stats!.totalSessions > 0
                                ? _stats!.totalSessions
                                : 1),
                        backgroundColor: Colors.grey[300],
                        valueColor:
                            const AlwaysStoppedAnimation(Color(0xFF16A085)),
                        minHeight: 8,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text('${mins}m',
                        style: const TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 13)),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  // ── 8) Recent sessions ──

  Widget _buildRecentSessions(bool isDark) {
    if (_weekSessions == null || _weekSessions!.isEmpty) return const SizedBox();

    final recent = _weekSessions!.reversed.take(10).toList();
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Recent Sessions',
                style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : Colors.brown[800])),
            const SizedBox(height: 8),
            ...recent.map((s) => ListTile(
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                  leading:
                      Icon(_typeIcon(s.type), color: const Color(0xFF16A085)),
                  title: Text(_typeLabel(s.type)),
                  subtitle: Text('${s.durationSeconds ~/ 60}min'),
                  trailing: Text(
                    DateFormat('M/d HH:mm').format(s.timestamp),
                    style: TextStyle(color: Colors.grey[500], fontSize: 12),
                  ),
                )),
          ],
        ),
      ),
    );
  }

  IconData _typeIcon(String type) {
    switch (type) {
      case 'fretboard':
        return Icons.music_note;
      case 'octave':
        return Icons.layers;
      case 'chord':
        return Icons.piano;
      case 'scale':
        return Icons.queue_music;
      case 'metronome':
        return Icons.timer;
      default:
        return Icons.music_note;
    }
  }

  String _typeLabel(String type) {
    switch (type) {
      case 'fretboard':
        return 'Fretboard';
      case 'octave':
        return 'Octave';
      case 'chord':
        return 'Chord';
      case 'scale':
        return 'Scale';
      case 'metronome':
        return 'Metronome';
      default:
        return type;
    }
  }
}
