import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../models/chord.dart';
import '../../widgets/chord_diagram_widget.dart';
import '../../widgets/ad_banner_widget.dart';
import '../../services/app_localizations.dart';
import '../../providers/note_name_provider.dart';

/// A single slot in a chord sequence (e.g. 2 beats of Am).
class ChordSlot {
  String chordName; // e.g. 'Am', 'C', 'G7'
  int beats; // 1..8

  ChordSlot({required this.chordName, this.beats = 2});

  Map<String, dynamic> toJson() => {'chord': chordName, 'beats': beats};
  factory ChordSlot.fromJson(Map<String, dynamic> j) =>
      ChordSlot(chordName: j['chord'] as String, beats: j['beats'] as int);
}

/// A saved sequence preset.
class ChordSequencePreset {
  String name;
  int bpm;
  List<ChordSlot> slots;

  ChordSequencePreset({required this.name, required this.bpm, required this.slots});

  Map<String, dynamic> toJson() => {
        'name': name,
        'bpm': bpm,
        'slots': slots.map((s) => s.toJson()).toList(),
      };

  factory ChordSequencePreset.fromJson(Map<String, dynamic> j) =>
      ChordSequencePreset(
        name: j['name'] as String,
        bpm: j['bpm'] as int,
        slots: (j['slots'] as List).map((s) => ChordSlot.fromJson(s)).toList(),
      );
}

class ChordSequenceScreen extends StatefulWidget {
  const ChordSequenceScreen({super.key});
  @override
  State<ChordSequenceScreen> createState() => _ChordSequenceScreenState();
}

class _ChordSequenceScreenState extends State<ChordSequenceScreen> {
  int _bpm = 80;
  final List<ChordSlot> _slots = [
    ChordSlot(chordName: 'C', beats: 4),
    ChordSlot(chordName: 'Am', beats: 4),
    ChordSlot(chordName: 'F', beats: 4),
    ChordSlot(chordName: 'G', beats: 4),
  ];

  List<ChordSequencePreset> _favorites = [];
  bool _isPlaying = false;
  Timer? _timer;
  int _currentSlotIndex = 0;
  int _currentBeat = 0; // 0-based within the slot

  static const _favKey = 'chord_sequence_favorites';

