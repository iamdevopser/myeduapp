import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../l10n/app_localizations.dart';
import '../providers/app_state.dart';
import '../screens/parent_portal/parent_tab_workspace.dart';
import 'parent_nav_section.dart';

export 'parent_nav_section.dart';

extension ParentNavSectionLabels on ParentNavSection {
  String label(AppLocalizations strings) {
    return switch (this) {
      ParentNavSection.home => strings.t('parentPortalOverview'),
      ParentNavSection.children => strings.t('parentPortalChildren'),
      ParentNavSection.announcements => strings.t('parentPortalAnnouncements'),
      ParentNavSection.documents => strings.t('parentPortalDocuments'),
      ParentNavSection.attendance => strings.t('parentPortalAttendance'),
      ParentNavSection.academic => strings.t('parentPortalAcademic'),
      ParentNavSection.weeklySchedule =>
        strings.t('parentPortalWeeklySchedule'),
      ParentNavSection.profile => strings.t('parentPortalProfile'),
    };
  }

  IconData get icon {
    return switch (this) {
      ParentNavSection.home => Icons.home_outlined,
      ParentNavSection.children => Icons.family_restroom_outlined,
      ParentNavSection.announcements => Icons.campaign_outlined,
      ParentNavSection.documents => Icons.folder_outlined,
      ParentNavSection.attendance => Icons.event_available_outlined,
      ParentNavSection.academic => Icons.school_outlined,
      ParentNavSection.weeklySchedule => Icons.calendar_view_week_outlined,
      ParentNavSection.profile => Icons.person_outline,
    };
  }
}

void navigateParentSection(BuildContext context, ParentNavSection section) {
  context.read<AppState>().openParentSection(section);
  if (!_isInsideParentTabWorkspace(context)) {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const ParentTabWorkspace()),
    );
  }
}

void openParentPortal(BuildContext context) {
  context.read<AppState>().openParentSection(ParentNavSection.home);
  Navigator.of(context).pushReplacement(
    MaterialPageRoute(builder: (_) => const ParentTabWorkspace()),
  );
}

bool _isInsideParentTabWorkspace(BuildContext context) {
  return context.findAncestorWidgetOfExactType<ParentTabWorkspace>() != null;
}
