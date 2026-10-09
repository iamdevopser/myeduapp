import 'package:flutter_test/flutter_test.dart';
import 'package:my_edu_app/utils/email_validation.dart';
import 'package:my_edu_app/utils/student_email_recipients.dart';

void main() {
  test('studentReportRecipientEmails dedupes and filters roles', () {
    final student = <String, Object?>{
      'email': 'student@school.edu',
      'anne_email': 'parent@school.edu',
      'baba_email': 'parent@school.edu',
    };
    final emails = studentReportRecipientEmails(
      student,
      toStudent: true,
      toMother: true,
      toFather: true,
    );
    expect(emails, ['student@school.edu', 'parent@school.edu']);
  });

  test('isValidEmail accepts simple addresses', () {
    expect(isValidEmail('a@b.co'), isTrue);
    expect(isValidEmail('not-an-email'), isFalse);
  });

  test('isValidEmail accepts orizont.md style domains', () {
    expect(isValidEmail('student@orizont.md'), isTrue);
    expect(isValidEmail('student@mail.orizont.md'), isTrue);
  });

  test('pickStudentReportRecipientEmails rejects invalid stored address', () {
    final pick = pickStudentReportRecipientEmails(
      <String, Object?>{'email': 'not-an-email'},
      toStudent: true,
      toMother: false,
      toFather: false,
    );
    expect(pick.validEmails, isEmpty);
    expect(pick.invalidEmails, ['not-an-email']);
  });
}
