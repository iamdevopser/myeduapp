import 'package:flutter_test/flutter_test.dart';
import 'package:my_edu_app/data/models/smtp_settings.dart';
import 'package:my_edu_app/utils/smtp_server_factory.dart';

void main() {
  test('normalizeSmtpPassword strips spaces from app password', () {
    expect(normalizeSmtpPassword('abcd efgh ijkl mnop'), 'abcdefghijklmnop');
  });

  test('normalizeSmtpSettings fixes Gmail username and from', () {
    final raw = SmtpSettings(
      host: 'smtp.gmail.com',
      port: 587,
      username: 'teacher@gmail.com',
      password: 'abcd efgh',
      fromEmail: 'other@gmail.com',
      useSsl: false,
    );
    final n = normalizeSmtpSettings(raw);
    expect(n.fromEmail, 'teacher@gmail.com');
    expect(n.password, 'abcdefgh');
  });

  test('normalizeSmtpSettings appends @gmail.com to bare username', () {
    final raw = SmtpSettings(
      host: 'smtp.gmail.com',
      port: 587,
      username: 'teacher',
      password: 'x',
      fromEmail: '',
      useSsl: false,
    );
    final n = normalizeSmtpSettings(raw);
    expect(n.username, 'teacher@gmail.com');
    expect(n.fromEmail, 'teacher@gmail.com');
  });
}
