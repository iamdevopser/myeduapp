import '../../models/app_role.dart';

class AppAccount {
  const AppAccount({
    required this.id,
    required this.username,
    this.email,
    required this.fullName,
    required this.role,
    required this.active,
    this.domainType,
    this.domainId,
    required this.mustChangePassword,
    required this.createdAt,
    required this.updatedAt,
    this.lastLoginAt,
  });

  final int id;
  final String username;
  final String? email;
  final String fullName;
  final AppRole role;
  final bool active;
  final String? domainType;
  final int? domainId;
  final bool mustChangePassword;
  final String createdAt;
  final String updatedAt;
  final String? lastLoginAt;

  static AppAccount fromMap(Map<String, Object?> row) {
    return AppAccount(
      id: row['id'] as int,
      username: row['kullanici_adi'] as String,
      email: row['email'] as String?,
      fullName: row['ad_soyad'] as String? ?? '',
      role: AppRole.values.byName(row['rol'] as String),
      active: (row['aktif'] as int? ?? 1) == 1,
      domainType: row['domain_tur'] as String?,
      domainId: row['domain_id'] as int?,
      mustChangePassword: (row['sifre_degistir'] as int? ?? 0) == 1,
      createdAt: row['olusturma_tarihi'] as String,
      updatedAt: row['guncelleme_tarihi'] as String,
      lastLoginAt: row['son_giris_tarihi'] as String?,
    );
  }

  String get roleDbValue => role.name;
}
