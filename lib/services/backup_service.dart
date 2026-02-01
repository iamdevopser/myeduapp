import 'dart:io';

import 'package:archive/archive_io.dart';
import 'package:path/path.dart' as p;

import 'app_paths.dart';
import 'file_service.dart';

class BackupService {
  BackupService(this.paths, this.fileService);

  final AppPaths paths;
  final FileService fileService;

  Future<void> createBackup(String targetPath) async {
    final root = await paths.getRootDir();
    final encoder = ZipFileEncoder();
    encoder.create(targetPath);
    encoder.addDirectory(root);
    encoder.close();
  }

  Future<void> createZipFromDirectory(
    String sourcePath,
    String targetPath,
  ) async {
    final encoder = ZipFileEncoder();
    encoder.create(targetPath);
    encoder.addDirectory(Directory(sourcePath));
    encoder.close();
  }

  Future<void> restoreBackup(String zipPath) async {
    final root = await paths.getRootDir();
    final tempDir = await Directory.systemTemp.createTemp('myeduapp_restore_');
    final archive = ZipDecoder().decodeBytes(await File(zipPath).readAsBytes());
    extractArchiveToDisk(archive, tempDir.path);

    final extractedRoot = Directory(p.join(tempDir.path, p.basename(root.path)));
    final sourceDir = extractedRoot.existsSync() ? extractedRoot : tempDir;
    if (root.existsSync()) {
      await root.delete(recursive: true);
    }
    await fileService.copyDirectory(sourceDir, root);
  }
}

