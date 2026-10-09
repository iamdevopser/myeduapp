import 'package:flutter_test/flutter_test.dart';
import 'package:my_edu_app/data/local/app_database.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  sqfliteFfiInit();

  late AppDatabase db;

  setUp(() async {
    databaseFactory = databaseFactoryFfi;
    db = AppDatabase(inMemoryDatabasePath);
    await db.open();
  });

  tearDown(() async {
    await db.close();
  });

  test('folder links content without duplicating icerik row', () async {
    final classId = await db.insertClass('8.SINIFLAR');
    final lessonId = await db.insertLesson(classId, 'Matematik', 0);
    final contentId = await db.insertContent(
      lessonId: lessonId,
      topicId: null,
      name: 'Dosya.pdf',
      type: 'pdf',
      path: '/tmp/dosya.pdf',
      order: 0,
    );
    final folderA = await db.insertDocumentFolder('A');
    final folderB = await db.insertDocumentFolder('B');
    await db.addContentToFolder(folderId: folderA, contentId: contentId);
    await db.addContentToFolder(folderId: folderB, contentId: contentId);

    final inA = await db.getFolderContents(folderA);
    final inB = await db.getFolderContents(folderB);
    expect(inA.length, 1);
    expect(inB.length, 1);
    expect(inA.first.item.id, contentId);
    expect(inB.first.item.id, contentId);
  });

  test('deleting folder keeps icerik', () async {
    final classId = await db.insertClass('8.SINIFLAR');
    final lessonId = await db.insertLesson(classId, 'Fizik', 0);
    final contentId = await db.insertContent(
      lessonId: lessonId,
      topicId: null,
      name: 'x.pdf',
      type: 'pdf',
      path: '/tmp/x.pdf',
      order: 0,
    );
    final folderId = await db.insertDocumentFolder('Genel');
    await db.addContentToFolder(folderId: folderId, contentId: contentId);
    await db.deleteDocumentFolder(folderId);

    final contents = await db.getContents(lessonId);
    expect(contents.any((c) => c.id == contentId), isTrue);
    final folders = await db.getDocumentFolders();
    expect(folders.where((f) => f.id == folderId), isEmpty);
    expect(contents.any((c) => c.id == contentId), isTrue);
  });

  test('folder picker splits documents and homework', () async {
    final classId = await db.insertClass('8.SINIFLAR');
    final lessonId = await db.insertLesson(classId, 'Matematik', 0);
    await db.insertContent(
      lessonId: lessonId,
      topicId: null,
      name: 'Konu.pdf',
      type: 'pdf',
      path: '/tmp/konu.pdf',
      order: 0,
    );
    await db.insertContent(
      lessonId: lessonId,
      topicId: null,
      name: 'Ödev 1',
      type: 'homework',
      path: '/tmp/odev',
      order: 1,
    );
    final docs = await db.listContentsForFolderPicker(homeworkOnly: false);
    final homework = await db.listContentsForFolderPicker(homeworkOnly: true);
    expect(docs.map((r) => r.item.name), ['Konu.pdf']);
    expect(homework.map((r) => r.item.name), ['Ödev 1']);
  });

  test('folder item counts aggregate junction rows', () async {
    final classId = await db.insertClass('8.SINIFLAR');
    final lessonId = await db.insertLesson(classId, 'Matematik', 0);
    final c1 = await db.insertContent(
      lessonId: lessonId,
      topicId: null,
      name: 'a.pdf',
      type: 'pdf',
      path: '/tmp/a.pdf',
      order: 0,
    );
    final c2 = await db.insertContent(
      lessonId: lessonId,
      topicId: null,
      name: 'b.pdf',
      type: 'pdf',
      path: '/tmp/b.pdf',
      order: 1,
    );
    final folderId = await db.insertDocumentFolder('Sayım');
    await db.addContentToFolder(folderId: folderId, contentId: c1);
    await db.addContentToFolder(folderId: folderId, contentId: c2);
    final counts = await db.getDocumentFolderItemCounts();
    expect(counts[folderId], 2);
  });

  test('nested folders use parent_id and path', () async {
    final rootId = await db.insertDocumentFolder('9. Sınıf');
    final mathId = await db.insertDocumentFolder(
      'Matematik',
      parentId: rootId,
    );
    final unitId = await db.insertDocumentFolder(
      '1. Ünite',
      parentId: mathId,
    );
    final roots = await db.getDocumentFolders();
    expect(roots.map((f) => f.name), ['9. Sınıf']);
    final mathChildren = await db.getDocumentFolders(parentId: rootId);
    expect(mathChildren.single.name, 'Matematik');
    final path = await db.getDocumentFolderPath(unitId);
    expect(path.map((f) => f.name), ['9. Sınıf', 'Matematik', '1. Ünite']);
    final childCounts = await db.getDocumentFolderChildCounts();
    expect(childCounts[rootId], 1);
    expect(childCounts[mathId], 1);
  });

  test('folder picker filters by lesson', () async {
    final classId = await db.insertClass('8.SINIFLAR');
    final matId = await db.insertLesson(classId, 'Matematik', 0);
    final fizId = await db.insertLesson(classId, 'Fizik', 1);
    await db.insertContent(
      lessonId: matId,
      topicId: null,
      name: 'Mat.pdf',
      type: 'pdf',
      path: '/tmp/mat.pdf',
      order: 0,
    );
    await db.insertContent(
      lessonId: fizId,
      topicId: null,
      name: 'Fiz.pdf',
      type: 'pdf',
      path: '/tmp/fiz.pdf',
      order: 0,
    );
    final matOnly = await db.listContentsForFolderPicker(lessonId: matId);
    expect(matOnly.map((r) => r.item.name), ['Mat.pdf']);
  });

  test('removeContentFromFolder keeps icerik row', () async {
    final classId = await db.insertClass('8.SINIFLAR');
    final lessonId = await db.insertLesson(classId, 'Matematik', 0);
    final contentId = await db.insertContent(
      lessonId: lessonId,
      topicId: null,
      name: 'y.pdf',
      type: 'pdf',
      path: '/tmp/y.pdf',
      order: 0,
    );
    final folderId = await db.insertDocumentFolder('Ders');
    await db.addContentToFolder(folderId: folderId, contentId: contentId);
    await db.removeContentFromFolder(
      folderId: folderId,
      contentId: contentId,
    );
    expect(await db.getFolderContents(folderId), isEmpty);
    final contents = await db.getContents(lessonId);
    expect(contents.any((c) => c.id == contentId), isTrue);
  });
}
