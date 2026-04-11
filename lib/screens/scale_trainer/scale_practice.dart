import 'package:flutter/material.dart';
import '../../models/scale.dart';
import '../../models/note.dart';
import '../../models/guitar_string.dart';

/// Practice Mode: Shows scale notes highlighted on fretboard
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

  @override
  void initState() {
    super.initState();
    _scale = ScaleData.byName(widget.scaleName);
    _scaleNotes = _scale.notesForRoot(widget.rootNote);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.rootNote} ${widget.scaleName}'),
        actions: [
          IconButton(
            icon: Icon(_showNoteNames ? Icons.abc : Icons.music_note),
            tooltip: _showNoteNames ? 'Hide note names' : 'Show note names',
            onPressed: () => setState(() => _showNoteNames = !_showNoteNames),
          ),
        ],
      ),
      body: Column(
        children: [
          // Scale notes display
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Wrap(
              spacing: 6,
              children: _scaleNotes.asMap().entries.map((e) {
                final isActive = _currentNoteIndex == -1 || _currentNoteIndex == e.key;
                final isRoot = e.key == 0;
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
                    if (_currentNoteIndex <= 0) {
                      _currentNoteIndex = _scaleNotes.length - 1;
                    } else {
                      _currentNoteIndex--;
                    }
                  });
                }),
                _controlBtn(Icons.grid_view, 'All', () {
                  setState(() => _currentNoteIndex = -1);
                }),
                _controlBtn(Icons.skip_next, 'Next', () {
                  setState(() {
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
          // AD Banner
          Container(
            height: 50, width: double.infinity,
            color: isDark ? Colors.grey[900] : Colors.grey[200],
            child: Center(child: Text('AD BANNER',
              style: TextStyle(color: isDark ? Colors.grey[700] : Colors.grey, fontSize: 11))),
          ),
        ],
      ),
    );
  }

  Widget _controlBtn(IconData icon, String label, VoidCallback onTap) {
    return ElevatedButton.icon(
      onPressed: onTap,
      icon: Icon(icon, size: 20),
      label: Text(label),
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFF8B6914),
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
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
      // String label
      final tp = TextPainter(
        text: TextSpan(
          text: '${strings[s].number}${strings[s].openNote}',
          style: TextStyle(fontSize: 11, color: isDark ? Colors.grey[400] : Colors.grey[700]),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, Offset(2, y - tp.height / 2));
      // String line
      canvas.drawLine(Offset(leftPad, y), Offset(leftPad + fretCount * cellW, y), stringPaint);
    }

    // Draw frets (vertical)
    for (int f = 0; f <= fretCount; f++) {
      final x = leftPad + f * cellW;
      canvas.drawLine(Offset(x, topPad), Offset(x, topPad + (strings.length - 1) * cellH), linePaint);
    }

    // Draw fret markers (dots at 3,5,7,9,12)
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
          final dotColor = isRoot ? Colors.red[700]! : const Color(0xFF8B6914);
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
