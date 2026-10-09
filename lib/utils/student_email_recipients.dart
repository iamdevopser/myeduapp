import 'email_validation.dart';

/// Hangi veli/öğrenci adreslerine rapor gönderileceği.
class ReportEmailRecipientRoles {
  const ReportEmailRecipientRoles({
    required this.toStudent,
    required this.toMother,
    required this.toFather,
  });

  final bool toStudent;
  final bool toMother;
  final bool toFather;

  bool get anySelected => toStudent || toMother || toFather;
}

class StudentReportRecipientPick {
  const StudentReportRecipientPick({
    required this.validEmails,
    required this.invalidEmails,
    required this.hadEmptyFieldsForSelectedRoles,
  });

  final List<String> validEmails;
  final List<String> invalidEmails;

  /// Seçili rol var ama ilgili alan boş (veritabanında kayıt yok).
  final bool hadEmptyFieldsForSelectedRoles;
}

/// Öğrenci satırından (`ogrenciler` tablosu) geçerli alıcı listesi.
List<String> studentReportRecipientEmails(
  Map<String, Object?> student, {
  required bool toStudent,
  required bool toMother,
  required bool toFather,
}) {
  return pickStudentReportRecipientEmails(
    student,
    toStudent: toStudent,
    toMother: toMother,
    toFather: toFather,
  ).validEmails;
}

StudentReportRecipientPick pickStudentReportRecipientEmails(
  Map<String, Object?> student, {
  required bool toStudent,
  required bool toMother,
  required bool toFather,
}) {
  final seen = <String>{};
  final valid = <String>[];
  final invalid = <String>[];
  var hadEmpty = false;

  void consider(String? raw, bool roleOn) {
    if (!roleOn) return;
    final normalized = normalizeEmail(raw);
    if (normalized == null) {
      hadEmpty = true;
      return;
    }
    if (!isValidEmail(normalized)) {
      invalid.add(normalized);
      return;
    }
    final key = normalized.toLowerCase();
    if (seen.add(key)) {
      valid.add(normalized);
    }
  }

  consider(student['email'] as String?, toStudent);
  consider(student['anne_email'] as String?, toMother);
  consider(student['baba_email'] as String?, toFather);

  return StudentReportRecipientPick(
    validEmails: valid,
    invalidEmails: invalid,
    hadEmptyFieldsForSelectedRoles:
        hadEmpty && valid.isEmpty && invalid.isEmpty,
  );
}
