import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../l10n/app_localizations.dart';
import '../models/app_role.dart';
import '../models/in_app_notification.dart';
import '../providers/app_state.dart';
import '../screens/secretary_portal/secretary_document_detail_screen.dart';
import 'parent_navigation.dart';
import 'secretary_navigation.dart';
import 'student_navigation.dart';

Future<void> openNotificationReference(
  BuildContext context,
  InAppNotification notification,
) async {
  final refType = notification.referenceType;
  final refId = notification.referenceId;
  if (refType == null || refId == null) return;

  final state = context.read<AppState>();
  final role = state.currentRole;

  switch (refType) {
    case NotificationFanoutRef.announcement:
      switch (role) {
        case AppRole.student:
          state.setPendingStudentAnnouncementOpenId(refId);
          navigateStudentSection(context, StudentNavSection.announcements);
        case AppRole.parent:
          navigateParentSection(context, ParentNavSection.announcements);
        case AppRole.secretary:
          openSecretaryAnnouncementDetail(context, refId);
        case AppRole.teacher:
        case AppRole.admin:
        case null:
          break;
      }
    case NotificationFanoutRef.document:
      switch (role) {
        case AppRole.student:
          navigateStudentSection(context, StudentNavSection.documents);
        case AppRole.parent:
          navigateParentSection(context, ParentNavSection.documents);
        case AppRole.secretary:
        case AppRole.teacher:
        case AppRole.admin:
          state.setSecretaryFocusDocument(refId);
          if (role == AppRole.secretary) {
            openSecretaryDocumentDetail(context, refId);
          } else if (role == AppRole.teacher) {
            await Navigator.of(context).push<void>(
              MaterialPageRoute(
                builder: (_) => const SecretaryDocumentDetailScreen(),
              ),
            );
          } else {
            break;
          }
        case null:
          break;
      }
  }
}

/// Referans tür sabitleri (fanout ile uyumlu).
abstract class NotificationFanoutRef {
  static const String announcement = 'ogrenci_duyuru';
  static const String document = 'icerik';
}

void showNotificationReferenceMissing(BuildContext context) {
  final strings = AppLocalizations.of(context);
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text(strings.t('notificationReferenceMissing'))),
  );
}
