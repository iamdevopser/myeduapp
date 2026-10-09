import '../data/local/app_database.dart';
import '../utils/course_form_options.dart';
import '../utils/student_announcement_meta.dart';
import 'notification_fanout_service.dart';

class SecretaryAnnouncement {
  const SecretaryAnnouncement({
    required this.id,
    required this.title,
    required this.body,
    required this.status,
    required this.targetType,
    this.classId,
    this.targetGradeLevel,
    required this.createdAt,
    this.publishedAt,
    this.updatedAt,
    this.teacherName,
    this.courseLabel,
    this.coverImagePath,
  });

  final int id;
  final String title;
  final String body;
  final StudentAnnouncementStatus status;
  final StudentAnnouncementTargetType targetType;
  final int? classId;
  final int? targetGradeLevel;
  final String createdAt;
  final String? publishedAt;
  final String? updatedAt;
  final String? teacherName;
  final String? courseLabel;
  final String? coverImagePath;

  static SecretaryAnnouncement fromMap(Map<String, Object?> row) {
    return SecretaryAnnouncement(
      id: row['id'] as int,
      title: row['baslik'] as String,
      body: row['icerik'] as String,
      status: StudentAnnouncementStatusDb.fromDb(row['durum'] as String?),
      targetType: StudentAnnouncementTargetTypeDb.fromDb(
        row['hedef_tur'] as String?,
      ),
      classId: row['sinif_id'] as int?,
      targetGradeLevel: row['hedef_sinif_seviye'] as int?,
      createdAt: row['olusturma_tarihi'] as String,
      publishedAt: row['yayin_tarihi'] as String?,
      updatedAt: row['guncelleme_tarihi'] as String?,
      teacherName: row['ogretmen_adi'] as String?,
      courseLabel: row['ders_adi'] as String?,
      coverImagePath: row['kapak_gorsel_yolu'] as String?,
    );
  }
}

class SecretaryAnnouncementService {
  SecretaryAnnouncementService(this._db);

  final AppDatabase _db;

  Future<List<SecretaryAnnouncement>> list({
    String? search,
    StudentAnnouncementStatus? statusFilter,
    StudentAnnouncementTargetType? targetFilter,
    String? fromDate,
    String? toDate,
  }) async {
    final rows = await _db.listAnnouncementsForSecretary(
      search: search,
      status: statusFilter?.dbValue,
      targetType: targetFilter?.dbValue,
      fromDate: fromDate,
      toDate: toDate,
    );
    return rows.map(SecretaryAnnouncement.fromMap).toList();
  }

  Future<SecretaryAnnouncement?> getById(int id) async {
    final row = await _db.getStudentAnnouncementById(id);
    if (row == null) return null;
    return SecretaryAnnouncement.fromMap(row);
  }

  Future<int> create({
    required String title,
    required String body,
    required StudentAnnouncementTargetType targetType,
    int? classId,
    int? targetGradeLevel,
    StudentAnnouncementStatus status = StudentAnnouncementStatus.draft,
    String? coverImagePath,
  }) {
    return _db.insertSecretaryAnnouncement(
      title: title,
      body: body,
      status: status.dbValue,
      targetType: targetType.dbValue,
      classId: classId,
      targetGradeLevel: targetGradeLevel,
      coverImagePath: coverImagePath,
    );
  }

  Future<void> update({
    required int id,
    required String title,
    required String body,
    required StudentAnnouncementTargetType targetType,
    int? classId,
    int? targetGradeLevel,
    String? coverImagePath,
    bool clearCoverImage = false,
  }) {
    return _db.updateSecretaryAnnouncement(
      id: id,
      title: title,
      body: body,
      targetType: targetType.dbValue,
      classId: classId,
      targetGradeLevel: targetGradeLevel,
      coverImagePath: coverImagePath,
      clearCoverImage: clearCoverImage,
    );
  }

  Future<void> publish(int id) async {
    await _db.publishStudentAnnouncement(id);
    await NotificationFanoutService(_db).onAnnouncementPublished(id);
  }

  Future<void> unpublish(int id) => _db.unpublishStudentAnnouncement(id);

  String targetGradeSectionLabel(
    SecretaryAnnouncement item,
    List<Map<String, Object?>> classes,
  ) {
    switch (item.targetType) {
      case StudentAnnouncementTargetType.allSchool:
        return '';
      case StudentAnnouncementTargetType.grade:
        final g = item.targetGradeLevel ?? 0;
        return CourseFormOptions.gradeLabel(g);
      case StudentAnnouncementTargetType.section:
        if (item.classId == null) return '—';
        Map<String, Object?>? row;
        for (final c in classes) {
          if (c['id'] == item.classId) {
            row = c;
            break;
          }
        }
        if (row == null) return '—';
        final grade = CourseFormOptions.resolveGrade(row['ad'] as String?);
        final section = CourseFormOptions.resolveSection(
          row['sube'] as String?,
        );
        return '${CourseFormOptions.gradeLabel(grade)} $section';
    }
  }
}
