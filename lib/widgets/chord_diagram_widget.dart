import 'package:flutter/material.dart';
import '../models/chord.dart';

/// Reusable chord diagram widget with optional ? help button
class ChordDiagramWidget extends StatelessWidget {
  final ChordData chord;
  final bool showHelp;
  final double size;

  const ChordDiagramWidget({
    super.key,
    required this.chord,
    this.showHelp = true,
    this.size = 1.0,
  });

  @override
  Widget build(BuildContext context) {
    final frets = chord.frets;
    final playedFrets = frets.where((f) => f > 0).toList();
    final minFret = playedFrets.isEmpty ? 1 : playedFrets.reduce((a, b) => a < b ? a : b);
    final startFret = (minFret > 3) ? minFret : 1;
    final numFrets = 4;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Stack(
      children: [
        Container(
          padding: EdgeInsets.all(12 * size),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF2A2A2A) : Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isDark ? Colors.grey[700]! : const Color(0xFF8B6914),
              width: 1.5,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Chord name header
              Text(
                chord.name,
                style: TextStyle(
                  fontSize: 20 * size,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : const Color(0xFF5D3A00),
                ),
              ),
              SizedBox(height: 4 * size),
              // Fretboard diagram
              _buildFretboard(context, frets, startFret, numFrets, isDark),
              if (chord.barFret != null)
                Padding(
                  padding: EdgeInsets.only(top: 4 * size),
                  child: Text(
                    'Barre: Fret ${chord.barFret}',
                    style: TextStyle(
                      fontSize: 11 * size,
                      color: isDark ? Colors.grey[400] : Colors.brown,
                    ),
                  ),
                ),
            ],
          ),
        ),
        // ? help button
        if (showHelp)
          Positioned(
            top: 4,
            right: 4,
            child: GestureDetector(
              onTap: () => _showChordInfo(context),
              child: Container(
                width: 22 * size,
                height: 22 * size,
                decoration: BoxDecoration(
                  color: isDark ? Colors.grey[700] : Colors.grey[300],
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.help_outline,
                    size: 14 * size,
                    color: isDark ? Colors.white70 : Colors.grey[700]),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildFretboard(BuildContext ctx, List<int> frets, int startFret, int numFrets, bool isDark) {
    final cellW = 28.0 * size;
    final cellH = 24.0 * size;
    final totalW = cellW * 6;
    final totalH = cellH * (numFrets + 1);
    final nutColor = isDark ? Colors.grey[300]! : Colors.black;
    final lineColor = isDark ? Colors.grey[600]! : Colors.grey[800]!;

    return SizedBox(
      width: totalW + 30 * size,
      height: totalH + 28 * size,
      child: CustomPaint(
        painter: _FretboardPainter(
          frets: frets,
          startFret: startFret,
          numFrets: numFrets,
          cellW: cellW,
          cellH: cellH,
          barFret: chord.barFret,
          isDark: isDark,
          nutColor: nutColor,
          lineColor: lineColor,
          size: size,
        ),
      ),
    );
  }

  void _showChordInfo(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('${chord.name} Info'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _infoRow('Type', chord.type.toUpperCase()),
            _infoRow('Difficulty', chord.difficulty),
            _infoRow('Frets', chord.frets.map((f) => f == -1 ? 'X' : '$f').join(' ')),
            if (chord.barFret != null) _infoRow('Barre', 'Fret ${chord.barFret}'),
            const SizedBox(height: 12),
            Text(
              _chordDescription(chord),
              style: TextStyle(
                fontSize: 13,
                color: isDark ? Colors.grey[300] : Colors.grey[700],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('OK')),
        ],
      ),
    );
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Text('$label: ', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
          Text(value, style: const TextStyle(fontSize: 14)),
        ],
      ),
    );
  }

  String _chordDescription(ChordData chord) {
    final type = chord.type;
    if (type == 'major') return 'A bright, happy sounding chord. Root + Major 3rd + Perfect 5th.';
    if (type == 'minor') return 'A sad, melancholic chord. Root + Minor 3rd + Perfect 5th.';
    if (type == '7th') return 'A dominant 7th chord with bluesy tension. Root + Major 3rd + 5th + Minor 7th.';
    if (type == 'maj7') return 'A smooth, dreamy chord. Root + Major 3rd + 5th + Major 7th.';
    if (type == 'm7') return 'A jazzy minor chord. Root + Minor 3rd + 5th + Minor 7th.';
    if (type == '9th') return 'Extended chord with the 9th. Common in jazz and funk.';
    if (type == 'dim') return 'A tense, unstable diminished chord. Root + Minor 3rd + Diminished 5th.';
    if (type == 'dim7') return 'Fully diminished with 4 equally-spaced notes. Very tense.';
    if (type == 'aug') return 'An augmented chord with raised 5th. Root + Major 3rd + Augmented 5th.';
    if (type == 'm7b5') return 'Half-diminished chord (minor 7 flat 5). Common in jazz ii-V-I.';
    if (type == '13th') return 'Extended jazz chord including the 13th (6th). Rich and colorful.';
    return 'A ${chord.type} chord voicing.';
  }
}

