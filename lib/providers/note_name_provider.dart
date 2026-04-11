import 'package:shared_preferences/shared_preferences.dart';
import '../services/app_localizations.dart';

/// Provides note name display based on user preference (alphabet vs solfege).
/// Alphabet: C D E F G A B
/// Solfege:  Do Re Mi Fa Sol La Si
class NoteNameProvider {
  static final NoteNameProvider _instance = NoteNameProvider._();
  factory NoteNameProvider() => _instance;
  NoteNameProvider._();

  static const String _prefKey = 'note_name_system';

  // 'alphabet' or 'solfege'
  String _system = 'alphabet';
  String get system => _system;
  bool get isSolfege => _system == 'solfege';

  /// Alphabet -> Solfege mapping
  static const Map<String, String> _toSolfege = {
    'C': 'Do',
    'D': 'Re',
    'E': 'Mi',
    'F': 'Fa',
    'G': 'Sol',
    'A': 'La',
    'B': 'Si',
  };

  /// Initialize from SharedPreferences + locale default
  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString(_prefKey);
    if (saved != null) {
      _system = saved;
    } else {
      // Set default based on locale
      _system = _defaultForLocale(AppLocalizations().locale);
    }
  }

  /// Set system and persist
  Future<void> setSystem(String system) async {
    _system = system;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefKey, system);
  }

  /// Default system based on locale
  static String _defaultForLocale(String locale) {
    switch (locale) {
      case 'fr':
      case 'es':
        return 'solfege';
      default:
        return 'alphabet';
    }
  }

  /// Convert a single note name for display.
  /// Input: 'C', 'Db', 'C#', 'Eb', etc.
  /// Output depends on current system setting.
  String display(String note) {
    if (_system == 'alphabet') return note;

    // Handle accidentals: e.g. 'Db' -> 'Reb', 'C#' -> 'Do#'
    if (note.length == 1) {
      return _toSolfege[note] ?? note;
    }

    final baseLetter = note[0]; // e.g. 'C', 'D'
    final accidental = note.substring(1); // e.g. 'b', '#'
    final solfegeBase = _toSolfege[baseLetter];
    if (solfegeBase == null) return note;

    // Convert accidental: 'b' -> 'b', '#' -> '#'
    return '$solfegeBase$accidental';
  }

  /// Convert a list of note names for display.
  List<String> displayAll(List<String> notes) {
    return notes.map(display).toList();
  }

  /// Convert a chord name for display.
  /// Input: 'Am', 'C#m7', 'Bb7', etc.
  /// Extracts the root note (1-2 chars), converts it, keeps the rest.
  String displayChord(String chordName) {
    if (_system == 'alphabet') return chordName;
    if (chordName.isEmpty) return chordName;

    // Try 2-char root first (e.g. 'Bb', 'C#', 'Db', 'Eb')
    if (chordName.length >= 2 && (chordName[1] == 'b' || chordName[1] == '#')) {
      final root = chordName.substring(0, 2);
      final suffix = chordName.substring(2);
      return '${display(root)}$suffix';
    }

    // Single-char root (e.g. 'C', 'A', 'G')
    final root = chordName[0];
    final suffix = chordName.substring(1);
    return '${display(root)}$suffix';
  }

  /// Called when locale changes to reset default if user hasn't explicitly set
  Future<void> onLocaleChanged(String newLocale) async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString(_prefKey);
    if (saved == null) {
      _system = _defaultForLocale(newLocale);
    }
  }
}
