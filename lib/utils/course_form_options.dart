/// Shared grade and academic year options for Kurs Ekle and Öğrenci Sınıf Ekle.
class CourseFormOptions {
  static const int minGrade = 1;
  static const int maxGrade = 12;

  static List<String> academicYearOptions() {
    return List.generate(24, (i) {
      final start = 2026 + i;
      final end = (start + 1) % 100;
      return '$start–${end.toString().padLeft(2, '0')}';
    });
  }

  static String gradeLabel(int grade) => '$grade. Sınıf';

  static List<int> grades() =>
      List.generate(maxGrade - minGrade + 1, (i) => minGrade + i);

  static int? parseGradeFromName(String name) {
    final match = RegExp(r'^(\d+)').firstMatch(name.trim());
    if (match == null) {
      return null;
    }
    final grade = int.tryParse(match.group(1) ?? '');
    if (grade == null || grade < minGrade || grade > maxGrade) {
      return null;
    }
    return grade;
  }

  static String resolveAcademicYear(String? value) {
    final years = academicYearOptions();
    if (value != null && years.contains(value)) {
      return value;
    }
    return years.first;
  }

  static int resolveGrade(String? name) =>
      parseGradeFromName(name ?? '') ?? minGrade;

  static const List<String> sectionOptions = <String>[
    'A',
    'B',
    'C',
    'D',
    'E',
    'F',
    'G',
    'H',
  ];

  static String resolveSection(String? value) {
    if (value != null && sectionOptions.contains(value)) {
      return value;
    }
    return sectionOptions.first;
  }

  static String studentClassSubtitle(String year, String? section) {
    final resolved = section?.trim();
    if (resolved != null && resolved.isNotEmpty) {
      return '$year / $resolved';
    }
    return year;
  }

  /// Sınıf Defterim vb. için: `7. Sınıf A` (yıl hariç).
  static String studentClassGradeSectionLabel(
    String name, {
    String? section,
  }) {
    final grade = parseGradeFromName(name);
    final base = grade != null ? gradeLabel(grade) : name.trim();
    final resolved = section?.trim();
    if (resolved != null && resolved.isNotEmpty) {
      return '$base $resolved';
    }
    return base;
  }

  static String studentClassLabel(
    String name,
    String year, {
    String? section,
  }) {
    final resolved = section?.trim();
    if (resolved != null && resolved.isNotEmpty) {
      return '$name · $year · $resolved';
    }
    return '$name · $year';
  }

  static int sectionSortIndex(String? section) {
    final value = section?.trim();
    if (value == null || value.isEmpty) {
      return -1;
    }
    final index = sectionOptions.indexOf(value);
    return index >= 0 ? index : sectionOptions.length;
  }

  static int compareStudentClassRows(
    Map<String, Object?> a,
    Map<String, Object?> b,
  ) {
    final gradeCompare = resolveGrade(a['ad'] as String?)
        .compareTo(resolveGrade(b['ad'] as String?));
    if (gradeCompare != 0) {
      return gradeCompare;
    }
    return sectionSortIndex(a['sube'] as String?)
        .compareTo(sectionSortIndex(b['sube'] as String?));
  }

  /// Sınıf Defterim listesi: seviye ↑, şube A→H; şubesi olmayanlar sonda.
  static int compareStudentClassRowsNotebook(
    Map<String, Object?> a,
    Map<String, Object?> b,
  ) {
    final gradeCompare = resolveGrade(a['ad'] as String?)
        .compareTo(resolveGrade(b['ad'] as String?));
    if (gradeCompare != 0) {
      return gradeCompare;
    }
    final aSection = (a['sube'] as String?)?.trim();
    final bSection = (b['sube'] as String?)?.trim();
    final aEmpty = aSection == null || aSection.isEmpty;
    final bEmpty = bSection == null || bSection.isEmpty;
    if (aEmpty != bEmpty) {
      return aEmpty ? 1 : -1;
    }
    return sectionSortIndex(aSection).compareTo(sectionSortIndex(bSection));
  }
}
