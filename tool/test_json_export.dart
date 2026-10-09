import 'dart:io';

import 'package:my_edu_app/data/local/app_database.dart';
import 'package:my_edu_app/services/database_sync_service.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

Future<void> main() async {
  print('');
  print('==============================================');
  print('MYEDUAPP JSON EXPORT TEST');
  print('==============================================');

  // Dart CLI ortamÄ±nda sqflite FFI database factory'sini baÅŸlat.
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;

  const dbPath =
      r'D:\cursor_apps\MyEduApp\build\windows\x64\runner\Debug\\MyEduAppData\\myeduapp.sqlite';

  const jsonPath = r'D:\cursor_apps\MyEduApp\test_sync.json';

  final dbFile = File(dbPath);

  print('');
  print('Database:');
  print(dbPath);

  if (!await dbFile.exists()) {
    throw Exception('MyEduApp database dosyasi bulunamadi:\n$dbPath');
  }

  print('Database dosyasi: OK');
  print('Database boyutu: ${await dbFile.length()} bytes');

  AppDatabase? database;

  try {
    print('');
    print('Database aciliyor...');

    database = AppDatabase(dbPath);

    await database.open();

    print('Database: OK');

    final syncService = DatabaseSyncService(database);

    print('');
    print('Mevcut kayit sayilari:');

    final counts = await syncService.getRecordCounts();

    for (final entry in counts.entries) {
      print('  ${entry.key.padRight(24)} ${entry.value}');
    }

    print('');
    print('JSON olusturuluyor...');
    print('Hedef: $jsonPath');

    await syncService.exportToFile(jsonPath);

    final jsonFile = File(jsonPath);

    if (!await jsonFile.exists()) {
      throw Exception('JSON dosyasi olusturulamadi.');
    }

    print('');
    print('==============================================');
    print('EXPORT BASARILI');
    print('==============================================');
    print('JSON dosyasi:');
    print(jsonPath);
    print('JSON boyutu: ${await jsonFile.length()} bytes');
    print('==============================================');
    print('');
  } catch (e, stackTrace) {
    print('');
    print('==============================================');
    print('EXPORT HATASI');
    print('==============================================');
    print(e);
    print('');
    print(stackTrace);
    print('==============================================');
    print('');
    exitCode = 1;
  } finally {
    await database?.close();
  }
}
