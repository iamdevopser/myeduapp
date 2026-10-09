import 'package:crypto/crypto.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_edu_app/data/local/app_database.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  sqfliteFfiInit();

  late AppDatabase db;

  setUp(() async {
    databaseFactory = databaseFactoryFfi;
    db = AppDatabase('role_pw_${DateTime.now().microsecondsSinceEpoch}.sqlite');
    await db.open();
  });

  tearDown(() async {
    await db.close();
  });

  test('student and secretary password hashes persist in ayarlar', () async {
    final ogrenci = _hashPassword('ogrenci')!;
    final custom = _hashPassword('okul-2026')!;
    await db.setSetting('student_password_hash', custom);
    expect(await db.getSetting('student_password_hash'), custom);
    expect(custom, isNot(ogrenci));

    final sekreter = _hashPassword('sekreter')!;
    await db.setSetting('secretary_password_hash', sekreter);
    expect(await db.getSetting('secretary_password_hash'), sekreter);
  });
}

String? _hashPassword(String s) {
  if (s.isEmpty) return null;
  final bytes = s.runes.map((r) => r & 0xff).toList();
  return sha256.convert(bytes).toString();
}
