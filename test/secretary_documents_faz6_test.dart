import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:my_edu_app/data/local/app_database.dart';
import 'package:my_edu_app/models/app_role.dart';
import 'package:my_edu_app/providers/app_state.dart';
import 'package:my_edu_app/services/app_paths.dart';
import 'package:my_edu_app/services/authorization_service.dart';
import 'package:my_edu_app/services/file_service.dart';
import 'package:my_edu_app/services/secretary_document_service.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;

  late AppDatabase db;
  late SecretaryDocumentService service;

  setUp(() async {
    db = AppDatabase('faz6_${DateTime.now().microsecondsSinceEpoch}.sqlite');
    await db.open();
    service = SecretaryDocumentService(db, FileService(AppPaths()));
  });

  tearDown(() async {
    await db.close();
  });

  test('schema version 31 extends icerikler for secretary documents', () async {
    final v = await db.database.rawQuery('PRAGMA user_version');
    expect(v.first['user_version'], 35);
    final cols = await db.database.rawQuery('PRAGMA table_info(icerikler)');
    final names = cols.map((c) => c['name'] as String).toSet();
    expect(names.contains('kritik'), isTrue);
    expect(names.contains('belge_kategori'), isTrue);
    expect(names.contains('guncelleme_tarihi'), isTrue);
  });

  test('insert list search filter and metadata update', () async {
    final id = await db.insertSecretaryDocument(
      name: 'Yönerge',
      type: 'pdf',
      path: r'C:\fake\yonerge.pdf',
      description: 'Okul yönergesi',
      category: 'Resmi',
      scope: 'Tüm okul',
    );
    await db.insertSecretaryDocument(
      name: 'Form',
      type: 'docx',
      path: r'C:\fake\form.docx',
      category: 'İdari',
    );
    final all = await service.list();
    expect(all.length, 2);
    final found = await service.list(search: 'Yönerge');
    expect(found.length, 1);
    expect(found.first.category, 'Resmi');

    await service.updateMetadata(
      id: id,
      title: 'Yönerge Güncel',
      description: 'Revize',
      category: 'Resmi',
      scope: 'Personel',
    );
    final one = await service.getById(id);
    expect(one!.name, 'Yönerge Güncel');
    expect(one.scope, 'Personel');

    final cats = await service.distinctCategories();
    expect(cats, contains('Resmi'));
    expect(cats, contains('İdari'));
  });

  test('secretary cannot delete documents service level', () async {
    final id = await db.insertSecretaryDocument(
      name: 'Silinemez',
      type: 'pdf',
      path: r'C:\fake\a.pdf',
    );
    final ok = await service.deleteForRole(id, AppRole.secretary);
    expect(ok, isFalse);
    expect(await service.getById(id), isNotNull);
  });

  test('critical document delete blocked for secretary and archive blocked', () async {
    final id = await db.insertSecretaryDocument(
      name: 'Kritik',
      type: 'pdf',
      path: r'C:\fake\kritik.pdf',
    );
    await db.database.update(
      'icerikler',
      {'kritik': 1},
      where: 'id = ?',
      whereArgs: [id],
    );
    expect(await service.deleteForRole(id, AppRole.secretary), isFalse);
    expect(
      await service.archiveForSecretary(id, AppRole.secretary),
      isFalse,
    );
    final row = await service.getById(id);
    expect(row!.critical, isTrue);
    expect(row.archived, isFalse);
  });

  test('non-critical document can be archived by secretary', () async {
    final id = await db.insertSecretaryDocument(
      name: 'Arşiv',
      type: 'pdf',
      path: r'C:\fake\arsiv.pdf',
    );
    final ok = await service.archiveForSecretary(id, AppRole.secretary);
    expect(ok, isTrue);
    final row = await service.getById(id);
    expect(row!.archived, isTrue);
  });

  test('isSecretaryDocument scopes to evraklar lesson', () async {
    final lessonId = await db.ensureSecretaryDocumentsLessonId();
    final otherLesson = await db.insertLesson(
      (await db.getClasses()).first.id,
      'Başka Ders',
      99,
    );
    final otherId = await db.database.insert('icerikler', {
      'ders_id': otherLesson,
      'ad': 'Dış',
      'tur': 'pdf',
      'dosya_yolu': r'C:\x.pdf',
      'sira': 1,
      'olusturma_tarihi': DateTime.now().toIso8601String(),
    });
    final secId = await db.insertSecretaryDocument(
      name: 'İç',
      type: 'pdf',
      path: r'C:\fake\ic.pdf',
    );
    expect(await db.isSecretaryDocument(secId), isTrue);
    expect(await db.isSecretaryDocument(otherId), isFalse);
    final listed = await service.list();
    expect(listed.every((d) => d.id == secId), isTrue);
    expect(lessonId, greaterThan(0));
  });

  test('secretary document authorization flags', () async {
    final state = await AppState.createWithDatabase(db);
    state.setUnlocked(true, role: AppRole.secretary);
    final auth = AuthorizationService(state);
    expect(auth.canViewDocuments, isTrue);
    expect(auth.canCreateDocument, isTrue);
    expect(auth.canEditDocument, isTrue);
    expect(auth.canOpenDocument, isTrue);
    expect(auth.canDownloadDocument, isTrue);
    expect(auth.canDeleteCriticalDocument, isFalse);
    expect(auth.canPhysicallyDeleteDocument, isFalse);
    expect(auth.canArchiveDocument, isTrue);
  });

  test('teacher can physically delete non-secretary content via role gate', () async {
    final classes = await db.getClasses();
    final classId = classes.isNotEmpty
        ? classes.first.id
        : await db.insertClass('Test');
    final lessonId = await db.insertLesson(classId, 'Ders', 1);
    final contentId = await db.database.insert('icerikler', {
      'ders_id': lessonId,
      'ad': 'Öğretmen',
      'tur': 'pdf',
      'dosya_yolu': r'C:\t.pdf',
      'sira': 1,
      'olusturma_tarihi': DateTime.now().toIso8601String(),
    });
    final ok = await db.tryDeleteContentForRole(
      contentId: contentId,
      roleName: 'teacher',
    );
    expect(ok, isTrue);
    expect(await db.getContentById(contentId), isNull);
  });

  test('createFromFile copies into content dir', () async {
    final tempDir = await Directory.systemTemp.createTemp('faz6_src_');
    final src = File('${tempDir.path}/sample.txt');
    await src.writeAsString('hello');
    final id = await service.createFromFile(
      title: 'Örnek',
      sourcePath: src.path,
      category: 'Test',
    );
    final doc = await service.getById(id);
    expect(doc, isNotNull);
    expect(await File(doc!.path).exists(), isTrue);
    await tempDir.delete(recursive: true);
  });
}
