String sanitizePathSegment(String input) {
  var sanitized = input.trim();

  // Windows'ta geçersiz karakterleri "_" ile değiştir.
  sanitized = sanitized.replaceAll(RegExp(r'[\\/:*?"<>|]'), '_');

  // Windows'ta dosya/klasör adlarının sonunda nokta veya boşluk bulunamaz.
  sanitized = sanitized.replaceFirst(RegExp(r'[ .]+$'), '');

  // Boş kalırsa güvenli bir isim kullan.
  return sanitized.isEmpty ? 'untitled' : sanitized;
}

/// Report export dosya adı gövdesi (uzantı hariç): tab/çoklu boşluk → `_`, Win32 geçersiz karakterler.
String sanitizeReportFileStem(String input) {
  var sanitized = input.trim().replaceAll(RegExp(r'\s+'), '_');
  sanitized = sanitizePathSegment(sanitized);
  return sanitized.isEmpty ? 'rapor' : sanitized;
}
