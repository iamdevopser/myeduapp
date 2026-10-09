import '../l10n/app_localizations.dart';

/// Main teacher workspace sections.
enum TeacherNavSection {
  home,
  lessonPlatform,
  studentPlatform,
  academicPlans,
  mentorship,
  reports,
  userGuide,
  settings,
}

extension TeacherNavSectionLabels on TeacherNavSection {
  String title(AppLocalizations strings) {
    return switch (this) {
      TeacherNavSection.home => strings.t('homePage'),
      TeacherNavSection.lessonPlatform => strings.t('lessonPlatform'),
      TeacherNavSection.studentPlatform => strings.t('studentPlatform'),
      TeacherNavSection.academicPlans => strings.t('academicPlans'),
      TeacherNavSection.mentorship => strings.t('mentorship'),
      TeacherNavSection.reports => strings.t('reports'),
      TeacherNavSection.userGuide => strings.t('userGuide'),
      TeacherNavSection.settings => strings.t('settings'),
    };
  }
}
