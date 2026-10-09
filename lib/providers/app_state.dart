import 'dart:io';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:flutter/material.dart';

import '../data/local/app_database.dart';
import '../data/models/smtp_settings.dart';
import '../l10n/app_localizations.dart';
import '../utils/smtp_server_factory.dart';
import '../data/models/class_model.dart';
import '../data/models/content_item.dart';
import '../data/models/content_with_tags.dart' as cwt;
import '../data/models/lesson_model.dart';
import '../data/models/tag_model.dart' as data;
import '../data/models/exam_question.dart';
import '../data/models/topic_model.dart';
import '../data/models/unit_model.dart';
import '../services/app_paths.dart';
import '../services/backup_service.dart';
import '../services/backup_package_service.dart';
import '../services/database_sync_service.dart';
import '../services/file_service.dart';
import '../services/pdf_service.dart';
import '../utils/academic_plans_navigation.dart';
import '../utils/teacher_activity.dart';
import '../models/app_role.dart';
import '../utils/admin_nav_section.dart';
import '../utils/parent_nav_section.dart';
import '../utils/secretary_nav_section.dart';
import '../utils/student_nav_section.dart';
import '../utils/teacher_nav_section.dart';
import '../services/account_auth_service.dart';
import '../services/account_service.dart';
import '../services/notification_recipient.dart';
import '../utils/teacher_display_name.dart';

/// Yedekleme/geri yükleme yalnızca öğretmen workspace oturumunda.
class TeacherBackupAccessDeniedException implements Exception {
  const TeacherBackupAccessDeniedException();
}

/// Öğretmen workspace ayarları (SMTP, portal şifreleri vb.).
class TeacherSettingsAccessDeniedException implements Exception {
  const TeacherSettingsAccessDeniedException();
}

/// Dil/tema — geçerli workspace oturumu gerekir.
class GeneralSettingsAccessDeniedException implements Exception {
  const GeneralSettingsAccessDeniedException();
}

class TagModel {
  final int id;
  final String name;
  final int? color;
  TagModel({required this.id, required this.name, this.color});
}

class ContentModel {
  final int id;
  final String title;
  bool favorite;
  bool archived;
  final ContentItem? _contentItem;
  final List<data.TagModel> tags;

  ContentModel({
    required this.id,
    required this.title,
    this.favorite = false,
    this.archived = false,
    ContentItem? contentItem,
    this.tags = const [],
  }) : _contentItem = contentItem;

  ContentModel get content => this;

  ContentItem? get contentItem => _contentItem;

  String get name => title;

  String get path => _contentItem?.path ?? '';

  String get type => _contentItem?.type ?? '';
}

class AppState extends ChangeNotifier {
  AppState._({
    required AppDatabase database,
    required AppPaths paths,
    required FileService fileService,
    required BackupService backupService,
    required BackupPackageService backupPackageService,
    required PdfService pdfService,
    Locale locale = const Locale('tr'),
    ThemeMode themeMode = ThemeMode.system,
    bool lockEnabled = false,
    String? teacherPasswordHash,
    String? studentPasswordHash,
    String? secretaryPasswordHash,
    String? parentPasswordHash,
    bool autoBackupEnabled = false,
    int autoBackupMinutes = 30,
  }) : _db = database,
       _paths = paths,
       _fileService = fileService,
       _backupService = backupService,
       _backupPackageService = backupPackageService,
       _pdfService = pdfService,
       _locale = locale,
       _themeMode = themeMode,
       _lockEnabled = lockEnabled,
       _teacherPasswordHash = teacherPasswordHash,
       _studentPasswordHash = studentPasswordHash,
       _secretaryPasswordHash = secretaryPasswordHash,
       _parentPasswordHash = parentPasswordHash,
       _autoBackupEnabled = autoBackupEnabled,
       _autoBackupMinutes = autoBackupMinutes;

  final AppDatabase _db;
  final AppPaths _paths;
  final FileService _fileService;
  final BackupService _backupService;
  final BackupPackageService _backupPackageService;
  final PdfService _pdfService;

  static Future<AppState> create() async {
    final paths = AppPaths();
    final root = await paths.getRootDir();
    final dbPath = AppDatabase.buildDatabasePath(root.path);
    final db = AppDatabase(dbPath);
    await db.open();

    final fileService = FileService(paths);
    final backupService = BackupService(paths, fileService);
    final backupPackageService = BackupPackageService(db, fileService);
    final pdfService = PdfService();

    Locale locale = const Locale('tr');
    ThemeMode themeMode = ThemeMode.system;
    bool lockEnabled = false;

    bool autoBackupEnabled = false;
    int autoBackupMinutes = 30;

    final localeStr = await db.getSetting('locale');
    if (localeStr != null) {
      locale = Locale(localeStr);
    }
    final themeStr = await db.getSetting('theme_mode');
    if (themeStr != null) {
      themeMode = ThemeMode.values.firstWhere(
        (e) => e.name == themeStr,
        orElse: () => ThemeMode.system,
      );
    }
    final lockStr = await db.getSetting('lock_enabled');
    lockEnabled = lockStr == '1';
    var teacherPasswordHash = await db.getSetting('teacher_password_hash');
    // Migration: old single password_hash becomes teacher password
    if (teacherPasswordHash == null || teacherPasswordHash.isEmpty) {
      teacherPasswordHash = await db.getSetting('password_hash');
    }
    final studentPasswordHash = await db.getSetting('student_password_hash');
    final secretaryPasswordHash = await db.getSetting(
      'secretary_password_hash',
    );
    final parentPasswordHash = await db.getSetting('parent_password_hash');
    final autoStr = await db.getSetting('auto_backup_enabled');
    autoBackupEnabled = autoStr == '1';
    final minStr = await db.getSetting('auto_backup_minutes');
    if (minStr != null) {
      autoBackupMinutes = int.tryParse(minStr) ?? 30;
    }

    final state = AppState._(
      database: db,
      paths: paths,
      fileService: fileService,
      backupService: backupService,
      backupPackageService: backupPackageService,
      pdfService: pdfService,
      locale: locale,
      themeMode: themeMode,
      lockEnabled: lockEnabled,
      teacherPasswordHash: teacherPasswordHash,
      studentPasswordHash: studentPasswordHash,
      secretaryPasswordHash: secretaryPasswordHash,
      parentPasswordHash: parentPasswordHash,
      autoBackupEnabled: autoBackupEnabled,
      autoBackupMinutes: autoBackupMinutes,
    );
    await state._loadClasses();
    await state._loadTags();
    return state;
  }

  /// Testler için: veritabanı zaten açılmış olmalı.
  static Future<AppState> createWithDatabase(AppDatabase database) async {
    final paths = AppPaths();
    final fileService = FileService(paths);
    final backupService = BackupService(paths, fileService);
    final backupPackageService = BackupPackageService(database, fileService);
    final pdfService = PdfService();

    final state = AppState._(
      database: database,
      paths: paths,
      fileService: fileService,
      backupService: backupService,
      backupPackageService: backupPackageService,
      pdfService: pdfService,
    );
    await state._loadClasses();
    await state._loadTags();
    return state;
  }

  AppDatabase get db => _db;

  FileService get fileService => _fileService;

  /// ================= TEACHER NAV TABS =================
  List<TeacherNavSection> _openTeacherTabs = [TeacherNavSection.home];
  TeacherNavSection _activeTeacherTab = TeacherNavSection.home;

  List<TeacherNavSection> get openTeacherTabs =>
      List<TeacherNavSection>.unmodifiable(_openTeacherTabs);
  TeacherNavSection get activeTeacherTab => _activeTeacherTab;

