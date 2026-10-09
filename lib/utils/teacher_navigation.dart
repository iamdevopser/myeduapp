import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../l10n/app_localizations.dart';
import '../providers/app_state.dart';
import '../screens/app_builder_screen.dart';
import '../screens/app_viewer_screen.dart';
import '../screens/settings_screen.dart';
import '../screens/student_platform_screen.dart';
import '../screens/mentorship_class_select_screen.dart';
import '../screens/mentorship_dashboard_screen.dart';
import '../screens/student_report_screen.dart';
import '../screens/teacher_menu_screen.dart';
import '../screens/user_guide_screen.dart';
import 'academic_plans_navigation.dart';
import 'teacher_nav_section.dart';
import '../screens/academic_plans/academic_plans_screen.dart';
import 'app_navigation.dart';

/// Ders Platformu sidebar alt menü seviyeleri.
enum LessonPlatformSidebarSection {
  subjects,
  courses,
  units,
  topics,
  documents,
}

/// Sidebar alt menü sırası (enum `.values` yerine sabit liste).
const List<LessonPlatformSidebarSection> lessonPlatformSidebarMenuOrder =
    <LessonPlatformSidebarSection>[
  LessonPlatformSidebarSection.subjects,
  LessonPlatformSidebarSection.courses,
  LessonPlatformSidebarSection.units,
  LessonPlatformSidebarSection.topics,
];

extension LessonPlatformSidebarSectionLabels on LessonPlatformSidebarSection {
  String label(AppLocalizations strings) {
    return switch (this) {
      LessonPlatformSidebarSection.subjects => strings.t('subjects'),
      LessonPlatformSidebarSection.courses => strings.t('courses'),
      LessonPlatformSidebarSection.units => strings.t('units'),
      LessonPlatformSidebarSection.topics => strings.t('topics'),
      LessonPlatformSidebarSection.documents => strings.t('documents'),
    };
  }

  IconData get icon {
    return switch (this) {
      LessonPlatformSidebarSection.subjects => Icons.auto_stories_outlined,
      LessonPlatformSidebarSection.courses => Icons.library_books_outlined,
      LessonPlatformSidebarSection.units => Icons.view_module_outlined,
      LessonPlatformSidebarSection.topics => Icons.topic_outlined,
      LessonPlatformSidebarSection.documents => Icons.insert_drive_file_outlined,
    };
  }
}

/// Keeps open teacher sections alive in an [IndexedStack].
class TeacherTabWorkspace extends StatelessWidget {
  const TeacherTabWorkspace({super.key});

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    if (!appState.isTeacher || !appState.isUnlocked) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (context.mounted) leaveWorkspaceToLogin(context);
      });
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }
    final tabs = appState.openTeacherTabs;
    final active = appState.activeTeacherTab;
    final index = tabs.indexOf(active);
    return IndexedStack(
      index: index < 0 ? 0 : index,
      sizing: StackFit.expand,
      children: [
        for (final section in tabs) _teacherSectionWidget(section),
      ],
    );
  }

  static Widget _teacherSectionWidget(TeacherNavSection section) {
    return switch (section) {
      TeacherNavSection.home => const TeacherMenuScreen(),
      TeacherNavSection.lessonPlatform => const AppViewerScreen(),
      TeacherNavSection.studentPlatform => const StudentPlatformScreen(),
      TeacherNavSection.academicPlans => const AcademicPlansScreen(),
      TeacherNavSection.mentorship => const MentorshipClassSelectScreen(),
      TeacherNavSection.reports => const StudentReportScreen(),
      TeacherNavSection.userGuide => const UserGuideScreen(),
      TeacherNavSection.settings => const SettingsScreen(),
    };
  }
}

bool _isInsideTeacherTabWorkspace(BuildContext context) {
  return context.findAncestorWidgetOfExactType<TeacherTabWorkspace>() != null;
}

void navigateTeacherSection(BuildContext context, TeacherNavSection section) {
  final appState = context.read<AppState>();
  appState.openTeacherTab(section);
  if (!_isInsideTeacherTabWorkspace(context)) {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const TeacherTabWorkspace()),
    );
  }
}

void openLessonBuilder(BuildContext context) {
  Navigator.of(context).push(
    MaterialPageRoute(builder: (_) => const AppBuilderScreen()),
  );
}

void openStudentPlatform(BuildContext context, {int? classId}) {
  final appState = context.read<AppState>();
  appState.openTeacherTab(TeacherNavSection.studentPlatform);
  if (_isInsideTeacherTabWorkspace(context)) {
    return;
  }
  Navigator.of(context).pushReplacement(
    MaterialPageRoute(
      builder: (_) => StudentPlatformScreen(initialClassId: classId),
    ),
  );
}

void openReports(BuildContext context, {int? classId}) {
  final appState = context.read<AppState>();
  appState.openTeacherTab(TeacherNavSection.reports);
  if (_isInsideTeacherTabWorkspace(context)) {
    return;
  }
  Navigator.of(context).push(
    MaterialPageRoute(
      builder: (_) => StudentReportScreen(initialClassId: classId),
    ),
  );
}

void openAcademicPlans(
  BuildContext context, {
  AcademicPlansSidebarSection? section,
}) {
  final appState = context.read<AppState>();
  if (section != null) {
    appState.requestAcademicPlansSection(section);
  }
  navigateTeacherSection(context, TeacherNavSection.academicPlans);
}

void redirectLessonPlatformDocumentsToAcademicPlans(BuildContext context) {
  openAcademicPlans(
    context,
    section: AcademicPlansSidebarSection.documents,
  );
}

void openMentorshipDashboard(BuildContext context, {required int classId}) {
  Navigator.of(context).push(
    MaterialPageRoute(
      builder: (_) => MentorshipDashboardScreen(classId: classId),
    ),
  );
}
