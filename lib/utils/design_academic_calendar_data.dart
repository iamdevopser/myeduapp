import 'package:flutter/material.dart';

import '../data/local/app_database.dart';
import '../screens/academic_plans/weekly_schedule_grid.dart';
import '../widgets/design/design_academic_calendar_view.dart';

/// Haftalık program verisini tasarım 06 takvim görünümüne dönüştürür.
class DesignAcademicCalendarData {
  DesignAcademicCalendarData({
    required this.dayLessons,
    required this.periodTimes,
  });

  final Map<int, List<DesignCalendarLesson>> dayLessons;
  final Map<int, ({String start, String end})> periodTimes;

  static const _accents = [
    Color(0xFF3B82F6),
    Color(0xFFF59E0B),
    Color(0xFFEC4899),
    Color(0xFF22C55E),
    Color(0xFF8B5CF6),
  ];

  static Future<DesignAcademicCalendarData> load(
    AppDatabase db, {
    Set<int>? allowedClassIds,
  }) async {
    final slots = await db.getWeeklySchedulePeriodSlots();
    final periodTimes = <int, ({String start, String end})>{};
    for (var i = 0; i < slots.length; i++) {
      periodTimes[i + 1] = (start: slots[i].start, end: slots[i].end);
    }

    var entries = await db.getWeeklyScheduleEntries();
    if (allowedClassIds != null && allowedClassIds.isNotEmpty) {
      entries = entries
          .where((e) {
            final id = e['ogrenci_sinif_id'] as int?;
            return id != null && allowedClassIds.contains(id);
          })
          .toList();
    }

    final grid = buildWeeklyScheduleGrid(entries);
    final dayLessons = <int, List<DesignCalendarLesson>>{};
    var colorIndex = 0;

    for (final cell in grid) {
      if (cell.isEmpty) continue;
      final list = dayLessons.putIfAbsent(cell.dayOfWeek, () => []);
      list.add(
        DesignCalendarLesson(
          title: cell.classLabel,
          subtitle: '',
          period: cell.period,
          accent: _accents[colorIndex % _accents.length],
        ),
      );
      colorIndex++;
    }

    for (final list in dayLessons.values) {
      list.sort((a, b) => a.period.compareTo(b.period));
    }

    return DesignAcademicCalendarData(
      dayLessons: dayLessons,
      periodTimes: periodTimes,
    );
  }
}
