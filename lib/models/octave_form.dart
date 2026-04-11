class OctaveForm {
  final int formNumber;
  final String cagedName;
  final String description;
  final List<List<int>> pattern; // [stringNumber, relativeFret] pairs

  const OctaveForm({
    required this.formNumber,
    required this.cagedName,
    required this.description,
    required this.pattern,
  });

  static const List<OctaveForm> allForms = [
    OctaveForm(
      formNumber: 1,
      cagedName: 'E Form',
      description: 'Root on string 6.\nOctave on string 4, +2 frets.',
      pattern: [[6, 0], [4, 2]],
    ),
    OctaveForm(
      formNumber: 2,
      cagedName: 'D Form',
      description: 'Root on string 4.\nOctave on string 2, +3 frets.',
      pattern: [[4, 0], [2, 3]],
    ),
    OctaveForm(
      formNumber: 3,
      cagedName: 'C Form',
      description: 'Root on string 5.\nOctave on string 3, +2 frets.',
      pattern: [[5, 0], [3, 2]],
    ),
    OctaveForm(
      formNumber: 4,
      cagedName: 'A Form',
      description: 'Root on string 5.\nOctave on string 3, +2 frets.',
      pattern: [[5, 0], [3, 2]],
    ),
    OctaveForm(
      formNumber: 5,
      cagedName: 'G Form',
      description: 'Root on string 6.\nOctave on string 4, +2 frets.',
      pattern: [[6, 0], [4, 2]],
    ),
  ];
}
