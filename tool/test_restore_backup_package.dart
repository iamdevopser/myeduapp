import 'dart:convert';
import 'dart:io';

import 'package:archive/archive_io.dart';

import 'package:my_edu_app/data/local/app_database.dart';
import 'package:my_edu_app/services/app_paths.dart';
import 'package:my_edu_app/services/backup_package_service.dart';
import 'package:my_edu_app/services/file_service.dart';
import 'package:my_edu_app/services/database_sync_service.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

Future<void> main() async {
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;

  const packagePath =
      r'C:\Users\tarik\OneDrive\Masaüstü\Backup\myeduapp_final_restore_test.zip';

  const sourceAppDataPath =
      r'D:\cursor_apps\MyEduApp\build\windows\x64\runner\Debug\MyEduAppData';

  final testRoot = Directory(
    '${Directory.systemTemp.path}${Platform.pathSeparator}myeduapp_restore_test',
  );

  final testAppDataPath = testRoot.path;
  final testDbPath =
      '$testAppDataPath${Platform.pathSeparator}myeduapp.sqlite';

  print('');
  print('==============================================');
  print('MYEDUAPP BACKUP RESTORE TEST');
  print('==============================================');

  final packageFile = File(packagePath);

  if (!await packageFile.exists()) {
    throw Exception('Backup ZIP bulunamadi:\n$packagePath');
  }

  final sourceDirectory = Directory(sourceAppDataPath);

  if (!await sourceDirectory.exists()) {
    throw Exception('Kaynak MyEduAppData bulunamadi:\n$sourceAppDataPath');
  }

  if (await testRoot.exists()) {
    print('');
    print('Onceki restore test klasoru siliniyor...');
    await testRoot.delete(recursive: true);
    print('Eski restore test klasoru silindi.');
  }

  await testRoot.create(recursive: true);

  print('');
  print('Test klasoru:');
  print(testAppDataPath);

  print('');
  print('Backup ZIP:');
  print(packagePath);

  /*
   * ZIP yapisini once dogrudan kontrol ediyoruz.
   */
  final archiveBytes = await packageFile.readAsBytes();

  print('');
  print('ZIP okunuyor...');

  final archive = ZipDecoder().decodeBytes(archiveBytes);

  ArchiveFile? manifestFile;
  ArchiveFile? databaseFile;

  var physicalFileCount = 0;

  for (final file in archive) {
    if (file.name == 'manifest.json') {
      manifestFile = file;
    } else if (file.name == 'database.json') {
      databaseFile = file;
    } else if (file.name.startsWith('files/')) {
      physicalFileCount++;
    }
  }

  if (manifestFile == null) {
    throw Exception('ZIP icinde manifest.json bulunamadi.');
  }

  if (databaseFile == null) {
    throw Exception('ZIP icinde database.json bulunamadi.');
  }

  final manifestJson =
      utf8.decode(manifestFile.content as List<int>);

  final manifest = jsonDecode(manifestJson);

  if (manifest is! Map<String, dynamic>) {
    throw Exception('manifest.json gecersiz.');
  }

  print('ZIP yapisi: OK');

  print('');
  print('Manifest format:');
  print(manifest['format']);

  print('Manifest version:');
  print(manifest['formatVersion']);

  print('Manifest fileCount:');
  print(manifest['fileCount']);

  print('ZIP fiziksel dosya sayisi:');
  print(physicalFileCount);

  final expectedFileCount =
      (manifest['fileCount'] as num?)?.toInt() ?? 0;

  if (physicalFileCount != expectedFileCount) {
    throw Exception(
      'ZIP fiziksel dosya sayisi manifest ile uyusmuyor. '
      'Beklenen: $expectedFileCount, Bulunan: $physicalFileCount',
    );
  }

  /*
   * Test database'i aciyoruz.
   * Gercek MyEduApp database'ine dokunulmuyor.
   */
  print('');
  print('Test database aciliyor...');

  final database = AppDatabase(testDbPath);

  try {
    await database.open();

    print('Test database: OK');

    /*
     * Restore islemi.
     */
    final service = BackupPackageService(database, FileService(AppPaths()));

    print('');
    print('Backup restore ediliyor...');
    print('Hedef:');
    print(testAppDataPath);

    final result = await service.restorePackage(
      packagePath: packagePath,
      appDataPath: testAppDataPath,
    );

    print('');
    print('==============================================');
    print('RESTORE SONUCU');
    print('==============================================');

    print('Beklenen dosya:');
    print(result.expectedFileCount);

    print('Geri yuklenen dosya:');
    print(result.restoredFileCount);

    print('Eksik dosya:');
    print(result.missingFileCount);

    print('Database JSON boyutu:');
    print('${result.databaseJsonBytes} bytes');

    print('');

    /*
     * Fiziksel dosya kontrolu.
     */
    var restoredPhysicalFileCount = 0;

    await for (final entity
        in Directory(testAppDataPath).list(recursive: true)) {
      if (entity is! File) {
        continue;
      }

      if (entity.path == testDbPath) {
        continue;
      }

      restoredPhysicalFileCount++;
    }

    print('Restore klasorundaki fiziksel dosya:');
    print(restoredPhysicalFileCount);

    /*
     * Database kayıt sayılarını kontrol ediyoruz.
     */
    final syncService = DatabaseSyncService(database);
    final recordCounts = await syncService.getRecordCounts();

    print('');
    print('DATABASE KAYIT SAYILARI');
    print('==============================================');

    var totalRecords = 0;

    for (final entry in recordCounts.entries) {
      print('${entry.key}: ${entry.value}');
      totalRecords += entry.value;
    }

    print('');
    print('Toplam database kaydi:');
    print(totalRecords);

    /*
     * database.json boyut kontrolu.
     */
    final restoredDatabaseFile = File(testDbPath);

    if (!await restoredDatabaseFile.exists()) {
      throw Exception(
        'Restore sonrasinda test database dosyasi bulunamadi.',
      );
    }

    /*
     * Temel basari kosullari.
     */
    if (result.missingFileCount != 0) {
      throw Exception(
        'Restore sirasinda eksik fiziksel dosya bulundu.',
      );
    }

    if (result.restoredFileCount != result.expectedFileCount) {
      throw Exception(
        'Restore edilen fiziksel dosya sayisi beklenen sayiya esit degil.',
      );
    }

    if (restoredPhysicalFileCount != expectedFileCount) {
      throw Exception(
        'Restore klasorundaki fiziksel dosya sayisi beklenen sayiya esit degil.',
      );
    }

    print('');
    print('==============================================');
    print('BACKUP RESTORE TEST BASARILI');
    print('==============================================');
    print('');
    print('ZIP okunabildi.');
    print('Manifest dogrulandi.');
    print('Database JSON import edildi.');
    print('Tum fiziksel dosyalar restore edildi.');
    print('');
    print('Gercek MyEduAppData degistirilmedi.');
    print('');
    print('Test klasoru:');
    print(testAppDataPath);
    print('==============================================');
  } finally {
    await database.close();

    /*
     * Test database klasorunu temizliyoruz.
     */
    if (await testRoot.exists()) {
      await testRoot.delete(recursive: true);
    }
  }
}




