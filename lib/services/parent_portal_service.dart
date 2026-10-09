import '../data/local/app_database.dart';
import '../models/student_enrollment.dart';
import 'secretary_document_service.dart';
import 'student_portal_service.dart';

/// Veli portalı veri erişimi — öğrenci ID'si her sorguda veli ilişkisiyle doğrulanır.
class ParentAccessDeniedException implements Exception {
  const ParentAccessDeniedException();
}

class ParentLinkedStudent {
  const ParentLinkedStudent({
    required this.studentId,
    required this.classId,
    required this.studentName,
    required this.className,
    required this.section,
    required this.number,
    required this.relationCode,
  });

  final int studentId;
  final int classId;
  final String studentName;
  final String className;
  final String? section;
  final int number;
  final String relationCode;

  String get displayClass {
    final s = section?.trim();
    if (s != null && s.isNotEmpty) return '$className-$s';
    return className;
  }

  StudentEnrollment toEnrollment() => StudentEnrollment(
    classId: classId,
    studentId: studentId,
    className: className,
    section: section,
    studentName: studentName,
    number: number,
  );

  static ParentLinkedStudent fromRow(Map<String, Object?> row) {
    return ParentLinkedStudent(
      studentId: row['ogrenci_id'] as int,
      classId:
          row['sinif_id'] as int? ??
          (throw StateError('parent_student_row_missing_class')),
      studentName: row['ad_soyad'] as String,
      className: row['sinif_ad'] as String,
      section: row['sinif_sube'] as String?,
      number: row['numara'] as int,
      relationCode: row['yakinlik'] as String? ?? '',
    );
  }
}

class ParentPortalService {
  ParentPortalService(this._db) : _studentPortal = StudentPortalService(_db);

  final AppDatabase _db;
  final StudentPortalService _studentPortal;

  Future<void> requireLinked({
    required int parentId,
    required int studentId,
  }) async {
    final ok = await _db.isStudentLinkedToParent(
      parentId: parentId,
      studentId: studentId,
    );
    if (!ok) throw const ParentAccessDeniedException();
  }

  Future<List<ParentLinkedStudent>> listLinkedStudents(int parentId) async {
    final rows = await _db.listStudentsForParent(parentId);
    return rows.map(ParentLinkedStudent.fromRow).toList();
  }

  Future<ParentLinkedStudent?> linkedStudent({
    required int parentId,
    required int studentId,
  }) async {
    await requireLinked(parentId: parentId, studentId: studentId);
    final rows = await _db.listStudentsForParent(parentId);
    for (final row in rows) {
      if (row['ogrenci_id'] == studentId) {
        return ParentLinkedStudent.fromRow(row);
      }
    }
    return null;
  }

  Future<Map<String, Object?>?> parentProfile(int parentId) async {
    return _db.getParentGuardianById(parentId);
  }

  Future<List<StudentPortalAnnouncement>> announcementsForStudent({
    required int parentId,
    required int studentId,
  }) async {
    final linked = await linkedStudent(
      parentId: parentId,
      studentId: studentId,
    );
    if (linked == null) return [];
    return _studentPortal.loadAnnouncements([linked.toEnrollment()]);
  }

  Future<List<SecretaryDocument>> documentsForStudent({
    required int parentId,
    required int studentId,
  }) async {
    final linked = await linkedStudent(
      parentId: parentId,
      studentId: studentId,
    );
    if (linked == null) return [];
    final rows = await _db.listSecretaryDocuments(archived: false);
    final out = <SecretaryDocument>[];
    for (final row in rows) {
      if (_documentVisibleToStudent(row, linked)) {
        out.add(SecretaryDocument.fromMap(row));
      }
    }
    return out;
  }

  Future<SecretaryDocument?> documentByIdForStudent({
    required int parentId,
    required int studentId,
    required int documentId,
  }) async {
    final docs = await documentsForStudent(
      parentId: parentId,
      studentId: studentId,
    );
    for (final d in docs) {
      if (d.id == documentId) return d;
    }
    return null;
  }

  bool _documentVisibleToStudent(
    Map<String, Object?> row,
    ParentLinkedStudent student,
  ) {
    final scope = (row['belge_kapsam'] as String?)?.trim();
    if (scope == null || scope.isEmpty) return true;
    final lower = scope.toLowerCase();
    if (lower.contains('tüm okul') || lower.contains('all school')) {
      return true;
    }
    if (scope.startsWith('sinif:')) {
      final id = int.tryParse(scope.substring(6).trim());
      return id != null && id == student.classId;
    }
    final label = student.displayClass.toLowerCase();
    if (lower.contains(label)) return true;
    if (lower.contains(student.className.toLowerCase())) return true;
    return false;
  }

  Future<List<Map<String, Object?>>> attendanceForStudent({
    required int parentId,
    required int studentId,
    String? fromDate,
    String? toDate,
  }) async {
    await requireLinked(parentId: parentId, studentId: studentId);
    return _db.listDailyAttendanceForStudent(
      studentId: studentId,
      fromDate: fromDate,
      toDate: toDate,
    );
  }

  Future<Map<String, int>> attendanceSummaryForStudent({
    required int parentId,
    required int studentId,
  }) async {
    await requireLinked(parentId: parentId, studentId: studentId);
    return _db.countStudentDailyAttendanceByStatus(studentId);
  }

  Future<List<Map<String, Object?>>> academicRowsForStudent({
    required int parentId,
    required int studentId,
  }) async {
    final linked = await linkedStudent(
      parentId: parentId,
      studentId: studentId,
    );
    if (linked == null) return [];
    return _studentPortal.loadPerformanceRows(linked.toEnrollment());
  }

  Future<ParentLinkedStudent> _requireLinkedEnrollment({
    required int parentId,
    required int studentId,
  }) async {
    final linked = await linkedStudent(
      parentId: parentId,
      studentId: studentId,
    );
    if (linked == null) throw const ParentAccessDeniedException();
    return linked;
  }

  Future<StudentDashboardSummary> dashboardSummaryForStudent({
    required int parentId,
    required int studentId,
  }) async {
    final linked = await _requireLinkedEnrollment(
      parentId: parentId,
      studentId: studentId,
    );
    return _studentPortal.loadDashboardSummary([linked.toEnrollment()]);
  }

  Future<List<StudentPortalTodayLesson>> todayLessonsForStudent({
    required int parentId,
    required int studentId,
  }) async {
    final linked = await _requireLinkedEnrollment(
      parentId: parentId,
      studentId: studentId,
    );
    return _studentPortal.loadTodayLessons([linked.toEnrollment()]);
  }

  Future<List<StudentPortalHomework>> pendingHomeworkForStudent({
    required int parentId,
    required int studentId,
  }) async {
    final linked = await _requireLinkedEnrollment(
      parentId: parentId,
      studentId: studentId,
    );
    return _studentPortal.loadHomework(
      enrollments: [linked.toEnrollment()],
      filter: 'pending',
    );
  }

  Future<List<StudentPortalExam>> examsForStudent({
    required int parentId,
    required int studentId,
  }) async {
    final linked = await _requireLinkedEnrollment(
      parentId: parentId,
      studentId: studentId,
    );
    return _studentPortal.loadExams([linked.toEnrollment()]);
  }
}
