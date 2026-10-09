import 'package:flutter_test/flutter_test.dart';
import 'package:my_edu_app/data/local/app_database.dart';
import 'package:my_edu_app/data/models/student_behavior_definition.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  sqfliteFfiInit();

  late AppDatabase db;

  setUp(() async {
    databaseFactory = databaseFactoryFfi;
    db = AppDatabase(
      'behaviors_${DateTime.now().microsecondsSinceEpoch}.sqlite',
    );
    await db.open();
  });

  tearDown(() async {
    await db.close();
  });

  test('absent flag persists separately from empty score', () async {
    final classId = await db.insertStudentClass('7B', '2025-2026', section: 'B');
    final studentId = await db.insertStudent(
      classId: classId,
      number: 1,
      name: 'Ayşe',
    );
    final columnId = await db.insertScoreColumn(
      classId: classId,
      name: 'Aktivite 1',
      type: 'activity',
    );
    const dateKey = '2026-10-01';
    await db.setStudentScore(
      studentId: studentId,
      columnId: columnId,
      absent: true,
      date: dateKey,
    );
    final rows = await db.getStudentScores(classId, date: dateKey);
    final match = rows.firstWhere(
      (r) => r['ogrenci_id'] == studentId && r['kolon_id'] == columnId,
    );
    expect(match['not_deger'], isNull);
    expect(match['devamsiz'], 1);
  });

  test('behavior checkbox record is unique per student behavior date', () async {
    final classId = await db.insertStudentClass('8C', '2025-2026', section: 'C');
    final studentId = await db.insertStudent(
      classId: classId,
      number: 2,
      name: 'Mehmet',
    );
    final defs = await db.getBehaviorDefinitions();
    expect(defs.length, StudentBehaviorCatalog.defaults.length);
    final behaviorId = defs.first['id'] as int;
    const dateKey = '2026-10-02';

    await db.setStudentBehaviorChecked(
      classId: classId,
      studentId: studentId,
      behaviorId: behaviorId,
      date: dateKey,
      checked: true,
    );
    var keys = await db.getStudentBehaviorRecordKeys(
      classId: classId,
      date: dateKey,
    );
    expect(keys, contains('${studentId}_$behaviorId'));

    await db.setStudentBehaviorChecked(
      classId: classId,
      studentId: studentId,
      behaviorId: behaviorId,
      date: dateKey,
      checked: false,
    );
    keys = await db.getStudentBehaviorRecordKeys(
      classId: classId,
      date: dateKey,
    );
    expect(keys, isNot(contains('${studentId}_$behaviorId')));
  });

  test('behaviors system category is created for class', () async {
    final classId = await db.insertStudentClass('9D', '2025-2026', section: 'D');
    final categories = await db.getStudentCategories(classId);
    expect(
      categories.any((c) => c.code == 'behaviors'),
      isTrue,
    );
  });
}
