import 'dart:io';

import 'package:my_edu_app/data/local/app_database.dart';
import 'package:my_edu_app/services/database_sync_service.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

Future<void> main() async {
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;

  const jsonPath = r'D:\cursor_apps\MyEduApp\test_sync.json';

  const testDbPath = r'D:\cursor_apps\MyEduApp\test_import.sqlite';

  print('');
  print('==============================================');
  print('MYEDUAPP JSON IMPORT TEST');
  print('==============================================');

  final jsonFile = File(jsonPath);

  print('');
  print('JSON:');
  print(jsonPath);

  if (!await jsonFile.exists()) {
    throw Exception('test_sync.json bulunamadi:\n$jsonPath');
  }

  print('JSON dosyasi: OK');
  print('JSON boyutu: ${await jsonFile.length()} bytes');

  final oldTestDb = File(testDbPath);

  if (await oldTestDb.exists()) {
    print('');
    print('Onceki test database siliniyor...');
    await oldTestDb.delete();
    print('Eski test database silindi.');
  }

  print('');
  print('Yeni test database olusturuluyor...');
  print(testDbPath);

  AppDatabase? database;

  try {
    database = AppDatabase(testDbPath);

    await database.open();

    print('Database: OK');

    final syncService = DatabaseSyncService(database);

    print('');
    print('==============================================');
    print('IMPORT ONCESI');
    print('==============================================');

    final beforeCounts = await syncService.getRecordCounts();

    for (final entry in beforeCounts.entries) {
      print('  ${entry.key.padRight(24)} ${entry.value}');
    }

    print('');
    print('JSON import ediliyor...');

    await syncService.importFromFile(jsonPath);

    print('IMPORT BASARILI');

    print('');
    print('==============================================');
    print('IMPORT SONRASI');
    print('==============================================');

    final afterCounts = await syncService.getRecordCounts();

    for (final entry in afterCounts.entries) {
      print('  ${entry.key.padRight(24)} ${entry.value}');
    }

    print('');
    print('==============================================');
    print('KAYIT KONTROLU');
    print('==============================================');

    const expected = <String, int>{
      'siniflar': 2,
      'dersler': 1,
      'konular': 3,
      'icerikler': 17,
      'etiketler': 0,
      'icerik_etiketleri': 0,
      'ayarlar': 4,
      'favoriler': 0,
      'sinavlar': 0,
      'sorular': 0,
      'soru_bankasi': 0,
      'notlar': 0,
      'ogrenci_siniflar': 2,
      'ogrenciler': 4,
      'not_kolonlari': 3,
      'ogrenci_notlari': 1,
    };

    var allMatch = true;

    for (final table in expected.keys) {
      final expectedCount = expected[table]!;
      final actualCount = afterCounts[table] ?? -1;

      final match = expectedCount == actualCount;

      if (!match) {
        allMatch = false;
      }

      print(
        '${match ? '[OK]' : '[HATA]'} '
        '${table.padRight(24)} '
        'beklenen=$expectedCount '
        'gercek=$actualCount',
      );
    }

    print('');

    if (allMatch) {
      print('==============================================');
      print('IMPORT TEST BASARILI');
      print('==============================================');
      print('');
      print('SQLite -> JSON -> SQLite dongusu BASARILI.');
      print('');
      print('Test database:');
      print(testDbPath);
      print('');
      print('Gercek uygulama databaseine dokunulmadi.');
      print('==============================================');
    } else {
      print('==============================================');
      print('IMPORT TEST BASARISIZ');
      print('==============================================');
      exitCode = 1;
    }
  } catch (e, stackTrace) {
    print('');
    print('==============================================');
    print('IMPORT HATASI');
    print('==============================================');
    print(e);
    print('');
    print(stackTrace);
    exitCode = 1;
  } finally {
    await database?.close();
  }
}
