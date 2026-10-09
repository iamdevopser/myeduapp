import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../l10n/app_localizations.dart';
import '../../models/app_role.dart';
import '../../providers/app_state.dart';
import '../../services/account_service.dart';
import '../../theme/app_spacing.dart';
import '../../widgets/app_card.dart';
import 'admin_tab_workspace.dart';

/// İlk kurulum — aktif admin yoksa güvenli bootstrap.
class AdminBootstrapScreen extends StatefulWidget {
  const AdminBootstrapScreen({super.key});

  @override
  State<AdminBootstrapScreen> createState() => _AdminBootstrapScreenState();
}

class _AdminBootstrapScreenState extends State<AdminBootstrapScreen> {
  final _username = TextEditingController();
  final _fullName = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _passwordConfirm = TextEditingController();

  @override
  void dispose() {
    _username.dispose();
    _fullName.dispose();
    _email.dispose();
    _password.dispose();
    _passwordConfirm.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context);
    final width = MediaQuery.sizeOf(context).width;
    return Scaffold(
      appBar: AppBar(title: Text(strings.t('adminBootstrapTitle'))),
      body: SingleChildScrollView(
        padding: AppSpacing.pagePadding(width),
        child: AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(strings.t('adminBootstrapDesc')),
              const SizedBox(height: 16),
              TextField(
                controller: _username,
                decoration: InputDecoration(
                  labelText: strings.t('adminAccountUsername'),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _fullName,
                decoration: InputDecoration(
                  labelText: strings.t('adminAccountName'),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _email,
                decoration: InputDecoration(
                  labelText: strings.t('adminAccountEmail'),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _password,
                obscureText: true,
                decoration: InputDecoration(
                  labelText: strings.t('adminAccountPassword'),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _passwordConfirm,
                obscureText: true,
                decoration: InputDecoration(
                  labelText: strings.t('adminPasswordConfirm'),
                ),
              ),
              const SizedBox(height: 20),
              FilledButton(
                onPressed: () => _create(context, strings),
                child: Text(strings.t('adminBootstrapCreate')),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _create(BuildContext context, AppLocalizations strings) async {
    if (_password.text != _passwordConfirm.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(strings.t('adminPasswordMismatch'))),
      );
      return;
    }
    final state = context.read<AppState>();
    try {
      await AccountService(state.db, actorAccountId: 0).createBootstrapAdmin(
        username: _username.text,
        fullName: _fullName.text,
        email: _email.text.isEmpty ? null : _email.text,
        passwordPlain: _password.text,
      );
      final login = await state.loginRoleAccount(
        role: AppRole.admin,
        login: _username.text,
        password: _password.text,
      );
      if (!login.success) {
        throw StateError('bootstrap_login_failed');
      }
      state.setUnlocked(true, role: AppRole.admin);
      if (!context.mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => AdminTabWorkspace()),
      );
    } on AccountAccessDeniedException {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(strings.t('adminBootstrapExists'))),
        );
        Navigator.of(context).pop();
      }
    } on AccountValidationException catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(strings.t(e.messageKey))),
        );
      }
    }
  }
}
