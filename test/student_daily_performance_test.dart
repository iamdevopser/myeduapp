import 'package:flutter_test/flutter_test.dart';
import 'package:my_edu_app/utils/student_daily_performance.dart';

void main() {
  group('StudentDailyPerformance', () {
    test('daily average uses equal weight for all numeric scores', () {
      final rows = [
        {
          'ogrenci_id': 1,
          'tarih': '2026-09-09',
          'tur': 'materials',
          'not_deger': 8,
        },
        {
          'ogrenci_id': 1,
          'tarih': '2026-09-09',
          'tur': 'activity',
          'not_deger': 10,
        },
        {
          'ogrenci_id': 1,
          'tarih': '2026-09-09',
          'tur': 'activity',
          'not_deger': 7,
        },
        {
          'ogrenci_id': 1,
          'tarih': '2026-09-09',
          'tur': 'homework',
          'not_deger': 9,
        },
        {
          'ogrenci_id': 1,
          'tarih': '2026-09-09',
          'tur': 'exam',
          'not_deger': 6,
        },
      ];

      final daily = StudentDailyPerformance.dailyAveragesForStudent(
        rows,
        studentId: 1,
      );
      expect(daily['2026-09-09'], 8.0);
    });

    test('empty scores are excluded from daily average', () {
      final rows = [
        {
          'ogrenci_id': 1,
          'tarih': '2026-09-10',
          'tur': 'materials',
          'not_deger': 8,
        },
        {
          'ogrenci_id': 1,
          'tarih': '2026-09-10',
          'tur': 'activity',
          'not_deger': 10,
        },
        {
          'ogrenci_id': 1,
          'tarih': '2026-09-10',
          'tur': 'activity',
          'not_deger': null,
        },
        {
          'ogrenci_id': 1,
          'tarih': '2026-09-10',
          'tur': 'homework',
          'not_deger': 6,
        },
      ];

      final daily = StudentDailyPerformance.dailyAveragesForStudent(
        rows,
        studentId: 1,
      );
      expect(daily['2026-09-10'], 8.0);
    });

    test('period average is equal-weight mean of daily averages', () {
      final daily = {
        '2026-09-09': 8.0,
        '2026-09-10': 7.5,
        '2026-09-11': 9.0,
      };
      final period =
          StudentDailyPerformance.periodAverageFromDailyAverages(daily);
      expect(period, closeTo(8.166666, 0.0001));
    });

    test('days without scores are excluded from period average', () {
      final daily = {
        '2026-09-09': 8.0,
        '2026-09-11': 9.0,
      };
      final period =
          StudentDailyPerformance.periodAverageFromDailyAverages(daily);
      expect(period, 8.5);
    });

    test('no scores returns null period average', () {
      final period =
          StudentDailyPerformance.periodAverageFromDailyAverages({});
      expect(period, isNull);
    });
  });
}
