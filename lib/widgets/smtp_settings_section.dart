import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../data/models/smtp_settings.dart';
import '../l10n/app_localizations.dart';
import '../providers/app_state.dart';
import '../services/report_email_service.dart';
import '../utils/email_validation.dart';
import '../utils/smtp_server_factory.dart';
import 'settings_section.dart';

class SmtpSettingsSection extends StatefulWidget {
  const SmtpSettingsSection({super.key});

  @override
  State<SmtpSettingsSection> createState() => _SmtpSettingsSectionState();
}

class _SmtpSettingsSectionState extends State<SmtpSettingsSection> {
  final _hostController = TextEditingController();
  final _portController = TextEditingController(text: '587');
  final _userController = TextEditingController();
  final _passwordController = TextEditingController();
  final _fromController = TextEditingController();
  bool _useSsl = false;
  bool _loading = true;
  bool _saving = false;
  bool _testing = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _hostController.dispose();
    _portController.dispose();
    _userController.dispose();
    _passwordController.dispose();
    _fromController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final settings = await context.read<AppState>().loadSmtpSettings();
    if (!mounted) return;
    _hostController.text = settings.host;
    _portController.text = '${settings.port}';
    _userController.text = settings.username;
    _passwordController.text = settings.password;
    _fromController.text = settings.fromEmail;
    _useSsl = settings.useSsl;
    setState(() => _loading = false);
  }

  Future<void> _save() async {
    final strings = AppLocalizations.of(context);
    final from = _fromController.text.trim();
    if (!isValidEmail(from)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(strings.t('smtpInvalidFromEmail'))),
      );
      return;
    }
    final port = int.tryParse(_portController.text.trim()) ?? 587;
    final settings = normalizeSmtpSettings(
      SmtpSettings(
        host: _hostController.text.trim(),
        port: port,
        username: _userController.text.trim(),
        password: _passwordController.text,
        fromEmail: from,
        useSsl: _useSsl,
      ),
    );
    setState(() => _saving = true);
    try {
      await context.read<AppState>().saveSmtpSettings(settings);
      _hostController.text = settings.host;
      _portController.text = '${settings.port}';
      _userController.text = settings.username;
      _fromController.text = settings.fromEmail;
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(strings.t('smtpSettingsSaved'))),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  SmtpSettings _currentSettings() {
    final port = int.tryParse(_portController.text.trim()) ?? 587;
    return normalizeSmtpSettings(
      SmtpSettings(
        host: _hostController.text.trim(),
        port: port,
        username: _userController.text.trim(),
        password: _passwordController.text,
        fromEmail: _fromController.text.trim(),
        useSsl: _useSsl,
      ),
    );
  }

  Future<void> _testConnection() async {
    final strings = AppLocalizations.of(context);
    final settings = _currentSettings();
    if (!settings.isConfigured) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(strings.t('smtpNotConfigured'))),
      );
      return;
    }
    if (!isValidEmail(settings.fromEmail)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(strings.t('smtpInvalidFromEmail'))),
      );
      return;
    }
    setState(() => _testing = true);
    try {
      await ReportEmailService().verifyConnection(settings);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(strings.t('smtpTestSuccess'))),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(resolveSmtpErrorMessage(strings, e)),
          duration: const Duration(seconds: 8),
        ),
      );
    } finally {
      if (mounted) setState(() => _testing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context);
    if (_loading) {
      return SettingsSection(
        title: strings.t('smtpSettings'),
        icon: Icons.email_outlined,
        children: const [
          Padding(
            padding: EdgeInsets.all(16),
            child: Center(child: CircularProgressIndicator()),
          ),
        ],
      );
    }
    return SettingsSection(
      title: strings.t('smtpSettings'),
      icon: Icons.email_outlined,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
          child: Text(
            strings.t('smtpSettingsHint'),
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
          child: Text(
            strings.t('smtpGmailSetupHint'),
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.primary,
                ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: TextField(
            controller: _hostController,
            decoration: InputDecoration(labelText: strings.t('smtpHost')),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: TextField(
            controller: _portController,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(labelText: strings.t('smtpPort')),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: TextField(
            controller: _userController,
            decoration: InputDecoration(labelText: strings.t('smtpUsername')),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: TextField(
            controller: _passwordController,
            obscureText: true,
            decoration: InputDecoration(labelText: strings.t('smtpPassword')),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: TextField(
            controller: _fromController,
            keyboardType: TextInputType.emailAddress,
            decoration: InputDecoration(labelText: strings.t('smtpFromEmail')),
          ),
        ),
        SwitchListTile(
          title: Text(strings.t('smtpUseSsl')),
          subtitle: Text(strings.t('smtpUseSslHint')),
          value: _useSsl,
          onChanged: (value) => setState(() => _useSsl = value),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          child: Wrap(
            spacing: 12,
            runSpacing: 8,
            children: [
              FilledButton(
                onPressed: _saving ? null : _save,
                child: _saving
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Text(strings.t('save')),
              ),
              OutlinedButton(
                onPressed: (_saving || _testing) ? null : _testConnection,
                child: _testing
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Text(strings.t('smtpTestConnection')),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
