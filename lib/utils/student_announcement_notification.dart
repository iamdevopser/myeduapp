import '../models/in_app_notification.dart';
import '../providers/app_state.dart';
import '../services/notification_service.dart';
import 'notification_navigation.dart';

/// P9 — duyuru referansı için mevcut bildirimi bulur ve `markAsRead` çağırır.
Future<bool> markStudentAnnouncementReadFromNotifications({
  required AppState state,
  required int announcementId,
}) async {
  final service = NotificationService(state.db, state: state);
  List<InAppNotification> list;
  try {
    list = await service.listForCurrentUser();
  } on NotificationAccessDeniedException {
    return false;
  }
  for (final n in list) {
    if (n.referenceType == NotificationFanoutRef.announcement &&
        n.referenceId == announcementId &&
        !n.isRead) {
      return service.markAsRead(n.id);
    }
  }
  return false;
}

Future<Set<int>> unreadStudentAnnouncementIds(AppState state) async {
  final service = NotificationService(state.db, state: state);
  try {
    final list = await service.listForCurrentUser();
    return list
        .where(
          (n) =>
              n.referenceType == NotificationFanoutRef.announcement &&
              n.referenceId != null &&
              !n.isRead,
        )
        .map((n) => n.referenceId!)
        .toSet();
  } on NotificationAccessDeniedException {
    return {};
  }
}
