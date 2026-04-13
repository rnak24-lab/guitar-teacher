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
      cagedName: 'Form 1',
      description: 'Root(R) on string 6.\nOctave(O) on string 4, +2 frets.',
      descriptionKo: '루트(R): 6번줄\n옥타브(O): 4번줄, +2프렛 위',
      pattern: [[6, 0], [4, 2]],
    ),
    OctaveForm(
      formNumber: 2,
      cagedName: 'Form 2',
      description: 'Root(R) on string 4.\nOctave(O) on string 2, +3 frets.',
      descriptionKo: '루트(R): 4번줄\n옥타브(O): 2번줄, +3프렛 위',
      pattern: [[4, 0], [2, 3]],
    ),
    OctaveForm(
      formNumber: 3,
      cagedName: 'Form 3',
      description: 'Root(R) on string 2.\nOctave(O) on string 5, +2 frets.',
      descriptionKo: '루트(R): 2번줄\n옥타브(O): 5번줄, +2프렛 위',
      pattern: [[2, 0], [5, 2]],
    ),
    OctaveForm(
      formNumber: 4,
      cagedName: 'Form 4',
      description: 'Root(R) on string 5.\nOctave(O) on string 3, +2 frets.',
      descriptionKo: '루트(R): 5번줄\n옥타브(O): 3번줄, +2프렛 위',
      pattern: [[5, 0], [3, 2]],
    ),
    OctaveForm(
      formNumber: 5,
      cagedName: 'Form 5',
      description: 'Root(R) on string 3.\nOctave(O) on string 1, +3 frets.',
      descriptionKo: '루트(R): 3번줄\n옥타브(O): 1번줄, +3프렛 위',
      pattern: [[3, 0], [1, 3]],
    ),
  ];
}
