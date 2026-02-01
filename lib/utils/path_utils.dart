String sanitizePathSegment(String input) {
  final sanitized = input.trim().replaceAll(RegExp(r'[\\/:*?"<>|]'), '_');
  return sanitized.isEmpty ? 'untitled' : sanitized;
}



