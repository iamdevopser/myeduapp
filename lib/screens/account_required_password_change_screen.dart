import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../l10n/app_localizations.dart';
import '../models/app_role.dart';
import '../providers/app_state.dart';
import '../services/account_service.dart';
import '../utils/app_navigation.dart';
import '../utils/role_workspace_navigation.dart';

/// Merkezi hesap girişinde `mustChangePassword` true ise workspace bypass edilmez.
class AccountRequiredPasswordChangeScreen extends StatefulWidget {
  const AccountRequiredPasswordChangeScreen({
    super.key,
    required this.role,
  });

  final AppRole role;

  @override
  State<AccountRequiredPasswordChangeScreen> createState() =>
      _AccountRequiredPasswordChangeScreenState();
}

class _AccountRequiredPasswordChangeScreenState
    extends State<AccountRequiredPasswordChangeScreen> {
  final _newController = TextEditingController();
  final _confirmController = TextEditingController();
  String? _error;
  bool _saving = false;

  @override
  void dispose() {
    _newController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  void _abortToLogin() {
    context.read<AppState>().clearSession();
    logoutToLogin(context);
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context);
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) _abortToLogin();
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(strings.t('changePassword')),
          automaticallyImplyLeading: false,
        ),
        body: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 400),
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        strings.t('changePasswordRequired'),
                        style: Theme.of(context).textTheme.bodyLarge,
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 24),
                      TextField(
                        controller: _newController,
                        obscureText: true,
                        decoration: InputDecoration(
                          labelText: strings.t('newPassword'),
                          errorText: _error,
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: _confirmController,
                        obscureText: true,
                        decoration: InputDecoration(
                          labelText: strings.t('confirmPassword'),
                        ),
                        onSubmitted: (_) => _save(strings),
                      ),
                      const SizedBox(height: 24),
                      FilledButton(
                        onPressed: _saving ? null : () => _save(strings),
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
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _save(AppLocalizations strings) async {
    final newPass = _newController.text;
    final confirm = _confirmController.text;

    if (newPass.length < 4) {
      setState(() => _error = strings.t('passwordTooShort'));
      return;
    }
    if (newPass != confirm) {
      setState(() => _error = strings.t('passwordMismatch'));
      return;
    }

    final state = context.read<AppState>();
    final accountId = state.sessionAccountId;
    if (accountId == null) {
      _abortToLogin();
      return;
    }

    setState(() {
      _error = null;
      _saving = true;
    });

    try {
      await AccountService(state.db, actorAccountId: accountId)
          .changePasswordAsAccountOwner(
        accountId: accountId,
        actorAccountId: accountId,
        newPasswordPlain: newPass,
      );
    } on AccountValidationException catch (e) {
      if (mounted) {
        setState(() {
          _error = strings.t(e.messageKey);
          _saving = false;
        });
      }
      return;
    } on AccountAccessDeniedException {
      if (mounted) _abortToLogin();
      return;
    }

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(strings.t('passwordChangedSuccess'))),
    );

    state.setUnlocked(true, role: widget.role);
    openRolePrimaryWorkspace(context, widget.role);
  }
}
