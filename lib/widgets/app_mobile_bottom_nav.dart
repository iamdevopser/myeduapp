import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../l10n/app_localizations.dart';
import '../models/app_role.dart';
import '../providers/app_state.dart';
import '../services/authorization_service.dart';
import '../theme/app_design_tokens.dart';
import '../utils/admin_navigation.dart';
import '../utils/mobile_bottom_nav_destinations.dart';
import '../utils/parent_navigation.dart';
import '../utils/secretary_navigation.dart';
import '../utils/settings_navigation.dart';
import '../utils/student_navigation.dart';
import '../utils/teacher_nav_section.dart';
import '../utils/teacher_navigation.dart';

class AppMobileBottomNav extends StatelessWidget {
  const AppMobileBottomNav({
    super.key,
    this.teacherSection,
    this.studentSection,
    this.secretarySection,
    this.parentSection,
    this.adminSection,
    this.settingsRouteActive = false,
  });

  final TeacherNavSection? teacherSection;
  final StudentNavSection? studentSection;
  final SecretaryNavSection? secretarySection;
  final ParentNavSection? parentSection;
  final AdminNavSection? adminSection;
  final bool settingsRouteActive;

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final role = state.currentRole;
    if (!state.isUnlocked || role == null) {
      return const SizedBox.shrink();
    }

    final specs = mobileBottomNavSpecsForRole(role);
    if (specs.isEmpty) return const SizedBox.shrink();

    final strings = AppLocalizations.of(context);
    final selected = mobileBottomNavSelectedIndex(
      role: role,
      specs: specs,
      teacherSection: teacherSection,
      studentSection: studentSection,
      parentSection: parentSection,
      secretarySection: secretarySection,
      adminSection: adminSection,
      settingsRouteActive: settingsRouteActive,
    );

    final tokens = context.tokens;
    return NavigationBar(
      // Always show labels; destinations are >= 48 px tall (bar height 80) and
      // NavigationDestination exposes button + selected semantics.
      labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
      height: 80,
      backgroundColor: tokens.surface,
      indicatorColor: tokens.primary.withValues(alpha: 0.14),
      selectedIndex: selected,
      onDestinationSelected: (index) =>
          _onSelect(context, role, specs[index].key),
      destinations: [
        for (final spec in specs)
          NavigationDestination(
            icon: Icon(spec.icon),
            label: strings.t(spec.labelKey),
            tooltip: strings.t(spec.labelKey),
          ),
      ],
    );
  }

  void _onSelect(BuildContext context, AppRole role, MobileBottomNavKey key) {
    switch (key) {
      case MobileBottomNavKey.teacherHome:
        navigateTeacherSection(context, TeacherNavSection.home);
      case MobileBottomNavKey.teacherStudentPlatform:
        navigateTeacherSection(context, TeacherNavSection.studentPlatform);
      case MobileBottomNavKey.teacherLessonPlatform:
        navigateTeacherSection(context, TeacherNavSection.lessonPlatform);
      case MobileBottomNavKey.teacherSettings:
        navigateTeacherSection(context, TeacherNavSection.settings);
      case MobileBottomNavKey.studentHome:
        navigateStudentSection(context, StudentNavSection.home);
      case MobileBottomNavKey.studentCourses:
        navigateStudentSection(context, StudentNavSection.courses);
      case MobileBottomNavKey.studentCalendar:
        navigateStudentSection(context, StudentNavSection.academicPlansWeekly);
      case MobileBottomNavKey.studentAnnouncements:
        navigateStudentSection(context, StudentNavSection.announcements);
      case MobileBottomNavKey.studentProfile:
        navigateStudentSection(context, StudentNavSection.profile);
      case MobileBottomNavKey.parentHome:
        navigateParentSection(context, ParentNavSection.home);
      case MobileBottomNavKey.parentChildren:
        navigateParentSection(context, ParentNavSection.children);
      case MobileBottomNavKey.parentAnnouncements:
        navigateParentSection(context, ParentNavSection.announcements);
      case MobileBottomNavKey.parentProfile:
        navigateParentSection(context, ParentNavSection.profile);
      case MobileBottomNavKey.secretaryHome:
        navigateSecretarySection(context, SecretaryNavSection.home);
      case MobileBottomNavKey.secretaryStudents:
        navigateSecretarySection(context, SecretaryNavSection.studentsParents);
      case MobileBottomNavKey.secretaryAttendance:
        navigateSecretarySection(context, SecretaryNavSection.attendanceReports);
      case MobileBottomNavKey.secretaryProfile:
        navigateSecretarySection(context, SecretaryNavSection.profile);
      case MobileBottomNavKey.adminHome:
        navigateAdminSection(context, AdminNavSection.home);
      case MobileBottomNavKey.adminUsers:
        navigateAdminSection(context, AdminNavSection.users);
      case MobileBottomNavKey.adminProfile:
        navigateAdminSection(context, AdminNavSection.profile);
      case MobileBottomNavKey.adminSettings:
        final auth = AuthorizationService(context.read<AppState>());
        if (auth.canManageLocaleAndTheme) {
          openAppSettings(context);
        }
    }
  }
}
