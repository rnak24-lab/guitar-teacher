import 'package:flutter/material.dart';
import '../../models/box_pattern.dart';
import '../../models/note.dart';
import '../../models/guitar_string.dart';
import '../../widgets/ad_banner_widget.dart';
import '../../providers/note_name_provider.dart';

/// Displays a selected box pattern on the fretboard diagram.
/// Supports in-screen key changes: when root note changes,
/// all form positions (2~5/7) update automatically.
class BoxPatternScreen extends StatefulWidget {
  final String rootNote;

  /// 'pentatonic' or 'major'
  final String patternType;

  const BoxPatternScreen({
    super.key,
    required this.rootNote,
    required this.patternType,
  });

  @override
  State<BoxPatternScreen> createState() => _BoxPatternScreenState();
}

class _BoxPatternScreenState extends State<BoxPatternScreen> {
  int _selectedPosition = 0;
  bool _showNoteNames = true;
  late String _currentRoot;
  late String _currentType;

  @override
  void initState() {
    super.initState();
    _currentRoot = widget.rootNote;
    _currentType = widget.patternType;
  }

  List<BoxPattern> get _patterns =>
      _currentType == 'pentatonic'
          ? BoxPattern.pentatonicMinor
          : BoxPattern.majorScale;

  String get _title =>
      _currentType == 'pentatonic'
          ? 'Pentatonic Box Patterns'
          : 'Major Scale Box Patterns';

  /// Calculate the starting fret for the selected pattern & root.
  int _startFretForRoot() {
    final rootIdx = Note.noteIndex(_currentRoot);
    final openEIdx = Note.noteIndex('E');
    int baseFret = (rootIdx - openEIdx) % 12;
    if (baseFret == 0) baseFret = 12;

    final shift = _selectedPosition * 3;
    return (baseFret + shift) % 12;
  }

  void _changeRoot(String newRoot) {
    setState(() {
      _currentRoot = newRoot;
      // All form positions recalculate automatically via _startFretForRoot()
    });
  }

  void _changeType(String newType) {
    setState(() {
      _currentType = newType;
      // Reset position if current exceeds available positions
      if (_selectedPosition >= _patterns.length) {
        _selectedPosition = 0;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    const accent = Color(0xFF8B6914);
    final pattern = _patterns[_selectedPosition];
    final nn = NoteNameProvider();
    final startFret = _startFretForRoot();

    return Scaffold(
      appBar: AppBar(
        title: Text('${nn.display(_currentRoot)} $_title'),
        actions: [
          IconButton(
            icon: Icon(_showNoteNames ? Icons.abc : Icons.music_note),
            tooltip: _showNoteNames ? 'Hide notes' : 'Show notes',
            onPressed: () => setState(() => _showNoteNames = !_showNoteNames),
          ),
        ],
      ),
      body: Column(
        children: [
          // ── Key (Root Note) selector ──
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text('Key: ',
                        style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey[700])),
                    const SizedBox(width: 4),
                    Expanded(
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: Note.allNotes.map((note) {
                            final isSelected = _currentRoot == note;
                            return Padding(
                              padding: const EdgeInsets.only(right: 4),
                              child: ChoiceChip(
                                label: Text(nn.display(note),
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.bold,
                                      color:
                                          isSelected ? Colors.white : null,
                                    )),
                                selected: isSelected,
                                selectedColor: Colors.red[700],
                                visualDensity: VisualDensity.compact,
                                onSelected: (_) => _changeRoot(note),
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                // Pattern type toggle
                Row(
                  children: [
                    Text('Type: ',
                        style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey[700])),
                    const SizedBox(width: 4),
                    ChoiceChip(
                      label: const Text('Pentatonic',
                          style: TextStyle(fontSize: 12)),
                      selected: _currentType == 'pentatonic',
                      selectedColor: accent,
                      labelStyle: TextStyle(
                        color: _currentType == 'pentatonic'
                            ? Colors.white
                            : null,
                        fontWeight: FontWeight.w600,
                      ),
                      visualDensity: VisualDensity.compact,
                      onSelected: (_) => _changeType('pentatonic'),
                    ),
                    const SizedBox(width: 6),
                    ChoiceChip(
                      label: const Text('Major Scale',
                          style: TextStyle(fontSize: 12)),
                      selected: _currentType == 'major',
                      selectedColor: accent,
                      labelStyle: TextStyle(
                        color:
                            _currentType == 'major' ? Colors.white : null,
                        fontWeight: FontWeight.w600,
                      ),
                      visualDensity: VisualDensity.compact,
                      onSelected: (_) => _changeType('major'),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Position selector (forms)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: List.generate(_patterns.length, (i) {
                  final p = _patterns[i];
                  final isSelected = _selectedPosition == i;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: Text(p.name),
                      selected: isSelected,
                      selectedColor: accent,
                      labelStyle: TextStyle(
                        color: isSelected ? Colors.white : null,
                        fontWeight: FontWeight.bold,
                      ),
                      onSelected: (_) => setState(() => _selectedPosition = i),
                    ),
                  );
                }),
              ),
            ),
          ),

          // Pattern info
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Text(
              'Root: ${nn.display(_currentRoot)}  |  Start Fret: $startFret  |  ${pattern.name}',
              style: TextStyle(fontSize: 14, color: Colors.grey[600]),
            ),
          ),

          // Fretboard diagram
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: _buildPatternFretboard(isDark, pattern, startFret),
              ),
            ),
          ),

          const AdBannerWidget(),
        ],
      ),
    );
  }

  Widget _buildPatternFretboard(bool isDark, BoxPattern pattern, int startFret) {
    final strings = GuitarString.standard;
    const cellW = 50.0;
    const cellH = 40.0;
    const leftPad = 40.0;
    const topPad = 24.0;

    // Determine fret range to display
    int maxOffset = 0;
    for (final offsets in pattern.fretOffsets) {
      for (final o in offsets) {
        if (o > maxOffset) maxOffset = o;
      }
    }
    final displayStart = (startFret - 1).clamp(0, 15);
    final displayEnd = (startFret + maxOffset + 2).clamp(displayStart + 1, 18);
    final fretCount = displayEnd - displayStart + 1;
    final nn = NoteNameProvider();

    return SizedBox(
      width: leftPad + fretCount * cellW + 20,
      height: topPad + strings.length * cellH + 20,
      child: CustomPaint(
        painter: _BoxPatternPainter(
          strings: strings,
          startFret: displayStart,
          endFret: displayEnd,
          pattern: pattern,
          patternStartFret: startFret,
          rootNote: _currentRoot,
          showNames: _showNoteNames,
          isDark: isDark,
          cellW: cellW,
          cellH: cellH,
          leftPad: leftPad,
          topPad: topPad,
          noteNameProvider: nn,
        ),
      ),
    );
  }
}

