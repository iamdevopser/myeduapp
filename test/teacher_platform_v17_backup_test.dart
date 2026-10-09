import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:my_edu_app/data/local/app_database.dart';
import 'package:my_edu_app/services/database_sync_service.dart';
import 'package:path/path.dart' as p;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

Map<String, List<Map<String, Object?>>> _syncTableData(
  Map<String, dynamic> syncData,
) {
  final raw = syncData['data'];
  if (raw is! Map<String, dynamic>) {
    throw const FormatException('export data missing');
  }
  return raw.map(
    (table, value) => MapEntry(
      table,
      (value as List)
          .map((row) => Map<String, Object?>.from(row as Map))
          .toList(),
    ),
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  sqfliteFfiInit();

  group('ogretmen platform backup restore (FAZ 7)', () {
    test('exportTables orders v17 tables after parent tables', () {
      final tables = DatabaseSyncService.exportTables;
      final icerikIndex = tables.indexOf('icerikler');
      final readingIndex = tables.indexOf('icerik_okuma');
      final studentClassIndex = tables.indexOf('ogrenci_siniflar');
      final notebookIndex = tables.indexOf('sinif_defteri_notlari');

      expect(icerikIndex, greaterThanOrEqualTo(0));
      expect(readingIndex, greaterThan(icerikIndex));
      expect(studentClassIndex, greaterThanOrEqualTo(0));
      expect(notebookIndex, greaterThan(studentClassIndex));
      expect(tables, contains('ogretmen_son_islemler'));
    });

    test('export import roundtrip preserves v17 teacher data', () async {
      databaseFactory = databaseFactoryFfi;
      final sourceDb = AppDatabase(
        'teacher_v17_backup_src_${DateTime.now().microsecondsSinceEpoch}.sqlite',
      );
      await sourceDb.open();

      final classId = await sourceDb.insertClass('8.SINIFLAR');
      final lessonId = await sourceDb.insertLesson(classId, 'Matematik', 0);
      final contentId = await sourceDb.insertContent(
        lessonId: lessonId,
        topicId: null,
        name: 'okuma.pdf',
        type: 'pdf',
        path: '/tmp/okuma.pdf',
        order: 0,
      );
      await sourceDb.upsertContentReadingProgress(
        contentId: contentId,
        lastPage: 12,
      );

      final studentClassId = await sourceDb.insertStudentClass(
        '9A',
        '2025-2026',
        section: 'A',
      );
      final noteId = await sourceDb.insertClassNotebookNote(
        classId: studentClassId,
        text: 'Ünite tekrarı yapıldı.',
        noteDate: '2025-09-21',
      );
      final activityId = await sourceDb.insertTeacherActivity(
        type: 'pdf_opened',
        title: 'okuma.pdf',
        targetType: 'content',
        targetId: contentId,
      );

      final sync = DatabaseSyncService(sourceDb);
      final exported = await sync.exportData();
      expect(exported['databaseVersion'], 34);

      final data = exported['data'] as Map<String, dynamic>;
      expect((data['icerik_okuma'] as List), isNotEmpty);
      expect((data['sinif_defteri_notlari'] as List), isNotEmpty);
      expect((data['ogretmen_son_islemler'] as List), isNotEmpty);

      final tempDir = await Directory.systemTemp.createTemp('teacher_v17_backup_');
      final targetPath = p.join(tempDir.path, 'target.sqlite');
      final targetDb = AppDatabase(targetPath);
      await targetDb.open();
      await DatabaseSyncService(targetDb).importData(_syncTableData(exported));

      final reading = await targetDb.getContentReadingProgress(contentId);
      expect(reading?.lastPage, 12);

      final notes = await targetDb.getClassNotebookNotes(studentClassId);
      expect(notes, hasLength(1));
      expect(notes.first.id, noteId);
      expect(notes.first.text, 'Ünite tekrarı yapıldı.');

      final activities = await targetDb.getRecentTeacherActivities(limit: 5);
      expect(activities.any((a) => a.id == activityId), isTrue);

      await sourceDb.close();
      await targetDb.close();
      await tempDir.delete(recursive: true);
    });

    test('legacy json without v17 tables imports without error', () async {
      databaseFactory = databaseFactoryFfi;
      final db = AppDatabase(
        'teacher_v17_legacy_${DateTime.now().microsecondsSinceEpoch}.sqlite',
      );
      await db.open();

      final classId = await db.insertClass('8.SINIFLAR');
      final lessonId = await db.insertLesson(classId, 'Fizik', 0);
      await db.insertContent(
        lessonId: lessonId,
        topicId: null,
        name: 'eski.pdf',
        type: 'pdf',
        path: '/tmp/eski.pdf',
        order: 0,
      );

      final sync = DatabaseSyncService(db);
      final exported = await sync.exportData();
      final data = Map<String, dynamic>.from(exported['data'] as Map);
      data.remove('icerik_okuma');
      data.remove('sinif_defteri_notlari');
      data.remove('ogretmen_son_islemler');
      final legacyPayload = {
        ...exported,
        'databaseVersion': 16,
        'data': data,
      };
      final legacyJson = const JsonEncoder().convert(legacyPayload);

      await sync.importFromJsonString(legacyJson);

      expect(await db.getRecentTeacherActivities(), isEmpty);
      final studentClasses = await db.getStudentClasses();
      if (studentClasses.isNotEmpty) {
        final sid = studentClasses.first['id'] as int;
        expect(await db.getClassNotebookNotes(sid), isEmpty);
      }

      await db.close();
    });

    test('teacher activity row kept when content target is deleted', () async {
      databaseFactory = databaseFactoryFfi;
      final db = AppDatabase(
        'teacher_v17_orphan_act_${DateTime.now().microsecondsSinceEpoch}.sqlite',
      );
      await db.open();

      final classId = await db.insertClass('8.SINIFLAR');
      final lessonId = await db.insertLesson(classId, 'Kimya', 0);
      final contentId = await db.insertContent(
        lessonId: lessonId,
        topicId: null,
        name: 'gone.pdf',
        type: 'pdf',
        path: '/tmp/gone.pdf',
        order: 0,
      );
      await db.insertTeacherActivity(
        type: 'pdf_opened',
        title: 'gone.pdf',
        targetType: 'content',
        targetId: contentId,
      );

      await db.deleteContent(contentId);

      final activities = await db.getRecentTeacherActivities(limit: 1);
      expect(activities, hasLength(1));
      expect(activities.first.targetId, contentId);
      expect(await db.getContentById(contentId), isNull);

      await db.close();
    });
  });
}
