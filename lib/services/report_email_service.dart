import 'dart:developer' as developer;
import 'dart:typed_data';

import 'package:mailer/mailer.dart';
import 'package:path/path.dart' as p;

import '../data/models/smtp_settings.dart';
import '../l10n/app_localizations.dart';
import '../utils/email_validation.dart';
import '../utils/smtp_server_factory.dart';

class ReportEmailSendException implements Exception {
  ReportEmailSendException(this.message, {this.cause});

  final String message;
  final Object? cause;

  @override
  String toString() => message;
}

class ReportEmailService {
  SmtpSettings _effectiveSettings(SmtpSettings smtp) =>
      normalizeSmtpSettings(smtp);

  Future<void> verifyConnection(SmtpSettings smtp) async {
    final effective = _effectiveSettings(smtp);
    if (!effective.isConfigured) {
      throw ReportEmailSendException('SMTP is not configured');
    }
    final server = createSmtpServer(effective);
    final message = Message()
      ..from = Address(effective.fromEmail, 'MyEduApp')
      ..recipients.add(effective.fromEmail)
      ..subject = 'MyEduApp SMTP test'
      ..text =
          'Bu mesaj MyEduApp e-posta ayarlarının doğru çalıştığını doğrular.';
    try {
      await send(message, server);
    } catch (e, st) {
      developer.log(
        'SMTP verify failed',
        name: 'ReportEmailService',
        error: e,
        stackTrace: st,
      );
      throw ReportEmailSendException(_friendlySmtpError(e), cause: e);
    }
  }

  Future<void> sendReportPdf({
    required SmtpSettings smtp,
    required List<String> recipients,
    required String subject,
    required String bodyText,
    required Uint8List pdfBytes,
    required String attachmentFileName,
  }) async {
    final effective = _effectiveSettings(smtp);
    if (!effective.isConfigured) {
      throw ReportEmailSendException('SMTP is not configured');
    }
    final validRecipients = recipients
        .map(normalizeEmail)
        .whereType<String>()
        .where(isValidEmail)
        .toList();
    if (validRecipients.isEmpty) {
      throw ArgumentError('No valid recipient emails');
    }

    final server = createSmtpServer(effective);
    final safeName = p.basename(attachmentFileName);

    for (final to in validRecipients) {
      final message = Message()
        ..from = Address(effective.fromEmail, 'MyEduApp')
        ..recipients.add(to)
        ..subject = subject
        ..text = bodyText
        ..attachments = [
          StreamAttachment(
            Stream.value(pdfBytes),
            'application/pdf',
            fileName: safeName,
          ),
        ];
      try {
        await send(message, server);
      } catch (e, st) {
        developer.log(
          'SMTP send failed to=$to',
          name: 'ReportEmailService',
          error: e,
          stackTrace: st,
        );
        throw ReportEmailSendException(_friendlySmtpError(e), cause: e);
      }
    }
  }

  String _friendlySmtpError(Object e) {
    final text = e.toString().toLowerCase();
    if (text.contains('authentication') ||
        text.contains('535') ||
        text.contains('username and password') ||
        text.contains('invalid credentials')) {
      return 'gmailAuthFailed';
    }
    if (text.contains('starttls') || text.contains('certificate')) {
      return 'smtpTlsFailed';
    }
    if (text.contains('connection') || text.contains('socket')) {
      return 'smtpConnectionFailed';
    }
    return 'smtpSendFailed';
  }
}

String resolveSmtpErrorMessage(AppLocalizations strings, Object error) {
  if (error is ReportEmailSendException) {
    switch (error.message) {
      case 'gmailAuthFailed':
        return strings.t('smtpGmailAuthFailed');
      case 'smtpTlsFailed':
        return strings.t('smtpTlsFailed');
      case 'smtpConnectionFailed':
        return strings.t('smtpConnectionFailed');
      case 'smtpSendFailed':
        return strings.t('smtpSendFailed');
      default:
        return error.message;
    }
  }
  return strings.t('smtpSendFailed');
}
