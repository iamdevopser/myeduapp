import 'package:flutter_test/flutter_test.dart';
import 'package:my_edu_app/data/local/app_database.dart';
import 'package:my_edu_app/providers/app_state.dart';
import 'package:my_edu_app/services/account_service.dart';
import 'package:my_edu_app/services/secretary_student_service.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;

  late AppDatabase db;
  late int classId;
  late int studentId;

  setUp(() async {
    db = AppDatabase(
      'student_account_${DateTime.now().microsecondsSinceEpoch}.sqlite',
    );
    await db.open();
    classId = await db.insertStudentClass('9', '2025', section: 'A');
    studentId = await db.insertStudent(
      classId: classId,
      number: 42,
      name: 'Test Öğrenci',
    );
    await SecretaryStudentService(db).createStudentPortalAccountIfNeeded(
      studentId: studentId,
      name: 'Test Öğrenci',
      passwordPlain: '1111',
      portalUsername: 'Test',
    );
  });

  tearDown(() async {
    await db.close();
  });

  test('student signs in with portal username and password', () async {
    final state = await AppState.createWithDatabase(db);
    final login = await state.loginStudentAccount(
      login: 'test',
      password: '1111',
    );
    expect(login.success, isTrue);
    expect(login.studentId, studentId);
    expect(login.classId, classId);
  });

  test('wrong password or unknown username is rejected', () async {
    final state = await AppState.createWithDatabase(db);
    expect(
      (await state.loginStudentAccount(
        login: 'Test',
        password: '9999',
      )).success,
      isFalse,
    );
    expect(
      (await state.loginStudentAccount(
        login: 'nobody',
        password: '1111',
      )).success,
      isFalse,
    );
  });

  test(
    'taken portal username is rejected before the student is saved',
    () async {
      final service = SecretaryStudentService(db);
      await expectLater(
        service.validateStudentPortalAccount(portalUsername: 'TEST'),
        throwsA(
          isA<AccountValidationException>().having(
            (e) => e.messageKey,
            'messageKey',
            'adminAccountUsernameTaken',
          ),
        ),
      );
      await service.validateStudentPortalAccount(portalUsername: 'test.ogr');
      await service.validateStudentPortalAccount(portalUsername: '  ');
    },
  );

  test('student number login still works with the same password', () async {
    final state = await AppState.createWithDatabase(db);
    final login = await state.loginStudent(studentNumber: 42, password: '1111');
    expect(login.success, isTrue);
    expect(login.studentId, studentId);
  });
}
