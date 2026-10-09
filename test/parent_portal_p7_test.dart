import 'package:flutter_test/flutter_test.dart';
import 'package:my_edu_app/data/local/app_database.dart';
import 'package:my_edu_app/data/models/parent_guardian_model.dart';
import 'package:my_edu_app/services/parent_portal_service.dart';
import 'package:my_edu_app/services/secretary_parent_service.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;

  late AppDatabase db;
  late ParentPortalService portal;
  late SecretaryParentService parents;

  setUp(() async {
    db = AppDatabase('p7_${DateTime.now().microsecondsSinceEpoch}.sqlite');
    await db.open();
    portal = ParentPortalService(db);
    parents = SecretaryParentService(db);
  });

  tearDown(() async {
    await db.close();
  });

  Future<(int parentId, int studentId)> seed() async {
    final classId = await db.insertStudentClass('7', '2025', section: 'A');
    final studentId = await db.insertStudent(
      classId: classId,
      number: 5,
      name: 'Child P7',
    );
    final parentId = await parents.createParent(
      fullName: 'Parent P7',
      email: 'p7@school.test',
    );
    await parents.linkToStudent(
      studentId: studentId,
      parentId: parentId,
      relation: ParentRelationType.anne,
    );
    return (parentId, studentId);
  }

  test('dashboardSummaryForStudent requires link', () async {
    final (parentId, studentId) = await seed();
    final summary = await portal.dashboardSummaryForStudent(
      parentId: parentId,
      studentId: studentId,
    );
    expect(summary.courseCount, greaterThanOrEqualTo(0));

    final (_, otherId) = await seed();
    expect(
      () => portal.dashboardSummaryForStudent(
        parentId: parentId,
        studentId: otherId,
      ),
      throwsA(isA<ParentAccessDeniedException>()),
    );
  });

  test('todayLessonsForStudent rejects foreign student', () async {
    final (parentId, _) = await seed();
    final (_, otherId) = await seed();
    expect(
      () => portal.todayLessonsForStudent(
        parentId: parentId,
        studentId: otherId,
      ),
      throwsA(isA<ParentAccessDeniedException>()),
    );
  });
}
