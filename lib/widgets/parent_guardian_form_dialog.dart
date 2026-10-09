import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import '../utils/email_validation.dart';

class ParentGuardianFormData {
  const ParentGuardianFormData({
    required this.fullName,
    this.phone,
    this.email,
    this.address,
    this.notes,
  });

  final String fullName;
  final String? phone;
  final String? email;
  final String? address;
  final String? notes;
}

Future<ParentGuardianFormData?> showParentGuardianFormDialog(
  BuildContext context, {
  String? titleKey,
  ParentGuardianFormData? initial,
}) async {
  final strings = AppLocalizations.of(context);
  final nameController = TextEditingController(text: initial?.fullName ?? '');
  final phoneController = TextEditingController(text: initial?.phone ?? '');
  final emailController = TextEditingController(text: initial?.email ?? '');
  final addressController = TextEditingController(text: initial?.address ?? '');
  final notesController = TextEditingController(text: initial?.notes ?? '');

  return showDialog<ParentGuardianFormData>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: Text(strings.t(titleKey ?? 'secretaryParentEdit')),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: InputDecoration(
                labelText: strings.t('parentFullName'),
              ),
            ),
            TextField(
              controller: phoneController,
              keyboardType: TextInputType.phone,
              decoration: InputDecoration(
                labelText: strings.t('parentPhone'),
              ),
            ),
            TextField(
              controller: emailController,
              keyboardType: TextInputType.emailAddress,
              decoration: InputDecoration(
                labelText: strings.t('parentEmail'),
              ),
            ),
            TextField(
              controller: addressController,
              decoration: InputDecoration(
                labelText: strings.t('parentAddress'),
              ),
            ),
            TextField(
              controller: notesController,
              decoration: InputDecoration(
                labelText: strings.t('parentNotes'),
              ),
              minLines: 1,
              maxLines: 3,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(dialogContext),
          child: Text(strings.t('cancelSimple')),
        ),
        FilledButton(
          onPressed: () {
            final name = nameController.text.trim();
            if (name.isEmpty) return;
            final email = emailController.text.trim();
            if (email.isNotEmpty && !isValidEmail(email)) {
              ScaffoldMessenger.of(dialogContext).showSnackBar(
                SnackBar(content: Text(strings.t('invalidEmail'))),
              );
              return;
            }
            Navigator.pop(
              dialogContext,
              ParentGuardianFormData(
                fullName: name,
                phone: phoneController.text.trim().isEmpty
                    ? null
                    : phoneController.text.trim(),
                email: email.isEmpty ? null : email,
                address: addressController.text.trim().isEmpty
                    ? null
                    : addressController.text.trim(),
                notes: notesController.text.trim().isEmpty
                    ? null
                    : notesController.text.trim(),
              ),
            );
          },
          child: Text(strings.t('save')),
        ),
      ],
    ),
  );
}
