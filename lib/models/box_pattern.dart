/// Box Pattern data for Pentatonic and Major Scale positions.
///
/// Each pattern is defined as fret offsets per string (relative to root fret).
/// Strings are ordered 6→1 (low E to high E).
/// Each entry is a list of fret offsets from the root position.
class BoxPattern {
  final String name;

  /// Display names per language
  final Map<String, String> displayNames;

  /// 6 lists (one per string, low-E first), each containing
  /// fret offsets relative to the pattern's start position.
  final List<List<int>> fretOffsets;

  const BoxPattern({
    required this.name,
    required this.displayNames,
    required this.fretOffsets,
  });

  // ── Pentatonic Minor Box Patterns (5 positions) ──
  static const List<BoxPattern> pentatonicMinor = [
    BoxPattern(
      name: 'Position 1',
      displayNames: {'en': 'Position 1', 'ko': '1번 포지션', 'ja': 'ポジション1'},
      fretOffsets: [
        [0, 3], // 6th string
        [0, 3], // 5th string
        [0, 2], // 4th string
        [0, 2], // 3rd string
        [0, 3], // 2nd string
        [0, 3], // 1st string
      ],
    ),
    BoxPattern(
      name: 'Position 2',
      displayNames: {'en': 'Position 2', 'ko': '2번 포지션', 'ja': 'ポジション2'},
      fretOffsets: [
        [0, 2],
        [0, 3],
        [0, 2],
        [0, 2],
        [0, 2],
        [0, 2],
      ],
    ),
    BoxPattern(
      name: 'Position 3',
      displayNames: {'en': 'Position 3', 'ko': '3번 포지션', 'ja': 'ポジション3'},
      fretOffsets: [
        [0, 2],
        [0, 2],
        [0, 2],
        [0, 3],
        [0, 2],
        [0, 2],
      ],
    ),
    BoxPattern(
      name: 'Position 4',
      displayNames: {'en': 'Position 4', 'ko': '4번 포지션', 'ja': 'ポジション4'},
      fretOffsets: [
        [0, 2],
        [0, 2],
        [0, 3],
        [0, 2],
        [0, 2],
        [0, 3],
      ],
    ),
    BoxPattern(
      name: 'Position 5',
      displayNames: {'en': 'Position 5', 'ko': '5번 포지션', 'ja': 'ポジション5'},
      fretOffsets: [
        [0, 3],
        [0, 2],
        [0, 2],
        [0, 2],
        [0, 3],
        [0, 2],
      ],
    ),
  ];

  // ── Major Scale Box Patterns (7 positions / CAGED-extended) ──
  static const List<BoxPattern> majorScale = [
    BoxPattern(
      name: 'Position 1',
      displayNames: {'en': 'Position 1', 'ko': '1번 포지션', 'ja': 'ポジション1'},
      fretOffsets: [
        [0, 2, 4],
        [0, 2, 4],
        [1, 2, 4],
        [1, 2, 4],
        [1, 2],
        [0, 2, 4],
      ],
    ),
    BoxPattern(
      name: 'Position 2',
      displayNames: {'en': 'Position 2', 'ko': '2번 포지션', 'ja': 'ポジション2'},
      fretOffsets: [
        [0, 2],
        [0, 2],
        [0, 2],
        [0, 2],
        [0, 2, 3],
        [0, 2],
      ],
    ),
    BoxPattern(
      name: 'Position 3',
      displayNames: {'en': 'Position 3', 'ko': '3번 포지션', 'ja': 'ポジション3'},
      fretOffsets: [
        [0, 2],
        [0, 2, 3],
        [0, 2],
        [0, 1],
        [0, 2],
        [0, 2],
      ],
    ),
    BoxPattern(
      name: 'Position 4',
      displayNames: {'en': 'Position 4', 'ko': '4번 포지션', 'ja': 'ポジション4'},
      fretOffsets: [
        [0, 2],
        [0, 2],
        [0, 1],
        [0, 2],
        [0, 2],
        [0, 2],
      ],
    ),
    BoxPattern(
      name: 'Position 5',
      displayNames: {'en': 'Position 5', 'ko': '5번 포지션', 'ja': 'ポジション5'},
      fretOffsets: [
        [0, 1, 2],
        [0, 2],
        [0, 2],
        [0, 2],
        [0, 2],
        [0, 1, 2],
      ],
    ),
    BoxPattern(
      name: 'Position 6',
      displayNames: {'en': 'Position 6', 'ko': '6번 포지션', 'ja': 'ポジション6'},
      fretOffsets: [
        [0, 2],
        [0, 2],
        [0, 2],
        [0, 2, 4],
        [0, 2],
        [0, 2],
      ],
    ),
    BoxPattern(
      name: 'Position 7',
      displayNames: {'en': 'Position 7', 'ko': '7번 포지션', 'ja': 'ポジション7'},
      fretOffsets: [
        [0, 2],
        [0, 2],
        [0, 2, 4],
        [0, 2],
        [0, 2],
        [0, 2],
      ],
    ),
  ];
}
