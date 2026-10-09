import 'package:flutter_test/flutter_test.dart';
import 'package:my_edu_app/data/local/app_database.dart';
import 'package:my_edu_app/models/student_enrollment.dart';
import 'package:my_edu_app/services/student_portal_service.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  sqfliteFfiInit();

  late AppDatabase db;
  late StudentPortalService service;

  setUp(() async {
    databaseFactory = databaseFactoryFfi;
    db = AppDatabase(
      'student_portal_${DateTime.now().microsecondsSinceEpoch}.sqlite',
    );
    await db.open();
    service = StudentPortalService(db);
  });

  tearDown(() async {
    await db.close();
  });

  test('enrollmentsForIdentity links same name+number across classes', () async {
    final classA = await db.insertStudentClass('8', '2025-2026', section: 'A');
    final classB = await db.insertStudentClass('8', '2025-2026', section: 'B');
    final idA = await db.insertStudent(
      classId: classA,
      number: 12,
      name: 'Ali Veli',
    );
    await db.insertStudent(
      classId: classB,
      number: 12,
      name: 'Ali Veli',
    );

    final all = await service.listAllEnrollments();
    final primary = all.firstWhere((e) => e.studentId == idA);
    final linked = await service.enrollmentsForIdentity(primary);

    expect(linked.length, 2);
    expect(linked.map((e) => e.classId).toSet(), {classA, classB});
  });

  test('homework load only includes session enrollments', () async {
    final classId = await db.insertStudentClass('7', '2025-2026', section: 'C');
    final otherClass =
        await db.insertStudentClass('7', '2025-2026', section: 'D');
    final studentId = await db.insertStudent(
      classId: classId,
      number: 3,
      name: 'Zeynep',
    );
    await db.insertStudent(
      classId: otherClass,
      number: 99,
      name: 'Other',
    );
    final colId = await db.insertScoreColumn(
      classId: classId,
      name: 'Ödev 1',
      type: 'homework',
    );
    await db.insertScoreColumn(
      classId: otherClass,
      name: 'Başka ödev',
      type: 'homework',
    );

    final enr = StudentEnrollment(
      classId: classId,
      studentId: studentId,
      className: '7',
      section: 'C',
      studentName: 'Zeynep',
      number: 3,
    );

    final items = await service.loadHomework(enrollments: [enr]);
    expect(items.length, 1);
    expect(items.first.title, 'Ödev 1');
    expect(items.first.enrollment.studentId, studentId);
  });

  test('announcements respect class scope', () async {
    final classA = await db.insertStudentClass('7', '2025-2026', section: 'A');
    final classB = await db.insertStudentClass('7', '2025-2026', section: 'B');
    await db.insertStudentAnnouncement(
      title: 'Sadece A',
      body: 'Mesaj',
      classId: classA,
    );
    await db.insertStudentAnnouncement(
      title: 'Genel',
      body: 'Herkes',
    );
    final enr = StudentEnrollment(
      classId: classB,
      studentId: 1,
      className: '7',
      section: 'B',
      studentName: 'X',
      number: 1,
    );
    final items = await service.loadAnnouncements([enr]);
    expect(items.any((a) => a.title == 'Sadece A'), isFalse);
    expect(items.any((a) => a.title == 'Genel'), isTrue);
  });

  test('ogrenciye_goster column exists after open', () async {
    final classId = await db.insertStudentClass('6', '2025-2026', section: 'A');
    final studentId = await db.insertStudent(
      classId: classId,
      number: 1,
      name: 'Test',
    );
    final defs = await db.getBehaviorDefinitions();
    final behaviorId = defs.first['id'] as int;
    await db.setStudentBehaviorChecked(
      classId: classId,
      studentId: studentId,
      behaviorId: behaviorId,
      date: '2026-10-01',
      checked: true,
    );
    final rows = await db.getStudentBehaviorReportRows(
      classId: classId,
      studentId: studentId,
    );
    expect(rows, isNotEmpty);
    expect(rows.first.containsKey('ogrenciye_goster'), isTrue);
  });
}
