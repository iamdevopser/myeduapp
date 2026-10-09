/// Günlük ve tarih aralığı not ortalaması (eşit ağırlıklı).
class StudentDailyPerformance {
  StudentDailyPerformance({
    required this.studentId,
    required this.date,
    required this.dailyAverage,
  });

  final int studentId;
  final String date;
  final double dailyAverage;

  static bool isNumericScore(int? score) {
    return score != null && score >= 1 && score <= 10;
  }

  /// Tek gün için tüm numerik notların eşit ağırlıklı ortalaması.
  static double? averageOfScores(List<int> scores) {
    if (scores.isEmpty) {
      return null;
    }
    return scores.reduce((a, b) => a + b) / scores.length;
  }

  /// Rapor satırlarından öğrenci+gün bazında günlük ortalamalar.
  static Map<int, Map<String, double>> dailyAveragesByStudent(
    List<Map<String, Object?>> rows,
  ) {
    final scoresByStudentDate = <int, Map<String, List<int>>>{};

    for (final row in rows) {
      final studentId = row['ogrenci_id'] as int?;
      final date = row['tarih'] as String? ?? '';
      final score = row['not_deger'] as int?;
      if (studentId == null || date.isEmpty || !isNumericScore(score)) {
        continue;
      }
      scoresByStudentDate
          .putIfAbsent(studentId, () => {})
          .putIfAbsent(date, () => [])
          .add(score!);
    }

    final result = <int, Map<String, double>>{};
    for (final studentEntry in scoresByStudentDate.entries) {
      final daily = <String, double>{};
      for (final dateEntry in studentEntry.value.entries) {
        final avg = averageOfScores(dateEntry.value);
        if (avg != null) {
          daily[dateEntry.key] = avg;
        }
      }
      if (daily.isNotEmpty) {
        result[studentEntry.key] = daily;
      }
    }
    return result;
  }

  static Map<String, double> dailyAveragesForStudent(
    List<Map<String, Object?>> rows, {
    required int studentId,
  }) {
    return dailyAveragesByStudent(rows)[studentId] ?? {};
  }

  /// Seçilen aralıktaki günlük ortalamaların eşit ağırlıklı genel ortalaması.
  static double? periodAverageFromDailyAverages(Map<String, double> dailyAverages) {
    if (dailyAverages.isEmpty) {
      return null;
    }
    final values = dailyAverages.values.toList();
    return values.reduce((a, b) => a + b) / values.length;
  }

  static List<StudentDailyPerformance> sortedDailyListForStudent(
    List<Map<String, Object?>> rows, {
    required int studentId,
  }) {
    final daily = dailyAveragesForStudent(rows, studentId: studentId);
    final dates = daily.keys.toList()..sort();
    return dates
        .map(
          (date) => StudentDailyPerformance(
            studentId: studentId,
            date: date,
            dailyAverage: daily[date]!,
          ),
        )
        .toList();
  }

  static String formatAverage(double? value, {int fractionDigits = 2}) {
    if (value == null) {
      return '—';
    }
    return value.toStringAsFixed(fractionDigits);
  }

  static String formatDisplayDate(String date) {
    if (date.length >= 10) {
      return '${date.substring(8, 10)}.${date.substring(5, 7)}.${date.substring(0, 4)}';
    }
    return date;
  }
}
