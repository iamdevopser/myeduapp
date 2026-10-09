import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../l10n/app_localizations.dart';
import '../providers/app_state.dart';
import '../utils/app_navigation.dart';

/// Shown when teacher uses default password. Forces password change.
/// After change, returns to home - teacher must login again with new password.
class ChangeTeacherPasswordScreen extends StatefulWidget {
  const ChangeTeacherPasswordScreen({super.key});

  @override
  State<ChangeTeacherPasswordScreen> createState() =>
      _ChangeTeacherPasswordScreenState();
}

class _ChangeTeacherPasswordScreenState extends State<ChangeTeacherPasswordScreen> {
  final _newController = TextEditingController();
  final _confirmController = TextEditingController();
  String? _error;

  @override
  void dispose() {
    _newController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(strings.t('changeTeacherPassword')),
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
                      onPressed: () => _save(strings),
                      child: Text(strings.t('save')),
                    ),
                  ],
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

    await context.read<AppState>().setTeacherPassword(newPass);

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(strings.t('passwordChangedSuccess'))),
    );

    context.read<AppState>().clearSession();
    logoutToLogin(context);
  }
}
