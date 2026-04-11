import 'package:flutter/material.dart';
import '../../services/practice_record.dart';

class PracticeStatsScreen extends StatefulWidget {
  const PracticeStatsScreen({super.key});

  @override
  State<PracticeStatsScreen> createState() => _PracticeStatsScreenState();
}

class _PracticeStatsScreenState extends State<PracticeStatsScreen> {
  WeeklyStats? _stats;
  List<PracticeSession>? _weekSessions;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final stats = await PracticeRecord.getWeeklyStats();
    final sessions = await PracticeRecord.getWeekSessions();
    if (mounted) setState(() { _stats = stats; _weekSessions = sessions; _loading = false; });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primary = Theme.of(context).colorScheme.primary;

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
                      // Percentile card
                      _buildPercentileCard(primary),
                      const SizedBox(height: 16),
                      // Streak
                      _buildStreakCard(isDark),
                      const SizedBox(height: 16),
                      // Weekly summary (time + sessions only)
                      _buildWeeklySummary(isDark),
                      const SizedBox(height: 16),
                      // Practice by type
                      _buildTypeBreakdown(isDark),
                      const SizedBox(height: 16),
                      // Recent sessions
                      _buildRecentSessions(isDark),
                      const SizedBox(height: 60),
                    ],
                  ),
                ),
    );
  }

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
              style: const TextStyle(fontSize: 36, fontWeight: FontWeight.bold, color: Colors.white),
            ),
            const SizedBox(height: 4),
            Text(
              'Among Guitar Learners This Week',
              style: TextStyle(fontSize: 14, color: Colors.white.withValues(alpha: 0.9)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStreakCard(bool isDark) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            const Text('🔥', style: TextStyle(fontSize: 48)),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${_stats!.streak} Day Streak',
                    style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                  Text(
                    _stats!.streak > 7 ? 'Amazing dedication!'
                        : _stats!.streak > 3 ? 'Keep it up!'
                        : _stats!.streak > 0 ? 'Good start!'
                        : 'Start practicing today!',
                    style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWeeklySummary(bool isDark) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('This Week', style: TextStyle(
              fontSize: 16, fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : Colors.brown[800])),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _statItem(Icons.timer, '${_stats!.totalMinutes}', 'Minutes'),
                _statItem(Icons.check_circle, '${_stats!.totalSessions}', 'Sessions'),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _statItem(IconData icon, String value, String label) {
    return Column(
      children: [
        Icon(icon, size: 28, color: const Color(0xFF8B6914)),
        const SizedBox(height: 4),
        Text(value, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
        Text(label, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
      ],
    );
  }

  Widget _buildTypeBreakdown(bool isDark) {
    final types = _stats!.sessionsByType;
    if (types.isEmpty) {
      return Card(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: const Padding(
          padding: EdgeInsets.all(20),
          child: Center(child: Text('No sessions this week.\nStart practicing! 🎸',
            textAlign: TextAlign.center, style: TextStyle(fontSize: 16))),
        ),
      );
    }

    final typeLabels = {
      'fretboard': '🎵 Fretboard',
      'octave': '🎹 Octave',
      'chord': '🎸 Chord',
      'scale': '🎼 Scale',
    };

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('By Category', style: TextStyle(
              fontSize: 16, fontWeight: FontWeight.bold,
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
                        value: e.value / (_stats!.totalSessions > 0 ? _stats!.totalSessions : 1),
                        backgroundColor: Colors.grey[300],
                        valueColor: const AlwaysStoppedAnimation(Color(0xFF8B6914)),
                        minHeight: 8,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text('${mins}m', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

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
            Text('Recent Sessions', style: TextStyle(
              fontSize: 16, fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : Colors.brown[800])),
            const SizedBox(height: 8),
            ...recent.map((s) => ListTile(
              dense: true,
              contentPadding: EdgeInsets.zero,
              leading: Icon(_typeIcon(s.type), color: const Color(0xFF8B6914)),
              title: Text(_typeLabel(s.type)),
              subtitle: Text('${s.durationSeconds ~/ 60}min'),
              trailing: Text(
                '${s.timestamp.month}/${s.timestamp.day}',
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
      case 'fretboard': return Icons.music_note;
      case 'octave': return Icons.layers;
      case 'chord': return Icons.piano;
      case 'scale': return Icons.queue_music;
      default: return Icons.music_note;
    }
  }

  String _typeLabel(String type) {
    switch (type) {
      case 'fretboard': return 'Fretboard';
      case 'octave': return 'Octave';
      case 'chord': return 'Chord';
      case 'scale': return 'Scale';
      default: return type;
    }
  }
}
