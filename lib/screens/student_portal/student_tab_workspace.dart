import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../l10n/app_localizations.dart';
import '../../providers/app_state.dart';
import '../../utils/app_navigation.dart';
import '../../utils/student_navigation.dart';
import '../../widgets/app_shell.dart';
import 'student_dashboard_screen.dart';
import 'student_portal_section_screens.dart';
import 'student_session_gate.dart';

class StudentTabWorkspace extends StatelessWidget {
  const StudentTabWorkspace({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    if (!state.isStudent || !state.isUnlocked || state.sessionStudentId == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (context.mounted) {
          leaveWorkspaceToLogin(context);
        }
      });
      return const Center(child: CircularProgressIndicator());
    }
    return StudentSessionGate(
      builder: (context, enrollments, primary) {
        final strings = AppLocalizations.of(context);
        final section = context.watch<AppState>().activeStudentSection;
        return AppShell(
          studentSection: section,
          title: section.label(strings),
          subtitle: primary.displayClass,
          child: _sectionWidget(section),
        );
      },
    );
  }

  Widget _sectionWidget(StudentNavSection section) {
    return switch (section) {
      StudentNavSection.home => const StudentDashboardScreen(),
      StudentNavSection.courses => const StudentCoursesScreen(),
      StudentNavSection.academicPlansWeekly =>
        const StudentWeeklyScheduleScreen(),
      StudentNavSection.assignments => const StudentAssignmentsScreen(),
      StudentNavSection.exams => const StudentExamsScreen(),
      StudentNavSection.performance => const StudentPerformanceScreen(),
      StudentNavSection.attendance => const StudentAttendanceScreen(),
      StudentNavSection.documents => const StudentDocumentsScreen(),
      StudentNavSection.announcements => const StudentAnnouncementsScreen(),
      StudentNavSection.profile => const StudentProfileScreen(),
      StudentNavSection.lessonPlatform => const StudentCoursesScreen(),
    };
  }
}
