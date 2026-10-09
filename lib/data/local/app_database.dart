import 'dart:async';

import 'package:path/path.dart' as p;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import '../models/class_model.dart';
import '../models/content_item.dart';
import '../models/content_with_tags.dart';
import '../models/lesson_model.dart';
import '../models/student_behavior_definition.dart';
import '../models/student_category_model.dart';
import '../models/tag_model.dart';
import '../models/class_notebook_note.dart';
import '../models/content_reading_progress.dart';
import '../models/document_folder_model.dart';
import '../models/teacher_recent_activity.dart';
import '../models/unit_model.dart';
import '../../utils/course_form_options.dart';
import '../../utils/student_password_hash.dart';

class AppDatabase {
  AppDatabase(this.dbPath);

  final String dbPath;
  Database? _db;

  Future<void> open() async {
    _db = await openDatabase(
      dbPath,
      version: 35,
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
            akademik_yil TEXT NOT NULL DEFAULT '',
            resim_yolu TEXT,
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
          CREATE TABLE uniteler (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            ders_id INTEGER NOT NULL,
            ad TEXT NOT NULL,
            numara INTEGER NOT NULL DEFAULT 1,
            sira INTEGER NOT NULL,
            resim_yolu TEXT,
            olusturma_tarihi TEXT NOT NULL,
            FOREIGN KEY (ders_id) REFERENCES dersler(id) ON DELETE CASCADE
          )
        ''');
        await db.execute('''
          CREATE TABLE konular (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            ders_id INTEGER NOT NULL,
            unite_id INTEGER,
            ad TEXT NOT NULL,
            sira INTEGER NOT NULL,
            resim_yolu TEXT,
            olusturma_tarihi TEXT NOT NULL,
            FOREIGN KEY (ders_id) REFERENCES dersler(id) ON DELETE CASCADE,
            FOREIGN KEY (unite_id) REFERENCES uniteler(id) ON DELETE SET NULL
          )
        ''');
        await db.execute('''
          CREATE TABLE ders_gorselleri (
            ad TEXT PRIMARY KEY,
            resim_yolu TEXT
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
            yil TEXT NOT NULL,
            sube TEXT
          )
        ''');
        await db.execute('''
          CREATE TABLE ogrenciler (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            sinif_id INTEGER NOT NULL,
            numara INTEGER NOT NULL,
            ad_soyad TEXT NOT NULL,
            email TEXT,
            anne_email TEXT,
            baba_email TEXT,
            sifre_hash TEXT,
            FOREIGN KEY (sinif_id) REFERENCES ogrenci_siniflar(id) ON DELETE CASCADE
          )
        ''');
        await db.execute('''
          CREATE TABLE not_kolonlari (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            sinif_id INTEGER NOT NULL,
            ad TEXT NOT NULL,
            tur TEXT NOT NULL,
            aciklama TEXT,
            FOREIGN KEY (sinif_id) REFERENCES ogrenci_siniflar(id) ON DELETE CASCADE
          )
        ''');
        await db.execute('''
          CREATE TABLE ogrenci_kategoriler (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            sinif_id INTEGER NOT NULL,
            ad TEXT NOT NULL,
            kod TEXT NOT NULL,
            sira INTEGER NOT NULL,
            aktif INTEGER NOT NULL DEFAULT 1,
            sistem INTEGER NOT NULL DEFAULT 0,
            FOREIGN KEY (sinif_id) REFERENCES ogrenci_siniflar(id) ON DELETE CASCADE
          )
        ''');
        await db.execute('''
          CREATE TABLE ogrenci_notlari (
            ogrenci_id INTEGER NOT NULL,
            kolon_id INTEGER NOT NULL,
            tarih TEXT NOT NULL,
            not_deger INTEGER,
            yapildi INTEGER,
            devamsiz INTEGER NOT NULL DEFAULT 0,
            aciklama TEXT,
            PRIMARY KEY (ogrenci_id, kolon_id, tarih),
            FOREIGN KEY (ogrenci_id) REFERENCES ogrenciler(id) ON DELETE CASCADE,
            FOREIGN KEY (kolon_id) REFERENCES not_kolonlari(id) ON DELETE CASCADE
          )
        ''');
        await _createDocumentFolderTables(db);
        await _createV17Tables(db);
        await _createV18Tables(db);
        await _createMentorshipTables(db);
        await _createAcademicPlansTablesV21(db);
        await _ensureWeeklySchedulePeriodColumn(db);
        await _migrateWeeklySchedulePeriodSlotsV23(db);
        await _createBehaviorTablesV24(db);
        await _migrateStudentPortalV26(db);
        await _migrateStudentLoginV27(db);
        await _migrateParentsV28(db);
        await _migrateAttendanceV29(db);
        await _migrateAnnouncementsV30(db);
        await _migrateSecretaryDocumentsV31(db);
        await _migrateParentPortalV32(db);
        await _migrateNotificationsV33(db);
        await _migrateAccountsV34(db);
        await _migrateAnnouncementCoverV35(db);
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 2) {
          await db.execute('ALTER TABLE icerikler ADD COLUMN konu_id INTEGER');
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
          await db.execute('ALTER TABLE sorular ADD COLUMN secenekler TEXT');
        }
        if (oldVersion < 5) {
          await db.execute(
            'ALTER TABLE sorular ADD COLUMN dogru_secenek INTEGER',
          );
        }
        if (oldVersion < 6) {
          await db.execute('ALTER TABLE etiketler ADD COLUMN renk INTEGER');
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
          await db.execute('ALTER TABLE sorular ADD COLUMN ses_yolu TEXT');
          await db.execute(
            'ALTER TABLE soru_bankasi ADD COLUMN gorsel_yolu TEXT',
          );
          await db.execute('ALTER TABLE soru_bankasi ADD COLUMN ses_yolu TEXT');
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
        if (oldVersion < 9) {
          await db.execute(
            "ALTER TABLE dersler ADD COLUMN akademik_yil TEXT NOT NULL DEFAULT ''",
          );
          await db.execute('ALTER TABLE dersler ADD COLUMN resim_yolu TEXT');
          await db.execute('''
            CREATE TABLE IF NOT EXISTS uniteler (
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              ders_id INTEGER NOT NULL,
              ad TEXT NOT NULL,
              numara INTEGER NOT NULL DEFAULT 1,
              sira INTEGER NOT NULL,
              resim_yolu TEXT,
              olusturma_tarihi TEXT NOT NULL,
              FOREIGN KEY (ders_id) REFERENCES dersler(id) ON DELETE CASCADE
            )
          ''');
          await db.execute('ALTER TABLE konular ADD COLUMN unite_id INTEGER');
          final lessons = await db.query('dersler');
          final now = DateTime.now().toIso8601String();
          for (final lesson in lessons) {
            final unitId = await db.insert('uniteler', {
              'ders_id': lesson['id'],
              'ad': 'Ünite 1',
              'numara': 1,
              'sira': 1,
              'olusturma_tarihi': now,
            });
            await db.update(
              'konular',
              {'unite_id': unitId},
              where: 'ders_id = ?',
              whereArgs: [lesson['id']],
            );
          }
          await db.execute('''
            CREATE TABLE IF NOT EXISTS ogrenci_kategoriler (
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              sinif_id INTEGER NOT NULL,
              ad TEXT NOT NULL,
              kod TEXT NOT NULL,
              sira INTEGER NOT NULL,
              aktif INTEGER NOT NULL DEFAULT 1,
              sistem INTEGER NOT NULL DEFAULT 0,
              FOREIGN KEY (sinif_id) REFERENCES ogrenci_siniflar(id) ON DELETE CASCADE
            )
          ''');
          await db.execute('''
            CREATE TABLE ogrenci_notlari_v9 (
              ogrenci_id INTEGER NOT NULL,
              kolon_id INTEGER NOT NULL,
              tarih TEXT NOT NULL,
              not_deger INTEGER,
              yapildi INTEGER,
              aciklama TEXT,
              PRIMARY KEY (ogrenci_id, kolon_id, tarih),
              FOREIGN KEY (ogrenci_id) REFERENCES ogrenciler(id) ON DELETE CASCADE,
              FOREIGN KEY (kolon_id) REFERENCES not_kolonlari(id) ON DELETE CASCADE
            )
          ''');
          await db.execute(
            '''
            INSERT INTO ogrenci_notlari_v9
              (ogrenci_id, kolon_id, tarih, not_deger, yapildi, aciklama)
            SELECT ogrenci_id, kolon_id, ?, not_deger, yapildi, NULL
            FROM ogrenci_notlari
            ''',
            [scoreDateKey(DateTime.now())],
          );
          await db.execute('DROP TABLE ogrenci_notlari');
          await db.execute(
            'ALTER TABLE ogrenci_notlari_v9 RENAME TO ogrenci_notlari',
          );
          final studentClasses = await db.query('ogrenci_siniflar');
          for (final row in studentClasses) {
            await seedDefaultCategories(db, row['id'] as int);
          }
        }
        if (oldVersion < 10) {
          await db.execute('ALTER TABLE not_kolonlari ADD COLUMN aciklama TEXT');
        }
        if (oldVersion < 11) {
          await db.execute('ALTER TABLE ogrenci_siniflar ADD COLUMN sube TEXT');
        }
        if (oldVersion < 12) {
          await _migrateStudentCategoriesV12(db);
        }
        if (oldVersion < 13) {
          await db.execute('''
            CREATE TABLE IF NOT EXISTS ders_gorselleri (
              ad TEXT PRIMARY KEY,
              resim_yolu TEXT
            )
          ''');
          await db.execute('ALTER TABLE konular ADD COLUMN resim_yolu TEXT');
          final rows = await db.rawQuery('''
            SELECT ad, resim_yolu
            FROM dersler
            WHERE resim_yolu IS NOT NULL AND resim_yolu != ''
            GROUP BY ad
          ''');
          for (final row in rows) {
            await db.insert(
              'ders_gorselleri',
              {
                'ad': row['ad'],
                'resim_yolu': row['resim_yolu'],
              },
              conflictAlgorithm: ConflictAlgorithm.ignore,
            );
          }
        }
        if (oldVersion < 14) {
          await _createMentorshipTables(db);
        }
        if (oldVersion < 15) {
          await _migrateStudentCategoriesV15(db);
        }
        if (oldVersion < 16) {
          await _createDocumentFolderTables(db);
        }
        if (oldVersion < 17) {
          await _createV17Tables(db);
        }
        if (oldVersion < 18) {
          await _createV18Tables(db);
        }
        if (oldVersion < 19) {
          await _migrateScoreDescriptionsV19(db);
        }
        if (oldVersion < 20) {
          await _migrateStudentEmailsV20(db);
        }
        if (oldVersion < 21) {
          await _createAcademicPlansTablesV21(db);
        }
        if (oldVersion < 23) {
          await _ensureWeeklySchedulePeriodColumn(db);
          await _backfillWeeklySchedulePeriodNumbers(db);
          await _migrateWeeklySchedulePeriodSlotsV23(db);
        }
        if (oldVersion < 24) {
          await _migrateStudentPlatformV24(db);
        }
        if (oldVersion < 25) {
          await _migrateStudentPortalV25(db);
        }
        if (oldVersion < 26) {
          await _migrateStudentPortalV26(db);
        }
        if (oldVersion < 27) {
          await _migrateStudentLoginV27(db);
        }
        if (oldVersion < 28) {
          await _migrateParentsV28(db);
        }
        if (oldVersion < 29) {
          await _migrateAttendanceV29(db);
        }
        if (oldVersion < 30) {
          await _migrateAnnouncementsV30(db);
        }
        if (oldVersion < 31) {
          await _migrateSecretaryDocumentsV31(db);
        }
        if (oldVersion < 32) {
          await _migrateParentPortalV32(db);
        }
        if (oldVersion < 33) {
          await _migrateNotificationsV33(db);
        }
        if (oldVersion < 34) {
          await _migrateAccountsV34(db);
        }
        if (oldVersion < 35) {
          await _migrateAnnouncementCoverV35(db);
        }
      },
    );
    await ensurePlatformDefaults();
  }

  Database get _database {
    if (_db == null) {
      throw StateError('Database is not open.');
    }
    return _db!;
  }

  /// JSON senkronizasyon servisi için açık database erişimi.
  Database get database => _database;

  static String scoreDateKey(DateTime date) {
    final y = date.year.toString().padLeft(4, '0');
    final m = date.month.toString().padLeft(2, '0');
    final d = date.day.toString().padLeft(2, '0');
    return '$y-$m-$d';
  }

  static Future<void> seedDefaultCategories(Database db, int classId) async {
    final existing = await db.query(
      'ogrenci_kategoriler',
      where: 'sinif_id = ?',
      whereArgs: [classId],
      limit: 1,
    );
    if (existing.isNotEmpty) {
      return;
    }
    for (final item in StudentCategory.defaultSystemCategories) {
      await db.insert('ogrenci_kategoriler', {
        'sinif_id': classId,
        'ad': item['ad'],
        'kod': item['kod'],
        'sira': item['sira'],
        'aktif': 1,
        'sistem': 1,
      });
    }
  }

  static Future<void> _migrateStudentCategoriesV12(Database db) async {
    final classes = await db.query('ogrenci_siniflar');
    for (final cls in classes) {
      final classId = cls['id'] as int;
      for (final item in StudentCategory.defaultSystemCategories) {
        final code = item['kod'] as String;
        final existing = await db.query(
          'ogrenci_kategoriler',
          where: 'sinif_id = ? AND kod = ?',
          whereArgs: [classId, code],
          limit: 1,
        );
        if (existing.isEmpty) {
          await db.insert('ogrenci_kategoriler', {
            'sinif_id': classId,
            'ad': item['ad'],
            'kod': code,
            'sira': item['sira'],
            'aktif': 1,
            'sistem': 1,
          });
        } else {
          await db.update(
            'ogrenci_kategoriler',
            {
              'ad': item['ad'],
              'sira': item['sira'],
              'sistem': 1,
            },
            where: 'id = ?',
            whereArgs: [existing.first['id']],
          );
        }
      }
      final customs = await db.query(
        'ogrenci_kategoriler',
        where: 'sinif_id = ? AND sistem = 0',
        whereArgs: [classId],
        orderBy: 'sira ASC, id ASC',
      );
      var order = StudentCategory.defaultSystemCategories.length + 1;
      for (final row in customs) {
        await db.update(
          'ogrenci_kategoriler',
          {'sira': order},
          where: 'id = ?',
          whereArgs: [row['id']],
        );
        order += 1;
      }
    }
  }

  static Future<void> _migrateStudentCategoriesV15(Database db) async {
    final classes = await db.query('ogrenci_siniflar');
    for (final cls in classes) {
      await ensurePerformanceCategoryForClass(db, cls['id'] as int);
    }
  }

  /// Performans menüsünü garanti eder; materials/activity verilerini korur.
  static Future<void> ensurePerformanceCategoryForClass(
    Database db,
    int classId,
  ) async {
    await seedDefaultCategories(db, classId);

    final performance = await db.query(
      'ogrenci_kategoriler',
      where: 'sinif_id = ? AND kod = ?',
      whereArgs: [classId, StudentCategory.performanceCode],
      limit: 1,
    );
    if (performance.isEmpty) {
      await db.insert('ogrenci_kategoriler', {
        'sinif_id': classId,
        'ad': 'Performans',
        'kod': StudentCategory.performanceCode,
        'sira': 2,
        'aktif': 1,
        'sistem': 1,
      });
    } else {
      await db.update(
        'ogrenci_kategoriler',
        {
          'ad': 'Performans',
          'sira': 2,
          'aktif': 1,
          'sistem': 1,
        },
        where: 'id = ?',
        whereArgs: [performance.first['id']],
      );
    }

    await db.update(
      'ogrenci_kategoriler',
      {'aktif': 0},
      where: 'sinif_id = ? AND kod IN (?, ?)',
      whereArgs: [classId, 'materials', 'activity'],
    );

    for (final item in [
      {'kod': 'homework', 'sira': 3, 'ad': 'Ödevler'},
      {'kod': 'exam', 'sira': 4, 'ad': 'Sınavlar'},
    ]) {
      await db.update(
        'ogrenci_kategoriler',
        {'sira': item['sira'], 'ad': item['ad']},
        where: 'sinif_id = ? AND kod = ?',
        whereArgs: [classId, item['kod']],
      );
    }
  }

  static Future<void> ensureStudentCategoriesForClass(
    Database db,
    int classId,
  ) async {
    await ensurePerformanceCategoryForClass(db, classId);
    await ensureBehaviorsCategoryForClass(db, classId);
  }

  static Future<void> ensureBehaviorsCategoryForClass(
    Database db,
    int classId,
  ) async {
    final existing = await db.query(
      'ogrenci_kategoriler',
      where: 'sinif_id = ? AND kod = ?',
      whereArgs: [classId, StudentCategory.behaviorsCode],
      limit: 1,
    );
    if (existing.isEmpty) {
      await db.insert('ogrenci_kategoriler', {
        'sinif_id': classId,
        'ad': 'Davranışlar',
        'kod': StudentCategory.behaviorsCode,
        'sira': 5,
        'aktif': 1,
        'sistem': 1,
      });
    } else {
      await db.update(
        'ogrenci_kategoriler',
        {
          'ad': 'Davranışlar',
          'sira': 5,
          'aktif': 1,
          'sistem': 1,
        },
        where: 'id = ?',
        whereArgs: [existing.first['id']],
      );
    }
  }

  Future<void> ensurePlatformDefaults() async {
    await ensureContentHierarchy();
    final classes = await getStudentClasses();
    for (final row in classes) {
      await ensureStudentCategoriesForClass(_database, row['id'] as int);
    }
  }

  Future<void> ensureContentHierarchy() async {
    final lessons = await _database.query('dersler');
    final now = DateTime.now().toIso8601String();
    for (final lesson in lessons) {
      final lessonId = lesson['id'] as int;
      final units = await _database.query(
        'uniteler',
        where: 'ders_id = ?',
        whereArgs: [lessonId],
        limit: 1,
      );
      int unitId;
      if (units.isEmpty) {
        unitId = await _database.insert('uniteler', {
          'ders_id': lessonId,
          'ad': 'Ünite 1',
          'numara': 1,
          'sira': 1,
          'olusturma_tarihi': now,
        });
      } else {
        unitId = units.first['id'] as int;
      }
      await _database.update(
        'konular',
        {'unite_id': unitId},
        where: 'ders_id = ? AND unite_id IS NULL',
        whereArgs: [lessonId],
      );
    }
  }

  /// Extracts leading number from class name (e.g. "1.SINIF" -> 1, "12.SINIF" -> 12).
  /// Returns 999 for names without a leading number (sorts to end).
  static int _classOrderKey(String name) {
    final match = RegExp(r'^(\d+)').firstMatch(name.trim());
    return match != null ? int.tryParse(match.group(1) ?? '') ?? 999 : 999;
  }

  Future<List<ClassModel>> getClasses() async {
    final rows = await _database.query('siniflar');
    final list = rows.map(ClassModel.fromMap).toList();
    list.sort(
      (a, b) => _classOrderKey(a.name).compareTo(_classOrderKey(b.name)),
    );
    return list;
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

  /// Returns grade number parsed from class name, or null if not found.
  Future<int?> getClassGrade(int classId) async {
    final row = await getClassById(classId);
    if (row == null) {
      return null;
    }
    final key = _classOrderKey(row['ad'] as String);
    return key == 999 ? null : key;
  }

  /// Finds existing class for [grade] or creates one using the standard naming pattern.
  Future<int> getOrCreateClassForGrade(int grade) async {
    final classes = await getClasses();
    for (final cls in classes) {
      if (_classOrderKey(cls.name) == grade) {
        return cls.id;
      }
    }
    return insertClass('$grade.SINIFLAR');
  }

  Future<LessonModel?> findCourseByKeys({
    required String name,
    required int classId,
    required String academicYear,
  }) async {
    final rows = await _database.query(
      'dersler',
      where: 'ad = ? AND sinif_id = ? AND akademik_yil = ?',
      whereArgs: [name, classId, academicYear],
      limit: 1,
    );
    if (rows.isEmpty) {
      return null;
    }
    return LessonModel.fromMap(rows.first);
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

  Future<int> insertLesson(
    int classId,
    String name,
    int order, {
    String academicYear = '',
    String? imagePath,
  }) async {
    final lessonId = await _database.insert('dersler', {
      'sinif_id': classId,
      'ad': name,
      'sira': order,
      'olusturma_tarihi': DateTime.now().toIso8601String(),
      'akademik_yil': academicYear,
      'resim_yolu': imagePath,
    });
    await insertUnit(
      lessonId: lessonId,
      name: 'Ünite 1',
      number: 1,
      order: 1,
    );
    return lessonId;
  }

  Future<void> updateLesson(
    int id,
    String name, {
    String? academicYear,
    String? imagePath,
    bool clearImage = false,
    int? classId,
    String? teacherName,
  }) async {
    final values = <String, Object?>{'ad': name};
    if (teacherName != null) {
      values['ogretmen_adi'] = teacherName.trim().isEmpty ? null : teacherName.trim();
    }
    if (academicYear != null) {
      values['akademik_yil'] = academicYear;
    }
    if (classId != null) {
      values['sinif_id'] = classId;
    }
    if (clearImage) {
      values['resim_yolu'] = null;
    } else if (imagePath != null) {
      values['resim_yolu'] = imagePath;
    }
    await _database.update(
      'dersler',
      values,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> setSubjectImage(String name, String? imagePath) async {
    if (imagePath == null || imagePath.isEmpty) {
      await _database.delete(
        'ders_gorselleri',
        where: 'ad = ?',
        whereArgs: [name],
      );
      return;
    }
    await _database.insert(
      'ders_gorselleri',
      {'ad': name, 'resim_yolu': imagePath},
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<String?> getSubjectImage(String name) async {
    final rows = await _database.query(
      'ders_gorselleri',
      where: 'ad = ?',
      whereArgs: [name],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return rows.first['resim_yolu'] as String?;
  }

  Future<List<SubjectSummary>> getSubjects() async {
    final rows = await _database.rawQuery('''
      SELECT d.ad,
             g.resim_yolu as resim_yolu,
             COUNT(DISTINCT d.id) as kurs_sayisi,
             COUNT(DISTINCT u.id) as unite_sayisi,
             COUNT(DISTINCT k.id) as konu_sayisi
      FROM dersler d
      LEFT JOIN ders_gorselleri g ON g.ad = d.ad
      LEFT JOIN uniteler u ON u.ders_id = d.id
      LEFT JOIN konular k ON k.ders_id = d.id
      GROUP BY d.ad
      ORDER BY d.ad COLLATE NOCASE ASC
    ''');
    return rows
        .map(
          (row) => SubjectSummary(
            name: row['ad'] as String,
            imagePath: row['resim_yolu'] as String?,
            courseCount: (row['kurs_sayisi'] as num?)?.toInt() ?? 0,
            unitCount: (row['unite_sayisi'] as num?)?.toInt() ?? 0,
            topicCount: (row['konu_sayisi'] as num?)?.toInt() ?? 0,
          ),
        )
        .toList();
  }

  Future<List<LessonModel>> getCoursesForSubject(String subjectName) async {
    final rows = await _database.rawQuery(
      '''
      SELECT d.*, s.ad as sinif_ad,
        (SELECT COUNT(*) FROM uniteler u WHERE u.ders_id = d.id) as unite_sayisi,
        (SELECT COUNT(*) FROM konular k WHERE k.ders_id = d.id) as konu_sayisi
      FROM dersler d
      JOIN siniflar s ON s.id = d.sinif_id
      WHERE d.ad = ?
      ORDER BY d.akademik_yil DESC, s.ad ASC
      ''',
      [subjectName],
    );
    return rows.map(LessonModel.fromMap).toList();
  }

  Future<void> renameSubject(String oldName, String newName) async {
    await _database.update(
      'dersler',
      {'ad': newName},
      where: 'ad = ?',
      whereArgs: [oldName],
    );
    final image = await getSubjectImage(oldName);
    if (image != null) {
      await setSubjectImage(newName, image);
      await _database.delete(
        'ders_gorselleri',
        where: 'ad = ?',
        whereArgs: [oldName],
      );
    }
  }

  Future<void> deleteSubjectImage(String name) async {
    await _database.delete(
      'ders_gorselleri',
      where: 'ad = ?',
      whereArgs: [name],
    );
  }

  Future<void> deleteLessonsBySubjectName(String subjectName) async {
    final rows = await _database.query(
      'dersler',
      where: 'ad = ?',
      whereArgs: [subjectName],
    );
    for (final row in rows) {
      await deleteLesson(row['id'] as int);
    }
    await deleteSubjectImage(subjectName);
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

  Future<void> updateContentName(int contentId, String newName) async {
    await _database.update(
      'icerikler',
      {'ad': newName},
      where: 'id = ?',
      whereArgs: [contentId],
    );
  }

  Future<void> updateContentTopic(
    int contentId,
    int? topicId,
    String newPath,
  ) async {
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

  /// Sekreter fiziksel silme yapamaz; kritik belgeler için ek koruma.
  Future<bool> tryDeleteContentForRole({
    required int contentId,
    required String roleName,
  }) async {
    if (roleName == 'secretary') {
      return false;
    }
    final row = await getContentById(contentId);
    if (row == null) return false;
    if ((row['kritik'] as int? ?? 0) == 1 && roleName == 'secretary') {
      return false;
    }
    await deleteContent(contentId);
    return true;
  }

  static const secretaryDocumentsClassSettingKey =
      'secretary_documents_sinif_id';
  static const secretaryDocumentsLessonSettingKey =
      'secretary_documents_ders_id';
  static const secretaryDocumentsClassName = 'Okul Belgeleri';
  static const secretaryDocumentsLessonName = 'Evraklar';

  Future<int> ensureSecretaryDocumentsLessonId() async {
    final lessonStr = await getSetting(secretaryDocumentsLessonSettingKey);
    if (lessonStr != null) {
      final lessonId = int.tryParse(lessonStr);
      if (lessonId != null) {
        final lesson = await getLessonById(lessonId);
        if (lesson != null) return lessonId;
      }
    }
    var classIdStr = await getSetting(secretaryDocumentsClassSettingKey);
    int classId;
    if (classIdStr != null) {
      classId = int.tryParse(classIdStr) ?? await insertClass(
            secretaryDocumentsClassName,
          );
    } else {
      final classes = await getClasses();
      final existing = classes
          .where((c) => c.name == secretaryDocumentsClassName)
          .toList();
      if (existing.isNotEmpty) {
        classId = existing.first.id;
      } else {
        classId = await insertClass(secretaryDocumentsClassName);
      }
      await setSetting(secretaryDocumentsClassSettingKey, '$classId');
    }
    final lessons = await getLessons(classId);
    final lessonRow = lessons
        .where((l) => l.name == secretaryDocumentsLessonName)
        .toList();
    int lessonId;
    if (lessonRow.isNotEmpty) {
      lessonId = lessonRow.first.id;
    } else {
      lessonId = await insertLesson(
        classId,
        secretaryDocumentsLessonName,
        0,
      );
    }
    await setSetting(secretaryDocumentsLessonSettingKey, '$lessonId');
    return lessonId;
  }

  Future<List<Map<String, Object?>>> listSecretaryDocuments({
    String? search,
    String? category,
    bool? archived,
    bool? critical,
  }) async {
    final lessonId = await ensureSecretaryDocumentsLessonId();
    final where = <String>['ders_id = ?'];
    final args = <Object?>[lessonId];
    if (search != null && search.trim().isNotEmpty) {
      final q = '%${search.trim()}%';
      where.add('(ad LIKE ? OR IFNULL(aciklama, \'\') LIKE ?)');
      args.addAll([q, q]);
    }
    if (category != null && category.isNotEmpty) {
      where.add('belge_kategori = ?');
      args.add(category);
    }
    if (archived != null) {
      where.add('arsiv = ?');
      args.add(archived ? 1 : 0);
    }
    if (critical != null) {
      where.add('kritik = ?');
      args.add(critical ? 1 : 0);
    }
    return _database.query(
      'icerikler',
      where: where.join(' AND '),
      whereArgs: args,
      orderBy: 'guncelleme_tarihi DESC, olusturma_tarihi DESC',
    );
  }

  Future<int> insertSecretaryDocument({
    required String name,
    required String type,
    required String path,
    String? description,
    String? category,
    String? scope,
  }) async {
    final lessonId = await ensureSecretaryDocumentsLessonId();
    final rows = await _database.rawQuery(
      'SELECT MAX(sira) as maxOrder FROM icerikler WHERE ders_id = ?',
      [lessonId],
    );
    final maxOrder = rows.first['maxOrder'] as int? ?? 0;
    final now = DateTime.now().toIso8601String();
    return _database.insert('icerikler', {
      'ders_id': lessonId,
      'konu_id': null,
      'ad': name.trim(),
      'tur': type,
      'dosya_yolu': path,
      'sira': maxOrder + 1,
      'olusturma_tarihi': now,
      'guncelleme_tarihi': now,
      'aciklama': description?.trim().isEmpty == true ? null : description?.trim(),
      'belge_kategori': category?.trim().isEmpty == true ? null : category?.trim(),
      'belge_kapsam': scope?.trim().isEmpty == true ? null : scope?.trim(),
      'kritik': 0,
      'arsiv': 0,
    });
  }

  Future<void> updateSecretaryDocumentMetadata({
    required int contentId,
    required String name,
    String? description,
    String? category,
    String? scope,
  }) async {
    await _database.update(
      'icerikler',
      {
        'ad': name.trim(),
        'aciklama':
            description?.trim().isEmpty == true ? null : description?.trim(),
        'belge_kategori':
            category?.trim().isEmpty == true ? null : category?.trim(),
        'belge_kapsam': scope?.trim().isEmpty == true ? null : scope?.trim(),
        'guncelleme_tarihi': DateTime.now().toIso8601String(),
      },
      where: 'id = ?',
      whereArgs: [contentId],
    );
  }

  Future<bool> tryArchiveSecretaryDocument({
    required int contentId,
    required String roleName,
  }) async {
    if (roleName != 'secretary') return false;
    final row = await getContentById(contentId);
    if (row == null) return false;
    if ((row['kritik'] as int? ?? 0) == 1) return false;
    await setContentArchived(contentId, true);
    return true;
  }

  Future<bool> isSecretaryDocument(int contentId) async {
    final lessonId = await ensureSecretaryDocumentsLessonId();
    final row = await getContentById(contentId);
    return row != null && row['ders_id'] == lessonId;
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
      await _database.insert('favoriler', {
        'icerik_id': contentId,
      }, conflictAlgorithm: ConflictAlgorithm.ignore);
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
    return _database.rawQuery(
      '''
      SELECT i.*, d.ad as ders_ad, s.ad as sinif_ad
      FROM icerikler i
      JOIN dersler d ON d.id = i.ders_id
      JOIN siniflar s ON s.id = d.sinif_id
      WHERE i.ad LIKE ?
      ORDER BY i.id DESC
    ''',
      ['%$query%'],
    );
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

  Future<int> insertStudentClass(
    String name,
    String year, {
    required String section,
  }) async {
    final id = await _database.insert('ogrenci_siniflar', {
      'ad': name,
      'yil': year,
      'sube': section,
    });
    await seedDefaultCategories(_database, id);
    return id;
  }

  Future<List<Map<String, Object?>>> getStudentClasses() async {
    final rows = await _database.query('ogrenci_siniflar');
    final sorted = List<Map<String, Object?>>.from(rows);
    sorted.sort(CourseFormOptions.compareStudentClassRows);
    return sorted;
  }

  Future<Map<String, Object?>?> getStudentClassById(int classId) async {
    final rows = await _database.query(
      'ogrenci_siniflar',
      where: 'id = ?',
      whereArgs: [classId],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return rows.first;
  }

  Future<void> updateStudentClass(
    int id,
    String name,
    String year, {
    required String section,
  }) async {
    await _database.update(
      'ogrenci_siniflar',
      {'ad': name, 'yil': year, 'sube': section},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> deleteStudentClass(int id) async {
    await _database.delete(
      'ogrenci_siniflar',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<int> insertStudent({
    required int classId,
    required int number,
    required String name,
    String? email,
    String? motherEmail,
    String? fatherEmail,
    String? passwordHash,
  }) async {
    return _database.insert('ogrenciler', {
      'sinif_id': classId,
      'numara': number,
      'ad_soyad': name,
      'email': _nullableEmail(email),
      'anne_email': _nullableEmail(motherEmail),
      'baba_email': _nullableEmail(fatherEmail),
      if (await studentPasswordHashColumnReady())
        'sifre_hash': passwordHash,
    });
  }

  Future<bool> studentPasswordHashColumnReady() async {
    final rows = await _database.rawQuery('PRAGMA table_info(ogrenciler)');
    return rows.any((r) => r['name'] == 'sifre_hash');
  }

  Future<void> setStudentPasswordHash(int studentId, String passwordHash) async {
    if (!await studentPasswordHashColumnReady()) {
      throw StateError('student_password_hash_column_missing');
    }
    await _database.update(
      'ogrenciler',
      {'sifre_hash': passwordHash},
      where: 'id = ?',
      whereArgs: [studentId],
    );
  }

  /// Öğrenci numarası + şifre ile tek kayıt doğrulama.
  Future<({int studentId, int classId})?> authenticateStudent({
    required int studentNumber,
    required String passwordPlain,
  }) async {
    if (!await studentPasswordHashColumnReady()) {
      return null;
    }
    final rows = await _database.query(
      'ogrenciler',
      where: 'numara = ?',
      whereArgs: [studentNumber],
    );
    if (rows.isEmpty) return null;

    final defaultHash =
        StudentPasswordHash.hash(StudentPasswordHash.defaultPortalPassword);
    final matches = <({int studentId, int classId})>[];
    for (final row in rows) {
      final stored = row['sifre_hash'] as String?;
      final ok = stored != null && stored.isNotEmpty
          ? StudentPasswordHash.matches(passwordPlain, stored)
          : StudentPasswordHash.matches(
              passwordPlain,
              defaultHash,
            );
      if (ok) {
        matches.add((
          studentId: row['id'] as int,
          classId: row['sinif_id'] as int,
        ));
      }
    }
    if (matches.length != 1) return null;
    return matches.first;
  }

  Future<void> updateStudent({
    required int studentId,
    required int number,
    required String name,
    String? email,
    String? motherEmail,
    String? fatherEmail,
    int? classId,
  }) async {
    if (!await studentEmailColumnsReady()) {
      throw StateError('student_email_schema_missing');
    }
    final data = <String, Object?>{
      'numara': number,
      'ad_soyad': name,
      'email': _nullableEmail(email),
      'anne_email': _nullableEmail(motherEmail),
      'baba_email': _nullableEmail(fatherEmail),
    };
    if (classId != null) {
      data['sinif_id'] = classId;
    }
    await _database.update(
      'ogrenciler',
      data,
      where: 'id = ?',
      whereArgs: [studentId],
    );
  }

  Future<int> countAllStudents() async {
    final rows = await _database.rawQuery('SELECT COUNT(*) as c FROM ogrenciler');
    return rows.first['c'] as int? ?? 0;
  }

  Future<List<Map<String, Object?>>> listStudentsWithClass() async {
    return _database.rawQuery(
      '''
      SELECT o.id, o.numara, o.ad_soyad, o.email, o.anne_email, o.baba_email,
             o.sinif_id, s.ad as sinif_ad, s.yil as sinif_yil, s.sube as sinif_sube
      FROM ogrenciler o
      JOIN ogrenci_siniflar s ON s.id = o.sinif_id
      ORDER BY s.ad COLLATE NOCASE ASC,
               s.sube COLLATE NOCASE ASC,
               o.numara ASC
      ''',
    );
  }

  Future<void> deleteStudent(int studentId) async {
    await _database.delete(
      'ogrenciler',
      where: 'id = ?',
      whereArgs: [studentId],
    );
  }

  // —— Veliler (Faz 3) ——

  Future<int> insertParentGuardian({
    required String fullName,
    String? phone,
    String? email,
    String? address,
    String? notes,
  }) async {
    return _database.insert('veliler', {
      'ad_soyad': fullName.trim(),
      'telefon': phone?.trim().isEmpty == true ? null : phone?.trim(),
      'email': _nullableEmail(email),
      'adres': address?.trim().isEmpty == true ? null : address?.trim(),
      'notlar': notes?.trim().isEmpty == true ? null : notes?.trim(),
      'olusturma_tarihi': DateTime.now().toIso8601String(),
    });
  }

  Future<void> updateParentGuardian({
    required int id,
    required String fullName,
    String? phone,
    String? email,
    String? address,
    String? notes,
  }) async {
    await _database.update(
      'veliler',
      {
        'ad_soyad': fullName.trim(),
        'telefon': phone?.trim().isEmpty == true ? null : phone?.trim(),
        'email': _nullableEmail(email),
        'adres': address?.trim().isEmpty == true ? null : address?.trim(),
        'notlar': notes?.trim().isEmpty == true ? null : notes?.trim(),
      },
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<int> countParentStudentLinks(int parentId) async {
    final rows = await _database.rawQuery(
      'SELECT COUNT(*) as c FROM ogrenci_veliler WHERE veli_id = ?',
      [parentId],
    );
    return rows.first['c'] as int? ?? 0;
  }

  Future<bool> deleteParentGuardian(int parentId) async {
    final links = await countParentStudentLinks(parentId);
    if (links > 0) return false;
    await _database.delete('veliler', where: 'id = ?', whereArgs: [parentId]);
    return true;
  }

  Future<List<Map<String, Object?>>> listParentGuardians({
    String? searchQuery,
  }) async {
    final where = <String>[];
    final args = <Object?>[];
    if (searchQuery != null && searchQuery.trim().isNotEmpty) {
      final q = '%${searchQuery.trim()}%';
      where.add(
        '(v.ad_soyad LIKE ? OR v.email LIKE ? OR v.telefon LIKE ?)',
      );
      args.addAll([q, q, q]);
    }
    final sql = '''
      SELECT v.*,
             (SELECT COUNT(*) FROM ogrenci_veliler ov WHERE ov.veli_id = v.id)
               AS linked_count
      FROM veliler v
      ${where.isEmpty ? '' : 'WHERE ${where.join(' AND ')}'}
      ORDER BY v.ad_soyad COLLATE NOCASE ASC
    ''';
    return _database.rawQuery(sql, args);
  }

  Future<Map<String, Object?>?> getParentGuardianById(int id) async {
    final rows = await _database.rawQuery(
      '''
      SELECT v.*,
             (SELECT COUNT(*) FROM ogrenci_veliler ov WHERE ov.veli_id = v.id)
               AS linked_count
      FROM veliler v
      WHERE v.id = ?
      ''',
      [id],
    );
    if (rows.isEmpty) return null;
    return rows.first;
  }

  Future<int> linkStudentParent({
    required int studentId,
    required int parentId,
    required String relationCode,
    bool isPrimary = false,
  }) async {
    return _database.insert(
      'ogrenci_veliler',
      {
        'ogrenci_id': studentId,
        'veli_id': parentId,
        'yakinlik': relationCode,
        'birincil': isPrimary ? 1 : 0,
      },
      conflictAlgorithm: ConflictAlgorithm.abort,
    );
  }

  Future<void> unlinkStudentParent(int linkId) async {
    await _database.delete(
      'ogrenci_veliler',
      where: 'id = ?',
      whereArgs: [linkId],
    );
  }

  Future<List<Map<String, Object?>>> listParentsForStudent(int studentId) async {
    return _database.rawQuery(
      '''
      SELECT ov.id as link_id, ov.yakinlik, ov.birincil,
             v.id as veli_id, v.ad_soyad, v.telefon, v.email
      FROM ogrenci_veliler ov
      JOIN veliler v ON v.id = ov.veli_id
      WHERE ov.ogrenci_id = ?
      ORDER BY ov.birincil DESC, v.ad_soyad COLLATE NOCASE ASC
      ''',
      [studentId],
    );
  }

  Future<Map<String, Object?>?> getParentByEmail(String email) async {
    final trimmed = email.trim();
    if (trimmed.isEmpty) return null;
    final rows = await _database.query(
      'veliler',
      where: 'LOWER(TRIM(email)) = LOWER(TRIM(?))',
      whereArgs: [trimmed],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return rows.first;
  }

  Future<bool> isStudentLinkedToParent({
    required int parentId,
    required int studentId,
  }) async {
    final rows = await _database.query(
      'ogrenci_veliler',
      where: 'veli_id = ? AND ogrenci_id = ?',
      whereArgs: [parentId, studentId],
      limit: 1,
    );
    return rows.isNotEmpty;
  }

  Future<void> setParentPasswordHash(int parentId, String passwordHash) async {
    await _database.update(
      'veliler',
      {'sifre_hash': passwordHash},
      where: 'id = ?',
      whereArgs: [parentId],
    );
  }

  Future<void> updateParentEmail(int parentId, String email) async {
    await _database.update(
      'veliler',
      {'email': _nullableEmail(email)},
      where: 'id = ?',
      whereArgs: [parentId],
    );
  }

  Future<List<Map<String, Object?>>> listStudentsForParent(int parentId) async {
    return _database.rawQuery(
      '''
      SELECT ov.id as link_id, ov.yakinlik, ov.birincil,
             o.id as ogrenci_id, o.sinif_id as sinif_id, o.numara, o.ad_soyad,
             s.ad as sinif_ad, s.sube as sinif_sube
      FROM ogrenci_veliler ov
      JOIN ogrenciler o ON o.id = ov.ogrenci_id
      JOIN ogrenci_siniflar s ON s.id = o.sinif_id
      WHERE ov.veli_id = ?
      ORDER BY o.ad_soyad COLLATE NOCASE ASC
      ''',
      [parentId],
    );
  }

  // —— Günlük devamsızlık (Faz 4) ——

  Future<Map<int, String>> getDailyAttendanceStatusMap({
    required String dateKey,
    required List<int> studentIds,
  }) async {
    if (studentIds.isEmpty) return {};
    final placeholders = List.filled(studentIds.length, '?').join(',');
    final rows = await _database.rawQuery(
      '''
      SELECT ogrenci_id, durum
      FROM ogrenci_devamsizlik
      WHERE tarih = ? AND ogrenci_id IN ($placeholders)
      ''',
      [dateKey, ...studentIds],
    );
    final map = <int, String>{};
    for (final row in rows) {
      map[row['ogrenci_id'] as int] = row['durum'] as String;
    }
    return map;
  }

  Future<void> setStudentDailyAttendance({
    required int studentId,
    required String dateKey,
    required String status,
  }) async {
    if (status == 'var') {
      await _database.delete(
        'ogrenci_devamsizlik',
        where: 'ogrenci_id = ? AND tarih = ?',
        whereArgs: [studentId, dateKey],
      );
      return;
    }
    final now = DateTime.now().toIso8601String();
    final existing = await _database.query(
      'ogrenci_devamsizlik',
      where: 'ogrenci_id = ? AND tarih = ?',
      whereArgs: [studentId, dateKey],
      limit: 1,
    );
    if (existing.isNotEmpty) {
      await _database.update(
        'ogrenci_devamsizlik',
        {
          'durum': status,
          'guncelleme_tarihi': now,
        },
        where: 'id = ?',
        whereArgs: [existing.first['id']],
      );
      return;
    }
    await _database.insert('ogrenci_devamsizlik', {
      'ogrenci_id': studentId,
      'tarih': dateKey,
      'durum': status,
      'olusturma_tarihi': now,
      'guncelleme_tarihi': now,
    });
  }

  Future<void> bulkSetStudentDailyAttendance({
    required List<int> studentIds,
    required String dateKey,
    required String status,
  }) async {
    for (final id in studentIds) {
      await setStudentDailyAttendance(
        studentId: id,
        dateKey: dateKey,
        status: status,
      );
    }
  }

  Future<List<Map<String, Object?>>> listDailyAttendanceHistory({
    required String fromDate,
    required String toDate,
    int? studentId,
  }) async {
    final where = <String>[
      'd.tarih >= ?',
      'd.tarih <= ?',
    ];
    final args = <Object?>[fromDate, toDate];
    if (studentId != null) {
      where.add('d.ogrenci_id = ?');
      args.add(studentId);
    }
    return _database.rawQuery(
      '''
      SELECT d.id, d.ogrenci_id, d.tarih, d.durum,
             o.numara, o.ad_soyad, s.ad as sinif_ad, s.sube as sinif_sube
      FROM ogrenci_devamsizlik d
      JOIN ogrenciler o ON o.id = d.ogrenci_id
      JOIN ogrenci_siniflar s ON s.id = o.sinif_id
      WHERE ${where.join(' AND ')}
      ORDER BY d.tarih DESC, o.numara ASC
      ''',
      args,
    );
  }

  Future<List<Map<String, Object?>>> listDailyAttendanceForStudent({
    required int studentId,
    String? fromDate,
    String? toDate,
  }) async {
    final where = <String>['ogrenci_id = ?'];
    final args = <Object?>[studentId];
    if (fromDate != null) {
      where.add('tarih >= ?');
      args.add(fromDate);
    }
    if (toDate != null) {
      where.add('tarih <= ?');
      args.add(toDate);
    }
    return _database.query(
      'ogrenci_devamsizlik',
      where: where.join(' AND '),
      whereArgs: args,
      orderBy: 'tarih DESC',
    );
  }

  Future<Map<String, int>> countStudentDailyAttendanceByStatus(
    int studentId,
  ) async {
    final rows = await _database.rawQuery(
      '''
      SELECT durum, COUNT(*) as c
      FROM ogrenci_devamsizlik
      WHERE ogrenci_id = ?
      GROUP BY durum
      ''',
      [studentId],
    );
    final result = <String, int>{};
    for (final row in rows) {
      result[row['durum'] as String] = row['c'] as int? ?? 0;
    }
    return result;
  }

  Future<List<Map<String, Object?>>> getStudents(int classId) async {
    return _database.query(
      'ogrenciler',
      where: 'sinif_id = ?',
      whereArgs: [classId],
      orderBy: 'numara ASC',
    );
  }

  Future<List<Map<String, Object?>>> getStudentsByNumber(int number) async {
    return _database.query(
      'ogrenciler',
      where: 'numara = ?',
      whereArgs: [number],
    );
  }

  Future<Map<String, Object?>?> getStudentById(int studentId) async {
    final rows = await _database.query(
      'ogrenciler',
      where: 'id = ?',
      whereArgs: [studentId],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return rows.first;
  }

  Future<bool> studentEmailColumnsReady() async {
    final rows = await _database.rawQuery('PRAGMA table_info(ogrenciler)');
    final names = rows.map((r) => r['name'] as String).toSet();
    return names.contains('email') &&
        names.contains('anne_email') &&
        names.contains('baba_email');
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
    String? description,
  }) async {
    return _database.insert('not_kolonlari', {
      'sinif_id': classId,
      'ad': name,
      'tur': type,
      'aciklama': description,
    });
  }

  /// Materyal notlandırması için tek kolon garantisi.
  Future<int> ensureMaterialScoreColumn(
    int classId, {
    required String defaultName,
  }) async {
    final columns = await getScoreColumns(classId);
    final materialColumns =
        columns.where((col) => col['tur'] == 'materials').toList();
    if (materialColumns.isNotEmpty) {
      return materialColumns.first['id'] as int;
    }
    return insertScoreColumn(
      classId: classId,
      name: defaultName,
      type: 'materials',
    );
  }

  /// Performans tablosu için ilk/sabit Aktivite 1 kolonu.
  Future<int> ensurePrimaryActivityScoreColumn(
    int classId, {
    required String defaultName,
  }) async {
    final columns = await getScoreColumns(classId);
    final activityColumns =
        columns.where((col) => col['tur'] == 'activity').toList();
    if (activityColumns.isNotEmpty) {
      return activityColumns.first['id'] as int;
    }
    return insertScoreColumn(
      classId: classId,
      name: defaultName,
      type: 'activity',
    );
  }

  Future<int> getPrimaryActivityColumnId(int classId) async {
    return ensurePrimaryActivityScoreColumn(
      classId,
      defaultName: 'Aktivite 1',
    );
  }

  /// Kolon Ekle: Aktivite 2, 3, 4 ...
  Future<String> nextActivityColumnName(int classId) async {
    await ensurePrimaryActivityScoreColumn(
      classId,
      defaultName: 'Aktivite 1',
    );
    final columns = await getScoreColumns(classId);
    final activityCount =
        columns.where((col) => col['tur'] == 'activity').length;
    return 'Aktivite ${activityCount + 1}';
  }

  Future<void> ensurePerformanceScoreColumns(
    int classId, {
    required String materialColumnName,
    required String primaryActivityColumnName,
  }) async {
    await ensureMaterialScoreColumn(
      classId,
      defaultName: materialColumnName,
    );
    await ensurePrimaryActivityScoreColumn(
      classId,
      defaultName: primaryActivityColumnName,
    );
  }

  Future<void> updateScoreColumn({
    required int columnId,
    required String name,
    required String type,
    String? description,
    String? scoreDate,
  }) async {
    final trimmedDescription = description?.trim();
    await _database.update(
      'not_kolonlari',
      {
        'ad': name,
        'tur': type,
        if (scoreDate == null || scoreDate.isEmpty)
          'aciklama': trimmedDescription,
      },
      where: 'id = ?',
      whereArgs: [columnId],
    );
    if (scoreDate != null && scoreDate.isNotEmpty) {
      await setScoreColumnDateDescription(
        columnId: columnId,
        date: scoreDate,
        description: trimmedDescription,
      );
    }
  }

  Future<void> setScoreColumnDateDescription({
    required int columnId,
    required String date,
    String? description,
  }) async {
    final trimmed = description?.trim();
    if (trimmed == null || trimmed.isEmpty) {
      await _database.delete(
        'not_kolon_tarih_aciklama',
        where: 'kolon_id = ? AND tarih = ?',
        whereArgs: [columnId, date],
      );
      return;
    }
    await _database.insert(
      'not_kolon_tarih_aciklama',
      {
        'kolon_id': columnId,
        'tarih': date,
        'aciklama': trimmed,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<String?> scoreColumnDateDescription(int columnId, String date) async {
    final rows = await _database.query(
      'not_kolon_tarih_aciklama',
      columns: ['aciklama'],
      where: 'kolon_id = ? AND tarih = ?',
      whereArgs: [columnId, date],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    final text = rows.first['aciklama'] as String?;
    if (text == null || text.trim().isEmpty) return null;
    return text.trim();
  }

  Future<List<Map<String, Object?>>> getScoreColumnsForDate(
    int classId,
    String date,
  ) async {
    final columns = await getScoreColumns(classId);
    if (columns.isEmpty) return columns;
    final rows = await _database.rawQuery(
      '''
      SELECT d.kolon_id, d.aciklama
      FROM not_kolon_tarih_aciklama d
      JOIN not_kolonlari k ON k.id = d.kolon_id
      WHERE k.sinif_id = ? AND d.tarih = ?
      ''',
      [classId, date],
    );
    final byColumn = <int, String>{
      for (final row in rows)
        row['kolon_id'] as int: (row['aciklama'] as String).trim(),
    };
    return columns.map((col) {
      final id = col['id'] as int;
      return {
        ...col,
        'aciklama': byColumn[id],
      };
    }).toList();
  }

  Future<void> deleteScoreColumn(int columnId) async {
    await _database.delete(
      'not_kolonlari',
      where: 'id = ?',
      whereArgs: [columnId],
    );
  }

  Future<List<Map<String, Object?>>> getScoreColumns(int classId) async {
    return _database.query(
      'not_kolonlari',
      where: 'sinif_id = ?',
      whereArgs: [classId],
      orderBy: 'id ASC',
    );
  }

  Future<String?> _scoreColumnDescription(int columnId) async {
    final rows = await _database.query(
      'not_kolonlari',
      columns: ['aciklama'],
      where: 'id = ?',
      whereArgs: [columnId],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    final text = rows.first['aciklama'] as String?;
    if (text == null || text.trim().isEmpty) return null;
    return text.trim();
  }

  Future<void> setStudentScore({
    required int studentId,
    required int columnId,
    int? score,
    int? done,
    String? date,
    String? note,
    bool absent = false,
  }) async {
    final scoreDate = date ?? scoreDateKey(DateTime.now());
    final storedNote = note?.trim().isNotEmpty == true ? note!.trim() : null;
    await _database.insert('ogrenci_notlari', {
      'ogrenci_id': studentId,
      'kolon_id': columnId,
      'tarih': scoreDate,
      'not_deger': absent ? null : score,
      'yapildi': done,
      'devamsiz': absent ? 1 : 0,
      'aciklama': storedNote,
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<void> clearStudentScoresForClass(int classId) async {
    await _database.rawDelete(
      '''
      DELETE FROM ogrenci_notlari
      WHERE kolon_id IN (
        SELECT id FROM not_kolonlari WHERE sinif_id = ?
      )
    ''',
      [classId],
    );
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
    await _database.rawDelete(
      '''
      DELETE FROM ogrenci_notlari
      WHERE kolon_id IN (
        SELECT id FROM not_kolonlari WHERE sinif_id = ? AND tur = ?
      )
    ''',
      [classId, type],
    );
  }

  Future<List<Map<String, Object?>>> getStudentScores(
    int classId, {
    String? date,
  }) async {
    final dateKey = date ?? scoreDateKey(DateTime.now());
    return _database.rawQuery(
      '''
      SELECT o.id as ogrenci_id, k.id as kolon_id, n.not_deger, n.yapildi,
             n.devamsiz, n.tarih, n.aciklama
      FROM ogrenciler o
      JOIN not_kolonlari k ON k.sinif_id = o.sinif_id
      LEFT JOIN ogrenci_notlari n
        ON n.ogrenci_id = o.id AND n.kolon_id = k.id AND n.tarih = ?
      WHERE o.sinif_id = ?
    ''',
      [dateKey, classId],
    );
  }

  Future<int> countScoresForType(int classId, String type) async {
    final rows = await _database.rawQuery(
      '''
      SELECT COUNT(*) as c
      FROM ogrenci_notlari n
      JOIN not_kolonlari k ON k.id = n.kolon_id
      WHERE k.sinif_id = ? AND k.tur = ?
      ''',
      [classId, type],
    );
    return rows.first['c'] as int? ?? 0;
  }

  Future<List<Map<String, Object?>>> getStudentReportRows({
    int? classId,
    int? studentId,
    String? fromDate,
    String? toDate,
    String? categoryCode,
  }) async {
    final where = <String>[
      '(n.not_deger IS NOT NULL OR n.yapildi IS NOT NULL OR n.devamsiz = 1 OR IFNULL(n.aciklama, \'\') != \'\')',
    ];
    final args = <Object?>[];
    if (classId != null) {
      where.add('o.sinif_id = ?');
      args.add(classId);
    }
    if (studentId != null) {
      where.add('o.id = ?');
      args.add(studentId);
    }
    if (fromDate != null && fromDate.isNotEmpty) {
      where.add('n.tarih >= ?');
      args.add(fromDate);
    }
    if (toDate != null && toDate.isNotEmpty) {
      where.add('n.tarih <= ?');
      args.add(toDate);
    }
    if (categoryCode != null &&
        categoryCode.isNotEmpty &&
        categoryCode != 'students') {
      if (StudentCategory.isPerformanceCode(categoryCode)) {
        where.add('k.tur IN (?, ?)');
        args.addAll(StudentCategory.performanceScoreTypes);
      } else {
        where.add('k.tur = ?');
        args.add(categoryCode);
      }
    }
    return _database.rawQuery(
      '''
      SELECT o.id as ogrenci_id, o.ad_soyad, o.numara, o.sinif_id,
             s.ad as sinif_ad, k.id as kolon_id, k.ad as kolon_ad,
             k.aciklama as kolon_aciklama, d.aciklama as kolon_tarih_aciklama,
             k.tur, n.tarih, n.not_deger, n.yapildi, n.devamsiz, n.aciklama
      FROM ogrenci_notlari n
      JOIN ogrenciler o ON o.id = n.ogrenci_id
      JOIN ogrenci_siniflar s ON s.id = o.sinif_id
      JOIN not_kolonlari k ON k.id = n.kolon_id
      LEFT JOIN not_kolon_tarih_aciklama d
        ON d.kolon_id = k.id AND d.tarih = n.tarih
      WHERE ${where.join(' AND ')}
      ORDER BY s.ad ASC, o.numara ASC, n.tarih ASC, k.tur ASC, k.ad ASC
      ''',
      args,
    );
  }

  Future<List<StudentCategory>> getStudentCategories(
    int classId, {
    bool activeOnly = false,
  }) async {
    await ensureStudentCategoriesForClass(_database, classId);
    final rows = await _database.query(
      'ogrenci_kategoriler',
      where: activeOnly ? 'sinif_id = ? AND aktif = 1' : 'sinif_id = ?',
      whereArgs: [classId],
    );
    final list = rows.map(StudentCategory.fromMap).toList();
    list.sort(StudentCategory.compareByDisplayOrder);
    return list;
  }

  Future<int> insertStudentCategory({
    required int classId,
    required String name,
    required String code,
    required int order,
    bool system = false,
  }) async {
    return _database.insert('ogrenci_kategoriler', {
      'sinif_id': classId,
      'ad': name,
      'kod': code,
      'sira': order,
      'aktif': 1,
      'sistem': system ? 1 : 0,
    });
  }

  Future<int> getNextCategoryOrder(int classId) async {
    final rows = await _database.rawQuery(
      'SELECT MAX(sira) as maxOrder FROM ogrenci_kategoriler WHERE sinif_id = ?',
      [classId],
    );
    return ((rows.first['maxOrder'] as int?) ?? 0) + 1;
  }

  Future<void> updateStudentCategory({
    required int id,
    required String name,
    required int order,
    required bool active,
  }) async {
    await _database.update(
      'ogrenci_kategoriler',
      {'ad': name, 'sira': order, 'aktif': active ? 1 : 0},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> deleteStudentCategory(int id) async {
    await _database.delete(
      'ogrenci_kategoriler',
      where: 'id = ? AND sistem = 0',
      whereArgs: [id],
    );
  }

  Future<void> swapStudentCategoryOrder(int firstId, int secondId) async {
    final first = await _database.query(
      'ogrenci_kategoriler',
      where: 'id = ?',
      whereArgs: [firstId],
      limit: 1,
    );
    final second = await _database.query(
      'ogrenci_kategoriler',
      where: 'id = ?',
      whereArgs: [secondId],
      limit: 1,
    );
    if (first.isEmpty || second.isEmpty) {
      return;
    }
    if ((first.first['sistem'] as int? ?? 0) == 1 ||
        (second.first['sistem'] as int? ?? 0) == 1) {
      return;
    }
    final firstOrder = first.first['sira'] as int;
    final secondOrder = second.first['sira'] as int;
    await _database.update(
      'ogrenci_kategoriler',
      {'sira': secondOrder},
      where: 'id = ?',
      whereArgs: [firstId],
    );
    await _database.update(
      'ogrenci_kategoriler',
      {'sira': firstOrder},
      where: 'id = ?',
      whereArgs: [secondId],
    );
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

  Future<List<ContentWithTags>> getContentsWithTagsByTopic(int topicId) async {
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
        .map(
          (content) => ContentWithTags(
            content: content,
            tags: tagsByContent[content.id] ?? [],
          ),
        )
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
    await _database.insert('ayarlar', {
      'anahtar': key,
      'deger': value,
    }, conflictAlgorithm: ConflictAlgorithm.replace);
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

  Future<int> getNextTopicOrder(int lessonId, {int? unitId}) async {
    if (unitId != null) {
      final rows = await _database.rawQuery(
        'SELECT MAX(sira) as maxOrder FROM konular WHERE ders_id = ? AND unite_id = ?',
        [lessonId, unitId],
      );
      return ((rows.first['maxOrder'] as int?) ?? 0) + 1;
    }
    final rows = await _database.rawQuery(
      'SELECT MAX(sira) as maxOrder FROM konular WHERE ders_id = ?',
      [lessonId],
    );
    final maxOrder = rows.first['maxOrder'] as int?;
    return (maxOrder ?? 0) + 1;
  }

  Future<List<Map<String, Object?>>> getTopicsRaw(
    int lessonId, {
    int? unitId,
  }) async {
    if (unitId != null) {
      return _database.query(
        'konular',
        where: 'ders_id = ? AND unite_id = ?',
        whereArgs: [lessonId, unitId],
        orderBy: 'sira ASC',
      );
    }
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

  Future<int> _defaultUnitId(int lessonId) async {
    final units = await getUnits(lessonId);
    if (units.isNotEmpty) {
      return units.first.id;
    }
    return insertUnit(
      lessonId: lessonId,
      name: 'Ünite 1',
      number: 1,
      order: 1,
    );
  }

  Future<int> insertTopic(
    int lessonId,
    String name,
    int order, {
    int? unitId,
    String? imagePath,
  }) async {
    final resolvedUnitId = unitId ?? await _defaultUnitId(lessonId);
    return _database.insert('konular', {
      'ders_id': lessonId,
      'unite_id': resolvedUnitId,
      'ad': name,
      'sira': order,
      'resim_yolu': imagePath,
      'olusturma_tarihi': DateTime.now().toIso8601String(),
    });
  }

  Future<List<UnitModel>> getUnits(int lessonId) async {
    final rows = await _database.query(
      'uniteler',
      where: 'ders_id = ?',
      whereArgs: [lessonId],
      orderBy: 'sira ASC, numara ASC, id ASC',
    );
    return rows.map(UnitModel.fromMap).toList();
  }

  Future<List<UnitModel>> getUnitsForSubject(String subjectName) async {
    final rows = await _database.rawQuery(
      '''
      SELECT u.*
      FROM uniteler u
      INNER JOIN dersler d ON d.id = u.ders_id
      WHERE d.ad = ?
      ORDER BY d.akademik_yil DESC, u.sira ASC, u.numara ASC, u.id ASC
      ''',
      [subjectName],
    );
    return rows.map(UnitModel.fromMap).toList();
  }

  Future<List<Map<String, Object?>>> getTopicsForSubject(
    String subjectName,
  ) async {
    return _database.rawQuery(
      '''
      SELECT k.*
      FROM konular k
      INNER JOIN dersler d ON d.id = k.ders_id
      WHERE d.ad = ?
      ORDER BY k.sira ASC, k.id ASC
      ''',
      [subjectName],
    );
  }

  Future<List<ContentItem>> getContentsForSubject(String subjectName) async {
    final rows = await _database.rawQuery(
      '''
      SELECT i.*
      FROM icerikler i
      INNER JOIN dersler d ON d.id = i.ders_id
      WHERE d.ad = ?
      ORDER BY i.sira ASC, i.id ASC
      ''',
      [subjectName],
    );
    return rows.map(ContentItem.fromMap).toList();
  }

  Future<List<ContentItem>> getContentsForUnit(int unitId) async {
    final rows = await _database.rawQuery(
      '''
      SELECT i.*
      FROM icerikler i
      INNER JOIN konular k ON k.id = i.konu_id
      WHERE k.unite_id = ?
      ORDER BY i.sira ASC, i.id ASC
      ''',
      [unitId],
    );
    return rows.map(ContentItem.fromMap).toList();
  }

  Future<int> countTopicsForSubject(String subjectName) async {
    final rows = await _database.rawQuery(
      '''
      SELECT COUNT(k.id) as c
      FROM konular k
      INNER JOIN uniteler u ON u.id = k.unite_id
      INNER JOIN dersler d ON d.id = u.ders_id
      WHERE d.ad = ?
      ''',
      [subjectName],
    );
    return (rows.first['c'] as num?)?.toInt() ?? 0;
  }

  Future<int> countTopicsForLesson(int lessonId) async {
    final rows = await _database.rawQuery(
      '''
      SELECT COUNT(k.id) as c
      FROM konular k
      INNER JOIN uniteler u ON u.id = k.unite_id
      WHERE u.ders_id = ?
      ''',
      [lessonId],
    );
    return (rows.first['c'] as num?)?.toInt() ?? 0;
  }

  Future<Map<int, int>> getTopicCountsByUnitForLesson(int lessonId) async {
    final rows = await _database.rawQuery(
      '''
      SELECT u.id, COUNT(k.id) as konu_sayisi
      FROM uniteler u
      LEFT JOIN konular k ON k.unite_id = u.id
      WHERE u.ders_id = ?
      GROUP BY u.id
      ''',
      [lessonId],
    );
    return {
      for (final row in rows)
        row['id'] as int: (row['konu_sayisi'] as num?)?.toInt() ?? 0,
    };
  }

  Future<int> getNextUnitOrder(int lessonId) async {
    final rows = await _database.rawQuery(
      'SELECT MAX(sira) as maxOrder FROM uniteler WHERE ders_id = ?',
      [lessonId],
    );
    return ((rows.first['maxOrder'] as int?) ?? 0) + 1;
  }

  Future<int> getNextUnitNumber(int lessonId) async {
    final rows = await _database.rawQuery(
      'SELECT MAX(numara) as maxNumber FROM uniteler WHERE ders_id = ?',
      [lessonId],
    );
    return ((rows.first['maxNumber'] as int?) ?? 0) + 1;
  }

  Future<int> insertUnit({
    required int lessonId,
    required String name,
    required int number,
    required int order,
    String? imagePath,
  }) async {
    return _database.insert('uniteler', {
      'ders_id': lessonId,
      'ad': name,
      'numara': number,
      'sira': order,
      'resim_yolu': imagePath,
      'olusturma_tarihi': DateTime.now().toIso8601String(),
    });
  }

  Future<void> updateUnit({
    required int id,
    required String name,
    required int number,
    String? imagePath,
    bool clearImage = false,
  }) async {
    final values = <String, Object?>{'ad': name, 'numara': number};
    if (clearImage) {
      values['resim_yolu'] = null;
    } else if (imagePath != null) {
      values['resim_yolu'] = imagePath;
    }
    await _database.update(
      'uniteler',
      values,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> deleteUnit(int id) async {
    final rows = await _database.query(
      'uniteler',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    if (rows.isEmpty) {
      return;
    }
    final lessonId = rows.first['ders_id'] as int;
    await _database.delete('uniteler', where: 'id = ?', whereArgs: [id]);
    var remaining = await getUnits(lessonId);
    if (remaining.isEmpty) {
      await insertUnit(
        lessonId: lessonId,
        name: 'Ünite 1',
        number: 1,
        order: 1,
      );
      remaining = await getUnits(lessonId);
    }
    await _database.update(
      'konular',
      {'unite_id': remaining.first.id},
      where: 'ders_id = ? AND unite_id IS NULL',
      whereArgs: [lessonId],
    );
  }

  Future<void> updateTopic(
    int id,
    String name, {
    String? imagePath,
    bool clearImage = false,
  }) async {
    final values = <String, Object?>{'ad': name};
    if (clearImage) {
      values['resim_yolu'] = null;
    } else if (imagePath != null) {
      values['resim_yolu'] = imagePath;
    }
    await _database.update(
      'konular',
      values,
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

  static Future<void> _createV17Tables(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS icerik_okuma (
        icerik_id INTEGER PRIMARY KEY,
        son_sayfa INTEGER NOT NULL DEFAULT 1,
        guncelleme_tarihi TEXT NOT NULL,
        ekstra_json TEXT,
        FOREIGN KEY (icerik_id) REFERENCES icerikler(id) ON DELETE CASCADE
      )
    ''');
    await db.execute('''
      CREATE TABLE IF NOT EXISTS sinif_defteri_notlari (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        sinif_id INTEGER NOT NULL,
        metin TEXT NOT NULL,
        not_tarihi TEXT NOT NULL,
        olusturma_tarihi TEXT NOT NULL,
        guncelleme_tarihi TEXT,
        FOREIGN KEY (sinif_id) REFERENCES ogrenci_siniflar(id) ON DELETE CASCADE
      )
    ''');
    await db.execute('''
      CREATE INDEX IF NOT EXISTS idx_sinif_defteri_sinif_tarih
      ON sinif_defteri_notlari(sinif_id, not_tarihi DESC)
    ''');
    await db.execute('''
      CREATE TABLE IF NOT EXISTS ogretmen_son_islemler (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        tur TEXT NOT NULL,
        baslik TEXT NOT NULL,
        hedef_tur TEXT,
        hedef_id INTEGER,
        ek_veri TEXT,
        olusturma_tarihi TEXT NOT NULL
      )
    ''');
    await db.execute('''
      CREATE INDEX IF NOT EXISTS idx_ogretmen_son_islem_tarih
      ON ogretmen_son_islemler(olusturma_tarihi DESC)
    ''');
  }

