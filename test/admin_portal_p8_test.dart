import 'package:flutter_test/flutter_test.dart';
import 'package:my_edu_app/data/local/app_database.dart';
import 'package:my_edu_app/models/app_role.dart';
import 'package:my_edu_app/services/account_service.dart';
import 'package:my_edu_app/services/admin_portal_service.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

Future<int> _bootstrapAdmin(AppDatabase db) async {
  return AccountService(db, actorAccountId: 0).createBootstrapAdmin(
    username: 'admin.p8',
    fullName: 'P8 Admin',
    passwordPlain: 'AdminPass123!',
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;

  late AppDatabase db;

  setUp(() async {
    db = AppDatabase('admin_p8_${DateTime.now().microsecondsSinceEpoch}.sqlite');
    await db.open();
  });

  tearDown(() async {
    await db.close();
  });

  test('loadDashboardStats returns aggregate counts', () async {
    final adminId = await _bootstrapAdmin(db);
    final classId = await db.insertStudentClass('8', '2025', section: 'A');
    await db.insertStudent(
      classId: classId,
      number: 1,
      name: 'Student One',
    );

    final service = AdminPortalService(db, actorAccountId: adminId);
    final stats = await service.loadDashboardStats();

    expect(stats.totalAccounts, greaterThanOrEqualTo(1));
    expect(stats.activeAccounts, greaterThanOrEqualTo(1));
    expect(stats.studentCount, 1);
    expect(stats.classSectionCount, 1);
  });

  test('AccountService still requires admin actor for list', () async {
    final adminId = await _bootstrapAdmin(db);
    final adminSvc = AccountService(db, actorAccountId: adminId);
    final teacherId = await adminSvc.createStaffAccount(
      username: 'teacher.p8',
      fullName: 'Teacher',
      passwordPlain: 'pass',
      role: AppRole.teacher,
    );
    expect(
      () => AccountService(db, actorAccountId: teacherId).listAccounts(),
      throwsA(isA<AccountAccessDeniedException>()),
    );
  });
}
