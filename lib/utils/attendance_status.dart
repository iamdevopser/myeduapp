/// Günlük okul devamsızlık durumları (sekreter modülü).
enum AttendanceStatus {
  present,
  absent,
  excused,
}

extension AttendanceStatusDb on AttendanceStatus {
  String get dbValue => switch (this) {
        AttendanceStatus.present => 'var',
        AttendanceStatus.absent => 'yok',
        AttendanceStatus.excused => 'izinli',
      };

  static AttendanceStatus fromDb(String? value) {
    switch (value) {
      case 'yok':
        return AttendanceStatus.absent;
      case 'izinli':
        return AttendanceStatus.excused;
      case 'var':
      default:
        return AttendanceStatus.present;
    }
  }
}

String attendanceDateKey(DateTime date) {
  final y = date.year;
  final m = date.month.toString().padLeft(2, '0');
  final d = date.day.toString().padLeft(2, '0');
  return '$y-$m-$d';
}

DateTime? parseAttendanceDateKey(String? key) {
  if (key == null || key.length < 10) return null;
  final parts = key.split('-');
  if (parts.length != 3) return null;
  final y = int.tryParse(parts[0]);
  final m = int.tryParse(parts[1]);
  final d = int.tryParse(parts[2]);
  if (y == null || m == null || d == null) return null;
  return DateTime(y, m, d);
}
