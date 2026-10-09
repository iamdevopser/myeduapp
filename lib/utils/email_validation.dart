/// Pratik doğrulama: kurumsal alan adları (ör. @mail.orizont.md) dahil.
final _emailPattern = RegExp(
  r'^[^@\s]+@([A-Za-z0-9-]+\.)+[A-Za-z0-9-]{2,}$',
);

String? normalizeEmail(String? value) {
  var trimmed = value?.trim();
  if (trimmed == null || trimmed.isEmpty) return null;
  if (trimmed.toLowerCase().startsWith('mailto:')) {
    trimmed = trimmed.substring(7).trim();
  }
  // Sondaki noktalama (kopyala-yapıştır).
  trimmed = trimmed.replaceAll(RegExp(r'[,;]+$'), '');
  return trimmed.isEmpty ? null : trimmed;
}

bool isValidEmail(String? value) {
  final normalized = normalizeEmail(value);
  if (normalized == null) return false;
  final at = normalized.indexOf('@');
  if (at <= 0 || at >= normalized.length - 1) return false;
  if (normalized.contains(' ')) return false;
  return _emailPattern.hasMatch(normalized);
}