class _FretboardPainter extends CustomPainter {
  final List<int> frets;
  final int startFret;
  final int numFrets;
  final double cellW;
  final double cellH;
  final int? barFret;
  final bool isDark;
  final Color nutColor;
  final Color lineColor;
  final double size;

  _FretboardPainter({
    required this.frets,
    required this.startFret,
    required this.numFrets,
    required this.cellW,
    required this.cellH,
    required this.barFret,
    required this.isDark,
    required this.nutColor,
    required this.lineColor,
    required this.size,
  });

  @override
  void paint(Canvas canvas, Size canvasSize) {
    final leftPad = 20.0 * size;
    final topPad = 20.0 * size;

    final stringPaint = Paint()..color = lineColor..strokeWidth = 1.0;
    final fretPaint = Paint()..color = lineColor..strokeWidth = 1.5;
    final nutPaint = Paint()..color = nutColor..strokeWidth = 3.0;
    final dotPaint = Paint()..color = const Color(0xFF8B6914);

    // Draw nut (if starting from fret 1)
    if (startFret == 1) {
      canvas.drawLine(
        Offset(leftPad, topPad),
        Offset(leftPad + cellW * 5, topPad),
        nutPaint,
      );
    }

    // Draw fret number if not starting from 1
    if (startFret > 1) {
      final tp = TextPainter(
        text: TextSpan(
          text: '${startFret}fr',
          style: TextStyle(fontSize: 10 * size, color: Colors.grey),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, Offset(0, topPad));
    }

    // Draw strings (vertical)
    for (int i = 0; i < 6; i++) {
      final x = leftPad + i * cellW;
      canvas.drawLine(Offset(x, topPad), Offset(x, topPad + cellH * numFrets), stringPaint);
    }

    // Draw frets (horizontal)
    for (int i = 0; i <= numFrets; i++) {
      final y = topPad + i * cellH;
      canvas.drawLine(Offset(leftPad, y), Offset(leftPad + cellW * 5, y), fretPaint);
    }

    // Draw barre
    if (barFret != null) {
      final barreY = topPad + (barFret! - startFret + 0.5) * cellH;
      if (barreY >= topPad && barreY <= topPad + cellH * numFrets) {
        final barPaint = Paint()
          ..color = const Color(0xFF8B6914).withValues(alpha: 0.4)
          ..strokeWidth = 8 * size
          ..strokeCap = StrokeCap.round;
        final firstStr = frets.indexWhere((f) => f == barFret);
        final lastStr = frets.lastIndexWhere((f) => f == barFret);
        if (firstStr >= 0 && lastStr >= 0) {
          canvas.drawLine(
            Offset(leftPad + firstStr * cellW, barreY),
            Offset(leftPad + lastStr * cellW, barreY),
            barPaint,
          );
        }
      }
    }

    // Draw finger dots and open/mute markers
    for (int i = 0; i < 6; i++) {
      final f = frets[i];
      final x = leftPad + i * cellW;

      if (f == -1) {
        // Mute X
        final tp = TextPainter(
          text: TextSpan(
            text: 'X',
            style: TextStyle(fontSize: 12 * size, color: Colors.grey[600], fontWeight: FontWeight.bold),
          ),
          textDirection: TextDirection.ltr,
        )..layout();
        tp.paint(canvas, Offset(x - tp.width / 2, topPad - 16 * size));
      } else if (f == 0) {
        // Open O
        canvas.drawCircle(
          Offset(x, topPad - 8 * size),
          5 * size,
          Paint()..color = Colors.transparent..style = PaintingStyle.stroke..strokeWidth = 1.5,
        );
        canvas.drawCircle(
          Offset(x, topPad - 8 * size),
          5 * size,
          Paint()..color = isDark ? Colors.green[300]! : Colors.green..style = PaintingStyle.stroke..strokeWidth = 1.5,
        );
      } else {
        // Fingered dot
        final fretPos = f - startFret;
        if (fretPos >= 0 && fretPos < numFrets) {
          final y = topPad + (fretPos + 0.5) * cellH;
          canvas.drawCircle(Offset(x, y), 8 * size, dotPaint);
          // Fret number text
          final tp = TextPainter(
            text: TextSpan(
              text: '$f',
              style: TextStyle(fontSize: 10 * size, color: Colors.white, fontWeight: FontWeight.bold),
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
