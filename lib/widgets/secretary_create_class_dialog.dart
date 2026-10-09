import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import '../services/secretary_student_service.dart';
import '../utils/course_form_options.dart';

/// Sekreter: eğitim yılı + sınıf seviyesi + şube ile `ogrenci_siniflar` kaydı.
Future<bool> showSecretaryCreateClassDialog({
  required BuildContext context,
  required SecretaryStudentService service,
  required AppLocalizations strings,
}) async {
  final years = CourseFormOptions.academicYearOptions();
  var selectedYear = years.first;
  var selectedGrade = CourseFormOptions.minGrade;
  var selectedSection = CourseFormOptions.sectionOptions.first;

  final confirmed = await showDialog<bool>(
    context: context,
    builder: (dialogContext) {
      return StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            title: Text(strings.t('createNewClass')),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  DropdownButtonFormField<String>(
                    isExpanded: true,
                    value: selectedYear,
                    decoration: InputDecoration(
                      labelText: strings.t('academicYear'),
                    ),
                    items: years
                        .map(
                          (year) => DropdownMenuItem(
                            value: year,
                            child: Text(year),
                          ),
                        )
                        .toList(),
                    onChanged: (value) {
                      if (value != null) {
                        setDialogState(() => selectedYear = value);
                      }
                    },
                  ),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<int>(
                    isExpanded: true,
                    value: selectedGrade,
                    decoration: InputDecoration(
                      labelText: strings.t('studentClassName'),
                    ),
                    items: CourseFormOptions.grades()
                        .map(
                          (grade) => DropdownMenuItem(
                            value: grade,
                            child: Text(CourseFormOptions.gradeLabel(grade)),
                          ),
                        )
                        .toList(),
                    onChanged: (value) {
                      if (value != null) {
                        setDialogState(() => selectedGrade = value);
                      }
                    },
                  ),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String>(
                    isExpanded: true,
                    value: selectedSection,
                    decoration: InputDecoration(
                      labelText: strings.t('studentClassSection'),
                    ),
                    items: CourseFormOptions.sectionOptions
                        .map(
                          (section) => DropdownMenuItem(
                            value: section,
                            child: Text(section),
                          ),
                        )
                        .toList(),
                    onChanged: (value) {
                      if (value != null) {
                        setDialogState(() => selectedSection = value);
                      }
                    },
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext, false),
                child: Text(strings.t('cancelSimple')),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(dialogContext, true),
                child: Text(strings.t('save')),
              ),
            ],
          );
        },
      );
    },
  );

  if (confirmed != true || !context.mounted) return false;

  try {
    await service.createClassSection(
      grade: selectedGrade,
      section: selectedSection,
      year: selectedYear,
    );
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(strings.t('secretaryClassSectionCreated'))),
      );
    }
    return true;
  } on SecretaryClassValidationException catch (e) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(strings.t(e.messageKey))),
      );
    }
    return false;
  }
}
