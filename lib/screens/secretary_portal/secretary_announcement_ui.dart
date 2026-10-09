import '../../l10n/app_localizations.dart';
import '../../utils/student_announcement_meta.dart';

String announcementStatusLabel(
  AppLocalizations strings,
  StudentAnnouncementStatus status,
) {
  return switch (status) {
    StudentAnnouncementStatus.draft => strings.t('announcementStatusDraft'),
    StudentAnnouncementStatus.published => strings.t(
      'announcementStatusPublished',
    ),
    StudentAnnouncementStatus.unpublished => strings.t(
      'announcementStatusUnpublished',
    ),
  };
}

String announcementTargetLabel(
  AppLocalizations strings,
  StudentAnnouncementTargetType type,
) {
  return switch (type) {
    StudentAnnouncementTargetType.allSchool => strings.t(
      'announcementTargetAllSchool',
    ),
    StudentAnnouncementTargetType.grade => strings.t('studentClassName'),
    StudentAnnouncementTargetType.section => strings.t('studentClassSection'),
  };
}
