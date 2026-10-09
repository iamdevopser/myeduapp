import 'package:flutter_test/flutter_test.dart';
import 'package:my_edu_app/data/local/app_database.dart';
import 'package:my_edu_app/data/models/parent_guardian_model.dart';
import 'package:my_edu_app/models/app_role.dart';
import 'package:my_edu_app/providers/app_state.dart';
import 'package:my_edu_app/services/authorization_service.dart';
import 'package:my_edu_app/services/secretary_parent_service.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;

  late AppDatabase db;
  late SecretaryParentService service;

  setUp(() async {
    db = AppDatabase('faz3_${DateTime.now().microsecondsSinceEpoch}.sqlite');
    await db.open();
    service = SecretaryParentService(db);
  });

  tearDown(() async {
    await db.close();
  });

  test('schema version 28 includes veliler tables', () async {
    final v = await db.database.rawQuery('PRAGMA user_version');
    expect(v.first['user_version'], 35);
    final tables = await db.database.rawQuery(
      "SELECT name FROM sqlite_master WHERE type='table' AND name IN ('veliler','ogrenci_veliler')",
    );
    expect(tables.length, 2);
  });

  test('create update list parent', () async {
    final id = await service.createParent(
      fullName: 'Ayşe Veli',
      phone: '555',
      email: 'ayse@ornek.com',
    );
    await service.updateParent(
      id: id,
      fullName: 'Ayşe Veli Güncel',
      phone: '556',
      email: 'ayse@ornek.com',
    );
    final list = await service.listParents(search: 'Ayşe');
    expect(list.any((p) => p.id == id), isTrue);
    expect(list.first.fullName, 'Ayşe Veli Güncel');
  });

  test('student parent link both directions', () async {
    final classId = await db.insertStudentClass('7', '2025', section: 'A');
    final studentId = await db.insertStudent(
      classId: classId,
      number: 1,
      name: 'Sofia Test',
    );
    final parentId = await service.createParent(fullName: 'Mehmet Veli');
    await service.linkToStudent(
      studentId: studentId,
      parentId: parentId,
      relation: ParentRelationType.baba,
    );
    final forStudent = await service.parentsForStudent(studentId);
    expect(forStudent.length, 1);
    expect(forStudent.first.relation, ParentRelationType.baba);

    final forParent = await service.studentsForParent(parentId);
    expect(forParent.length, 1);
    expect(forParent.first.studentName, 'Sofia Test');
  });

  test('unlink and delete blocked with links', () async {
    final classId = await db.insertStudentClass('8', '2025', section: 'B');
    final studentId = await db.insertStudent(
      classId: classId,
      number: 2,
      name: 'Ali',
    );
    final parentId = await service.createParent(fullName: 'Anne');
    final linkId = await service.linkToStudent(
      studentId: studentId,
      parentId: parentId,
      relation: ParentRelationType.anne,
    );
    expect(await service.tryDeleteParent(parentId), isFalse);
    await service.unlink(linkId);
    expect(await service.tryDeleteParent(parentId), isTrue);
  });

  test('migration preserves anne_email on ogrenciler', () async {
    final classId = await db.insertStudentClass('5', '2025', section: 'C');
    await db.insertStudent(
      classId: classId,
      number: 3,
      name: 'Ece',
      motherEmail: 'anne@test.com',
      fatherEmail: 'baba@test.com',
    );
    final row = await db.getStudentById(
      (await db.getStudents(classId)).first['id'] as int,
    );
    expect(row?['anne_email'], 'anne@test.com');
    expect(row?['baba_email'], 'baba@test.com');
  });

  test('secretary authorization for parents', () async {
    final state = await AppState.create();
    state.setUnlocked(true, role: AppRole.secretary);
    final auth = AuthorizationService(state);
    expect(auth.canViewParents, isTrue);
    expect(auth.canCreateParent, isTrue);
    expect(auth.canManageStudentParentRelation, isTrue);
    expect(auth.canDeleteParent, isFalse);
  });
}
