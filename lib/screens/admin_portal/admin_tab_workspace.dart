import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../l10n/app_localizations.dart';
import '../../providers/app_state.dart';
import '../../utils/admin_navigation.dart';
import '../../utils/app_navigation.dart';
import '../../widgets/app_shell.dart';
import 'admin_home_screen.dart';
import 'admin_user_add_screen.dart';
import 'admin_users_list_screen.dart';
import 'admin_profile_screen.dart';

class AdminTabWorkspace extends StatelessWidget {
  const AdminTabWorkspace({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    if (!state.isAdmin || !state.isUnlocked || state.sessionAccountId == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (context.mounted) leaveWorkspaceToLogin(context);
      });
      return const Center(child: CircularProgressIndicator());
    }

    final strings = AppLocalizations.of(context);
    final section = state.activeAdminSection;

    final Widget body = switch (section) {
      AdminNavSection.home => const AdminHomeScreen(),
      AdminNavSection.users => const AdminUsersListScreen(),
      AdminNavSection.userAdd => const AdminUserAddScreen(),
      AdminNavSection.profile => const AdminProfileScreen(),
    };

    final title = switch (section) {
      AdminNavSection.home => strings.t('adminPortalOverview'),
      AdminNavSection.users => strings.t('adminUsersMenu'),
      AdminNavSection.userAdd => strings.t('adminUserAdd'),
      AdminNavSection.profile => strings.t('adminProfile'),
    };

    return AppShell(
      title: title,
      subtitle: strings.t('adminPortalTitle'),
      adminSection: section,
      child: body,
    );
  }
}