  void openTeacherTab(TeacherNavSection section) {
    if (!_openTeacherTabs.contains(section)) {
      final updated = [..._openTeacherTabs, section];
      updated.sort((a, b) => a.index.compareTo(b.index));
      _openTeacherTabs = updated;
    }
    _activeTeacherTab = section;
    notifyListeners();
  }

  void activateTeacherTab(TeacherNavSection section) {
    if (!_openTeacherTabs.contains(section)) {
      return;
    }
    if (_activeTeacherTab == section) {
      return;
    }
    _activeTeacherTab = section;
    notifyListeners();
  }

  void closeTeacherTab(TeacherNavSection section) {
    if (_openTeacherTabs.length <= 1) {
      return;
    }
    final wasActive = _activeTeacherTab == section;
    _openTeacherTabs = _openTeacherTabs
        .where((tab) => tab != section)
        .toList(growable: false);
    if (wasActive) {
      _activeTeacherTab = _openTeacherTabs.last;
    }
    notifyListeners();
  }

  StudentNavSection _activeStudentSection = StudentNavSection.home;
  StudentNavSection get activeStudentSection => _activeStudentSection;

  SecretaryNavSection _activeSecretarySection = SecretaryNavSection.home;
  SecretaryNavSection get activeSecretarySection => _activeSecretarySection;

  int _secretaryStudentsParentsTab = 0;
  int _secretaryAttendanceTab = 0;
  bool _secretaryPendingStudentSheet = false;
  bool _secretaryPendingParentSheet = false;
  bool _secretaryShowParentDetailPanel = false;
  bool _secretaryShowStudentParentsPanel = false;

  int get secretaryStudentsParentsTab => _secretaryStudentsParentsTab;
  int get secretaryAttendanceTab => _secretaryAttendanceTab;

  bool consumeSecretaryPendingStudentSheet() {
    if (!_secretaryPendingStudentSheet) return false;
    _secretaryPendingStudentSheet = false;
    return true;
  }

  bool consumeSecretaryPendingParentSheet() {
    if (!_secretaryPendingParentSheet) return false;
    _secretaryPendingParentSheet = false;
    return true;
  }

  bool get secretaryShowParentDetailPanel => _secretaryShowParentDetailPanel;
  bool get secretaryShowStudentParentsPanel =>
      _secretaryShowStudentParentsPanel;

  void clearSecretaryParentDetailPanelFlag() {
    _secretaryShowParentDetailPanel = false;
  }

  void clearSecretaryStudentParentsPanelFlag() {
    _secretaryShowStudentParentsPanel = false;
  }

  void openSecretarySection(SecretaryNavSection section) {
    switch (section) {
      case SecretaryNavSection.studentList:
        _secretaryStudentsParentsTab = 0;
        _activeSecretarySection = SecretaryNavSection.studentsParents;
      case SecretaryNavSection.studentAdd:
        _secretaryStudentsParentsTab = 0;
        _secretaryPendingStudentSheet = true;
        _activeSecretarySection = SecretaryNavSection.studentsParents;
      case SecretaryNavSection.studentParents:
        _secretaryStudentsParentsTab = 0;
        _secretaryShowStudentParentsPanel = true;
        _activeSecretarySection = SecretaryNavSection.studentsParents;
      case SecretaryNavSection.parentList:
        _secretaryStudentsParentsTab = 1;
        _activeSecretarySection = SecretaryNavSection.studentsParents;
      case SecretaryNavSection.parentAdd:
        _secretaryStudentsParentsTab = 1;
        _secretaryPendingParentSheet = true;
        _activeSecretarySection = SecretaryNavSection.studentsParents;
      case SecretaryNavSection.parentDetail:
        _secretaryStudentsParentsTab = 1;
        _secretaryShowParentDetailPanel = true;
        _activeSecretarySection = SecretaryNavSection.studentsParents;
      case SecretaryNavSection.classes:
      case SecretaryNavSection.sections:
        _activeSecretarySection = SecretaryNavSection.classesSections;
      case SecretaryNavSection.attendanceDaily:
        _secretaryAttendanceTab = 0;
        _activeSecretarySection = SecretaryNavSection.attendanceReports;
      case SecretaryNavSection.attendanceHistory:
        _secretaryAttendanceTab = 1;
        _activeSecretarySection = SecretaryNavSection.attendanceReports;
      default:
        _activeSecretarySection = section;
    }
    notifyListeners();
  }

  int? _secretaryFocusParentId;
  int? _secretaryFocusStudentId;
  int? _secretaryFocusAnnouncementId;
  int? _secretaryFocusDocumentId;
  int? get secretaryFocusParentId => _secretaryFocusParentId;
  int? get secretaryFocusStudentId => _secretaryFocusStudentId;
  int? get secretaryFocusAnnouncementId => _secretaryFocusAnnouncementId;
  int? get secretaryFocusDocumentId => _secretaryFocusDocumentId;

  void setSecretaryFocusParent(int? id) {
    _secretaryFocusParentId = id;
    notifyListeners();
  }

  void setSecretaryFocusStudent(int? id) {
    _secretaryFocusStudentId = id;
    notifyListeners();
  }

  void setSecretaryFocusAnnouncement(int? id) {
    _secretaryFocusAnnouncementId = id;
    notifyListeners();
  }

  void setSecretaryFocusDocument(int? id) {
    _secretaryFocusDocumentId = id;
    notifyListeners();
  }

  void openStudentSection(StudentNavSection section) {
    _activeStudentSection = section;
    notifyListeners();
  }

  ParentNavSection _activeParentSection = ParentNavSection.home;
  ParentNavSection get activeParentSection => _activeParentSection;

  void openParentSection(ParentNavSection section) {
    _activeParentSection = section;
    notifyListeners();
  }

  AdminNavSection _activeAdminSection = AdminNavSection.home;
  AdminNavSection get activeAdminSection => _activeAdminSection;

  void openAdminSection(AdminNavSection section) {
    _activeAdminSection = section;
    notifyListeners();
  }

  int _adminAccountsRevision = 0;
  int get adminAccountsRevision => _adminAccountsRevision;

  void bumpAdminAccountsRevision() {
    _adminAccountsRevision++;
    notifyListeners();
  }

  int _notificationRevision = 0;
  int get notificationRevision => _notificationRevision;
  int? _cachedUnreadNotificationCount;
  int get cachedUnreadNotificationCount => _cachedUnreadNotificationCount ?? 0;

  void bumpNotificationRevision() {
    _notificationRevision++;
    refreshUnreadNotifications();
  }

  Future<void> refreshUnreadNotifications() async {
    final recipient = NotificationRecipient.fromAppState(this);
    if (recipient == null) {
      _cachedUnreadNotificationCount = null;
      notifyListeners();
      return;
    }
    _cachedUnreadNotificationCount = await _db.countUnreadInAppNotifications(
      recipientRole: recipient.roleDbValue,
      recipientId: recipient.userId,
    );
    notifyListeners();
  }

  int? _sessionParentId;
  int? _parentSelectedStudentId;
  int? get sessionParentId => _sessionParentId;
  int? get parentSelectedStudentId => _parentSelectedStudentId;

  void setParentSession({required int parentId, int? selectedStudentId}) {
    _sessionParentId = parentId;
    _parentSelectedStudentId = selectedStudentId;
    notifyListeners();
  }

