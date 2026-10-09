import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import '../data/local/app_database.dart';
import '../data/models/app_account.dart';
import '../models/app_role.dart';
import '../utils/student_password_hash.dart';

class AccountAccessDeniedException implements Exception {
  const AccountAccessDeniedException();
}

class AccountValidationException implements Exception {
  AccountValidationException(this.messageKey);
  final String messageKey;
}

class LastAdminProtectionException implements Exception {
  const LastAdminProtectionException();
}

/// Merkezi hesap yönetimi — yalnızca aktif admin hesabı üzerinden.
class AccountService {
  AccountService(this._db, {required this.actorAccountId});

  final AppDatabase _db;
  final int actorAccountId;

  static const domainStudent = 'ogrenci';
  static const domainParent = 'veli';

  Future<void> _requireAdmin() async {
    final actor = await _db.getAccountById(actorAccountId);
    if (actor == null) throw const AccountAccessDeniedException();
    if (actor['rol'] != AppRole.admin.name) {
      throw const AccountAccessDeniedException();
    }
    if ((actor['aktif'] as int? ?? 0) != 1) {
      throw const AccountAccessDeniedException();
    }
  }

  Future<List<AppAccount>> listAccounts({
    AppRole? roleFilter,
    String? search,
    bool? activeOnly,
  }) async {
    await _requireAdmin();
    final rows = await _db.listAccounts(
      roleFilter: roleFilter?.name,
      search: search,
      activeOnly: activeOnly,
    );
    return rows.map(AppAccount.fromMap).toList();
  }

  Future<AppAccount?> getAccount(int id) async {
    await _requireAdmin();
    final row = await _db.getAccountById(id);
    if (row == null) return null;
    return AppAccount.fromMap(row);
  }

  Future<int> createBootstrapAdmin({
    required String username,
    required String fullName,
    required String passwordPlain,
    String? email,
  }) async {
    if (await _db.hasActiveAdminAccount()) {
      throw const AccountAccessDeniedException();
    }
    return _createAccountInternal(
      username: username,
      fullName: fullName,
      email: email,
      role: AppRole.admin,
      passwordPlain: passwordPlain,
      domainType: null,
      domainId: null,
      actorAccountId: null,
      syncDomainPassword: false,
    );
  }

  /// Yönetici yalnızca öğretmen ve sekreter personel hesabı oluşturur.
  Future<int> createStaffAccount({
    required String username,
    required String fullName,
    required String passwordPlain,
    required AppRole role,
    String? email,
    bool mustChangePassword = true,
  }) async {
    await _requireAdmin();
    if (role != AppRole.teacher && role != AppRole.secretary) {
      throw AccountValidationException('adminStaffRoleOnly');
    }
    return _createAccountInternal(
      username: username,
      fullName: fullName,
      email: email,
      role: role,
      passwordPlain: passwordPlain,
      domainType: null,
      domainId: null,
      actorAccountId: actorAccountId,
      syncDomainPassword: false,
      mustChangePassword: mustChangePassword,
    );
  }

  /// Veli portal hesabı — sekreter veli kaydı sonrası (domain bağlantılı).
  Future<int> createParentPortalAccount({
    required int parentId,
    required String username,
    required String fullName,
    required String passwordPlain,
    String? email,
    int? actorAccountId,
    bool mustChangePassword = false,
  }) async {
    final existing = await _db.getAccountForDomain(
      domainType: domainParent,
      domainId: parentId,
    );
    if (existing != null) {
      throw AccountValidationException('adminAccountDomainExists');
    }
    return _createAccountInternal(
      username: username,
      fullName: fullName,
      email: email,
      role: AppRole.parent,
      passwordPlain: passwordPlain,
      domainType: domainParent,
      domainId: parentId,
      actorAccountId: actorAccountId,
      syncDomainPassword: true,
      mustChangePassword: mustChangePassword,
    );
  }

  /// Öğrenci portal hesabı — sekreter öğrenci kaydı sonrası (domain bağlantılı).
  Future<int> createStudentPortalAccount({
    required int studentId,
    required String username,
    required String fullName,
    required String passwordPlain,
    String? email,
    int? actorAccountId,
    bool mustChangePassword = false,
  }) async {
    final existing = await _db.getAccountForDomain(
      domainType: domainStudent,
      domainId: studentId,
    );
    if (existing != null) {
      throw AccountValidationException('adminAccountDomainExists');
    }
    return _createAccountInternal(
      username: username,
      fullName: fullName,
      email: email,
      role: AppRole.student,
      passwordPlain: passwordPlain,
      domainType: domainStudent,
      domainId: studentId,
      actorAccountId: actorAccountId,
      syncDomainPassword: true,
      mustChangePassword: mustChangePassword,
    );
  }

  Future<int> _createAccountInternal({
    required String username,
    required String fullName,
    required String passwordPlain,
    required AppRole role,
    String? email,
    String? domainType,
    int? domainId,
    required int? actorAccountId,
    required bool syncDomainPassword,
    bool mustChangePassword = false,
  }) async {
    _validateUsername(username);
    await _ensureAccountCredentialsAvailable(username: username, email: email);
    final hash = StudentPasswordHash.hash(passwordPlain);
    if (hash == null) {
      throw AccountValidationException('adminAccountPasswordRequired');
    }

    late final int id;
    try {
      id = await _db.insertAccount(
        username: username,
        email: email,
        fullName: fullName,
        role: role.name,
        passwordHash: hash,
        active: true,
        domainType: domainType,
        domainId: domainId,
        mustChangePassword: mustChangePassword,
      );
    } on DatabaseException catch (e) {
      _rethrowMappedAccountInsert(e);
    } catch (e) {
      _rethrowMappedAccountInsertFromUnknown(e);
    }

    if (syncDomainPassword && domainType == domainStudent && domainId != null) {
      await _db.setStudentPasswordHash(domainId, hash);
    }
    if (syncDomainPassword && domainType == domainParent && domainId != null) {
      await _db.setParentPasswordHash(domainId, hash);
      if (email != null && email.trim().isNotEmpty) {
        await _db.updateParentEmail(domainId, email.trim());
      }
    }

    await _db.insertAccountAudit(
      targetAccountId: id,
      actionType: 'account_created',
      detail: role.name,
      actorAccountId: actorAccountId,
    );
    return id;
  }

