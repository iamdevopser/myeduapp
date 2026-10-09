import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../l10n/app_localizations.dart';
import '../models/app_role.dart';
import '../providers/app_state.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../widgets/app_sidebar_profile.dart';

/// Tasarım: `10_ayarlar.png` üst profil alanı.
class DesignSettingsProfileHeader extends StatelessWidget {
  const DesignSettingsProfileHeader({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final strings = AppLocalizations.of(context);
    final role = state.currentRole;
    if (role == null || !state.isUnlocked) {
      return const SizedBox.shrink();
    }

    return FutureBuilder<String>(
      future: AppSidebarProfile.resolveDisplayName(state, role, strings),
      builder: (context, snap) {
        final name = snap.data ?? _roleFallback(strings, role);
        final roleLabel = _roleLabel(strings, role);
        final initial =
            name.isNotEmpty ? name.substring(0, 1).toUpperCase() : '?';

        return Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg,
            AppSpacing.lg,
            AppSpacing.lg,
            AppSpacing.md,
          ),
          child: Row(
            children: [
              CircleAvatar(
                radius: 28,
                backgroundColor:
                    AppColors.primaryBlue.withValues(alpha: 0.12),
                child: Text(
                  initial,
                  style: const TextStyle(
                    color: AppColors.navy,
                    fontWeight: FontWeight.w700,
                    fontSize: 22,
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                            color: AppColors.navy,
                          ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      roleLabel,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppColors.textSecondary,
                          ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  static String _roleFallback(AppLocalizations strings, AppRole role) {
    return switch (role) {
      AppRole.teacher => strings.t('homeRoleTeacherTitle'),
      AppRole.secretary => strings.t('homeRoleSecretaryTitle'),
      AppRole.admin => strings.t('homeRoleAdminTitle'),
      AppRole.student => strings.t('homeRoleStudentTitle'),
      AppRole.parent => strings.t('homeRoleParentTitle'),
    };
  }

  static String _roleLabel(AppLocalizations strings, AppRole role) {
    return switch (role) {
      AppRole.teacher => strings.t('homeRoleTeacherTitle'),
      AppRole.secretary => strings.t('homeRoleSecretaryTitle'),
      AppRole.admin => strings.t('adminPortalTitle'),
      AppRole.student => strings.t('homeRoleStudentTitle'),
      AppRole.parent => strings.t('homeRoleParentTitle'),
    };
  }
}
