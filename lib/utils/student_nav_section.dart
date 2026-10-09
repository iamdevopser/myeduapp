/// Öğrenci paneli ana bölümleri.
enum StudentNavSection {
  home,
  courses,
  academicPlansWeekly,
  assignments,
  exams,
  performance,
  attendance,
  documents,
  announcements,
  profile,
  /// Eski ders içerik görüntüleyici (materyaller).
  lessonPlatform,
}

const List<StudentNavSection> studentSidebarMenuOrder = [
  StudentNavSection.home,
  StudentNavSection.courses,
  StudentNavSection.academicPlansWeekly,
  StudentNavSection.assignments,
  StudentNavSection.exams,
  StudentNavSection.performance,
  StudentNavSection.attendance,
  StudentNavSection.documents,
  StudentNavSection.announcements,
  StudentNavSection.profile,
];
