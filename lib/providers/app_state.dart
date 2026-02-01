import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;

import '../data/local/app_database.dart';
import '../data/models/class_model.dart';
import '../data/models/content_with_tags.dart';
import '../data/models/exam_question.dart';
import '../data/models/lesson_model.dart';
import '../data/models/tag_model.dart';
import '../data/models/topic_model.dart';
import '../services/app_paths.dart';
import '../services/backup_service.dart';
import '../services/file_service.dart';
import '../services/pdf_service.dart';
import '../services/security_service.dart';
import '../utils/path_utils.dart';

class AppState extends ChangeNotifier {
  AppState({
    required this.db,
    required this.paths,
    required this.fileService,
    required this.backupService,
    required this.pdfService,
    required this.securityService,
  });

  final AppDatabase db;
  final AppPaths paths;
  final FileService fileService;
  final BackupService backupService;
  final PdfService pdfService;
  final SecurityService securityService;

  List<ClassModel> classes = [];
  List<LessonModel> lessons = [];
  List<ContentWithTags> contents = [];
  List<TagModel> tags = [];
  List<TopicModel> topics = [];
  Set<int> favoriteContentIds = {};
  bool showArchived = false;

  ClassModel? selectedClass;
  LessonModel? selectedLesson;
  ContentWithTags? selectedContent;
  TopicModel? selectedTopic;

  String searchQuery = '';
  Set<int> filterTagIds = {};

  Locale locale = const Locale('tr');
  bool lockEnabled = false;
  String? passwordHash;
  bool autoBackupEnabled = false;
  int autoBackupMinutes = 60;
  Timer? _autoBackupTimer;
  ThemeMode themeMode = ThemeMode.system;

  static const _settingsLanguageKey = 'language_code';
  static const _settingsLockKey = 'lock_enabled';
  static const _settingsPasswordHashKey = 'password_hash';
  static const _settingsAutoBackupKey = 'auto_backup_enabled';
  static const _settingsAutoBackupMinutesKey = 'auto_backup_minutes';
  static const _settingsThemeModeKey = 'theme_mode';

  static Future<AppState> create() async {
    final paths = AppPaths();
    final root = await paths.getRootDir();
    final dbPath = AppDatabase.buildDatabasePath(root.path);
    final db = AppDatabase(dbPath);
    await db.open();
    final fileService = FileService(paths);
    final backupService = BackupService(paths, fileService);
    final pdfService = PdfService();
    final securityService = SecurityService();
    final state = AppState(
      db: db,
      paths: paths,
      fileService: fileService,
      backupService: backupService,
      pdfService: pdfService,
      securityService: securityService,
    );
    await state._loadSettings();
    await state.refreshAll();
    return state;
  }

  Future<void> _loadSettings() async {
    final languageCode = await db.getSetting(_settingsLanguageKey);
    if (languageCode != null && languageCode.isNotEmpty) {
      locale = Locale(languageCode);
    }
    final lockValue = await db.getSetting(_settingsLockKey);
    lockEnabled = lockValue == '1';
    passwordHash = await db.getSetting(_settingsPasswordHashKey);
    if (lockEnabled && (passwordHash == null || passwordHash!.isEmpty)) {
      lockEnabled = false;
    }
    final autoValue = await db.getSetting(_settingsAutoBackupKey);
    autoBackupEnabled = autoValue == '1';
    final minutesValue = await db.getSetting(_settingsAutoBackupMinutesKey);
    final parsedMinutes = int.tryParse(minutesValue ?? '');
    if (parsedMinutes != null && parsedMinutes > 0) {
      autoBackupMinutes = parsedMinutes;
    }
    final themeValue = await db.getSetting(_settingsThemeModeKey);
    if (themeValue == 'light') {
      themeMode = ThemeMode.light;
    } else if (themeValue == 'dark') {
      themeMode = ThemeMode.dark;
    } else {
      themeMode = ThemeMode.system;
    }
    _scheduleAutoBackup();
  }

  Future<void> refreshAll() async {
    classes = await db.getClasses();
    tags = await db.getTags();
    favoriteContentIds = (await db.getFavoriteContentIds()).toSet();
    if (selectedClass != null) {
      lessons = await db.getLessons(selectedClass!.id);
    } else {
      lessons = [];
    }
    if (selectedLesson != null) {
      await loadTopics(selectedLesson!.id);
      await loadContentsForSelection();
    } else {
      topics = [];
      contents = [];
    }
    notifyListeners();
  }

