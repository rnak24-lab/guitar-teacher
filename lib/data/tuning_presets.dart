/// Guitar tuning presets — standard + common alternate tunings.
class TuningPreset {
  final String name;

  /// Notes from 6th string (low) to 1st string (high).
  final List<String> notes;

  /// Target frequencies from 6th string to 1st string (A4 = 440 Hz).
  final List<double> frequencies;

  const TuningPreset({
    required this.name,
    required this.notes,
    required this.frequencies,
  });

  /// Build the display map used by the tuner: {'6E': 82.41, …}
  Map<String, double> toFrequencyMap() {
    final map = <String, double>{};
    for (int i = 0; i < notes.length; i++) {
      final key = '${6 - i}${notes[i]}';
      map[key] = frequencies[i];
    }
    return map;
  }

  /// String labels in display order (6→1)
  List<String> get stringLabels =>
      List.generate(notes.length, (i) => '${6 - i}${notes[i]}');

  static const List<TuningPreset> all = [
    TuningPreset(
      name: 'Standard',
      notes: ['E', 'A', 'D', 'G', 'B', 'E'],
      frequencies: [82.41, 110.00, 146.83, 196.00, 246.94, 329.63],
    ),
    TuningPreset(
      name: 'Drop D',
      notes: ['D', 'A', 'D', 'G', 'B', 'E'],
      frequencies: [73.42, 110.00, 146.83, 196.00, 246.94, 329.63],
    ),
    TuningPreset(
      name: 'Open D',
      notes: ['D', 'A', 'D', 'F#', 'A', 'D'],
      frequencies: [73.42, 110.00, 146.83, 185.00, 220.00, 293.66],
    ),
    TuningPreset(
      name: 'Open G',
      notes: ['D', 'G', 'D', 'G', 'B', 'D'],
      frequencies: [73.42, 98.00, 146.83, 196.00, 246.94, 293.66],
    ),
    TuningPreset(
      name: 'Open E',
      notes: ['E', 'B', 'E', 'G#', 'B', 'E'],
      frequencies: [82.41, 123.47, 164.81, 207.65, 246.94, 329.63],
    ),
    TuningPreset(
      name: 'DADGAD',
      notes: ['D', 'A', 'D', 'G', 'A', 'D'],
      frequencies: [73.42, 110.00, 146.83, 196.00, 220.00, 293.66],
    ),
    TuningPreset(
      name: 'Half-step Down',
      notes: ['Eb', 'Ab', 'Db', 'Gb', 'Bb', 'Eb'],
      frequencies: [77.78, 103.83, 138.59, 185.00, 233.08, 311.13],
    ),
  ];

  static TuningPreset byName(String name) =>
      all.firstWhere((t) => t.name == name, orElse: () => all[0]);
}
