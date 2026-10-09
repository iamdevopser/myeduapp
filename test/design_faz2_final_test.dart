import 'package:flutter_test/flutter_test.dart';
import 'package:my_edu_app/data/local/app_database.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  test('schema version 35 adds kapak_gorsel_yolu to ogrenci_duyurular', () async {
    final db = AppDatabase(':memory:');
    await db.open();
    final cols = await db.database.rawQuery(
      "PRAGMA table_info(ogrenci_duyurular)",
    );
    final names = cols.map((c) => c['name'] as String).toSet();
    expect(names.contains('kapak_gorsel_yolu'), isTrue);
    await db.database.close();
  });

  test('secretary announcement persists kapak_gorsel_yolu', () async {
    final db = AppDatabase(':memory:');
    await db.open();
    final id = await db.insertSecretaryAnnouncement(
      title: 'Kapak test',
      body: 'İçerik',
      status: 'yayinda',
      targetType: 'tum_okul',
      coverImagePath: r'C:\fake\cover.png',
    );
    final row = await db.getStudentAnnouncementById(id);
    expect(row?['kapak_gorsel_yolu'], r'C:\fake\cover.png');
    await db.database.close();
  });
}
