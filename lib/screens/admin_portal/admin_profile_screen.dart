import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../l10n/app_localizations.dart';
import '../../models/app_role.dart';
import '../../providers/app_state.dart';
import '../../services/account_service.dart';
import '../../services/authorization_service.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../../widgets/app_card.dart';
import '../student_portal/widgets/student_portal_ui.dart';

class AdminProfileScreen extends StatelessWidget {
  const AdminProfileScreen({super.key});

  Future<void> _showChangePasswordDialog(
    BuildContext context,
    AppState state,
  ) async {
    final strings = AppLocalizations.of(context);
    final accountId = state.sessionAccountId;
    if (accountId == null) return;

    final pass = TextEditingController();
    final confirm = TextEditingController();
    String? error;

    await showDialog<void>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setLocal) {
          return AlertDialog(
            title: Text(strings.t('changePassword')),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: pass,
                  obscureText: true,
                  decoration: InputDecoration(
                    labelText: strings.t('newPassword'),
                  ),
                ),
                TextField(
                  controller: confirm,
                  obscureText: true,
                  decoration: InputDecoration(
                    labelText: strings.t('confirmPassword'),
                  ),
                ),
                if (error != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    error!,
                    style: TextStyle(color: Theme.of(ctx).colorScheme.error),
                  ),
                ],
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: Text(strings.t('cancel')),
              ),
              FilledButton(
                onPressed: () async {
                  final newPass = pass.text;
                  if (newPass.length < 4) {
                    setLocal(() => error = strings.t('passwordTooShort'));
                    return;
                  }
                  if (newPass != confirm.text) {
                    setLocal(() => error = strings.t('passwordMismatch'));
                    return;
                  }
                  try {
                    await AccountService(state.db, actorAccountId: accountId)
                        .changePasswordAsAccountOwner(
                      accountId: accountId,
                      actorAccountId: accountId,
                      newPasswordPlain: newPass,
                    );
                  } on AccountValidationException catch (e) {
                    setLocal(() => error = strings.t(e.messageKey));
                    return;
                  } on AccountAccessDeniedException {
                    if (ctx.mounted) Navigator.pop(ctx);
                    return;
                  }
                  if (ctx.mounted) Navigator.pop(ctx);
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(strings.t('passwordChangedSuccess')),
                      ),
                    );
                  }
                },
                child: Text(strings.t('save')),
              ),
            ],
          );
        },
      ),
    );
    pass.dispose();
    confirm.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context);
    final state = context.watch<AppState>();
    final auth = AuthorizationService(state);
    if (!auth.canAccessAdminWorkspace || state.sessionAccountId == null) {
      return Center(child: Text(strings.t('adminAccessDenied')));
    }

    return FutureBuilder<Map<String, Object?>?>(
      future: state.db.getAccountById(state.sessionAccountId!),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        final row = snapshot.data;
        final name = row?['gorunen_ad'] as String? ??
            row?['kullanici_adi'] as String? ??
            strings.t('adminProfile');
        final username = row?['kullanici_adi'] as String? ?? '';
        final email = row?['email'] as String?;
        final active = (row?['aktif'] as int? ?? 1) == 1;

        return SingleChildScrollView(
          padding: AppSpacing.pagePadding(context.layoutWidth),
          child: AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                StudentProfileHeader(
                  name: name,
                  subtitle: strings.t('adminPortalTitle'),
                ),
                const SizedBox(height: AppSpacing.lg),
                const Divider(height: 1),
                const SizedBox(height: AppSpacing.lg),
                StudentProfileInfoRow(
                  label: strings.t('adminAccountUsername'),
                  value: username,
                ),
                StudentProfileInfoRow(
                  label: strings.t('adminAccountRole'),
                  value: AppRole.admin.name,
                ),
                StudentProfileInfoRow(
                  label: strings.t('adminAccountStatus'),
                  value: active
                      ? strings.t('adminAccountActive')
                      : strings.t('adminAccountInactive'),
                ),
                if (email != null && email.isNotEmpty)
                  StudentProfileInfoRow(
                    label: strings.t('studentPortalEmail'),
                    value: email,
                  ),
                const SizedBox(height: AppSpacing.lg),
                Semantics(
                  button: true,
                  label: strings.t('changePassword'),
                  child: FilledButton.icon(
                    onPressed: () => _showChangePasswordDialog(context, state),
                    icon: const Icon(Icons.lock_outline),
                    label: Text(strings.t('changePassword')),
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  strings.t('adminProfileHint'),
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
