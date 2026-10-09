/// Grade 1–12, sections A–H (e.g. 1A … 12H) for weekly schedule cells.
abstract final class WeeklyScheduleClassOptions {
  static const List<String> sectionLetters = [
    'A',
    'B',
    'C',
    'D',
    'E',
    'F',
    'G',
    'H',
  ];

  static List<String> all() {
    final options = <String>[];
    for (var grade = 1; grade <= 12; grade++) {
      for (final section in sectionLetters) {
        options.add('$grade$section');
      }
    }
    return options;
  }

  static String? normalizeSelection(String? value) {
    if (value == null || value.trim().isEmpty) return null;
    final trimmed = value.trim().toUpperCase();
    return all().contains(trimmed) ? trimmed : null;
  }
}
