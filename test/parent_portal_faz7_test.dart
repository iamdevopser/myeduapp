import 'package:crypto/crypto.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_edu_app/data/local/app_database.dart';
import 'package:my_edu_app/data/models/parent_guardian_model.dart';
import 'package:my_edu_app/models/app_role.dart';
import 'package:my_edu_app/providers/app_state.dart';
import 'package:my_edu_app/services/app_paths.dart';
import 'package:my_edu_app/services/authorization_service.dart';
import 'package:my_edu_app/services/file_service.dart';
import 'package:my_edu_app/services/parent_portal_service.dart';
import 'package:my_edu_app/services/secretary_announcement_service.dart';
import 'package:my_edu_app/services/secretary_document_service.dart';
import 'package:my_edu_app/services/secretary_parent_service.dart';
import 'package:my_edu_app/utils/student_announcement_meta.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

String _hash(String s) {
  final bytes = s.runes.map((r) => r & 0xff).toList();
  return sha256.convert(bytes).toString();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;

  late AppDatabase db;
  late SecretaryParentService parentAdmin;
  late ParentPortalService portal;
  late SecretaryDocumentService docService;

  setUp(() async {
    db = AppDatabase('faz7_${DateTime.now().microsecondsSinceEpoch}.sqlite');
    await db.open();
    parentAdmin = SecretaryParentService(db);
    portal = ParentPortalService(db);
    docService = SecretaryDocumentService(db, FileService(AppPaths()));
  });

  tearDown(() async {
    await db.close();
  });

  Future<(int parentId, int studentId, int classId)> seedFamily({
    required String email,
    int number = 10,
  }) async {
    final classId = await db.insertStudentClass('7', '2025', section: 'A');
    final studentId = await db.insertStudent(
      classId: classId,
      number: number,
      name: 'Child $number',
    );
    final parentId = await parentAdmin.createParent(
      fullName: 'Parent $email',
      email: email,
    );
    await parentAdmin.linkToStudent(
      studentId: studentId,
      parentId: parentId,
      relation: ParentRelationType.anne,
    );
    return (parentId, studentId, classId);
  }

  test('schema version 34 adds veliler sifre_hash', () async {
    final v = await db.database.rawQuery('PRAGMA user_version');
    expect(v.first['user_version'], 35);
    final cols = await db.database.rawQuery('PRAGMA table_info(veliler)');
    final names = cols.map((c) => c['name'] as String).toSet();
    expect(names.contains('sifre_hash'), isTrue);
  });

  test('parent login success and role assignment', () async {
    final (parentId, _, _) =
        await seedFamily(email: 'login@school.test');
    final state = await AppState.createWithDatabase(db);
    final login = await state.loginParent(
      email: 'login@school.test',
      password: AppState.defaultParentPassword,
    );
    expect(login.success, isTrue);
    expect(login.parentId, parentId);
    state.setParentSession(parentId: parentId, selectedStudentId: null);
    state.setUnlocked(true, role: AppRole.parent);
    expect(state.isParent, isTrue);
    expect(state.currentRole, AppRole.parent);
  });

  test('wrong parent credentials rejected', () async {
    await seedFamily(email: 'bad@school.test');
    final state = await AppState.createWithDatabase(db);
    final login = await state.loginParent(
      email: 'bad@school.test',
      password: 'wrong-password',
    );
    expect(login.success, isFalse);
  });

  test('linked students listed and foreign student access denied', () async {
    final (parentA, studentA, _) =
        await seedFamily(email: 'a@school.test', number: 11);
    final (_, studentB, _) =
        await seedFamily(email: 'b@school.test', number: 12);

    final list = await portal.listLinkedStudents(parentA);
    expect(list.length, 1);
    expect(list.first.studentId, studentA);

    expect(
      () => portal.requireLinked(parentId: parentA, studentId: studentB),
      throwsA(isA<ParentAccessDeniedException>()),
    );
  });

  test('announcements only published and scoped', () async {
    final (parentId, studentId, classId) =
        await seedFamily(email: 'ann@school.test');
    final ann = SecretaryAnnouncementService(db);
    await ann.create(
      title: 'Taslak',
      body: 'Gizli',
      targetType: StudentAnnouncementTargetType.allSchool,
      status: StudentAnnouncementStatus.draft,
    );
    final pubId = await ann.create(
      title: 'Yayında',
      body: 'Okul',
      targetType: StudentAnnouncementTargetType.allSchool,
      status: StudentAnnouncementStatus.published,
    );
    await ann.publish(pubId);

    final items = await portal.announcementsForStudent(
      parentId: parentId,
      studentId: studentId,
    );
    expect(items.any((a) => a.title == 'Taslak'), isFalse);
    expect(items.any((a) => a.title == 'Yayında'), isTrue);

    final otherClass = await db.insertStudentClass('8', '2025', section: 'A');
    final sectionOnly = await ann.create(
      title: '8-A only',
      body: 'x',
      targetType: StudentAnnouncementTargetType.section,
      classId: otherClass,
      status: StudentAnnouncementStatus.published,
    );
    await ann.publish(sectionOnly);
    final scoped = await portal.announcementsForStudent(
      parentId: parentId,
      studentId: studentId,
    );
    expect(scoped.any((a) => a.title == '8-A only'), isFalse);
    expect(classId, greaterThan(0));
  });

  test('documents scoped by belge_kapsam', () async {
    final (parentId, studentId, classId) =
        await seedFamily(email: 'doc@school.test');
    await db.insertSecretaryDocument(
      name: 'Genel',
      type: 'pdf',
      path: r'C:\x.pdf',
      scope: 'Tüm okul',
    );
    await db.insertSecretaryDocument(
      name: 'Başka sınıf',
      type: 'pdf',
      path: r'C:\y.pdf',
      scope: 'sinif:99999',
    );
    await db.insertSecretaryDocument(
      name: 'Bu sınıf',
      type: 'pdf',
      path: r'C:\z.pdf',
      scope: 'sinif:$classId',
    );

    final docs = await portal.documentsForStudent(
      parentId: parentId,
      studentId: studentId,
    );
    expect(docs.any((d) => d.name == 'Genel'), isTrue);
    expect(docs.any((d) => d.name == 'Bu sınıf'), isTrue);
    expect(docs.any((d) => d.name == 'Başka sınıf'), isFalse);
  });

  test('attendance isolated per student', () async {
    final (parentId, studentId, _) =
        await seedFamily(email: 'att@school.test', number: 20);
    final (_, otherStudent, _) =
        await seedFamily(email: 'att2@school.test', number: 21);

    final today = AppDatabase.scoreDateKey(DateTime.now());
    await db.setStudentDailyAttendance(
      studentId: studentId,
      dateKey: today,
      status: 'yok',
    );
    await db.setStudentDailyAttendance(
      studentId: otherStudent,
      dateKey: today,
      status: 'izinli',
    );

    final rows = await portal.attendanceForStudent(
      parentId: parentId,
      studentId: studentId,
    );
    expect(rows.length, 1);
    expect(rows.first['durum'], 'yok');

    expect(
      () => portal.attendanceForStudent(
        parentId: parentId,
        studentId: otherStudent,
      ),
      throwsA(isA<ParentAccessDeniedException>()),
    );
  });

  test('parent authorization read-only', () async {
    final (parentId, _, _) = await seedFamily(email: 'auth@school.test');
    final state = await AppState.createWithDatabase(db);
    state.setParentSession(parentId: parentId, selectedStudentId: null);
    state.setUnlocked(true, role: AppRole.parent);
    final auth = AuthorizationService(state);
    expect(auth.canViewOwnStudents, isTrue);
    expect(auth.canViewStudentAnnouncements, isTrue);
    expect(auth.canManageAnnouncementsAsParent, isFalse);
    expect(auth.canManageDocumentsAsParent, isFalse);
    expect(auth.canCreateStudent, isFalse);
    expect(auth.canEditDocument, isFalse);
    expect(auth.canDeleteStudent, isFalse);
  });

  test('selectParentStudent rejects unlinked id', () async {
    final (parentId, studentId, _) =
        await seedFamily(email: 'sel@school.test');
    final (_, otherId, _) =
        await seedFamily(email: 'other@school.test', number: 99);
    final state = await AppState.createWithDatabase(db);
    state.setParentSession(parentId: parentId, selectedStudentId: studentId);
    final ok = await state.selectParentStudent(otherId);
    expect(ok, isFalse);
    expect(state.parentSelectedStudentId, studentId);
  });

  test('per-parent password hash supported', () async {
    final (parentId, _, _) =
        await seedFamily(email: 'hash@school.test');
    await db.setParentPasswordHash(parentId, _hash('secret123'));
    final state = await AppState.createWithDatabase(db);
    var login = await state.loginParent(
      email: 'hash@school.test',
      password: AppState.defaultParentPassword,
    );
    expect(login.success, isFalse);
    login = await state.loginParent(
      email: 'hash@school.test',
      password: 'secret123',
    );
    expect(login.success, isTrue);
  });
}
