import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import '../utils/course_form_options.dart';
import '../utils/email_validation.dart';

/// Öğretmen ve sekreter öğrenci düzenleme formu.
Future<Map<String, dynamic>?> showStudentProfileEditDialog(
  BuildContext context, {
  required Map<String, Object?> student,
  List<Map<String, Object?>>? classOptions,
}) async {
  final strings = AppLocalizations.of(context);
  final nameController =
      TextEditingController(text: student['ad_soyad'] as String? ?? '');
  final numberController =
      TextEditingController(text: '${student['numara'] ?? ''}');
  final emailController =
      TextEditingController(text: student['email'] as String? ?? '');
  final motherEmailController =
      TextEditingController(text: student['anne_email'] as String? ?? '');
  final fatherEmailController =
      TextEditingController(text: student['baba_email'] as String? ?? '');
  int? selectedClassId = student['sinif_id'] as int?;

  return showDialog<Map<String, dynamic>>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: Text(strings.t('edit')),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (classOptions != null && classOptions.isNotEmpty)
              DropdownButtonFormField<int>(
                value: selectedClassId,
                decoration: InputDecoration(
                  labelText: strings.t('studentClassName'),
                ),
                items: classOptions.map((row) {
                  final id = row['id'] as int;
                  final label = CourseFormOptions.studentClassGradeSectionLabel(
                    row['ad'] as String? ?? '',
                    section: row['sube'] as String?,
                  );
                  return DropdownMenuItem(value: id, child: Text(label));
                }).toList(),
                onChanged: (value) => selectedClassId = value,
              ),
            TextField(
              controller: numberController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: strings.t('studentNumber'),
              ),
            ),
            TextField(
              controller: nameController,
              decoration: InputDecoration(labelText: strings.t('studentName')),
            ),
            TextField(
              controller: emailController,
              keyboardType: TextInputType.emailAddress,
              decoration: InputDecoration(
                labelText: strings.t('studentEmail'),
              ),
            ),
            TextField(
              controller: motherEmailController,
              keyboardType: TextInputType.emailAddress,
              decoration: InputDecoration(
                labelText: strings.t('motherEmail'),
              ),
            ),
            TextField(
              controller: fatherEmailController,
              keyboardType: TextInputType.emailAddress,
              decoration: InputDecoration(
                labelText: strings.t('fatherEmail'),
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(dialogContext).pop(),
          child: Text(strings.t('cancelSimple')),
        ),
        FilledButton(
          onPressed: () {
            final name = nameController.text.trim();
            final number = int.tryParse(numberController.text.trim());
            if (name.isEmpty || number == null) {
              return;
            }
            if (classOptions != null &&
                classOptions.isNotEmpty &&
                selectedClassId == null) {
              return;
            }
            final email = emailController.text.trim();
            final motherEmail = motherEmailController.text.trim();
            final fatherEmail = fatherEmailController.text.trim();
            for (final entry in [email, motherEmail, fatherEmail]) {
              if (entry.isNotEmpty && !isValidEmail(entry)) {
                ScaffoldMessenger.of(dialogContext).showSnackBar(
                  SnackBar(content: Text(strings.t('invalidEmail'))),
                );
                return;
              }
            }
            Navigator.of(dialogContext).pop({
              'name': name,
              'number': number,
              'email': email.isEmpty ? null : email,
              'motherEmail': motherEmail.isEmpty ? null : motherEmail,
              'fatherEmail': fatherEmail.isEmpty ? null : fatherEmail,
              if (selectedClassId != null) 'classId': selectedClassId,
            });
          },
          child: Text(strings.t('save')),
        ),
      ],
    ),
  );
}
