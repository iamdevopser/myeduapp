import 'package:mailer/smtp_server.dart';

import '../data/models/smtp_settings.dart';

/// Google uygulama şifreleri bazen "abcd efgh ijkl mnop" olarak kopyalanır.
String normalizeSmtpPassword(String password) => password.replaceAll(' ', '').trim();

bool isGmailSmtpHost(String host) {
  final h = host.trim().toLowerCase();
  return h == 'smtp.gmail.com' || h.endsWith('.gmail.com');
}

/// Gmail ve yaygın kullanıcı hataları için ayarları düzeltir.
SmtpSettings normalizeSmtpSettings(SmtpSettings raw) {
  var host = raw.host.trim().toLowerCase();
  if (host.isEmpty && raw.username.contains('@gmail.')) {
    host = 'smtp.gmail.com';
  }
  var username = raw.username.trim();
  if (username.isNotEmpty &&
      !username.contains('@') &&
      (host.isEmpty || isGmailSmtpHost(host))) {
    username = '$username@gmail.com';
    host = 'smtp.gmail.com';
  }
  var from = raw.fromEmail.trim();
  final password = normalizeSmtpPassword(raw.password);
  final gmail = isGmailSmtpHost(host);

  if (gmail) {
    host = 'smtp.gmail.com';
    if (from.isEmpty) {
      from = username;
    }
    // Gmail uygulama şifresi: gönderen adresi oturum açan hesapla aynı olmalı.
    if (username.isNotEmpty &&
        from.toLowerCase() != username.toLowerCase()) {
      from = username;
    }
    final port = raw.useSsl ? 465 : 587;
    return raw.copyWith(
      host: host,
      port: port,
      username: username,
      password: password,
      fromEmail: from,
      useSsl: raw.useSsl,
    );
  }

  if (from.isEmpty) {
    from = raw.fromEmail.trim();
  }
  return raw.copyWith(
    host: host.isEmpty ? raw.host.trim() : host,
    username: username,
    password: password,
    fromEmail: from,
  );
}

SmtpServer createSmtpServer(SmtpSettings settings) {
  final smtp = normalizeSmtpSettings(settings);
  if (isGmailSmtpHost(smtp.host)) {
    if (smtp.useSsl) {
      return SmtpServer(
        'smtp.gmail.com',
        port: 465,
        username: smtp.username,
        password: smtp.password,
        ssl: true,
      );
    }
    return gmail(smtp.username, smtp.password);
  }
  return SmtpServer(
    smtp.host,
    port: smtp.port,
    username: smtp.username,
    password: smtp.password,
    ssl: smtp.useSsl,
    allowInsecure: false,
  );
}
