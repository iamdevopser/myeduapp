import '../data/local/app_database.dart';
import '../models/app_role.dart';
import 'account_service.dart';

/// Yönetici paneli özet istatistikleri (salt okuma, aggregate).
class AdminDashboardStats {
  const AdminDashboardStats({
    required this.totalAccounts,
    required this.activeAccounts,
    required this.studentCount,
    required this.classSectionCount,
    required this.parentGuardianCount,
    required this.teacherAccountCount,
    required this.secretaryAccountCount,
    required this.parentAccountCount,
  });

  final int totalAccounts;
  final int activeAccounts;
  final int studentCount;
  final int classSectionCount;
  final int parentGuardianCount;
  final int teacherAccountCount;
  final int secretaryAccountCount;
  final int parentAccountCount;
}

/// Admin workspace read-only özetleri — hesap yönetimi `AccountService` ile kalır.
class AdminPortalService {
  AdminPortalService(this._db, {required int actorAccountId})
    : _accounts = AccountService(_db, actorAccountId: actorAccountId);

  final AppDatabase _db;
  final AccountService _accounts;

  Future<AdminDashboardStats> loadDashboardStats() async {
    final accounts = await _accounts.listAccounts();
    final active = accounts.where((a) => a.active).length;
    final students = await _db.countAllStudents();
    final classes = await _db.getStudentClasses();
    final parentRows = await _db.database.rawQuery(
      'SELECT COUNT(*) as c FROM veliler',
    );
    final parentGuardians = parentRows.first['c'] as int? ?? 0;

    int countRole(AppRole role) => accounts.where((a) => a.role == role).length;

    return AdminDashboardStats(
      totalAccounts: accounts.length,
      activeAccounts: active,
      studentCount: students,
      classSectionCount: classes.length,
      parentGuardianCount: parentGuardians,
      teacherAccountCount: countRole(AppRole.teacher),
      secretaryAccountCount: countRole(AppRole.secretary),
      parentAccountCount: countRole(AppRole.parent),
    );
  }
}
