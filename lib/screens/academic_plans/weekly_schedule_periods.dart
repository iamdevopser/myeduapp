/// Default lesson period count and clock ranges for the weekly grid.
abstract final class WeeklySchedulePeriods {
  static const int count = 8;

  static const List<({String start, String end})> defaultSlots = [
    (start: '08:00', end: '08:45'),
    (start: '08:50', end: '09:35'),
    (start: '09:40', end: '10:25'),
    (start: '10:30', end: '11:15'),
    (start: '11:20', end: '12:05'),
    (start: '13:00', end: '13:45'),
    (start: '13:50', end: '14:35'),
    (start: '14:40', end: '15:25'),
  ];

  static ({String start, String end}) timesForPeriod(
    int period, [
    List<({String start, String end})>? slots,
  ]) {
    final list = slots ?? defaultSlots;
    final index = period.clamp(1, count) - 1;
    if (index < 0 || index >= list.length) {
      return defaultSlots[index.clamp(0, defaultSlots.length - 1)];
    }
    return list[index];
  }
}
