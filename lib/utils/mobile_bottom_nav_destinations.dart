import 'package:flutter/material.dart';

import '../models/app_role.dart';
import 'admin_nav_section.dart';
import 'parent_nav_section.dart';
import 'secretary_nav_section.dart';
import 'student_nav_section.dart';
import 'teacher_nav_section.dart';

/// Bottom navigation item keys (role-scoped).
enum MobileBottomNavKey {
  teacherHome,
  teacherStudentPlatform,
  teacherLessonPlatform,
  teacherSettings,
  studentHome,
  studentCourses,
  studentCalendar,
  studentAnnouncements,
  studentProfile,
  parentHome,
  parentChildren,
  parentAnnouncements,
  parentProfile,
  secretaryHome,
  secretaryStudents,
  secretaryAttendance,
  secretaryProfile,
  adminHome,
  adminUsers,
  adminProfile,
  adminSettings,
}

class MobileBottomNavSpec {
  const MobileBottomNavSpec({
    required this.key,
    required this.icon,
    required this.labelKey,
  });

  final MobileBottomNavKey key;
  final IconData icon;
  final String labelKey;
}

List<MobileBottomNavSpec> mobileBottomNavSpecsForRole(AppRole role) {
  switch (role) {
    case AppRole.teacher:
      return const [
        MobileBottomNavSpec(
          key: MobileBottomNavKey.teacherHome,
          icon: Icons.dashboard_outlined,
          labelKey: 'homePage',
        ),
        MobileBottomNavSpec(
          key: MobileBottomNavKey.teacherStudentPlatform,
          icon: Icons.groups_outlined,
          labelKey: 'studentPlatform',
        ),
        MobileBottomNavSpec(
          key: MobileBottomNavKey.teacherLessonPlatform,
          icon: Icons.auto_stories_outlined,
          labelKey: 'goToApp',
        ),
        MobileBottomNavSpec(
          key: MobileBottomNavKey.teacherSettings,
          icon: Icons.settings_outlined,
          labelKey: 'settings',
        ),
      ];
    case AppRole.student:
      return const [
        MobileBottomNavSpec(
          key: MobileBottomNavKey.studentHome,
          icon: Icons.home_outlined,
          labelKey: 'studentPortalHome',
        ),
        MobileBottomNavSpec(
          key: MobileBottomNavKey.studentCourses,
          icon: Icons.menu_book_outlined,
          labelKey: 'studentPortalCourses',
        ),
        MobileBottomNavSpec(
          key: MobileBottomNavKey.studentCalendar,
          icon: Icons.calendar_month_outlined,
          labelKey: 'studentPortalCalendarShort',
        ),
        MobileBottomNavSpec(
          key: MobileBottomNavKey.studentAnnouncements,
          icon: Icons.campaign_outlined,
          labelKey: 'studentPortalAnnouncements',
        ),
        MobileBottomNavSpec(
          key: MobileBottomNavKey.studentProfile,
          icon: Icons.person_outline,
          labelKey: 'studentPortalProfile',
        ),
      ];
    case AppRole.parent:
      return const [
        MobileBottomNavSpec(
          key: MobileBottomNavKey.parentHome,
          icon: Icons.home_outlined,
          labelKey: 'parentPortalOverview',
        ),
        MobileBottomNavSpec(
          key: MobileBottomNavKey.parentChildren,
          icon: Icons.family_restroom_outlined,
          labelKey: 'parentPortalChildren',
        ),
        MobileBottomNavSpec(
          key: MobileBottomNavKey.parentAnnouncements,
          icon: Icons.campaign_outlined,
          labelKey: 'parentPortalAnnouncements',
        ),
        MobileBottomNavSpec(
          key: MobileBottomNavKey.parentProfile,
          icon: Icons.person_outline,
          labelKey: 'parentPortalProfile',
        ),
      ];
    case AppRole.secretary:
      return const [
        MobileBottomNavSpec(
          key: MobileBottomNavKey.secretaryHome,
          icon: Icons.dashboard_outlined,
          labelKey: 'secretaryDashboard',
        ),
        MobileBottomNavSpec(
          key: MobileBottomNavKey.secretaryStudents,
          icon: Icons.people_outline,
          labelKey: 'secretaryStudentsParentsModule',
        ),
        MobileBottomNavSpec(
          key: MobileBottomNavKey.secretaryAttendance,
          icon: Icons.event_available_outlined,
          labelKey: 'secretaryAttendanceReportsModule',
        ),
        MobileBottomNavSpec(
          key: MobileBottomNavKey.secretaryProfile,
          icon: Icons.person_outline,
          labelKey: 'secretaryProfile',
        ),
      ];
    case AppRole.admin:
      return const [
        MobileBottomNavSpec(
          key: MobileBottomNavKey.adminHome,
          icon: Icons.dashboard_outlined,
          labelKey: 'adminPortalOverview',
        ),
        MobileBottomNavSpec(
          key: MobileBottomNavKey.adminUsers,
          icon: Icons.people_outline,
          labelKey: 'adminUsersMenu',
        ),
        MobileBottomNavSpec(
          key: MobileBottomNavKey.adminProfile,
          icon: Icons.admin_panel_settings_outlined,
          labelKey: 'adminProfile',
        ),
        MobileBottomNavSpec(
          key: MobileBottomNavKey.adminSettings,
          icon: Icons.settings_outlined,
          labelKey: 'settings',
        ),
      ];
  }
}

