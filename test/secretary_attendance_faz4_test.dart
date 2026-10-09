import 'package:flutter_test/flutter_test.dart';
import 'package:my_edu_app/data/local/app_database.dart';
import 'package:my_edu_app/models/app_role.dart';
import 'package:my_edu_app/providers/app_state.dart';
import 'package:my_edu_app/services/authorization_service.dart';
import 'package:my_edu_app/services/secretary_attendance_service.dart';
import 'package:my_edu_app/utils/attendance_status.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;

  late AppDatabase db;
  late SecretaryAttendanceService service;

  setUp(() async {
    db = AppDatabase('faz4_${DateTime.now().microsecondsSinceEpoch}.sqlite');
    await db.open();
    service = SecretaryAttendanceService(db);
  });

  tearDown(() async {
    await db.close();
  });

  test('schema version 31 includes ogrenci_devamsizlik', () async {
    final v = await db.database.rawQuery('PRAGMA user_version');
    expect(v.first['user_version'], 35);
    final tables = await db.database.rawQuery(
      "SELECT name FROM sqlite_master WHERE type='table' AND name='ogrenci_devamsizlik'",
    );
    expect(tables.length, 1);
  });

  test('insert update and duplicate prevention same student date', () async {
    final classId = await db.insertStudentClass('7', '2025', section: 'A');
    final studentId = await db.insertStudent(
      classId: classId,
      number: 1,
      name: 'Test Öğrenci',
    );
    final date = attendanceDateKey(DateTime(2025, 3, 10));

    await db.setStudentDailyAttendance(
      studentId: studentId,
      dateKey: date,
      status: 'yok',
    );
    await db.setStudentDailyAttendance(
      studentId: studentId,
      dateKey: date,
      status: 'izinli',
    );

    final rows = await db.listDailyAttendanceForStudent(studentId: studentId);
    expect(rows.length, 1);
    expect(rows.first['durum'], 'izinli');

    await db.setStudentDailyAttendance(
      studentId: studentId,
      dateKey: date,
      status: 'var',
    );
    final cleared = await db.listDailyAttendanceForStudent(studentId: studentId);
    expect(cleared, isEmpty);
  });

  test('attendance list by date and filters', () async {
    final classA = await db.insertStudentClass('7', '2025', section: 'A');
    final classB = await db.insertStudentClass('8', '2025', section: 'B');
    final s1 = await db.insertStudent(classId: classA, number: 1, name: 'A');
    final s2 = await db.insertStudent(classId: classB, number: 2, name: 'B');
    final day = DateTime(2025, 4, 1);

    await service.setStudentStatus(
      studentId: s1,
      date: day,
      status: AttendanceStatus.absent,
    );

    final all = await service.loadDaily(date: day);
    expect(all.length, 2);
    expect(
      all.firstWhere((r) => r.studentId == s1).status,
      AttendanceStatus.absent,
    );
    expect(
      all.firstWhere((r) => r.studentId == s2).status,
      AttendanceStatus.present,
    );

    final grade7 = await service.loadDaily(
      date: day,
      gradeFilter: 7,
    );
    expect(grade7.length, 1);
    expect(grade7.first.studentId, s1);
  });

  test('bulk update and history', () async {
    final classId = await db.insertStudentClass('6', '2025', section: 'C');
    final s1 = await db.insertStudent(classId: classId, number: 3, name: 'C1');
    final s2 = await db.insertStudent(classId: classId, number: 4, name: 'C2');
    final day = DateTime(2025, 5, 15);

    await service.bulkSetStatus(
      studentIds: [s1, s2],
      date: day,
      status: AttendanceStatus.absent,
    );

    final history = await service.loadHistory(
      from: day,
      to: day,
      studentIdFilter: null,
    );
    expect(history.length, 2);

    await service.bulkSetStatus(
      studentIds: [s1, s2],
      date: day,
      status: AttendanceStatus.present,
    );
    final cleared = await service.loadHistory(from: day, to: day);
    expect(cleared, isEmpty);
  });

  test('student attendance history and summary', () async {
    final classId = await db.insertStudentClass('5', '2025', section: 'D');
    final studentId = await db.insertStudent(
      classId: classId,
      number: 9,
      name: 'Özet',
    );
    await service.setStudentStatus(
      studentId: studentId,
      date: DateTime(2025, 1, 1),
      status: AttendanceStatus.absent,
    );
    await service.setStudentStatus(
      studentId: studentId,
      date: DateTime(2025, 1, 2),
      status: AttendanceStatus.excused,
    );
    await service.setStudentStatus(
      studentId: studentId,
      date: DateTime(2025, 1, 3),
      status: AttendanceStatus.absent,
    );

    final hist = await service.studentHistory(studentId: studentId);
    expect(hist.length, 3);
    final summary = await service.studentSummary(studentId);
    expect(summary.absentCount, 2);
    expect(summary.excusedCount, 1);
  });

  test('secretary authorization for attendance', () async {
    final state = await AppState.createWithDatabase(db);
    state.setUnlocked(true, role: AppRole.secretary);
    final auth = AuthorizationService(state);
    expect(auth.canViewAttendance, isTrue);
    expect(auth.canCreateAttendance, isTrue);
    expect(auth.canEditAttendance, isTrue);
    expect(auth.canDeleteAttendance, isFalse);

    state.setUnlocked(true, role: AppRole.student);
    final studentAuth = AuthorizationService(state);
    expect(studentAuth.canCreateAttendance, isFalse);
  });
}
