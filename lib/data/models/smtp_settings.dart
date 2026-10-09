class SmtpSettings {
  const SmtpSettings({
    required this.host,
    required this.port,
    required this.username,
    required this.password,
    required this.fromEmail,
    this.useSsl = false,
  });

  final String host;
  final int port;
  final String username;
  final String password;
  final String fromEmail;
  final bool useSsl;

  bool get isConfigured =>
      host.trim().isNotEmpty &&
      fromEmail.trim().isNotEmpty &&
      username.trim().isNotEmpty &&
      password.isNotEmpty;

  SmtpSettings copyWith({
    String? host,
    int? port,
    String? username,
    String? password,
    String? fromEmail,
    bool? useSsl,
  }) {
    return SmtpSettings(
      host: host ?? this.host,
      port: port ?? this.port,
      username: username ?? this.username,
      password: password ?? this.password,
      fromEmail: fromEmail ?? this.fromEmail,
      useSsl: useSsl ?? this.useSsl,
    );
  }
}
