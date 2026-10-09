import 'dart:io';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

Future<void> main() async {
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;

  final db = await databaseFactory.openDatabase(
    r'D:\cursor_apps\MyEduApp\build\windows\x64\runner\Debug\MyEduAppData\myeduapp.sqlite',
  );

  final rows = await db.query(
    'icerikler',
    columns: ['id', 'ad', 'tur', 'dosya_yolu'],
  );

  print('');
  print('==============================================');
  print('GERCEK ICERIK KAYITLARI');
  print('==============================================');

  if (rows.isEmpty) {
    print('icerikler tablosu BOS.');
  } else {
    for (final row in rows) {
      print('');
      print('ID       : ${row['id']}');
      print('Ad       : ${row['ad']}');
      print('Tur      : ${row['tur']}');
      print('Dosya    : ${row['dosya_yolu']}');
    }
  }

  print('');
  print('Toplam kayit: ${rows.length}');

  await db.close();
}
