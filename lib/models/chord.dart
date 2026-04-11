class ChordData {
  final String name;
  final String type;
  final String difficulty; // beginner, intermediate, advanced
  final List<int> frets; // -1=mute, 0=open, 1~12=fret (6번줄→1번줄)
  final int? barFret; // 바레 프렛 (null이면 없음)

  const ChordData({
    required this.name,
    required this.type,
    required this.difficulty,
    required this.frets,
    this.barFret,
  });

  // === 초급: 오픈코드 (0~3프렛) ===
  static const List<ChordData> beginnerChords = [
    ChordData(name: 'C', type: 'major', difficulty: 'beginner', frets: [-1, 3, 2, 0, 1, 0]),
    ChordData(name: 'D', type: 'major', difficulty: 'beginner', frets: [-1, -1, 0, 2, 3, 2]),
    ChordData(name: 'E', type: 'major', difficulty: 'beginner', frets: [0, 2, 2, 1, 0, 0]),
    ChordData(name: 'G', type: 'major', difficulty: 'beginner', frets: [3, 2, 0, 0, 0, 3]),
    ChordData(name: 'A', type: 'major', difficulty: 'beginner', frets: [-1, 0, 2, 2, 2, 0]),
    ChordData(name: 'Am', type: 'minor', difficulty: 'beginner', frets: [-1, 0, 2, 2, 1, 0]),
    ChordData(name: 'Em', type: 'minor', difficulty: 'beginner', frets: [0, 2, 2, 0, 0, 0]),
    ChordData(name: 'Dm', type: 'minor', difficulty: 'beginner', frets: [-1, -1, 0, 2, 3, 1]),
    ChordData(name: 'E7', type: '7th', difficulty: 'beginner', frets: [0, 2, 0, 1, 0, 0]),
    ChordData(name: 'A7', type: '7th', difficulty: 'beginner', frets: [-1, 0, 2, 0, 2, 0]),
    ChordData(name: 'D7', type: '7th', difficulty: 'beginner', frets: [-1, -1, 0, 2, 1, 2]),
    ChordData(name: 'G7', type: '7th', difficulty: 'beginner', frets: [3, 2, 0, 0, 0, 1]),
    ChordData(name: 'C7', type: '7th', difficulty: 'beginner', frets: [-1, 3, 2, 3, 1, 0]),
  ];

  // === 중급: 바레코드/하이코드 ===
  static const List<ChordData> intermediateChords = [
    ChordData(name: 'F', type: 'major', difficulty: 'intermediate', frets: [1, 3, 3, 2, 1, 1], barFret: 1),
    ChordData(name: 'Bb', type: 'major', difficulty: 'intermediate', frets: [-1, 1, 3, 3, 3, 1], barFret: 1),
    ChordData(name: 'B', type: 'major', difficulty: 'intermediate', frets: [-1, 2, 4, 4, 4, 2], barFret: 2),
    ChordData(name: 'Db', type: 'major', difficulty: 'intermediate', frets: [-1, 4, 6, 6, 6, 4], barFret: 4),
    ChordData(name: 'Eb', type: 'major', difficulty: 'intermediate', frets: [-1, -1, 1, 3, 4, 3]),
    ChordData(name: 'Ab', type: 'major', difficulty: 'intermediate', frets: [4, 6, 6, 5, 4, 4], barFret: 4),
    ChordData(name: 'Fm', type: 'minor', difficulty: 'intermediate', frets: [1, 3, 3, 1, 1, 1], barFret: 1),
    ChordData(name: 'Bm', type: 'minor', difficulty: 'intermediate', frets: [-1, 2, 4, 4, 3, 2], barFret: 2),
    ChordData(name: 'Cm', type: 'minor', difficulty: 'intermediate', frets: [-1, 3, 5, 5, 4, 3], barFret: 3),
    ChordData(name: 'Gm', type: 'minor', difficulty: 'intermediate', frets: [3, 5, 5, 3, 3, 3], barFret: 3),
    ChordData(name: 'Fmaj7', type: 'maj7', difficulty: 'intermediate', frets: [-1, -1, 3, 2, 1, 0]),
    ChordData(name: 'Cmaj7', type: 'maj7', difficulty: 'intermediate', frets: [-1, 3, 2, 0, 0, 0]),
    ChordData(name: 'Bbmaj7', type: 'maj7', difficulty: 'intermediate', frets: [-1, 1, 3, 2, 3, 1], barFret: 1),
  ];

  // === 고급: 재즈코드 ===
  static const List<ChordData> advancedChords = [
    // m7
    ChordData(name: 'Am7', type: 'm7', difficulty: 'advanced', frets: [-1, 0, 2, 0, 1, 0]),
    ChordData(name: 'Dm7', type: 'm7', difficulty: 'advanced', frets: [-1, -1, 0, 2, 1, 1]),
    ChordData(name: 'Em7', type: 'm7', difficulty: 'advanced', frets: [0, 2, 0, 0, 0, 0]),
    ChordData(name: 'Cm7', type: 'm7', difficulty: 'advanced', frets: [-1, 3, 5, 3, 4, 3], barFret: 3),
    ChordData(name: 'Fm7', type: 'm7', difficulty: 'advanced', frets: [1, 3, 1, 1, 1, 1], barFret: 1),
    ChordData(name: 'Bbm7', type: 'm7', difficulty: 'advanced', frets: [-1, 1, 3, 1, 2, 1], barFret: 1),
    // 9th
    ChordData(name: 'G9', type: '9th', difficulty: 'advanced', frets: [3, 2, 0, 2, 0, 1]),
    ChordData(name: 'C9', type: '9th', difficulty: 'advanced', frets: [-1, 3, 2, 3, 3, 3]),
    ChordData(name: 'D9', type: '9th', difficulty: 'advanced', frets: [-1, -1, 0, 2, 1, 0]),
    // dim
    ChordData(name: 'Bdim', type: 'dim', difficulty: 'advanced', frets: [-1, 2, 3, 4, 3, -1]),
    ChordData(name: 'Cdim7', type: 'dim7', difficulty: 'advanced', frets: [-1, 3, 4, 2, 4, 2]),
    // aug
    ChordData(name: 'Caug', type: 'aug', difficulty: 'advanced', frets: [-1, 3, 2, 1, 1, 0]),
    ChordData(name: 'Eaug', type: 'aug', difficulty: 'advanced', frets: [0, 3, 2, 1, 1, 0]),
    // m7b5
    ChordData(name: 'Bm7b5', type: 'm7b5', difficulty: 'advanced', frets: [-1, 2, 3, 2, 3, -1]),
    ChordData(name: 'Am7b5', type: 'm7b5', difficulty: 'advanced', frets: [-1, 0, 1, 2, 1, 3]),
    // 13th, altered
    ChordData(name: 'G13', type: '13th', difficulty: 'advanced', frets: [3, -1, 0, 0, 0, 0]),
    ChordData(name: 'C13', type: '13th', difficulty: 'advanced', frets: [-1, 3, 2, 3, 3, 5]),
    ChordData(name: 'Db9', type: '9th', difficulty: 'advanced', frets: [-1, 4, 3, 4, 4, 4], barFret: 4),
    ChordData(name: 'Abmaj7', type: 'maj7', difficulty: 'advanced', frets: [4, -1, 5, 5, 4, -1]),
    ChordData(name: 'Ebm7', type: 'm7', difficulty: 'advanced', frets: [-1, -1, 1, 3, 2, 2]),
  ];

  static List<ChordData> byDifficulty(String difficulty) {
    switch (difficulty) {
      case 'beginner': return beginnerChords;
      case 'intermediate': return intermediateChords;
      case 'advanced': return advancedChords;
      default: return beginnerChords;
    }
  }

  static List<ChordData> get allChords => [...beginnerChords, ...intermediateChords, ...advancedChords];
}
