import 'dart:io';

import 'package:my_edu_app/data/local/app_database.dart';
import 'package:my_edu_app/services/app_paths.dart';
import 'package:my_edu_app/services/backup_package_service.dart';
import 'package:my_edu_app/services/file_service.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

Future<void> main() async {
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;

  const dbPath =
      r'D:\cursor_apps\MyEduApp\build\windows\x64\runner\Debug\MyEduAppData\myeduapp.sqlite';

  const appDataPath =
      r'D:\cursor_apps\MyEduApp\build\windows\x64\runner\Debug\MyEduAppData';

  const outputPath = r'D:\cursor_apps\MyEduApp\test_backup_v1.zip';

  print('');
  print('==============================================');
  print('MYEDUAPP BACKUP PACKAGE TEST');
  print('==============================================');

  final dbFile = File(dbPath);

  if (!await dbFile.exists()) {
    throw Exception('Database bulunamadi:\n$dbPath');
  }

  final appDataDirectory = Directory(appDataPath);

  if (!await appDataDirectory.exists()) {
    throw Exception('MyEduAppData klasoru bulunamadi:\n$appDataPath');
  }

  final oldPackage = File(outputPath);

  if (await oldPackage.exists()) {
    print('');
    print('Onceki test ZIP siliniyor...');
    await oldPackage.delete();
    print('Eski test ZIP silindi.');
  }

  final database = AppDatabase(dbPath);

  try {
    print('');
    print('Database aciliyor...');

    await database.open();

    print('Database: OK');

    final service = BackupPackageService(database, FileService(AppPaths()));

    print('');
    print('Backup paketi olusturuluyor...');
    print('Kaynak:');
    print(appDataPath);
    print('');
    print('Hedef:');
    print(outputPath);

    final result = await service.createPackage(
      outputPath: outputPath,
      appDataPath: appDataPath,
    );

    print('');
    print('==============================================');
    print('BACKUP PACKAGE SONUCU');
    print('==============================================');

    print('ZIP dosyasi:');
    print(result.outputPath);

    print('');
    print('Database JSON boyutu:');
    print('${result.databaseJsonBytes} bytes');

    print('');
    print('Beklenen fiziksel dosya:');
    print(result.expectedFileCount);

    print('ZIP icine eklenen dosya:');
    print(result.packagedFileCount);

    print('Eksik dosya:');
    print(result.missingFileCount);

    print('ZIP boyutu:');
    print('${result.packageSize} bytes');

    print('');

    if (!result.success) {
      throw Exception('Backup paketi eksik dosyalar nedeniyle basarisiz.');
    }

    final packageFile = File(outputPath);

    if (!await packageFile.exists()) {
      throw Exception('ZIP dosyasi olusturulamadi.');
    }

    print('==============================================');
    print('BACKUP PACKAGE TEST BASARILI');
    print('==============================================');
    print('');
    print('ZIP dosyasi:');
    print(outputPath);
    print('');
    print('Tum fiziksel dosyalar pakete eklendi.');
    print('==============================================');
  } finally {
    await database.close();
  }
}
