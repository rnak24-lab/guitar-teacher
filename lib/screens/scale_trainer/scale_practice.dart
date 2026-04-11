import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../models/scale.dart';
import '../../models/note.dart';
import '../../models/guitar_string.dart';
import '../../widgets/ad_banner_widget.dart';
import '../../services/pitch_detector.dart';

/// Practice Mode: Shows scale notes highlighted on fretboard
/// Now with microphone support — play the correct note to advance.
class ScalePractice extends StatefulWidget {
  final String rootNote;
  final String scaleName;
  final int startFret;
  final int endFret;

  const ScalePractice({
    super.key,
    required this.rootNote,
    required this.scaleName,
    required this.startFret,
    required this.endFret,
  });

  @override
  State<ScalePractice> createState() => _ScalePracticeState();
}

class _ScalePracticeState extends State<ScalePractice> {
  late ScaleData _scale;
  late List<String> _scaleNotes;
  bool _showNoteNames = true;
  final bool _highlightRoot = true;
  int _currentNoteIndex = -1; // -1 = show all

  // ── Microphone / Auto mode ──
  final PitchDetector _pitchDetector = PitchDetector();
  bool _micEnabled = false;
  bool _autoMode = false;
  double _detectedFrequency = 0;
  String _detectedNote = '';
  bool _noteMatched = false;

  @override
  void initState() {
    super.initState();
    _scale = ScaleData.byName(widget.scaleName);
    _scaleNotes = _scale.notesForRoot(widget.rootNote);

    _pitchDetector.onPitchDetected = (freq, noteName, cents) {
      if (!mounted) return;
      setState(() {
        _detectedFrequency = freq;
        _detectedNote = noteName;
      });

      // Check if detected note matches current target
      if (_currentNoteIndex >= 0 && _currentNoteIndex < _scaleNotes.length) {
        final targetNote = _scaleNotes[_currentNoteIndex];
        if (PitchDetector.isNoteNameMatch(freq, targetNote, centsTolerance: 50)) {
          if (!_noteMatched) {
            setState(() => _noteMatched = true);
            if (_autoMode) {
              // Auto advance after brief visual feedback
              Future.delayed(const Duration(milliseconds: 400), () {
                if (mounted && _autoMode) {
                  _advanceNote();
                }
              });
            }
          }
        } else {
          if (mounted) setState(() => _noteMatched = false);
        }
      }
    };
  }

  @override
  void dispose() {
    _pitchDetector.dispose();
    super.dispose();
  }