  Future<bool> selectParentStudent(int? studentId) async {
    if (_sessionParentId == null) return false;
    if (studentId == null) {
      _parentSelectedStudentId = null;
      notifyListeners();
      return true;
    }
    final ok = await _db.isStudentLinkedToParent(
      parentId: _sessionParentId!,
      studentId: studentId,
    );
    if (!ok) return false;
    _parentSelectedStudentId = studentId;
    notifyListeners();
    return true;
  }

  int? _pendingDocumentFolderId;
  bool _pendingOpenLessonPlatformDocuments = false;
  AcademicPlansSidebarSection? _pendingAcademicPlansSection;
  int? _pendingClassNotebookClassId;

  void requestOpenClassNotebook(int classId) {
    _pendingClassNotebookClassId = classId;
    notifyListeners();
  }

  int? takePendingClassNotebookClassId() {
    final id = _pendingClassNotebookClassId;
    _pendingClassNotebookClassId = null;
    return id;
  }

  int? _pendingStudentAnnouncementOpenId;

  void setPendingStudentAnnouncementOpenId(int? id) {
    _pendingStudentAnnouncementOpenId = id;
    notifyListeners();
  }

  int? takePendingStudentAnnouncementOpenId() {
    final id = _pendingStudentAnnouncementOpenId;
    _pendingStudentAnnouncementOpenId = null;
    return id;
  }

  void requestOpenDocumentFolder(int folderId) {
    _pendingDocumentFolderId = folderId;
    _pendingOpenLessonPlatformDocuments = true;
    _pendingAcademicPlansSection = AcademicPlansSidebarSection.documents;
    notifyListeners();
  }

  void requestOpenLessonPlatformDocuments() {
    _pendingOpenLessonPlatformDocuments = true;
    _pendingAcademicPlansSection = AcademicPlansSidebarSection.documents;
    notifyListeners();
  }

  void requestAcademicPlansSection(AcademicPlansSidebarSection section) {
    _pendingAcademicPlansSection = section;
    if (section == AcademicPlansSidebarSection.documents) {
      _pendingOpenLessonPlatformDocuments = true;
    }
    notifyListeners();
  }

  AcademicPlansSidebarSection? takePendingAcademicPlansSection() {
    final section = _pendingAcademicPlansSection;
    _pendingAcademicPlansSection = null;
    return section;
  }

  int? takePendingDocumentFolderId() {
    final id = _pendingDocumentFolderId;
    _pendingDocumentFolderId = null;
    return id;
  }

  bool takePendingOpenLessonPlatformDocuments() {
    final open = _pendingOpenLessonPlatformDocuments;
    _pendingOpenLessonPlatformDocuments = false;
    return open;
  }

  DateTime? _lastPerformanceActivityLoggedAt;
  static const _performanceActivityMinGap = Duration(seconds: 45);

  Future<void> recordTeacherActivity({
    required String type,
    required String title,
    String? targetType,
    int? targetId,
    String? extraData,
  }) async {
    if (type == TeacherActivityTypes.performanceUpdated) {
      final now = DateTime.now();
      if (_lastPerformanceActivityLoggedAt != null &&
          now.difference(_lastPerformanceActivityLoggedAt!) <
              _performanceActivityMinGap) {
        return;
      }
      _lastPerformanceActivityLoggedAt = now;
    }
    await _db.insertTeacherActivity(
      type: type,
      title: title,
      targetType: targetType,
      targetId: targetId,
      extraData: extraData,
    );
  }

  /// ================= LOCALE / THEME / LOCK =================
  Locale _locale;
  Locale get locale => _locale;
  Future<void> setLocale(Locale v) async {
    _requireGeneralSettingsAccess();
    _locale = v;
    await _db.setSetting('locale', v.languageCode);
    notifyListeners();
  }

  /// Display-language preference; unlike [setLocale] it is available to every
  /// role and on the sign-in screen. Only [AppLocalizations.supportedLocales].
  Future<void> setDisplayLocale(Locale v) async {
    final supported = AppLocalizations.supportedLocales.any(
      (l) => l.languageCode == v.languageCode,
    );
    if (!supported || v.languageCode == _locale.languageCode) return;
    _locale = Locale(v.languageCode);
    await _db.setSetting('locale', v.languageCode);
    notifyListeners();
  }

  ThemeMode _themeMode;
  ThemeMode get themeMode => _themeMode;
  Future<void> setThemeMode(ThemeMode v) async {
    _requireGeneralSettingsAccess();
    _themeMode = v;
    await _db.setSetting('theme_mode', v.name);
    notifyListeners();
  }

  /// Default teacher password. Teacher must change on first login.
  static const String defaultTeacherPassword = 'ogretmen';

  /// Shared student portal login password (hashed in settings).
  static const String defaultStudentPassword = 'ogrenci';

  /// Shared secretary login password (hashed in settings).
  static const String defaultSecretaryPassword = 'sekreter';

  /// Shared parent portal login password (hashed in settings).
  static const String defaultParentPassword = 'veli';

  bool _lockEnabled;
  bool get lockEnabled => _lockEnabled;
  bool _isUnlocked = false;
  bool get isUnlocked => _isUnlocked;
  AppRole? _currentRole;

  AppRole? get currentRole => _currentRole;
  bool get isTeacher => _currentRole == AppRole.teacher;
  bool get isStudent => _currentRole == AppRole.student;
  bool get isSecretary => _currentRole == AppRole.secretary;
  bool get isParent => _currentRole == AppRole.parent;
  bool get isAdmin => _currentRole == AppRole.admin;

  int? _sessionAccountId;
  int? get sessionAccountId => _sessionAccountId;

  void setAccountSession(int accountId) {
    _sessionAccountId = accountId;
    notifyListeners();
  }

  int? _sessionClassId;
  int? _sessionStudentId;
  int? get sessionClassId => _sessionClassId;
  int? get sessionStudentId => _sessionStudentId;

  void setStudentSession({required int classId, required int studentId}) {
    _sessionClassId = classId;
    _sessionStudentId = studentId;
    notifyListeners();
  }

  /// [role] verilirse önceliklidir; geriye uyum için [isTeacher] kullanılabilir.
  void setUnlocked(bool v, {AppRole? role, bool isTeacher = false}) {
    if (!v) {
      clearSession();
      return;
    }
    _isUnlocked = true;
    _currentRole = role ?? (isTeacher ? AppRole.teacher : AppRole.student);
    if (_currentRole != AppRole.student) {
      _sessionClassId = null;
      _sessionStudentId = null;
    }
    if (_currentRole != AppRole.parent) {
      _sessionParentId = null;
      _parentSelectedStudentId = null;
    }
    refreshUnreadNotifications();
    notifyListeners();
  }

  void clearSession() {
    _isUnlocked = false;
    _currentRole = null;
    _sessionClassId = null;
    _sessionStudentId = null;
    _sessionParentId = null;
    _parentSelectedStudentId = null;
    _activeStudentSection = StudentNavSection.home;
    _activeSecretarySection = SecretaryNavSection.home;
    _activeParentSection = ParentNavSection.home;
    _activeAdminSection = AdminNavSection.home;
    _secretaryFocusParentId = null;
    _secretaryFocusStudentId = null;
    _secretaryFocusAnnouncementId = null;
    _secretaryFocusDocumentId = null;
    _openTeacherTabs = [TeacherNavSection.home];
    _activeTeacherTab = TeacherNavSection.home;
    _cachedUnreadNotificationCount = null;
    _sessionAccountId = null;
    notifyListeners();
  }

  String? _teacherPasswordHash;
  String? _studentPasswordHash;
  String? _secretaryPasswordHash;
  String? _parentPasswordHash;

