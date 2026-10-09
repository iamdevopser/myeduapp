import 'dart:developer' as developer;
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;

import '../l10n/app_localizations.dart';
import 'desktop_file_reveal.dart';
import 'path_utils.dart';

enum ReportSavePickOutcome { success, cancelled, failed }

class ReportSavePickResult {
  const ReportSavePickResult._({
    required this.outcome,
    this.path,
  });

  final ReportSavePickOutcome outcome;
  final String? path;

  factory ReportSavePickResult.success(String path) {
    return ReportSavePickResult._(
      outcome: ReportSavePickOutcome.success,
      path: path,
    );
  }

  factory ReportSavePickResult.cancelled() {
    return const ReportSavePickResult._(
      outcome: ReportSavePickOutcome.cancelled,
    );
  }

  factory ReportSavePickResult.failed() {
    return const ReportSavePickResult._(
      outcome: ReportSavePickOutcome.failed,
    );
  }
}

String _reportExportBaseFileName(String suggestedFileName, String ext) {
  var fileName = p.basename(suggestedFileName);
  final dot = fileName.lastIndexOf('.');
  if (dot > 0) {
    fileName = fileName.substring(0, dot);
  }
  fileName = sanitizeReportFileStem(fileName);
  return '$fileName.$ext';
}

/// Kaydet diyalogundan gelen tam path: dosya adındaki tab/çoklu boşlukları düzeltir (Win errno 123).
String sanitizeWindowsExportFilePath(String fullPath) {
  final dir = p.dirname(fullPath);
  final base = p.basename(fullPath);
  final dot = base.lastIndexOf('.');
  if (dot <= 0) {
    return p.join(dir, sanitizeReportFileStem(base));
  }
  final stem = base.substring(0, dot);
  final extension = base.substring(dot);
  return p.join(dir, '${sanitizeReportFileStem(stem)}$extension');
}

/// Desktop save dialog for report export. Matches [Settings] backup save first;
/// retries when file_picker returns null (failed dialog vs cancel is ambiguous).
Future<ReportSavePickResult> pickReportExportSavePath({
  required String dialogTitle,
  required String suggestedFileName,
  required String extension,
  String? folderPickDialogTitle,
}) async {
  final ext = extension.startsWith('.') ? extension.substring(1) : extension;
  final fileName = _reportExportBaseFileName(suggestedFileName, ext);

  Future<String?> runSave({
    required FileType type,
    List<String>? allowedExtensions,
    bool lockParentWindow = false,
  }) async {
    return FilePicker.platform.saveFile(
      dialogTitle: dialogTitle,
      fileName: fileName,
      type: type,
      allowedExtensions: allowedExtensions,
      lockParentWindow: lockParentWindow,
    );
  }

  Object? lastError;
  var nullSaveCount = 0;

  // 1) Same as Settings > Backup on desktop (no lockParentWindow, no initialDirectory).
  try {
    final path = await runSave(
      type: FileType.custom,
      allowedExtensions: [ext],
    );
    if (path != null && path.isNotEmpty) {
      return ReportSavePickResult.success(path);
    }
    nullSaveCount++;
  } catch (e, st) {
    lastError = e;
    developer.log(
      'Report saveFile (backup-style) failed: fileName=$fileName',
      name: 'report_export_support',
      error: e,
      stackTrace: st,
    );
  }

  // 2) file_picker can return null when the dialog fails to open — retry looser filter.
  try {
    final path = await runSave(type: FileType.any);
    if (path != null && path.isNotEmpty) {
      return ReportSavePickResult.success(path);
    }
    nullSaveCount++;
  } catch (e, st) {
    lastError = e;
    developer.log(
      'Report saveFile (any type) failed: fileName=$fileName',
      name: 'report_export_support',
      error: e,
      stackTrace: st,
    );
  }

  // 3) Optional parent lock (last resort for save dialog).
  if (Platform.isWindows) {
    try {
      final path = await runSave(
        type: FileType.custom,
        allowedExtensions: [ext],
        lockParentWindow: true,
      );
      if (path != null && path.isNotEmpty) {
        return ReportSavePickResult.success(path);
      }
      nullSaveCount++;
    } catch (e, st) {
      lastError = e;
      developer.log(
        'Report saveFile (lock parent) failed: fileName=$fileName',
        name: 'report_export_support',
        error: e,
        stackTrace: st,
      );
    }
  }

  // 4) Folder picker — often works when save dialog does not.
  try {
    final dir = await FilePicker.platform.getDirectoryPath(
      dialogTitle: folderPickDialogTitle ?? dialogTitle,
    );
    if (dir != null && dir.isNotEmpty) {
      return ReportSavePickResult.success(p.join(dir, fileName));
    }
  } catch (e, st) {
    lastError = e;
    developer.log(
      'Report getDirectoryPath failed: fileName=$fileName',
      name: 'report_export_support',
      error: e,
      stackTrace: st,
    );
  }

  if (nullSaveCount > 0 || lastError != null) {
    developer.log(
      'Report save picker exhausted: nullSaveCount=$nullSaveCount '
      'lastError=$lastError fileName=$fileName',
      name: 'report_export_support',
    );
    return ReportSavePickResult.failed();
  }

  return ReportSavePickResult.cancelled();
}