  /// Oturum sahibi kendi şifresini günceller (zorunlu ilk giriş / self-service).
  Future<void> changePasswordAsAccountOwner({
    required int accountId,
    required int actorAccountId,
    required String newPasswordPlain,
  }) async {
    if (accountId != actorAccountId) {
      throw const AccountAccessDeniedException();
    }
    final row = await _db.getAccountById(accountId);
    if (row == null) throw AccountValidationException('adminAccountNotFound');
    if ((row['aktif'] as int? ?? 0) != 1) {
      throw const AccountAccessDeniedException();
    }
    final hash = StudentPasswordHash.hash(newPasswordPlain);
    if (hash == null) {
      throw AccountValidationException('adminAccountPasswordRequired');
    }

    await _db.setAccountPasswordHash(
      id: accountId,
      passwordHash: hash,
      mustChangePassword: false,
    );

    final domainType = row['domain_tur'] as String?;
    final domainId = row['domain_id'] as int?;
    if (domainType == domainStudent && domainId != null) {
      await _db.setStudentPasswordHash(domainId, hash);
    }
    if (domainType == domainParent && domainId != null) {
      await _db.setParentPasswordHash(domainId, hash);
    }

    await _db.insertAccountAudit(
      targetAccountId: accountId,
      actionType: 'password_changed',
      actorAccountId: actorAccountId,
    );
  }

  Future<void> resetPassword({
    required int accountId,
    required String newPasswordPlain,
    bool mustChangePassword = true,
  }) async {
    await _requireAdmin();
    final hash = StudentPasswordHash.hash(newPasswordPlain);
    if (hash == null) {
      throw AccountValidationException('adminAccountPasswordRequired');
    }
    final row = await _db.getAccountById(accountId);
    if (row == null) throw AccountValidationException('adminAccountNotFound');

    await _db.setAccountPasswordHash(
      id: accountId,
      passwordHash: hash,
      mustChangePassword: mustChangePassword,
    );

    final domainType = row['domain_tur'] as String?;
    final domainId = row['domain_id'] as int?;
    if (domainType == domainStudent && domainId != null) {
      await _db.setStudentPasswordHash(domainId, hash);
    }
    if (domainType == domainParent && domainId != null) {
      await _db.setParentPasswordHash(domainId, hash);
    }

    await _db.insertAccountAudit(
      targetAccountId: accountId,
      actionType: 'password_reset',
      actorAccountId: actorAccountId,
    );
  }

  Future<void> setActive({required int accountId, required bool active}) async {
    await _requireAdmin();
    final row = await _db.getAccountById(accountId);
    if (row == null) throw AccountValidationException('adminAccountNotFound');

    final role = row['rol'] as String;
    final isActive = (row['aktif'] as int? ?? 1) == 1;
    if (role == AppRole.admin.name && isActive && !active) {
      final others = await _db.countActiveAdmins(excludeAccountId: accountId);
      if (others == 0) throw const LastAdminProtectionException();
    }

    await _db.updateAccountFields(id: accountId, active: active);
    await _db.insertAccountAudit(
      targetAccountId: accountId,
      actionType: active ? 'account_activated' : 'account_deactivated',
      actorAccountId: actorAccountId,
    );
  }

  /// Throws [AccountValidationException] if a new account with these
  /// credentials could not be created (short / taken username, taken email).
  Future<void> ensureCredentialsAvailable({
    required String username,
    String? email,
  }) async {
    _validateUsername(username);
    await _ensureAccountCredentialsAvailable(username: username, email: email);
  }

  void _validateUsername(String username) {
    final t = username.trim();
    if (t.length < 3) {
      throw AccountValidationException('adminAccountUsernameShort');
    }
  }

  Future<void> _ensureAccountCredentialsAvailable({
    required String username,
    String? email,
  }) async {
    if (await _db.getAccountByUsername(username) != null) {
      throw AccountValidationException('adminAccountUsernameTaken');
    }
    final emailTrim = email?.trim();
    if (emailTrim != null && emailTrim.isNotEmpty) {
      if (await _db.getAccountByEmail(emailTrim) != null) {
        throw AccountValidationException('adminAccountEmailTaken');
      }
    }
  }

  void _rethrowMappedAccountInsert(DatabaseException e) {
    final mapped = _mapUniqueConstraintMessage(e.toString());
    if (mapped != null) {
      throw AccountValidationException(mapped);
    }
    if (e.isUniqueConstraintError()) {
      throw AccountValidationException('adminAccountCreateFailed');
    }
    throw e;
  }

  void _rethrowMappedAccountInsertFromUnknown(Object e) {
    final mapped = _mapUniqueConstraintMessage(e.toString());
    if (mapped != null) {
      throw AccountValidationException(mapped);
    }
    throw e;
  }

  String? _mapUniqueConstraintMessage(String detail) {
    final lower = detail.toLowerCase();
    if (!lower.contains('unique') && !lower.contains('2067')) {
      return null;
    }
    if (lower.contains('kullanici_adi') || lower.contains('username')) {
      return 'adminAccountUsernameTaken';
    }
    if (lower.contains('email')) {
      return 'adminAccountEmailTaken';
    }
    return 'adminAccountCreateFailed';
  }
}
