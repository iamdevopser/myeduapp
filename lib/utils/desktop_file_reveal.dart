import 'dart:developer' as developer;
import 'dart:io';

import 'package:path/path.dart' as p;

/// Win32: `/select,<path>` — path with spaces must be quoted in one argument.
String windowsExplorerSelectArgument(String absolutePath) {
  final normalized = absolutePath.replaceAll('/', '\\');
  final safe = normalized.replaceAll('"', '');
  if (RegExp(r'\s').hasMatch(safe)) {
    return '/select,"$safe"';
  }
  return '/select,$safe';
}

/// Opens the system file manager and highlights [filePath] when the platform
/// supports it. Returns false if the UI could not be opened (export may still
/// have succeeded).
Future<bool> revealSavedFileInSystemFileManager(String filePath) async {
  try {
    final file = File(filePath);
    final absolute = file.absolute.path;
    if (!await file.exists()) {
      return _openFolderPath(p.dirname(absolute));
    }

    if (Platform.isWindows) {
      final selectArg = windowsExplorerSelectArgument(absolute);
      try {
        await Process.run('explorer.exe', [selectArg]);
        return true;
      } catch (e, st) {
        developer.log(
          'explorer /select failed for $absolute',
          name: 'desktop_file_reveal',
          error: e,
          stackTrace: st,
        );
      }
      try {
        await Process.run('explorer.exe', [p.dirname(absolute)]);
        return true;
      } catch (e, st) {
        developer.log(
          'explorer open folder failed for $absolute',
          name: 'desktop_file_reveal',
          error: e,
          stackTrace: st,
        );
        return false;
      }
    }
    if (Platform.isMacOS) {
      final result = await Process.run('open', ['-R', absolute]);
      if (result.exitCode == 0) return true;
      return _openFolderPath(p.dirname(absolute));
    }
    if (Platform.isLinux) {
      return _openFolderPath(p.dirname(absolute));
    }
    return false;
  } catch (e, st) {
    developer.log(
      'revealSavedFileInSystemFileManager failed for $filePath',
      name: 'desktop_file_reveal',
      error: e,
      stackTrace: st,
    );
    return false;
  }
}

Future<bool> _openFolderPath(String folderPath) async {
  try {
    final dir = Directory(folderPath);
    if (!await dir.exists()) return false;
    final absolute = dir.absolute.path;
    if (Platform.isWindows) {
      await Process.run('explorer.exe', [absolute]);
      return true;
    }
    if (Platform.isMacOS) {
      final result = await Process.run('open', [absolute]);
      return result.exitCode == 0;
    }
    if (Platform.isLinux) {
      final result = await Process.run('xdg-open', [absolute]);
      return result.exitCode == 0;
    }
    return false;
  } catch (e, st) {
    developer.log(
      'open folder failed for $folderPath',
      name: 'desktop_file_reveal',
      error: e,
      stackTrace: st,
    );
    return false;
  }
}
