import 'package:flutter_test/flutter_test.dart';
import 'package:my_edu_app/data/local/app_database.dart';
import 'package:my_edu_app/models/app_role.dart';
import 'package:my_edu_app/providers/app_state.dart';
import 'package:my_edu_app/services/database_sync_service.dart';
import 'package:my_edu_app/services/notification_fanout_service.dart';
import 'package:my_edu_app/services/notification_recipient.dart';
import 'package:my_edu_app/services/notification_service.dart';
import 'package:my_edu_app/services/secretary_announcement_service.dart';
import 'package:my_edu_app/services/secretary_parent_service.dart';
import 'package:my_edu_app/data/models/parent_guardian_model.dart';
import 'package:my_edu_app/utils/student_announcement_meta.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;

  late AppDatabase db;

  setUp(() async {
    db = AppDatabase('faz8_${DateTime.now().microsecondsSinceEpoch}.sqlite');
    await db.open();
  });

  tearDown(() async {
    await db.close();
  });

  test('schema version 34 creates bildirimler', () async {
    final v = await db.database.rawQuery('PRAGMA user_version');
    expect(v.first['user_version'], 35);
    final tables = await db.database.rawQuery(
      "SELECT name FROM sqlite_master WHERE type='table' AND name='bildirimler'",
    );
    expect(tables.length, 1);
    expect(DatabaseSyncService.exportTables, contains('bildirimler'));
    expect(DatabaseSyncService.databaseVersion, 34);
  });

  test('notification creation and unread count', () async {
    final service = NotificationService(
      db,
      fixedRecipient: const NotificationRecipient(
        role: AppRole.student,
        userId: 1,
      ),
    );
    final inserted = await service.createIdempotent(
      recipient: const NotificationRecipient(role: AppRole.student, userId: 1),
      title: 'Test',
      body: 'Body',
      type: 'duyuru',
      referenceType: 'ogrenci_duyuru',
      referenceId: 5,
      dedupKey: 'test:1',
    );
    expect(inserted, isTrue);
    expect(await service.unreadCount(), 1);
    final list = await service.listForCurrentUser();
    expect(list.length, 1);
    expect(list.first.isRead, isFalse);
    expect(list.first.referenceId, 5);
  });

  test('user isolation between recipients', () async {
    await db.insertInAppNotificationIdempotent(
      recipientRole: 'student',
      recipientId: 10,
      title: 'A',
      body: '',
      type: 'duyuru',
      dedupKey: 'iso:a',
    );
    await db.insertInAppNotificationIdempotent(
      recipientRole: 'student',
      recipientId: 20,
      title: 'B',
      body: '',
      type: 'duyuru',
      dedupKey: 'iso:b',
    );

    final userA = NotificationService(
      db,
      fixedRecipient: const NotificationRecipient(
        role: AppRole.student,
        userId: 10,
      ),
    );
    final userB = NotificationService(
      db,
      fixedRecipient: const NotificationRecipient(
        role: AppRole.student,
        userId: 20,
      ),
    );
    expect((await userA.listForCurrentUser()).length, 1);
    expect((await userB.listForCurrentUser()).length, 1);
    expect((await userA.listForCurrentUser()).first.title, 'A');
    expect((await userB.listForCurrentUser()).first.title, 'B');
  });

  test('mark read and mark all scoped to recipient', () async {
    final r1 = const NotificationRecipient(role: AppRole.parent, userId: 3);
    final r2 = const NotificationRecipient(role: AppRole.parent, userId: 4);
    final s1 = NotificationService(db, fixedRecipient: r1);
    final s2 = NotificationService(db, fixedRecipient: r2);

    await s1.createIdempotent(
      recipient: r1,
      title: 'P3',
      body: '',
      type: 'duyuru',
      dedupKey: 'p3:1',
    );
    await s2.createIdempotent(
      recipient: r2,
      title: 'P4',
      body: '',
      type: 'duyuru',
      dedupKey: 'p4:1',
    );
    await s1.createIdempotent(
      recipient: r1,
      title: 'P3b',
      body: '',
      type: 'duyuru',
      dedupKey: 'p3:2',
    );

    final id = (await s1.listForCurrentUser()).first.id;
    await s1.markAsRead(id);
    expect(await s1.unreadCount(), 1);
    expect(await s2.unreadCount(), 1);

    await s1.markAllAsRead();
    expect(await s1.unreadCount(), 0);
    expect(await s2.unreadCount(), 1);
  });

  test('duplicate protection on dedup key', () async {
    final recipient = const NotificationRecipient(
      role: AppRole.secretary,
      userId: 0,
    );
    final service = NotificationService(db, fixedRecipient: recipient);
    final first = await service.createIdempotent(
      recipient: recipient,
      title: 'Once',
      body: '',
      type: 'belge',
      dedupKey: 'dup:1',
    );
    final second = await service.createIdempotent(
      recipient: recipient,
      title: 'Twice',
      body: '',
      type: 'belge',
      dedupKey: 'dup:1',
    );
    expect(first, isTrue);
    expect(second, isFalse);
    expect(await service.unreadCount(), 1);
  });

  test('announcement publish fanout respects scope and dedup', () async {
    final classA = await db.insertStudentClass('7', '2025', section: 'A');
    final classB = await db.insertStudentClass('8', '2025', section: 'B');
    final studentA = await db.insertStudent(
      classId: classA,
      number: 1,
      name: 'Student A',
    );
    final studentB = await db.insertStudent(
      classId: classB,
      number: 2,
      name: 'Student B',
    );

    final ann = SecretaryAnnouncementService(db);
    final draftId = await ann.create(
      title: 'Scoped',
      body: 'Only 7th',
      targetType: StudentAnnouncementTargetType.grade,
      targetGradeLevel: 7,
      status: StudentAnnouncementStatus.draft,
    );
    await ann.publish(draftId);
    await ann.publish(draftId);

    final svcA = NotificationService(
      db,
      fixedRecipient: NotificationRecipient(
        role: AppRole.student,
        userId: studentA,
      ),
    );
    final svcB = NotificationService(
      db,
      fixedRecipient: NotificationRecipient(
        role: AppRole.student,
        userId: studentB,
      ),
    );
    expect(await svcA.unreadCount(), 1);
    expect(await svcB.unreadCount(), 0);
  });

  test('document fanout notifies teacher role inbox', () async {
    final id = await db.insertSecretaryDocument(
      name: 'Takvim',
      type: 'pdf',
      path: r'C:\fake\takvim.pdf',
      scope: 'Tüm okul',
    );
    await NotificationFanoutService(db).onDocumentCreated(id);
    await NotificationFanoutService(db).onDocumentCreated(id);

    final teacherInbox = NotificationService(
      db,
      fixedRecipient: const NotificationRecipient(
        role: AppRole.teacher,
        userId: 0,
      ),
    );
    expect(await teacherInbox.unreadCount(), 1);
    final n = (await teacherInbox.listForCurrentUser()).first;
    expect(n.referenceType, NotificationFanoutService.refDocument);
    expect(n.referenceId, id);
  });

  test('role isolation secretary vs teacher inboxes', () async {
    await db.insertInAppNotificationIdempotent(
      recipientRole: 'teacher',
      recipientId: 0,
      title: 'T',
      body: '',
      type: 'belge',
      dedupKey: 'role:t',
    );
    await db.insertInAppNotificationIdempotent(
      recipientRole: 'secretary',
      recipientId: 0,
      title: 'S',
      body: '',
      type: 'belge',
      dedupKey: 'role:s',
    );
    final teacher = NotificationService(
      db,
      fixedRecipient: const NotificationRecipient(
        role: AppRole.teacher,
        userId: 0,
      ),
    );
    final secretary = NotificationService(
      db,
      fixedRecipient: const NotificationRecipient(
        role: AppRole.secretary,
        userId: 0,
      ),
    );
    expect((await teacher.listForCurrentUser()).single.title, 'T');
    expect((await secretary.listForCurrentUser()).single.title, 'S');
  });

  test('parent receives announcement when child linked', () async {
    final parents = SecretaryParentService(db);
    final classId = await db.insertStudentClass('7', '2025', section: 'A');
    final studentId = await db.insertStudent(
      classId: classId,
      number: 5,
      name: 'Kid',
    );
    final parentId = await parents.createParent(
      fullName: 'Veli',
      email: 'veli@x.test',
    );
    await parents.linkToStudent(
      studentId: studentId,
      parentId: parentId,
      relation: ParentRelationType.anne,
    );

    final ann = SecretaryAnnouncementService(db);
    final id = await ann.create(
      title: 'Okul',
      body: 'Mesaj',
      targetType: StudentAnnouncementTargetType.allSchool,
      status: StudentAnnouncementStatus.draft,
    );
    await ann.publish(id);

    final parentSvc = NotificationService(
      db,
      fixedRecipient: NotificationRecipient(
        role: AppRole.parent,
        userId: parentId,
      ),
    );
    expect(await parentSvc.unreadCount(), 1);
  });

  test('mark read rejected for wrong recipient id', () async {
    await db.insertInAppNotificationIdempotent(
      recipientRole: 'student',
      recipientId: 1,
      title: 'X',
      body: '',
      type: 'duyuru',
      dedupKey: 'idor:1',
    );
    final rows = await db.listInAppNotificationsForRecipient(
      recipientRole: 'student',
      recipientId: 1,
    );
    final notifId = rows.first['id'] as int;

    final attacker = NotificationService(
      db,
      fixedRecipient: const NotificationRecipient(
        role: AppRole.student,
        userId: 2,
      ),
    );
    expect(await attacker.markAsRead(notifId), isFalse);
    final owner = NotificationService(
      db,
      fixedRecipient: const NotificationRecipient(
        role: AppRole.student,
        userId: 1,
      ),
    );
    expect(await owner.unreadCount(), 1);
  });
}
