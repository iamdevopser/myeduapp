import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:my_edu_app/data/local/app_database.dart';
import 'package:my_edu_app/services/database_sync_service.dart';
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

  group('document folder sync (FAZ 6)', () {
    test('exportTables includes folder tables after icerikler', () {
      final tables = DatabaseSyncService.exportTables;
      final icerikIndex = tables.indexOf('icerikler');
      final folderIndex = tables.indexOf('dokuman_klasorleri');
      final junctionIndex = tables.indexOf('dokuman_klasor_ogeleri');
      expect(icerikIndex, greaterThanOrEqualTo(0));
      expect(folderIndex, greaterThan(icerikIndex));
      expect(junctionIndex, greaterThan(folderIndex));
    });

    test('json export and import preserves folders and links', () async {
      databaseFactory = databaseFactoryFfi;
      final sourceDb = AppDatabase('folder_sync_source_${DateTime.now().microsecondsSinceEpoch}.sqlite');
      await sourceDb.open();

      final classId = await sourceDb.insertClass('8.SINIFLAR');
      final lessonId = await sourceDb.insertLesson(classId, 'Matematik', 0);
      final contentId = await sourceDb.insertContent(
        lessonId: lessonId,
        topicId: null,
        name: 'Senkron.pdf',
        type: 'pdf',
        path: '/tmp/senkron.pdf',
        order: 0,
      );
      final folderId = await sourceDb.insertDocumentFolder('Yedek Klasör');
      await sourceDb.addContentToFolder(
        folderId: folderId,
        contentId: contentId,
      );

      final sync = DatabaseSyncService(sourceDb);
      final exported = await sync.exportData();
      expect(exported['databaseVersion'], 34);

      final folderRows =
          (exported['data'] as Map)['dokuman_klasorleri'] as List;
      final junctionRows =
          (exported['data'] as Map)['dokuman_klasor_ogeleri'] as List;
      expect(folderRows.length, 1);
      expect(junctionRows.length, 1);

      final tempDir = await Directory.systemTemp.createTemp('folder_sync_');
      final targetPath = p.join(tempDir.path, 'target.sqlite');
      final targetDb = AppDatabase(targetPath);
      await targetDb.open();
      final targetSync = DatabaseSyncService(targetDb);
      await targetSync.importData(_syncTableData(exported));

      final folders = await targetDb.getDocumentFolders();
      expect(folders.length, 1);
      expect(folders.first.name, 'Yedek Klasör');

      final contents = await targetDb.getFolderContents(folders.first.id);
      expect(contents.length, 1);
      expect(contents.first.item.name, 'Senkron.pdf');

      await sourceDb.close();
      await targetDb.close();
      await tempDir.delete(recursive: true);
    });

    test('importFromJsonString roundtrip matches exportData', () async {
      databaseFactory = databaseFactoryFfi;
      final db = AppDatabase('folder_json_roundtrip_${DateTime.now().microsecondsSinceEpoch}.sqlite');
      await db.open();

      final classId = await db.insertClass('8.SINIFLAR');
      final lessonId = await db.insertLesson(classId, 'Fizik', 0);
      final contentId = await db.insertContent(
        lessonId: lessonId,
        topicId: null,
        name: 'z.pdf',
        type: 'pdf',
        path: '/tmp/z.pdf',
        order: 0,
      );
      final folderId = await db.insertDocumentFolder('JSON');
      await db.addContentToFolder(folderId: folderId, contentId: contentId);

      final sync = DatabaseSyncService(db);
      final json = await sync.exportAsJsonString();

      await sync.importFromJsonString(json);

      final folders = await db.getDocumentFolders();
      expect(folders, hasLength(1));
      expect(folders.first.name, 'JSON');
      expect(await db.getFolderContents(folders.first.id), isNotEmpty);

      await db.close();
    });
  });

  group('document folder data integrity (FAZ 7)', () {
    late AppDatabase db;

    setUp(() async {
      databaseFactory = databaseFactoryFfi;
      db = AppDatabase(
        'folder_integrity_${DateTime.now().microsecondsSinceEpoch}.sqlite',
      );
      await db.open();
    });

    tearDown(() async {
      await db.close();
    });

    test('deleteContent cascades folder junction rows', () async {
      final classId = await db.insertClass('8.SINIFLAR');
      final lessonId = await db.insertLesson(classId, 'Matematik', 0);
      final contentId = await db.insertContent(
        lessonId: lessonId,
        topicId: null,
        name: 'sil.pdf',
        type: 'pdf',
        path: '/tmp/sil.pdf',
        order: 0,
      );
      final folderId = await db.insertDocumentFolder('Cascade');
      await db.addContentToFolder(folderId: folderId, contentId: contentId);

      await db.deleteContent(contentId);

      expect(await db.getFolderContents(folderId), isEmpty);
      final counts = await db.getDocumentFolderItemCounts();
      expect(counts[folderId], isNull);
    });

    test('addContentToFolder ignores duplicate junction', () async {
      final classId = await db.insertClass('8.SINIFLAR');
      final lessonId = await db.insertLesson(classId, 'Matematik', 0);
      final contentId = await db.insertContent(
        lessonId: lessonId,
        topicId: null,
        name: 'dup.pdf',
        type: 'pdf',
        path: '/tmp/dup.pdf',
        order: 0,
      );
      final folderId = await db.insertDocumentFolder('Tek');
      await db.addContentToFolder(folderId: folderId, contentId: contentId);
      await db.addContentToFolder(folderId: folderId, contentId: contentId);

      expect(await db.getFolderContents(folderId), hasLength(1));
      expect((await db.getDocumentFolderItemCounts())[folderId], 1);
    });

    test('legacy json without folder tables imports as empty folders', () async {
      final classId = await db.insertClass('8.SINIFLAR');
      final lessonId = await db.insertLesson(classId, 'Edebiyat', 0);
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
      data.remove('dokuman_klasorleri');
      data.remove('dokuman_klasor_ogeleri');
      final legacyPayload = {
        ...exported,
        'data': data,
      };
      final legacyJson = const JsonEncoder().convert(legacyPayload);

      await sync.importFromJsonString(legacyJson);

      expect(await db.getDocumentFolders(), isEmpty);
    });
  });
}
