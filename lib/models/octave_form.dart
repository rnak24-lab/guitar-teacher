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
      description: '6번줄 루트 기준. 6번줄과 4번줄에서 같은 프렛,\n1번줄은 6번줄과 동일.',
      pattern: [[6, 0], [4, 2], [1, 0]],
    ),
    OctaveForm(
      formNumber: 2,
      cagedName: 'D Form',
      description: '4번줄 루트 기준. 4번줄에서 시작,\n2번줄은 +3프렛, 6번줄은 -2프렛.',
      pattern: [[4, 0], [2, 3], [6, -2]],
    ),
    OctaveForm(
      formNumber: 3,
      cagedName: 'C Form',
      description: '5번줄 루트 기준. 5번줄에서 시작,\n3번줄은 +2프렛, 1번줄은 +5프렛.',
      pattern: [[5, 0], [3, 2], [1, 5]],
    ),
    OctaveForm(
      formNumber: 4,
      cagedName: 'A Form',
      description: '5번줄 루트 기준. 5번줄에서 시작,\n3번줄은 +2프렛.',
      pattern: [[5, 0], [3, 2]],
    ),
    OctaveForm(
      formNumber: 5,
      cagedName: 'G Form',
      description: '6번줄 루트 기준. 6번줄에서 시작,\n4번줄은 +2프렛, 1번줄은 +3프렛.',
      pattern: [[6, 0], [4, 2], [1, 3]],
    ),
  ];
}
