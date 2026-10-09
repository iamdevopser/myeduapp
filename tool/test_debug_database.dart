import 'dart:io';

import 'package:my_edu_app/data/local/app_database.dart';
import 'package:my_edu_app/services/database_sync_service.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

Future<void> main() async {
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;

  const dbPath =
      r'D:\cursor_apps\MyEduApp\build\windows\x64\runner\Debug\MyEduAppData\myeduapp.sqlite';

  final file = File(dbPath);

  print('');
  print('==============================================');
  print('DEBUG DATABASE TEST');
  print('==============================================');
  print('Database: $dbPath');

  if (!await file.exists()) {
    print('Database bulunamadi.');
    return;
  }

  print('Database bulundu.');
  print('Boyut: ${await file.length()} bytes');

  final database = AppDatabase(dbPath);

  try {
    await database.open();

    print('Database acildi.');

    final syncService = DatabaseSyncService(database);
    final counts = await syncService.getRecordCounts();

    print('');
    print('KAYIT SAYILARI');
    print('----------------------------------------------');

    for (final entry in counts.entries) {
      print('${entry.key.padRight(24)} ${entry.value}');
    }

    print('----------------------------------------------');
  } finally {
    await database.close();
  }
}
