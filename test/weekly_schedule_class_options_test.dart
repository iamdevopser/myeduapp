import 'package:flutter_test/flutter_test.dart';
import 'package:my_edu_app/screens/academic_plans/weekly_schedule_class_options.dart';

void main() {
  test('all class options are 1A through 12H', () {
    final options = WeeklyScheduleClassOptions.all();
    expect(options.length, 12 * 8);
    expect(options.first, '1A');
    expect(options[7], '1H');
    expect(options[8], '2A');
    expect(options.last, '12H');
  });

  test('normalizeSelection accepts valid labels', () {
    expect(WeeklyScheduleClassOptions.normalizeSelection('9d'), '9D');
    expect(WeeklyScheduleClassOptions.normalizeSelection('12H'), '12H');
    expect(WeeklyScheduleClassOptions.normalizeSelection('13A'), isNull);
  });
}
