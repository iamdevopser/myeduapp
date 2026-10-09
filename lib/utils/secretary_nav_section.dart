/// Sekreter paneli ana bölümleri.

enum SecretaryNavSection {

  home,

  /// Hub: öğrenci listesi + veli dizini (sekme).
  studentsParents,

  /// Hub: sınıf seviyeleri + şubeler.
  classesSections,

  /// Hub: günlük yoklama + geçmiş.
  attendanceReports,

  studentList,

  studentAdd,

  studentParents,

  classes,

  sections,

  parentList,

  parentAdd,

  parentDetail,

  attendanceDaily,

  attendanceHistory,

  announcementList,

  announcementAdd,

  announcementDetail,

  documentList,

  documentAdd,

  documentDetail,

  profile,

}



/// Ana sekreter sidebar modülleri (4 + profil ayrı).
const List<SecretaryNavSection> secretaryMainMenuOrder = [
  SecretaryNavSection.home,
  SecretaryNavSection.studentsParents,
  SecretaryNavSection.classesSections,
  SecretaryNavSection.attendanceReports,
  SecretaryNavSection.announcementList,
  SecretaryNavSection.documentList,
];

const List<SecretaryNavSection> secretaryStudentsMenuOrder = [
  SecretaryNavSection.studentList,
  SecretaryNavSection.studentAdd,
];

const List<SecretaryNavSection> secretaryClassesMenuOrder = [
  SecretaryNavSection.classes,
  SecretaryNavSection.sections,
];

const List<SecretaryNavSection> secretaryParentsMenuOrder = [
  SecretaryNavSection.parentList,
  SecretaryNavSection.parentAdd,
];

const List<SecretaryNavSection> secretaryAttendanceMenuOrder = [
  SecretaryNavSection.attendanceDaily,
  SecretaryNavSection.attendanceHistory,
];



const List<SecretaryNavSection> secretaryAnnouncementsMenuOrder = [

  SecretaryNavSection.announcementList,

  SecretaryNavSection.announcementAdd,

];



const List<SecretaryNavSection> secretaryDocumentsMenuOrder = [

  SecretaryNavSection.documentList,

  SecretaryNavSection.documentAdd,

];



extension SecretaryNavSectionGroups on SecretaryNavSection {
  SecretaryNavSection get sidebarModule {
    return switch (this) {
      SecretaryNavSection.home => SecretaryNavSection.home,
      SecretaryNavSection.studentsParents ||
      SecretaryNavSection.studentList ||
      SecretaryNavSection.studentAdd ||
      SecretaryNavSection.studentParents ||
      SecretaryNavSection.parentList ||
      SecretaryNavSection.parentAdd ||
      SecretaryNavSection.parentDetail =>
        SecretaryNavSection.studentsParents,
      SecretaryNavSection.classesSections ||
      SecretaryNavSection.classes ||
      SecretaryNavSection.sections =>
        SecretaryNavSection.classesSections,
      SecretaryNavSection.attendanceReports ||
      SecretaryNavSection.attendanceDaily ||
      SecretaryNavSection.attendanceHistory =>
        SecretaryNavSection.attendanceReports,
      SecretaryNavSection.announcementList ||
      SecretaryNavSection.announcementAdd ||
      SecretaryNavSection.announcementDetail =>
        SecretaryNavSection.announcementList,
      SecretaryNavSection.documentList ||
      SecretaryNavSection.documentAdd ||
      SecretaryNavSection.documentDetail =>
        SecretaryNavSection.documentList,
      _ => this,
    };
  }

  static const studentsGroup = secretaryStudentsMenuOrder;

  static const classesGroup = secretaryClassesMenuOrder;

  static const parentsGroup = secretaryParentsMenuOrder;

  static const attendanceGroup = secretaryAttendanceMenuOrder;

  static const announcementsGroup = secretaryAnnouncementsMenuOrder;

  static const documentsGroup = secretaryDocumentsMenuOrder;



  bool get isInStudentsGroup => studentsGroup.contains(this);

  bool get isInClassesGroup => classesGroup.contains(this);

  bool get isInParentsGroup => parentsGroup.contains(this);

  bool get isInAttendanceGroup => attendanceGroup.contains(this);

  bool get isInAnnouncementsGroup => announcementsGroup.contains(this);

  bool get isInDocumentsGroup => documentsGroup.contains(this);

}


