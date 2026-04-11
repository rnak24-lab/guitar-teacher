import 'note.dart';

class ScaleData {
  final String name;
  final List<int> intervals; // semitone intervals from root

  const ScaleData({required this.name, required this.intervals});

  /// Get note names for this scale starting from rootNote
  List<String> notesForRoot(String rootNote) {
    final rootIdx = Note.noteIndex(rootNote);
    return intervals.map((i) => Note.noteAtIndex(rootIdx + i)).toList();
  }

  /// Get fret positions for this scale on a given string (openNote)
  /// within fret range [minFret, maxFret]
  List<int> fretsOnString(String openNote, String rootNote, {int minFret = 0, int maxFret = 12}) {
    final notes = notesForRoot(rootNote);
    final frets = <int>[];
    for (int fret = minFret; fret <= maxFret; fret++) {
      final noteAtFret = Note.noteAtFret(openNote, fret);
      if (notes.contains(noteAtFret)) {
        frets.add(fret);
      }
    }
    return frets;
  }

  // === Common Scales ===
  static const List<ScaleData> allScales = [
    // Major modes
    ScaleData(name: 'Major (Ionian)', intervals: [0, 2, 4, 5, 7, 9, 11]),
    ScaleData(name: 'Dorian', intervals: [0, 2, 3, 5, 7, 9, 10]),
    ScaleData(name: 'Phrygian', intervals: [0, 1, 3, 5, 7, 8, 10]),
    ScaleData(name: 'Lydian', intervals: [0, 2, 4, 6, 7, 9, 11]),
    ScaleData(name: 'Mixolydian', intervals: [0, 2, 4, 5, 7, 9, 10]),
    ScaleData(name: 'Natural Minor (Aeolian)', intervals: [0, 2, 3, 5, 7, 8, 10]),
    ScaleData(name: 'Locrian', intervals: [0, 1, 3, 5, 6, 8, 10]),
    // Pentatonic
    ScaleData(name: 'Major Pentatonic', intervals: [0, 2, 4, 7, 9]),
    ScaleData(name: 'Minor Pentatonic', intervals: [0, 3, 5, 7, 10]),
    // Blues
    ScaleData(name: 'Blues', intervals: [0, 3, 5, 6, 7, 10]),
    // Harmonic/Melodic minor
    ScaleData(name: 'Harmonic Minor', intervals: [0, 2, 3, 5, 7, 8, 11]),
    ScaleData(name: 'Melodic Minor', intervals: [0, 2, 3, 5, 7, 9, 11]),
    // Chromatic
    ScaleData(name: 'Chromatic', intervals: [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11]),
  ];

  static ScaleData byName(String name) =>
      allScales.firstWhere((s) => s.name == name, orElse: () => allScales[0]);
}
