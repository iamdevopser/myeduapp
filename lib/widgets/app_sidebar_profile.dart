import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../l10n/app_localizations.dart';
import '../models/app_role.dart';
import '../providers/app_state.dart';
import '../theme/app_colors.dart';
import '../utils/teacher_display_name.dart';

/// Referans: sidebar alt kullanıcı alanı (`myeduapp_ui_reference.png`).
class AppSidebarProfile extends StatelessWidget {
  const AppSidebarProfile({super.key, this.showLabels = true});

  final bool showLabels;

  @override
  Widget build(BuildContext context) {
    if (!showLabels) {
      return const SizedBox.shrink();
    }
    final state = context.watch<AppState>();
    final strings = AppLocalizations.of(context);
    final role = state.currentRole;
    if (role == null || !state.isUnlocked) {
      return const SizedBox.shrink();
    }

    return FutureBuilder<String>(
      future: resolveDisplayName(state, role, strings),
      builder: (context, snap) {
        final name = snap.data ?? _roleFallback(strings, role);
        final roleLabel = _roleLabel(strings, role);
        final initial =
            name.isNotEmpty ? name.substring(0, 1).toUpperCase() : '?';
        return Padding(
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
          child: Row(
            children: [
              CircleAvatar(
                radius: 18,
                backgroundColor: AppColors.referenceBlue.withValues(alpha: 0.25),
                child: Text(
                  initial,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                    Text(
                      roleLabel,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.65),
                        fontSize: 11,
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

  static Future<String> resolveDisplayName(
    AppState state,
    AppRole role,
    AppLocalizations strings,
  ) async {
    switch (role) {
      case AppRole.teacher:
        return TeacherDisplayName.resolve(state.db);
      case AppRole.admin:
      case AppRole.secretary:
        final id = state.sessionAccountId;
        if (id != null) {
          final row = await state.db.getAccountById(id);
          final display = row?['gorunen_ad'] as String? ??
              row?['kullanici_adi'] as String? ??
              row?['email'] as String?;
          if (display != null && display.trim().isNotEmpty) {
            return display.trim();
          }
        }
        return _roleFallback(strings, role);
      case AppRole.student:
        if (state.sessionStudentId != null && state.sessionClassId != null) {
          final students =
              await state.db.getStudents(state.sessionClassId!);
          for (final row in students) {
            if (row['id'] == state.sessionStudentId) {
              final name = row['ad_soyad'] as String?;
              if (name != null && name.isNotEmpty) return name;
            }
          }
        }
        return strings.t('homeRoleStudentTitle');
      case AppRole.parent:
        if (state.sessionParentId != null) {
          final row =
              await state.db.getParentGuardianById(state.sessionParentId!);
          final name = row?['ad_soyad'] as String?;
          if (name != null && name.isNotEmpty) return name;
        }
        return strings.t('homeRoleParentTitle');
    }
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
      AppRole.teacher => strings.t('teacherMenuWelcome'),
      AppRole.secretary => strings.t('secretaryMenuWelcome'),
      AppRole.admin => strings.t('adminPortalTitle'),
      AppRole.student => strings.t('studentPlatform'),
      AppRole.parent => strings.t('parentPortalTitle'),
    };
  }
}
