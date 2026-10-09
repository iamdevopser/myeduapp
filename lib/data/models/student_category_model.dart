class StudentCategory {
  StudentCategory({
    required this.id,
    required this.classId,
    required this.name,
    required this.code,
    required this.order,
    required this.active,
    required this.system,
  });

  static const String performanceCode = 'performance';
  static const String behaviorsCode = 'behaviors';

  static const List<String> performanceScoreTypes = ['materials', 'activity'];

  static const Map<String, int> systemOrderByCode = {
    'students': 1,
    'performance': 2,
    'homework': 3,
    'exam': 4,
    'behaviors': 5,
    // Eski kurulumlar — menüde gösterilmez, veri korunur.
    'materials': 2,
    'activity': 3,
  };

  static const List<Map<String, Object>> defaultSystemCategories = [
    {'ad': 'Öğrenci Listesi', 'kod': 'students', 'sira': 1},
    {'ad': 'Performans', 'kod': 'performance', 'sira': 2},
    {'ad': 'Ödevler', 'kod': 'homework', 'sira': 3},
    {'ad': 'Sınavlar', 'kod': 'exam', 'sira': 4},
    {'ad': 'Davranışlar', 'kod': 'behaviors', 'sira': 5},
  ];

  static bool isPerformanceCode(String code) {
    return code == performanceCode || code == 'materials' || code == 'activity';
  }

  /// Eski menü kodları — Performans menüsü ile değiştirildi.
  static bool isPerformanceLegacyMenuCode(String code) {
    return code == 'materials' || code == 'activity';
  }

  final int id;
  final int classId;
  final String name;
  final String code;
  final int order;
  final bool active;
  final bool system;

  bool get isFixedSystemCategory =>
      system && systemOrderByCode.containsKey(code);

  static int displayOrder(StudentCategory category) {
    if (category.isFixedSystemCategory) {
      return systemOrderByCode[category.code]!;
    }
    return 1000 + category.order;
  }

  static int compareByDisplayOrder(StudentCategory a, StudentCategory b) {
    final order = displayOrder(a).compareTo(displayOrder(b));
    if (order != 0) {
      return order;
    }
    return a.id.compareTo(b.id);
  }

  factory StudentCategory.fromMap(Map<String, Object?> map) {
    return StudentCategory(
      id: map['id'] as int,
      classId: map['sinif_id'] as int,
      name: map['ad'] as String,
      code: map['kod'] as String,
      order: map['sira'] as int,
      active: (map['aktif'] as int? ?? 1) == 1,
      system: (map['sistem'] as int? ?? 0) == 1,
    );
  }
}
