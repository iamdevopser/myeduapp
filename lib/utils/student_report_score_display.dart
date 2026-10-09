/// Note / description column for report detail rows (UI, PDF, Excel).
String studentReportScoreDescription(Map<String, Object?> row) {
  final dateColumnDescription =
      (row['kolon_tarih_aciklama'] as String?)?.trim();
  if (dateColumnDescription != null && dateColumnDescription.isNotEmpty) {
    return dateColumnDescription;
  }
  return '';
}

/// Category column: include score column name (e.g. Aktivite 2) when distinct.
String studentReportScoreTypeLabel({
  required String categoryCode,
  required String categoryLabel,
  required String? columnName,
}) {
  final name = columnName?.trim();
  if (name == null || name.isEmpty) {
    return categoryLabel;
  }
  if (name == categoryLabel) {
    return categoryLabel;
  }
  const multiColumnTypes = {
    'activity',
    'materials',
    'homework',
    'exam',
  };
  if (multiColumnTypes.contains(categoryCode)) {
    return '$categoryLabel — $name';
  }
  return categoryLabel;
}
