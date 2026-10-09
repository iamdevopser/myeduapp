import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../l10n/app_localizations.dart';
import '../providers/app_state.dart';
import '../screens/secretary_portal/secretary_student_detail_screen.dart';
import '../screens/secretary_portal/secretary_tab_workspace.dart';
import 'secretary_nav_section.dart';

export 'secretary_nav_section.dart';

extension SecretaryNavSectionLabels on SecretaryNavSection {
  String label(AppLocalizations strings) {
    return switch (this) {
      SecretaryNavSection.home => strings.t('secretaryDashboard'),
      SecretaryNavSection.studentsParents =>
        strings.t('secretaryStudentsParentsModule'),
      SecretaryNavSection.classesSections =>
        strings.t('secretaryClassesSectionsModule'),
      SecretaryNavSection.attendanceReports =>
        strings.t('secretaryAttendanceReportsModule'),
      SecretaryNavSection.studentList => strings.t('secretaryStudentList'),
      SecretaryNavSection.studentAdd => strings.t('secretaryStudentAdd'),
      SecretaryNavSection.studentParents => strings.t('secretaryStudentParents'),
      SecretaryNavSection.classes => strings.t('secretaryClasses'),
      SecretaryNavSection.sections => strings.t('secretarySections'),
      SecretaryNavSection.parentList => strings.t('secretaryParentList'),
      SecretaryNavSection.parentAdd => strings.t('secretaryParentAdd'),
      SecretaryNavSection.parentDetail => strings.t('secretaryParentDetail'),
      SecretaryNavSection.attendanceDaily =>
        strings.t('secretaryAttendanceDaily'),
      SecretaryNavSection.attendanceHistory =>
        strings.t('secretaryAttendanceHistory'),
      SecretaryNavSection.announcementList =>
        strings.t('secretaryAnnouncementList'),
      SecretaryNavSection.announcementAdd =>
        strings.t('secretaryAnnouncementAdd'),
      SecretaryNavSection.announcementDetail =>
        strings.t('secretaryAnnouncementDetail'),
      SecretaryNavSection.documentList => strings.t('secretaryDocumentList'),
      SecretaryNavSection.documentAdd => strings.t('secretaryDocumentAdd'),
      SecretaryNavSection.documentDetail => strings.t('secretaryDocumentDetail'),
      SecretaryNavSection.profile => strings.t('secretaryProfile'),
    };
  }

  IconData get icon {
    return switch (this) {
      SecretaryNavSection.home => Icons.dashboard_outlined,
      SecretaryNavSection.studentsParents => Icons.groups_outlined,
      SecretaryNavSection.classesSections => Icons.apartment_outlined,
      SecretaryNavSection.attendanceReports => Icons.event_available_outlined,
      SecretaryNavSection.studentList => Icons.list_alt_outlined,
      SecretaryNavSection.studentAdd => Icons.person_add_outlined,
      SecretaryNavSection.studentParents => Icons.family_restroom_outlined,
      SecretaryNavSection.classes => Icons.class_outlined,
      SecretaryNavSection.sections => Icons.view_module_outlined,
      SecretaryNavSection.parentList => Icons.people_outline,
      SecretaryNavSection.parentAdd => Icons.person_add_alt_1_outlined,
      SecretaryNavSection.parentDetail => Icons.person_outline,
      SecretaryNavSection.attendanceDaily => Icons.today_outlined,
      SecretaryNavSection.attendanceHistory => Icons.history_outlined,
      SecretaryNavSection.announcementList => Icons.campaign_outlined,
      SecretaryNavSection.announcementAdd => Icons.add_alert_outlined,
      SecretaryNavSection.announcementDetail => Icons.article_outlined,
      SecretaryNavSection.documentList => Icons.folder_outlined,
      SecretaryNavSection.documentAdd => Icons.upload_file_outlined,
      SecretaryNavSection.documentDetail => Icons.description_outlined,
      SecretaryNavSection.profile => Icons.person_outline,
    };
  }
}

void navigateSecretarySection(BuildContext context, SecretaryNavSection section) {
  context.read<AppState>().openSecretarySection(section);
  if (!_isInsideSecretaryTabWorkspace(context)) {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const SecretaryTabWorkspace()),
    );
  }
}

void openSecretaryStudentDetail(
  BuildContext context,
  int studentId, {
  Map<String, Object?>? studentRow,
}) {
  Navigator.of(context).push(
    MaterialPageRoute<void>(
      builder: (_) => SecretaryStudentDetailScreen(
        studentId: studentId,
        initialRow: studentRow,
      ),
    ),
  );
}

void openSecretaryStudentParents(BuildContext context, int studentId) {
  final state = context.read<AppState>();
  state.setSecretaryFocusStudent(studentId);
  navigateSecretarySection(context, SecretaryNavSection.studentParents);
}

void openSecretaryParentDetail(BuildContext context, int parentId) {
  final state = context.read<AppState>();
  state.setSecretaryFocusParent(parentId);
  navigateSecretarySection(context, SecretaryNavSection.parentDetail);
}

void openSecretaryStudentAttendanceHistory(BuildContext context, int studentId) {
  final state = context.read<AppState>();
  state.setSecretaryFocusStudent(studentId);
  navigateSecretarySection(context, SecretaryNavSection.attendanceHistory);
}

void openSecretaryAnnouncementDetail(BuildContext context, int announcementId) {
  final state = context.read<AppState>();
  state.setSecretaryFocusAnnouncement(announcementId);
  navigateSecretarySection(context, SecretaryNavSection.announcementDetail);
}

void openSecretaryAnnouncementAdd(BuildContext context, {int? editId}) {
  final state = context.read<AppState>();
  state.setSecretaryFocusAnnouncement(editId);
  navigateSecretarySection(context, SecretaryNavSection.announcementAdd);
}

void openSecretaryDocumentDetail(BuildContext context, int documentId) {
  final state = context.read<AppState>();
  state.setSecretaryFocusDocument(documentId);
  navigateSecretarySection(context, SecretaryNavSection.documentDetail);
}

void openSecretaryDocumentAdd(BuildContext context, {int? editId}) {
  final state = context.read<AppState>();
  state.setSecretaryFocusDocument(editId);
  navigateSecretarySection(context, SecretaryNavSection.documentAdd);
}

bool _isInsideSecretaryTabWorkspace(BuildContext context) {
  return context.findAncestorWidgetOfExactType<SecretaryTabWorkspace>() != null;
}

void openSecretaryPortal(BuildContext context) {
  context.read<AppState>().openSecretarySection(SecretaryNavSection.home);
  Navigator.of(context).pushReplacement(
    MaterialPageRoute(builder: (_) => const SecretaryTabWorkspace()),
  );
}
