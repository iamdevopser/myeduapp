import 'dart:convert';
import 'dart:io';

import 'package:archive/archive_io.dart';
import 'package:path/path.dart' as p;
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

  final testRoot = Directory(
    '${Directory.systemTemp.path}${Platform.pathSeparator}myeduapp_path_test',
  );

  if (await testRoot.exists()) {
    await testRoot.delete(recursive: true);
  }

  await testRoot.create(recursive: true);

  print('');
  print('==============================================');
  print('MYEDUAPP DOSYA YOLU RESTORE TEST');
  print('==============================================');

  final databasePath =
      '${testRoot.path}${Platform.pathSeparator}myeduapp.sqlite';

  final database = AppDatabase(databasePath);

  try {
    await database.open();

    final service = BackupPackageService(database, FileService(AppPaths()));

    print('');
    print('Backup restore ediliyor...');
    print(testRoot.path);

    final result = await service.restorePackage(
      packagePath: packagePath,
      appDataPath: testRoot.path,
    );

    print('');
    print('Restore tamamlandi.');
    print('Restore edilen dosya: ${result.restoredFileCount}');
    print('Eksik dosya: ${result.missingFileCount}');

    final syncService = DatabaseSyncService(database);
    final syncData = await syncService.exportData();

    final rawData = syncData['data'];

    if (rawData is! Map<String, dynamic>) {
      throw Exception('Database export data alani gecersiz.');
    }

    final contents = rawData['icerikler'];

    if (contents is! List) {
      throw Exception('icerikler verisi bulunamadi.');
    }

    print('');
    print('==============================================');
    print('ICERIK -> DOSYA YOLU KONTROLU');
    print('==============================================');

    var checked = 0;
    var missing = 0;

    for (final item in contents) {
      if (item is! Map) {
        continue;
      }

      final id = item['id'];
      final name = item['ad'];
      final rawPath = item['dosya_yolu'];

      if (rawPath is! String || rawPath.trim().isEmpty) {
        continue;
      }

      final normalized = rawPath
          .replaceAll('/', Platform.pathSeparator)
          .replaceAll('\\', Platform.pathSeparator);

      final filePath = File(
        '${testRoot.path}${Platform.pathSeparator}$normalized',
      );

      final exists = await filePath.exists();

      print('');
      print('ID       : $id');
      print('Ad       : $name');
      print('Database : $rawPath');
      print('Fiziksel : ${filePath.path}');
      print('Mevcut   : $exists');

      checked++;

      if (!exists) {
        missing++;
      }
    }

    print('');
    print('==============================================');
    print('SONUC');
    print('==============================================');
    print('Kontrol edilen icerik : $checked');
    print('Eksik fiziksel dosya  : $missing');

    final physicalFiles = <File>[];

    await for (final entity in testRoot.list(recursive: true)) {
      if (entity is File &&
          !p.equals(entity.path, databasePath)) {
        physicalFiles.add(entity);
      }
    }

    print('Restore fiziksel dosya: ${physicalFiles.length}');

    if (missing != 0) {
      throw Exception(
        'Database dosya yollarindan bazilari fiziksel dosyaya karsilik gelmiyor.',
      );
    }

    if (physicalFiles.length != checked) {
      throw Exception(
        'Restore edilen fiziksel dosya sayisi ile database icerik sayisi uyusmuyor.',
      );
    }

    print('');
    print('==============================================');
    print('DOSYA YOLU RESTORE TEST BASARILI');
    print('==============================================');
  } finally {
    await database.close();

    print('');
    print('Test klasoru temizleniyor...');
    if (await testRoot.exists()) {
      await testRoot.delete(recursive: true);
    }
    print('Test klasoru temizlendi.');
  }
}

