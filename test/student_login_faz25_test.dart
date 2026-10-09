import 'package:flutter_test/flutter_test.dart';
import 'package:my_edu_app/data/local/app_database.dart';
import 'package:my_edu_app/providers/app_state.dart';
import 'package:my_edu_app/utils/course_form_options.dart';
import 'package:my_edu_app/utils/student_password_hash.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;

  late AppDatabase db;
  late AppState state;

  setUp(() async {
    db = AppDatabase(
      'student_login_faz25_${DateTime.now().microsecondsSinceEpoch}.sqlite',
    );
    await db.open();
    state = await AppState.createWithDatabase(db);
  });

  tearDown(() async {
    await db.close();
  });

  test('authenticateStudent accepts number and personal password', () async {
    final classId = await db.insertStudentClass(
      CourseFormOptions.gradeLabel(8),
      '2025-2026',
      section: 'A',
    );
    final hash = StudentPasswordHash.hash('sifre-123')!;
    await db.insertStudent(
      classId: classId,
      number: 42,
      name: 'Ayşe Test',
      passwordHash: hash,
    );

    final auth = await db.authenticateStudent(
      studentNumber: 42,
      passwordPlain: 'sifre-123',
    );
    expect(auth, isNotNull);
    expect(auth!.studentId, greaterThan(0));
    expect(auth.classId, classId);
  });

  test('wrong password is rejected', () async {
    final classId = await db.insertStudentClass(
      '7',
      '2025-2026',
      section: 'B',
    );
    await db.insertStudent(
      classId: classId,
      number: 5,
      name: 'Ali',
      passwordHash: StudentPasswordHash.hash('dogru'),
    );
    final auth = await db.authenticateStudent(
      studentNumber: 5,
      passwordPlain: 'yanlis',
    );
    expect(auth, isNull);
  });

  test('loginStudent sets session fields via AppState', () async {
    final classId = await db.insertStudentClass(
      '6',
      '2025-2026',
      section: 'C',
    );
    final studentId = await db.insertStudent(
      classId: classId,
      number: 11,
      name: 'Zeynep',
      passwordHash: StudentPasswordHash.hash('portal'),
    );

    final login = await state.loginStudent(
      studentNumber: 11,
      password: 'portal',
    );
    expect(login.success, isTrue);
    state.setStudentSession(
      classId: login.classId!,
      studentId: login.studentId!,
    );
    expect(state.sessionStudentId, studentId);
    expect(state.sessionClassId, classId);

    state.clearSession();
    expect(state.sessionStudentId, isNull);
    expect(state.sessionClassId, isNull);
  });

  test('ambiguous same number rejects login', () async {
    final classA = await db.insertStudentClass('5', '2025', section: 'A');
    final classB = await db.insertStudentClass('5', '2025', section: 'B');
    final hash = StudentPasswordHash.hash('ortak')!;
    await db.insertStudent(
      classId: classA,
      number: 99,
      name: 'Bir',
      passwordHash: hash,
    );
    await db.insertStudent(
      classId: classB,
      number: 99,
      name: 'İki',
      passwordHash: hash,
    );
    final auth = await db.authenticateStudent(
      studentNumber: 99,
      passwordPlain: 'ortak',
    );
    expect(auth, isNull);
  });
}
