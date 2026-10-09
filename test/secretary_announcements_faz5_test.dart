import 'package:flutter_test/flutter_test.dart';
import 'package:my_edu_app/data/local/app_database.dart';
import 'package:my_edu_app/models/app_role.dart';
import 'package:my_edu_app/models/student_enrollment.dart';
import 'package:my_edu_app/providers/app_state.dart';
import 'package:my_edu_app/services/authorization_service.dart';
import 'package:my_edu_app/services/secretary_announcement_service.dart';
import 'package:my_edu_app/services/student_portal_service.dart';
import 'package:my_edu_app/utils/student_announcement_meta.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;

  late AppDatabase db;
  late SecretaryAnnouncementService service;
  late StudentPortalService portalService;

  setUp(() async {
    db = AppDatabase('faz5_${DateTime.now().microsecondsSinceEpoch}.sqlite');
    await db.open();
    service = SecretaryAnnouncementService(db);
    portalService = StudentPortalService(db);
  });

  tearDown(() async {
    await db.close();
  });

  test('schema version 31 extends ogrenci_duyurular', () async {
    final v = await db.database.rawQuery('PRAGMA user_version');
    expect(v.first['user_version'], 35);
    final cols = await db.database.rawQuery('PRAGMA table_info(ogrenci_duyurular)');
    final names = cols.map((c) => c['name'] as String).toSet();
    expect(names.contains('durum'), isTrue);
    expect(names.contains('hedef_tur'), isTrue);
  });

  test('create update publish unpublish and targeting', () async {
    final class7a = await db.insertStudentClass('7', '2025', section: 'A');
    final id = await service.create(
      title: 'Taslak',
      body: 'İçerik',
      targetType: StudentAnnouncementTargetType.allSchool,
      status: StudentAnnouncementStatus.draft,
    );
    var item = await service.getById(id);
    expect(item!.status, StudentAnnouncementStatus.draft);

    await service.update(
      id: id,
      title: 'Güncel',
      body: 'Yeni içerik',
      targetType: StudentAnnouncementTargetType.section,
      classId: class7a,
    );
    await service.publish(id);
    item = await service.getById(id);
    expect(item!.status, StudentAnnouncementStatus.published);
    expect(item.targetType, StudentAnnouncementTargetType.section);

    await service.unpublish(id);
    item = await service.getById(id);
    expect(item!.status, StudentAnnouncementStatus.unpublished);
  });

  test('legacy teacher announcement still visible when published', () async {
    final classA = await db.insertStudentClass('7', '2025', section: 'A');
    await db.insertStudentAnnouncement(
      title: 'Öğretmen',
      body: 'Mesaj',
      classId: classA,
    );
    final rows = await db.listStudentAnnouncementsForClasses({classA});
    expect(rows.any((r) => r['baslik'] == 'Öğretmen'), isTrue);
  });

  test('draft hidden from student portal published grade target works', () async {
    final class7a = await db.insertStudentClass('7', '2025', section: 'A');
    final class7b = await db.insertStudentClass('7', '2025', section: 'B');
    await service.create(
      title: 'Gizli',
      body: 'Taslak',
      targetType: StudentAnnouncementTargetType.allSchool,
    );
    final gradeId = await service.create(
      title: '7. sınıf',
      body: 'Hepsi',
      targetType: StudentAnnouncementTargetType.grade,
      targetGradeLevel: 7,
      status: StudentAnnouncementStatus.draft,
    );
    await service.publish(gradeId);

    final enrB = StudentEnrollment(
      classId: class7b,
      studentId: 1,
      className: '7',
      section: 'B',
      studentName: 'X',
      number: 1,
    );
    final items = await portalService.loadAnnouncements([enrB]);
    expect(items.any((a) => a.title == 'Gizli'), isFalse);
    expect(items.any((a) => a.title == '7. sınıf'), isTrue);

    final class8 = await db.insertStudentClass('8', '2025', section: 'A');
    final enr8 = StudentEnrollment(
      classId: class8,
      studentId: 2,
      className: '8',
      section: 'A',
      studentName: 'Y',
      number: 2,
    );
    final items8 = await portalService.loadAnnouncements([enr8]);
    expect(items8.any((a) => a.title == '7. sınıf'), isFalse);
  });

  test('search and filter list', () async {
    await service.create(
      title: 'Spor',
      body: 'Turnuva',
      targetType: StudentAnnouncementTargetType.allSchool,
    );
    await service.create(
      title: 'Müzik',
      body: 'Konser',
      targetType: StudentAnnouncementTargetType.allSchool,
      status: StudentAnnouncementStatus.published,
    );
    final found = await service.list(search: 'Spor');
    expect(found.length, 1);
    final published = await service.list(
      statusFilter: StudentAnnouncementStatus.published,
    );
    expect(published.any((a) => a.title == 'Müzik'), isTrue);
  });

  test('secretary announcement authorization', () async {
    final state = await AppState.createWithDatabase(db);
    state.setUnlocked(true, role: AppRole.secretary);
    final auth = AuthorizationService(state);
    expect(auth.canViewAnnouncements, isTrue);
    expect(auth.canPublishAnnouncement, isTrue);
    expect(auth.canDeleteAnnouncement, isFalse);
  });
}