  Future<void> selectClass(ClassModel? value) async {
    selectedClass = value;
    selectedLesson = null;
    selectedContent = null;
    selectedTopic = null;
    lessons = value == null ? [] : await db.getLessons(value.id);
    topics = [];
    contents = [];
    notifyListeners();
  }

  Future<void> selectLesson(LessonModel? value) async {
    selectedLesson = value;
    searchQuery = '';
    filterTagIds = {};
    selectedContent = null;
    selectedTopic = null;
    if (value == null) {
      topics = [];
      contents = [];
    } else {
      await loadTopics(value.id);
      await loadContentsForSelection();
    }
    notifyListeners();
  }

  Future<void> loadTopics(int lessonId) async {
    final rows = await db.getTopicsRaw(lessonId);
    topics = rows.map(TopicModel.fromMap).toList();
  }

  Future<void> loadContentsForSelection() async {
    if (selectedLesson == null) {
      contents = [];
      return;
    }
    if (selectedTopic == null) {
      contents = await db.getContentsWithTags(selectedLesson!.id);
    } else {
      contents = await db.getContentsWithTagsByTopic(selectedTopic!.id);
    }
    favoriteContentIds = (await db.getFavoriteContentIds()).toSet();
    notifyListeners();
  }

  Future<void> selectTopic(TopicModel? topic) async {
    selectedTopic = topic;
    await loadContentsForSelection();
  }

  void selectContent(ContentWithTags? content) {
    selectedContent = content;
    notifyListeners();
  }

  List<ContentWithTags> get filteredContents {
    final query = searchQuery.trim().toLowerCase();
    return contents.where((item) {
      final matchesQuery =
          query.isEmpty || item.content.name.toLowerCase().contains(query);
      final matchesTags = filterTagIds.isEmpty ||
          item.tags.any((tag) => filterTagIds.contains(tag.id));
      final matchesArchive = showArchived || !item.content.archived;
      return matchesQuery && matchesTags && matchesArchive;
    }).toList();
  }

  void setSearchQuery(String value) {
    searchQuery = value;
    notifyListeners();
  }

  void toggleFilterTag(int tagId) {
    if (filterTagIds.contains(tagId)) {
      filterTagIds.remove(tagId);
    } else {
      filterTagIds.add(tagId);
    }
    notifyListeners();
  }

  Future<void> addClass(String name) async {
    final trimmed = name.trim();
    if (trimmed.isEmpty) {
      return;
    }
    if (classes.any((item) => item.name.toLowerCase() == trimmed.toLowerCase())) {
      return;
    }
    await db.insertClass(trimmed);
    await paths.getClassDir(trimmed);
    await refreshAll();
  }

  Future<void> updateClass(ClassModel model, String name) async {
    final trimmed = name.trim();
    if (trimmed.isEmpty) {
      return;
    }
    if (trimmed == model.name) {
      return;
    }
    final classesDir = await paths.getClassesDir();
    final oldPath = p.join(classesDir.path, sanitizePathSegment(model.name));
    final newPath = p.join(classesDir.path, sanitizePathSegment(trimmed));
    await fileService.renameDirectory(oldPath, newPath);
    final classLessons = await db.getLessons(model.id);
    for (final lesson in classLessons) {
      final lessonContents = await db.getContents(lesson.id);
      for (final content in lessonContents) {
        final updatedPath = content.path.replaceFirst(oldPath, newPath);
        if (updatedPath != content.path) {
          await db.updateContentPath(content.id, updatedPath);
        }
      }
    }
    await db.updateClass(model.id, trimmed);
    await refreshAll();
  }

  Future<void> deleteClass(ClassModel model) async {
    final classesDir = await paths.getClassesDir();
    final path = p.join(classesDir.path, sanitizePathSegment(model.name));
    await db.deleteClass(model.id);
    await fileService.deleteDirectory(path);
    if (selectedClass?.id == model.id) {
      selectedClass = null;
      selectedLesson = null;
    }
    await refreshAll();
  }