class _BoxPatternPainter extends CustomPainter {
  final List<GuitarString> strings;
  final int startFret, endFret;
  final BoxPattern pattern;
  final int patternStartFret;
  final String rootNote;
  final bool showNames, isDark;
  final double cellW, cellH, leftPad, topPad;
  final NoteNameProvider noteNameProvider;

  _BoxPatternPainter({
    required this.strings,
    required this.startFret,
    required this.endFret,
    required this.pattern,
    required this.patternStartFret,
    required this.rootNote,
    required this.showNames,
    required this.isDark,
    required this.cellW,
    required this.cellH,
    required this.leftPad,
    required this.topPad,
    required this.noteNameProvider,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final fretCount = endFret - startFret + 1;
    final linePaint = Paint()
      ..color = (isDark ? Colors.grey[600]! : Colors.grey[800]!)
      ..strokeWidth = 1;
    final stringPaint = Paint()
      ..color = (isDark ? Colors.grey[500]! : Colors.grey[700]!)
      ..strokeWidth = 1.5;
    final nutPaint = Paint()
      ..color = (isDark ? Colors.grey[300]! : Colors.black)
      ..strokeWidth = 3;

    // Fret numbers
    for (int f = startFret; f <= endFret; f++) {
      final x = leftPad + (f - startFret + 0.5) * cellW;
      final tp = TextPainter(
        text: TextSpan(
            text: '$f',
            style: TextStyle(fontSize: 10, color: Colors.grey[500])),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, Offset(x - tp.width / 2, 2));
    }

    // Nut
    if (startFret == 0) {
      canvas.drawLine(
          Offset(leftPad + cellW, topPad),
          Offset(leftPad + cellW, topPad + (strings.length - 1) * cellH),
          nutPaint);
    }

    // Strings
    for (int s = 0; s < strings.length; s++) {
      final y = topPad + s * cellH;
      final tp = TextPainter(
        text: TextSpan(
          text: '${strings[s].number}${strings[s].openNote}',
          style: TextStyle(
              fontSize: 11,
              color: isDark ? Colors.grey[400] : Colors.grey[700]),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, Offset(2, y - tp.height / 2));
      canvas.drawLine(Offset(leftPad, y),
          Offset(leftPad + fretCount * cellW, y), stringPaint);
    }

    // Frets
    for (int f = 0; f <= fretCount; f++) {
      final x = leftPad + f * cellW;
      canvas.drawLine(Offset(x, topPad),
          Offset(x, topPad + (strings.length - 1) * cellH), linePaint);
    }

    // Fret markers
    const markerFrets = [3, 5, 7, 9, 12, 15];
    for (final mf in markerFrets) {
      if (mf >= startFret && mf <= endFret) {
        final x = leftPad + (mf - startFret + 0.5) * cellW;
        final y = topPad + 2.5 * cellH;
        canvas.drawCircle(
            Offset(x, y), 4, Paint()..color = Colors.grey[400]!);
      }
    }

    // Draw pattern notes
    // pattern.fretOffsets[0] = 6th string (low E), but strings[0] = 1st string (high E)
    // So we reverse: pattern index 0 → strings index 5
    for (int pIdx = 0; pIdx < pattern.fretOffsets.length && pIdx < 6; pIdx++) {
      final stringIdx = 5 - pIdx; // reverse mapping
      final y = topPad + stringIdx * cellH;
      final offsets = pattern.fretOffsets[pIdx];

      for (final offset in offsets) {
        final fret = patternStartFret + offset;
        if (fret < startFret || fret > endFret) continue;

        final x = fret == 0
            ? leftPad + 0.5 * cellW * 0.5
            : leftPad + (fret - startFret + 0.5) * cellW;

        final noteAtFret = Note.noteAtFret(strings[stringIdx].openNote, fret);
        final isRoot = noteAtFret == rootNote;

        final dotColor = isRoot ? Colors.red[700]! : const Color(0xFF8B6914);
        final radius = isRoot ? 13.0 : 10.0;

        canvas.drawCircle(Offset(x, y), radius, Paint()..color = dotColor);

        if (showNames) {
          final tp = TextPainter(
            text: TextSpan(
              text: noteNameProvider.display(noteAtFret),
              style: const TextStyle(
                  fontSize: 10,
                  color: Colors.white,
                  fontWeight: FontWeight.bold),
            ),
            textDirection: TextDirection.ltr,
          )..layout();
          tp.paint(canvas, Offset(x - tp.width / 2, y - tp.height / 2));
        }
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
