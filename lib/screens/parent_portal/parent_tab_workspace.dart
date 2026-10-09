import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../l10n/app_localizations.dart';
import '../../providers/app_state.dart';
import '../../utils/app_navigation.dart';
import '../../utils/parent_navigation.dart';
import '../../widgets/app_shell.dart';
import 'parent_portal_screens.dart';

class ParentTabWorkspace extends StatelessWidget {
  const ParentTabWorkspace({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    if (!state.isParent ||
        !state.isUnlocked ||
        state.sessionParentId == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (context.mounted) {
          leaveWorkspaceToLogin(context);
        }
      });
      return const Center(child: CircularProgressIndicator());
    }
    final strings = AppLocalizations.of(context);
    final section = state.activeParentSection;
    return AppShell(
      parentSection: section,
      title: section.label(strings),
      subtitle: strings.t('parentPortalTitle'),
      child: switch (section) {
        ParentNavSection.home => const ParentHomeScreen(),
        ParentNavSection.children => const ParentChildrenScreen(),
        ParentNavSection.announcements => const ParentAnnouncementsScreen(),
        ParentNavSection.documents => const ParentDocumentsScreen(),
        ParentNavSection.attendance => const ParentAttendanceScreen(),
        ParentNavSection.academic => const ParentAcademicScreen(),
        ParentNavSection.weeklySchedule =>
          const ParentWeeklyScheduleScreen(),
        ParentNavSection.profile => const ParentProfileScreen(),
      },
    );
  }
}
