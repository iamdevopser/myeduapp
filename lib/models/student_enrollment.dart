/// Öğrencinin bir sınıftaki kaydı (çoklu sınıf desteği).
class StudentEnrollment {
  const StudentEnrollment({
    required this.classId,
    required this.studentId,
    required this.className,
    required this.section,
    required this.studentName,
    required this.number,
    this.email,
  });

  final int classId;
  final int studentId;
  final String className;
  final String? section;
  final String studentName;
  final int number;
  final String? email;

  String get displayClass {
    final base = className.trim();
    final sec = section?.trim();
    if (sec == null || sec.isEmpty) return base;
    return '$base-$sec';
  }

  String get scheduleClassLabel {
    final sec = section?.trim();
    if (sec == null || sec.isEmpty) return className.trim();
    return '${className.trim()}$sec';
  }
}
