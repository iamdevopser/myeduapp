import 'package:flutter_test/flutter_test.dart';
import 'package:my_edu_app/utils/student_monthly_performance.dart';

void main() {
  group('StudentMonthlyPerformance monthLabelFromKey', () {
    test('uses Turkish month names for tr locale', () {
      expect(
        StudentMonthlyPerformance.monthLabelFromKey('2026-09', locale: 'tr'),
        contains('Eylül'),
      );
    });

    test('uses English month names for en locale', () {
      expect(
        StudentMonthlyPerformance.monthLabelFromKey('2026-09', locale: 'en'),
        contains('September'),
      );
    });
  });
}
