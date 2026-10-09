import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../l10n/app_localizations.dart';
import '../providers/app_state.dart';
import '../screens/admin_portal/admin_tab_workspace.dart';
import 'admin_nav_section.dart';

export 'admin_nav_section.dart';

extension AdminNavSectionLabels on AdminNavSection {
  String label(AppLocalizations strings) {
    return switch (this) {
      AdminNavSection.home => strings.t('adminPortalOverview'),
      AdminNavSection.users => strings.t('adminUsersMenu'),
      AdminNavSection.userAdd => strings.t('adminUserAdd'),
      AdminNavSection.profile => strings.t('adminProfile'),
    };
  }

  IconData get icon {
    return switch (this) {
      AdminNavSection.home => Icons.dashboard_outlined,
      AdminNavSection.users => Icons.people_outline,
      AdminNavSection.userAdd => Icons.person_add_alt_1_outlined,
      AdminNavSection.profile => Icons.admin_panel_settings_outlined,
    };
  }
}

void navigateAdminSection(BuildContext context, AdminNavSection section) {
  context.read<AppState>().openAdminSection(section);
  if (!_isInsideAdminTabWorkspace(context)) {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const AdminTabWorkspace()),
    );
  }
}

bool _isInsideAdminTabWorkspace(BuildContext context) {
  return context.findAncestorWidgetOfExactType<AdminTabWorkspace>() != null;
}

void openAdminPortal(BuildContext context) {
  context.read<AppState>().openAdminSection(AdminNavSection.home);
  Navigator.of(context).pushReplacement(
    MaterialPageRoute(builder: (_) => const AdminTabWorkspace()),
  );
}