  @override
  void initState() {
    super.initState();
    _loadFavorites();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  // ── Persistence ──
  Future<void> _loadFavorites() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_favKey);
    if (raw != null) {
      final list = jsonDecode(raw) as List;
      setState(() {
        _favorites = list.map((e) => ChordSequencePreset.fromJson(e)).toList();
      });
    }
  }

  Future<void> _saveFavorites() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_favKey, jsonEncode(_favorites.map((e) => e.toJson()).toList()));
  }

  // ── Playback ──
  void _startPlayback() {
    if (_slots.isEmpty) return;
    setState(() {
      _isPlaying = true;
      _currentSlotIndex = 0;
      _currentBeat = 0;
    });
    final intervalMs = (60000 / _bpm).round();
    _timer = Timer.periodic(Duration(milliseconds: intervalMs), (_) {
      setState(() {
        _currentBeat++;
        if (_currentBeat >= _slots[_currentSlotIndex].beats) {
          _currentBeat = 0;
          _currentSlotIndex++;
          if (_currentSlotIndex >= _slots.length) {
            _currentSlotIndex = 0; // loop
          }
        }
      });
    });
  }

  void _stopPlayback() {
    _timer?.cancel();
    setState(() => _isPlaying = false);
  }

  // ── Chord picker ──
  Future<String?> _pickChord() async {
    final all = ChordData.allChords;
    return showDialog<String>(
      context: context,
      builder: (ctx) {
        String filter = '';
        return StatefulBuilder(builder: (ctx2, setLocal) {
          final filtered = all.where((c) =>
              c.name.toLowerCase().contains(filter.toLowerCase())).toList();
          return AlertDialog(
            title: Text(tr('seq_pick_chord')),
            content: SizedBox(
              width: 300,
              height: 400,
              child: Column(
                children: [
                  TextField(
                    decoration: InputDecoration(
                      hintText: tr('seq_search_chord'),
                      prefixIcon: const Icon(Icons.search),
                    ),
                    onChanged: (v) => setLocal(() => filter = v),
                  ),
                  const SizedBox(height: 8),
                  Expanded(
                    child: ListView.builder(
                      itemCount: filtered.length,
                      itemBuilder: (_, i) {
                        final c = filtered[i];
                        return ListTile(
                          title: Text(NoteNameProvider().displayChord(c.name)),
                          subtitle: Text(c.type),
                          onTap: () => Navigator.pop(ctx2, c.name),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          );
        });
      },
    );
  }

  // ── BPM editor (tap or drag) ──
  void _editBpm() {
    showDialog(
      context: context,
      builder: (ctx) {
        int tempBpm = _bpm;
        return StatefulBuilder(builder: (ctx2, setLocal) {
          return AlertDialog(
            title: const Text('BPM'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.remove_circle_outline),
                      onPressed: () {
                        if (tempBpm > 20) setLocal(() => tempBpm--);
                      },
                    ),
                    GestureDetector(
                      onVerticalDragUpdate: (d) {
                        setLocal(() {
                          tempBpm = (tempBpm - d.delta.dy.toInt()).clamp(20, 300);
                        });
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                        decoration: BoxDecoration(
                          color: const Color(0xFF8B6914).withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text('$tempBpm',
                            style: const TextStyle(fontSize: 36, fontWeight: FontWeight.bold)),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.add_circle_outline),
                      onPressed: () {
                        if (tempBpm < 300) setLocal(() => tempBpm++);
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(tr('seq_drag_bpm'), style: TextStyle(fontSize: 12, color: Colors.grey[500])),
              ],
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx2), child: Text(tr('cancel'))),
              TextButton(
                onPressed: () {
                  setState(() => _bpm = tempBpm);
                  Navigator.pop(ctx2);
                },
                child: const Text('OK'),
              ),
            ],
          );
        });
      },
    );
  }

  void _addSlot() async {
    final chord = await _pickChord();
    if (chord != null) {
      setState(() => _slots.add(ChordSlot(chordName: chord, beats: 4)));
    }
  }

  void _editSlotBeats(int index) {
    showDialog(
      context: context,
      builder: (ctx) {
        int beats = _slots[index].beats;
        return StatefulBuilder(builder: (ctx2, setLocal) {
          return AlertDialog(
            title: Text(NoteNameProvider().displayChord(_slots[index].chordName)),
            content: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(
                  icon: const Icon(Icons.remove),
                  onPressed: () {
                    if (beats > 1) setLocal(() => beats--);
                  },
                ),
                Text('$beats ${tr("seq_beats")}',
                    style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                IconButton(
                  icon: const Icon(Icons.add),
                  onPressed: () {
                    if (beats < 16) setLocal(() => beats++);
                  },
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () {
                  setState(() => _slots[index].beats = beats);
                  Navigator.pop(ctx2);
                },
                child: const Text('OK'),
              ),
            ],
          );
        });
      },
    );
  }

  void _removeSlot(int index) {
    setState(() => _slots.removeAt(index));
  }

  void _changeSlotChord(int index) async {
    final chord = await _pickChord();
    if (chord != null) {
      setState(() => _slots[index].chordName = chord);
    }
  }

  void _saveAsFavorite() async {
    final controller = TextEditingController();
    final name = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(tr('seq_save_favorite')),
        content: TextField(
          controller: controller,
          decoration: InputDecoration(hintText: tr('seq_preset_name')),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text(tr('cancel'))),
          TextButton(
            onPressed: () => Navigator.pop(ctx, controller.text.trim()),
            child: Text(tr('save')),
          ),
        ],
      ),
    );
    if (name != null && name.isNotEmpty) {
      _favorites.add(ChordSequencePreset(
        name: name,
        bpm: _bpm,
        slots: _slots.map((s) => ChordSlot(chordName: s.chordName, beats: s.beats)).toList(),
      ));
      await _saveFavorites();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${tr("seq_saved")}: $name')),
        );
      }
    }
  }

  void _loadFavoriteDialog() {
    if (_favorites.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(tr('seq_no_favorites'))),
      );
      return;
    }
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(tr('seq_favorites')),
        content: SizedBox(
          width: 300,
          height: 300,
          child: ListView.builder(
            itemCount: _favorites.length,
            itemBuilder: (_, i) {
              final fav = _favorites[i];
              return ListTile(
                title: Text(fav.name),
                subtitle: Text('${fav.bpm} BPM · ${fav.slots.length} chords'),
                trailing: IconButton(
                  icon: const Icon(Icons.delete, size: 18),
                  onPressed: () async {
                    _favorites.removeAt(i);
                    await _saveFavorites();
                    Navigator.pop(ctx);
                    _loadFavoriteDialog();
                  },
                ),
                onTap: () {
                  setState(() {
                    _bpm = fav.bpm;
                    _slots.clear();
                    _slots.addAll(fav.slots.map((s) =>
                        ChordSlot(chordName: s.chordName, beats: s.beats)));
                  });
                  Navigator.pop(ctx);
                },
              );
            },
          ),
        ),
      ),
    );
  }

  // ── Build ──
  @override
  Widget build(BuildContext context) {
    final np = NoteNameProvider();
    return Scaffold(
      appBar: AppBar(
        title: Text(tr('seq_title')),
        actions: [
          IconButton(icon: const Icon(Icons.bookmark_border), onPressed: _loadFavoriteDialog,
              tooltip: tr('seq_favorites')),
          IconButton(icon: const Icon(Icons.save_alt), onPressed: _saveAsFavorite,
              tooltip: tr('seq_save_favorite')),
        ],
      ),
      body: Column(
        children: [
          // ── Staff-like sequence view ──
          Container(
            margin: const EdgeInsets.all(12),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border.all(color: Colors.brown.shade200),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // BPM + add button
                Row(
                  children: [
                    GestureDetector(
                      onTap: _editBpm,
                      onDoubleTap: _editBpm,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFF8B6914).withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.speed, size: 16, color: Color(0xFF8B6914)),
                            const SizedBox(width: 4),
                            Text('$_bpm BPM',
                                style: const TextStyle(
                                    fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF8B6914))),
                          ],
                        ),
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      icon: const Icon(Icons.add_circle, color: Color(0xFF8B6914)),
                      onPressed: _addSlot,
                      tooltip: tr('seq_add_chord'),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                // Chord slots (staff-like boxes)
                if (_slots.isEmpty)
                  Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Text(tr('seq_empty'), style: TextStyle(color: Colors.grey[400], fontSize: 16)),
                    ),
                  )
                else
                  SizedBox(
                    height: 80,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: _slots.length,
                      itemBuilder: (_, i) {
                        final slot = _slots[i];
                        final isActive = _isPlaying && i == _currentSlotIndex;
                        return GestureDetector(
                          onTap: () => _changeSlotChord(i),
                          onDoubleTap: () => _editSlotBeats(i),
                          onLongPress: () => _removeSlot(i),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            width: 44.0 + slot.beats * 14.0,
                            margin: const EdgeInsets.only(right: 6),
                            decoration: BoxDecoration(
                              color: isActive
                                  ? const Color(0xFF8B6914).withValues(alpha: 0.25)
                                  : Colors.grey[100],
                              border: Border.all(
                                color: isActive ? const Color(0xFF8B6914) : Colors.grey[300]!,
                                width: isActive ? 2 : 1,
                              ),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(np.displayChord(slot.chordName),
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: isActive ? const Color(0xFF8B6914) : const Color(0xFF5D3A00),
                                    )),
                                Text('${slot.beats} ${tr("seq_beats")}',
                                    style: TextStyle(fontSize: 11, color: Colors.grey[500])),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                const SizedBox(height: 4),
                Text(tr('seq_hint'),
                    style: TextStyle(fontSize: 11, color: Colors.grey[400])),
              ],
            ),
          ),

          // ── Play / Stop ──
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    icon: Icon(_isPlaying ? Icons.stop : Icons.play_arrow),
                    label: Text(_isPlaying ? tr('stop') : tr('start')),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _isPlaying ? Colors.red[400] : const Color(0xFF8B6914),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: _isPlaying ? _stopPlayback : _startPlayback,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 12),

          // ── Current chord diagram (during playback) ──
          if (_isPlaying && _slots.isNotEmpty)
            Expanded(
              child: _buildCurrentChordView(np),
            )
          else
            const Expanded(child: SizedBox()),

          const AdBannerWidget(),
        ],
      ),
    );
  }

  Widget _buildCurrentChordView(NoteNameProvider np) {
    final slot = _slots[_currentSlotIndex];
    final chordData = ChordData.allChords
        .where((c) => c.name == slot.chordName)
        .toList();
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(np.displayChord(slot.chordName),
              style: const TextStyle(fontSize: 64, fontWeight: FontWeight.bold, color: Color(0xFF5D3A00))),
          Text('${tr("seq_beat")} ${_currentBeat + 1} / ${slot.beats}',
              style: TextStyle(fontSize: 18, color: Colors.grey[600])),
          const SizedBox(height: 12),
          if (chordData.isNotEmpty) ChordDiagramWidget(chord: chordData.first),
        ],
      ),
    );
  }
}
