import '../data/local/app_database.dart';
import '../models/in_app_notification.dart';
import '../providers/app_state.dart';
import 'notification_recipient.dart';

class NotificationAccessDeniedException implements Exception {
  const NotificationAccessDeniedException();
}

/// Uygulama içi bildirimler — oturum alıcısı ile sınırlı (IDOR koruması).
class NotificationService {
  NotificationService(
    this._db, {
    AppState? state,
    NotificationRecipient? fixedRecipient,
  }) : _state = state,
       _fixedRecipient = fixedRecipient;

  final AppDatabase _db;
  final AppState? _state;
  final NotificationRecipient? _fixedRecipient;

  NotificationRecipient? _currentRecipient() {
    if (_fixedRecipient != null) return _fixedRecipient;
    if (_state == null) return null;
    return NotificationRecipient.fromAppState(_state!);
  }

  Future<List<InAppNotification>> listForCurrentUser({int limit = 100}) async {
    final recipient = _currentRecipient();
    if (recipient == null) throw const NotificationAccessDeniedException();
    final rows = await _db.listInAppNotificationsForRecipient(
      recipientRole: recipient.roleDbValue,
      recipientId: recipient.userId,
      limit: limit,
    );
    return rows.map(InAppNotification.fromMap).toList();
  }

  Future<int> unreadCount() async {
    final recipient = _currentRecipient();
    if (recipient == null) return 0;
    return _db.countUnreadInAppNotifications(
      recipientRole: recipient.roleDbValue,
      recipientId: recipient.userId,
    );
  }

  Future<bool> markAsRead(int notificationId) async {
    final recipient = _currentRecipient();
    if (recipient == null) throw const NotificationAccessDeniedException();
    final ok = await _db.markInAppNotificationRead(
      notificationId: notificationId,
      recipientRole: recipient.roleDbValue,
      recipientId: recipient.userId,
    );
    if (ok) _state?.bumpNotificationRevision();
    return ok;
  }

  Future<int> markAllAsRead() async {
    final recipient = _currentRecipient();
    if (recipient == null) throw const NotificationAccessDeniedException();
    final count = await _db.markAllInAppNotificationsRead(
      recipientRole: recipient.roleDbValue,
      recipientId: recipient.userId,
    );
    if (count > 0) _state?.bumpNotificationRevision();
    return count;
  }

  Future<bool> createIdempotent({
    required NotificationRecipient recipient,
    required String title,
    required String body,
    required String type,
    String? referenceType,
    int? referenceId,
    required String dedupKey,
  }) async {
    final inserted = await _db.insertInAppNotificationIdempotent(
      recipientRole: recipient.roleDbValue,
      recipientId: recipient.userId,
      title: title,
      body: body,
      type: type,
      referenceType: referenceType,
      referenceId: referenceId,
      dedupKey: dedupKey,
    );
    if (inserted) {
      final current = _currentRecipient();
      if (current != null &&
          current.role == recipient.role &&
          current.userId == recipient.userId) {
        _state?.bumpNotificationRevision();
      }
    }
    return inserted;
  }
}
