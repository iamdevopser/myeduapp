import 'package:flutter_test/flutter_test.dart';
import 'package:my_edu_app/data/local/app_database.dart';
import 'package:my_edu_app/models/app_role.dart';
import 'package:my_edu_app/providers/app_state.dart';
import 'package:my_edu_app/services/account_auth_service.dart';
import 'package:my_edu_app/services/account_service.dart';
import 'package:my_edu_app/services/authorization_service.dart';
import 'package:my_edu_app/services/database_sync_service.dart';
import 'package:my_edu_app/services/secretary_parent_service.dart';
import 'package:my_edu_app/data/models/parent_guardian_model.dart';
import 'package:my_edu_app/utils/student_password_hash.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;

  late AppDatabase db;

  setUp(() async {
    db = AppDatabase('faz9_${DateTime.now().microsecondsSinceEpoch}.sqlite');
    await db.open();
  });

  tearDown(() async {
    await db.close();
  });

  test('schema version 34 creates hesaplar', () async {
    final v = await db.database.rawQuery('PRAGMA user_version');
    expect(v.first['user_version'], 35);
    expect(DatabaseSyncService.databaseVersion, 34);
    expect(DatabaseSyncService.exportTables, contains('hesaplar'));
  });

  test('bootstrap admin and login', () async {
    await AccountService(db, actorAccountId: 0).createBootstrapAdmin(
      username: 'root.admin',
      fullName: 'Root Admin',
      passwordPlain: 'Str0ng-Pass-9',
    );
    final auth = AccountAuthService(db);
    final result = await auth.authenticate(
      login: 'root.admin',
      passwordPlain: 'Str0ng-Pass-9',
      role: AppRole.admin,
    );
    expect(result, isNotNull);
    final rows = await db.database.query('hesaplar');
    expect(rows.first['sifre_hash'], isNot(contains('Str0ng')));
    expect(rows.first['sifre_hash'], StudentPasswordHash.hash('Str0ng-Pass-9'));
  });

  test('wrong admin password rejected', () async {
    await AccountService(db, actorAccountId: 0).createBootstrapAdmin(
      username: 'admin2',
      fullName: 'A',
      passwordPlain: 'pass-abc',
    );
    final auth = AccountAuthService(db);
    expect(
      await auth.authenticate(
        login: 'admin2',
        passwordPlain: 'wrong',
        role: AppRole.admin,
      ),
      isNull,
    );
  });

  Future<int> bootstrapAndLoginAdmin() async {
    final id = await AccountService(db, actorAccountId: 0).createBootstrapAdmin(
      username: 'main.admin',
      fullName: 'Main',
      passwordPlain: 'Admin-9-pass',
    );
    return id;
  }

  test('create staff and domain-linked portal accounts', () async {
    final adminId = await bootstrapAndLoginAdmin();
    final service = AccountService(db, actorAccountId: adminId);
    await service.createStaffAccount(
      username: 'teacher1',
      fullName: 'Teacher One',
      passwordPlain: 'teach-pass',
      role: AppRole.teacher,
    );
    await service.createStaffAccount(
      username: 'sec1',
      fullName: 'Secretary One',
      passwordPlain: 'sec-pass',
      role: AppRole.secretary,
    );
    expect(
      () => service.createStaffAccount(
        username: 'stu.bad',
        fullName: 'Nope',
        passwordPlain: 'x-pass-9',
        role: AppRole.student,
      ),
      throwsA(isA<AccountValidationException>()),
    );
    final classId = await db.insertStudentClass('7', '2025', section: 'A');
    final studentId = await db.insertStudent(
      classId: classId,
      number: 7,
      name: 'Student Seven',
    );
    await AccountService(db, actorAccountId: 0).createStudentPortalAccount(
      studentId: studentId,
      username: 'stu7',
      fullName: 'Student Seven',
      passwordPlain: 'stu-pass',
    );
    final parentId = await SecretaryParentService(db).createParent(
      fullName: 'Parent P',
      email: 'parent@faz9.test',
    );
    await SecretaryParentService(db).linkToStudent(
      studentId: studentId,
      parentId: parentId,
      relation: ParentRelationType.anne,
    );
    await AccountService(db, actorAccountId: 0).createParentPortalAccount(
      username: 'parentp',
      fullName: 'Parent P',
      email: 'parent@faz9.test',
      passwordPlain: 'par-pass',
      parentId: parentId,
    );
    final list = await service.listAccounts();
    expect(list.length, 5);
  });

  test('inactive account cannot login', () async {
    final adminId = await bootstrapAndLoginAdmin();
    final service = AccountService(db, actorAccountId: adminId);
    final teacherId = await service.createStaffAccount(
      username: 'inactive.t',
      fullName: 'T',
      passwordPlain: 'x-pass-1',
      role: AppRole.teacher,
    );
    await service.setActive(accountId: teacherId, active: false);
    final auth = AccountAuthService(db);
    expect(
      await auth.authenticate(
        login: 'inactive.t',
        passwordPlain: 'x-pass-1',
        role: AppRole.teacher,
      ),
      isNull,
    );
  });

  test('last admin cannot be deactivated', () async {
    final adminId = await bootstrapAndLoginAdmin();
    final service = AccountService(db, actorAccountId: adminId);
    expect(
      () => service.setActive(accountId: adminId, active: false),
      throwsA(isA<LastAdminProtectionException>()),
    );
  });

  test('duplicate staff email rejected with validation', () async {
    final adminId = await bootstrapAndLoginAdmin();
    final service = AccountService(db, actorAccountId: adminId);
    await service.createStaffAccount(
      username: 'teacher.one',
      fullName: 'T One',
      email: 'shared@school.test',
      passwordPlain: 'pass-one-11',
      role: AppRole.teacher,
    );
    expect(
      () => service.createStaffAccount(
        username: 'teacher.two',
        fullName: 'T Two',
        email: 'shared@school.test',
        passwordPlain: 'pass-two-11',
        role: AppRole.teacher,
      ),
      throwsA(
        predicate(
          (e) =>
              e is AccountValidationException &&
              e.messageKey == 'adminAccountEmailTaken',
        ),
      ),
    );
  });

  test('non-admin cannot manage accounts', () async {
    final adminId = await bootstrapAndLoginAdmin();
    final adminSvc = AccountService(db, actorAccountId: adminId);
    final teacherAccId = await adminSvc.createStaffAccount(
      username: 'tonly',
      fullName: 'T',
      passwordPlain: 'pw',
      role: AppRole.teacher,
    );
    final teacherSvc = AccountService(db, actorAccountId: teacherAccId);
    expect(
      () => teacherSvc.listAccounts(),
      throwsA(isA<AccountAccessDeniedException>()),
    );
  });

  test('password reset updates hash not plain text', () async {
    final adminId = await bootstrapAndLoginAdmin();
    final service = AccountService(db, actorAccountId: adminId);
    final id = await service.createStaffAccount(
      username: 'resetme',
      fullName: 'R',
      passwordPlain: 'old-pass-9',
      role: AppRole.secretary,
    );
    await service.resetPassword(
      accountId: id,
      newPasswordPlain: 'new-pass-9',
    );
    final row = await db.getAccountById(id);
    expect(row!['sifre_hash'], isNot(contains('new-pass')));
    final auth = AccountAuthService(db);
    expect(
      await auth.authenticate(
        login: 'resetme',
        passwordPlain: 'new-pass-9',
        role: AppRole.secretary,
      ),
      isNotNull,
    );
  });

  test('authorization service flags admin workspace', () async {
    final adminId = await bootstrapAndLoginAdmin();
    final state = await AppState.createWithDatabase(db);
    state.setAccountSession(adminId);
    state.setUnlocked(true, role: AppRole.admin);
    final auth = AuthorizationService(state);
    expect(auth.canManageAccounts, isTrue);
    expect(auth.canAccessAdminWorkspace, isTrue);
  });

  test('student login blocked when linked account inactive', () async {
    final adminId = await bootstrapAndLoginAdmin();
    final service = AccountService(db, actorAccountId: adminId);
    final classId = await db.insertStudentClass('8', '2025', section: 'A');
    final studentId = await db.insertStudent(
      classId: classId,
      number: 88,
      name: 'Blocked Student',
    );
    await db.setStudentPasswordHash(
      studentId,
      StudentPasswordHash.hash('stu88')!,
    );
    final accId = await AccountService(db, actorAccountId: 0)
        .createStudentPortalAccount(
      studentId: studentId,
      username: 'stu88',
      fullName: 'Blocked Student',
      passwordPlain: 'stu88',
    );
    await service.setActive(accountId: accId, active: false);
    final state = await AppState.createWithDatabase(db);
    final login = await state.loginStudent(
      studentNumber: 88,
      password: 'stu88',
    );
    expect(login.success, isFalse);
  });
}
