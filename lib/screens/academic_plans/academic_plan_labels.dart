import '../../l10n/app_localizations.dart';

String academicPlanSubjectLabel(Map<String, Object?> row) {
  final lesson = row['ders_ad'] as String?;
  if (lesson != null && lesson.trim().isNotEmpty) {
    return lesson.trim();
  }
  return (row['konu_metin'] as String? ?? '').trim();
}

String academicPlanClassLabel(Map<String, Object?> row) {
  final name = row['ogrenci_sinif_ad'] as String?;
  final section = row['ogrenci_sube'] as String?;
  if (name != null && name.trim().isNotEmpty) {
    final s = section?.trim();
    if (s != null && s.isNotEmpty) {
      return '${name.trim()} $s';
    }
    return name.trim();
  }
  return (row['sinif_metin'] as String? ?? '').trim();
}

String weeklyDayLabel(AppLocalizations strings, int day) {
  if (day < 1 || day > 5) return '$day';
  return switch (day) {
    1 => strings.t('weekdayMonday'),
    2 => strings.t('weekdayTuesday'),
    3 => strings.t('weekdayWednesday'),
    4 => strings.t('weekdayThursday'),
    5 => strings.t('weekdayFriday'),
    _ => '$day',
  };
}