bool _secretaryStudentsBucket(SecretaryNavSection? section) {
  if (section == null) return false;
  return section == SecretaryNavSection.studentsParents ||
      section == SecretaryNavSection.studentList ||
      section == SecretaryNavSection.studentAdd ||
      section == SecretaryNavSection.studentParents ||
      section == SecretaryNavSection.parentList ||
      section == SecretaryNavSection.parentAdd ||
      section == SecretaryNavSection.parentDetail;
}

bool _secretaryAttendanceBucket(SecretaryNavSection? section) {
  if (section == null) return false;
  return section == SecretaryNavSection.attendanceReports ||
      section == SecretaryNavSection.attendanceDaily ||
      section == SecretaryNavSection.attendanceHistory;
}

int mobileBottomNavSelectedIndex({
  required AppRole role,
  required List<MobileBottomNavSpec> specs,
  TeacherNavSection? teacherSection,
  StudentNavSection? studentSection,
  ParentNavSection? parentSection,
  SecretaryNavSection? secretarySection,
  AdminNavSection? adminSection,
  bool settingsRouteActive = false,
}) {
  if (specs.isEmpty) return 0;
  MobileBottomNavKey active;
  switch (role) {
    case AppRole.teacher:
      if (teacherSection == TeacherNavSection.settings) {
        active = MobileBottomNavKey.teacherSettings;
      } else {
        switch (teacherSection) {
          case TeacherNavSection.studentPlatform:
            active = MobileBottomNavKey.teacherStudentPlatform;
          case TeacherNavSection.lessonPlatform:
            active = MobileBottomNavKey.teacherLessonPlatform;
          case TeacherNavSection.home:
          case null:
            active = MobileBottomNavKey.teacherHome;
          default:
            active = MobileBottomNavKey.teacherHome;
        }
      }
    case AppRole.student:
      switch (studentSection) {
        case StudentNavSection.courses:
          active = MobileBottomNavKey.studentCourses;
        case StudentNavSection.academicPlansWeekly:
          active = MobileBottomNavKey.studentCalendar;
        case StudentNavSection.announcements:
          active = MobileBottomNavKey.studentAnnouncements;
        case StudentNavSection.profile:
          active = MobileBottomNavKey.studentProfile;
        case StudentNavSection.home:
        case null:
          active = MobileBottomNavKey.studentHome;
        default:
          active = MobileBottomNavKey.studentHome;
      }
    case AppRole.parent:
      switch (parentSection) {
        case ParentNavSection.children:
          active = MobileBottomNavKey.parentChildren;
        case ParentNavSection.announcements:
          active = MobileBottomNavKey.parentAnnouncements;
        case ParentNavSection.profile:
          active = MobileBottomNavKey.parentProfile;
        case ParentNavSection.home:
        case null:
          active = MobileBottomNavKey.parentHome;
        default:
          active = MobileBottomNavKey.parentHome;
      }
    case AppRole.secretary:
      if (secretarySection == SecretaryNavSection.profile) {
        active = MobileBottomNavKey.secretaryProfile;
      } else if (_secretaryAttendanceBucket(secretarySection)) {
        active = MobileBottomNavKey.secretaryAttendance;
      } else if (_secretaryStudentsBucket(secretarySection)) {
        active = MobileBottomNavKey.secretaryStudents;
      } else {
        active = MobileBottomNavKey.secretaryHome;
      }
    case AppRole.admin:
      if (settingsRouteActive) {
        active = MobileBottomNavKey.adminSettings;
      } else {
        switch (adminSection) {
          case AdminNavSection.users:
          case AdminNavSection.userAdd:
            active = MobileBottomNavKey.adminUsers;
          case AdminNavSection.profile:
            active = MobileBottomNavKey.adminProfile;
          case AdminNavSection.home:
          case null:
            active = MobileBottomNavKey.adminHome;
        }
      }
  }
  final idx = specs.indexWhere((s) => s.key == active);
  return idx >= 0 ? idx : 0;
}
