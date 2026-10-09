import 'package:flutter_test/flutter_test.dart';
import 'package:my_edu_app/data/local/app_database.dart';
import 'package:my_edu_app/models/app_role.dart';
import 'package:my_edu_app/providers/app_state.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;

  late AppState state;
  late AppDatabase db;

  setUp(() async {
    db = AppDatabase('role_sess_${DateTime.now().microsecondsSinceEpoch}.sqlite');
    await db.open();
    state = await AppState.createWithDatabase(db);
  });

  tearDown(() async {
    await db.close();
  });

  test('setUnlocked teacher sets role and isTeacher', () {
    state.setUnlocked(true, role: AppRole.teacher);
    expect(state.isUnlocked, isTrue);
    expect(state.isTeacher, isTrue);
    expect(state.isStudent, isFalse);
    expect(state.isSecretary, isFalse);
    expect(state.currentRole, AppRole.teacher);
  });

  test('setUnlocked student sets role', () {
    state.setUnlocked(true, role: AppRole.student);
    expect(state.isStudent, isTrue);
    expect(state.isTeacher, isFalse);
    expect(state.isSecretary, isFalse);
  });

  test('setUnlocked secretary sets role', () {
    state.setUnlocked(true, role: AppRole.secretary);
    expect(state.isSecretary, isTrue);
    expect(state.isTeacher, isFalse);
    expect(state.isStudent, isFalse);
  });

  test('setUnlocked parent sets role', () {
    state.setUnlocked(true, role: AppRole.parent);
    expect(state.isParent, isTrue);
    expect(state.isStudent, isFalse);
    expect(state.isTeacher, isFalse);
  });

  test('clearSession resets role and student session', () {
    state.setUnlocked(true, role: AppRole.student);
    state.setStudentSession(classId: 1, studentId: 42);
    state.clearSession();
    expect(state.isUnlocked, isFalse);
    expect(state.currentRole, isNull);
    expect(state.sessionStudentId, isNull);
    expect(state.sessionClassId, isNull);
  });

  test('teacher role clears student session ids', () {
    state.setUnlocked(true, role: AppRole.student);
    state.setStudentSession(classId: 1, studentId: 42);
    state.setUnlocked(true, role: AppRole.teacher);
    expect(state.sessionStudentId, isNull);
    expect(state.sessionClassId, isNull);
  });

  test('legacy isTeacher parameter maps to role', () {
    state.setUnlocked(true, isTeacher: false);
    expect(state.currentRole, AppRole.student);
    state.setUnlocked(true, isTeacher: true);
    expect(state.currentRole, AppRole.teacher);
  });
}