  Future<void> setLockEnabled(bool v) async {
    _lockEnabled = v;
    if (!v) _teacherPasswordHash = null;
    await _db.setSetting('lock_enabled', v ? '1' : '0');
    if (!v) await _db.setSetting('teacher_password_hash', '');
    notifyListeners();
  }

  Future<void> setTeacherPassword(String v) async {
    _requireTeacherForWorkspaceSettings();
    _teacherPasswordHash = _hashPassword(v);
    await _db.setSetting('teacher_password_hash', _teacherPasswordHash ?? '');
    notifyListeners();
  }

  Future<void> setStudentPassword(String v) async {
    _requireTeacherForWorkspaceSettings();
    _studentPasswordHash = _hashPassword(v);
    await _db.setSetting('student_password_hash', _studentPasswordHash ?? '');
    notifyListeners();
  }

  Future<void> setSecretaryPassword(String v) async {
    _requireTeacherForWorkspaceSettings();
    _secretaryPasswordHash = _hashPassword(v);
    await _db.setSetting(
      'secretary_password_hash',
      _secretaryPasswordHash ?? '',
    );
    notifyListeners();
  }

  Future<void> setTeacherDisplayName(String displayName) async {
    _requireTeacherForWorkspaceSettings();
    await _db.setSetting(TeacherDisplayName.settingKey, displayName.trim());
    notifyListeners();
  }

