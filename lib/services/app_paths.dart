import 'dart:io';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../utils/path_utils.dart';

/// Desktop: taşınabilir mod — veriler exe ile aynı dizinde.
/// Android/iOS: uygulama belgeler dizininde MyEduAppData.
class AppPaths {
  Future<String> _dataParentPath() async {
    if (!kIsWeb && (Platform.isAndroid || Platform.isIOS)) {
      final appDir = await getApplicationDocumentsDirectory();
      return appDir.path;
    }
    return p.dirname(Platform.resolvedExecutable);
  }

  Future<Directory> getRootDir() async {
    final parent = await _dataParentPath();
    final root = Directory(p.join(parent, 'MyEduAppData'));
    if (!root.existsSync()) {
      root.createSync(recursive: true);
    }
    return root;
  }

  Future<Directory> getClassesDir() async {
    final root = await getRootDir();
    final classes = Directory(p.join(root.path, 'Siniflar'));
    if (!classes.existsSync()) {
      classes.createSync(recursive: true);
    }
    return classes;
  }

  Future<Directory> getClassDir(String className) async {
    final classes = await getClassesDir();
    final dir = Directory(p.join(classes.path, sanitizePathSegment(className)));
    if (!dir.existsSync()) {
      dir.createSync(recursive: true);
    }
    return dir;
  }

  Future<Directory> getLessonDir(String className, String lessonName) async {
    final classDir = await getClassDir(className);
    final lessonDir = Directory(
      p.join(classDir.path, sanitizePathSegment(lessonName)),
    );
    if (!lessonDir.existsSync()) {
      lessonDir.createSync(recursive: true);
    }
    return lessonDir;
  }

  Future<Directory> getContentDir(
    String className,
    String lessonName, {
    String? topicName,
  }) async {
    final lessonDir = await getLessonDir(className, lessonName);
    final baseDir = topicName == null
        ? lessonDir
        : Directory(p.join(lessonDir.path, sanitizePathSegment(topicName)));
    if (!baseDir.existsSync()) {
      baseDir.createSync(recursive: true);
    }
    final contentDir = Directory(p.join(baseDir.path, 'Icerikler'));
    if (!contentDir.existsSync()) {
      contentDir.createSync(recursive: true);
    }
    return contentDir;
  }

  Future<Directory> getQuestionBankDir() async {
    final root = await getRootDir();
    final dir = Directory(p.join(root.path, 'SoruBankasi'));
    if (!dir.existsSync()) {
      dir.createSync(recursive: true);
    }
    return dir;
  }

  /// Kapak/görsel medya dosyaları (Gorseller/{category}/).
  Future<Directory> getMediaDir(String category) async {
    final root = await getRootDir();
    final dir = Directory(
      p.join(root.path, 'Gorseller', sanitizePathSegment(category)),
    );
    if (!dir.existsSync()) {
      dir.createSync(recursive: true);
    }
    return dir;
  }
}
