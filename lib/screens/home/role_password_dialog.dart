import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';

Future<String?> showRolePasswordDialog(
  BuildContext context, {
  required String titleKey,
  required String hintKey,
}) {
  return showDialog<String>(
    context: context,
    barrierDismissible: false,
    builder: (_) => _RolePasswordDialog(
      titleKey: titleKey,
      hintKey: hintKey,
    ),
  );
}

class _RolePasswordDialog extends StatefulWidget {
  const _RolePasswordDialog({
    required this.titleKey,
    required this.hintKey,
  });

  final String titleKey;
  final String hintKey;

  @override
  State<_RolePasswordDialog> createState() => _RolePasswordDialogState();
}

class _RolePasswordDialogState extends State<_RolePasswordDialog> {
  final _controller = TextEditingController();
  String? _error;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context);
    return AlertDialog(
      title: Text(strings.t(widget.titleKey)),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            strings.t(widget.hintKey),
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _controller,
            obscureText: true,
            decoration: InputDecoration(
              labelText: strings.t('password'),
              errorText: _error,
            ),
            onSubmitted: (_) => _submit(strings),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(strings.t('cancelSimple')),
        ),
        FilledButton(
          onPressed: () => _submit(strings),
          child: Text(strings.t('unlock')),
        ),
      ],
    );
  }

  void _submit(AppLocalizations strings) {
    final p = _controller.text;
    if (p.isEmpty) {
      setState(() => _error = strings.t('passwordTooShort'));
      return;
    }
    Navigator.pop(context, p);
  }
}
