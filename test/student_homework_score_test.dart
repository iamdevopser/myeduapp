import 'package:flutter_test/flutter_test.dart';
import 'package:my_edu_app/data/local/app_database.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  sqfliteFfiInit();

  late AppDatabase db;

  setUp(() async {
    databaseFactory = databaseFactoryFfi;
    db = AppDatabase(
      'homework_score_${DateTime.now().microsecondsSinceEpoch}.sqlite',
    );
    await db.open();
  });

  tearDown(() async {
    await db.close();
  });

  test('homework score persists for date and reloads from getStudentScores', () async {
    final classId = await db.insertStudentClass('6A', '2025-2026', section: 'A');
    final studentId = await db.insertStudent(
      classId: classId,
      number: 1,
      name: 'Ali Veli',
    );
    final columnId = await db.insertScoreColumn(
      classId: classId,
      name: 'Ödev 1',
      type: 'homework',
    );
    const dateKey = '2025-09-26';
    await db.setStudentScore(
      studentId: studentId,
      columnId: columnId,
      score: 8,
      done: 1,
      date: dateKey,
    );

    final rows = await db.getStudentScores(classId, date: dateKey);
    final match = rows.firstWhere(
      (r) => r['ogrenci_id'] == studentId && r['kolon_id'] == columnId,
    );
    expect(match['not_deger'], 8);
    expect(match['yapildi'], 1);

    await db.setStudentScore(
      studentId: studentId,
      columnId: columnId,
      score: 9,
      done: 1,
      date: dateKey,
    );
    final rows2 = await db.getStudentScores(classId, date: dateKey);
    final match2 = rows2.firstWhere(
      (r) => r['ogrenci_id'] == studentId && r['kolon_id'] == columnId,
    );
    expect(match2['not_deger'], 9);
  });
}
