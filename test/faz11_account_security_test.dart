import 'package:flutter_test/flutter_test.dart';
import 'package:my_edu_app/data/local/app_database.dart';
import 'package:my_edu_app/data/models/parent_guardian_model.dart';
import 'package:my_edu_app/models/app_role.dart';
import 'package:my_edu_app/providers/app_state.dart';
import 'package:my_edu_app/services/account_auth_service.dart';
import 'package:my_edu_app/services/account_service.dart';
import 'package:my_edu_app/services/parent_portal_service.dart';
import 'package:my_edu_app/services/secretary_parent_service.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;

  late AppDatabase db;

  setUp(() async {
    db = AppDatabase('faz11_${DateTime.now().microsecondsSinceEpoch}.sqlite');
    await db.open();
  });

  tearDown(() async {
    await db.close();
  });

  Future<int> bootstrapAdmin() async {
    return AccountService(db, actorAccountId: 0).createBootstrapAdmin(
      username: 'admin.faz11',
      fullName: 'Admin',
      passwordPlain: 'Admin-pass-11',
    );
  }

  test('mustChangePassword cleared after owner password change', () async {
    final adminId = await bootstrapAdmin();
    final service = AccountService(db, actorAccountId: adminId);
    final staffId = await service.createStaffAccount(
      username: 'sec.mustchange',
      fullName: 'Sec',
      passwordPlain: 'temp-pass-11',
      role: AppRole.secretary,
      mustChangePassword: true,
    );

    final auth = AccountAuthService(db);
    var login = await auth.authenticate(
      login: 'sec.mustchange',
      passwordPlain: 'temp-pass-11',
      role: AppRole.secretary,
    );
    expect(login, isNotNull);
    expect(login!.mustChangePassword, isTrue);

    await AccountService(db, actorAccountId: staffId)
        .changePasswordAsAccountOwner(
      accountId: staffId,
      actorAccountId: staffId,
      newPasswordPlain: 'new-secure-11',
    );

    final row = await db.getAccountById(staffId);
    expect((row!['sifre_degistir'] as int? ?? 0), 0);

    login = await auth.authenticate(
      login: 'sec.mustchange',
      passwordPlain: 'new-secure-11',
      role: AppRole.secretary,
    );
    expect(login, isNotNull);
    expect(login!.mustChangePassword, isFalse);
  });

  test('reset password sets mustChangePassword and new password works', () async {
    final adminId = await bootstrapAdmin();
    final service = AccountService(db, actorAccountId: adminId);
    final teacherId = await service.createStaffAccount(
      username: 'teach.reset',
      fullName: 'T',
      passwordPlain: 'first-pass-11',
      role: AppRole.teacher,
      mustChangePassword: false,
    );
    await service.resetPassword(
      accountId: teacherId,
      newPasswordPlain: 'reset-pass-11',
    );
    final row = await db.getAccountById(teacherId);
    expect((row!['sifre_degistir'] as int? ?? 0), 1);

    final auth = AccountAuthService(db);
    expect(
      await auth.authenticate(
        login: 'teach.reset',
        passwordPlain: 'first-pass-11',
        role: AppRole.teacher,
      ),
      isNull,
    );
    final login = await auth.authenticate(
      login: 'teach.reset',
      passwordPlain: 'reset-pass-11',
      role: AppRole.teacher,
    );
    expect(login, isNotNull);
    expect(login!.mustChangePassword, isTrue);
  });

  test('owner cannot change another account password', () async {
    final adminId = await bootstrapAdmin();
    final adminSvc = AccountService(db, actorAccountId: adminId);
    final otherId = await adminSvc.createStaffAccount(
      username: 'other.staff',
      fullName: 'O',
      passwordPlain: 'other-pass-11',
      role: AppRole.teacher,
    );
    expect(
      () => AccountService(db, actorAccountId: adminId)
          .changePasswordAsAccountOwner(
        accountId: otherId,
        actorAccountId: adminId,
        newPasswordPlain: 'hack-pass-11',
      ),
      throwsA(isA<AccountAccessDeniedException>()),
    );
  });

  test('clearSession removes account and role state', () async {
    final state = await AppState.createWithDatabase(db);
    state.setAccountSession(42);
    state.setStudentSession(classId: 1, studentId: 2);
    state.setUnlocked(true, role: AppRole.student);
    state.clearSession();
    expect(state.sessionAccountId, isNull);
    expect(state.sessionStudentId, isNull);
    expect(state.sessionClassId, isNull);
    expect(state.currentRole, isNull);
    expect(state.isUnlocked, isFalse);
  });

  test('parent email and username login regression', () async {
    final classId = await db.insertStudentClass('7', '2025', section: 'A');
    final studentId = await db.insertStudent(
      classId: classId,
      number: 77,
      name: 'Child',
    );
    final parentId = await SecretaryParentService(db).createParent(
      fullName: 'Reg Parent',
      email: 'reg@school.test',
    );
    await SecretaryParentService(db).linkToStudent(
      studentId: studentId,
      parentId: parentId,
      relation: ParentRelationType.anne,
    );
    await AccountService(db, actorAccountId: 0).createParentPortalAccount(
      parentId: parentId,
      username: 'reg.parent',
      fullName: 'Reg Parent',
      passwordPlain: 'reg-pass-11',
      email: 'reg@school.test',
    );

    final state = await AppState.createWithDatabase(db);
    final byEmail = await state.loginParent(
      email: 'reg@school.test',
      password: 'reg-pass-11',
    );
    expect(byEmail.success, isTrue);

    final byUsername = await state.loginParent(
      email: 'reg.parent',
      password: 'reg-pass-11',
    );
    expect(byUsername.success, isTrue);

    final portal = ParentPortalService(db);
    expect(
      () => portal.requireLinked(parentId: parentId, studentId: 99999),
      throwsA(isA<ParentAccessDeniedException>()),
    );
  });

  test('loginRoleAccount reports mustChangePassword for staff', () async {
    final adminId = await bootstrapAdmin();
    await AccountService(db, actorAccountId: adminId).createStaffAccount(
      username: 'flag.check',
      fullName: 'F',
      passwordPlain: 'flag-pass-11',
      role: AppRole.secretary,
    );
    final state = await AppState.createWithDatabase(db);
    final login = await state.loginRoleAccount(
      role: AppRole.secretary,
      login: 'flag.check',
      password: 'flag-pass-11',
    );
    expect(login.success, isTrue);
    expect(login.mustChangePassword, isTrue);
    expect(state.sessionAccountId, isNotNull);
  });
}
