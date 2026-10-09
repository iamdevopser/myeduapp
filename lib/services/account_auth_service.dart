import '../data/local/app_database.dart';
import '../data/models/app_account.dart';
import '../models/app_role.dart';
import '../utils/student_password_hash.dart';

class AccountAuthResult {
  const AccountAuthResult({
    required this.account,
    required this.mustChangePassword,
  });

  final AppAccount account;
  final bool mustChangePassword;
}

/// Hesap tablosu üzerinden kimlik doğrulama (plain şifre DB'ye yazılmaz).
class AccountAuthService {
  AccountAuthService(this._db);

  final AppDatabase _db;

  Future<AccountAuthResult?> authenticate({
    required String login,
    required String passwordPlain,
    required AppRole role,
  }) async {
    final row = await _db.findAccountByLogin(login: login, role: role.name);
    if (row == null) return null;
    if ((row['aktif'] as int? ?? 0) != 1) return null;
    if (!StudentPasswordHash.matches(
      passwordPlain,
      row['sifre_hash'] as String?,
    )) {
      return null;
    }
    final account = AppAccount.fromMap(row);
    await _db.recordAccountLogin(account.id);
    return AccountAuthResult(
      account: account,
      mustChangePassword: account.mustChangePassword,
    );
  }
}
