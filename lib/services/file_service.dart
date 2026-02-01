import 'dart:io';

import 'package:path/path.dart' as p;

import '../utils/path_utils.dart';
import 'app_paths.dart';

class FileService {
  FileService(this.paths);

  final AppPaths paths;

  static const supportedExtensions = [
    'pdf',
    'doc',
    'docx',
    'jpg',
    'jpeg',
    'png',
    'mp3',
    'wav',
    'mp4',
    'avi',
  ];

  String typeForFile(String filePath) {
    final ext = p.extension(filePath).toLowerCase().replaceFirst('.', '');
    if (['mp3', 'wav'].contains(ext)) {
      return 'audio';
    }
    if (['mp4', 'avi'].contains(ext)) {
      return 'video';
    }
    if (['jpg', 'jpeg', 'png'].contains(ext)) {
      return 'image';
    }
    if (['pdf'].contains(ext)) {
      return 'pdf';
    }
    if (['doc', 'docx'].contains(ext)) {
      return 'word';
    }
    return 'file';
  }

  Future<String> copyFileToContentDir({
    required String sourcePath,
    required String className,
    required String lessonName,
    String? topicName,
  }) async {
    final contentDir = await paths.getContentDir(
      className,
      lessonName,
      topicName: topicName,
    );
    final originalName = p.basename(sourcePath);
    final safeName = sanitizePathSegment(originalName);
    final fileName =
        '${DateTime.now().millisecondsSinceEpoch}_$safeName';
    final targetPath = p.join(contentDir.path, fileName);
    await File(sourcePath).copy(targetPath);
    return targetPath;
  }

  Future<List<String>> importFolder({
    required String folderPath,
    required String className,
    required String lessonName,
    String? topicName,
  }) async {
    final contentDir = await paths.getContentDir(
      className,
      lessonName,
      topicName: topicName,
    );
    final folderName = sanitizePathSegment(p.basename(folderPath));
    final targetRoot = Directory(p.join(contentDir.path, folderName));
    if (!targetRoot.existsSync()) {
      targetRoot.createSync(recursive: true);
    }
    final copiedFiles = <String>[];
    final sourceDir = Directory(folderPath);
    await for (final entity in sourceDir.list(recursive: true)) {
      if (entity is File) {
        final ext =
            p.extension(entity.path).toLowerCase().replaceFirst('.', '');
        if (!supportedExtensions.contains(ext)) {
          continue;
        }
        final relative = p.relative(entity.path, from: folderPath);
        final targetPath = p.join(targetRoot.path, relative);
        final targetDir = Directory(p.dirname(targetPath));
        if (!targetDir.existsSync()) {
          targetDir.createSync(recursive: true);
        }
        await entity.copy(targetPath);
        copiedFiles.add(targetPath);
      }
    }
    return copiedFiles;
  }

  Future<void> deleteFile(String path) async {
    final file = File(path);
    if (await file.exists()) {
      await file.delete();
    }
  }

  Future<void> deleteDirectory(String path) async {
    final dir = Directory(path);
    if (await dir.exists()) {
      await dir.delete(recursive: true);
    }
  }

  Future<void> renameDirectory(String oldPath, String newPath) async {
    final dir = Directory(oldPath);
    if (!dir.existsSync()) {
      return;
    }
    final target = Directory(newPath);
    if (target.existsSync()) {
      await target.delete(recursive: true);
    }
    await dir.rename(newPath);
  }

  Future<void> replaceDirectory(String sourcePath, String targetPath) async {
    final sourceDir = Directory(sourcePath);
    if (!sourceDir.existsSync()) {
      return;
    }
    final targetDir = Directory(targetPath);
    if (targetDir.existsSync()) {
      await targetDir.delete(recursive: true);
    }
    await sourceDir.rename(targetPath);
  }

  Future<void> copyDirectory(Directory source, Directory target) async {
    if (!target.existsSync()) {
      target.createSync(recursive: true);
    }
    await for (final entity in source.list(recursive: false)) {
      if (entity is Directory) {
        final newDir = Directory(p.join(target.path, p.basename(entity.path)));
        await copyDirectory(entity, newDir);
      } else if (entity is File) {
        final newFile = File(p.join(target.path, p.basename(entity.path)));
        await entity.copy(newFile.path);
      }
    }
  }

  Future<void> openPath(String path) async {
    if (Platform.isWindows) {
      await Process.start('cmd', ['/c', 'start', '', path]);
      return;
    }
    if (Platform.isMacOS) {
      await Process.start('open', [path]);
      return;
    }
    if (Platform.isLinux) {
      await Process.start('xdg-open', [path]);
    }
  }

  Future<String> copyToQuestionBank(String sourcePath) async {
    final bankDir = await paths.getQuestionBankDir();
    final originalName = p.basename(sourcePath);
    final safeName = sanitizePathSegment(originalName);
    final fileName = '${DateTime.now().millisecondsSinceEpoch}_$safeName';
    final targetPath = p.join(bankDir.path, fileName);
    await File(sourcePath).copy(targetPath);
    return targetPath;
  }

}

