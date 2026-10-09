import '../data/local/app_database.dart';
import '../utils/attendance_status.dart';
import '../utils/course_form_options.dart';

class SecretaryAttendanceStudentRow {
  const SecretaryAttendanceStudentRow({
    required this.studentId,
    required this.number,
    required this.name,
    required this.classId,
    required this.gradeLabel,
    required this.section,
    required this.status,
  });

  final int studentId;
  final int number;
  final String name;
  final int classId;
  final String gradeLabel;
  final String section;
  final AttendanceStatus status;
}

class SecretaryAttendanceHistoryRow {
  const SecretaryAttendanceHistoryRow({
    required this.id,
    required this.studentId,
    required this.date,
    required this.status,
    required this.studentName,
    required this.number,
    required this.gradeLabel,
    required this.section,
  });

  final int id;
  final int studentId;
  final String date;
  final AttendanceStatus status;
  final String studentName;
  final int number;
  final String gradeLabel;
  final String section;
}

class StudentAttendanceSummary {
  const StudentAttendanceSummary({
    required this.absentCount,
    required this.excusedCount,
  });

  final int absentCount;
  final int excusedCount;
}

class SecretaryAttendanceService {
  SecretaryAttendanceService(this._db);

  final AppDatabase _db;

  Future<List<SecretaryAttendanceStudentRow>> loadDaily({
    required DateTime date,
    int? gradeFilter,
    String? sectionFilter,
    int? classIdFilter,
  }) async {
    final dateKey = attendanceDateKey(date);
    final students = await _db.listStudentsWithClass();
    final filtered = students.where((row) {
      final classId = row['sinif_id'] as int;
      if (classIdFilter != null && classId != classIdFilter) return false;
      final className = row['sinif_ad'] as String? ?? '';
      final grade = CourseFormOptions.resolveGrade(className);
      final section = CourseFormOptions.resolveSection(
        row['sinif_sube'] as String?,
      );
      if (gradeFilter != null && grade != gradeFilter) return false;
      if (sectionFilter != null &&
          sectionFilter.isNotEmpty &&
          section != sectionFilter) {
        return false;
      }
      return true;
    }).toList();

    final ids = filtered.map((r) => r['id'] as int).toList();
    final statusMap = await _db.getDailyAttendanceStatusMap(
      dateKey: dateKey,
      studentIds: ids,
    );

    return filtered.map((row) {
      final studentId = row['id'] as int;
      final className = row['sinif_ad'] as String? ?? '';
      final grade = CourseFormOptions.resolveGrade(className);
      return SecretaryAttendanceStudentRow(
        studentId: studentId,
        number: row['numara'] as int,
        name: row['ad_soyad'] as String,
        classId: row['sinif_id'] as int,
        gradeLabel: CourseFormOptions.gradeLabel(grade),
        section: CourseFormOptions.resolveSection(row['sinif_sube'] as String?),
        status: AttendanceStatusDb.fromDb(statusMap[studentId]),
      );
    }).toList();
  }

  Future<void> setStudentStatus({
    required int studentId,
    required DateTime date,
    required AttendanceStatus status,
  }) {
    return _db.setStudentDailyAttendance(
      studentId: studentId,
      dateKey: attendanceDateKey(date),
      status: status.dbValue,
    );
  }

  Future<void> bulkSetStatus({
    required List<int> studentIds,
    required DateTime date,
    required AttendanceStatus status,
  }) {
    return _db.bulkSetStudentDailyAttendance(
      studentIds: studentIds,
      dateKey: attendanceDateKey(date),
      status: status.dbValue,
    );
  }

  Future<List<SecretaryAttendanceHistoryRow>> loadHistory({
    required DateTime from,
    required DateTime to,
    int? gradeFilter,
    String? sectionFilter,
    int? studentIdFilter,
  }) async {
    final rows = await _db.listDailyAttendanceHistory(
      fromDate: attendanceDateKey(from),
      toDate: attendanceDateKey(to),
      studentId: studentIdFilter,
    );
    final mapped = rows.map((row) {
      final className = row['sinif_ad'] as String? ?? '';
      final grade = CourseFormOptions.resolveGrade(className);
      return SecretaryAttendanceHistoryRow(
        id: row['id'] as int,
        studentId: row['ogrenci_id'] as int,
        date: row['tarih'] as String,
        status: AttendanceStatusDb.fromDb(row['durum'] as String?),
        studentName: row['ad_soyad'] as String,
        number: row['numara'] as int,
        gradeLabel: CourseFormOptions.gradeLabel(grade),
        section: CourseFormOptions.resolveSection(row['sinif_sube'] as String?),
      );
    }).toList();
    return mapped.where((row) {
      if (gradeFilter != null) {
        final g = CourseFormOptions.parseGradeFromName(row.gradeLabel);
        if (g != gradeFilter) return false;
      }
      if (sectionFilter != null &&
          sectionFilter.isNotEmpty &&
          row.section != sectionFilter) {
        return false;
      }
      return true;
    }).toList();
  }

  Future<List<SecretaryAttendanceHistoryRow>> studentHistory({
    required int studentId,
    DateTime? from,
    DateTime? to,
  }) async {
    final rows = await _db.listDailyAttendanceForStudent(
      studentId: studentId,
      fromDate: from != null ? attendanceDateKey(from) : null,
      toDate: to != null ? attendanceDateKey(to) : null,
    );
    final student = await _db.getStudentById(studentId);
    final sinifId = student?['sinif_id'] as int?;
    final classRow = sinifId != null
        ? await _db.getStudentClassById(sinifId)
        : null;
    final className = classRow?['ad'] as String? ?? '';
    final grade = CourseFormOptions.resolveGrade(className);
    final gradeLabel = CourseFormOptions.gradeLabel(grade);
    final section = CourseFormOptions.resolveSection(
      classRow?['sube'] as String?,
    );
    final name = student?['ad_soyad'] as String? ?? '';
    final number = student?['numara'] as int? ?? 0;

    return rows
        .map(
          (row) => SecretaryAttendanceHistoryRow(
            id: row['id'] as int,
            studentId: studentId,
            date: row['tarih'] as String,
            status: AttendanceStatusDb.fromDb(row['durum'] as String?),
            studentName: name,
            number: number,
            gradeLabel: gradeLabel,
            section: section,
          ),
        )
        .toList();
  }

  Future<StudentAttendanceSummary> studentSummary(int studentId) async {
    final counts = await _db.countStudentDailyAttendanceByStatus(studentId);
    return StudentAttendanceSummary(
      absentCount: counts['yok'] ?? 0,
      excusedCount: counts['izinli'] ?? 0,
    );
  }
}