  Future<void> addLesson(String name) async {
    if (selectedClass == null) {
      return;
    }
    final trimmed = name.trim();
    if (trimmed.isEmpty) {
      return;
    }
    if (lessons.any((item) => item.name.toLowerCase() == trimmed.toLowerCase())) {
      return;
    }
    final order = await db.getNextLessonOrder(selectedClass!.id);
    await db.insertLesson(selectedClass!.id, trimmed, order);
    await paths.getLessonDir(selectedClass!.name, trimmed);
    lessons = await db.getLessons(selectedClass!.id);
    notifyListeners();
  }

  Future<void> addTopic(String name) async {
    if (selectedLesson == null || selectedClass == null) {
      return;
    }
    final trimmed = name.trim();
    if (trimmed.isEmpty) {
      return;
    }
    if (topics.any((item) => item.name.toLowerCase() == trimmed.toLowerCase())) {
      return;
    }
    final order = await db.getNextTopicOrder(selectedLesson!.id);
    await db.insertTopic(selectedLesson!.id, trimmed, order);
    await paths.getContentDir(
      selectedClass!.name,
      selectedLesson!.name,
      topicName: trimmed,
    );
    await loadTopics(selectedLesson!.id);
    notifyListeners();
  }

  Future<void> updateTopic(TopicModel topic, String name) async {
    if (selectedLesson == null || selectedClass == null) {
      return;
    }
    final trimmed = name.trim();
    if (trimmed.isEmpty || trimmed == topic.name) {
      return;
    }
    final lessonDir =
        await paths.getLessonDir(selectedClass!.name, selectedLesson!.name);
    final oldPath = p.join(lessonDir.path, sanitizePathSegment(topic.name));
    final newPath = p.join(lessonDir.path, sanitizePathSegment(trimmed));
    await fileService.renameDirectory(oldPath, newPath);
    await db.updateTopic(topic.id, trimmed);
    await loadTopics(selectedLesson!.id);
    notifyListeners();
  }

  Future<void> deleteTopic(TopicModel topic) async {
    if (selectedLesson == null || selectedClass == null) {
      return;
    }
    final lessonDir =
        await paths.getLessonDir(selectedClass!.name, selectedLesson!.name);
    final topicPath = p.join(lessonDir.path, sanitizePathSegment(topic.name));
    final topicContents = await db.getContentsByTopic(topic.id);
    for (final item in topicContents) {
      await db.deleteContent(item.id);
      if (item.type == 'exam') {
        final examId = int.tryParse(item.path);
        if (examId != null) {
          await db.deleteExam(examId);
        }
      }
      if (item.type != 'link' && item.type != 'exam') {
        await fileService.deleteFile(item.path);
      }
    }
    await db.deleteTopic(topic.id);
    await fileService.deleteDirectory(topicPath);
    if (selectedTopic?.id == topic.id) {
      selectedTopic = null;
    }
    await loadTopics(selectedLesson!.id);
    await loadContentsForSelection();
  }

  Future<void> reorderTopics(int oldIndex, int newIndex) async {
    final list = List<TopicModel>.from(topics);
    if (newIndex > oldIndex) {
      newIndex -= 1;
    }
    final item = list.removeAt(oldIndex);
    list.insert(newIndex, item);
    for (var i = 0; i < list.length; i += 1) {
      await db.updateTopicOrder(list[i].id, i + 1);
    }
    if (selectedLesson != null) {
      await loadTopics(selectedLesson!.id);
    }
    notifyListeners();
  }

  Future<void> updateLesson(LessonModel lesson, String name) async {
    if (selectedClass == null) {
      return;
    }
    final trimmed = name.trim();
    if (trimmed.isEmpty || trimmed == lesson.name) {
      return;
    }
    final classDir = await paths.getClassDir(selectedClass!.name);
    final oldPath = p.join(classDir.path, sanitizePathSegment(lesson.name));
    final newPath = p.join(classDir.path, sanitizePathSegment(trimmed));
    await fileService.renameDirectory(oldPath, newPath);
    final lessonContents = await db.getContents(lesson.id);
    for (final content in lessonContents) {
      final updatedPath = content.path.replaceFirst(oldPath, newPath);
      if (updatedPath != content.path) {
        await db.updateContentPath(content.id, updatedPath);
      }
    }
    await db.updateLesson(lesson.id, trimmed);
    lessons = await db.getLessons(selectedClass!.id);
    if (selectedLesson?.id == lesson.id) {
      selectedLesson = LessonModel(
        id: lesson.id,
        classId: lesson.classId,
        name: trimmed,
        order: lesson.order,
        createdAt: lesson.createdAt,
      );
    }
    notifyListeners();
  }

