import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:my_edu_app/data/local/app_database.dart';
import 'package:my_edu_app/services/database_sync_service.dart';
import 'package:path/path.dart' as p;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

/// FAZ 8 — migration, schema version, acceptance checks (doc §13–14, §12).
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  sqfliteFfiInit();

  group('ogretmen platform faz 8', () {
    test('fresh database uses current schema version with v17 tables', () async {
      databaseFactory = databaseFactoryFfi;
      final db = AppDatabase(
        'faz8_fresh_${DateTime.now().microsecondsSinceEpoch}.sqlite',
      );
      await db.open();

      final versionRows = await db.database.rawQuery('PRAGMA user_version');
      expect(versionRows.first['user_version'], 35);

      final tableRows = await db.database.rawQuery(
        '''
        SELECT name FROM sqlite_master
        WHERE type = 'table'
          AND name IN (
            'icerik_okuma',
            'sinif_defteri_notlari',
            'ogretmen_son_islemler',
            'dokuman_klasorleri',
            'dokuman_klasor_ogeleri'
          )
        ORDER BY name
        ''',
      );
      expect(tableRows.length, 5);

      await db.close();
    });

    test('v16 to v17 upgrade recreates v17 tables additively', () async {
      databaseFactory = databaseFactoryFfi;
      final tempDir = await Directory.systemTemp.createTemp('faz8_migrate_');
      final path = p.join(tempDir.path, 'migrate.sqlite');

      final db = AppDatabase(path);
      await db.open();

      final classId = await db.insertClass('8.SINIFLAR');
      final lessonId = await db.insertLesson(classId, 'Mat', 0);
      final contentId = await db.insertContent(
        lessonId: lessonId,
        topicId: null,
        name: 'keep.pdf',
        type: 'pdf',
        path: '/tmp/keep.pdf',
        order: 0,
      );

      await db.database.execute('DROP TABLE IF EXISTS icerik_okuma');
      await db.database.execute('DROP TABLE IF EXISTS sinif_defteri_notlari');
      await db.database.execute('DROP TABLE IF EXISTS ogretmen_son_islemler');
      await db.database.execute('PRAGMA user_version = 16');
      await db.close();

      final upgraded = AppDatabase(path);
      await upgraded.open();

      final versionRows = await upgraded.database.rawQuery('PRAGMA user_version');
      expect(versionRows.first['user_version'], 35);

      final contentRow = await upgraded.getContentById(contentId);
      expect(contentRow, isNotNull);
      expect(contentRow!['ad'], 'keep.pdf');

      await upgraded.upsertContentReadingProgress(
        contentId: contentId,
        lastPage: 3,
      );
      expect(
        (await upgraded.getContentReadingProgress(contentId))?.lastPage,
        3,
      );

      await upgraded.close();
      await tempDir.delete(recursive: true);
    });

    test('sync metadata version matches database version', () {
      expect(DatabaseSyncService.databaseVersion, 34);
    });

    test('acceptance: folder junction does not duplicate content rows', () async {
      databaseFactory = databaseFactoryFfi;
      final db = AppDatabase(
        'faz8_accept_${DateTime.now().microsecondsSinceEpoch}.sqlite',
      );
      await db.open();

      final classId = await db.insertClass('8.SINIFLAR');
      final lessonId = await db.insertLesson(classId, 'Fizik', 0);
      final contentId = await db.insertContent(
        lessonId: lessonId,
        topicId: null,
        name: 'one.pdf',
        type: 'pdf',
        path: '/tmp/one.pdf',
        order: 0,
      );
      final folderA = await db.insertDocumentFolder('A');
      final folderB = await db.insertDocumentFolder('B');
      await db.addContentToFolder(folderId: folderA, contentId: contentId);
      await db.addContentToFolder(folderId: folderB, contentId: contentId);

      final countRows = await db.database.rawQuery(
        'SELECT COUNT(*) as c FROM icerikler WHERE id = ?',
        [contentId],
      );
      expect(countRows.first['c'], 1);
      expect(await db.getFolderContents(folderA), hasLength(1));
      expect(await db.getFolderContents(folderB), hasLength(1));

      await db.close();
    });
  });
}
