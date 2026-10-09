import 'package:flutter_test/flutter_test.dart';
import 'package:my_edu_app/data/local/app_database.dart';
import 'package:my_edu_app/models/app_role.dart';
import 'package:my_edu_app/providers/app_state.dart';
import 'package:my_edu_app/services/authorization_service.dart';
import 'package:my_edu_app/services/secretary_student_service.dart';
import 'package:my_edu_app/utils/course_form_options.dart';
import 'package:my_edu_app/utils/secretary_navigation.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;

  late AppDatabase db;
  late AppState state;

  setUp(() async {
    db = AppDatabase('sec2_${DateTime.now().microsecondsSinceEpoch}.sqlite');
    await db.open();
    state = await AppState.createWithDatabase(db);
    state.setUnlocked(true, role: AppRole.secretary);
    await state.refreshUnreadNotifications();
  });

  tearDown(() async {
    await db.close();
  });

  group('AuthorizationService', () {
    test('secretary can view and edit students but not delete', () {
      final auth = AuthorizationService(state);
      expect(auth.canViewStudents, isTrue);
      expect(auth.canCreateStudent, isTrue);
      expect(auth.canEditStudent, isTrue);
      expect(auth.canDeleteStudent, isFalse);
      expect(auth.canAccessTeacherWorkspace, isFalse);
    });

    test('teacher can delete students', () async {
      state.setUnlocked(true, role: AppRole.teacher);
      await state.refreshUnreadNotifications();
      final auth = AuthorizationService(state);
      expect(auth.canDeleteStudent, isTrue);
      expect(auth.canAccessTeacherWorkspace, isTrue);
    });
  });

  group('SecretaryStudentService', () {
    test('create and list students', () async {
      final db = state.db;
      final classId = await db.insertStudentClass(
        CourseFormOptions.gradeLabel(7),
        CourseFormOptions.academicYearOptions().first,
        section: 'A',
      );
      final service = SecretaryStudentService(db);
      await service.createStudent(
        classId: classId,
        name: 'Ayşe Test',
        passwordPlain: 'ogrenci',
      );
      final rows = await service.listStudents();
      expect(rows.any((r) => r['ad_soyad'] == 'Ayşe Test'), isTrue);
      final stats = await service.loadDashboardStats();
      expect(stats.studentCount, greaterThanOrEqualTo(1));
    });

    test('create class section and reject duplicate', () async {
      final db = AppDatabase('sec2_${DateTime.now().microsecondsSinceEpoch}.sqlite');
      await db.open();
      final service = SecretaryStudentService(db);
      final year = CourseFormOptions.academicYearOptions().first;
      final id = await service.createClassSection(
        grade: 12,
        section: 'H',
        year: year,
      );
      expect(id, greaterThan(0));
      expect(
        () => service.createClassSection(
          grade: 12,
          section: 'H',
          year: year,
        ),
        throwsA(isA<SecretaryClassValidationException>()),
      );
      final sections = await service.listSectionSummaries();
      expect(
        sections.any((s) => s.classId == id && s.section == 'H'),
        isTrue,
      );
      await db.close();
    });
  });

  group('Secretary navigation', () {
    test('openSecretarySection updates active section', () {
      state.openSecretarySection(SecretaryNavSection.studentList);
      expect(
        state.activeSecretarySection,
        SecretaryNavSection.studentsParents,
      );
      state.openSecretarySection(SecretaryNavSection.studentAdd);
      expect(
        state.activeSecretarySection,
        SecretaryNavSection.studentsParents,
      );
      state.openSecretarySection(SecretaryNavSection.classes);
      expect(
        state.activeSecretarySection,
        SecretaryNavSection.classesSections,
      );
      state.openSecretarySection(SecretaryNavSection.sections);
      expect(
        state.activeSecretarySection,
        SecretaryNavSection.classesSections,
      );
    });
  });
}