  Future<void> deleteLesson(LessonModel lesson) async {
    if (selectedClass == null) {
      return;
    }
    final classDir = await paths.getClassDir(selectedClass!.name);
    final lessonPath = p.join(classDir.path, sanitizePathSegment(lesson.name));
    await db.deleteLesson(lesson.id);
    await fileService.deleteDirectory(lessonPath);
    lessons = await db.getLessons(selectedClass!.id);
    if (selectedLesson?.id == lesson.id) {
      selectedLesson = null;
      contents = [];
    }
    notifyListeners();
  }

  Future<void> addContentFiles(List<String> filePaths) async {
    if (selectedClass == null || selectedLesson == null) {
      return;
    }
    var order = await db.getNextContentOrder(selectedLesson!.id);
    for (final path in filePaths) {
      final targetPath = await fileService.copyFileToContentDir(
        sourcePath: path,
        className: selectedClass!.name,
        lessonName: selectedLesson!.name,
        topicName: selectedTopic?.name,
      );
      final fileName = p.basename(path);
      await db.insertContent(
        lessonId: selectedLesson!.id,
        topicId: selectedTopic?.id,
        name: fileName,
        type: fileService.typeForFile(path),
        path: targetPath,
        order: order,
      );
      order += 1;
    }
    await loadContentsForSelection();
  }

  Future<void> addWebLink({
    required String title,
    required String url,
  }) async {
    if (selectedClass == null || selectedLesson == null) {
      return;
    }
    final trimmedTitle = title.trim();
    final trimmedUrl = url.trim();
    if (trimmedTitle.isEmpty || trimmedUrl.isEmpty) {
      return;
    }
    final order = await db.getNextContentOrder(selectedLesson!.id);
    await db.insertContent(
      lessonId: selectedLesson!.id,
      topicId: selectedTopic?.id,
      name: trimmedTitle,
      type: 'link',
      path: trimmedUrl,
      order: order,
    );
    await loadContentsForSelection();
  }

  Future<void> addExamWithQuestions({
    required String title,
    required List<ExamQuestion> questions,
  }) async {
    if (selectedLesson == null) {
      return;
    }
    final trimmedTitle = title.trim();
    if (trimmedTitle.isEmpty || questions.isEmpty) {
      return;
    }
    final examId = await db.insertExam(
      lessonId: selectedLesson!.id,
      topicId: selectedTopic?.id,
      name: trimmedTitle,
    );
    final contentOrder = await db.getNextContentOrder(selectedLesson!.id);
    await db.insertContent(
      lessonId: selectedLesson!.id,
      topicId: selectedTopic?.id,
      name: trimmedTitle,
      type: 'exam',
      path: examId.toString(),
      order: contentOrder,
    );
    var order = 1;
    for (final question in questions) {
      final trimmed = question.value.trim();
      if (trimmed.isEmpty) {
        continue;
      }
      await db.insertExamQuestion(
        examId: examId,
        question: trimmed,
        type: question.typeCode,
        optionsJson: question.toOptionsJson(),
        correctOption: question.correctOptionIndex,
        audioPath: question.audioPath,
        order: order,
      );
      order += 1;
    }
  }

  Future<String?> copyExamImage(String sourcePath) async {
    if (selectedClass == null || selectedLesson == null) {
      return null;
    }
    return fileService.copyFileToContentDir(
      sourcePath: sourcePath,
      className: selectedClass!.name,
      lessonName: selectedLesson!.name,
      topicName: selectedTopic?.name,
    );
  }

  Future<String> copyToQuestionBank(String sourcePath) async {
    return fileService.copyToQuestionBank(sourcePath);
  }

