import 'package:flutter_test/flutter_test.dart';
import 'package:my_edu_app/data/local/app_database.dart';
import 'package:my_edu_app/data/models/smtp_settings.dart';
import 'package:my_edu_app/models/app_role.dart';
import 'package:my_edu_app/providers/app_state.dart';
import 'package:my_edu_app/services/authorization_service.dart';
import 'package:my_edu_app/services/notification_recipient.dart';
import 'package:my_edu_app/services/notification_service.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;

  late AppDatabase db;

  setUp(() async {
    db = AppDatabase('p10_${DateTime.now().microsecondsSinceEpoch}.sqlite');
    await db.open();
  });

  tearDown(() async {
    await db.close();
  });

  group('Teacher display name guard (P10)', () {
    test('teacher can set display name', () async {
      final state = await AppState.createWithDatabase(db);
      state.setUnlocked(true, role: AppRole.teacher);
      await state.setTeacherDisplayName('Ada Öğretmen');
      final stored = await db.getSetting('teacher_display_name');
      expect(stored, 'Ada Öğretmen');
    });

    test('student cannot set display name', () async {
      final classId = await db.insertStudentClass('9', '2025', section: 'A');
      final studentId = await db.insertStudent(
        classId: classId,
        number: 1,
        name: 'S',
      );
      final state = await AppState.createWithDatabase(db);
      state.setStudentSession(classId: classId, studentId: studentId);
      state.setUnlocked(true, role: AppRole.student);
      expect(
        () => state.setTeacherDisplayName('Hack'),
        throwsA(isA<TeacherSettingsAccessDeniedException>()),
      );
    });

    test('parent cannot set display name', () async {
      final state = await AppState.createWithDatabase(db);
      state.setParentSession(parentId: 1, selectedStudentId: 1);
      state.setUnlocked(true, role: AppRole.parent);
      expect(
        () => state.setTeacherDisplayName('Hack'),
        throwsA(isA<TeacherSettingsAccessDeniedException>()),
      );
    });

    test('secretary cannot set display name', () async {
      final state = await AppState.createWithDatabase(db);
      state.setUnlocked(true, role: AppRole.secretary);
      expect(
        () => state.setTeacherDisplayName('Hack'),
        throwsA(isA<TeacherSettingsAccessDeniedException>()),
      );
    });

    test('admin cannot set teacher display name', () async {
      final state = await AppState.createWithDatabase(db);
      state.setUnlocked(true, role: AppRole.admin);
      state.setAccountSession(1);
      expect(
        () => state.setTeacherDisplayName('Hack'),
        throwsA(isA<TeacherSettingsAccessDeniedException>()),
      );
    });
  });

  group('Settings authorization regression (P10)', () {
    test('student has locale access but not SMTP', () async {
      final classId = await db.insertStudentClass('10', '2025', section: 'A');
      final studentId = await db.insertStudent(
        classId: classId,
        number: 2,
        name: 'S2',
      );
      final state = await AppState.createWithDatabase(db);
      state.setStudentSession(classId: classId, studentId: studentId);
      state.setUnlocked(true, role: AppRole.student);
      final auth = AuthorizationService(state);
      expect(auth.canManageLocaleAndTheme, isTrue);
      expect(auth.canManageSmtpSettings, isFalse);
      expect(
        () => state.saveSmtpSettings(
          const SmtpSettings(
            host: 'x',
            port: 587,
            username: 'u',
            password: 'p',
            fromEmail: 'a@b.com',
            useSsl: false,
          ),
        ),
        throwsA(isA<TeacherSettingsAccessDeniedException>()),
      );
    });

    test('backup denied for student session', () async {
      final state = await AppState.createWithDatabase(db);
      state.setStudentSession(classId: 1, studentId: 1);
      state.setUnlocked(true, role: AppRole.student);
      expect(
        () => state.buildBackupBytes(),
        throwsA(isA<TeacherBackupAccessDeniedException>()),
      );
    });
  });

  group('Notification regression (P10)', () {
    test('markAsRead blocked for other recipient', () async {
      await db.insertInAppNotificationIdempotent(
        recipientRole: 'parent',
        recipientId: 2,
        title: 'Other',
        body: '',
        type: 'duyuru',
        dedupKey: 'p10:n',
      );
      final rows = await db.listInAppNotificationsForRecipient(
        recipientRole: 'parent',
        recipientId: 2,
        limit: 5,
      );
      final id = rows.first['id'] as int;
      final service = NotificationService(
        db,
        fixedRecipient: const NotificationRecipient(
          role: AppRole.parent,
          userId: 1,
        ),
      );
      expect(await service.markAsRead(id), isFalse);
    });
  });
}
