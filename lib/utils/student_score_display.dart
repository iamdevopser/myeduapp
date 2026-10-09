/// Öğrenci not hücresi gösterimi: 1–10, devamsızlık (`a`), boş (`—`).
String formatStudentScoreDisplay({
  int? numericScore,
  bool absent = false,
}) {
  if (absent) {
    return 'a';
  }
  if (numericScore != null && numericScore >= 1 && numericScore <= 10) {
    return '$numericScore';
  }
  return '—';
}

bool studentScoreRowIsAbsent(Map<String, Object?> row) {
  return (row['devamsiz'] as int? ?? 0) == 1;
}
