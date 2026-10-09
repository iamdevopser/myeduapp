import '../data/local/app_database.dart';
import '../models/app_role.dart';
import '../utils/course_form_options.dart';
import '../utils/secretary_document_scope.dart';
import 'notification_recipient.dart';
import 'notification_service.dart';

/// Duyuru/belge olaylarından hedef kullanıcı bildirimleri (idempotent).
class NotificationFanoutService {
  NotificationFanoutService(this._db);

  final AppDatabase _db;

  static const String typeAnnouncement = 'duyuru';
  static const String typeDocument = 'belge';
  static const String refAnnouncement = 'ogrenci_duyuru';
  static const String refDocument = 'icerik';

  Future<void> onAnnouncementPublished(int announcementId) async {
    final row = await _db.getStudentAnnouncementById(announcementId);
    if (row == null) return;
    if ((row['durum'] as String?) != 'yayinda') return;

    final title = row['baslik'] as String? ?? '';
    final body = (row['icerik'] as String? ?? '').trim();
    final preview = body.length > 120 ? '${body.substring(0, 120)}…' : body;

    final students = await _db.listStudentsWithClass();
    final notifiedParents = <int>{};

    for (final student in students) {
      final classId = student['sinif_id'] as int;
      final classIds = {classId};
      final gradeLevels = {
        CourseFormOptions.resolveGrade(student['sinif_ad'] as String?),
      };
      if (!_announcementMatches(
        row,
        classIds: classIds,
        gradeLevels: gradeLevels,
      )) {
        continue;
      }
      final studentId = student['id'] as int;
      await _notify(
        recipient: NotificationRecipient(
          role: AppRole.student,
          userId: studentId,
        ),
        title: title,
        body: preview,
        type: typeAnnouncement,
        referenceType: refAnnouncement,
        referenceId: announcementId,
        dedupKey: 'duyuru:$refAnnouncement:$announcementId:student:$studentId',
      );

      final parents = await _db.listParentsForStudent(studentId);
      for (final p in parents) {
        final parentId = p['veli_id'] as int;
        if (notifiedParents.contains(parentId)) continue;
        notifiedParents.add(parentId);
        await _notify(
          recipient: NotificationRecipient(
            role: AppRole.parent,
            userId: parentId,
          ),
          title: title,
          body: preview,
          type: typeAnnouncement,
          referenceType: refAnnouncement,
          referenceId: announcementId,
          dedupKey: 'duyuru:$refAnnouncement:$announcementId:parent:$parentId',
        );
      }
    }
  }

  Future<void> onDocumentCreated(int documentId) async {
    if (!await _db.isSecretaryDocument(documentId)) return;
    final row = await _db.getContentById(documentId);
    if (row == null) return;
    if ((row['arsiv'] as int? ?? 0) == 1) return;

    final title = row['ad'] as String? ?? '';
    final scope = row['belge_kapsam'] as String?;
    final description = (row['aciklama'] as String? ?? '').trim();
    final preview = description.isNotEmpty
        ? (description.length > 120
              ? '${description.substring(0, 120)}…'
              : description)
        : '';

    await _notify(
      recipient: const NotificationRecipient(role: AppRole.teacher, userId: 0),
      title: title,
      body: preview,
      type: typeDocument,
      referenceType: refDocument,
      referenceId: documentId,
      dedupKey: 'belge:$refDocument:$documentId:teacher:0',
    );
    await _notify(
      recipient: const NotificationRecipient(
        role: AppRole.secretary,
        userId: 0,
      ),
      title: title,
      body: preview,
      type: typeDocument,
      referenceType: refDocument,
      referenceId: documentId,
      dedupKey: 'belge:$refDocument:$documentId:secretary:0',
    );

    final students = await _db.listStudentsWithClass();
    final notifiedParents = <int>{};

    for (final student in students) {
      final classId = student['sinif_id'] as int;
      final className = student['sinif_ad'] as String? ?? '';
      final section = student['sinif_sube'] as String?;
      if (!secretaryDocumentVisibleToStudentClass(
        scope: scope,
        classId: classId,
        className: className,
        section: section,
      )) {
        continue;
      }
      final studentId = student['id'] as int;
      await _notify(
        recipient: NotificationRecipient(
          role: AppRole.student,
          userId: studentId,
        ),
        title: title,
        body: preview,
        type: typeDocument,
        referenceType: refDocument,
        referenceId: documentId,
        dedupKey: 'belge:$refDocument:$documentId:student:$studentId',
      );

      final parents = await _db.listParentsForStudent(studentId);
      for (final p in parents) {
        final parentId = p['veli_id'] as int;
        if (notifiedParents.contains(parentId)) continue;
        notifiedParents.add(parentId);
        await _notify(
          recipient: NotificationRecipient(
            role: AppRole.parent,
            userId: parentId,
          ),
          title: title,
          body: preview,
          type: typeDocument,
          referenceType: refDocument,
          referenceId: documentId,
          dedupKey: 'belge:$refDocument:$documentId:parent:$parentId',
        );
      }
    }
  }

  Future<void> _notify({
    required NotificationRecipient recipient,
    required String title,
    required String body,
    required String type,
    required String? referenceType,
    required int? referenceId,
    required String dedupKey,
  }) async {
    final service = NotificationService(_db, fixedRecipient: recipient);
    await service.createIdempotent(
      recipient: recipient,
      title: title,
      body: body,
      type: type,
      referenceType: referenceType,
      referenceId: referenceId,
      dedupKey: dedupKey,
    );
  }

  bool _announcementMatches(
    Map<String, Object?> row, {
    required Set<int> classIds,
    required Set<int> gradeLevels,
  }) {
    final tur =
        row['hedef_tur'] as String? ??
        (row['sinif_id'] == null ? 'tum_okul' : 'sube');
    switch (tur) {
      case 'tum_okul':
        return true;
      case 'sube':
        final sid = row['sinif_id'] as int?;
        return sid != null && classIds.contains(sid);
      case 'sinif':
        final g = row['hedef_sinif_seviye'] as int?;
        return g != null && gradeLevels.contains(g);
      default:
        final sid = row['sinif_id'] as int?;
        if (sid == null) return true;
        return classIds.contains(sid);
    }
  }
}
