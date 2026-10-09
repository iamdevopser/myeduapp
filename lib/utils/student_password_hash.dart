import 'package:crypto/crypto.dart';

/// Öğrenci giriş şifreleri (SHA-256, AppState ile uyumlu).
abstract final class StudentPasswordHash {
  /// Yeni kayıtlar ve migration için varsayılan portal şifresi.
  static const defaultPortalPassword = 'ogrenci';

  static String? hash(String plain) {
    if (plain.isEmpty) return null;
    final bytes = plain.runes.map((r) => r & 0xff).toList();
    return sha256.convert(bytes).toString();
  }

  static bool matches(String plain, String? storedHash) {
    final h = hash(plain);
    if (h == null || storedHash == null || storedHash.isEmpty) return false;
    return h == storedHash;
  }
}
