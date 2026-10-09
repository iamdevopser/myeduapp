import 'package:flutter_test/flutter_test.dart';
import 'package:my_edu_app/data/local/app_database.dart';
import 'package:my_edu_app/services/database_sync_service.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  sqfliteFfiInit();

  late AppDatabase db;

  setUp(() async {
    databaseFactory = databaseFactoryFfi;
    db = AppDatabase(
      'teacher_v17_${DateTime.now().microsecondsSinceEpoch}.sqlite',
    );
    await db.open();
  });

  tearDown(() async {
    await db.close();
  });

  group('v17 tables', () {
    test('fresh database exposes reading, notebook and activity tables', () async {
      final reading = await db.getContentReadingProgress(999);
      expect(reading, isNull);
      expect(await db.getClassNotebookNotes(1), isEmpty);
      expect(await db.getRecentTeacherActivities(), isEmpty);
    });
  });

  group('content reading', () {
    test('upsert and read last page', () async {
      final classId = await db.insertClass('8.SINIFLAR');
      final lessonId = await db.insertLesson(classId, 'Mat', 0);
      final contentId = await db.insertContent(
        lessonId: lessonId,
        topicId: null,
        name: 'a.pdf',
        type: 'pdf',
        path: '/tmp/a.pdf',
        order: 0,
      );
      await db.upsertContentReadingProgress(contentId: contentId, lastPage: 37);
      await db.upsertContentReadingProgress(contentId: contentId, lastPage: 40);
      final progress = await db.getContentReadingProgress(contentId);
      expect(progress?.lastPage, 40);
      final map = await db.getContentReadingPages([contentId]);
      expect(map[contentId], 40);
    });

    test('deleteContent removes icerik_okuma row', () async {
      final classId = await db.insertClass('8.SINIFLAR');
      final lessonId = await db.insertLesson(classId, 'Mat', 0);
      final contentId = await db.insertContent(
        lessonId: lessonId,
        topicId: null,
        name: 'b.pdf',
        type: 'pdf',
        path: '/tmp/b.pdf',
        order: 0,
      );
      await db.upsertContentReadingProgress(contentId: contentId, lastPage: 2);
      await db.deleteContent(contentId);
      expect(await db.getContentReadingProgress(contentId), isNull);
    });
  });

  group('class notebook', () {
    test('notes are scoped per class and cascade on class delete', () async {
      final classRows = await db.getStudentClasses();
      final classId = await db.insertStudentClass(
        '9A',
        '2025-2026',
        section: 'A',
      );
      await db.insertClassNotebookNote(
        classId: classId,
        text: 'Fonksiyonlar işlendi.',
        noteDate: '2025-09-20',
      );
      final notes = await db.getClassNotebookNotes(classId);
      expect(notes, hasLength(1));
      expect(notes.first.noteDate, '2025-09-20');
      await db.deleteStudentClass(classId);
      expect(await db.getClassNotebookNotes(classId), isEmpty);
      expect(classRows, isA<List>());
    });

    test('update and delete note by id', () async {
      final classId = await db.insertStudentClass(
        '9B',
        '2025-2026',
        section: 'B',
      );
      final noteId = await db.insertClassNotebookNote(
        classId: classId,
        text: 'Ilk metin',
        noteDate: '2025-09-20',
      );
      await db.updateClassNotebookNote(
        noteId: noteId,
        text: 'Guncel metin',
        noteDate: '2025-09-21',
      );
      final notes = await db.getClassNotebookNotes(classId);
      expect(notes.single.text, 'Guncel metin');
      expect(notes.single.noteDate, '2025-09-21');

      await db.deleteClassNotebookNote(noteId);
      expect(await db.getClassNotebookNotes(classId), isEmpty);
    });
  });

  group('teacher activities', () {
    test('homework_created activity persists with content target', () async {
      await db.insertTeacherActivity(
        type: 'homework_created',
        title: 'Ödev oluşturuldu: Deneme',
        targetType: 'content',
        targetId: 42,
      );
      final recent = await db.getRecentTeacherActivities(limit: 1);
      expect(recent.single.type, 'homework_created');
      expect(recent.single.targetId, 42);
    });

    test('trim keeps most recent rows', () async {
      for (var i = 0; i < 105; i++) {
        await db.insertTeacherActivity(
          type: 'test',
          title: 'Event $i',
          createdAt: DateTime.utc(2025, 1, 1, 0, 0, i),
        );
      }
      final countRows = await db.database.rawQuery(
        'SELECT COUNT(*) as cnt FROM ogretmen_son_islemler',
      );
      final count = countRows.first['cnt'] as int?;
      expect(count, 100);
      final recent = await db.getRecentTeacherActivities(limit: 3);
      expect(recent.first.title, 'Event 104');
    });
  });

  group('folder batch', () {
    test('addContentsToFolderBatch skips duplicates', () async {
      final classId = await db.insertClass('8.SINIFLAR');
      final lessonId = await db.insertLesson(classId, 'Mat', 0);
      final c1 = await db.insertContent(
        lessonId: lessonId,
        topicId: null,
        name: '1.pdf',
        type: 'pdf',
        path: '/tmp/1.pdf',
        order: 0,
      );
      final c2 = await db.insertContent(
        lessonId: lessonId,
        topicId: null,
        name: '2.pdf',
        type: 'pdf',
        path: '/tmp/2.pdf',
        order: 1,
      );
      final folderId = await db.insertDocumentFolder('Batch');
      final first = await db.addContentsToFolderBatch(
        folderId: folderId,
        contentIds: [c1, c2, c1],
      );
      expect(first, 2);
      final second = await db.addContentsToFolderBatch(
        folderId: folderId,
        contentIds: [c1],
      );
      expect(second, 0);
      expect((await db.getFolderContents(folderId)), hasLength(2));
    });
  });

  group('sync', () {
    test('export includes v17 tables', () async {
      expect(DatabaseSyncService.databaseVersion, 34);
      expect(DatabaseSyncService.exportTables, contains('icerik_okuma'));
      expect(DatabaseSyncService.exportTables, contains('sinif_defteri_notlari'));
      expect(
        DatabaseSyncService.exportTables,
        contains('ogretmen_son_islemler'),
      );
      final sync = DatabaseSyncService(db);
      final exported = await sync.exportData();
      expect(exported['databaseVersion'], 34);
      final data = exported['data'] as Map;
      expect(data['icerik_okuma'], isA<List>());
      expect(data['sinif_defteri_notlari'], isA<List>());
      expect(data['ogretmen_son_islemler'], isA<List>());
    });
  });
}