  Future<void> addContentFromFolder(String folderPath) async {
    if (selectedClass == null || selectedLesson == null) {
      return;
    }
    final copiedPaths = await fileService.importFolder(
      folderPath: folderPath,
      className: selectedClass!.name,
      lessonName: selectedLesson!.name,
      topicName: selectedTopic?.name,
    );
    var order = await db.getNextContentOrder(selectedLesson!.id);
    for (final path in copiedPaths) {
      await db.insertContent(
        lessonId: selectedLesson!.id,
        topicId: selectedTopic?.id,
        name: p.basename(path),
        type: fileService.typeForFile(path),
        path: path,
        order: order,
      );
      order += 1;
    }
    await loadContentsForSelection();
  }

  Future<void> deleteContent(ContentWithTags item) async {
    await db.deleteContent(item.content.id);
    if (item.content.type == 'exam') {
      final examId = int.tryParse(item.content.path);
      if (examId != null) {
        await db.deleteExam(examId);
      }
    }
    if (item.content.type != 'link' && item.content.type != 'exam') {
      await fileService.deleteFile(item.content.path);
    }
    if (selectedLesson != null) {
      await loadContentsForSelection();
    }
  }

  Future<void> openContent(ContentWithTags item) async {
    await fileService.openPath(item.content.path);
  }

  Future<void> moveContentToTopic(
    ContentWithTags item,
    TopicModel? topic,
  ) async {
    if (selectedClass == null || selectedLesson == null) {
      return;
    }
    String newPath = item.content.path;
    if (item.content.type != 'link' && item.content.type != 'exam') {
      final targetDir = await paths.getContentDir(
        selectedClass!.name,
        selectedLesson!.name,
        topicName: topic?.name,
      );
      final fileName = p.basename(item.content.path);
      newPath = p.join(targetDir.path, fileName);
      await File(item.content.path).copy(newPath);
      await fileService.deleteFile(item.content.path);
    }
    await db.updateContentTopic(item.content.id, topic?.id, newPath);
    await loadContentsForSelection();
  }

  Future<void> moveAllFilteredContentsToTopic(TopicModel? topic) async {
    for (final item in filteredContents) {
      await moveContentToTopic(item, topic);
    }
    await loadContentsForSelection();
  }

  Future<void> deleteFilteredContents() async {
    final items = List<ContentWithTags>.from(filteredContents);
    for (final item in items) {
      await deleteContent(item);
    }
    await loadContentsForSelection();
  }


  Future<void> reorderContents(int oldIndex, int newIndex) async {
    final list = List<ContentWithTags>.from(filteredContents);
    if (newIndex > oldIndex) {
      newIndex -= 1;
    }
    final item = list.removeAt(oldIndex);
    list.insert(newIndex, item);
    for (var i = 0; i < list.length; i += 1) {
      await db.updateContentOrder(list[i].content.id, i + 1);
    }
    if (selectedLesson != null) {
      await loadContentsForSelection();
    }
  }

  Future<void> updateContentTags(int contentId, List<int> tagIds) async {
    await db.setContentTags(contentId, tagIds);
    if (selectedLesson != null) {
      await loadContentsForSelection();
    }
  }

  Future<void> addTag(String name) async {
    final trimmed = name.trim();
    if (trimmed.isEmpty) {
      return;
    }
    try {
      await db.insertTag(trimmed);
    } catch (_) {
      return;
    }
    tags = await db.getTags();
    notifyListeners();
  }

  Future<void> updateTag(TagModel tag, String name) async {
    final trimmed = name.trim();
    if (trimmed.isEmpty || trimmed == tag.name) {
      return;
    }
    await db.updateTag(tag.id, trimmed);
    tags = await db.getTags();
    notifyListeners();
  }

  Future<void> updateTagColor(TagModel tag, int color) async {
    await db.updateTagColor(tag.id, color);
    tags = await db.getTags();
    notifyListeners();
  }

  Future<void> toggleFavorite(ContentWithTags item) async {
    final isFav = favoriteContentIds.contains(item.content.id);
    await db.setFavorite(item.content.id, !isFav);
    favoriteContentIds =
        (await db.getFavoriteContentIds()).toSet();
    notifyListeners();
  }

  Future<void> toggleArchive(ContentWithTags item) async {
    await db.setContentArchived(item.content.id, !item.content.archived);
    await loadContentsForSelection();
  }

  void toggleShowArchived(bool value) {
    showArchived = value;
    notifyListeners();
  }

