import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../widgets/ad_banner_widget.dart';

// ── Color tokens (warm wood / apricot / gold) ──
class _C {
  static const bg = Color(0xFFFAF3E8);
  static const cardBg = Color(0xFFF0E4CC);
  static const border = Color(0xFFC8A878);
  static const gold = Color(0xFFD4A017);
  static const goldDeep = Color(0xFFB8860B);
  static const dotInactive = Color(0xFFE8C9A0);
  static const dotActive = Color(0xFFD4956A);
  static const textPrimary = Color(0xFF3D2B1F);
  static const textSecondary = Color(0xFF7A5C3E);
  static const btnInactiveBg = Color(0xFFE8D5B0);
}

class MetronomeScreen extends StatefulWidget {
  const MetronomeScreen({super.key});

  @override
  State<MetronomeScreen> createState() => _MetronomeScreenState();
}

class _MetronomeScreenState extends State<MetronomeScreen>
    with SingleTickerProviderStateMixin {
  int _bpm = 120;
  int _beatsPerMeasure = 4;
  int _currentBeat = -1;
  bool _isPlaying = false;
  Timer? _timer;

  bool _vibrationEnabled = false;
  bool _soundEnabled = true;

  // Use a pool of AudioPlayers to avoid stop/play race conditions
  final List<AudioPlayer> _highPlayers = List.generate(4, (_) => AudioPlayer());
  final List<AudioPlayer> _lowPlayers = List.generate(4, (_) => AudioPlayer());
  int _highIdx = 0;
  int _lowIdx = 0;
  bool _assetsPreloaded = false;

  // ── Tap Tempo state ──
  final List<int> _tapTimestamps = [];
  static const _tapResetMs = 3000; // reset after 3s silence

  // Time signatures
  static const _signatures = [2, 3, 4, 6];
  static const _sigLabels = ['2/4', '3/4', '4/4', '6/8'];

  // Tempo presets
  static const _presets = [
    ('Grave', 35),
    ('Largo', 50),
    ('Larghetto', 63),
    ('Adagio', 72),
    ('Andante', 92),
    ('Moderato', 114),
    ('Allegro', 138),
    ('Vivace', 166),
    ('Presto', 188),
    ('Prestissimo', 210),
  ];

  String get _tempoName {
    if (_bpm <= 40) return 'Grave';
    if (_bpm <= 55) return 'Largo';
    if (_bpm <= 65) return 'Larghetto';
    if (_bpm <= 85) return 'Adagio';
    if (_bpm <= 105) return 'Andante';
    if (_bpm <= 120) return 'Moderato';
    if (_bpm <= 156) return 'Allegro';
    if (_bpm <= 176) return 'Vivace';
    if (_bpm <= 200) return 'Presto';
    return 'Prestissimo';
  }

  @override
  void initState() {
    super.initState();
    _loadPreferences();
  }

  Future<void> _loadPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _vibrationEnabled = prefs.getBool('metronome_vibration') ?? false;
      _soundEnabled = prefs.getBool('metronome_sound') ?? true;
      _bpm = prefs.getInt('metronome_bpm') ?? 120;
      _beatsPerMeasure = prefs.getInt('metronome_beats') ?? 4;
    });
    _preloadAssets();
  }

  /// Pre-load audio assets into all pool players so first beat plays instantly.
  Future<void> _preloadAssets() async {
    if (_assetsPreloaded) return;
    _assetsPreloaded = true;
    for (final p in _highPlayers) {
      await p.setSource(AssetSource('sounds/click_high.wav'));
      await p.setReleaseMode(ReleaseMode.stop);
      await p.setVolume(1.0);
    }
    for (final p in _lowPlayers) {
      await p.setSource(AssetSource('sounds/click_low.wav'));
      await p.setReleaseMode(ReleaseMode.stop);
      await p.setVolume(1.0);
    }
  }

  Future<void> _savePreferences() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('metronome_vibration', _vibrationEnabled);
    await prefs.setBool('metronome_sound', _soundEnabled);
    await prefs.setInt('metronome_bpm', _bpm);
    await prefs.setInt('metronome_beats', _beatsPerMeasure);
  }

  void _togglePlay() {
    setState(() {
      _isPlaying = !_isPlaying;
      if (_isPlaying) {
        _currentBeat = 0;
        _playBeat(true);
        _startTimer();
      } else {
        _timer?.cancel();
        _currentBeat = -1;
      }
    });
  }

  void _startTimer() {
    _timer?.cancel();
    final interval = Duration(milliseconds: (60000 / _bpm).round());
    _timer = Timer.periodic(interval, (_) {
      setState(() {
        _currentBeat = (_currentBeat + 1) % _beatsPerMeasure;
        _playBeat(_currentBeat == 0);
      });
    });
  }

  void _playBeat(bool isDownbeat) {
    if (_soundEnabled) {
      if (isDownbeat) {
        final player = _highPlayers[_highIdx % _highPlayers.length];
        _highIdx++;
        // Use seek+resume for pre-loaded assets to avoid stop/play race condition
        player.seek(Duration.zero).then((_) => player.resume()).catchError((_) {
          // Fallback: if seek/resume fails, do full play
          player.play(AssetSource('sounds/click_high.wav'));
        });
      } else {
        final player = _lowPlayers[_lowIdx % _lowPlayers.length];
        _lowIdx++;
        player.seek(Duration.zero).then((_) => player.resume()).catchError((_) {
          player.play(AssetSource('sounds/click_low.wav'));
        });
      }
    }
    if (_vibrationEnabled) {
      if (isDownbeat) {
        HapticFeedback.heavyImpact();
      } else {
        HapticFeedback.lightImpact();
      }
    }
  }

  void _setBpm(int bpm) {
    setState(() {
      _bpm = bpm.clamp(20, 300);
      if (_isPlaying) _startTimer();
    });
    _savePreferences();
  }

  void _onTapTempo() {
    final now = DateTime.now().millisecondsSinceEpoch;
    // Reset if gap > 3 seconds
    if (_tapTimestamps.isNotEmpty && now - _tapTimestamps.last > _tapResetMs) {
      _tapTimestamps.clear();
    }
    _tapTimestamps.add(now);
    if (_tapTimestamps.length < 2) return;

    // Keep only last 8 taps for averaging
    if (_tapTimestamps.length > 8) {
      _tapTimestamps.removeAt(0);
    }

    // Calculate average interval
    int totalInterval = 0;
    for (int i = 1; i < _tapTimestamps.length; i++) {
      totalInterval += _tapTimestamps[i] - _tapTimestamps[i - 1];
    }
    final avgMs = totalInterval / (_tapTimestamps.length - 1);
    final tapBpm = (60000 / avgMs).round().clamp(20, 300);
    _setBpm(tapBpm);
  }

  void _showBpmKeypad() async {
    final controller = TextEditingController(text: '$_bpm');
    final result = await showDialog<int>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: _C.cardBg,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('BPM', style: TextStyle(color: _C.textPrimary, fontWeight: FontWeight.bold)),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          autofocus: true,
          style: TextStyle(fontSize: 32, color: _C.textPrimary, fontWeight: FontWeight.bold),
          textAlign: TextAlign.center,
          decoration: InputDecoration(
            hintText: '20 ~ 300',
            hintStyle: TextStyle(color: _C.textSecondary.withValues(alpha: 0.5)),
            enabledBorder: UnderlineInputBorder(
              borderSide: BorderSide(color: _C.border),
            ),
            focusedBorder: UnderlineInputBorder(
              borderSide: BorderSide(color: _C.gold, width: 2),
            ),
          ),
          inputFormatters: [
            FilteringTextInputFormatter.digitsOnly,
            LengthLimitingTextInputFormatter(3),
          ],
          onSubmitted: (v) {
            final n = int.tryParse(v);
            if (n != null) Navigator.pop(ctx, n.clamp(20, 300));
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Cancel', style: TextStyle(color: _C.textSecondary)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: _C.gold),
            onPressed: () {
              final n = int.tryParse(controller.text);
              if (n != null) Navigator.pop(ctx, n.clamp(20, 300));
            },
            child: const Text('OK', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
    if (result != null) _setBpm(result);
  }

  @override
  void dispose() {
    _timer?.cancel();
    for (final p in _highPlayers) { p.dispose(); }
    for (final p in _lowPlayers) { p.dispose(); }
    super.dispose();
  }

  // ── Build ──
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _C.bg,
      appBar: AppBar(
        title: const Text('Metronome'),
        backgroundColor: _C.cardBg,
        foregroundColor: _C.textPrimary,
        elevation: 0,
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                child: Column(
                  children: [
                    // ── Toggle row (vibration / sound) ──
                    _buildToggles(),
                    const SizedBox(height: 20),

                    // ── BPM display ──
                    _buildBpmSection(),
                    const SizedBox(height: 12),

                    // ── Tap Tempo button ──
                    _buildTapTempoButton(),
                    const SizedBox(height: 12),

                    // ── Beat indicators ──
                    _buildBeatIndicators(),
                    const SizedBox(height: 20),

                    // ── Time signature buttons ──
                    _buildTimeSignatureButtons(),
                    const SizedBox(height: 16),

                    // ── Tempo presets ──
                    _buildTempoPresets(),
                    const SizedBox(height: 24),

                    // ── Start / Stop button ──
                    _buildPlayButton(),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ),

            // ── Ad banner ──
            const AdBannerWidget(),
          ],
        ),
      ),
    );
  }

  // ── Toggles ──
  Widget _buildToggles() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        _pillToggle(
          label: 'Vibration',
          icon: _vibrationEnabled ? Icons.vibration : Icons.phone_android,
          isOn: _vibrationEnabled,
          onTap: () {
            setState(() => _vibrationEnabled = !_vibrationEnabled);
            _savePreferences();
          },
        ),
        const SizedBox(width: 12),
        _pillToggle(
          label: 'Sound',
          icon: _soundEnabled ? Icons.volume_up : Icons.volume_off,
          isOn: _soundEnabled,
          onTap: () {
            setState(() => _soundEnabled = !_soundEnabled);
            _savePreferences();
          },
        ),
      ],
    );
  }

  Widget _pillToggle({
    required String label,
    required IconData icon,
    required bool isOn,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isOn ? _C.gold : _C.btnInactiveBg,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: isOn ? Colors.white : _C.textSecondary),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: isOn ? Colors.white : _C.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── BPM Section ──
  Widget _buildBpmSection() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
      decoration: BoxDecoration(
        color: _C.cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _C.border, width: 1),
      ),
      child: Column(
        children: [
          // BPM number (tappable)
          GestureDetector(
            onTap: _showBpmKeypad,
            child: Text(
              '$_bpm',
              style: const TextStyle(
                fontSize: 72,
                fontWeight: FontWeight.bold,
                color: _C.textPrimary,
                height: 1.0,
              ),
            ),
          ),
          const SizedBox(height: 4),
          // Tempo name (tappable -> applies preset)
          GestureDetector(
            onTap: _showBpmKeypad,
            child: Text(
              _tempoName,
              style: const TextStyle(fontSize: 14, color: _C.textSecondary),
            ),
          ),
          const SizedBox(height: 12),
          // -/+ row
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _bpmCircleButton(
                icon: Icons.remove,
                onTap: () => _setBpm(_bpm - 1),
                onLongPress: () => _setBpm(_bpm - 5),
              ),
              const SizedBox(width: 16),
              // Slider
              Expanded(
                child: SliderTheme(
                  data: SliderThemeData(
                    activeTrackColor: _C.gold,
                    inactiveTrackColor: _C.dotInactive,
                    thumbColor: _C.goldDeep,
                    overlayColor: _C.gold.withValues(alpha: 0.2),
                    trackHeight: 4,
                  ),
                  child: Slider(
                    value: _bpm.toDouble(),
                    min: 20,
                    max: 300,
                    onChanged: (v) => _setBpm(v.round()),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              _bpmCircleButton(
                icon: Icons.add,
                onTap: () => _setBpm(_bpm + 1),
                onLongPress: () => _setBpm(_bpm + 5),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _bpmCircleButton({
    required IconData icon,
    required VoidCallback onTap,
    required VoidCallback onLongPress,
  }) {
    return GestureDetector(
      onTap: onTap,
      onLongPress: onLongPress,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: _C.gold, width: 2),
          color: Colors.transparent,
        ),
        child: Icon(icon, color: _C.gold, size: 20),
      ),
    );
  }

  // ── Tap Tempo Button ──
  Widget _buildTapTempoButton() {
    return GestureDetector(
      onTap: _onTapTempo,
      child: Container(
        height: 44,
        padding: const EdgeInsets.symmetric(horizontal: 24),
        decoration: BoxDecoration(
          color: _C.btnInactiveBg,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: _C.gold, width: 1.5),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.touch_app, color: _C.gold, size: 20),
            const SizedBox(width: 8),
            Text(
              'TAP',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: _C.gold,
              ),
            ),
            if (_tapTimestamps.length >= 2) ...[
              const SizedBox(width: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: _C.gold.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '${_tapTimestamps.length - 1} taps',
                  style: TextStyle(fontSize: 11, color: _C.textSecondary),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  // ── Beat Indicators (horizontal dots) ──
  Widget _buildBeatIndicators() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
      decoration: BoxDecoration(
        color: _C.cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _C.border, width: 1),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: List.generate(_beatsPerMeasure, (i) {
          final isActive = _isPlaying && _currentBeat == i;
          final isDownbeat = i == 0;
          final double size = isActive ? 28 : 20;

          Color color;
          if (isActive) {
            color = isDownbeat ? _C.goldDeep : _C.dotActive;
          } else {
            color = Colors.transparent;
          }

          Color borderColor = isActive
              ? (isDownbeat ? _C.goldDeep : _C.dotActive)
              : _C.dotInactive;

          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 80),
              width: size,
              height: size,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: color,
                border: Border.all(color: borderColor, width: 2.5),
                boxShadow: isActive
                    ? [
                        BoxShadow(
                          color: (isDownbeat ? _C.goldDeep : _C.dotActive)
                              .withValues(alpha: 0.5),
                          blurRadius: 12,
                        ),
                      ]
                    : null,
              ),
            ),
          );
        }),
      ),
    );
  }

  // ── Time Signature Buttons ──
  Widget _buildTimeSignatureButtons() {
    return Row(
      children: List.generate(_signatures.length, (i) {
        final isSelected = _beatsPerMeasure == _signatures[i];
        return Expanded(
          child: Padding(
            padding: EdgeInsets.only(
              left: i == 0 ? 0 : 4,
              right: i == _signatures.length - 1 ? 0 : 4,
            ),
            child: GestureDetector(
              onTap: () {
                setState(() {
                  _beatsPerMeasure = _signatures[i];
                  _currentBeat = 0;
                  if (_isPlaying) _startTimer();
                });
                _savePreferences();
              },
              child: Container(
                height: 44,
                decoration: BoxDecoration(
                  color: isSelected ? _C.gold : _C.btnInactiveBg,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: Text(
                    _sigLabels[i],
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: isSelected ? Colors.white : _C.textPrimary,
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      }),
    );
  }

  // ── Tempo Presets (horizontal scroll chips) ──
  Widget _buildTempoPresets() {
    return SizedBox(
      height: 40,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: _presets.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (_, i) {
          final (name, bpm) = _presets[i];
          final isActive = _tempoName == name;
          return GestureDetector(
            onTap: () => _setBpm(bpm),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              decoration: BoxDecoration(
                color: isActive ? _C.gold : _C.btnInactiveBg,
                borderRadius: BorderRadius.circular(20),
              ),
              alignment: Alignment.center,
              child: Text(
                name,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: isActive ? Colors.white : _C.textSecondary,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  // ── Play / Stop Button ──
  Widget _buildPlayButton() {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton.icon(
        onPressed: _togglePlay,
        icon: Icon(
          _isPlaying ? Icons.stop : Icons.play_arrow,
          size: 24,
        ),
        label: Text(
          _isPlaying ? 'Stop' : 'Start',
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: _isPlaying ? _C.textPrimary : _C.gold,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          elevation: 0,
        ),
      ),
    );
  }
}
