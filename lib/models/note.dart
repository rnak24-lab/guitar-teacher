class Note {
  static const List<String> allNotes = [
    'C', 'Db', 'D', 'Eb', 'E', 'F', 'Gb', 'G', 'Ab', 'A', 'Bb', 'B'
  ];

  static int noteIndex(String note) => allNotes.indexOf(note);

  static String noteAtIndex(int index) => allNotes[index % 12];

  static String noteAtFret(String openNote, int fret) {
    final startIndex = noteIndex(openNote);
    return noteAtIndex(startIndex + fret);
  }

  static int fretForNote(String openNote, String targetNote) {
    final startIndex = noteIndex(openNote);
    final targetIndex = noteIndex(targetNote);
    return (targetIndex - startIndex + 12) % 12;
  }

  static List<int> allFretsForNote(String openNote, String targetNote, {int maxFret = 12}) {
    final frets = <int>[];
    for (int fret = 0; fret <= maxFret; fret++) {
      if (noteAtFret(openNote, fret) == targetNote) {
        frets.add(fret);
      }
    }
    return frets;
  }
}
