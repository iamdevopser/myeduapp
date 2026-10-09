import '../models/app_role.dart';
import '../providers/app_state.dart';

class NotificationRecipient {
  const NotificationRecipient({required this.role, required this.userId});

  final AppRole role;
  final int userId;

  String get roleDbValue => role.name;

  static NotificationRecipient? fromAppState(AppState state) {
    if (!state.isUnlocked || state.currentRole == null) return null;
    switch (state.currentRole!) {
      case AppRole.student:
        final id = state.sessionStudentId;
        if (id == null) return null;
        return NotificationRecipient(role: AppRole.student, userId: id);
      case AppRole.parent:
        final id = state.sessionParentId;
        if (id == null) return null;
        return NotificationRecipient(role: AppRole.parent, userId: id);
      case AppRole.teacher:
      case AppRole.secretary:
        return NotificationRecipient(role: state.currentRole!, userId: 0);
      case AppRole.admin:
        final id = state.sessionAccountId;
        if (id == null) return null;
        return NotificationRecipient(role: AppRole.admin, userId: id);
    }
  }
}
