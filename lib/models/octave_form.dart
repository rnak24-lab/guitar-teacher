class OctaveForm {
  final int formNumber;
  final String cagedName;
  final String description;
  final String descriptionKo;
  final List<List<int>> pattern; // [stringNumber, relativeFret] pairs

  const OctaveForm({
    required this.formNumber,
    required this.cagedName,
    required this.description,
    required this.descriptionKo,
    required this.pattern,
  });

  static const List<OctaveForm> allForms = [
    OctaveForm(
      formNumber: 1,
      cagedName: 'E Form',
      description: 'Root on string 6.\nOctave on string 4, +2 frets.',
      descriptionKo: '루트: 6번줄\n옥타브: 4번줄, +2프렛 위',
      pattern: [[6, 0], [4, 2]],
    ),
    OctaveForm(
      formNumber: 2,
      cagedName: 'D Form',
      description: 'Root on string 4.\nOctave on string 2, +3 frets.',
      descriptionKo: '루트: 4번줄\n옥타브: 2번줄, +3프렛 위',
      pattern: [[4, 0], [2, 3]],
    ),
    OctaveForm(
      formNumber: 3,
      cagedName: 'C Form',
      description: 'Root on string 2.\nOctave on string 5, +2 frets.',
      descriptionKo: '루트: 2번줄\n옥타브: 5번줄, +2프렛 위',
      pattern: [[2, 0], [5, 2]],
    ),
    OctaveForm(
      formNumber: 4,
      cagedName: 'A Form',
      description: 'Root on string 5.\nOctave on string 3, +2 frets.',
      descriptionKo: '루트: 5번줄\n옥타브: 3번줄, +2프렛 위',
      pattern: [[5, 0], [3, 2]],
    ),
    OctaveForm(
      formNumber: 5,
      cagedName: 'G Form',
      description: 'Root on string 3.\nOctave on string 1, +3 frets.',
      descriptionKo: '루트: 3번줄\n옥타브: 1번줄, +3프렛 위',
      pattern: [[3, 0], [1, 3]],
    ),
  ];
}