  Future<void> _toggleMic() async {
    if (_micEnabled) {
      await _pitchDetector.stopListening();
      setState(() {
        _micEnabled = false;
        _detectedFrequency = 0;
        _detectedNote = '';
        _noteMatched = false;
      });
    } else {
      final ok = await _pitchDetector.startListening();
      if (ok) {
        setState(() => _micEnabled = true);
        // If showing all notes, start from first note when mic is on
        if (_currentNoteIndex == -1) {
          setState(() => _currentNoteIndex = 0);
        }
      } else {
        if (mounted) {
          final isPermanent = await PitchDetector.isPermissionPermanentlyDenied();
          if (!mounted) return;
          if (isPermanent) {
            _showPermissionDialog();
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Microphone permission required')),
            );
          }
        }
      }
    }
  }

  void _showPermissionDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Microphone Permission'),
        content: const Text(
          'Microphone access is needed for pitch detection.\n'
          'Please enable it in your device settings.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              openAppSettings();
            },
            child: const Text('Open Settings'),
          ),
        ],
      ),
    );
  }

  void _advanceNote() {
    setState(() {
      _noteMatched = false;
      if (_currentNoteIndex >= _scaleNotes.length - 1) {
        _currentNoteIndex = 0;
      } else {
        _currentNoteIndex++;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final currentTarget = _currentNoteIndex >= 0 && _currentNoteIndex < _scaleNotes.length
        ? _scaleNotes[_currentNoteIndex]
        : null;

    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.rootNote} ${widget.scaleName}'),
        actions: [
          // Auto mode toggle
          if (_micEnabled)
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('Auto', style: TextStyle(fontSize: 12)),
                Switch(
                  value: _autoMode,
                  onChanged: (v) => setState(() => _autoMode = v),
                  activeColor: Colors.green,
                ),
              ],
            ),
          IconButton(
            icon: Icon(_showNoteNames ? Icons.abc : Icons.music_note),
            tooltip: _showNoteNames ? 'Hide note names' : 'Show note names',
            onPressed: () => setState(() => _showNoteNames = !_showNoteNames),
          ),
        ],
      ),
      body: Column(
        children: [
          // Mic status bar
          if (_micEnabled)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              color: _noteMatched
                  ? Colors.green.withValues(alpha: 0.15)
                  : Colors.purple.withValues(alpha: 0.1),
              child: Row(
                children: [
                  Icon(
                    _noteMatched ? Icons.check_circle : Icons.mic,
                    color: _noteMatched ? Colors.green : Colors.purple,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  if (_detectedFrequency > 0) ...[
                    Text(
                      '$_detectedNote  ${_detectedFrequency.toStringAsFixed(1)}Hz',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: _noteMatched ? Colors.green[700] : Colors.purple[700],
                      ),
                    ),
                    const Spacer(),
                    if (currentTarget != null)
                      Text(
                        'Target: $currentTarget',
                        style: TextStyle(color: Colors.grey[600], fontSize: 13),
                      ),
                  ] else
                    Text('Listening...', style: TextStyle(color: Colors.grey[600])),
                  if (_autoMode) ...[
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.green.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Text('AUTO', style: TextStyle(fontSize: 10, color: Colors.green, fontWeight: FontWeight.bold)),
                    ),
                  ],
                ],
              ),
            ),

          // Scale notes display
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Wrap(
              spacing: 6,
              children: _scaleNotes.asMap().entries.map((e) {
                final isActive = _currentNoteIndex == -1 || _currentNoteIndex == e.key;
                final isRoot = e.key == 0;
                final isCurrent = _currentNoteIndex == e.key;
                return GestureDetector(
                  onTap: () => setState(() => _currentNoteIndex = _currentNoteIndex == e.key ? -1 : e.key),
                  child: Chip(
                    label: Text(e.value,
                      style: TextStyle(
                        color: isActive ? Colors.white : Colors.grey,
                        fontWeight: isRoot ? FontWeight.bold : FontWeight.normal,
                        fontSize: 16,
                      )),
                    backgroundColor: !isActive ? Colors.grey[300]
                        : (isCurrent && _noteMatched) ? Colors.green
                        : isRoot ? Colors.red[700]
                        : const Color(0xFF8B6914),
                  ),
                );
              }).toList(),
            ),
          ),
          // Fretboard
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: _buildFretboard(isDark),
              ),
            ),
          ),
          // Controls
          Container(
            padding: const EdgeInsets.all(12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _controlBtn(Icons.skip_previous, 'Prev', () {
                  setState(() {
                    _noteMatched = false;
                    if (_currentNoteIndex <= 0) {
                      _currentNoteIndex = _scaleNotes.length - 1;
                    } else {
                      _currentNoteIndex--;
                    }
                  });
                }),
                // Mic button
                _controlBtn(
                  _micEnabled ? Icons.mic_off : Icons.mic,
                  _micEnabled ? 'Mic Off' : 'Mic On',
                  _toggleMic,
                  color: _micEnabled ? Colors.red : Colors.purple,
                ),
                _controlBtn(Icons.grid_view, 'All', () {
                  setState(() => _currentNoteIndex = -1);
                }),
                _controlBtn(Icons.skip_next, 'Next', () {
                  setState(() {
                    _noteMatched = false;
                    if (_currentNoteIndex >= _scaleNotes.length - 1 || _currentNoteIndex == -1) {
                      _currentNoteIndex = 0;
                    } else {
                      _currentNoteIndex++;
                    }
                  });
                }),
              ],
            ),
          ),
          const AdBannerWidget(),
        ],
      ),
    );
  }

  Widget _controlBtn(IconData icon, String label, VoidCallback onTap, {Color? color}) {
    return ElevatedButton.icon(
      onPressed: onTap,
      icon: Icon(icon, size: 20),
      label: Text(label),
      style: ElevatedButton.styleFrom(
        backgroundColor: color ?? const Color(0xFF8B6914),
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      ),
    );
  }

  Widget _buildFretboard(bool isDark) {
    final strings = GuitarString.standard;
    final fretCount = widget.endFret - widget.startFret + 1;
    const cellW = 50.0;
    const cellH = 36.0;
    const leftPad = 40.0;
    const topPad = 24.0;

    final activeNotes = _currentNoteIndex == -1
        ? _scaleNotes
        : [_scaleNotes[_currentNoteIndex]];

    return SizedBox(
      width: leftPad + fretCount * cellW + 20,
      height: topPad + strings.length * cellH + 20,
      child: CustomPaint(
        painter: _ScaleFretboardPainter(
          strings: strings,
          startFret: widget.startFret,
          endFret: widget.endFret,
          activeNotes: activeNotes,
          rootNote: widget.rootNote,
          showNames: _showNoteNames,
          highlightRoot: _highlightRoot,
          isDark: isDark,
          cellW: cellW,
          cellH: cellH,
          leftPad: leftPad,
          topPad: topPad,
          matchedNote: _noteMatched && _currentNoteIndex >= 0 ? _scaleNotes[_currentNoteIndex] : null,
        ),
      ),
    );
  }
}

