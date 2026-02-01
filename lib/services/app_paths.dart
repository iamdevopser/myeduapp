import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../utils/path_utils.dart';

class AppPaths {
  Future<Directory> getRootDir() async {
    final docs = await getApplicationDocumentsDirectory();
    final root = Directory(p.join(docs.path, 'MyEduAppData'));
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
    final lessonDir =
        Directory(p.join(classDir.path, sanitizePathSegment(lessonName)));
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

}

