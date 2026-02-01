import 'dart:async';

import 'package:path/path.dart' as p;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import '../models/class_model.dart';
import '../models/content_item.dart';
import '../models/content_with_tags.dart';
import '../models/lesson_model.dart';
import '../models/tag_model.dart';

class AppDatabase {
  AppDatabase(this.dbPath);

  final String dbPath;
  Database? _db;

  Future<void> open() async {
    _db = await openDatabase(
      dbPath,
      version: 8,
      onConfigure: (db) async {
        await db.execute('PRAGMA foreign_keys = ON');
      },
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE siniflar (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            ad TEXT NOT NULL,
            olusturma_tarihi TEXT NOT NULL
          )
        ''');
        await db.execute('''
          CREATE TABLE dersler (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            sinif_id INTEGER NOT NULL,
            ad TEXT NOT NULL,
            sira INTEGER NOT NULL,
            olusturma_tarihi TEXT NOT NULL,
            FOREIGN KEY (sinif_id) REFERENCES siniflar(id) ON DELETE CASCADE
          )
        ''');
        await db.execute('''
          CREATE TABLE icerikler (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            ders_id INTEGER NOT NULL,
            konu_id INTEGER,
            ad TEXT NOT NULL,
            tur TEXT NOT NULL,
            dosya_yolu TEXT NOT NULL,
            sira INTEGER NOT NULL,
            olusturma_tarihi TEXT NOT NULL,
            arsiv INTEGER NOT NULL DEFAULT 0,
            FOREIGN KEY (ders_id) REFERENCES dersler(id) ON DELETE CASCADE,
            FOREIGN KEY (konu_id) REFERENCES konular(id) ON DELETE SET NULL
          )
        ''');
        await db.execute('''
          CREATE TABLE konular (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            ders_id INTEGER NOT NULL,
            ad TEXT NOT NULL,
            sira INTEGER NOT NULL,
            olusturma_tarihi TEXT NOT NULL,
            FOREIGN KEY (ders_id) REFERENCES dersler(id) ON DELETE CASCADE
          )
        ''');
        await db.execute('''
          CREATE TABLE etiketler (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            ad TEXT NOT NULL UNIQUE
          )
        ''');
        await db.execute('''
          CREATE TABLE icerik_etiketleri (
            icerik_id INTEGER NOT NULL,
            etiket_id INTEGER NOT NULL,
            PRIMARY KEY (icerik_id, etiket_id),
            FOREIGN KEY (icerik_id) REFERENCES icerikler(id) ON DELETE CASCADE,
            FOREIGN KEY (etiket_id) REFERENCES etiketler(id) ON DELETE CASCADE
          )
        ''');
        await db.execute('''
          CREATE TABLE ayarlar (
            anahtar TEXT PRIMARY KEY,
            deger TEXT NOT NULL
          )
        ''');
        await db.execute('''
          CREATE TABLE favoriler (
            icerik_id INTEGER PRIMARY KEY,
            FOREIGN KEY (icerik_id) REFERENCES icerikler(id) ON DELETE CASCADE
          )
        ''');
        await db.execute('''
          CREATE TABLE sinavlar (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            ders_id INTEGER NOT NULL,
            konu_id INTEGER,
            ad TEXT NOT NULL,
            olusturma_tarihi TEXT NOT NULL,
            FOREIGN KEY (ders_id) REFERENCES dersler(id) ON DELETE CASCADE,
            FOREIGN KEY (konu_id) REFERENCES konular(id) ON DELETE SET NULL
          )
        ''');
        await db.execute('''
          CREATE TABLE sorular (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            sinav_id INTEGER NOT NULL,
            soru TEXT NOT NULL,
            tur TEXT NOT NULL DEFAULT 'text',
            secenekler TEXT,
            dogru_secenek INTEGER,
            ses_yolu TEXT,
            sira INTEGER NOT NULL,
            FOREIGN KEY (sinav_id) REFERENCES sinavlar(id) ON DELETE CASCADE
          )
        ''');
        await db.execute('''
          CREATE TABLE soru_bankasi (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            soru TEXT NOT NULL,
            tur TEXT NOT NULL,
            secenekler TEXT,
            dogru_secenek INTEGER,
            gorsel_yolu TEXT,
            ses_yolu TEXT,
            etiketler TEXT,
            olusturma_tarihi TEXT NOT NULL
          )
        ''');
        await db.execute('''
          CREATE TABLE notlar (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            ders_id INTEGER NOT NULL,
            konu_id INTEGER,
            metin TEXT NOT NULL,
            olusturma_tarihi TEXT NOT NULL,
            FOREIGN KEY (ders_id) REFERENCES dersler(id) ON DELETE CASCADE,
            FOREIGN KEY (konu_id) REFERENCES konular(id) ON DELETE SET NULL
          )
        ''');
        await db.execute('''
          CREATE TABLE ogrenci_siniflar (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            ad TEXT NOT NULL,
            yil TEXT NOT NULL
          )
        ''');
        await db.execute('''
          CREATE TABLE ogrenciler (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            sinif_id INTEGER NOT NULL,
            numara INTEGER NOT NULL,
            ad_soyad TEXT NOT NULL,
            FOREIGN KEY (sinif_id) REFERENCES ogrenci_siniflar(id) ON DELETE CASCADE
          )
        ''');
        await db.execute('''
          CREATE TABLE not_kolonlari (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            sinif_id INTEGER NOT NULL,
            ad TEXT NOT NULL,
            tur TEXT NOT NULL,
            FOREIGN KEY (sinif_id) REFERENCES ogrenci_siniflar(id) ON DELETE CASCADE
          )
        ''');
        await db.execute('''
          CREATE TABLE ogrenci_notlari (
            ogrenci_id INTEGER NOT NULL,
            kolon_id INTEGER NOT NULL,
            not_deger INTEGER,
            yapildi INTEGER,
            PRIMARY KEY (ogrenci_id, kolon_id),
            FOREIGN KEY (ogrenci_id) REFERENCES ogrenciler(id) ON DELETE CASCADE,
            FOREIGN KEY (kolon_id) REFERENCES not_kolonlari(id) ON DELETE CASCADE
          )
        ''');
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 2) {
          await db.execute(
            'ALTER TABLE icerikler ADD COLUMN konu_id INTEGER',
          );
          await db.execute('''
            CREATE TABLE konular (
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              ders_id INTEGER NOT NULL,
              ad TEXT NOT NULL,
              sira INTEGER NOT NULL,
              olusturma_tarihi TEXT NOT NULL,
              FOREIGN KEY (ders_id) REFERENCES dersler(id) ON DELETE CASCADE
            )
          ''');
        }
        if (oldVersion < 3) {
          await db.execute('''
            CREATE TABLE sinavlar (
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              ders_id INTEGER NOT NULL,
              konu_id INTEGER,
              ad TEXT NOT NULL,
              olusturma_tarihi TEXT NOT NULL,
              FOREIGN KEY (ders_id) REFERENCES dersler(id) ON DELETE CASCADE,
              FOREIGN KEY (konu_id) REFERENCES konular(id) ON DELETE SET NULL
            )
          ''');
          await db.execute('''
            CREATE TABLE sorular (
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              sinav_id INTEGER NOT NULL,
              soru TEXT NOT NULL,
              tur TEXT NOT NULL DEFAULT 'text',
              secenekler TEXT,
              dogru_secenek INTEGER,
              ses_yolu TEXT,
              sira INTEGER NOT NULL,
              FOREIGN KEY (sinav_id) REFERENCES sinavlar(id) ON DELETE CASCADE
            )
          ''');
        }
        if (oldVersion < 4) {
          await db.execute(
            "ALTER TABLE sorular ADD COLUMN tur TEXT NOT NULL DEFAULT 'text'",
          );
          await db.execute(
            'ALTER TABLE sorular ADD COLUMN secenekler TEXT',
          );
        }
        if (oldVersion < 5) {
          await db.execute(
            'ALTER TABLE sorular ADD COLUMN dogru_secenek INTEGER',
          );
        }
        if (oldVersion < 6) {
          await db.execute(
            'ALTER TABLE etiketler ADD COLUMN renk INTEGER',
          );
          await db.execute('''
            CREATE TABLE favoriler (
              icerik_id INTEGER PRIMARY KEY,
              FOREIGN KEY (icerik_id) REFERENCES icerikler(id) ON DELETE CASCADE
            )
          ''');
          await db.execute('''
            CREATE TABLE soru_bankasi (
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              soru TEXT NOT NULL,
              tur TEXT NOT NULL,
              secenekler TEXT,
              dogru_secenek INTEGER,
              olusturma_tarihi TEXT NOT NULL
            )
          ''');
        }
        if (oldVersion < 7) {
          await db.execute(
            'ALTER TABLE sorular ADD COLUMN ses_yolu TEXT',
          );
          await db.execute(
            'ALTER TABLE soru_bankasi ADD COLUMN gorsel_yolu TEXT',
          );
          await db.execute(
            'ALTER TABLE soru_bankasi ADD COLUMN ses_yolu TEXT',
          );
          await db.execute(
            'ALTER TABLE soru_bankasi ADD COLUMN etiketler TEXT',
          );
          await db.execute(
            "ALTER TABLE icerikler ADD COLUMN arsiv INTEGER NOT NULL DEFAULT 0",
          );
          await db.execute('''
            CREATE TABLE notlar (
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              ders_id INTEGER NOT NULL,
              konu_id INTEGER,
              metin TEXT NOT NULL,
              olusturma_tarihi TEXT NOT NULL,
              FOREIGN KEY (ders_id) REFERENCES dersler(id) ON DELETE CASCADE,
              FOREIGN KEY (konu_id) REFERENCES konular(id) ON DELETE SET NULL
            )
          ''');
        }
        if (oldVersion < 8) {
          await db.execute('''
            CREATE TABLE ogrenci_siniflar (
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              ad TEXT NOT NULL,
              yil TEXT NOT NULL
            )
          ''');
          await db.execute('''
            CREATE TABLE ogrenciler (
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              sinif_id INTEGER NOT NULL,
              numara INTEGER NOT NULL,
              ad_soyad TEXT NOT NULL,
              FOREIGN KEY (sinif_id) REFERENCES ogrenci_siniflar(id) ON DELETE CASCADE
            )
          ''');
          await db.execute('''
            CREATE TABLE not_kolonlari (
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              sinif_id INTEGER NOT NULL,
              ad TEXT NOT NULL,
              tur TEXT NOT NULL,
              FOREIGN KEY (sinif_id) REFERENCES ogrenci_siniflar(id) ON DELETE CASCADE
            )
          ''');
          await db.execute('''
            CREATE TABLE ogrenci_notlari (
              ogrenci_id INTEGER NOT NULL,
              kolon_id INTEGER NOT NULL,
              not_deger INTEGER,
              yapildi INTEGER,
              PRIMARY KEY (ogrenci_id, kolon_id),
              FOREIGN KEY (ogrenci_id) REFERENCES ogrenciler(id) ON DELETE CASCADE,
              FOREIGN KEY (kolon_id) REFERENCES not_kolonlari(id) ON DELETE CASCADE
            )
          ''');
        }
      },
    );
  }

  Database get _database {
    if (_db == null) {
      throw StateError('Database is not open.');
    }
    return _db!;
  }

  Future<List<ClassModel>> getClasses() async {
    final rows = await _database.query('siniflar', orderBy: 'id DESC');
    return rows.map(ClassModel.fromMap).toList();
  }

  Future<Map<String, Object?>?> getClassById(int id) async {
    final rows = await _database.query(
      'siniflar',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    if (rows.isEmpty) {
      return null;
    }
    return rows.first;
  }

  Future<int> insertClass(String name) async {
    return _database.insert('siniflar', {
      'ad': name,
      'olusturma_tarihi': DateTime.now().toIso8601String(),
    });
  }

  Future<void> updateClass(int id, String name) async {
    await _database.update(
      'siniflar',
      {'ad': name},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> deleteClass(int id) async {
    await _database.delete('siniflar', where: 'id = ?', whereArgs: [id]);
  }

  Future<List<LessonModel>> getLessons(int classId) async {
    final rows = await _database.query(
      'dersler',
      where: 'sinif_id = ?',
      whereArgs: [classId],
      orderBy: 'sira ASC',
    );
    return rows.map(LessonModel.fromMap).toList();
  }

  Future<Map<String, Object?>?> getLessonById(int id) async {
    final rows = await _database.query(
      'dersler',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    if (rows.isEmpty) {
      return null;
    }
    return rows.first;
  }

  Future<int> insertLesson(int classId, String name, int order) async {
    return _database.insert('dersler', {
      'sinif_id': classId,
      'ad': name,
      'sira': order,
      'olusturma_tarihi': DateTime.now().toIso8601String(),
    });
  }

  Future<void> updateLesson(int id, String name) async {
    await _database.update(
      'dersler',
      {'ad': name},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> deleteLesson(int id) async {
    await _database.delete('dersler', where: 'id = ?', whereArgs: [id]);
  }

  Future<List<ContentItem>> getContents(int lessonId) async {
    final rows = await _database.query(
      'icerikler',
      where: 'ders_id = ?',
      whereArgs: [lessonId],
      orderBy: 'sira ASC',
    );
    return rows.map(ContentItem.fromMap).toList();
  }

  Future<Map<String, Object?>?> getContentById(int id) async {
    final rows = await _database.query(
      'icerikler',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    if (rows.isEmpty) {
      return null;
    }
    return rows.first;
  }

  Future<List<ContentItem>> getContentsByTopic(int topicId) async {
    final rows = await _database.query(
      'icerikler',
      where: 'konu_id = ?',
      whereArgs: [topicId],
      orderBy: 'sira ASC',
    );
    return rows.map(ContentItem.fromMap).toList();
  }

  Future<int> insertContent({
    required int lessonId,
    int? topicId,
    required String name,
    required String type,
    required String path,
    required int order,
  }) async {
    return _database.insert('icerikler', {
      'ders_id': lessonId,
      'konu_id': topicId,
      'ad': name,
      'tur': type,
      'dosya_yolu': path,
      'sira': order,
      'olusturma_tarihi': DateTime.now().toIso8601String(),
    });
  }

  Future<void> updateContentOrder(int contentId, int order) async {
    await _database.update(
      'icerikler',
      {'sira': order},
      where: 'id = ?',
      whereArgs: [contentId],
    );
  }

  Future<void> updateContentPath(int contentId, String newPath) async {
    await _database.update(
      'icerikler',
      {'dosya_yolu': newPath},
      where: 'id = ?',
      whereArgs: [contentId],
    );
  }

  Future<void> updateContentTopic(int contentId, int? topicId, String newPath) async {
    await _database.update(
      'icerikler',
      {'konu_id': topicId, 'dosya_yolu': newPath},
      where: 'id = ?',
      whereArgs: [contentId],
    );
  }

  Future<void> deleteContent(int id) async {
    await _database.delete('icerikler', where: 'id = ?', whereArgs: [id]);
  }

  Future<List<TagModel>> getTags() async {
    final rows = await _database.query('etiketler', orderBy: 'ad ASC');
    return rows.map(TagModel.fromMap).toList();
  }

  Future<int> insertTag(String name) async {
    return _database.insert('etiketler', {'ad': name});
  }

  Future<void> updateTag(int id, String name) async {
    await _database.update(
      'etiketler',
      {'ad': name},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> deleteTag(int id) async {
    await _database.delete('etiketler', where: 'id = ?', whereArgs: [id]);
  }

  Future<void> updateTagColor(int id, int color) async {
    await _database.update(
      'etiketler',
      {'renk': color},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<List<int>> getFavoriteContentIds() async {
    final rows = await _database.query('favoriler');
    return rows.map((e) => e['icerik_id'] as int).toList();
  }

  Future<void> setFavorite(int contentId, bool isFavorite) async {
    if (isFavorite) {
      await _database.insert(
        'favoriler',
        {'icerik_id': contentId},
        conflictAlgorithm: ConflictAlgorithm.ignore,
      );
    } else {
      await _database.delete(
        'favoriler',
        where: 'icerik_id = ?',
        whereArgs: [contentId],
      );
    }
  }

  Future<int> insertBankQuestion({
    required String question,
    required String type,
    String? optionsJson,
    int? correctOption,
    String? imagePath,
    String? audioPath,
    String? tagIdsJson,
  }) async {
    return _database.insert('soru_bankasi', {
      'soru': question,
      'tur': type,
      'secenekler': optionsJson,
      'dogru_secenek': correctOption,
      'gorsel_yolu': imagePath,
      'ses_yolu': audioPath,
      'etiketler': tagIdsJson,
      'olusturma_tarihi': DateTime.now().toIso8601String(),
    });
  }

  Future<List<Map<String, Object?>>> getBankQuestions() async {
    return _database.query('soru_bankasi', orderBy: 'id DESC');
  }

  Future<List<Map<String, Object?>>> searchContents(String query) async {
    return _database.rawQuery('''
      SELECT i.*, d.ad as ders_ad, s.ad as sinif_ad
      FROM icerikler i
      JOIN dersler d ON d.id = i.ders_id
      JOIN siniflar s ON s.id = d.sinif_id
      WHERE i.ad LIKE ?
      ORDER BY i.id DESC
    ''', ['%$query%']);
  }

  Future<void> setContentArchived(int contentId, bool archived) async {
    await _database.update(
      'icerikler',
      {'arsiv': archived ? 1 : 0},
      where: 'id = ?',
      whereArgs: [contentId],
    );
  }

  Future<Map<String, Object?>?> getNote(int lessonId, int? topicId) async {
    final rows = await _database.query(
      'notlar',
      where: 'ders_id = ? AND konu_id ${topicId == null ? 'IS NULL' : '= ?'}',
      whereArgs: topicId == null ? [lessonId] : [lessonId, topicId],
      limit: 1,
    );
    if (rows.isEmpty) {
      return null;
    }
    return rows.first;
  }

  Future<void> upsertNote({
    required int lessonId,
    int? topicId,
    required String text,
  }) async {
    final existing = await getNote(lessonId, topicId);
    if (existing == null) {
      await _database.insert('notlar', {
        'ders_id': lessonId,
        'konu_id': topicId,
        'metin': text,
        'olusturma_tarihi': DateTime.now().toIso8601String(),
      });
    } else {
      await _database.update(
        'notlar',
        {'metin': text},
        where: 'id = ?',
        whereArgs: [existing['id']],
      );
    }
  }

  Future<void> deleteBankQuestion(int id) async {
    await _database.delete('soru_bankasi', where: 'id = ?', whereArgs: [id]);
  }

  Future<int> insertStudentClass(String name, String year) async {
    return _database.insert('ogrenci_siniflar', {
      'ad': name,
      'yil': year,
    });
  }

  Future<List<Map<String, Object?>>> getStudentClasses() async {
    return _database.query('ogrenci_siniflar', orderBy: 'id DESC');
  }

  Future<void> updateStudentClass(int id, String name, String year) async {
    await _database.update(
      'ogrenci_siniflar',
      {'ad': name, 'yil': year},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> deleteStudentClass(int id) async {
    await _database.delete('ogrenci_siniflar', where: 'id = ?', whereArgs: [id]);
  }

  Future<int> insertStudent({
    required int classId,
    required int number,
    required String name,
  }) async {
    return _database.insert('ogrenciler', {
      'sinif_id': classId,
      'numara': number,
      'ad_soyad': name,
    });
  }

  Future<void> updateStudent({
    required int studentId,
    required int number,
    required String name,
  }) async {
    await _database.update(
      'ogrenciler',
      {'numara': number, 'ad_soyad': name},
      where: 'id = ?',
      whereArgs: [studentId],
    );
  }

  Future<void> deleteStudent(int studentId) async {
    await _database.delete('ogrenciler', where: 'id = ?', whereArgs: [studentId]);
  }

  Future<List<Map<String, Object?>>> getStudents(int classId) async {
    return _database.query(
      'ogrenciler',
      where: 'sinif_id = ?',
      whereArgs: [classId],
      orderBy: 'numara ASC',
    );
  }

  Future<int> getNextStudentNumber(int classId) async {
    final rows = await _database.rawQuery(
      'SELECT MAX(numara) as maxNo FROM ogrenciler WHERE sinif_id = ?',
      [classId],
    );
    final maxNo = rows.first['maxNo'] as int?;
    return (maxNo ?? 0) + 1;
  }

  Future<int> insertScoreColumn({
    required int classId,
    required String name,
    required String type,
  }) async {
    return _database.insert('not_kolonlari', {
      'sinif_id': classId,
      'ad': name,
      'tur': type,
    });
  }

  Future<void> updateScoreColumn({
    required int columnId,
    required String name,
    required String type,
  }) async {
    await _database.update(
      'not_kolonlari',
      {'ad': name, 'tur': type},
      where: 'id = ?',
      whereArgs: [columnId],
    );
  }

  Future<void> deleteScoreColumn(int columnId) async {
    await _database.delete('not_kolonlari', where: 'id = ?', whereArgs: [columnId]);
  }

  Future<List<Map<String, Object?>>> getScoreColumns(int classId) async {
    return _database.query(
      'not_kolonlari',
      where: 'sinif_id = ?',
      whereArgs: [classId],
      orderBy: 'id ASC',
    );
  }

  Future<void> setStudentScore({
    required int studentId,
    required int columnId,
    int? score,
    int? done,
  }) async {
    await _database.insert(
      'ogrenci_notlari',
      {
        'ogrenci_id': studentId,
        'kolon_id': columnId,
        'not_deger': score,
        'yapildi': done,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> clearStudentScoresForClass(int classId) async {
    await _database.rawDelete('''
      DELETE FROM ogrenci_notlari
      WHERE kolon_id IN (
        SELECT id FROM not_kolonlari WHERE sinif_id = ?
      )
    ''', [classId]);
  }

  Future<void> clearStudentScoresForColumn(int columnId) async {
    await _database.delete(
      'ogrenci_notlari',
      where: 'kolon_id = ?',
      whereArgs: [columnId],
    );
  }

  Future<void> clearStudentScoresForStudent(int studentId) async {
    await _database.delete(
      'ogrenci_notlari',
      where: 'ogrenci_id = ?',
      whereArgs: [studentId],
    );
  }

  Future<void> clearStudentScoresForType({
    required int classId,
    required String type,
  }) async {
    await _database.rawDelete('''
      DELETE FROM ogrenci_notlari
      WHERE kolon_id IN (
        SELECT id FROM not_kolonlari WHERE sinif_id = ? AND tur = ?
      )
    ''', [classId, type]);
  }

  Future<List<Map<String, Object?>>> getStudentScores(int classId) async {
    return _database.rawQuery('''
      SELECT o.id as ogrenci_id, k.id as kolon_id, n.not_deger, n.yapildi
      FROM ogrenciler o
      JOIN not_kolonlari k ON k.sinif_id = o.sinif_id
      LEFT JOIN ogrenci_notlari n
        ON n.ogrenci_id = o.id AND n.kolon_id = k.id
      WHERE o.sinif_id = ?
    ''', [classId]);
  }

  Future<void> setContentTags(int contentId, List<int> tagIds) async {
    final db = _database;
    await db.delete(
      'icerik_etiketleri',
      where: 'icerik_id = ?',
      whereArgs: [contentId],
    );
    for (final tagId in tagIds) {
      await db.insert('icerik_etiketleri', {
        'icerik_id': contentId,
        'etiket_id': tagId,
      });
    }
  }

  Future<List<ContentWithTags>> getContentsWithTags(int lessonId) async {
    final contents = await getContents(lessonId);
    return _mapContentsWithTags(contents);
  }

  Future<List<ContentWithTags>> getContentsWithTagsByTopic(
    int topicId,
  ) async {
    final contents = await getContentsByTopic(topicId);
    return _mapContentsWithTags(contents);
  }

  Future<List<ContentWithTags>> _mapContentsWithTags(
    List<ContentItem> contents,
  ) async {
    if (contents.isEmpty) {
      return [];
    }
    final ids = contents.map((e) => e.id).toList();
    final rows = await _database.rawQuery('''
      SELECT ie.icerik_id, e.id, e.ad
      FROM icerik_etiketleri ie
      JOIN etiketler e ON e.id = ie.etiket_id
      WHERE ie.icerik_id IN (${List.filled(ids.length, '?').join(',')})
    ''', ids);
    final tagsByContent = <int, List<TagModel>>{};
    for (final row in rows) {
      final contentId = row['icerik_id'] as int;
      tagsByContent.putIfAbsent(contentId, () => []);
      tagsByContent[contentId]!.add(TagModel.fromMap(row));
    }
    return contents
        .map((content) => ContentWithTags(
              content: content,
              tags: tagsByContent[content.id] ?? [],
            ))
        .toList();
  }

  Future<String?> getSetting(String key) async {
    final rows = await _database.query(
      'ayarlar',
      where: 'anahtar = ?',
      whereArgs: [key],
      limit: 1,
    );
    if (rows.isEmpty) {
      return null;
    }
    return rows.first['deger'] as String;
  }

  Future<void> setSetting(String key, String value) async {
    await _database.insert(
      'ayarlar',
      {'anahtar': key, 'deger': value},
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<int> getNextLessonOrder(int classId) async {
    final rows = await _database.rawQuery(
      'SELECT MAX(sira) as maxOrder FROM dersler WHERE sinif_id = ?',
      [classId],
    );
    final maxOrder = rows.first['maxOrder'] as int?;
    return (maxOrder ?? 0) + 1;
  }

  Future<int> getNextContentOrder(int lessonId) async {
    final rows = await _database.rawQuery(
      'SELECT MAX(sira) as maxOrder FROM icerikler WHERE ders_id = ?',
      [lessonId],
    );
    final maxOrder = rows.first['maxOrder'] as int?;
    return (maxOrder ?? 0) + 1;
  }

  Future<int> getNextTopicOrder(int lessonId) async {
    final rows = await _database.rawQuery(
      'SELECT MAX(sira) as maxOrder FROM konular WHERE ders_id = ?',
      [lessonId],
    );
    final maxOrder = rows.first['maxOrder'] as int?;
    return (maxOrder ?? 0) + 1;
  }

  Future<List<Map<String, Object?>>> getTopicsRaw(int lessonId) async {
    return _database.query(
      'konular',
      where: 'ders_id = ?',
      whereArgs: [lessonId],
      orderBy: 'sira ASC',
    );
  }

  Future<Map<String, Object?>?> getTopicById(int id) async {
    final rows = await _database.query(
      'konular',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    if (rows.isEmpty) {
      return null;
    }
    return rows.first;
  }

  Future<int> insertTopic(int lessonId, String name, int order) async {
    return _database.insert('konular', {
      'ders_id': lessonId,
      'ad': name,
      'sira': order,
      'olusturma_tarihi': DateTime.now().toIso8601String(),
    });
  }

  Future<void> updateTopic(int id, String name) async {
    await _database.update(
      'konular',
      {'ad': name},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> updateTopicOrder(int id, int order) async {
    await _database.update(
      'konular',
      {'sira': order},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> deleteTopic(int id) async {
    await _database.delete('konular', where: 'id = ?', whereArgs: [id]);
  }

  Future<int> insertExam({
    required int lessonId,
    int? topicId,
    required String name,
  }) async {
    return _database.insert('sinavlar', {
      'ders_id': lessonId,
      'konu_id': topicId,
      'ad': name,
      'olusturma_tarihi': DateTime.now().toIso8601String(),
    });
  }

  Future<void> insertExamQuestion({
    required int examId,
    required String question,
    required String type,
    String? optionsJson,
    int? correctOption,
    String? audioPath,
    required int order,
  }) async {
    await _database.insert('sorular', {
      'sinav_id': examId,
      'soru': question,
      'tur': type,
      'secenekler': optionsJson,
      'dogru_secenek': correctOption,
      'ses_yolu': audioPath,
      'sira': order,
    });
  }

  Future<List<Map<String, Object?>>> getExamQuestions(int examId) async {
    return _database.query(
      'sorular',
      where: 'sinav_id = ?',
      whereArgs: [examId],
      orderBy: 'sira ASC',
    );
  }

  Future<void> deleteExam(int examId) async {
    await _database.delete('sinavlar', where: 'id = ?', whereArgs: [examId]);
  }

  Future<void> close() async {
    await _db?.close();
  }

  static String buildDatabasePath(String rootDir) {
    return p.join(rootDir, 'myeduapp.sqlite');
  }
}

