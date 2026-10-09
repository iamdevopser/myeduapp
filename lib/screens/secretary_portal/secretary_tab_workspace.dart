import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../l10n/app_localizations.dart';
import '../../providers/app_state.dart';
import '../../utils/app_navigation.dart';
import '../../utils/secretary_navigation.dart';
import '../../widgets/app_shell.dart';
import 'secretary_announcement_add_screen.dart';
import 'secretary_announcement_detail_screen.dart';
import 'secretary_announcements_list_screen.dart';
import 'secretary_attendance_hub_screen.dart';
import 'secretary_classes_sections_hub_screen.dart';
import 'secretary_dashboard_screen.dart';
import 'secretary_document_add_screen.dart';
import 'secretary_document_detail_screen.dart';
import 'secretary_documents_list_screen.dart';
import 'secretary_profile_screen.dart';
import 'secretary_students_parents_hub_screen.dart';

class SecretaryTabWorkspace extends StatelessWidget {
  const SecretaryTabWorkspace({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    if (!state.isSecretary || !state.isUnlocked) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (context.mounted) {
          leaveWorkspaceToLogin(context);
        }
      });
      return const Center(child: CircularProgressIndicator());
    }
    final strings = AppLocalizations.of(context);
    final section = state.activeSecretarySection;

    return AppShell(
      secretarySection: section,
      title: section.label(strings),
      subtitle: strings.t('secretaryMenuWelcome'),
      child: switch (section) {
        SecretaryNavSection.home => const SecretaryDashboardScreen(),
        SecretaryNavSection.studentsParents =>
          const SecretaryStudentsParentsHubScreen(),
        SecretaryNavSection.classesSections =>
          const SecretaryClassesSectionsHubScreen(),
        SecretaryNavSection.attendanceReports =>
          const SecretaryAttendanceHubScreen(),
        SecretaryNavSection.announcementList =>
          const SecretaryAnnouncementsListScreen(),
        SecretaryNavSection.announcementAdd =>
          const SecretaryAnnouncementAddScreen(),
        SecretaryNavSection.announcementDetail =>
          const SecretaryAnnouncementDetailScreen(),
        SecretaryNavSection.documentList =>
          const SecretaryDocumentsListScreen(),
        SecretaryNavSection.documentAdd => const SecretaryDocumentAddScreen(),
        SecretaryNavSection.documentDetail =>
          const SecretaryDocumentDetailScreen(),
        SecretaryNavSection.profile => const SecretaryProfileScreen(),
        _ => const SecretaryDashboardScreen(),
      },
    );
  }
}