  static Future<void> _createDocumentFolderTables(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS dokuman_klasorleri (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        ad TEXT NOT NULL,
        sira INTEGER NOT NULL DEFAULT 0,
        parent_id INTEGER,
        olusturma_tarihi TEXT NOT NULL,
        FOREIGN KEY (parent_id) REFERENCES dokuman_klasorleri(id) ON DELETE CASCADE
      )
    ''');
    await db.execute('''
      CREATE TABLE IF NOT EXISTS dokuman_klasor_ogeleri (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        klasor_id INTEGER NOT NULL,
        icerik_id INTEGER NOT NULL,
        sira INTEGER NOT NULL DEFAULT 0,
        UNIQUE(klasor_id, icerik_id),
        FOREIGN KEY (klasor_id) REFERENCES dokuman_klasorleri(id) ON DELETE CASCADE,
        FOREIGN KEY (icerik_id) REFERENCES icerikler(id) ON DELETE CASCADE
      )
    ''');
  }

  static Future<void> _createV18Tables(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS not_kolon_tarih_aciklama (
        kolon_id INTEGER NOT NULL,
        tarih TEXT NOT NULL,
        aciklama TEXT NOT NULL,
        PRIMARY KEY (kolon_id, tarih),
        FOREIGN KEY (kolon_id) REFERENCES not_kolonlari(id) ON DELETE CASCADE
      )
    ''');
  }

  /// Kolon açıklamaları yalnızca not_kolon_tarih_aciklama üzerinden tutulur.
  static Future<void> _migrateScoreDescriptionsV19(Database db) async {
    await db.execute('UPDATE not_kolonlari SET aciklama = NULL');
    await db.execute('UPDATE ogrenci_notlari SET aciklama = NULL');
  }

  static Future<void> _migrateStudentEmailsV20(Database db) async {
    if (!await _tableHasColumn(db, 'ogrenciler', 'email')) {
      await db.execute('ALTER TABLE ogrenciler ADD COLUMN email TEXT');
    }
    if (!await _tableHasColumn(db, 'ogrenciler', 'anne_email')) {
      await db.execute('ALTER TABLE ogrenciler ADD COLUMN anne_email TEXT');
    }
    if (!await _tableHasColumn(db, 'ogrenciler', 'baba_email')) {
      await db.execute('ALTER TABLE ogrenciler ADD COLUMN baba_email TEXT');
    }
  }

  static Future<void> _migrateWeeklySchedulePeriodSlotsV23(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS akademik_haftalik_saat (
        saat_sira INTEGER PRIMARY KEY,
        baslangic TEXT NOT NULL,
        bitis TEXT NOT NULL
      )
    ''');
    final countRow = await db.rawQuery('SELECT COUNT(*) AS c FROM akademik_haftalik_saat');
    final count = countRow.isEmpty ? 0 : countRow.first['c'] as int? ?? 0;
    if (count > 0) return;
    const defaults = <List<String>>[
      ['08:00', '08:45'],
      ['08:50', '09:35'],
      ['09:40', '10:25'],
      ['10:30', '11:15'],
      ['11:20', '12:05'],
      ['13:00', '13:45'],
      ['13:50', '14:35'],
      ['14:40', '15:25'],
    ];
    for (var i = 0; i < defaults.length; i++) {
      await db.insert('akademik_haftalik_saat', {
        'saat_sira': i + 1,
        'baslangic': defaults[i][0],
        'bitis': defaults[i][1],
      });
    }
  }

  static Future<bool> _tableHasColumn(
    Database db,
    String table,
    String column,
  ) async {
    final rows = await db.rawQuery('PRAGMA table_info($table)');
    for (final row in rows) {
      if (row['name'] == column) return true;
    }
    return false;
  }

  static Future<void> _ensureWeeklySchedulePeriodColumn(Database db) async {
    final tableExists = await db.rawQuery(
      "SELECT name FROM sqlite_master WHERE type='table' AND name='akademik_haftalik_ders'",
    );
    if (tableExists.isEmpty) return;

    final hasPeriodColumn = await _tableHasColumn(
      db,
      'akademik_haftalik_ders',
      'saat_sira',
    );
    if (hasPeriodColumn) return;

    try {
      await db.execute(
        'ALTER TABLE akademik_haftalik_ders ADD COLUMN saat_sira INTEGER NOT NULL DEFAULT 1',
      );
    } catch (e) {
      final message = e.toString().toLowerCase();
      if (!message.contains('duplicate column')) {
        rethrow;
      }
    }
  }

  static Future<void> _backfillWeeklySchedulePeriodNumbers(Database db) async {
    final tableExists = await db.rawQuery(
      "SELECT name FROM sqlite_master WHERE type='table' AND name='akademik_haftalik_ders'",
    );
    if (tableExists.isEmpty) return;
    if (!await _tableHasColumn(db, 'akademik_haftalik_ders', 'saat_sira')) {
      return;
    }

    for (var day = 1; day <= 5; day++) {
      final rows = await db.query(
        'akademik_haftalik_ders',
        where: 'gun = ?',
        whereArgs: [day],
        orderBy: 'baslangic ASC, id ASC',
      );
      for (var i = 0; i < rows.length; i++) {
        final period = (i + 1).clamp(1, 8);
        await db.update(
          'akademik_haftalik_ders',
          {'saat_sira': period},
          where: 'id = ?',
          whereArgs: [rows[i]['id']],
        );
      }
    }
  }

  static Future<void> _migrateParentPortalV32(Database db) async {
    if (!await _tableHasColumn(db, 'veliler', 'sifre_hash')) {
      await db.execute('ALTER TABLE veliler ADD COLUMN sifre_hash TEXT');
    }
  }

  static Future<void> _migrateAccountsV34(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS hesaplar (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        kullanici_adi TEXT NOT NULL UNIQUE,
        email TEXT UNIQUE,
        ad_soyad TEXT NOT NULL DEFAULT '',
        rol TEXT NOT NULL,
        sifre_hash TEXT NOT NULL,
        aktif INTEGER NOT NULL DEFAULT 1,
        domain_tur TEXT,
        domain_id INTEGER,
        sifre_degistir INTEGER NOT NULL DEFAULT 0,
        olusturma_tarihi TEXT NOT NULL,
        guncelleme_tarihi TEXT NOT NULL,
        son_giris_tarihi TEXT
      )
    ''');
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_hesaplar_rol ON hesaplar(rol, aktif)',
    );
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_hesaplar_domain ON hesaplar(domain_tur, domain_id)',
    );
    await db.execute('''
      CREATE TABLE IF NOT EXISTS hesap_denetcilik (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        hesap_id INTEGER,
        islem_tur TEXT NOT NULL,
        detay TEXT,
        yapan_hesap_id INTEGER,
        olusturma_tarihi TEXT NOT NULL
      )
    ''');
  }

  static Future<void> _migrateNotificationsV33(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS bildirimler (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        alici_rol TEXT NOT NULL,
        alici_id INTEGER NOT NULL DEFAULT 0,
        baslik TEXT NOT NULL,
        icerik TEXT NOT NULL DEFAULT '',
        tur TEXT NOT NULL,
        referans_tur TEXT,
        referans_id INTEGER,
        olusturma_tarihi TEXT NOT NULL,
        okunma_tarihi TEXT,
        durum TEXT NOT NULL DEFAULT 'okunmadi',
        dedup_anahtar TEXT NOT NULL UNIQUE
      )
    ''');
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_bildirimler_alici ON bildirimler(alici_rol, alici_id)',
    );
  }

  static Future<void> _migrateSecretaryDocumentsV31(Database db) async {
    if (!await _tableHasColumn(db, 'icerikler', 'kritik')) {
      await db.execute(
        'ALTER TABLE icerikler ADD COLUMN kritik INTEGER NOT NULL DEFAULT 0',
      );
    }
    if (!await _tableHasColumn(db, 'icerikler', 'aciklama')) {
      await db.execute('ALTER TABLE icerikler ADD COLUMN aciklama TEXT');
    }
    if (!await _tableHasColumn(db, 'icerikler', 'guncelleme_tarihi')) {
      await db.execute('ALTER TABLE icerikler ADD COLUMN guncelleme_tarihi TEXT');
    }
    if (!await _tableHasColumn(db, 'icerikler', 'belge_kategori')) {
      await db.execute('ALTER TABLE icerikler ADD COLUMN belge_kategori TEXT');
    }
    if (!await _tableHasColumn(db, 'icerikler', 'belge_kapsam')) {
      await db.execute('ALTER TABLE icerikler ADD COLUMN belge_kapsam TEXT');
    }
    final now = DateTime.now().toIso8601String();
    await db.rawUpdate(
      '''
      UPDATE icerikler
      SET guncelleme_tarihi = COALESCE(guncelleme_tarihi, olusturma_tarihi, ?)
      WHERE guncelleme_tarihi IS NULL OR guncelleme_tarihi = ''
      ''',
      [now],
    );
  }

  static Future<void> _migrateAnnouncementCoverV35(Database db) async {
    if (!await _tableHasColumn(db, 'ogrenci_duyurular', 'kapak_gorsel_yolu')) {
      await db.execute(
        'ALTER TABLE ogrenci_duyurular ADD COLUMN kapak_gorsel_yolu TEXT',
      );
    }
  }

  static Future<void> _migrateAnnouncementsV30(Database db) async {
    if (!await _tableHasColumn(db, 'ogrenci_duyurular', 'durum')) {
      await db.execute(
        "ALTER TABLE ogrenci_duyurular ADD COLUMN durum TEXT NOT NULL DEFAULT 'yayinda'",
      );
    }
    if (!await _tableHasColumn(db, 'ogrenci_duyurular', 'yayin_tarihi')) {
      await db.execute('ALTER TABLE ogrenci_duyurular ADD COLUMN yayin_tarihi TEXT');
    }
    if (!await _tableHasColumn(db, 'ogrenci_duyurular', 'guncelleme_tarihi')) {
      await db.execute(
        'ALTER TABLE ogrenci_duyurular ADD COLUMN guncelleme_tarihi TEXT',
      );
    }
    if (!await _tableHasColumn(db, 'ogrenci_duyurular', 'hedef_tur')) {
      await db.execute(
        "ALTER TABLE ogrenci_duyurular ADD COLUMN hedef_tur TEXT NOT NULL DEFAULT 'tum_okul'",
      );
    }
    if (!await _tableHasColumn(db, 'ogrenci_duyurular', 'hedef_sinif_seviye')) {
      await db.execute(
        'ALTER TABLE ogrenci_duyurular ADD COLUMN hedef_sinif_seviye INTEGER',
      );
    }
    final rows = await db.query('ogrenci_duyurular');
    final now = DateTime.now().toIso8601String();
    for (final row in rows) {
      final id = row['id'] as int;
      final sinifId = row['sinif_id'] as int?;
      final created = row['olusturma_tarihi'] as String? ?? now;
      final hedefTur = sinifId != null ? 'sube' : 'tum_okul';
      await db.update(
        'ogrenci_duyurular',
        {
          'durum': row['durum'] ?? 'yayinda',
          'hedef_tur': row['hedef_tur'] ?? hedefTur,
          'yayin_tarihi': row['yayin_tarihi'] ?? created,
          'guncelleme_tarihi': row['guncelleme_tarihi'] ?? created,
        },
        where: 'id = ?',
        whereArgs: [id],
      );
    }
  }

  static Future<void> _migrateAttendanceV29(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS ogrenci_devamsizlik (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        ogrenci_id INTEGER NOT NULL,
        tarih TEXT NOT NULL,
        durum TEXT NOT NULL,
        olusturma_tarihi TEXT NOT NULL,
        guncelleme_tarihi TEXT NOT NULL,
        UNIQUE(ogrenci_id, tarih),
        FOREIGN KEY (ogrenci_id) REFERENCES ogrenciler(id) ON DELETE CASCADE
      )
    ''');
  }

  static Future<void> _migrateParentsV28(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS veliler (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        ad_soyad TEXT NOT NULL,
        telefon TEXT,
        email TEXT,
        adres TEXT,
        notlar TEXT,
        olusturma_tarihi TEXT NOT NULL
      )
    ''');
    await db.execute('''
      CREATE TABLE IF NOT EXISTS ogrenci_veliler (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        ogrenci_id INTEGER NOT NULL,
        veli_id INTEGER NOT NULL,
        yakinlik TEXT NOT NULL,
        birincil INTEGER NOT NULL DEFAULT 0,
        UNIQUE(ogrenci_id, veli_id),
        FOREIGN KEY (ogrenci_id) REFERENCES ogrenciler(id) ON DELETE CASCADE,
        FOREIGN KEY (veli_id) REFERENCES veliler(id) ON DELETE RESTRICT
      )
    ''');

    final students = await db.query('ogrenciler');
    for (final row in students) {
      final studentId = row['id'] as int;
      final studentName = row['ad_soyad'] as String? ?? '';
      final anneEmail = (row['anne_email'] as String?)?.trim();
      final babaEmail = (row['baba_email'] as String?)?.trim();
      if (anneEmail != null && anneEmail.isNotEmpty) {
        await _migrationLinkParentEmail(
          db,
          studentId: studentId,
          studentName: studentName,
          email: anneEmail,
          relation: 'anne',
          labelPrefix: 'Anne',
        );
      }
      if (babaEmail != null && babaEmail.isNotEmpty) {
        await _migrationLinkParentEmail(
          db,
          studentId: studentId,
          studentName: studentName,
          email: babaEmail,
          relation: 'baba',
          labelPrefix: 'Baba',
        );
      }
    }
  }

  static Future<void> _migrationLinkParentEmail(
    Database db, {
    required int studentId,
    required String studentName,
    required String email,
    required String relation,
    required String labelPrefix,
  }) async {
    final existingLink = await db.query(
      'ogrenci_veliler',
      where: 'ogrenci_id = ? AND yakinlik = ?',
      whereArgs: [studentId, relation],
      limit: 1,
    );
    if (existingLink.isNotEmpty) return;

    var veliRows = await db.query(
      'veliler',
      where: 'LOWER(email) = LOWER(?)',
      whereArgs: [email],
      limit: 1,
    );
    int veliId;
    if (veliRows.isNotEmpty) {
      veliId = veliRows.first['id'] as int;
    } else {
      veliId = await db.insert('veliler', {
        'ad_soyad': '$labelPrefix — $studentName',
        'telefon': null,
        'email': email,
        'adres': null,
        'notlar': 'Otomatik: ogrenciler.$relation email',
        'olusturma_tarihi': DateTime.now().toIso8601String(),
      });
    }
    try {
      await db.insert('ogrenci_veliler', {
        'ogrenci_id': studentId,
        'veli_id': veliId,
        'yakinlik': relation,
        'birincil': relation == 'anne' ? 1 : 0,
      });
    } on DatabaseException {
      // duplicate link
    }
  }

  static Future<void> _migrateStudentLoginV27(Database db) async {
    if (!await _tableHasColumn(db, 'ogrenciler', 'sifre_hash')) {
      await db.execute('ALTER TABLE ogrenciler ADD COLUMN sifre_hash TEXT');
    }
    final defaultHash =
        StudentPasswordHash.hash(StudentPasswordHash.defaultPortalPassword);
    if (defaultHash == null) return;
    await db.update(
      'ogrenciler',
      {'sifre_hash': defaultHash},
      where: 'sifre_hash IS NULL OR sifre_hash = ?',
      whereArgs: [''],
    );
  }

  static Future<void> _migrateStudentPortalV26(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS ogrenci_duyurular (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        baslik TEXT NOT NULL,
        icerik TEXT NOT NULL,
        ogretmen_adi TEXT,
        sinif_id INTEGER,
        ders_id INTEGER,
        ders_adi TEXT,
        olusturma_tarihi TEXT NOT NULL,
        FOREIGN KEY (sinif_id) REFERENCES ogrenci_siniflar(id) ON DELETE CASCADE,
        FOREIGN KEY (ders_id) REFERENCES dersler(id) ON DELETE SET NULL
      )
    ''');
    if (!await _tableHasColumn(db, 'dersler', 'ogretmen_adi')) {
      await db.execute('ALTER TABLE dersler ADD COLUMN ogretmen_adi TEXT');
    }
    if (!await _tableHasColumn(db, 'not_kolonlari', 'ogretmen_adi')) {
      await db.execute('ALTER TABLE not_kolonlari ADD COLUMN ogretmen_adi TEXT');
    }
  }

  static Future<void> _migrateStudentPortalV25(Database db) async {
    if (await _tableHasColumn(db, 'ogrenci_davranis_kayitlari', 'ogrenciye_goster')) {
      return;
    }
    final tableExists = await db.rawQuery(
      "SELECT name FROM sqlite_master WHERE type='table' AND name='ogrenci_davranis_kayitlari'",
    );
    if (tableExists.isEmpty) return;
    await db.execute(
      'ALTER TABLE ogrenci_davranis_kayitlari '
      'ADD COLUMN ogrenciye_goster INTEGER NOT NULL DEFAULT 0',
    );
  }

  static Future<void> _migrateStudentPlatformV24(Database db) async {
    if (!await _tableHasColumn(db, 'ogrenci_notlari', 'devamsiz')) {
      await db.execute(
        'ALTER TABLE ogrenci_notlari ADD COLUMN devamsiz INTEGER NOT NULL DEFAULT 0',
      );
    }
    await _createBehaviorTablesV24(db);
    final classes = await db.query('ogrenci_siniflar');
    for (final cls in classes) {
      await ensureBehaviorsCategoryForClass(db, cls['id'] as int);
    }
  }

  static Future<void> _createBehaviorTablesV24(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS davranis_tanimlari (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        kod TEXT NOT NULL UNIQUE,
        ad TEXT NOT NULL,
        tur TEXT NOT NULL,
        sira INTEGER NOT NULL
      )
    ''');
    await db.execute('''
      CREATE TABLE IF NOT EXISTS ogrenci_davranis_kayitlari (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        sinif_id INTEGER NOT NULL,
        ogrenci_id INTEGER NOT NULL,
        davranis_id INTEGER NOT NULL,
        tarih TEXT NOT NULL,
        olusturma_tarihi TEXT NOT NULL,
        ogrenciye_goster INTEGER NOT NULL DEFAULT 0,
        UNIQUE(ogrenci_id, davranis_id, tarih),
        FOREIGN KEY (sinif_id) REFERENCES ogrenci_siniflar(id) ON DELETE CASCADE,
        FOREIGN KEY (ogrenci_id) REFERENCES ogrenciler(id) ON DELETE CASCADE,
        FOREIGN KEY (davranis_id) REFERENCES davranis_tanimlari(id) ON DELETE CASCADE
      )
    ''');
    await _seedBehaviorDefinitions(db);
  }

  static Future<void> _seedBehaviorDefinitions(Database db) async {
    for (final def in StudentBehaviorCatalog.defaults) {
      final existing = await db.query(
        'davranis_tanimlari',
        where: 'kod = ?',
        whereArgs: [def.code],
        limit: 1,
      );
      if (existing.isEmpty) {
        await db.insert('davranis_tanimlari', def.toDbRow());
      }
    }
  }

  static Future<void> _createAcademicPlansTablesV21(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS akademik_haftalik_ders (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        gun INTEGER NOT NULL,
        saat_sira INTEGER NOT NULL DEFAULT 1,
        baslangic TEXT NOT NULL,
        bitis TEXT NOT NULL,
        ders_id INTEGER,
        ogrenci_sinif_id INTEGER,
        konu_metin TEXT NOT NULL DEFAULT '',
        sinif_metin TEXT NOT NULL DEFAULT '',
        FOREIGN KEY (ders_id) REFERENCES dersler(id) ON DELETE SET NULL,
        FOREIGN KEY (ogrenci_sinif_id) REFERENCES ogrenci_siniflar(id) ON DELETE SET NULL
      )
    ''');
    await db.execute('''
      CREATE TABLE IF NOT EXISTS akademik_gunluk_plan (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        tarih TEXT NOT NULL,
        ders_id INTEGER,
        ogrenci_sinif_id INTEGER,
        konu_metin TEXT NOT NULL DEFAULT '',
        sinif_metin TEXT NOT NULL DEFAULT '',
        konu TEXT,
        hedefler TEXT,
        etkinlikler TEXT,
        materyaller TEXT,
        odev TEXT,
        notlar TEXT,
        FOREIGN KEY (ders_id) REFERENCES dersler(id) ON DELETE SET NULL,
        FOREIGN KEY (ogrenci_sinif_id) REFERENCES ogrenci_siniflar(id) ON DELETE SET NULL
      )
    ''');
    await db.execute('''
      CREATE TABLE IF NOT EXISTS akademik_yillik_plan (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        ogretim_yili TEXT NOT NULL,
        ders_id INTEGER,
        ogrenci_sinif_id INTEGER,
        konu_metin TEXT NOT NULL DEFAULT '',
        sinif_metin TEXT NOT NULL DEFAULT '',
        unite_konu TEXT NOT NULL,
        planlanan_donem TEXT,
        ders_saati INTEGER,
        hedefler TEXT,
        notlar TEXT,
        FOREIGN KEY (ders_id) REFERENCES dersler(id) ON DELETE SET NULL,
        FOREIGN KEY (ogrenci_sinif_id) REFERENCES ogrenci_siniflar(id) ON DELETE SET NULL
      )
    ''');
  }

  static String? _nullableEmail(String? value) {
    final trimmed = value?.trim();
    if (trimmed == null || trimmed.isEmpty) return null;
    return trimmed;
  }

  Future<List<DocumentFolder>> getDocumentFolders({int? parentId}) async {
    final rows = await _database.query(
      'dokuman_klasorleri',
      where: parentId == null ? 'parent_id IS NULL' : 'parent_id = ?',
      whereArgs: parentId == null ? null : [parentId],
      orderBy: 'sira ASC, ad ASC',
    );
    return rows.map(DocumentFolder.fromMap).toList();
  }

  Future<DocumentFolder?> getDocumentFolderById(int id) async {
    final rows = await _database.query(
      'dokuman_klasorleri',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    if (rows.isEmpty) {
      return null;
    }
    return DocumentFolder.fromMap(rows.first);
  }

  Future<int> insertDocumentFolder(String name, {int? parentId}) async {
    final orderRows = await _database.rawQuery(
      '''
      SELECT COALESCE(MAX(sira), -1) + 1 as next_sira
      FROM dokuman_klasorleri
      WHERE parent_id IS ${parentId == null ? 'NULL' : '?'}
      ''',
      parentId == null ? [] : [parentId],
    );
    final nextOrder = orderRows.first['next_sira'] as int? ?? 0;
    return _database.insert('dokuman_klasorleri', {
      'ad': name,
      'sira': nextOrder,
      'parent_id': parentId,
      'olusturma_tarihi': DateTime.now().toIso8601String(),
    });
  }

  Future<void> updateDocumentFolderName(int id, String name) async {
    await _database.update(
      'dokuman_klasorleri',
      {'ad': name},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> deleteDocumentFolder(int id) async {
    await _database.delete(
      'dokuman_klasorleri',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<List<DocumentFolder>> getDocumentFolderPath(int folderId) async {
    final path = <DocumentFolder>[];
    int? currentId = folderId;
    while (currentId != null) {
      final folder = await getDocumentFolderById(currentId);
      if (folder == null) {
        break;
      }
      path.insert(0, folder);
      currentId = folder.parentId;
    }
    return path;
  }

  Future<Map<int, int>> getDocumentFolderChildCounts() async {
    final rows = await _database.rawQuery(
      '''
      SELECT parent_id as pid, COUNT(*) as cnt
      FROM dokuman_klasorleri
      WHERE parent_id IS NOT NULL
      GROUP BY parent_id
      ''',
    );
    return {
      for (final row in rows)
        row['pid'] as int: row['cnt'] as int? ?? 0,
    };
  }

  Future<List<FolderPickerContent>> getFolderContents(int folderId) async {
    final rows = await _database.rawQuery(
      '''
      SELECT i.*, d.ad as ders_ad, k.ad as konu_ad
      FROM dokuman_klasor_ogeleri o
      INNER JOIN icerikler i ON i.id = o.icerik_id
      LEFT JOIN dersler d ON d.id = i.ders_id
      LEFT JOIN konular k ON k.id = i.konu_id
      WHERE o.klasor_id = ?
      ORDER BY o.sira ASC, i.ad ASC
      ''',
      [folderId],
    );
    return rows.map((row) {
      final itemMap = Map<String, Object?>.from(row);
      final lessonName = itemMap.remove('ders_ad') as String?;
      final topicName = itemMap.remove('konu_ad') as String?;
      return FolderPickerContent(
        item: ContentItem.fromMap(itemMap),
        lessonName: lessonName,
        topicName: topicName,
      );
    }).toList();
  }

  Future<Map<int, int>> getDocumentFolderItemCounts() async {
    final rows = await _database.rawQuery(
      '''
      SELECT klasor_id, COUNT(*) as cnt
      FROM dokuman_klasor_ogeleri
      GROUP BY klasor_id
      ''',
    );
    return {
      for (final row in rows)
        row['klasor_id'] as int: row['cnt'] as int? ?? 0,
    };
  }

  Future<void> addContentToFolder({
    required int folderId,
    required int contentId,
  }) async {
    final orderRows = await _database.rawQuery(
      '''
      SELECT COALESCE(MAX(sira), -1) + 1 as next_sira
      FROM dokuman_klasor_ogeleri
      WHERE klasor_id = ?
      ''',
      [folderId],
    );
    final nextOrder = orderRows.first['next_sira'] as int? ?? 0;
    await _database.insert(
      'dokuman_klasor_ogeleri',
      {
        'klasor_id': folderId,
        'icerik_id': contentId,
        'sira': nextOrder,
      },
      conflictAlgorithm: ConflictAlgorithm.ignore,
    );
  }

  Future<void> removeContentFromFolder({
    required int folderId,
    required int contentId,
  }) async {
    await _database.delete(
      'dokuman_klasor_ogeleri',
      where: 'klasor_id = ? AND icerik_id = ?',
      whereArgs: [folderId, contentId],
    );
  }

  /// Junction-only batch add; duplicate (klasor_id, icerik_id) pairs are skipped.
  Future<int> addContentsToFolderBatch({
    required int folderId,
    required List<int> contentIds,
  }) async {
    if (contentIds.isEmpty) {
      return 0;
    }
    var inserted = 0;
    await _database.transaction((txn) async {
      final orderRows = await txn.rawQuery(
        '''
        SELECT COALESCE(MAX(sira), -1) + 1 as next_sira
        FROM dokuman_klasor_ogeleri
        WHERE klasor_id = ?
        ''',
        [folderId],
      );
      var nextOrder = orderRows.first['next_sira'] as int? ?? 0;
      for (final contentId in contentIds) {
        final rowId = await txn.insert(
          'dokuman_klasor_ogeleri',
          {
            'klasor_id': folderId,
            'icerik_id': contentId,
            'sira': nextOrder,
          },
          conflictAlgorithm: ConflictAlgorithm.ignore,
        );
        if (rowId > 0) {
          inserted++;
          nextOrder++;
        }
      }
    });
    return inserted;
  }

  Future<void> upsertContentReadingProgress({
    required int contentId,
    required int lastPage,
    String? extraJson,
  }) async {
    final page = lastPage < 1 ? 1 : lastPage;
    await _database.insert(
      'icerik_okuma',
      {
        'icerik_id': contentId,
        'son_sayfa': page,
        'guncelleme_tarihi': DateTime.now().toIso8601String(),
        'ekstra_json': extraJson,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<ContentReadingProgress?> getContentReadingProgress(int contentId) async {
    final rows = await _database.query(
      'icerik_okuma',
      where: 'icerik_id = ?',
      whereArgs: [contentId],
      limit: 1,
    );
    if (rows.isEmpty) {
      return null;
    }
    return ContentReadingProgress.fromMap(rows.first);
  }

  Future<Map<int, int>> getContentReadingPages(Iterable<int> contentIds) async {
    final ids = contentIds.toSet().toList();
    if (ids.isEmpty) {
      return {};
    }
    final placeholders = List.filled(ids.length, '?').join(',');
    final rows = await _database.rawQuery(
      'SELECT icerik_id, son_sayfa FROM icerik_okuma WHERE icerik_id IN ($placeholders)',
      ids,
    );
    return {
      for (final row in rows)
        row['icerik_id'] as int: row['son_sayfa'] as int? ?? 1,
    };
  }

  Future<int> insertClassNotebookNote({
    required int classId,
    required String text,
    required String noteDate,
  }) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty) {
      throw ArgumentError.value(text, 'text', 'Note text must not be empty.');
    }
    final now = DateTime.now().toIso8601String();
    return _database.insert('sinif_defteri_notlari', {
      'sinif_id': classId,
      'metin': trimmed,
      'not_tarihi': noteDate,
      'olusturma_tarihi': now,
      'guncelleme_tarihi': null,
    });
  }

  Future<void> updateClassNotebookNote({
    required int noteId,
    String? text,
    String? noteDate,
  }) async {
    final updates = <String, Object?>{
      'guncelleme_tarihi': DateTime.now().toIso8601String(),
    };
    if (text != null) {
      final trimmed = text.trim();
      if (trimmed.isEmpty) {
        throw ArgumentError.value(text, 'text', 'Note text must not be empty.');
      }
      updates['metin'] = trimmed;
    }
    if (noteDate != null) {
      updates['not_tarihi'] = noteDate;
    }
    await _database.update(
      'sinif_defteri_notlari',
      updates,
      where: 'id = ?',
      whereArgs: [noteId],
    );
  }

  Future<void> deleteClassNotebookNote(int noteId) async {
    await _database.delete(
      'sinif_defteri_notlari',
      where: 'id = ?',
      whereArgs: [noteId],
    );
  }

  Future<List<ClassNotebookNote>> getClassNotebookNotes(
    int classId, {
    int? limit,
  }) async {
    final rows = await _database.query(
      'sinif_defteri_notlari',
      where: 'sinif_id = ?',
      whereArgs: [classId],
      orderBy: 'not_tarihi DESC, id DESC',
      limit: limit,
    );
    return rows.map(ClassNotebookNote.fromMap).toList();
  }

  Future<ClassNotebookNote?> getClassNotebookNoteById(int noteId) async {
    final rows = await _database.query(
      'sinif_defteri_notlari',
      where: 'id = ?',
      whereArgs: [noteId],
      limit: 1,
    );
    if (rows.isEmpty) {
      return null;
    }
    return ClassNotebookNote.fromMap(rows.first);
  }

  static const int defaultTeacherActivityKeepCount = 100;

  Future<int> insertTeacherActivity({
    required String type,
    required String title,
    String? targetType,
    int? targetId,
    String? extraData,
    DateTime? createdAt,
  }) async {
    final id = await _database.insert('ogretmen_son_islemler', {
      'tur': type,
      'baslik': title,
      'hedef_tur': targetType,
      'hedef_id': targetId,
      'ek_veri': extraData,
      'olusturma_tarihi': (createdAt ?? DateTime.now()).toIso8601String(),
    });
    await trimTeacherActivities(keep: defaultTeacherActivityKeepCount);
    return id;
  }

  Future<List<TeacherRecentActivity>> getRecentTeacherActivities({
    int limit = 10,
  }) async {
    final rows = await _database.query(
      'ogretmen_son_islemler',
      orderBy: 'olusturma_tarihi DESC, id DESC',
      limit: limit,
    );
    return rows.map(TeacherRecentActivity.fromMap).toList();
  }

  Future<void> trimTeacherActivities({int keep = defaultTeacherActivityKeepCount}) async {
    if (keep < 1) {
      return;
    }
    final countRows = await _database.rawQuery(
      'SELECT COUNT(*) as cnt FROM ogretmen_son_islemler',
    );
    final count = countRows.first['cnt'] as int? ?? 0;
    if (count <= keep) {
      return;
    }
    await _database.rawDelete(
      '''
      DELETE FROM ogretmen_son_islemler
      WHERE id NOT IN (
        SELECT id FROM ogretmen_son_islemler
        ORDER BY olusturma_tarihi DESC, id DESC
        LIMIT ?
      )
      ''',
      [keep],
    );
  }

  static const String _folderHomeworkMatchSql = '''
(i.tur = 'homework'
 OR (i.tur = 'text' AND (i.ad LIKE '%ödev%' OR i.ad LIKE '%Ödev%' OR i.ad = 'Ödev'))
 OR i.ad LIKE '%ödev%' OR i.ad LIKE '%Ödev%')''';

  Future<List<Map<String, Object?>>> listLessonOptionsForContentPicker({
    bool homeworkOnly = false,
  }) async {
    final homeworkClause = homeworkOnly
        ? _folderHomeworkMatchSql
        : 'NOT ($_folderHomeworkMatchSql)';
    return _database.rawQuery(
      '''
      SELECT DISTINCT d.id, d.ad
      FROM icerikler i
      INNER JOIN dersler d ON d.id = i.ders_id
      WHERE $homeworkClause
      ORDER BY d.ad COLLATE NOCASE
      ''',
    );
  }

  Future<List<FolderPickerContent>> listContentsForFolderPicker({
    String? query,
    bool homeworkOnly = false,
    int? lessonId,
    int? unitId,
    int? topicId,
  }) async {
    final where = <String>[];
    final args = <Object?>[];
    if (homeworkOnly) {
      where.add(_folderHomeworkMatchSql);
    } else {
      where.add('NOT ($_folderHomeworkMatchSql)');
    }
    if (lessonId != null) {
      where.add('i.ders_id = ?');
      args.add(lessonId);
    }
    if (topicId != null) {
      where.add('i.konu_id = ?');
      args.add(topicId);
    }
    if (unitId != null) {
      where.add('k.unit_id = ?');
      args.add(unitId);
    }
    if (query != null && query.trim().isNotEmpty) {
      where.add('i.ad LIKE ?');
      args.add('%${query.trim()}%');
    }
    final whereSql = where.isEmpty ? '' : 'WHERE ${where.join(' AND ')}';
    final rows = await _database.rawQuery(
      '''
      SELECT i.*, d.ad as ders_ad, k.ad as konu_ad
      FROM icerikler i
      LEFT JOIN dersler d ON d.id = i.ders_id
      LEFT JOIN konular k ON k.id = i.konu_id
      $whereSql
      ORDER BY i.id DESC
      LIMIT 200
      ''',
      args,
    );
    return rows.map((row) {
      final itemMap = Map<String, Object?>.from(row);
      final lessonName = itemMap.remove('ders_ad') as String?;
      final topicName = itemMap.remove('konu_ad') as String?;
      return FolderPickerContent(
        item: ContentItem.fromMap(itemMap),
        lessonName: lessonName,
        topicName: topicName,
      );
    }).toList();
  }

  static Future<void> _createMentorshipTables(Database db) async {
    await db.execute('''
      CREATE TABLE mentorluk_siniflar (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        sinif_id INTEGER NOT NULL UNIQUE,
        olusturma_tarihi TEXT NOT NULL,
        FOREIGN KEY (sinif_id) REFERENCES ogrenci_siniflar(id) ON DELETE CASCADE
      )
    ''');
    await db.execute('''
      CREATE TABLE mentorluk_etkinlikler (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        sinif_id INTEGER NOT NULL,
        tur TEXT NOT NULL,
        baslik TEXT NOT NULL,
        aciklama TEXT,
        tarih TEXT NOT NULL,
        saat TEXT NOT NULL,
        durum TEXT NOT NULL,
        tum_sinif INTEGER NOT NULL DEFAULT 0,
        olusturma_tarihi TEXT NOT NULL,
        FOREIGN KEY (sinif_id) REFERENCES ogrenci_siniflar(id) ON DELETE CASCADE
      )
    ''');
    await db.execute('''
      CREATE TABLE mentorluk_etkinlik_ogrenciler (
        etkinlik_id INTEGER NOT NULL,
        ogrenci_id INTEGER NOT NULL,
        PRIMARY KEY (etkinlik_id, ogrenci_id),
        FOREIGN KEY (etkinlik_id) REFERENCES mentorluk_etkinlikler(id) ON DELETE CASCADE,
        FOREIGN KEY (ogrenci_id) REFERENCES ogrenciler(id) ON DELETE CASCADE
      )
    ''');
    await db.execute('''
      CREATE TABLE mentorluk_davranis_raporlari (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        sinif_id INTEGER NOT NULL,
        ogrenci_id INTEGER NOT NULL,
        tarih TEXT NOT NULL,
        tur TEXT NOT NULL,
        davranis TEXT,
        aciklama TEXT,
        seviye TEXT,
        ogretmen_notu TEXT,
        olusturma_tarihi TEXT NOT NULL,
        FOREIGN KEY (sinif_id) REFERENCES ogrenci_siniflar(id) ON DELETE CASCADE,
        FOREIGN KEY (ogrenci_id) REFERENCES ogrenciler(id) ON DELETE CASCADE
      )
    ''');
    await db.execute('''
      CREATE TABLE mentorluk_notlar (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        sinif_id INTEGER NOT NULL,
        ogrenci_id INTEGER NOT NULL,
        metin TEXT NOT NULL,
        olusturma_tarihi TEXT NOT NULL,
        FOREIGN KEY (sinif_id) REFERENCES ogrenci_siniflar(id) ON DELETE CASCADE,
        FOREIGN KEY (ogrenci_id) REFERENCES ogrenciler(id) ON DELETE CASCADE
      )
    ''');
  }

  Future<int> linkMentorshipClass(int classId) async {
    final existing = await _database.query(
      'mentorluk_siniflar',
      where: 'sinif_id = ?',
      whereArgs: [classId],
      limit: 1,
    );
    if (existing.isNotEmpty) {
      return existing.first['id'] as int;
    }
    return _database.insert('mentorluk_siniflar', {
      'sinif_id': classId,
      'olusturma_tarihi': DateTime.now().toIso8601String(),
    });
  }

  Future<List<Map<String, Object?>>> getMentorshipClasses() async {
    return _database.rawQuery('''
      SELECT m.id as mentorluk_id, s.id, s.ad, s.yil, s.sube,
             (SELECT COUNT(*) FROM ogrenciler o WHERE o.sinif_id = s.id) as ogrenci_sayisi
      FROM mentorluk_siniflar m
      JOIN ogrenci_siniflar s ON s.id = m.sinif_id
      ORDER BY s.ad COLLATE NOCASE ASC
    ''');
  }

  Future<List<Map<String, Object?>>> getClassesAvailableForMentorshipTransfer() async {
    return _database.rawQuery('''
      SELECT s.id, s.ad, s.yil, s.sube,
             (SELECT COUNT(*) FROM ogrenciler o WHERE o.sinif_id = s.id) as ogrenci_sayisi
      FROM ogrenci_siniflar s
      WHERE s.id NOT IN (SELECT sinif_id FROM mentorluk_siniflar)
      ORDER BY s.ad COLLATE NOCASE ASC
    ''');
  }

  Future<int> getStudentCount(int classId) async {
    final rows = await _database.rawQuery(
      'SELECT COUNT(*) as c FROM ogrenciler WHERE sinif_id = ?',
      [classId],
    );
    return rows.first['c'] as int? ?? 0;
  }

  Future<int> insertMentorshipEvent({
    required int classId,
    required String type,
    required String title,
    String? description,
    required String date,
    required String time,
    required String status,
    bool allClass = false,
    List<int> studentIds = const [],
  }) async {
    final eventId = await _database.insert('mentorluk_etkinlikler', {
      'sinif_id': classId,
      'tur': type,
      'baslik': title,
      'aciklama': description,
      'tarih': date,
      'saat': time,
      'durum': status,
      'tum_sinif': allClass ? 1 : 0,
      'olusturma_tarihi': DateTime.now().toIso8601String(),
    });
    if (!allClass) {
      for (final studentId in studentIds) {
        await _database.insert('mentorluk_etkinlik_ogrenciler', {
          'etkinlik_id': eventId,
          'ogrenci_id': studentId,
        });
      }
    }
    return eventId;
  }

  Future<void> updateMentorshipEvent({
    required int eventId,
    required String title,
    String? description,
    required String date,
    required String time,
    required String status,
    bool allClass = false,
    List<int> studentIds = const [],
  }) async {
    await _database.update(
      'mentorluk_etkinlikler',
      {
        'baslik': title,
        'aciklama': description,
        'tarih': date,
        'saat': time,
        'durum': status,
        'tum_sinif': allClass ? 1 : 0,
      },
      where: 'id = ?',
      whereArgs: [eventId],
    );
    await _database.delete(
      'mentorluk_etkinlik_ogrenciler',
      where: 'etkinlik_id = ?',
      whereArgs: [eventId],
    );
    if (!allClass) {
      for (final studentId in studentIds) {
        await _database.insert('mentorluk_etkinlik_ogrenciler', {
          'etkinlik_id': eventId,
          'ogrenci_id': studentId,
        });
      }
    }
  }

  Future<void> deleteMentorshipEvent(int eventId) async {
    await _database.delete(
      'mentorluk_etkinlikler',
      where: 'id = ?',
      whereArgs: [eventId],
    );
  }

  Future<List<Map<String, Object?>>> getMentorshipEvents({
    required int classId,
    String? fromDate,
    String? toDate,
    int? studentId,
  }) async {
    final where = <String>['e.sinif_id = ?'];
    final args = <Object?>[classId];
    if (fromDate != null && fromDate.isNotEmpty) {
      where.add('e.tarih >= ?');
      args.add(fromDate);
    }
    if (toDate != null && toDate.isNotEmpty) {
      where.add('e.tarih <= ?');
      args.add(toDate);
    }
    if (studentId != null) {
      where.add('''
        (e.tum_sinif = 1 OR EXISTS (
          SELECT 1 FROM mentorluk_etkinlik_ogrenciler eo
          WHERE eo.etkinlik_id = e.id AND eo.ogrenci_id = ?
        ))
      ''');
      args.add(studentId);
    }
    return _database.rawQuery(
      '''
      SELECT e.*
      FROM mentorluk_etkinlikler e
      WHERE ${where.join(' AND ')}
      ORDER BY e.tarih ASC, e.saat ASC
      ''',
      args,
    );
  }

  Future<List<int>> getMentorshipEventStudentIds(int eventId) async {
    final rows = await _database.query(
      'mentorluk_etkinlik_ogrenciler',
      columns: ['ogrenci_id'],
      where: 'etkinlik_id = ?',
      whereArgs: [eventId],
    );
    return rows.map((row) => row['ogrenci_id'] as int).toList();
  }

  Future<int> insertMentorshipBehaviorReport({
    required int classId,
    required int studentId,
    required String date,
    required String type,
    String? behavior,
    String? description,
    String? level,
    String? teacherNote,
  }) async {
    return _database.insert('mentorluk_davranis_raporlari', {
      'sinif_id': classId,
      'ogrenci_id': studentId,
      'tarih': date,
      'tur': type,
      'davranis': behavior,
      'aciklama': description,
      'seviye': level,
      'ogretmen_notu': teacherNote,
      'olusturma_tarihi': DateTime.now().toIso8601String(),
    });
  }

  Future<List<Map<String, Object?>>> getMentorshipBehaviorReports({
    int? classId,
    int? studentId,
    String? fromDate,
    String? toDate,
    String? type,
    int? limit,
  }) async {
    final where = <String>['1 = 1'];
    final args = <Object?>[];
    if (classId != null) {
      where.add('r.sinif_id = ?');
      args.add(classId);
    }
    if (studentId != null) {
      where.add('r.ogrenci_id = ?');
      args.add(studentId);
    }
    if (fromDate != null && fromDate.isNotEmpty) {
      where.add('r.tarih >= ?');
      args.add(fromDate);
    }
    if (toDate != null && toDate.isNotEmpty) {
      where.add('r.tarih <= ?');
      args.add(toDate);
    }
    if (type != null && type.isNotEmpty) {
      where.add('r.tur = ?');
      args.add(type);
    }
    final limitSql = limit != null ? 'LIMIT $limit' : '';
    return _database.rawQuery(
      '''
      SELECT r.*, o.ad_soyad, o.numara
      FROM mentorluk_davranis_raporlari r
      JOIN ogrenciler o ON o.id = r.ogrenci_id
      WHERE ${where.join(' AND ')}
      ORDER BY r.tarih DESC, r.olusturma_tarihi DESC
      $limitSql
      ''',
      args,
    );
  }

  Future<int> insertMentorshipNote({
    required int classId,
    required int studentId,
    required String text,
  }) async {
    return _database.insert('mentorluk_notlar', {
      'sinif_id': classId,
      'ogrenci_id': studentId,
      'metin': text,
      'olusturma_tarihi': DateTime.now().toIso8601String(),
    });
  }

  Future<List<Map<String, Object?>>> getMentorshipNotes({
    required int classId,
    required int studentId,
  }) async {
    return _database.query(
      'mentorluk_notlar',
      where: 'sinif_id = ? AND ogrenci_id = ?',
      whereArgs: [classId, studentId],
      orderBy: 'olusturma_tarihi DESC',
    );
  }

  Future<List<({String start, String end})>> getWeeklySchedulePeriodSlots() async {
    const defaults = <List<String>>[
      ['08:00', '08:45'],
      ['08:50', '09:35'],
      ['09:40', '10:25'],
      ['10:30', '11:15'],
      ['11:20', '12:05'],
      ['13:00', '13:45'],
      ['13:50', '14:35'],
      ['14:40', '15:25'],
    ];
    try {
      final rows = await _database.query(
        'akademik_haftalik_saat',
        orderBy: 'saat_sira ASC',
      );
      if (rows.length >= 8) {
        return [
          for (final row in rows.take(8))
            (
              start: row['baslangic'] as String,
              end: row['bitis'] as String,
            ),
        ];
      }
    } catch (_) {
      // Table may not exist on very old DB until migration runs.
    }
    return [
      for (final pair in defaults)
        (start: pair[0], end: pair[1]),
    ];
  }

  Future<void> saveWeeklySchedulePeriodSlot({
    required int periodNumber,
    required String startTime,
    required String endTime,
  }) async {
    await _database.insert(
      'akademik_haftalik_saat',
      {
        'saat_sira': periodNumber,
        'baslangic': startTime,
        'bitis': endTime,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
    await _database.update(
      'akademik_haftalik_ders',
      {
        'baslangic': startTime,
        'bitis': endTime,
      },
      where: 'saat_sira = ?',
      whereArgs: [periodNumber],
    );
  }

  Future<List<Map<String, Object?>>> getWeeklyScheduleEntries() async {
    return _database.rawQuery('''
      SELECT h.*, d.ad as ders_ad, s.ad as ogrenci_sinif_ad, s.sube as ogrenci_sube
      FROM akademik_haftalik_ders h
      LEFT JOIN dersler d ON d.id = h.ders_id
      LEFT JOIN ogrenci_siniflar s ON s.id = h.ogrenci_sinif_id
      ORDER BY h.gun ASC, h.saat_sira ASC, h.baslangic ASC
    ''');
  }

  Future<int> insertWeeklyScheduleEntry({
    required int dayOfWeek,
    required int periodNumber,
    required String startTime,
    required String endTime,
    int? lessonId,
    int? studentClassId,
    String subjectLabel = '',
    String classLabel = '',
  }) async {
    return _database.insert('akademik_haftalik_ders', {
      'gun': dayOfWeek,
      'saat_sira': periodNumber,
      'baslangic': startTime,
      'bitis': endTime,
      'ders_id': lessonId,
      'ogrenci_sinif_id': studentClassId,
      'konu_metin': subjectLabel,
      'sinif_metin': classLabel,
    });
  }

  Future<void> updateWeeklyScheduleEntry({
    required int id,
    required int dayOfWeek,
    required int periodNumber,
    required String startTime,
    required String endTime,
    int? lessonId,
    int? studentClassId,
    String subjectLabel = '',
    String classLabel = '',
  }) async {
    await _database.update(
      'akademik_haftalik_ders',
      {
        'gun': dayOfWeek,
        'saat_sira': periodNumber,
        'baslangic': startTime,
        'bitis': endTime,
        'ders_id': lessonId,
        'ogrenci_sinif_id': studentClassId,
        'konu_metin': subjectLabel,
        'sinif_metin': classLabel,
      },
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> deleteWeeklyScheduleEntry(int id) async {
    await _database.delete(
      'akademik_haftalik_ders',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  /// Saves one grid cell (unique per [dayOfWeek] + [periodNumber]).
  Future<void> saveWeeklyScheduleGridCell({
    required int dayOfWeek,
    required int periodNumber,
    required String startTime,
    required String endTime,
    int? studentClassId,
    String classLabel = '',
    int? existingEntryId,
  }) async {
    final classText = classLabel.trim();
    final hasClass =
        studentClassId != null || classText.isNotEmpty;
    if (!hasClass) {
      if (existingEntryId != null) {
        await deleteWeeklyScheduleEntry(existingEntryId);
      } else {
        await _database.delete(
          'akademik_haftalik_ders',
          where: 'gun = ? AND saat_sira = ?',
          whereArgs: [dayOfWeek, periodNumber],
        );
      }
      return;
    }

    if (existingEntryId != null) {
      await updateWeeklyScheduleEntry(
        id: existingEntryId,
        dayOfWeek: dayOfWeek,
        periodNumber: periodNumber,
        startTime: startTime,
        endTime: endTime,
        studentClassId: studentClassId,
        classLabel: classText,
      );
      return;
    }

    await _database.delete(
      'akademik_haftalik_ders',
      where: 'gun = ? AND saat_sira = ?',
      whereArgs: [dayOfWeek, periodNumber],
    );
    await insertWeeklyScheduleEntry(
      dayOfWeek: dayOfWeek,
      periodNumber: periodNumber,
      startTime: startTime,
      endTime: endTime,
      studentClassId: studentClassId,
      classLabel: classText,
    );
  }

  Future<List<Map<String, Object?>>> getDailyPlans() async {
    return _database.rawQuery('''
      SELECT p.*, d.ad as ders_ad, s.ad as ogrenci_sinif_ad, s.sube as ogrenci_sube
      FROM akademik_gunluk_plan p
      LEFT JOIN dersler d ON d.id = p.ders_id
      LEFT JOIN ogrenci_siniflar s ON s.id = p.ogrenci_sinif_id
      ORDER BY p.tarih DESC, p.id DESC
    ''');
  }

  Future<int> insertDailyPlan(Map<String, Object?> values) async {
    return _database.insert('akademik_gunluk_plan', values);
  }

  Future<void> updateDailyPlan(int id, Map<String, Object?> values) async {
    await _database.update(
      'akademik_gunluk_plan',
      values,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> deleteDailyPlan(int id) async {
    await _database.delete(
      'akademik_gunluk_plan',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<List<Map<String, Object?>>> getAnnualPlans() async {
    return _database.rawQuery('''
      SELECT p.*, d.ad as ders_ad, s.ad as ogrenci_sinif_ad, s.sube as ogrenci_sube
      FROM akademik_yillik_plan p
      LEFT JOIN dersler d ON d.id = p.ders_id
      LEFT JOIN ogrenci_siniflar s ON s.id = p.ogrenci_sinif_id
      ORDER BY p.ogretim_yili DESC, p.id DESC
    ''');
  }

  Future<int> insertAnnualPlan(Map<String, Object?> values) async {
    return _database.insert('akademik_yillik_plan', values);
  }

  Future<void> updateAnnualPlan(int id, Map<String, Object?> values) async {
    await _database.update(
      'akademik_yillik_plan',
      values,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> deleteAnnualPlan(int id) async {
    await _database.delete(
      'akademik_yillik_plan',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<List<Map<String, Object?>>> listLessonsForAcademicPlanning() async {
    return _database.rawQuery('''
      SELECT d.id, d.ad, c.ad as sinif_ad
      FROM dersler d
      JOIN siniflar c ON c.id = d.sinif_id
      ORDER BY c.ad ASC, d.sira ASC, d.ad ASC
    ''');
  }

  Future<List<Map<String, Object?>>> getBehaviorDefinitions() async {
    await _seedBehaviorDefinitionsIfNeeded();
    return _database.query(
      'davranis_tanimlari',
      orderBy: 'sira ASC, id ASC',
    );
  }

  Future<void> _seedBehaviorDefinitionsIfNeeded() async {
    final countRows = await _database.rawQuery(
      'SELECT COUNT(*) as c FROM davranis_tanimlari',
    );
    final count = countRows.first['c'] as int? ?? 0;
    if (count == 0) {
      await _seedBehaviorDefinitions(_database);
    }
  }

  Future<Set<String>> getStudentBehaviorRecordKeys({
    required int classId,
    required String date,
  }) async {
    final rows = await _database.query(
      'ogrenci_davranis_kayitlari',
      columns: ['ogrenci_id', 'davranis_id'],
      where: 'sinif_id = ? AND tarih = ?',
      whereArgs: [classId, date],
    );
    return rows
        .map(
          (row) =>
              '${row['ogrenci_id']}_${row['davranis_id']}',
        )
        .toSet();
  }

  Future<Set<String>> getStudentBehaviorPublishKeys({
    required int classId,
    required String date,
  }) async {
    if (!await _tableHasColumn(_database, 'ogrenci_davranis_kayitlari', 'ogrenciye_goster')) {
      return {};
    }
    final rows = await _database.query(
      'ogrenci_davranis_kayitlari',
      columns: ['ogrenci_id', 'davranis_id'],
      where: 'sinif_id = ? AND tarih = ? AND ogrenciye_goster = 1',
      whereArgs: [classId, date],
    );
    return rows
        .map((r) => '${r['ogrenci_id']}_${r['davranis_id']}')
        .toSet();
  }

  Future<void> setStudentBehaviorVisibleToStudent({
    required int studentId,
    required int behaviorId,
    required String date,
    required bool visible,
  }) async {
    if (!await _tableHasColumn(_database, 'ogrenci_davranis_kayitlari', 'ogrenciye_goster')) {
      return;
    }
    await _database.update(
      'ogrenci_davranis_kayitlari',
      {'ogrenciye_goster': visible ? 1 : 0},
      where: 'ogrenci_id = ? AND davranis_id = ? AND tarih = ?',
      whereArgs: [studentId, behaviorId, date],
    );
  }

  Future<void> setStudentBehaviorChecked({
    required int classId,
    required int studentId,
    required int behaviorId,
    required String date,
    required bool checked,
  }) async {
    if (checked) {
      await _database.insert(
        'ogrenci_davranis_kayitlari',
        {
          'sinif_id': classId,
          'ogrenci_id': studentId,
          'davranis_id': behaviorId,
          'tarih': date,
          'olusturma_tarihi': DateTime.now().toIso8601String(),
        },
        conflictAlgorithm: ConflictAlgorithm.ignore,
      );
      return;
    }
    await _database.delete(
      'ogrenci_davranis_kayitlari',
      where: 'ogrenci_id = ? AND davranis_id = ? AND tarih = ?',
      whereArgs: [studentId, behaviorId, date],
    );
  }

  Future<List<Map<String, Object?>>> getStudentBehaviorReportRows({
    required int classId,
    int? studentId,
    String? fromDate,
    String? toDate,
  }) async {
    final where = <String>['r.sinif_id = ?'];
    final args = <Object?>[classId];
    if (studentId != null) {
      where.add('r.ogrenci_id = ?');
      args.add(studentId);
    }
    if (fromDate != null && fromDate.isNotEmpty) {
      where.add('r.tarih >= ?');
      args.add(fromDate);
    }
    if (toDate != null && toDate.isNotEmpty) {
      where.add('r.tarih <= ?');
      args.add(toDate);
    }
    return _database.rawQuery(
      '''
      SELECT r.ogrenci_id, o.ad_soyad, o.numara, r.tarih,
             d.ad as davranis_ad, d.tur as davranis_tur, d.kod as davranis_kod,
             r.ogrenciye_goster
      FROM ogrenci_davranis_kayitlari r
      JOIN ogrenciler o ON o.id = r.ogrenci_id
      JOIN davranis_tanimlari d ON d.id = r.davranis_id
      WHERE ${where.join(' AND ')}
      ORDER BY o.numara ASC, r.tarih ASC, d.sira ASC
      ''',
      args,
    );
  }

  Future<Map<String, Object?>?> getScoreColumnById(int columnId) async {
    final rows = await _database.query(
      'not_kolonlari',
      where: 'id = ?',
      whereArgs: [columnId],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return rows.first;
  }

  Future<Map<String, Object?>?> getLessonRow(int lessonId) async {
    final rows = await _database.query(
      'dersler',
      where: 'id = ?',
      whereArgs: [lessonId],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return rows.first;
  }

  Future<int> insertStudentAnnouncement({
    required String title,
    required String body,
    String? teacherName,
    int? classId,
    int? lessonId,
    String? courseLabel,
    String? coverImagePath,
  }) async {
    final now = DateTime.now().toIso8601String();
    final targetType = classId != null ? 'sube' : 'tum_okul';
    return _database.insert('ogrenci_duyurular', {
      'baslik': title,
      'icerik': body,
      'ogretmen_adi': teacherName,
      'sinif_id': classId,
      'ders_id': lessonId,
      'ders_adi': courseLabel,
      'olusturma_tarihi': now,
      'durum': 'yayinda',
      'hedef_tur': targetType,
      'yayin_tarihi': now,
      'guncelleme_tarihi': now,
      if (coverImagePath != null && coverImagePath.trim().isNotEmpty)
        'kapak_gorsel_yolu': coverImagePath.trim(),
    });
  }

  Future<int> insertSecretaryAnnouncement({
    required String title,
    required String body,
    required String status,
    required String targetType,
    int? classId,
    int? targetGradeLevel,
    String? authorLabel,
    String? coverImagePath,
  }) async {
    final now = DateTime.now().toIso8601String();
    return _database.insert('ogrenci_duyurular', {
      'baslik': title.trim(),
      'icerik': body.trim(),
      'ogretmen_adi': authorLabel ?? 'Sekreter',
      'sinif_id': targetType == 'sube' ? classId : null,
      'hedef_tur': targetType,
      'hedef_sinif_seviye': targetType == 'sinif' ? targetGradeLevel : null,
      'durum': status,
      'olusturma_tarihi': now,
      'guncelleme_tarihi': now,
      'yayin_tarihi': status == 'yayinda' ? now : null,
      if (coverImagePath != null && coverImagePath.trim().isNotEmpty)
        'kapak_gorsel_yolu': coverImagePath.trim(),
    });
  }

  Future<void> updateSecretaryAnnouncement({
    required int id,
    required String title,
    required String body,
    required String targetType,
    int? classId,
    int? targetGradeLevel,
    String? coverImagePath,
    bool clearCoverImage = false,
  }) async {
    final now = DateTime.now().toIso8601String();
    await _database.update(
      'ogrenci_duyurular',
      {
        'baslik': title.trim(),
        'icerik': body.trim(),
        'hedef_tur': targetType,
        'sinif_id': targetType == 'sube' ? classId : null,
        'hedef_sinif_seviye': targetType == 'sinif' ? targetGradeLevel : null,
        'guncelleme_tarihi': now,
        if (clearCoverImage) 'kapak_gorsel_yolu': null,
        if (!clearCoverImage &&
            coverImagePath != null &&
            coverImagePath.trim().isNotEmpty)
          'kapak_gorsel_yolu': coverImagePath.trim(),
      },
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> publishStudentAnnouncement(int id) async {
    final now = DateTime.now().toIso8601String();
    await _database.update(
      'ogrenci_duyurular',
      {
        'durum': 'yayinda',
        'yayin_tarihi': now,
        'guncelleme_tarihi': now,
      },
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> unpublishStudentAnnouncement(int id) async {
    final now = DateTime.now().toIso8601String();
    await _database.update(
      'ogrenci_duyurular',
      {
        'durum': 'kaldirildi',
        'guncelleme_tarihi': now,
      },
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<Map<String, Object?>?> getStudentAnnouncementById(int id) async {
    final rows = await _database.query(
      'ogrenci_duyurular',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return rows.first;
  }

  Future<List<Map<String, Object?>>> listAnnouncementsForSecretary({
    String? search,
    String? status,
    String? targetType,
    String? fromDate,
    String? toDate,
  }) async {
    final where = <String>[];
    final args = <Object?>[];
    if (search != null && search.trim().isNotEmpty) {
      final q = '%${search.trim()}%';
      where.add('(baslik LIKE ? OR icerik LIKE ?)');
      args.addAll([q, q]);
    }
    if (status != null && status.isNotEmpty) {
      where.add('durum = ?');
      args.add(status);
    }
    if (targetType != null && targetType.isNotEmpty) {
      where.add('hedef_tur = ?');
      args.add(targetType);
    }
    if (fromDate != null && fromDate.isNotEmpty) {
      where.add('date(COALESCE(yayin_tarihi, olusturma_tarihi)) >= date(?)');
      args.add(fromDate);
    }
    if (toDate != null && toDate.isNotEmpty) {
      where.add('date(COALESCE(yayin_tarihi, olusturma_tarihi)) <= date(?)');
      args.add(toDate);
    }
    return _database.query(
      'ogrenci_duyurular',
      where: where.isEmpty ? null : where.join(' AND '),
      whereArgs: args.isEmpty ? null : args,
      orderBy: 'guncelleme_tarihi DESC, olusturma_tarihi DESC',
    );
  }

  Future<void> deleteStudentAnnouncement(int id) async {
    await _database.delete(
      'ogrenci_duyurular',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<List<Map<String, Object?>>> listStudentAnnouncementsForTeacher() async {
    return _database.query(
      'ogrenci_duyurular',
      orderBy: 'olusturma_tarihi DESC',
    );
  }

  Future<List<Map<String, Object?>>> listStudentAnnouncementsForClasses(
    Set<int> classIds,
  ) async {
    final gradeLevels = await _gradeLevelsForStudentClassIds(classIds);
    final rows = await _database.query(
      'ogrenci_duyurular',
      where: "durum = ?",
      whereArgs: ['yayinda'],
      orderBy: 'COALESCE(yayin_tarihi, olusturma_tarihi) DESC',
      limit: 100,
    );
    final matched = rows
        .where(
          (row) => _announcementMatchesStudentScope(
            row,
            classIds: classIds,
            gradeLevels: gradeLevels,
          ),
        )
        .take(50)
        .toList();
    return matched;
  }

  Future<Set<int>> _gradeLevelsForStudentClassIds(Set<int> classIds) async {
    if (classIds.isEmpty) return {};
    final placeholders = List.filled(classIds.length, '?').join(',');
    final rows = await _database.rawQuery(
      'SELECT ad FROM ogrenci_siniflar WHERE id IN ($placeholders)',
      classIds.toList(),
    );
    return rows
        .map((r) => CourseFormOptions.resolveGrade(r['ad'] as String?))
        .toSet();
  }

  bool _announcementMatchesStudentScope(
    Map<String, Object?> row, {
    required Set<int> classIds,
    required Set<int> gradeLevels,
  }) {
    final tur = row['hedef_tur'] as String? ??
        (row['sinif_id'] == null ? 'tum_okul' : 'sube');
    switch (tur) {
      case 'tum_okul':
        return true;
      case 'sube':
        final sid = row['sinif_id'] as int?;
        return sid != null && classIds.contains(sid);
      case 'sinif':
        final g = row['hedef_sinif_seviye'] as int?;
        return g != null && gradeLevels.contains(g);
      default:
        final sid = row['sinif_id'] as int?;
        if (sid == null) return true;
        return classIds.contains(sid);
    }
  }

  Future<Set<int>> lessonIdsLinkedToStudentClasses(Set<int> studentClassIds) async {
    if (studentClassIds.isEmpty) return {};
    final placeholders = List.filled(studentClassIds.length, '?').join(',');
    final rows = await _database.rawQuery(
      '''
      SELECT DISTINCT ders_id FROM akademik_haftalik_ders
      WHERE ogrenci_sinif_id IN ($placeholders) AND ders_id IS NOT NULL
      ''',
      studentClassIds.toList(),
    );
    return rows.map((r) => r['ders_id'] as int).toSet();
  }

  Future<bool> insertInAppNotificationIdempotent({
    required String recipientRole,
    required int recipientId,
    required String title,
    required String body,
    required String type,
    String? referenceType,
    int? referenceId,
    required String dedupKey,
    String? createdAt,
  }) async {
    final now = createdAt ?? DateTime.now().toIso8601String();
    final id = await _database.insert(
      'bildirimler',
      {
        'alici_rol': recipientRole,
        'alici_id': recipientId,
        'baslik': title,
        'icerik': body,
        'tur': type,
        'referans_tur': referenceType,
        'referans_id': referenceId,
        'olusturma_tarihi': now,
        'okunma_tarihi': null,
        'durum': 'okunmadi',
        'dedup_anahtar': dedupKey,
      },
      conflictAlgorithm: ConflictAlgorithm.ignore,
    );
    return id > 0;
  }

  Future<List<Map<String, Object?>>> listInAppNotificationsForRecipient({
    required String recipientRole,
    required int recipientId,
    int limit = 100,
  }) async {
    return _database.query(
      'bildirimler',
      where: 'alici_rol = ? AND alici_id = ?',
      whereArgs: [recipientRole, recipientId],
      orderBy: 'olusturma_tarihi DESC',
      limit: limit,
    );
  }

  Future<int> countUnreadInAppNotifications({
    required String recipientRole,
    required int recipientId,
  }) async {
    final rows = await _database.rawQuery(
      '''
      SELECT COUNT(*) as c FROM bildirimler
      WHERE alici_rol = ? AND alici_id = ? AND durum = 'okunmadi'
      ''',
      [recipientRole, recipientId],
    );
    return (rows.first['c'] as int?) ?? 0;
  }

  Future<bool> markInAppNotificationRead({
    required int notificationId,
    required String recipientRole,
    required int recipientId,
  }) async {
    final now = DateTime.now().toIso8601String();
    final count = await _database.update(
      'bildirimler',
      {'durum': 'okundu', 'okunma_tarihi': now},
      where: 'id = ? AND alici_rol = ? AND alici_id = ?',
      whereArgs: [notificationId, recipientRole, recipientId],
    );
    return count > 0;
  }

  Future<int> markAllInAppNotificationsRead({
    required String recipientRole,
    required int recipientId,
  }) async {
    final now = DateTime.now().toIso8601String();
    return _database.update(
      'bildirimler',
      {'durum': 'okundu', 'okunma_tarihi': now},
      where: "alici_rol = ? AND alici_id = ? AND durum = 'okunmadi'",
      whereArgs: [recipientRole, recipientId],
    );
  }

  Future<bool> hasActiveAdminAccount() async {
    final rows = await _database.rawQuery(
      "SELECT COUNT(*) as c FROM hesaplar WHERE rol = 'admin' AND aktif = 1",
    );
    return (rows.first['c'] as int? ?? 0) > 0;
  }

  Future<int> countActiveAdmins({int? excludeAccountId}) async {
    final args = <Object?>[];
    var where = "rol = 'admin' AND aktif = 1";
    if (excludeAccountId != null) {
      where += ' AND id != ?';
      args.add(excludeAccountId);
    }
    final rows = await _database.rawQuery(
      'SELECT COUNT(*) as c FROM hesaplar WHERE $where',
      args,
    );
    return rows.first['c'] as int? ?? 0;
  }

  Future<Map<String, Object?>?> getAccountById(int id) async {
    final rows = await _database.query(
      'hesaplar',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return rows.first;
  }

  Future<Map<String, Object?>?> getAccountByUsername(String username) async {
    final trimmed = username.trim();
    if (trimmed.isEmpty) return null;
    final rows = await _database.query(
      'hesaplar',
      where: 'LOWER(kullanici_adi) = ?',
      whereArgs: [trimmed.toLowerCase()],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return rows.first;
  }

  Future<Map<String, Object?>?> getAccountByEmail(String email) async {
    final trimmed = email.trim();
    if (trimmed.isEmpty) return null;
    final rows = await _database.query(
      'hesaplar',
      where: 'LOWER(TRIM(email)) = ?',
      whereArgs: [trimmed.toLowerCase()],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return rows.first;
  }

  Future<Map<String, Object?>?> findAccountByLogin({
    required String login,
    required String role,
  }) async {
    final trimmed = login.trim();
    if (trimmed.isEmpty) return null;
    final lower = trimmed.toLowerCase();
    final rows = await _database.rawQuery(
      '''
      SELECT * FROM hesaplar
      WHERE rol = ? AND aktif = 1
        AND (LOWER(kullanici_adi) = ? OR (email IS NOT NULL AND LOWER(TRIM(email)) = ?))
      LIMIT 1
      ''',
      [role, lower, lower],
    );
    if (rows.isEmpty) return null;
    return rows.first;
  }

  Future<Map<String, Object?>?> getAccountForDomain({
    required String domainType,
    required int domainId,
  }) async {
    final rows = await _database.query(
      'hesaplar',
      where: 'domain_tur = ? AND domain_id = ?',
      whereArgs: [domainType, domainId],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return rows.first;
  }

  Future<bool> isDomainLoginAllowed({
    required String domainType,
    required int domainId,
  }) async {
    final acc = await getAccountForDomain(
      domainType: domainType,
      domainId: domainId,
    );
    if (acc == null) return true;
    return (acc['aktif'] as int? ?? 1) == 1;
  }

  Future<List<Map<String, Object?>>> listAccounts({
    String? roleFilter,
    String? search,
    bool? activeOnly,
  }) async {
    final where = <String>[];
    final args = <Object?>[];
    if (roleFilter != null && roleFilter.isNotEmpty) {
      where.add('rol = ?');
      args.add(roleFilter);
    }
    if (activeOnly == true) {
      where.add('aktif = 1');
    } else if (activeOnly == false) {
      where.add('aktif = 0');
    }
    if (search != null && search.trim().isNotEmpty) {
      final q = '%${search.trim()}%';
      where.add(
        '(kullanici_adi LIKE ? OR email LIKE ? OR ad_soyad LIKE ?)',
      );
      args.addAll([q, q, q]);
    }
    return _database.query(
      'hesaplar',
      where: where.isEmpty ? null : where.join(' AND '),
      whereArgs: args.isEmpty ? null : args,
      orderBy: 'olusturma_tarihi DESC',
    );
  }

  Future<int> insertAccount({
    required String username,
    String? email,
    required String fullName,
    required String role,
    required String passwordHash,
    required bool active,
    String? domainType,
    int? domainId,
    bool mustChangePassword = false,
  }) async {
    final now = DateTime.now().toIso8601String();
    return _database.insert(
      'hesaplar',
      {
        'kullanici_adi': username.trim(),
        'email': email?.trim().isEmpty == true ? null : email?.trim(),
        'ad_soyad': fullName.trim(),
        'rol': role,
        'sifre_hash': passwordHash,
        'aktif': active ? 1 : 0,
        'domain_tur': domainType,
        'domain_id': domainId,
        'sifre_degistir': mustChangePassword ? 1 : 0,
        'olusturma_tarihi': now,
        'guncelleme_tarihi': now,
      },
      conflictAlgorithm: ConflictAlgorithm.abort,
    );
  }

  Future<void> updateAccountFields({
    required int id,
    String? fullName,
    String? email,
    bool? active,
    bool? mustChangePassword,
  }) async {
    final map = <String, Object?>{
      'guncelleme_tarihi': DateTime.now().toIso8601String(),
    };
    if (fullName != null) map['ad_soyad'] = fullName.trim();
    if (email != null) {
      map['email'] = email.trim().isEmpty ? null : email.trim();
    }
    if (active != null) map['aktif'] = active ? 1 : 0;
    if (mustChangePassword != null) {
      map['sifre_degistir'] = mustChangePassword ? 1 : 0;
    }
    await _database.update('hesaplar', map, where: 'id = ?', whereArgs: [id]);
  }

  Future<void> setAccountPasswordHash({
    required int id,
    required String passwordHash,
    bool mustChangePassword = false,
  }) async {
    await _database.update(
      'hesaplar',
      {
        'sifre_hash': passwordHash,
        'sifre_degistir': mustChangePassword ? 1 : 0,
        'guncelleme_tarihi': DateTime.now().toIso8601String(),
      },
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> recordAccountLogin(int accountId) async {
    final now = DateTime.now().toIso8601String();
    await _database.update(
      'hesaplar',
      {'son_giris_tarihi': now, 'guncelleme_tarihi': now},
      where: 'id = ?',
      whereArgs: [accountId],
    );
  }

  Future<void> insertAccountAudit({
    int? targetAccountId,
    required String actionType,
    String? detail,
    int? actorAccountId,
  }) async {
    await _database.insert('hesap_denetcilik', {
      'hesap_id': targetAccountId,
      'islem_tur': actionType,
      'detay': detail,
      'yapan_hesap_id': actorAccountId,
      'olusturma_tarihi': DateTime.now().toIso8601String(),
    });
  }

  Future<void> close() async {
    await _db?.close();
  }

  static String buildDatabasePath(String rootDir) {
    return p.join(rootDir, 'myeduapp.sqlite');
  }
}