  static String? _hashPassword(String s) {
    if (s.isEmpty) return null;
    final bytes = s.runes.map((r) => r & 0xff).toList();
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  /// Returns (success, isTeacher, needsPasswordChange).
  /// needsPasswordChange=true when teacher used default password and must change it.
  Future<({bool success, bool isTeacher, bool needsPasswordChange})>
  verifyTeacherPassword(String v) async {
    final hash = _hashPassword(v);
    if (hash == null)
      return (success: false, isTeacher: false, needsPasswordChange: false);
    if (_teacherPasswordHash != null && hash == _teacherPasswordHash) {
      return (success: true, isTeacher: true, needsPasswordChange: false);
    }
    if (hash == _hashPassword(defaultTeacherPassword)) {
      return (success: true, isTeacher: true, needsPasswordChange: true);
    }
    return (success: false, isTeacher: false, needsPasswordChange: false);
  }

  bool verifyStudentPassword(String v) {
    final hash = _hashPassword(v);
    if (hash == null) return false;
    if (_studentPasswordHash != null &&
        _studentPasswordHash!.isNotEmpty &&
        hash == _studentPasswordHash) {
      return true;
    }
    return hash == _hashPassword(defaultStudentPassword);
  }

  /// Öğrenci numarası + kişisel şifre ile giriş (Faz 2.5).
  Future<({bool success, bool ambiguous, int? studentId, int? classId})>
  loginStudent({required int studentNumber, required String password}) async {
    final auth = await _db.authenticateStudent(
      studentNumber: studentNumber,
      passwordPlain: password,
    );
    if (auth != null) {
      final allowed = await _db.isDomainLoginAllowed(
        domainType: 'ogrenci',
        domainId: auth.studentId,
      );
      if (!allowed) {
        return (
          success: false,
          ambiguous: false,
          studentId: null,
          classId: null,
        );
      }
      return (
        success: true,
        ambiguous: false,
        studentId: auth.studentId,
        classId: auth.classId,
      );
    }
    final rows = await _db.getStudentsByNumber(studentNumber);
    if (rows.isEmpty) {
      return (success: false, ambiguous: false, studentId: null, classId: null);
    }
    var matchCount = 0;
    int? matchedStudentId;
    int? matchedClassId;
    for (final row in rows) {
      if (_studentRowPasswordMatches(row, password)) {
        matchCount++;
        matchedStudentId = row['id'] as int;
        matchedClassId = row['sinif_id'] as int;
      }
    }
    if (matchCount == 1 && matchedStudentId != null) {
      final allowed = await _db.isDomainLoginAllowed(
        domainType: 'ogrenci',
        domainId: matchedStudentId,
      );
      if (!allowed) {
        return (
          success: false,
          ambiguous: false,
          studentId: null,
          classId: null,
        );
      }
      return (
        success: true,
        ambiguous: false,
        studentId: matchedStudentId,
        classId: matchedClassId,
      );
    }
    return (
      success: false,
      ambiguous: matchCount > 1,
      studentId: null,
      classId: null,
    );
  }

  /// Öğrenci portal kullanıcı adı (`hesaplar`, rol=student) + şifre ile giriş.
  Future<
    ({bool success, bool mustChangePassword, int? studentId, int? classId})
  >
  loginStudentAccount({required String login, required String password}) async {
    const failed = (
      success: false,
      mustChangePassword: false,
      studentId: null,
      classId: null,
    );
    final result = await AccountAuthService(_db).authenticate(
      login: login,
      passwordPlain: password,
      role: AppRole.student,
    );
    final studentId = result?.account.domainId;
    if (result == null || studentId == null) return failed;
    final student = await _db.getStudentById(studentId);
    final classId = student?['sinif_id'] as int?;
    if (classId == null) return failed;
    _sessionAccountId = result.account.id;
    return (
      success: true,
      mustChangePassword: result.mustChangePassword,
      studentId: studentId,
      classId: classId,
    );
  }

  bool _studentRowPasswordMatches(Map<String, Object?> row, String password) {
    final stored = row['sifre_hash'] as String?;
    final hash = _hashPassword(password);
    if (hash == null) return false;
    if (stored != null && stored.isNotEmpty) {
      return hash == stored;
    }
    return verifyStudentPassword(password);
  }

  bool verifySecretaryPassword(String v) {
    final hash = _hashPassword(v);
    if (hash == null) return false;
    if (_secretaryPasswordHash != null &&
        _secretaryPasswordHash!.isNotEmpty &&
        hash == _secretaryPasswordHash) {
      return true;
    }
    return hash == _hashPassword(defaultSecretaryPassword);
  }

  bool _parentPasswordMatches(Map<String, Object?> parentRow, String password) {
    final stored = parentRow['sifre_hash'] as String?;
    final hash = _hashPassword(password);
    if (hash == null) return false;
    if (stored != null && stored.isNotEmpty) {
      return hash == stored;
    }
    return verifyParentPortalPassword(password);
  }

  bool verifyParentPortalPassword(String v) {
    final hash = _hashPassword(v);
    if (hash == null) return false;
    if (_parentPasswordHash != null &&
        _parentPasswordHash!.isNotEmpty &&
        hash == _parentPasswordHash) {
      return true;
    }
    return hash == _hashPassword(defaultParentPassword);
  }

  Future<({bool success, int? parentId, bool noLinkedStudents})> loginParent({
    required String email,
    required String password,
  }) async {
    final login = email.trim();
    if (login.isEmpty) {
      return (success: false, parentId: null, noLinkedStudents: false);
    }

    int? parentIdFromLegacy;
    final row = await _db.getParentByEmail(login);
    if (row != null && _parentPasswordMatches(row, password)) {
      parentIdFromLegacy = row['id'] as int;
      final allowed = await _db.isDomainLoginAllowed(
        domainType: AccountService.domainParent,
        domainId: parentIdFromLegacy,
      );
      if (!allowed) {
        return (success: false, parentId: null, noLinkedStudents: false);
      }
      final links = await _db.listStudentsForParent(parentIdFromLegacy);
      if (links.isEmpty) {
        return (success: false, parentId: null, noLinkedStudents: true);
      }
      return (
        success: true,
        parentId: parentIdFromLegacy,
        noLinkedStudents: false,
      );
    }

    final auth = AccountAuthService(_db);
    final accountResult = await auth.authenticate(
      login: login,
      passwordPlain: password,
      role: AppRole.parent,
    );
    if (accountResult == null) {
      return (success: false, parentId: null, noLinkedStudents: false);
    }
    final account = accountResult.account;
    if (account.domainType != AccountService.domainParent ||
        account.domainId == null) {
      return (success: false, parentId: null, noLinkedStudents: false);
    }
    final parentId = account.domainId!;
    final links = await _db.listStudentsForParent(parentId);
    if (links.isEmpty) {
      return (success: false, parentId: null, noLinkedStudents: true);
    }
    return (success: true, parentId: parentId, noLinkedStudents: false);
  }

  Future<({bool success, bool mustChangePassword, int? accountId})>
  loginRoleAccount({
    required AppRole role,
    required String login,
    required String password,
  }) async {
    final auth = AccountAuthService(_db);
    final result = await auth.authenticate(
      login: login,
      passwordPlain: password,
      role: role,
    );
    if (result == null) {
      return (success: false, mustChangePassword: false, accountId: null);
    }
    _sessionAccountId = result.account.id;
    return (
      success: true,
      mustChangePassword: result.mustChangePassword,
      accountId: result.account.id,
    );
  }

  Future<bool> hasActiveAdminAccount() => _db.hasActiveAdminAccount();

  bool _autoBackupEnabled;
  bool get autoBackupEnabled => _autoBackupEnabled;
  Future<void> setAutoBackupEnabled(bool v) async {
    _requireTeacherForBackupOperations();
    _autoBackupEnabled = v;
    await _db.setSetting('auto_backup_enabled', v ? '1' : '0');
    notifyListeners();
  }

  int _autoBackupMinutes;
  int get autoBackupMinutes => _autoBackupMinutes;
  Future<void> setAutoBackupMinutes(int v) async {
    _requireTeacherForBackupOperations();
    _autoBackupMinutes = v;
    await _db.setSetting('auto_backup_minutes', v.toString());
    notifyListeners();
  }

  /// ================= SELECTION =================
  dynamic selectedClass;
  dynamic selectedLesson;
  dynamic selectedUnit;
  dynamic selectedTopic;
  ContentModel? selectedContent;

  void selectClass(value) {
    selectedClass = value;
    selectedLesson = null;
    selectedUnit = null;
    selectedTopic = null;
    _units = [];
    _topics = [];
    _loadLessons().then((_) => notifyListeners());
  }

  void selectLesson(value, {bool autoSelectFirstUnit = false}) {
    selectedLesson = value;
    selectedUnit = null;
    selectedTopic = null;
    _topics = [];
    _loadUnits().then((_) {
      if (autoSelectFirstUnit && _units.isNotEmpty && selectedUnit == null) {
        selectedUnit = _units.first;
      }
      _loadTopics().then((_) {
        _loadContents().then((_) => notifyListeners());
      });
    });
  }

  /// Öğrenci doküman listesinden içerik görüntüleyiciye hazırlar.
  Future<bool> prepareStudentContentViewer(int contentId) async {
    final row = await _db.getContentById(contentId);
    if (row == null) return false;
    final item = ContentItem.fromMap(row);
    final lessonRow = await _db.getLessonRow(item.lessonId);
    if (lessonRow == null) return false;
    await openCourse(LessonModel.fromMap(lessonRow));
    await _loadTopics();
    if (item.topicId != null) {
      final topic = _findById(_topics, item.topicId!, (t) => t.id);
      if (topic != null) {
        selectedTopic = topic;
      } else if (_topics.isNotEmpty) {
        selectedTopic = _topics.first;
      }
    } else if (_topics.isNotEmpty) {
      selectedTopic = _topics.first;
    }
    await _loadContents();
    selectContent(
      ContentModel(id: item.id, title: item.name, contentItem: item),
    );
    return true;
  }

  Future<void> openCourse(LessonModel course) async {
    ClassModel? cls = _findById(_classes, course.classId, (c) => c.id);
    if (cls == null) {
      await _loadClasses();
      cls = _findById(_classes, course.classId, (c) => c.id);
    }
    if (cls == null) {
      final row = await _db.getClassById(course.classId);
      if (row != null) {
        cls = ClassModel.fromMap(row);
      }
    }
    if (cls == null) {
      return;
    }
    selectedClass = cls;
    selectedLesson = null;
    selectedUnit = null;
    selectedTopic = null;
    selectedContent = null;
    await _loadLessons();
    selectedLesson = _findById(_lessons, course.id, (l) => l.id) ?? course;
    selectedUnit = null;
    selectedTopic = null;
    await _loadUnits();
    _topics = [];
    _contents = [];
    _contentsWithTags = [];
    notifyListeners();
  }

  void selectUnit(value, {bool autoSelectFirstTopic = true}) {
    selectedUnit = value;
    selectedTopic = null;
    selectedContent = null;
    _topics = [];
    _contents = [];
    _contentsWithTags = [];
    notifyListeners();
    _loadTopics().then((_) {
      if (autoSelectFirstTopic && _topics.isNotEmpty) {
        selectedTopic = _topics.first;
      }
      _loadContents().then((_) => notifyListeners());
    });
  }

  void selectTopic(value) {
    selectedTopic = value;
    selectedContent = null;
    _loadContents().then((_) => notifyListeners());
  }

  void selectContent(value) {
    selectedContent = value;
    notifyListeners();
  }

  /// ================= COLLECTIONS =================
  List<ClassModel> _classes = [];
  List<ClassModel> get classes => _classes;

  List<LessonModel> _lessons = [];
  List<LessonModel> get lessons => _lessons;

  List<UnitModel> _units = [];
  List<UnitModel> get units => _units;

  List<TopicModel> _topics = [];
  List<TopicModel> get topics => _topics;

  List<data.TagModel> _tags = [];
  List<data.TagModel> get tags => _tags;

  List<cwt.ContentWithTags> _contentsWithTags = [];
  List<ContentModel> _contents = [];
  List<ContentModel> get filteredContents => _contents;

  Set<int> favoriteContentIds = {};
  String searchQuery = '';
  bool showArchived = false;
  final Set<int> filterTagIds = {};

  Future<void> _loadClasses() async {
    _classes = _uniqueById(await _db.getClasses(), (c) => c.id);
  }

  Future<void> refreshAll() async {
    await _loadClasses();
    if (selectedClass != null) await _loadLessons();
    if (selectedLesson != null) await _loadUnits();
    if (selectedLesson != null) await _loadTopics();
    if (selectedLesson != null) await _loadContents();
    _rebindSelection();
    notifyListeners();
  }

  List<T> _uniqueById<T>(List<T> items, int Function(T) idOf) {
    final unique = <int, T>{};
    for (final item in items) {
      unique[idOf(item)] = item;
    }
    return unique.values.toList();
  }

  T? _findById<T>(List<T> items, int? id, int Function(T) idOf) {
    if (id == null) return null;
    for (final item in items) {
      if (idOf(item) == id) return item;
    }
    return null;
  }

  /// After lists are reloaded from the DB, point selection at the new
  /// instances (same ids). DropdownButton requires value to be in items.
  void _rebindSelection() {
    final classId = selectedClass?.id as int?;
    final lessonId = selectedLesson?.id as int?;
    final unitId = selectedUnit?.id as int?;
    final topicId = selectedTopic?.id as int?;

    selectedClass = _findById(_classes, classId, (c) => c.id);
    if (selectedClass == null) {
      selectedLesson = null;
      selectedUnit = null;
      selectedTopic = null;
      if (classId != null) {
        _lessons = [];
        _units = [];
        _topics = [];
        _contents = [];
        _contentsWithTags = [];
      }
      return;
    }

    selectedLesson = _findById(_lessons, lessonId, (l) => l.id);
    if (selectedLesson == null) {
      selectedUnit = null;
      selectedTopic = null;
      if (lessonId != null) {
        _units = [];
        _topics = [];
      }
      return;
    }

    selectedUnit = _findById(_units, unitId, (u) => u.id);
    selectedTopic = _findById(_topics, topicId, (t) => t.id);
  }

  Future<void> _loadLessons() async {
    if (selectedClass == null) {
      _lessons = [];
      return;
    }
    final c = selectedClass as ClassModel;
    _lessons = _uniqueById(await _db.getLessons(c.id), (l) => l.id);
  }

  Future<void> _loadUnits() async {
    if (selectedLesson == null) {
      _units = [];
      return;
    }
    final l = selectedLesson as LessonModel;
    _units = _uniqueById(await _db.getUnits(l.id), (u) => u.id);
  }

  Future<void> _loadTopics() async {
    if (selectedLesson == null) {
      _topics = [];
      return;
    }
    final l = selectedLesson as LessonModel;
    final unitId = selectedUnit is UnitModel
        ? (selectedUnit as UnitModel).id
        : null;
    if (unitId == null) {
      _topics = [];
      return;
    }
    _topics = _uniqueById(
      (await _db.getTopicsRaw(
        l.id,
        unitId: unitId,
      )).map(TopicModel.fromMap).toList(),
      (t) => t.id,
    );
  }

  Future<void> _loadTags() async {
    _tags = await _db.getTags();
  }

  Future<void> _loadContents() async {
    if (selectedLesson == null) {
      _contentsWithTags = [];
      _contents = [];
      favoriteContentIds = (await _db.getFavoriteContentIds()).toSet();
      notifyListeners();
      return;
    }
    final lesson = selectedLesson as LessonModel;
    List<cwt.ContentWithTags> list;
    if (selectedTopic != null) {
      final topic = selectedTopic as TopicModel;
      list = await _db.getContentsWithTagsByTopic(topic.id);
    } else if (selectedUnit != null) {
      list = [];
    } else {
      list = await _db.getContentsWithTags(lesson.id);
    }
    _contentsWithTags = list;
    favoriteContentIds = (await _db.getFavoriteContentIds()).toSet();
    _applyFilters();
  }

  void _applyFilters() {
    List<cwt.ContentWithTags> items = _contentsWithTags;
    if (searchQuery.trim().isNotEmpty) {
      final q = searchQuery.toLowerCase();
      items = items
          .where((c) => c.content.name.toLowerCase().contains(q))
          .toList();
    }
    if (!showArchived) {
      items = items.where((c) => !c.content.archived).toList();
    }
    if (filterTagIds.isNotEmpty) {
      items = items.where((c) {
        return c.tags.any((t) => filterTagIds.contains(t.id));
      }).toList();
    }
    _contents = items
        .map(
          (cwt) => ContentModel(
            id: cwt.content.id,
            title: cwt.content.name,
            favorite: favoriteContentIds.contains(cwt.content.id),
            archived: cwt.content.archived,
            contentItem: cwt.content,
            tags: cwt.tags,
          ),
        )
        .toList();
  }

  void setSearchQuery(String value) {
    searchQuery = value;
    _applyFilters();
    notifyListeners();
  }

  void toggleShowArchived([bool? value]) {
    showArchived = value ?? !showArchived;
    _applyFilters();
    notifyListeners();
  }

  void toggleFilterTag(int id) {
    if (filterTagIds.contains(id)) {
      filterTagIds.remove(id);
    } else {
      filterTagIds.add(id);
    }
    _applyFilters();
    notifyListeners();
  }

  void toggleFavorite(ContentModel c) async {
    final fav = !favoriteContentIds.contains(c.id);
    if (fav) {
      favoriteContentIds.add(c.id);
    } else {
      favoriteContentIds.remove(c.id);
    }
    await _db.setFavorite(c.id, fav);
    _applyFilters();
    notifyListeners();
  }

  void toggleArchive(ContentModel c) async {
    c.archived = !c.archived;
    await _db.setContentArchived(c.id, c.archived);
    _applyFilters();
    notifyListeners();
  }

  Future<void> deleteContent(ContentModel c) async {
    await _db.deleteContent(c.id);
    await _loadContents();
    notifyListeners();
  }

  Future<void> updateContentNameAndPath(
    int contentId,
    String newName,
    String newPath,
  ) async {
    await _db.updateContentName(contentId, newName);
    await _db.updateContentPath(contentId, newPath);
    await _loadContents();
    notifyListeners();
  }

  void openContent(ContentModel c) {
    // handled by viewer
  }

  void reorderContents(int oldIndex, int newIndex) async {
    if (newIndex > oldIndex) newIndex--;
    final items = List<ContentModel>.from(_contents);
    final item = items.removeAt(oldIndex);
    items.insert(newIndex, item);
    for (var i = 0; i < items.length; i++) {
      await _db.updateContentOrder(items[i].id, i);
    }
    await _loadContents();
    notifyListeners();
  }

  Future<void> deleteFilteredContents() async {
    for (final c in _contents) {
      await _db.deleteContent(c.id);
    }
    await _loadContents();
    notifyListeners();
  }

  /// Harici görsel/medya path'ini MyEduAppData altına kopyalar.
  Future<String?> ensureMediaInAppData(
    String? sourcePath,
    String category,
  ) async {
    if (sourcePath == null || sourcePath.trim().isEmpty) {
      return sourcePath;
    }

    final root = await _paths.getRootDir();
    final normalized = sourcePath.trim();

    if (DatabaseSyncService.isUrlPath(normalized)) {
      return normalized;
    }

    if (DatabaseSyncService.isPathWithinRoot(normalized, root.path)) {
      return normalized;
    }

    if (!await File(normalized).exists()) {
      return normalized;
    }

    return _fileService.copyMediaToAppData(
      sourcePath: normalized,
      category: category,
    );
  }

  /// ================= BACKUP =================

  void _requireTeacherForBackupOperations() {
    if (_currentRole != AppRole.teacher || !_isUnlocked) {
      throw const TeacherBackupAccessDeniedException();
    }
  }

  void _requireTeacherForWorkspaceSettings() {
    if (_currentRole != AppRole.teacher || !_isUnlocked) {
      throw const TeacherSettingsAccessDeniedException();
    }
  }

  bool _hasGeneralSettingsAccess() {
    if (!_isUnlocked || _currentRole == null) return false;
    switch (_currentRole!) {
      case AppRole.teacher:
        return true;
      case AppRole.student:
        return _sessionStudentId != null;
      case AppRole.parent:
        return _sessionParentId != null;
      case AppRole.secretary:
        return true;
      case AppRole.admin:
        return _sessionAccountId != null;
    }
  }

  void _requireGeneralSettingsAccess() {
    if (!_hasGeneralSettingsAccess()) {
      throw const GeneralSettingsAccessDeniedException();
    }
  }

  Future<void> backupTo(String path) async {
    _requireTeacherForBackupOperations();
    final root = await _paths.getRootDir();
    await _backupPackageService.createPackage(
      outputPath: path,
      appDataPath: root.path,
    );
  }

  /// Android/iOS SAF save için ZIP bytes üretir (dosyaya yazmaz).
  Future<Uint8List> buildBackupBytes() async {
    _requireTeacherForBackupOperations();
    final root = await _paths.getRootDir();
    final built = await _backupPackageService.buildPackageBytes(
      appDataPath: root.path,
    );
    return Uint8List.fromList(built.encoded);
  }

  Future<void> _reloadSettingsFromDatabase() async {
    final localeStr = await _db.getSetting('locale');
    if (localeStr != null) {
      _locale = Locale(localeStr);
    }
    final themeStr = await _db.getSetting('theme_mode');
    if (themeStr != null) {
      _themeMode = ThemeMode.values.firstWhere(
        (e) => e.name == themeStr,
        orElse: () => ThemeMode.system,
      );
    }
    final lockStr = await _db.getSetting('lock_enabled');
    _lockEnabled = lockStr == '1';
    var teacherPasswordHash = await _db.getSetting('teacher_password_hash');
    if (teacherPasswordHash == null || teacherPasswordHash.isEmpty) {
      teacherPasswordHash = await _db.getSetting('password_hash');
    }
    _teacherPasswordHash = teacherPasswordHash;
    _studentPasswordHash = await _db.getSetting('student_password_hash');
    _secretaryPasswordHash = await _db.getSetting('secretary_password_hash');
    final autoStr = await _db.getSetting('auto_backup_enabled');
    _autoBackupEnabled = autoStr == '1';
    final minStr = await _db.getSetting('auto_backup_minutes');
    if (minStr != null) {
      _autoBackupMinutes = int.tryParse(minStr) ?? 30;
    }
  }

  Future<void> _refreshAfterRestore() async {
    await _reloadSettingsFromDatabase();
    await _loadClasses();
    await _loadTags();
    if (selectedClass != null) {
      await _loadLessons();
    } else {
      _lessons = [];
    }
    if (selectedLesson != null) {
      await _loadUnits();
      await _loadTopics();
      await _loadContents();
    } else {
      _units = [];
      _topics = [];
      _contents = [];
      _contentsWithTags = [];
      favoriteContentIds = (await _db.getFavoriteContentIds()).toSet();
    }
    _rebindSelection();
    notifyListeners();
  }

  Future<BackupPackageRestoreResult> restoreFrom(String path) async {
    _requireTeacherForBackupOperations();
    final root = await _paths.getRootDir();

    await _db.close();

    BackupRestoreSession? session;
    try {
      session = await _backupPackageService.beginSafeRestore(
        packagePath: path,
        appDataPath: root.path,
      );
    } catch (e) {
      await _db.open();
      rethrow;
    }

    try {
      await session.applyStagingToAppData(root.path);

      await _db.open();
      final syncService = DatabaseSyncService(_db);
      await syncService.importFromJsonString(
        session.databaseJson,
        rootPath: root.path,
      );

      final missingPhysical = await _backupPackageService
          .countMissingPhysicalFiles();

      final result = session.buildResult(
        missingPhysicalFileCount: missingPhysical,
      );

      await session.commit();
      await _refreshAfterRestore();
      return result;
    } catch (e, stackTrace) {
      debugPrint('===== RESTORE HATASI (rollback deneniyor) =====');
      debugPrint('Hata: $e');
      debugPrint('$stackTrace');

      try {
        await _db.close();
        await session.rollback(root.path);
      } catch (rollbackError, rollbackStack) {
        debugPrint('===== ROLLBACK HATASI =====');
        debugPrint('Hata: $rollbackError');
        debugPrint('$rollbackStack');
      } finally {
        await _db.open();
        await _refreshAfterRestore();
      }

      rethrow;
    }
  }

  /// ================= CRUD =================
  Future<void> updateClass(dynamic a, [dynamic b]) async {
    if (a is ClassModel && b is String) {
      await _db.updateClass(a.id, b);
      await _loadClasses();
      _rebindSelection();
      notifyListeners();
    }
  }

  Future<void> updateLesson(dynamic a, [dynamic b]) async {
    if (a is LessonModel && b is String) {
      await _db.updateLesson(a.id, b);
      await _loadLessons();
      _rebindSelection();
      notifyListeners();
    }
  }

  Future<void> updateUnit(
    UnitModel unit,
    String name, {
    int? number,
    String? imagePath,
    bool clearImage = false,
  }) async {
    final resolvedImage = clearImage
        ? null
        : await ensureMediaInAppData(imagePath, 'Uniteler');
    await _db.updateUnit(
      id: unit.id,
      name: name,
      number: number ?? unit.number,
      imagePath: resolvedImage,
      clearImage: clearImage,
    );
    await _loadUnits();
    _rebindSelection();
    notifyListeners();
  }

  Future<void> updateTopic(
    dynamic a, [
    dynamic b,
    String? imagePath,
    bool clearImage = false,
  ]) async {
    if (a is TopicModel && b is String) {
      final resolvedImage = clearImage
          ? null
          : await ensureMediaInAppData(imagePath, 'Konular');
      await _db.updateTopic(
        a.id,
        b,
        imagePath: resolvedImage,
        clearImage: clearImage,
      );
      await _loadTopics();
      _rebindSelection();
      notifyListeners();
    }
  }

  Future<void> deleteClass(dynamic a) async {
    if (a is ClassModel) {
      await _db.deleteClass(a.id);
      await _loadClasses();
      if (selectedClass?.id == a.id) {
        selectedClass = null;
        selectedLesson = null;
        selectedUnit = null;
        selectedTopic = null;
        _lessons = [];
        _units = [];
        _topics = [];
        _contents = [];
      }
      notifyListeners();
    }
  }

  Future<void> deleteLesson(dynamic l) async {
    if (l is LessonModel) {
      await _db.deleteLesson(l.id);
      if (selectedLesson?.id == l.id) {
        selectedLesson = null;
        selectedUnit = null;
        selectedTopic = null;
      }
      await _loadLessons();
      await _loadUnits();
      await _loadTopics();
      await _loadContents();
      notifyListeners();
    }
  }

  Future<void> deleteTopic(dynamic t) async {
    if (t is TopicModel) {
      await _db.deleteTopic(t.id);
      if (selectedTopic?.id == t.id) {
        selectedTopic = null;
      }
      await _loadTopics();
      if (selectedLesson != null) await _loadContents();
      notifyListeners();
    }
  }

  Future<void> deleteUnit(UnitModel unit) async {
    await _db.deleteUnit(unit.id);
    if (selectedUnit?.id == unit.id) {
      selectedUnit = null;
      selectedTopic = null;
    }
    await _loadUnits();
    if (_units.isNotEmpty && selectedUnit == null) {
      selectedUnit = _units.first;
    }
    await _loadTopics();
    if (selectedLesson != null) await _loadContents();
    notifyListeners();
  }

  Future<void> addTag(String name) async {
    await _db.insertTag(name);
    await _loadTags();
    notifyListeners();
  }

  void deleteTag(dynamic tag) async {
    if (tag is data.TagModel) {
      await _db.deleteTag(tag.id);
      await _loadTags();
      notifyListeners();
    }
  }

  Future<void> updateContentTags(dynamic contentOrId, List<int> tagIds) async {
    final contentId = contentOrId is int
        ? contentOrId
        : (contentOrId is ContentModel ? contentOrId.id : null);
    if (contentId != null) {
      await _db.setContentTags(contentId, tagIds);
      await _loadContents();
      notifyListeners();
    }
  }

  Future<void> moveContentToTopic(dynamic content, dynamic topic) async {
    if (content is! ContentModel) return;
    final topicId = topic is TopicModel ? topic.id : null;
    final path = content.contentItem?.path ?? '';
    await _db.updateContentTopic(content.id, topicId, path);
    await _loadContents();
    notifyListeners();
  }

  Future<void> moveAllFilteredContentsToTopic(dynamic topic) async {
    if (topic is TopicModel) {
      for (final c in _contents) {
        await _db.updateContentTopic(c.id, topic.id, '');
      }
      await _loadContents();
      notifyListeners();
    }
  }

  Future<void> addContentFromFolder(String path) async {
    if (selectedLesson == null || selectedClass == null) return;
    final l = selectedLesson as LessonModel;
    final c = selectedClass as ClassModel;
    final topic = selectedTopic as TopicModel?;
    final order = await _db.getNextContentOrder(l.id);
    final copied = await _fileService.importFolder(
      folderPath: path,
      className: c.name,
      lessonName: l.name,
      topicName: topic?.name,
    );
    for (var i = 0; i < copied.length; i++) {
      await _db.insertContent(
        lessonId: l.id,
        topicId: topic?.id,
        name: path.split(RegExp(r'[/\\]')).last,
        type: _fileService.typeForFile(copied[i]),
        path: copied[i],
        order: order + i,
      );
    }
    await _loadContents();
    notifyListeners();
  }

  Future<void> addContentFiles(List<String> paths) async {
    if (selectedLesson == null || selectedClass == null) return;
    final l = selectedLesson as LessonModel;
    final c = selectedClass as ClassModel;
    final topic = selectedTopic as TopicModel?;
    var order = await _db.getNextContentOrder(l.id);
    for (final p in paths) {
      final target = await _fileService.copyFileToContentDir(
        sourcePath: p,
        className: c.name,
        lessonName: l.name,
        topicName: topic?.name,
      );
      await _db.insertContent(
        lessonId: l.id,
        topicId: topic?.id,
        name: p.split(RegExp(r'[/\\]')).last,
        type: _fileService.typeForFile(target),
        path: target,
        order: order++,
      );
    }
    await _loadContents();
    notifyListeners();
  }

  /// Add a block to a specific step (for lesson builder drag & drop)
  Future<int> addBlockToStep({
    required int lessonId,
    required int? topicId,
    required String type,
    required String name,
    required String path,
    required String className,
    required String lessonName,
    String? topicName,
  }) async {
    final order = await _db.getNextContentOrder(lessonId);
    String contentPath = path;
    final skipCopy = ['text', 'link', 'question'].contains(type);
    if (path.isNotEmpty && !skipCopy) {
      contentPath = await _fileService.copyFileToContentDir(
        sourcePath: path,
        className: className,
        lessonName: lessonName,
        topicName: topicName,
      );
    }
    final contentId = await _db.insertContent(
      lessonId: lessonId,
      topicId: topicId,
      name: name,
      type: type,
      path: contentPath,
      order: order,
    );
    notifyListeners();
    return contentId;
  }

  Future<void> addWebLink({required String title, required String url}) async {
    if (selectedLesson == null || selectedClass == null) return;
    final l = selectedLesson as LessonModel;
    final topic = selectedTopic as TopicModel?;
    final order = await _db.getNextContentOrder(l.id);
    await _db.insertContent(
      lessonId: l.id,
      topicId: topic?.id,
      name: title,
      type: 'link',
      path: url,
      order: order,
    );
    await _loadContents();
    notifyListeners();
  }

  Future<void> addExamWithQuestions({
    String? title,
    List<dynamic>? questions,
  }) async {
    if (selectedLesson == null || title == null || questions == null) return;
    final l = selectedLesson as LessonModel;
    final topic = selectedTopic as TopicModel?;
    final examId = await _db.insertExam(
      lessonId: l.id,
      topicId: topic?.id,
      name: title,
    );
    for (var i = 0; i < questions.length; i++) {
      final q = questions[i];
      if (q == null) continue;
      String question = '';
      String type = 'text';
      String? optionsJson;
      int? correctOption;
      String? audioPath;
      if (q is ExamQuestion) {
        question = q.value;
        type = q.typeCode;
        optionsJson = q.toOptionsJson();
        correctOption = q.correctOptionIndex;
        audioPath = q.audioPath;
      } else if (q is Map) {
        question = q['soru'] ?? q['question'] ?? '';
        type = q['tur'] ?? q['type'] ?? 'text';
        optionsJson = q['secenekler'] ?? q['optionsJson'];
        correctOption = q['dogru_secenek'] ?? q['correctOption'];
        audioPath = q['ses_yolu'] ?? q['audioPath'];
      }
      await _db.insertExamQuestion(
        examId: examId,
        question: question,
        type: type,
        optionsJson: optionsJson,
        correctOption: correctOption,
        audioPath: audioPath,
        order: i,
      );
    }
    notifyListeners();
  }

  Future<String?> copyExamImage(String path) async {
    return _fileService.copyToQuestionBank(path);
  }

  Future<String> copyToQuestionBank(String path) async {
    return _fileService.copyToQuestionBank(path);
  }

  Future<void> exportLessonZip(String path) async {
    if (selectedClass == null || selectedLesson == null) return;
    final c = selectedClass as ClassModel;
    final l = selectedLesson as LessonModel;

    final lessonDir = await _paths.getLessonDir(c.name, l.name);
    await _backupService.createZipFromDirectory(lessonDir.path, path);
  }

  Future<void> exportTopicZip(String path) async {
    if (selectedClass == null ||
        selectedLesson == null ||
        selectedTopic == null)
      return;
    final c = selectedClass as ClassModel;
    final l = selectedLesson as LessonModel;
    final t = selectedTopic as TopicModel;
    final contentDir = await _paths.getContentDir(
      c.name,
      l.name,
      topicName: t.name,
    );
    await _backupService.createZipFromDirectory(contentDir.path, path);
  }

  Future<void> exportPdf(String path, dynamic labels) async {
    if (selectedClass == null || selectedLesson == null) return;
    final c = selectedClass as ClassModel;
    final l = selectedLesson as LessonModel;
    await _pdfService.exportLessonPdf(
      className: c.name,
      lessonName: l.name,
      contents: _contentsWithTags,
      targetPath: path,
      labels: labels is PdfLabels
          ? labels
          : PdfLabels(
              classLabel: labels?.classLabel ?? '',
              lessonLabel: labels?.lessonLabel ?? '',
              contentsTitle: labels?.contentsTitle ?? '',
              emptyMessage: labels?.emptyMessage ?? '',
            ),
    );
  }

  Future<SmtpSettings> loadSmtpSettings() async {
    final host = await _db.getSetting('smtp_host') ?? '';
    final portRaw = await _db.getSetting('smtp_port');
    final port = int.tryParse(portRaw ?? '') ?? 587;
    final username = await _db.getSetting('smtp_username') ?? '';
    final password = await _db.getSetting('smtp_password') ?? '';
    final fromEmail = await _db.getSetting('smtp_from_email') ?? '';
    final useSsl = (await _db.getSetting('smtp_use_ssl') ?? '0') == '1';
    return SmtpSettings(
      host: host,
      port: port,
      username: username,
      password: password,
      fromEmail: fromEmail,
      useSsl: useSsl,
    );
  }

  Future<void> saveSmtpSettings(SmtpSettings settings) async {
    _requireTeacherForWorkspaceSettings();
    final normalized = normalizeSmtpSettings(settings);
    await _db.setSetting('smtp_host', normalized.host.trim());
    await _db.setSetting('smtp_port', '${normalized.port}');
    await _db.setSetting('smtp_username', normalized.username.trim());
    await _db.setSetting('smtp_password', normalized.password);
    await _db.setSetting('smtp_from_email', normalized.fromEmail.trim());
    await _db.setSetting('smtp_use_ssl', normalized.useSsl ? '1' : '0');
  }
}