class _ScaleFretboardPainter extends CustomPainter {
  final List<GuitarString> strings;
  final int startFret;
  final int endFret;
  final List<String> activeNotes;
  final String rootNote;
  final bool showNames;
  final bool highlightRoot;
  final bool isDark;
  final double cellW, cellH, leftPad, topPad;
  final String? matchedNote;

  _ScaleFretboardPainter({
    required this.strings,
    required this.startFret,
    required this.endFret,
    required this.activeNotes,
    required this.rootNote,
    required this.showNames,
    required this.highlightRoot,
    required this.isDark,
    required this.cellW,
    required this.cellH,
    required this.leftPad,
    required this.topPad,
    this.matchedNote,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final fretCount = endFret - startFret + 1;
    final linePaint = Paint()..color = (isDark ? Colors.grey[600]! : Colors.grey[800]!)..strokeWidth = 1;
    final stringPaint = Paint()..color = (isDark ? Colors.grey[500]! : Colors.grey[700]!)..strokeWidth = 1.5;
    final nutPaint = Paint()..color = (isDark ? Colors.grey[300]! : Colors.black)..strokeWidth = 3;

    // Draw fret numbers
    for (int f = startFret; f <= endFret; f++) {
      final x = leftPad + (f - startFret + 0.5) * cellW;
      final tp = TextPainter(
        text: TextSpan(text: '$f', style: TextStyle(fontSize: 10, color: Colors.grey[500])),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, Offset(x - tp.width / 2, 2));
    }

    // Draw nut
    if (startFret == 0) {
      canvas.drawLine(Offset(leftPad + cellW, topPad), Offset(leftPad + cellW, topPad + (strings.length - 1) * cellH), nutPaint);
    }

    // Draw strings (horizontal)
    for (int s = 0; s < strings.length; s++) {
      final y = topPad + s * cellH;
      final tp = TextPainter(
        text: TextSpan(
          text: '${strings[s].number}${strings[s].openNote}',
          style: TextStyle(fontSize: 11, color: isDark ? Colors.grey[400] : Colors.grey[700]),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, Offset(2, y - tp.height / 2));
      canvas.drawLine(Offset(leftPad, y), Offset(leftPad + fretCount * cellW, y), stringPaint);
    }

    // Draw frets (vertical)
    for (int f = 0; f <= fretCount; f++) {
      final x = leftPad + f * cellW;
      canvas.drawLine(Offset(x, topPad), Offset(x, topPad + (strings.length - 1) * cellH), linePaint);
    }

    // Draw fret markers
    const markerFrets = [3, 5, 7, 9, 12, 15];
    for (final mf in markerFrets) {
      if (mf >= startFret && mf <= endFret) {
        final x = leftPad + (mf - startFret + 0.5) * cellW;
        final y = topPad + 2.5 * cellH;
        canvas.drawCircle(Offset(x, y), 4, Paint()..color = Colors.grey[400]!);
      }
    }

    // Draw scale notes
    for (int s = 0; s < strings.length; s++) {
      final openNote = strings[s].openNote;
      final y = topPad + s * cellH;

      for (int fret = startFret; fret <= endFret; fret++) {
        final noteAtFret = Note.noteAtFret(openNote, fret);
        if (activeNotes.contains(noteAtFret)) {
          final x = fret == 0
              ? leftPad + 0.5 * cellW * 0.5
              : leftPad + (fret - startFret + 0.5) * cellW;
          final isRoot = noteAtFret == rootNote && highlightRoot;
          final isMatched = matchedNote != null && noteAtFret == matchedNote;

          Color dotColor;
          if (isMatched) {
            dotColor = Colors.green;
          } else if (isRoot) {
            dotColor = Colors.red[700]!;
          } else {
            dotColor = const Color(0xFF8B6914);
          }
          final radius = isRoot ? 12.0 : 10.0;

          canvas.drawCircle(Offset(x, y), radius, Paint()..color = dotColor);

          if (showNames) {
            final tp = TextPainter(
              text: TextSpan(
                text: noteAtFret,
                style: const TextStyle(fontSize: 10, color: Colors.white, fontWeight: FontWeight.bold),
              ),
              textDirection: TextDirection.ltr,
            )..layout();
            tp.paint(canvas, Offset(x - tp.width / 2, y - tp.height / 2));
          }
        }
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
