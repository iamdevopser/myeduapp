import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../l10n/app_localizations.dart';
import '../../providers/app_state.dart';
import '../../services/academic_plan_import_service.dart';

Future<void> runAcademicPlanImport(
  BuildContext context, {
  required AcademicPlanImportKind kind,
  required VoidCallback onComplete,
}) async {
  final strings = AppLocalizations.of(context);
  final result = await FilePicker.platform.pickFiles(
    type: FileType.custom,
    allowedExtensions: const [
      'pdf',
      'docx',
      'xlsx',
      'xls',
      'csv',
      'txt',
    ],
  );
  final path = result?.files.single.path;
  if (path == null || !context.mounted) return;

  showDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (_) => const Center(child: CircularProgressIndicator()),
  );

  try {
    final importResult = await AcademicPlanImportService().importIntoDatabase(
      db: context.read<AppState>().db,
      path: path,
      kind: kind,
    );
    if (!context.mounted) return;
    Navigator.of(context, rootNavigator: true).pop();
    final String message;
    if (importResult.parsedCount == 0) {
      message = strings.t('academicPlanImportNoPlans');
    } else if (importResult.importedCount == 0) {
      message = strings.t('academicPlanImportAllSkipped');
    } else {
      message = strings
          .t('academicPlanImportDone')
          .replaceAll('{imported}', '${importResult.importedCount}')
          .replaceAll('{skipped}', '${importResult.skippedCount}');
    }
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
    onComplete();
  } catch (e) {
    if (!context.mounted) return;
    Navigator.of(context, rootNavigator: true).pop();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(strings.t('academicPlanImportFailed'))),
    );
  }
}
