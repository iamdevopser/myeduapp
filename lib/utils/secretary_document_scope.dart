/// Sekreter belgesi `belge_kapsam` alanına göre öğrenci/sınıf görünürlüğü.
bool secretaryDocumentVisibleToStudentClass({
  required String? scope,
  required int classId,
  required String className,
  String? section,
}) {
  final trimmed = scope?.trim();
  if (trimmed == null || trimmed.isEmpty) return true;
  final lower = trimmed.toLowerCase();
  if (lower.contains('tüm okul') || lower.contains('all school')) {
    return true;
  }
  if (scope!.startsWith('sinif:')) {
    final id = int.tryParse(scope.substring(6).trim());
    return id != null && id == classId;
  }
  final displayClass = () {
    final s = section?.trim();
    if (s != null && s.isNotEmpty) return '$className-$s';
    return className;
  }();
  final label = displayClass.toLowerCase();
  if (lower.contains(label)) return true;
  if (lower.contains(className.toLowerCase())) return true;
  return false;
}
