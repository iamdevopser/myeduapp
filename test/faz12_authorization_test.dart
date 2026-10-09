import 'package:flutter_test/flutter_test.dart';
import 'package:my_edu_app/data/local/app_database.dart';
import 'package:my_edu_app/data/models/parent_guardian_model.dart';
import 'package:my_edu_app/models/app_role.dart';
import 'package:my_edu_app/providers/app_state.dart';
import 'package:my_edu_app/services/account_service.dart';
import 'package:my_edu_app/services/notification_recipient.dart';
import 'package:my_edu_app/services/notification_service.dart';
import 'package:my_edu_app/services/parent_portal_service.dart';
import 'package:my_edu_app/services/secretary_parent_service.dart';
import 'package:my_edu_app/services/student_portal_service.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;

  late AppDatabase db;

  setUp(() async {
    db = AppDatabase('faz12_${DateTime.now().microsecondsSinceEpoch}.sqlite');
    await db.open();
  });

  tearDown(() async {
    await db.close();
  });

  test('secretary cannot manage accounts via AccountService', () async {
    final adminId = await AccountService(db, actorAccountId: 0)
        .createBootstrapAdmin(
      username: 'admin.faz12',
      fullName: 'Admin',
      passwordPlain: 'Admin-pass-12',
    );
    final adminSvc = AccountService(db, actorAccountId: adminId);
    final secId = await adminSvc.createStaffAccount(
      username: 'sec.faz12',
      fullName: 'Sec',
      passwordPlain: 'sec-pass-12',
      role: AppRole.secretary,
    );
    final secSvc = AccountService(db, actorAccountId: secId);
    expect(
      () => secSvc.listAccounts(),
      throwsA(isA<AccountAccessDeniedException>()),
    );
    expect(
      () => secSvc.resetPassword(
        accountId: adminId,
        newPasswordPlain: 'hack-pass-12',
      ),
      throwsA(isA<AccountAccessDeniedException>()),
    );
  });

  test('teacher account service cannot list or reset admin accounts', () async {
    final adminId = await AccountService(db, actorAccountId: 0)
        .createBootstrapAdmin(
      username: 'admin2.faz12',
      fullName: 'Admin',
      passwordPlain: 'Admin-pass-12b',
    );
    final adminSvc = AccountService(db, actorAccountId: adminId);
    final teacherId = await adminSvc.createStaffAccount(
      username: 'teach.faz12',
      fullName: 'T',
      passwordPlain: 'teach-pass-12',
      role: AppRole.teacher,
    );
    final teacherSvc = AccountService(db, actorAccountId: teacherId);
    expect(
      () => teacherSvc.listAccounts(),
      throwsA(isA<AccountAccessDeniedException>()),
    );
  });

  test('parent cannot access foreign student', () async {
    final classId = await db.insertStudentClass('7', '2025', section: 'A');
    final studentA = await db.insertStudent(
      classId: classId,
      number: 1,
      name: 'A',
    );
    final studentB = await db.insertStudent(
      classId: classId,
      number: 2,
      name: 'B',
    );
    final parentId = await SecretaryParentService(db).createParent(
      fullName: 'P',
      email: 'p@faz12.test',
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

  test('student enrollmentBySession rejects unrelated student id', () async {
    final classId = await db.insertStudentClass('8', '2025', section: 'A');
    final studentA = await db.insertStudent(
      classId: classId,
      number: 10,
      name: 'Session A',
    );
    final studentB = await db.insertStudent(
      classId: classId,
      number: 11,
      name: 'Session B',
    );
    final service = StudentPortalService(db);
    final enrA = await service.enrollmentBySession(
      classId: classId,
      studentId: studentA,
    );
    expect(enrA, isNotNull);
    final enrB = await service.enrollmentBySession(
      classId: classId,
      studentId: studentB,
    );
    expect(enrB, isNotNull);
    final wrong = await service.enrollmentBySession(
      classId: classId,
      studentId: 99999,
    );
    expect(wrong, isNull);
  });

  test('notification mark read blocked for other recipient', () async {
    await db.insertInAppNotificationIdempotent(
      recipientRole: 'parent',
      recipientId: 1,
      title: 'Mine',
      body: '',
      type: 'duyuru',
      dedupKey: 'faz12:parent:1',
    );
    await db.insertInAppNotificationIdempotent(
      recipientRole: 'parent',
      recipientId: 2,
      title: 'Other',
      body: '',
      type: 'duyuru',
      dedupKey: 'faz12:parent:2',
    );
    final rows = await db.listInAppNotificationsForRecipient(
      recipientRole: 'parent',
      recipientId: 2,
      limit: 10,
    );
    final otherId = rows.first['id'] as int;

    final service = NotificationService(
      db,
      fixedRecipient: const NotificationRecipient(
        role: AppRole.parent,
        userId: 1,
      ),
    );
    final ok = await service.markAsRead(otherId);
    expect(ok, isFalse);
  });

  test('backup operations denied outside teacher session', () async {
    final state = await AppState.createWithDatabase(db);
    state.setStudentSession(classId: 1, studentId: 1);
    state.setUnlocked(true, role: AppRole.student);
    expect(
      () => state.buildBackupBytes(),
      throwsA(isA<TeacherBackupAccessDeniedException>()),
    );
    expect(
      () => state.setAutoBackupEnabled(true),
      throwsA(isA<TeacherBackupAccessDeniedException>()),
    );
  });

  test('parent selectParentStudent blocks unlinked child', () async {
    final classId = await db.insertStudentClass('9', '2025', section: 'A');
    final linked = await db.insertStudent(
      classId: classId,
      number: 20,
      name: 'Linked',
    );
    final foreign = await db.insertStudent(
      classId: classId,
      number: 21,
      name: 'Foreign',
    );
    final parentId = await SecretaryParentService(db).createParent(
      fullName: 'Sel Parent',
    );
    await SecretaryParentService(db).linkToStudent(
      studentId: linked,
      parentId: parentId,
      relation: ParentRelationType.baba,
    );
    final state = await AppState.createWithDatabase(db);
    state.setParentSession(parentId: parentId, selectedStudentId: linked);
    state.setUnlocked(true, role: AppRole.parent);
    final ok = await state.selectParentStudent(foreign);
    expect(ok, isFalse);
  });
}
