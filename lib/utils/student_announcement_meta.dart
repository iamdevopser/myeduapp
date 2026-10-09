/// `ogrenci_duyurular` durum ve hedef türü sabitleri.
enum StudentAnnouncementStatus {
  draft,
  published,
  unpublished,
}

enum StudentAnnouncementTargetType {
  allSchool,
  grade,
  section,
}

extension StudentAnnouncementStatusDb on StudentAnnouncementStatus {
  String get dbValue => switch (this) {
        StudentAnnouncementStatus.draft => 'taslak',
        StudentAnnouncementStatus.published => 'yayinda',
        StudentAnnouncementStatus.unpublished => 'kaldirildi',
      };

  static StudentAnnouncementStatus fromDb(String? value) {
    switch (value) {
      case 'taslak':
        return StudentAnnouncementStatus.draft;
      case 'kaldirildi':
        return StudentAnnouncementStatus.unpublished;
      case 'yayinda':
      default:
        return StudentAnnouncementStatus.published;
    }
  }
}

extension StudentAnnouncementTargetTypeDb on StudentAnnouncementTargetType {
  String get dbValue => switch (this) {
        StudentAnnouncementTargetType.allSchool => 'tum_okul',
        StudentAnnouncementTargetType.grade => 'sinif',
        StudentAnnouncementTargetType.section => 'sube',
      };

  static StudentAnnouncementTargetType fromDb(String? value) {
    switch (value) {
      case 'sinif':
        return StudentAnnouncementTargetType.grade;
      case 'sube':
        return StudentAnnouncementTargetType.section;
      case 'tum_okul':
      default:
        return StudentAnnouncementTargetType.allSchool;
    }
  }
}