/// Folder picker for multi-file report export (one PDF per student).
Future<ReportSavePickResult> pickReportExportDirectory({
  required String dialogTitle,
}) async {
  Object? lastError;
  try {
    final dir = await FilePicker.platform.getDirectoryPath(
      dialogTitle: dialogTitle,
    );
    if (dir != null && dir.isNotEmpty) {
      return ReportSavePickResult.success(dir);
    }
  } catch (e, st) {
    lastError = e;
    developer.log(
      'Report bulk getDirectoryPath failed',
      name: 'report_export_support',
      error: e,
      stackTrace: st,
    );
  }

  if (lastError != null) {
    return ReportSavePickResult.failed();
  }
  return ReportSavePickResult.cancelled();
}

/// Picks a file path in [directory] that does not exist yet (`name (2).pdf`, …).
Future<String> uniqueExportPathInDirectory(
  String directory,
  String fileName,
) async {
  final safeName = p.basename(fileName);
  var candidate = p.join(directory, safeName);
  if (!await File(candidate).exists()) {
    return candidate;
  }
  final dot = safeName.lastIndexOf('.');
  final stem = dot > 0 ? safeName.substring(0, dot) : safeName;
  final ext = dot > 0 ? safeName.substring(dot) : '';
  for (var i = 2; i <= 99; i++) {
    candidate = p.join(directory, '$stem ($i)$ext');
    if (!await File(candidate).exists()) {
      return candidate;
    }
  }
  return p.join(directory, safeName);
}

/// Ensures [path] ends with `.$extension` (file_picker on Windows may omit it).
String normalizeReportSavePath(String path, String extension) {
  var normalized = sanitizeWindowsExportFilePath(path);
  final ext = extension.startsWith('.') ? extension.substring(1) : extension;
  final lower = normalized.toLowerCase();
  final suffix = '.$ext';
  if (!lower.endsWith(suffix)) {
    normalized = '$normalized$suffix';
  }
  return sanitizeWindowsExportFilePath(normalized);
}

Future<void> ensureReportExportParentDirectory(String filePath) async {
  final dir = Directory(p.dirname(filePath));
  if (!await dir.exists()) {
    await dir.create(recursive: true);
  }
}

Future<bool> reportExportFileExists(String filePath) async {
  return File(filePath).exists();
}

/// Success snackbar first, then Explorer reveal (failure does not undo export).
Future<void> showReportExportSuccessAndReveal({
  required BuildContext context,
  required AppLocalizations strings,
  required String savedPath,
  required String savedMessageKey,
}) async {
  if (!await reportExportFileExists(savedPath)) {
    throw FileSystemException('Exported file missing after write.', savedPath);
  }
  if (!context.mounted) return;
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text(strings.t(savedMessageKey))),
  );

  try {
    await Future<void>.delayed(const Duration(milliseconds: 150));
    final revealed = await revealSavedFileInSystemFileManager(savedPath);
    if (!context.mounted) return;
    if (!revealed) {
      developer.log(
        'Report export reveal failed: path=$savedPath',
        name: 'report_export_support',
      );
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(strings.t('exportRevealFailed'))),
      );
    }
  } catch (e, st) {
    developer.log(
      'Report export reveal error: path=$savedPath',
      name: 'report_export_support',
      error: e,
      stackTrace: st,
    );
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(strings.t('exportRevealFailed'))),
    );
  }
}
