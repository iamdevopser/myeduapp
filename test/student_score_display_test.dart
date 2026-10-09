import 'package:flutter_test/flutter_test.dart';
import 'package:my_edu_app/utils/student_daily_performance.dart';
import 'package:my_edu_app/utils/student_score_display.dart';

void main() {
  test('formatStudentScoreDisplay handles numeric, absent and empty', () {
    expect(formatStudentScoreDisplay(numericScore: 8), '8');
    expect(formatStudentScoreDisplay(absent: true), 'a');
    expect(formatStudentScoreDisplay(), '—');
  });

  test('daily average ignores absent rows', () {
    final averages = StudentDailyPerformance.dailyAveragesByStudent([
      {
        'ogrenci_id': 1,
        'tarih': '2026-10-01',
        'not_deger': 8,
        'devamsiz': 0,
      },
      {
        'ogrenci_id': 1,
        'tarih': '2026-10-01',
        'not_deger': null,
        'devamsiz': 1,
      },
      {
        'ogrenci_id': 1,
        'tarih': '2026-10-02',
        'not_deger': 10,
        'devamsiz': 0,
      },
    ]);
    expect(averages[1]!['2026-10-01'], 8);
    expect(averages[1]!['2026-10-02'], 10);
  });
}
