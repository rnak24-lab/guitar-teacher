import 'package:flutter/material.dart';
import '../../models/octave_form.dart';
import '../../services/app_localizations.dart';

class FormInfoDialog extends StatelessWidget {
  const FormInfoDialog({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        padding: const EdgeInsets.all(16),
        constraints: const BoxConstraints(maxHeight: 600),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '📐 ${AppLocalizations().t('octave_info_title')}',
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text(
              AppLocalizations().t('octave_info_sub'),
              style: TextStyle(fontSize: 12, color: Colors.grey[500]),
            ),
            const SizedBox(height: 12),
            Flexible(
              child: ListView.separated(
                shrinkWrap: true,
                itemCount: OctaveForm.allForms.length,
                separatorBuilder: (_, __) => const Divider(height: 8),
                itemBuilder: (context, index) {
                  final form = OctaveForm.allForms[index];
                  return _FormCard(form: form, isDark: isDark);
                },
              ),
            ),
            const SizedBox(height: 12),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(AppLocalizations().t('close')),
            ),
          ],
        ),
      ),
    );
  }
}

class _FormCard extends StatelessWidget {
  final OctaveForm form;
  final bool isDark;

  const _FormCard({required this.form, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final rootString = form.pattern[0][0];
    final octaveString = form.pattern[1][0];
    final fretOffset = form.pattern[1][1];

    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF2A2A2A) : Colors.orange.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          // Form number badge
          CircleAvatar(
            radius: 20,
            backgroundColor: Colors.orange,
            child: Text('${form.formNumber}',
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
          ),
          const SizedBox(width: 12),
          // Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(AppLocalizations().t('octave_form_n').replaceAll('{n}', '${form.formNumber}'), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                const SizedBox(height: 4),
                Text(
                  AppLocalizations().locale == 'ko' ? form.descriptionKo : form.description,
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          // Mini fretboard diagram
          _MiniDiagram(
            rootString: rootString,
            octaveString: octaveString,
            fretOffset: fretOffset,
            isDark: isDark,
          ),
        ],
      ),
    );
  }
}

/// Mini 2-string fretboard diagram showing root + octave position
class _MiniDiagram extends StatelessWidget {
  final int rootString;
  final int octaveString;
  final int fretOffset;
  final bool isDark;

  const _MiniDiagram({
    required this.rootString,
    required this.octaveString,
    required this.fretOffset,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 80,
      height: 60,
      child: CustomPaint(
        painter: _MiniDiagramPainter(
          rootString: rootString,
          octaveString: octaveString,
          fretOffset: fretOffset,
          isDark: isDark,
        ),
      ),
    );
  }
}

class _MiniDiagramPainter extends CustomPainter {
  final int rootString;
  final int octaveString;
  final int fretOffset;
  final bool isDark;

  _MiniDiagramPainter({
    required this.rootString,
    required this.octaveString,
    required this.fretOffset,
    required this.isDark,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final linePaint = Paint()..color = (isDark ? Colors.grey[600]! : Colors.grey[400]!)..strokeWidth = 1;
    final stringPaint = Paint()..color = (isDark ? Colors.grey[500]! : Colors.grey[600]!)..strokeWidth = 1.2;

    const numStrings = 6;
    const numFrets = 3;
    final cellW = size.width / (numFrets + 0.5);
    final cellH = size.height / (numStrings - 1);
    const leftPad = 4.0;

    // Draw strings (horizontal)
    for (int s = 0; s < numStrings; s++) {
      final y = s * cellH;
      canvas.drawLine(Offset(leftPad, y), Offset(size.width, y), stringPaint);
    }

    // Draw frets (vertical)
    for (int f = 0; f <= numFrets; f++) {
      final x = leftPad + f * cellW;
      canvas.drawLine(Offset(x, 0), Offset(x, size.height - cellH * 0), linePaint);
    }

    // Draw root dot (red)
    final rootY = (rootString - 1) * cellH;
    final rootX = leftPad + 0.5 * cellW;
    canvas.drawCircle(Offset(rootX, rootY), 7, Paint()..color = Colors.red[700]!);
    _drawText(canvas, 'R', rootX, rootY, Colors.white, 8);

    // Draw octave dot (orange)
    final octY = (octaveString - 1) * cellH;
    final octX = leftPad + (fretOffset + 0.5) * cellW;
    canvas.drawCircle(Offset(octX, octY), 7, Paint()..color = Colors.orange);
    _drawText(canvas, 'O', octX, octY, Colors.white, 8);

    // Fret numbers at bottom
    for (int f = 1; f <= numFrets; f++) {
      final x = leftPad + (f - 0.5) * cellW;
      _drawText(canvas, '$f', x, size.height + 2, Colors.grey, 8);
    }
  }

  void _drawText(Canvas canvas, String text, double x, double y, Color color, double fontSize) {
    final tp = TextPainter(
      text: TextSpan(text: text, style: TextStyle(fontSize: fontSize, color: color, fontWeight: FontWeight.bold)),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, Offset(x - tp.width / 2, y - tp.height / 2));
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
