import '../models/app_role.dart';

import '../providers/app_state.dart';

/// Rol bazlı yetki kontrolleri (kademeli genişletme).

class AuthorizationService {
  const AuthorizationService(this._state);

  final AppState _state;

  bool get isUnlocked => _state.isUnlocked;

  AppRole? get currentRole => _state.currentRole;

  bool hasRole(AppRole role) => _state.currentRole == role;

  bool get isSecretary => _state.isSecretary;

  bool get isTeacher => _state.isTeacher;

  bool get canViewStudents => isTeacher || (isSecretary && isUnlocked);

  bool get canCreateStudent => isTeacher || (isSecretary && isUnlocked);

  bool get canEditStudent => canCreateStudent;

  bool get canDeleteStudent => isTeacher;

  bool get canViewClasses => canViewStudents;

  bool get canAccessTeacherWorkspace => isTeacher;

  bool get canAccessStudentPortal => _state.isStudent;

  bool get canAccessStudentWorkspace =>
      _state.isStudent && _state.isUnlocked && _state.sessionStudentId != null;

  bool get canViewOwnStudentData => canAccessStudentWorkspace;

  bool get canViewParents => isTeacher || (isSecretary && isUnlocked);

  bool get canCreateParent => isSecretary && isUnlocked;

  bool get canEditParent => canCreateParent;

  bool get canDeleteParent => false;

  bool get canManageStudentParentRelation => canCreateParent;

  bool get canViewAttendance => isTeacher || (isSecretary && isUnlocked);

  bool get canCreateAttendance => isSecretary && isUnlocked;

  bool get canEditAttendance => canCreateAttendance;

  bool get canDeleteAttendance => false;

  bool get canViewAnnouncements => isTeacher || (isSecretary && isUnlocked);

  bool get canCreateAnnouncement => isSecretary && isUnlocked;

  bool get canEditAnnouncement => canCreateAnnouncement;

  bool get canPublishAnnouncement => canCreateAnnouncement;

  bool get canUnpublishAnnouncement => canCreateAnnouncement;

  bool get canDeleteAnnouncement => false;

  bool get canViewDocuments => isTeacher || (isSecretary && isUnlocked);

  bool get canCreateDocument => isSecretary && isUnlocked;

  bool get canEditDocument => canCreateDocument;

  bool get canOpenDocument => canViewDocuments;

  bool get canDownloadDocument => canViewDocuments;

  bool get canDeleteCriticalDocument => false;

  bool get canPhysicallyDeleteDocument => isTeacher;

  bool get canArchiveDocument => canCreateDocument;

  bool get isStudent => _state.isStudent;

  bool get isParent => _state.isParent;

  bool get isAdmin => _state.isAdmin;

  bool get canAccessAdminWorkspace =>
      isAdmin && _state.isUnlocked && _state.sessionAccountId != null;

  bool get canManageAccounts => canAccessAdminWorkspace;

  bool get canAccessParentWorkspace =>
      isParent && isUnlocked && _state.sessionParentId != null;

  bool get canViewOwnStudents => canAccessParentWorkspace;

  bool get canViewStudentAnnouncements => canViewOwnStudents;

  bool get canViewStudentDocuments => canViewOwnStudents;

  bool get canViewParentAttendance => canViewOwnStudents;

  bool get canViewAcademicStatus => canViewOwnStudents;

  bool get canManageAnnouncementsAsParent => false;

  bool get canManageDocumentsAsParent => false;

  bool get canViewOwnNotifications =>
      canAccessTeacherWorkspace ||
      canAccessStudentWorkspace ||
      (isSecretary && isUnlocked) ||
      canAccessParentWorkspace ||
      canAccessAdminWorkspace;

  /// Dil / tema — global `ayarlar`; unlocked workspace oturumları.
  bool get canManageLocaleAndTheme =>
      isUnlocked &&
      (canAccessTeacherWorkspace ||
          canAccessStudentWorkspace ||
          (isSecretary && isUnlocked) ||
          canAccessParentWorkspace ||
          canAccessAdminWorkspace);

  /// SMTP, portal şifreleri, etiketler, yedekleme vb.
  bool get canManageTeacherWorkspaceSettings => isTeacher && isUnlocked;

  bool get canManageBackupRestore => canManageTeacherWorkspaceSettings;

  bool get canManageSmtpSettings => canManageTeacherWorkspaceSettings;

  bool get canManagePortalPasswords => canManageTeacherWorkspaceSettings;
}
