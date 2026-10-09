import 'package:flutter_test/flutter_test.dart';
import 'package:my_edu_app/data/local/app_database.dart';
import 'package:my_edu_app/data/models/parent_guardian_model.dart';
import 'package:my_edu_app/models/app_role.dart';
import 'package:my_edu_app/providers/app_state.dart';
import 'package:my_edu_app/services/account_service.dart';
import 'package:my_edu_app/services/parent_portal_service.dart';
import 'package:my_edu_app/services/secretary_parent_service.dart';
import 'package:my_edu_app/services/secretary_student_service.dart';
import 'package:my_edu_app/utils/student_password_hash.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;

  late AppDatabase db;

  setUp(() async {
    db = AppDatabase('faz10_${DateTime.now().microsecondsSinceEpoch}.sqlite');
    await db.open();
  });

  tearDown(() async {
    await db.close();
  });

  Future<int> seedStudent({int number = 42}) async {
    final classId = await db.insertStudentClass('7', '2025', section: 'A');
    return db.insertStudent(
      classId: classId,
      number: number,
      name: 'Student $number',
      passwordHash: StudentPasswordHash.hash('pass-$number'),
    );
  }

  test('secretary creates student and optional portal account', () async {
    final classId = await db.insertStudentClass('7', '2025', section: 'B');
    final studentService = SecretaryStudentService(db);
    final studentId = await studentService.createStudent(
      classId: classId,
      name: 'New Student',
      number: 99,
      passwordPlain: 'portal-pass-9',
    );
    await studentService.createStudentPortalAccountIfNeeded(
      studentId: studentId,
      name: 'New Student',
      passwordPlain: 'portal-pass-9',
      portalUsername: 'stu99',
    );
    final acc = await db.getAccountForDomain(
      domainType: AccountService.domainStudent,
      domainId: studentId,
    );
    expect(acc, isNotNull);
    expect(acc!['kullanici_adi'], 'stu99');
  });

  test('secretary creates parent link and portal account by username', () async {
    final studentId = await seedStudent();
    final parentService = SecretaryParentService(db);
    final parentId = await parentService.createParent(
      fullName: 'Portal Parent',
      email: 'portal.parent@school.test',
    );
    await parentService.linkToStudent(
      studentId: studentId,
      parentId: parentId,
      relation: ParentRelationType.anne,
    );
    await AccountService(db, actorAccountId: 0).createParentPortalAccount(
      parentId: parentId,
      username: 'parent.portal',
      fullName: 'Portal Parent',
      passwordPlain: 'par-portal-9',
      email: 'portal.parent@school.test',
    );

    final state = await AppState.createWithDatabase(db);
    final byEmail = await state.loginParent(
      email: 'portal.parent@school.test',
      password: 'par-portal-9',
    );
    expect(byEmail.success, isTrue);
    expect(byEmail.parentId, parentId);

    final byUsername = await state.loginParent(
      email: 'parent.portal',
      password: 'par-portal-9',
    );
    expect(byUsername.success, isTrue);
    expect(byUsername.parentId, parentId);
  });

  test('inactive parent portal account cannot login', () async {
    final adminId = await AccountService(db, actorAccountId: 0)
        .createBootstrapAdmin(
      username: 'admin.inactive.parent',
      fullName: 'Admin',
      passwordPlain: 'Admin-pass-10',
    );
    final studentId = await seedStudent(number: 43);
    final parentService = SecretaryParentService(db);
    final parentId = await parentService.createParent(
      fullName: 'Inactive Parent',
      email: 'inactive@school.test',
    );
    await parentService.linkToStudent(
      studentId: studentId,
      parentId: parentId,
      relation: ParentRelationType.baba,
    );
    final accId = await AccountService(db, actorAccountId: 0)
        .createParentPortalAccount(
      parentId: parentId,
      username: 'inactive.parent',
      fullName: 'Inactive Parent',
      passwordPlain: 'inactive-pass-9',
      email: 'inactive@school.test',
    );
    await AccountService(db, actorAccountId: adminId).setActive(
      accountId: accId,
      active: false,
    );

    final state = await AppState.createWithDatabase(db);
    final login = await state.loginParent(
      email: 'inactive@school.test',
      password: 'inactive-pass-9',
    );
    expect(login.success, isFalse);
  });

  test('duplicate parent portal account rejected', () async {
    final parentId = await SecretaryParentService(db).createParent(
      fullName: 'Dup Parent',
      email: 'dup@school.test',
    );
    final svc = AccountService(db, actorAccountId: 0);
    await svc.createParentPortalAccount(
      parentId: parentId,
      username: 'dup.parent',
      fullName: 'Dup Parent',
      passwordPlain: 'dup-pass-9',
    );
    expect(
      () => svc.createParentPortalAccount(
        parentId: parentId,
        username: 'dup.parent2',
        fullName: 'Dup Parent',
        passwordPlain: 'dup-pass-9',
      ),
      throwsA(isA<AccountValidationException>()),
    );
  });

  test('duplicate student-parent link rejected at database', () async {
    final studentId = await seedStudent(number: 44);
    final parentId = await SecretaryParentService(db).createParent(
      fullName: 'Link Parent',
    );
    final parentService = SecretaryParentService(db);
    await parentService.linkToStudent(
      studentId: studentId,
      parentId: parentId,
      relation: ParentRelationType.anne,
    );
    expect(
      () => parentService.linkToStudent(
        studentId: studentId,
        parentId: parentId,
        relation: ParentRelationType.anne,
      ),
      throwsA(isA<Exception>()),
    );
  });

  test('parent foreign student access denied', () async {
    final classId = await db.insertStudentClass('7', '2025', section: 'C');
    final studentA = await db.insertStudent(
      classId: classId,
      number: 51,
      name: 'A',
    );
    final studentB = await db.insertStudent(
      classId: classId,
      number: 52,
      name: 'B',
    );
    final parentId = await SecretaryParentService(db).createParent(
      fullName: 'Parent A',
      email: 'aonly@school.test',
    );
    await SecretaryParentService(db).linkToStudent(
      studentId: studentA,
      parentId: parentId,
      relation: ParentRelationType.anne,
    );
    final portal = ParentPortalService(db);
    expect(
      () => portal.requireLinked(parentId: parentId, studentId: studentB),
      throwsA(isA<ParentAccessDeniedException>()),
    );
  });

  test('secretary cannot list accounts as admin', () async {
    await AccountService(db, actorAccountId: 0).createBootstrapAdmin(
      username: 'admin.faz10',
      fullName: 'Admin',
      passwordPlain: 'Admin-pass-10',
    );
    final teacherSvc = AccountService(db, actorAccountId: 0);
    expect(
      () => teacherSvc.listAccounts(),
      throwsA(isA<AccountAccessDeniedException>()),
    );
  });
}
