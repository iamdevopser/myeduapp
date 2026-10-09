import 'academic_plan_labels.dart';

/// One cell in the Mon–Fri × 8-period grid.
class WeeklyScheduleGridCell {
  const WeeklyScheduleGridCell({
    required this.dayOfWeek,
    required this.period,
    this.entryId,
    this.studentClassId,
    this.classLabel = '',
  });

  final int dayOfWeek;
  final int period;
  final int? entryId;
  final int? studentClassId;
  final String classLabel;

  bool get isEmpty => classLabel.trim().isEmpty;
}

/// Maps [akademik_haftalik_ders] rows to a fixed 5×8 grid (class labels only).
List<WeeklyScheduleGridCell> buildWeeklyScheduleGrid(
  List<Map<String, Object?>> entries, {
  int periodCount = 8,
  int dayCount = 5,
}) {
  final byKey = <String, Map<String, Object?>>{};
  for (final row in entries) {
    final day = row['gun'] as int?;
    final period = row['saat_sira'] as int? ?? _legacyPeriod(row, entries);
    if (day == null || day < 1 || day > dayCount) continue;
    if (period < 1 || period > periodCount) continue;
    byKey['$day-$period'] = row;
  }

  final cells = <WeeklyScheduleGridCell>[];
  for (var day = 1; day <= dayCount; day++) {
    for (var period = 1; period <= periodCount; period++) {
      final row = byKey['$day-$period'];
      cells.add(
        WeeklyScheduleGridCell(
          dayOfWeek: day,
          period: period,
          entryId: row?['id'] as int?,
          studentClassId: row?['ogrenci_sinif_id'] as int?,
          classLabel: row == null ? '' : academicPlanClassLabel(row),
        ),
      );
    }
  }
  return cells;
}

int _legacyPeriod(Map<String, Object?> row, List<Map<String, Object?>> all) {
  final day = row['gun'] as int?;
  if (day == null) return 1;
  final sameDay = all
      .where((e) => e['gun'] == day)
      .toList()
    ..sort(
      (a, b) => (a['baslangic'] as String? ?? '')
          .compareTo(b['baslangic'] as String? ?? ''),
    );
  final index = sameDay.indexWhere((e) => e['id'] == row['id']);
  return index < 0 ? 1 : index + 1;
}

WeeklyScheduleGridCell? findWeeklyScheduleCell(
  List<WeeklyScheduleGridCell> grid,
  int dayOfWeek,
  int period,
) {
  for (final cell in grid) {
    if (cell.dayOfWeek == dayOfWeek && cell.period == period) {
      return cell;
    }
  }
  return null;
}
