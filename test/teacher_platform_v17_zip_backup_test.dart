import 'dart:convert';
import 'dart:io';

import 'package:archive/archive.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_edu_app/data/local/app_database.dart';
import 'package:my_edu_app/services/app_paths.dart';
import 'package:my_edu_app/services/backup_package_service.dart';
import 'package:my_edu_app/services/file_service.dart';
import 'package:path/path.dart' as p;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  sqfliteFfiInit();

  group('teacher platform v17 ZIP backup restore (E2E)', () {
    test(
      'createPackage and restorePackage preserve v17 data and physical files',
      () async {
        databaseFactory = databaseFactoryFfi;

        final runRoot = await Directory.systemTemp.createTemp(
          'teacher_v17_zip_${DateTime.now().microsecondsSinceEpoch}_',
        );
        final srcData = Directory(p.join(runRoot.path, 'src'));
        final dstData = Directory(p.join(runRoot.path, 'dst'));
        await srcData.create(recursive: true);
        await dstData.create(recursive: true);

        final relativePdf = 'Siniflar/8A/Matematik/Konu1/zip_e2e.pdf';
        final pdfOnDisk = File(
          p.join(srcData.path, relativePdf.replaceAll('/', p.separator)),
        );
        await pdfOnDisk.parent.create(recursive: true);
        final pdfBytes = <int>[0x25, 0x50, 0x44, 0x46, 0x2D, 0x31, 0x2E];
        await pdfOnDisk.writeAsBytes(pdfBytes);

        final srcDbPath = p.join(srcData.path, 'myeduapp.sqlite');
        final zipPath = p.join(runRoot.path, 'backup.zip');

        final srcDb = AppDatabase(srcDbPath);
        await srcDb.open();

        final classId = await srcDb.insertClass('8.SINIFLAR');
        final lessonId = await srcDb.insertLesson(classId, 'Matematik', 0);
        final unitId = await srcDb.insertUnit(
          lessonId: lessonId,
          number: 1,
          name: 'Ünite 1',
          order: 0,
        );
        final topicId = await srcDb.insertTopic(
          lessonId,
          'Konu 1',
          0,
          unitId: unitId,
        );

        final contentId = await srcDb.insertContent(
          lessonId: lessonId,
          topicId: topicId,
          name: 'zip_e2e.pdf',
          type: 'pdf',
          path: relativePdf,
          order: 0,
        );
        final homeworkId = await srcDb.insertContent(
          lessonId: lessonId,
          topicId: topicId,
          name: 'zip_odev.pdf',
          type: 'homework',
          path: relativePdf,
          order: 1,
        );

        await srcDb.upsertContentReadingProgress(
          contentId: contentId,
          lastPage: 9,
        );

        final parentFolderId = await srcDb.insertDocumentFolder('ZIP Kök');
        final childFolderId = await srcDb.insertDocumentFolder(
          'ZIP Alt',
          parentId: parentFolderId,
        );
        await srcDb.addContentToFolder(
          folderId: childFolderId,
          contentId: contentId,
        );
        await srcDb.addContentToFolder(
          folderId: childFolderId,
          contentId: homeworkId,
        );

        final studentClassId = await srcDb.insertStudentClass(
          '8A',
          '2025-2026',
          section: 'A',
        );
        final noteId = await srcDb.insertClassNotebookNote(
          classId: studentClassId,
          text: 'ZIP E2E defter notu',
          noteDate: '2025-09-20',
        );
        final activityId = await srcDb.insertTeacherActivity(
          type: 'class_notebook_note',
          title: 'Defter',
          targetType: 'class_notebook_note',
          targetId: noteId,
        );

        final fileService = FileService(AppPaths());
        final backupService = BackupPackageService(srcDb, fileService);

        final packageResult = await backupService.createPackage(
          outputPath: zipPath,
          appDataPath: srcData.path,
        );
        expect(packageResult.success, isTrue);
        expect(packageResult.missingFileCount, 0);
        expect(await File(zipPath).exists(), isTrue);

        await srcDb.close();

        final archiveBytes = await File(zipPath).readAsBytes();
        final archive = ZipDecoder().decodeBytes(archiveBytes);

        ArchiveFile? manifestEntry;
        ArchiveFile? databaseEntry;
        final zipFileEntries = <ArchiveFile>[];

        for (final file in archive) {
          if (file.name == 'manifest.json') {
            manifestEntry = file;
          } else if (file.name == 'database.json') {
            databaseEntry = file;
          } else if (file.name.startsWith('files/')) {
            zipFileEntries.add(file);
          }
        }

        expect(manifestEntry, isNotNull);
        expect(databaseEntry, isNotNull);

        final manifest = jsonDecode(
          utf8.decode(manifestEntry!.content as List<int>),
        ) as Map<String, dynamic>;
        expect(manifest['format'], BackupPackageService.packageFormat);
        expect(manifest['databaseVersion'], 34);
        expect(manifest['checksumAlgorithm'], BackupPackageService.checksumAlgorithm);

        final checksums = manifest['fileChecksums'] as Map<String, dynamic>?;
        expect(checksums, isNotNull);
        expect(checksums!.isNotEmpty, isTrue);

        final dbJson = jsonDecode(
          utf8.decode(databaseEntry!.content as List<int>),
        ) as Map<String, dynamic>;
        expect(dbJson['databaseVersion'], 34);

        final data = dbJson['data'] as Map<String, dynamic>;
        for (final table in [
          'dokuman_klasorleri',
          'dokuman_klasor_ogeleri',
          'icerik_okuma',
          'sinif_defteri_notlari',
          'ogretmen_son_islemler',
        ]) {
          expect(data.containsKey(table), isTrue, reason: 'missing $table');
          expect((data[table] as List), isNotEmpty, reason: 'empty $table');
        }

        final folders = data['dokuman_klasorleri'] as List;
        expect(
          folders.any((row) => (row as Map)['parent_id'] != null),
          isTrue,
          reason: 'nested folder expected',
        );
        expect((data['dokuman_klasor_ogeleri'] as List).length, 2);

        final zipPdfEntry = zipFileEntries.firstWhere(
          (f) => f.name.endsWith('zip_e2e.pdf'),
          orElse: () => throw StateError('PDF missing under files/ in ZIP'),
        );
        final relativeInZip = zipPdfEntry.name.substring('files/'.length);
        final forwardPath = BackupPackageService.toBackupZipEntryPath(
          relativeInZip,
        );
        expect(
          checksums![forwardPath],
          BackupPackageService.sha256Hex(zipPdfEntry.content as List<int>),
        );
        expect(
          BackupPackageService.sha256Hex(pdfBytes),
          checksums[forwardPath],
        );

        for (final row in data['icerikler'] as List) {
          final path = (row as Map)['dosya_yolu'] as String;
          expect(path.contains('\\'), isFalse);
          expect(path.contains(':'), isFalse);
        }

        final dstDbPath = p.join(dstData.path, 'myeduapp.sqlite');
        final dstDb = AppDatabase(dstDbPath);
        await dstDb.open();

        final restoreService = BackupPackageService(dstDb, fileService);
        final restoreResult = await restoreService.restorePackage(
          packagePath: zipPath,
          appDataPath: dstData.path,
        );

        expect(restoreResult.missingFileCount, 0);
        expect(
          restoreResult.restoredFileCount,
          restoreResult.expectedFileCount,
        );

        final reading = await dstDb.getContentReadingProgress(contentId);
        expect(reading?.lastPage, 9);

        final folderPath = await dstDb.getDocumentFolderPath(childFolderId);
        expect(folderPath.length, greaterThanOrEqualTo(2));

        final folderContents = await dstDb.getFolderContents(childFolderId);
        expect(folderContents.length, 2);

        final notes = await dstDb.getClassNotebookNotes(studentClassId);
        expect(notes.length, 1);
        expect(notes.first.text, 'ZIP E2E defter notu');

        final activities = await dstDb.getRecentTeacherActivities(limit: 10);
        expect(activities.any((a) => a.id == activityId), isTrue);

        final restoredPdf = File(
          p.join(dstData.path, relativePdf.replaceAll('/', p.separator)),
        );
        expect(await restoredPdf.exists(), isTrue);
        expect(await restoredPdf.readAsBytes(), pdfBytes);

        await dstDb.close();
        await runRoot.delete(recursive: true);
      },
    );
  });
}
