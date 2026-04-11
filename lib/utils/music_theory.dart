import 'dart:math';
import '../models/note.dart';
import '../models/guitar_string.dart';

class MusicTheory {
  static final _random = Random();

  static String randomNote() {
    return Note.allNotes[_random.nextInt(12)];
  }

  static int randomString({int min = 1, int max = 6}) {
    return min + _random.nextInt(max - min + 1);
  }

  static Map<String, dynamic> generateQuestion({
    List<int>? allowedStrings,
    int maxFret = 12,
  }) {
    final strings = allowedStrings ?? [1, 2, 3, 4, 5, 6];
    final stringNum = strings[_random.nextInt(strings.length)];
    final guitarString = GuitarString.standard[stringNum - 1];
    final note = randomNote();
    final correctFrets = Note.allFretsForNote(
      guitarString.openNote, note, maxFret: maxFret,
    );

    return {
      'note': note,
      'string': stringNum,
      'openNote': guitarString.openNote,
      'correctFrets': correctFrets,
    };
  }
}