  Future<void> deleteTag(TagModel tag) async {
    await db.deleteTag(tag.id);
    tags = await db.getTags();
    notifyListeners();
  }

  Future<void> setLocale(Locale value) async {
    locale = value;
    await db.setSetting(_settingsLanguageKey, value.languageCode);
    notifyListeners();
  }

  Future<void> setLockEnabled(bool enabled) async {
    lockEnabled = enabled;
    await db.setSetting(_settingsLockKey, enabled ? '1' : '0');
    notifyListeners();
  }

  Future<void> setAutoBackupEnabled(bool enabled) async {
    autoBackupEnabled = enabled;
    await db.setSetting(_settingsAutoBackupKey, enabled ? '1' : '0');
    _scheduleAutoBackup();
    notifyListeners();
  }

  Future<void> setAutoBackupMinutes(int minutes) async {
    autoBackupMinutes = minutes;
    await db.setSetting(_settingsAutoBackupMinutesKey, minutes.toString());
    _scheduleAutoBackup();
    notifyListeners();
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    themeMode = mode;
    final value = mode == ThemeMode.dark
        ? 'dark'
        : mode == ThemeMode.light
            ? 'light'
            : 'system';
    await db.setSetting(_settingsThemeModeKey, value);
    notifyListeners();
  }

  Future<void> setPassword(String password) async {
    passwordHash = securityService.hashPassword(password);
    await db.setSetting(_settingsPasswordHashKey, passwordHash!);
    notifyListeners();
  }

  bool verifyPassword(String password) {
    if (passwordHash == null) {
      return false;
    }
    return securityService.hashPassword(password) == passwordHash;
  }

  Future<void> backupTo(String targetPath) async {
    await backupService.createBackup(targetPath);
  }

  void _scheduleAutoBackup() {
    _autoBackupTimer?.cancel();
    if (!autoBackupEnabled || autoBackupMinutes <= 0) {
      return;
    }
    _autoBackupTimer = Timer.periodic(
      Duration(minutes: autoBackupMinutes),
      (_) async {
        final root = await paths.getRootDir();
        final backupDir = Directory(
          p.join(root.path, 'AutoBackups'),
        );
        if (!backupDir.existsSync()) {
          backupDir.createSync(recursive: true);
        }
        final timestamp = DateTime.now().toIso8601String().replaceAll(':', '-');
        final targetPath = p.join(
          backupDir.path,
          'auto_backup_$timestamp.zip',
        );
        await backupService.createBackup(targetPath);
      },
    );
  }

  Future<void> restoreFrom(String zipPath) async {
    await db.close();
    await backupService.restoreBackup(zipPath);
    await db.open();
    await _loadSettings();
    await refreshAll();
  }

  Future<void> exportPdf(String targetPath, PdfLabels labels) async {
    if (selectedClass == null || selectedLesson == null) {
      return;
    }
    await pdfService.exportLessonPdf(
      className: selectedClass!.name,
      lessonName: selectedLesson!.name,
      contents: contents,
      targetPath: targetPath,
      labels: labels,
    );
  }

  Future<void> exportLessonZip(String targetPath) async {
    if (selectedClass == null || selectedLesson == null) {
      return;
    }
    final lessonDir =
        await paths.getLessonDir(selectedClass!.name, selectedLesson!.name);
    await backupService.createZipFromDirectory(lessonDir.path, targetPath);
  }

  Future<void> exportTopicZip(String targetPath) async {
    if (selectedClass == null || selectedLesson == null || selectedTopic == null) {
      return;
    }
    final lessonDir =
        await paths.getLessonDir(selectedClass!.name, selectedLesson!.name);
    final topicDir = Directory(
      p.join(lessonDir.path, sanitizePathSegment(selectedTopic!.name)),
    );
    await backupService.createZipFromDirectory(topicDir.path, targetPath);
  }

  Future<String?> loadNoteText() async {
    if (selectedLesson == null) {
      return null;
    }
    final note = await db.getNote(selectedLesson!.id, selectedTopic?.id);
    return note?['metin'] as String?;
  }

  Future<void> saveNoteText(String text) async {
    if (selectedLesson == null) {
      return;
    }
    await db.upsertNote(
      lessonId: selectedLesson!.id,
      topicId: selectedTopic?.id,
      text: text,
    );
  }
}

