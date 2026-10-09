import 'package:flutter/material.dart';
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
    db = AppDatabase('p9_${DateTime.now().microsecondsSinceEpoch}.sqlite');
    await db.open();
  });

  tearDown(() async {
    await db.close();
  });

  group('Settings authorization (P9)', () {
    test('teacher can change locale and portal passwords', () async {
      final state = await AppState.createWithDatabase(db);
      state.setUnlocked(true, role: AppRole.teacher);
      await state.setLocale(const Locale('en'));
      expect(state.locale.languageCode, 'en');
      await state.setTeacherPassword('secret1');
      await state.setStudentPassword('secret2');
      await state.setSecretaryPassword('secret3');
    });

    test('student cannot set portal passwords or SMTP', () async {
      final classId = await db.insertStudentClass('9', '2025', section: 'A');
      final studentId = await db.insertStudent(
        classId: classId,
        number: 1,
        name: 'P9 Student',
      );
      final state = await AppState.createWithDatabase(db);
      state.setStudentSession(classId: classId, studentId: studentId);
      state.setUnlocked(true, role: AppRole.student);

      expect(
        () => state.setTeacherPassword('x'),
        throwsA(isA<TeacherSettingsAccessDeniedException>()),
      );
      expect(
        () => state.setStudentPassword('x'),
        throwsA(isA<TeacherSettingsAccessDeniedException>()),
      );
      expect(
        () => state.saveSmtpSettings(
          const SmtpSettings(
            host: 'smtp.test',
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

    test('student can change locale when session is valid', () async {
      final classId = await db.insertStudentClass('9', '2025', section: 'B');
      final studentId = await db.insertStudent(
        classId: classId,
        number: 2,
        name: 'Locale Student',
      );
      final state = await AppState.createWithDatabase(db);
      state.setStudentSession(classId: classId, studentId: studentId);
      state.setUnlocked(true, role: AppRole.student);
      await state.setLocale(const Locale('en'));
      expect(state.locale.languageCode, 'en');
    });

    test('display locale can be changed before sign-in and persists',
        () async {
      final state = await AppState.createWithDatabase(db);
      await state.setDisplayLocale(const Locale('ru'));
      expect(state.locale.languageCode, 'ru');
      expect(await db.getSetting('locale'), 'ru');

      await state.setDisplayLocale(const Locale('de'));
      expect(state.locale.languageCode, 'ru');
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

    test('authorization flags gate teacher-only settings', () async {
      final teacher = await AppState.createWithDatabase(db);
      teacher.setUnlocked(true, role: AppRole.teacher);
      final teacherAuth = AuthorizationService(teacher);
      expect(teacherAuth.canManageTeacherWorkspaceSettings, isTrue);
      expect(teacherAuth.canManageSmtpSettings, isTrue);
      expect(teacherAuth.canManagePortalPasswords, isTrue);
      expect(teacherAuth.canManageBackupRestore, isTrue);

      final classId = await db.insertStudentClass('10', '2025', section: 'A');
      final studentId = await db.insertStudent(
        classId: classId,
        number: 3,
        name: 'Auth Student',
      );
      final student = await AppState.createWithDatabase(db);
      student.setStudentSession(classId: classId, studentId: studentId);
      student.setUnlocked(true, role: AppRole.student);
      final studentAuth = AuthorizationService(student);
      expect(studentAuth.canManageLocaleAndTheme, isTrue);
      expect(studentAuth.canManageTeacherWorkspaceSettings, isFalse);
      expect(studentAuth.canManageBackupRestore, isFalse);
    });
  });

  group('Notification Center (P9)', () {
    test('markAsRead blocked for other recipient', () async {
      await db.insertInAppNotificationIdempotent(
        recipientRole: 'student',
        recipientId: 1,
        title: 'Mine',
        body: '',
        type: 'duyuru',
        dedupKey: 'p9:a',
      );
      await db.insertInAppNotificationIdempotent(
        recipientRole: 'student',
        recipientId: 2,
        title: 'Other',
        body: '',
        type: 'duyuru',
        dedupKey: 'p9:b',
      );
      final rows = await db.listInAppNotificationsForRecipient(
        recipientRole: 'student',
        recipientId: 2,
        limit: 10,
      );
      final otherId = rows.first['id'] as int;

      final service = NotificationService(
        db,
        fixedRecipient: const NotificationRecipient(
          role: AppRole.student,
          userId: 1,
        ),
      );
      expect(await service.markAsRead(otherId), isFalse);
    });

    test('notification service lists only current recipient', () async {
      await db.insertInAppNotificationIdempotent(
        recipientRole: 'student',
        recipientId: 99,
        title: 'Scoped',
        body: '',
        type: 'duyuru',
        dedupKey: 'p9:scope',
      );
      final service = NotificationService(
        db,
        fixedRecipient: const NotificationRecipient(
          role: AppRole.student,
          userId: 99,
        ),
      );
      final list = await service.listForCurrentUser();
      expect(list.length, 1);
      expect(list.first.title, 'Scoped');
    });
  });
}
