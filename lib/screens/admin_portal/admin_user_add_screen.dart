import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../l10n/app_localizations.dart';
import '../../models/app_role.dart';
import '../../providers/app_state.dart';
import '../../services/account_service.dart';
import '../../services/authorization_service.dart';
import '../../theme/app_spacing.dart';
import '../../utils/admin_navigation.dart';
import '../../widgets/app_card.dart';

/// Yönetici: yalnızca öğretmen ve sekreter personel hesapları.
class AdminUserAddScreen extends StatefulWidget {
  const AdminUserAddScreen({super.key});

  @override
  State<AdminUserAddScreen> createState() => _AdminUserAddScreenState();
}

class _AdminUserAddScreenState extends State<AdminUserAddScreen> {
  final _username = TextEditingController();
  final _fullName = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  AppRole _role = AppRole.teacher;
  bool _saving = false;

  static const _staffRoles = [AppRole.teacher, AppRole.secretary];

  @override
  void dispose() {
    _username.dispose();
    _fullName.dispose();
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  void _showMessage(BuildContext context, String text) {
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(text),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 5),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context);
    final state = context.watch<AppState>();
    final auth = AuthorizationService(state);
    if (!auth.canManageAccounts || state.sessionAccountId == null) {
      return Center(child: Text(strings.t('adminAccessDenied')));
    }
    final width = MediaQuery.sizeOf(context).width;
    final service =
        AccountService(state.db, actorAccountId: state.sessionAccountId!);

    return SingleChildScrollView(
      padding: AppSpacing.pagePadding(width),
      child: AppCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              strings.t('adminStaffAccountHint'),
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<AppRole>(
              isExpanded: true,
              value: _role,
              decoration: InputDecoration(labelText: strings.t('adminAccountRole')),
              items: _staffRoles
                  .map(
                    (r) => DropdownMenuItem(
                      value: r,
                      child: Text(strings.t(_roleKey(r))),
                    ),
                  )
                  .toList(),
              onChanged: _saving
                  ? null
                  : (v) => setState(() => _role = v ?? AppRole.teacher),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _username,
              enabled: !_saving,
              textCapitalization: TextCapitalization.none,
              decoration: InputDecoration(
                labelText: strings.t('adminAccountUsername'),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _fullName,
              enabled: !_saving,
              textCapitalization: TextCapitalization.words,
              decoration: InputDecoration(
                labelText: strings.t('adminAccountName'),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _email,
              enabled: !_saving,
              keyboardType: TextInputType.emailAddress,
              decoration: InputDecoration(
                labelText: strings.t('adminAccountEmail'),
                helperText: strings.t('adminAccountEmailOptionalHint'),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _password,
              enabled: !_saving,
              obscureText: true,
              decoration: InputDecoration(
                labelText: strings.t('adminAccountPassword'),
                helperText: strings.t('adminAccountPasswordStaffHint'),
              ),
            ),
            const SizedBox(height: 20),
            FilledButton(
              onPressed: _saving
                  ? null
                  : () => _save(context, strings, service, state),
              child: _saving
                  ? const SizedBox(
                      height: 22,
                      width: 22,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text(strings.t('save')),
            ),
          ],
        ),
      ),
    );
  }

  String _roleKey(AppRole r) => switch (r) {
        AppRole.teacher => 'adminRoleTeacher',
        AppRole.secretary => 'adminRoleSecretary',
        _ => 'adminRoleTeacher',
      };

  String? _validateForm(AppLocalizations strings) {
    if (_username.text.trim().length < 3) {
      return strings.t('adminAccountUsernameShort');
    }
    if (_fullName.text.trim().isEmpty) {
      return strings.t('adminAccountNameRequired');
    }
    if (_password.text.isEmpty) {
      return strings.t('adminAccountPasswordRequired');
    }
    if (_password.text.length < 4) {
      return strings.t('passwordTooShort');
    }
    return null;
  }

  Future<void> _save(
    BuildContext context,
    AppLocalizations strings,
    AccountService service,
    AppState state,
  ) async {
    final validationError = _validateForm(strings);
    if (validationError != null) {
      _showMessage(context, validationError);
      return;
    }

    setState(() => _saving = true);
    try {
      final emailRaw = _email.text.trim();
      await service.createStaffAccount(
        username: _username.text.trim(),
        fullName: _fullName.text.trim(),
        email: emailRaw.isEmpty ? null : emailRaw,
        passwordPlain: _password.text,
        role: _role,
      );
      if (!context.mounted) return;
      state.bumpAdminAccountsRevision();
      _showMessage(context, strings.t('adminAccountCreated'));
      navigateAdminSection(context, AdminNavSection.users);
    } on AccountValidationException catch (e) {
      if (context.mounted) {
        _showMessage(context, strings.t(e.messageKey));
      }
    } on AccountAccessDeniedException {
      if (context.mounted) {
        _showMessage(context, strings.t('adminAccessDenied'));
      }
    } catch (_) {
      if (context.mounted) {
        _showMessage(context, strings.t('adminAccountCreateFailed'));
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }
}
