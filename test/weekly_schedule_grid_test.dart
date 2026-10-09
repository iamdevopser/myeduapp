import 'package:flutter_test/flutter_test.dart';
import 'package:my_edu_app/screens/academic_plans/weekly_schedule_grid.dart';

void main() {
  test('buildWeeklyScheduleGrid maps day and period to class label', () {
    final entries = [
      {
        'id': 1,
        'gun': 1,
        'saat_sira': 2,
        'ogrenci_sinif_ad': '8',
        'ogrenci_sube': 'B',
        'sinif_metin': '',
      },
      {
        'id': 2,
        'gun': 5,
        'saat_sira': 8,
        'sinif_metin': '9D',
      },
    ];
    final grid = buildWeeklyScheduleGrid(entries);
    final mondaySecond = findWeeklyScheduleCell(grid, 1, 2)!;
    expect(mondaySecond.classLabel, '8 B');
    expect(mondaySecond.entryId, 1);

    final fridayLast = findWeeklyScheduleCell(grid, 5, 8)!;
    expect(fridayLast.classLabel, '9D');
  });

  test('buildWeeklyScheduleGrid fills empty cells', () {
    final grid = buildWeeklyScheduleGrid([]);
    expect(grid.length, 40);
    expect(grid.every((c) => c.isEmpty), isTrue);
  });
}
