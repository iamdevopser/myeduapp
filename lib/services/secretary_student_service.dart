import '../data/local/app_database.dart';
import '../utils/course_form_options.dart';
import '../utils/student_password_hash.dart';
import 'account_service.dart';

class SecretaryDashboardStats {
  const SecretaryDashboardStats({
    required this.studentCount,
    required this.classSectionCount,
    required this.today,
  });

  final int studentCount;
  final int classSectionCount;
  final DateTime today;
}

class SecretaryGradeSummary {
  const SecretaryGradeSummary({
    required this.grade,
    required this.sectionCount,
    required this.studentCount,
  });

  final int grade;
  final int sectionCount;
  final int studentCount;
}

class SecretaryClassValidationException implements Exception {
  SecretaryClassValidationException(this.messageKey);
  final String messageKey;
}

class SecretarySectionSummary {
  const SecretarySectionSummary({
    required this.classId,
    required this.gradeLabel,
    required this.section,
    required this.year,
    required this.studentCount,
  });

  final int classId;
  final String gradeLabel;
  final String section;
  final String year;
  final int studentCount;
}

/// Sekreter öğrenci/sınıf ekranları için veri erişimi.
class SecretaryStudentService {
  SecretaryStudentService(this._db);

  final AppDatabase _db;

  Future<SecretaryDashboardStats> loadDashboardStats() async {
    final classes = await _db.getStudentClasses();
    final studentCount = await _db.countAllStudents();
    return SecretaryDashboardStats(
      studentCount: studentCount,
      classSectionCount: classes.length,
      today: DateTime.now(),
    );
  }

  Future<List<Map<String, Object?>>> listStudents() =>
      _db.listStudentsWithClass();

  Future<List<Map<String, Object?>>> listStudentClasses() =>
      _db.getStudentClasses();

  Future<List<SecretaryGradeSummary>> listGradeSummaries() async {
    final classes = await _db.getStudentClasses();
    final counts = <int, ({int sections, int students})>{};
    for (final row in classes) {
      final grade = CourseFormOptions.resolveGrade(row['ad'] as String?);
      final classId = row['id'] as int;
      final studentCount = await _db.getStudentCount(classId);
      final bucket = counts[grade] ?? (sections: 0, students: 0);
      counts[grade] = (
        sections: bucket.sections + 1,
        students: bucket.students + studentCount,
      );
    }
    return counts.entries
        .map(
          (e) => SecretaryGradeSummary(
            grade: e.key,
            sectionCount: e.value.sections,
            studentCount: e.value.students,
          ),
        )
        .toList()
      ..sort((a, b) => a.grade.compareTo(b.grade));
  }

  Future<List<SecretarySectionSummary>> listSectionSummaries() async {
    final classes = await _db.getStudentClasses();
    final result = <SecretarySectionSummary>[];
    for (final row in classes) {
      final classId = row['id'] as int;
      final name = row['ad'] as String? ?? '';
      final section = CourseFormOptions.resolveSection(row['sube'] as String?);
      final year = row['yil'] as String? ?? '';
      final grade = CourseFormOptions.parseGradeFromName(name);
      final gradeLabel = grade != null
          ? CourseFormOptions.gradeLabel(grade)
          : name;
      final studentCount = await _db.getStudentCount(classId);
      result.add(
        SecretarySectionSummary(
          classId: classId,
          gradeLabel: gradeLabel,
          section: section,
          year: year,
          studentCount: studentCount,
        ),
      );
    }
    return result;
  }

  /// Yeni sınıf şubesi (`ogrenci_siniflar`); aynı yıl + seviye + şube tekrarlanamaz.
  Future<int> createClassSection({
    required int grade,
    required String section,
    required String year,
  }) async {
    final resolvedYear = CourseFormOptions.resolveAcademicYear(year);
    final resolvedSection = CourseFormOptions.resolveSection(section);
    final classes = await _db.getStudentClasses();
    final duplicate = classes.any((row) {
      final rowGrade = CourseFormOptions.resolveGrade(row['ad'] as String?);
      final rowSection = CourseFormOptions.resolveSection(
        row['sube'] as String?,
      );
      final rowYear = CourseFormOptions.resolveAcademicYear(
        row['yil'] as String?,
      );
      return rowGrade == grade &&
          rowSection == resolvedSection &&
          rowYear == resolvedYear;
    });
    if (duplicate) {
      throw SecretaryClassValidationException('secretaryClassSectionExists');
    }
    return _db.insertStudentClass(
      CourseFormOptions.gradeLabel(grade),
      resolvedYear,
      section: resolvedSection,
    );
  }

  Future<int> createStudent({
    required int classId,
    required String name,
    int? number,
    String? email,
    String? motherEmail,
    String? fatherEmail,
    required String passwordPlain,
  }) async {
    final resolvedNumber = number ?? await _db.getNextStudentNumber(classId);
    final passwordHash = StudentPasswordHash.hash(passwordPlain);
    return _db.insertStudent(
      classId: classId,
      number: resolvedNumber,
      name: name,
      email: email,
      motherEmail: motherEmail,
      fatherEmail: fatherEmail,
      passwordHash: passwordHash,
    );
  }

  /// Öğrenci kaydından önce çağrılır; kullanıcı adı alınmışsa öğrenci yarım
  /// kaydedilmesin diye [AccountValidationException] fırlatır.
  Future<void> validateStudentPortalAccount({
    String? portalUsername,
    String? email,
  }) async {
    final username = portalUsername?.trim() ?? '';
    if (username.isEmpty) return;
    await AccountService(
      _db,
      actorAccountId: 0,
    ).ensureCredentialsAvailable(username: username, email: email);
  }

  /// İsteğe bağlı portal kullanıcı adı ile `hesaplar` kaydı (numara+şifre girişi ayrıca geçerli).
  Future<void> createStudentPortalAccountIfNeeded({
    required int studentId,
    required String name,
    required String passwordPlain,
    String? portalUsername,
    String? email,
    int? actorAdminAccountId,
  }) async {
    final username = portalUsername?.trim() ?? '';
    if (username.isEmpty) return;
    await AccountService(
      _db,
      actorAccountId: actorAdminAccountId ?? 0,
    ).createStudentPortalAccount(
      studentId: studentId,
      username: username,
      fullName: name,
      passwordPlain: passwordPlain,
      email: email,
      actorAccountId: actorAdminAccountId,
    );
  }

  Future<void> updateStudentProfile({
    required int studentId,
    required int number,
    required String name,
    String? email,
    String? motherEmail,
    String? fatherEmail,
    int? classId,
  }) {
    return _db.updateStudent(
      studentId: studentId,
      number: number,
      name: name,
      email: email,
      motherEmail: motherEmail,
      fatherEmail: fatherEmail,
      classId: classId,
    );
  }
}
