import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../l10n/app_localizations.dart';
import '../providers/app_state.dart';
import '../data/models/lesson_model.dart';
import '../screens/app_viewer_screen.dart';
import '../screens/student_portal/student_announcement_detail_screen.dart';
import '../screens/student_portal/student_portal_scope.dart';
import '../screens/student_portal/student_tab_workspace.dart';
import '../services/student_portal_service.dart';
import 'student_nav_section.dart';

export 'student_nav_section.dart';

extension StudentNavSectionLabels on StudentNavSection {
  String label(AppLocalizations strings) {
    return switch (this) {
      StudentNavSection.home => strings.t('studentPortalHome'),
      StudentNavSection.courses => strings.t('studentPortalCourses'),
      StudentNavSection.academicPlansWeekly =>
        strings.t('studentPortalWeeklySchedule'),
      StudentNavSection.assignments => strings.t('studentPortalAssignments'),
      StudentNavSection.exams => strings.t('studentPortalExams'),
      StudentNavSection.performance => strings.t('studentPortalPerformance'),
      StudentNavSection.attendance => strings.t('studentPortalAttendance'),
      StudentNavSection.documents => strings.t('studentPortalDocuments'),
      StudentNavSection.announcements => strings.t('studentPortalAnnouncements'),
      StudentNavSection.profile => strings.t('studentPortalProfile'),
      StudentNavSection.lessonPlatform => strings.t('goToApp'),
    };
  }

  IconData get icon {
    return switch (this) {
      StudentNavSection.home => Icons.home_outlined,
      StudentNavSection.courses => Icons.menu_book_outlined,
      StudentNavSection.academicPlansWeekly => Icons.calendar_view_week_outlined,
      StudentNavSection.assignments => Icons.assignment_outlined,
      StudentNavSection.exams => Icons.quiz_outlined,
      StudentNavSection.performance => Icons.insights_outlined,
      StudentNavSection.attendance => Icons.event_busy_outlined,
      StudentNavSection.documents => Icons.folder_open_outlined,
      StudentNavSection.announcements => Icons.campaign_outlined,
      StudentNavSection.profile => Icons.person_outline,
      StudentNavSection.lessonPlatform => Icons.auto_stories_outlined,
    };
  }
}

void navigateStudentSection(BuildContext context, StudentNavSection section) {
  final appState = context.read<AppState>();
  appState.openStudentSection(section);
  if (!_isInsideStudentTabWorkspace(context)) {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const StudentTabWorkspace()),
    );
  }
}

bool _isInsideStudentTabWorkspace(BuildContext context) {
  return context.findAncestorWidgetOfExactType<StudentTabWorkspace>() != null;
}

void openStudentPortal(BuildContext context) {
  context.read<AppState>().openStudentSection(StudentNavSection.home);
  Navigator.of(context).pushReplacement(
    MaterialPageRoute(builder: (_) => const StudentTabWorkspace()),
  );
}

Future<void> openStudentLessonPlatform(
  BuildContext context, {
  int? lessonId,
}) async {
  final state = context.read<AppState>();
  if (lessonId != null) {
    final row = await state.db.getLessonRow(lessonId);
    if (row != null) {
      await state.openCourse(LessonModel.fromMap(row));
    }
  }
  if (!context.mounted) return;
  Navigator.of(context).push(
    MaterialPageRoute(
      builder: (_) => const AppViewerScreen(),
      settings: const RouteSettings(
        arguments: {'studentLessonViewer': true},
      ),
    ),
  );
}

bool studentLessonViewerRoute(BuildContext context) {
  final args = ModalRoute.of(context)?.settings.arguments;
  return args is Map && args['studentLessonViewer'] == true;
}

void openStudentAnnouncementDetail(
  BuildContext context,
  StudentPortalAnnouncement announcement,
) {
  final scope = StudentPortalScope.of(context);
  Navigator.of(context).push<void>(
    MaterialPageRoute(
      builder: (_) => StudentPortalScope(
        enrollments: scope.enrollments,
        primary: scope.primary,
        child: StudentAnnouncementDetailScreen(announcement: announcement),
      ),
    ),
  );
}

Future<void> openStudentAnnouncementDetailById(
  BuildContext context,
  int announcementId,
) async {
  final strings = AppLocalizations.of(context);
  final scope = StudentPortalScope.of(context);
  final service = StudentPortalService(context.read<AppState>().db);
  final item = await service.loadAnnouncementById(
    announcementId,
    enrollments: scope.enrollments,
  );
  if (!context.mounted) return;
  if (item == null) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(strings.t('designAnnouncementNotFound'))),
    );
    return;
  }
  openStudentAnnouncementDetail(context, item);
}

Future<void> openStudentPortalDocument(
  BuildContext context,
  StudentPortalDocument document,
) async {
  final strings = AppLocalizations.of(context);
  final state = context.read<AppState>();
  final ok = await state.prepareStudentContentViewer(document.contentId);
  if (!context.mounted) return;
  if (!ok) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(strings.t('designDocumentOpenFailed'))),
    );
    return;
  }
  await Navigator.of(context).push<void>(
    MaterialPageRoute(
      builder: (_) => const AppViewerScreen(),
      settings: const RouteSettings(
        arguments: {'studentLessonViewer': true},
      ),
    ),
  );
}
