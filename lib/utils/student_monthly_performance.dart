/// Computes monthly category and overall averages from daily score rows.
class StudentMonthlyPerformance {
  StudentMonthlyPerformance({
    required this.studentId,
    required this.studentName,
    required this.monthKey,
    required this.monthLabel,
    required this.categoryCode,
    required this.categoryName,
    required this.categoryAverage,
    required this.monthlyOverallAverage,
  });

  final int studentId;
  final String studentName;
  final String monthKey;
  final String monthLabel;
  final String categoryCode;
  final String categoryName;
  final double categoryAverage;
  final double monthlyOverallAverage;

  static const Map<String, List<String>> _monthNamesByLocale = {
    'tr': [
      'Ocak',
      'Şubat',
      'Mart',
      'Nisan',
      'Mayıs',
      'Haziran',
      'Temmuz',
      'Ağustos',
      'Eylül',
      'Ekim',
      'Kasım',
      'Aralık',
    ],
    'en': [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ],
    'ro': [
      'Ianuarie',
      'Februarie',
      'Martie',
      'Aprilie',
      'Mai',
      'Iunie',
      'Iulie',
      'August',
      'Septembrie',
      'Octombrie',
      'Noiembrie',
      'Decembrie',
    ],
    'ru': [
      'Январь',
      'Февраль',
      'Март',
      'Апрель',
      'Май',
      'Июнь',
      'Июль',
      'Август',
      'Сентябрь',
      'Октябрь',
      'Ноябрь',
      'Декабрь',
    ],
  };

  static String monthKeyFromDate(String date) {
    return date.length >= 7 ? date.substring(0, 7) : date;
  }

  static String monthLabelFromKey(String monthKey, {String locale = 'tr'}) {
    final parts = monthKey.split('-');
    if (parts.length != 2) {
      return monthKey;
    }
    final year = int.tryParse(parts[0]);
    final month = int.tryParse(parts[1]);
    if (year == null || month == null || month < 1 || month > 12) {
      return monthKey;
    }
    final names =
        _monthNamesByLocale[locale] ?? _monthNamesByLocale['tr']!;
    return '${names[month - 1]} $year';
  }

  static List<StudentMonthlyPerformance> fromReportRows(
    List<Map<String, Object?>> rows, {
    required Map<String, String> categoryNames,
    Set<String> excludedCategoryCodes = const {'students'},
    String locale = 'tr',
  }) {
    final scoresByBucket = <String, List<int>>{};
    final studentNames = <int, String>{};

    for (final row in rows) {
      final categoryCode = row['tur'] as String? ?? '';
      if (excludedCategoryCodes.contains(categoryCode)) {
        continue;
      }
      final score = row['not_deger'] as int?;
      if (score == null) {
        continue;
      }
      final studentId = row['ogrenci_id'] as int?;
      final date = row['tarih'] as String? ?? '';
      if (studentId == null || date.isEmpty) {
        continue;
      }
      studentNames[studentId] =
          '${row['numara'] ?? ''} ${row['ad_soyad'] ?? ''}'.trim();
      final monthKey = monthKeyFromDate(date);
      final bucket = '$studentId|$monthKey|$categoryCode';
      scoresByBucket.putIfAbsent(bucket, () => []).add(score);
    }

    final categoryAveragesByStudentMonth = <String, Map<String, double>>{};
    for (final entry in scoresByBucket.entries) {
      final parts = entry.key.split('|');
      if (parts.length != 3) {
        continue;
      }
      final studentMonth = '${parts[0]}|${parts[1]}';
      final categoryCode = parts[2];
      final scores = entry.value;
      if (scores.isEmpty) {
        continue;
      }
      final avg = scores.reduce((a, b) => a + b) / scores.length;
      categoryAveragesByStudentMonth
          .putIfAbsent(studentMonth, () => {})[categoryCode] = avg;
    }

    final results = <StudentMonthlyPerformance>[];
    for (final entry in categoryAveragesByStudentMonth.entries) {
      final parts = entry.key.split('|');
      if (parts.length != 2) {
        continue;
      }
      final studentId = int.tryParse(parts[0]);
      final monthKey = parts[1];
      if (studentId == null) {
        continue;
      }
      final categoryAvgs = entry.value.values.toList();
      if (categoryAvgs.isEmpty) {
        continue;
      }
      final overall =
          categoryAvgs.reduce((a, b) => a + b) / categoryAvgs.length;
      for (final categoryEntry in entry.value.entries) {
        results.add(
          StudentMonthlyPerformance(
            studentId: studentId,
            studentName: studentNames[studentId] ?? '',
            monthKey: monthKey,
            monthLabel: monthLabelFromKey(monthKey, locale: locale),
            categoryCode: categoryEntry.key,
            categoryName:
                categoryNames[categoryEntry.key] ?? categoryEntry.key,
            categoryAverage: categoryEntry.value,
            monthlyOverallAverage: overall,
          ),
        );
      }
    }

    results.sort((a, b) {
      final monthCompare = a.monthKey.compareTo(b.monthKey);
      if (monthCompare != 0) {
        return monthCompare;
      }
      final studentCompare = a.studentId.compareTo(b.studentId);
      if (studentCompare != 0) {
        return studentCompare;
      }
      return a.categoryCode.compareTo(b.categoryCode);
    });
    return results;
  }

  static List<Map<String, String>> uniqueMonthlyOverallRows(
    List<StudentMonthlyPerformance> items,
  ) {
    final seen = <String>{};
    final rows = <Map<String, String>>[];
    for (final item in items) {
      final key = '${item.studentId}|${item.monthKey}';
      if (seen.contains(key)) {
        continue;
      }
      seen.add(key);
      rows.add({
        'student': item.studentName,
        'month': item.monthLabel,
        'overall': item.monthlyOverallAverage.toStringAsFixed(2),
      });
    }
    return rows;
  }
}
