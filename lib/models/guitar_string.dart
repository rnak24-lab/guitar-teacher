class GuitarString {
  final int number; // 1~6 (1=high E, 6=low E)
  final String openNote;

  const GuitarString({required this.number, required this.openNote});

  static const List<GuitarString> standard = [
    GuitarString(number: 1, openNote: 'E'),  // high E
    GuitarString(number: 2, openNote: 'B'),
    GuitarString(number: 3, openNote: 'G'),
    GuitarString(number: 4, openNote: 'D'),
    GuitarString(number: 5, openNote: 'A'),
    GuitarString(number: 6, openNote: 'E'),  // low E
  ];

  String get label => '$number번줄 ($openNote)';
}
