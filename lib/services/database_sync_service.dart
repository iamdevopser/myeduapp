import 'dart:convert';

import 'dart:io';

import 'package:path/path.dart' as p;

import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import '../data/local/app_database.dart';
import 'file_service.dart';
import 'json_sync_service.dart';

/// MyEduApp SQLite <-> JSON veri senkronizasyon motoru.

class DatabaseSyncService {
  DatabaseSyncService(this.appDatabase);

  final AppDatabase appDatabase;

  static const int databaseVersion = 34;

  static const String myEduAppDataMarker = 'MyEduAppData';

  /// Tablo -> fiziksel dosya path kolonlari.

  static const Map<String, List<String>> pathColumnsByTable = {
    'dersler': ['resim_yolu'],

    'ders_gorselleri': ['resim_yolu'],

    'uniteler': ['resim_yolu'],

    'konular': ['resim_yolu'],

    'icerikler': ['dosya_yolu'],

    'soru_bankasi': ['gorsel_yolu', 'ses_yolu'],

    'sorular': ['ses_yolu'],
  };

  static const List<String> exportTables = [
    'siniflar',

    'dersler',

    'ders_gorselleri',

    'uniteler',

    'konular',

    'icerikler',

    'icerik_okuma',

    'etiketler',

    'icerik_etiketleri',

    'dokuman_klasorleri',

    'dokuman_klasor_ogeleri',

    'ayarlar',

    'ogretmen_son_islemler',

    'favoriler',

    'sinavlar',

    'sorular',

    'soru_bankasi',

    'notlar',

    'ogrenci_siniflar',

    'sinif_defteri_notlari',

    'ogrenciler',

    'veliler',

    'ogrenci_veliler',

    'ogrenci_devamsizlik',

    'ogrenci_kategoriler',

    'not_kolonlari',

    'not_kolon_tarih_aciklama',

    'ogrenci_notlari',

    'davranis_tanimlari',

    'ogrenci_davranis_kayitlari',

    'ogrenci_duyurular',

    'bildirimler',

    'hesaplar',

    'hesap_denetcilik',

    'mentorluk_siniflar',

    'mentorluk_etkinlikler',

    'mentorluk_etkinlik_ogrenciler',

    'mentorluk_davranis_raporlari',

    'mentorluk_notlar',

    'akademik_haftalik_ders',

    'akademik_haftalik_saat',

    'akademik_gunluk_plan',

    'akademik_yillik_plan',
  ];

  static bool isUrlPath(String path) {
    final trimmed = path.trim().toLowerCase();

    return trimmed.startsWith('http://') || trimmed.startsWith('https://');
  }

  static bool isAbsolutePath(String path) {
    if (p.isAbsolute(path)) {
      return true;
    }

    return RegExp(r'^[A-Za-z]:[/\\]').hasMatch(path.trim());
  }

  static String toForwardSlashPath(String path) {
    return path.replaceAll('\\', '/');
  }

  static bool isPathWithinRoot(String path, String root) {
    final absPath = p.normalize(path);

    final absRoot = p.normalize(root);

    if (absPath == absRoot) {
      return true;
    }

    final prefix = absRoot.endsWith(p.separator)
        ? absRoot
        : '$absRoot${p.separator}';

    return absPath.startsWith(prefix);
  }

  /// Backup icinde kullanilacak platform-bagimsiz relative path (forward slash).

  static String? toBackupRelativePath(String rawPath, String appDataRoot) {
    final trimmed = rawPath.trim();

    if (trimmed.isEmpty || isUrlPath(trimmed)) {
      return trimmed;
    }

    final rootNorm = p.normalize(appDataRoot);

    final normalized = p.normalize(trimmed);

    if (isPathWithinRoot(normalized, rootNorm)) {
      final relative = p.relative(normalized, from: rootNorm);

      return toForwardSlashPath(relative);
    }

    final forward = toForwardSlashPath(normalized);

    final marker = '/$myEduAppDataMarker/';

    final markerIndex = forward.indexOf(marker);

    if (markerIndex >= 0) {
      return forward.substring(markerIndex + marker.length);
    }

    if (!isAbsolutePath(normalized)) {
      return forward.startsWith('/') ? forward.substring(1) : forward;
    }

    // Uygulama disi mutlak path (or. kapak gorseli) oldugu gibi kalir.

    return trimmed;
  }

  /// Restore sirasinda backup relative path'i mevcut cihazin appDataRoot'una baglar.

  static String resolveImportPath(String rawPath, String appDataRoot) {
    final trimmed = rawPath.trim();

    if (trimmed.isEmpty || isUrlPath(trimmed)) {
      return trimmed;
    }

    final rootNorm = p.normalize(appDataRoot);

    final normalized = p.normalize(trimmed);

    if (isAbsolutePath(normalized)) {
      if (isPathWithinRoot(normalized, rootNorm)) {
        return normalized;
      }

      final forward = toForwardSlashPath(normalized);

      final marker = '/$myEduAppDataMarker/';

      final markerIndex = forward.indexOf(marker);

      if (markerIndex >= 0) {
        final relative = forward.substring(markerIndex + marker.length);

        return joinUnderAppDataRoot(rootNorm, relative);
      }

      // Eski Windows/Android mutlak path; dis path olarak korunur.

      return normalized;
    }

    return joinUnderAppDataRoot(rootNorm, trimmed);
  }

  /// Backup ZIP'teki relative path'i fiziksel dosya yoluna cevirir.

  static String physicalPathFromBackupRelative(
    String appDataRoot,

    String backupRelativePath,
  ) {
    return joinUnderAppDataRoot(appDataRoot, backupRelativePath);
  }

  static String joinUnderAppDataRoot(String appDataRoot, String relativePath) {
    final forward = toForwardSlashPath(relativePath.trim());

    if (forward.isEmpty) {
      return p.normalize(appDataRoot);
    }

    if (forward.split('/').any((segment) => segment == '..')) {
      throw FormatException('Gecersiz dosya yolu: $relativePath');
    }

    final resolved = p.normalize(
      p.join(appDataRoot, forward.replaceAll('/', p.separator)),
    );

    if (!isPathWithinRoot(resolved, appDataRoot)) {
      throw FormatException('Dosya yolu app data disinda: $relativePath');
    }

    return resolved;
  }

  bool _shouldNormalizeContentPath(Map<String, dynamic> row) {
    final type = row['tur'];

    if (type is String) {
      final normalizedType = type.toLowerCase();

      if (normalizedType == 'link' || normalizedType == 'text') {
        return false;
      }
    }

    final path = row['dosya_yolu'];

    if (path is String && isUrlPath(path)) {
      return false;
    }

    return true;
  }

  String _appDataRoot() {
    return p.dirname(appDatabase.database.path);
  }

  Map<String, dynamic> _prepareRowForExport(
    String table,

    Map<String, dynamic> row,
  ) {
    final result = Map<String, dynamic>.from(row);

    final columns = pathColumnsByTable[table];

    if (columns == null) {
      return result;
    }

    final appDataRoot = _appDataRoot();

    for (final column in columns) {
      final rawPath = result[column];

      if (rawPath is! String || rawPath.trim().isEmpty) {
        continue;
      }

      if (table == 'icerikler' && !_shouldNormalizeContentPath(result)) {
        continue;
      }

      final relative = toBackupRelativePath(rawPath, appDataRoot);

      if (relative != null) {
        result[column] = relative;
      }
    }

    return result;
  }

  Map<String, Object?> _prepareRowForImport(
    String table,

    Map<String, Object?> row, {

    String? rootPath,
  }) {
    final result = Map<String, Object?>.from(row);

    final columns = pathColumnsByTable[table];

    final appDataRoot = rootPath ?? _appDataRoot();

    if (columns != null) {
      for (final column in columns) {
        final rawPath = result[column];

        if (rawPath is! String || rawPath.trim().isEmpty) {
          continue;
        }

        if (table == 'icerikler' && !_shouldNormalizeContentPath(result)) {
          continue;
        }

        result[column] = resolveImportPath(rawPath, appDataRoot);
      }
    }

    if (table == 'ogrenci_notlari') {
      result['tarih'] ??= AppDatabase.scoreDateKey(DateTime.now());
    }

    return result;
  }

  Future<Map<String, dynamic>> exportData() async {
    final db = appDatabase.database;

    final data = <String, dynamic>{};

    for (final table in exportTables) {
      final rows = await db.query(table);

      data[table] = rows
          .map(
            (row) =>
                _prepareRowForExport(table, Map<String, dynamic>.from(row)),
          )
          .toList();
    }

    return JsonSyncService.createSyncData(
      data: data,

      databaseVersion: databaseVersion,
    );
  }

  Future<void> exportToFile(String filePath) async {
    final syncData = await exportData();

    await JsonSyncService.writeJsonFile(filePath: filePath, syncData: syncData);
  }

  Future<void> importFromFile(String filePath, {String? rootPath}) async {
    final syncData = await JsonSyncService.readJsonFile(filePath);

    final rawData = syncData['data'];

    if (rawData is! Map<String, dynamic>) {
      throw const FormatException('JSON icerisindeki data alani gecersiz.');
    }

    final data = <String, List<Map<String, Object?>>>{};

    for (final table in exportTables) {
      final value = rawData[table];

      if (value == null) {
        data[table] = <Map<String, Object?>>[];

        continue;
      }

      if (value is! List) {
        throw FormatException('JSON icerisindeki "$table" tablosu gecersiz.');
      }

      final rows = <Map<String, Object?>>[];

      for (final item in value) {
        if (item is! Map) {
          throw FormatException('"$table" tablosunda gecersiz kayit bulundu.');
        }

        final row = Map<String, Object?>.from(item);

        rows.add(_prepareRowForImport(table, row, rootPath: rootPath));
      }

      data[table] = rows;
    }

    await importData(data);
  }

  Future<void> importData(Map<String, List<Map<String, Object?>>> data) async {
    final db = appDatabase.database;

    await db.transaction((txn) async {
      const deleteOrder = [
        'mentorluk_notlar',

        'ogretmen_son_islemler',

        'mentorluk_davranis_raporlari',

        'mentorluk_etkinlik_ogrenciler',

        'mentorluk_etkinlikler',

        'mentorluk_siniflar',

        'ogrenci_notlari',

        'ogrenciler',

        'not_kolonlari',

        'ogrenci_kategoriler',

        'sorular',

        'favoriler',

        'icerik_etiketleri',

        'icerik_okuma',

        'dokuman_klasor_ogeleri',

        'dokuman_klasorleri',

        'notlar',

        'sinavlar',

        'soru_bankasi',

        'icerikler',

        'konular',

        'uniteler',

        'etiketler',

        'ders_gorselleri',

        'dersler',

        'ayarlar',

        'sinif_defteri_notlari',

        'ogrenci_siniflar',

        'siniflar',
      ];

      for (final table in deleteOrder) {
        await txn.delete(table);
      }

      for (final table in exportTables) {
        final rows = data[table] ?? const [];

        for (final row in rows) {
          await txn.insert(
            table,

            row,

            conflictAlgorithm: ConflictAlgorithm.replace,
          );
        }
      }
    });

    await appDatabase.ensurePlatformDefaults();
  }

  Future<String> exportAsJsonString() async {
    final syncData = await exportData();

    const encoder = JsonEncoder.withIndent('  ');

    return encoder.convert(syncData);
  }

  Future<void> importFromJsonString(
    String jsonString, {

    String? rootPath,
  }) async {
    if (jsonString.trim().isEmpty) {
      throw const FormatException('JSON verisi bos.');
    }

    final decoded = jsonDecode(jsonString);

    if (decoded is! Map<String, dynamic>) {
      throw const FormatException('Gecersiz MyEduApp JSON verisi.');
    }

    JsonSyncService.validateSyncData(decoded);

    final rawData = decoded['data'];

    if (rawData is! Map<String, dynamic>) {
      throw const FormatException('JSON data alani gecersiz.');
    }

    final data = <String, List<Map<String, Object?>>>{};

    for (final table in exportTables) {
      final value = rawData[table];

      if (value == null) {
        data[table] = <Map<String, Object?>>[];

        continue;
      }

      if (value is! List) {
        throw FormatException('"$table" tablosu gecersiz.');
      }

      final rows = <Map<String, Object?>>[];

      for (final item in value) {
        if (item is! Map) {
          throw FormatException('"$table" tablosunda gecersiz kayit bulundu.');
        }

        rows.add(
          _prepareRowForImport(
            table,

            Map<String, Object?>.from(item),

            rootPath: rootPath,
          ),
        );
      }

      data[table] = rows;
    }

    await importData(data);
  }

  Future<Map<String, int>> getRecordCounts() async {
    final db = appDatabase.database;

    final result = <String, int>{};

    for (final table in exportTables) {
      final rows = await db.rawQuery('SELECT COUNT(*) AS count FROM $table');

      result[table] = (rows.first['count'] as int?) ?? 0;
    }

    return result;
  }

  Future<void> validateFile(String filePath) async {
    final file = File(filePath);

    if (!await file.exists()) {
      throw FileSystemException('JSON dosyasi bulunamadi.', filePath);
    }

    await JsonSyncService.readJsonFile(filePath);
  }

  static String mediaCategoryForTable(String table) {
    switch (table) {
      case 'ders_gorselleri':
        return 'DersGorselleri';
      case 'dersler':
        return 'Dersler';
      case 'uniteler':
        return 'Uniteler';
      case 'konular':
        return 'Konular';
      case 'icerikler':
        return 'Icerikler';
      case 'soru_bankasi':
        return 'SoruBankasi';
      case 'sorular':
        return 'SinavSorulari';
      default:
        return 'Medya';
    }
  }

  static String? primaryKeyColumn(String table) {
    return table == 'ders_gorselleri' ? 'ad' : 'id';
  }

  static bool isPhysicalFileReference(
    String table,
    Map<String, Object?> row,
    String column,
    String path,
  ) {
    if (path.isEmpty || isUrlPath(path)) {
      return false;
    }

    if (table == 'icerikler' && column == 'dosya_yolu') {
      final type = row['tur'];
      if (type is String) {
        final normalizedType = type.toLowerCase();
        if (normalizedType == 'link' || normalizedType == 'text') {
          return false;
        }
      }
    }

    return true;
  }

  /// Harici absolute path'leri MyEduAppData altına kopyalar ve DB'yi günceller.
  Future<void> migrateExternalPathsForBackup({
    required String appDataRoot,
    required FileService fileService,
  }) async {
    final db = appDatabase.database;

    await db.transaction((txn) async {
      for (final entry in pathColumnsByTable.entries) {
        final table = entry.key;
        final pk = primaryKeyColumn(table);
        if (pk == null) {
          continue;
        }

        final rows = await txn.query(table);

        for (final row in rows) {
          final rowMap = Map<String, Object?>.from(row);

          for (final column in entry.value) {
            final rawPath = rowMap[column];
            if (rawPath is! String || rawPath.trim().isEmpty) {
              continue;
            }

            if (!isPhysicalFileReference(
              table,
              rowMap,
              column,
              rawPath.trim(),
            )) {
              continue;
            }

            final normalized = p.normalize(rawPath.trim());
            if (isPathWithinRoot(normalized, appDataRoot)) {
              continue;
            }

            final source = File(normalized);
            if (!await source.exists()) {
              continue;
            }

            final newPath = table == 'soru_bankasi' || table == 'sorular'
                ? await fileService.copyToQuestionBank(normalized)
                : await fileService.copyMediaToAppData(
                    sourcePath: normalized,
                    category: mediaCategoryForTable(table),
                  );

            await txn.update(
              table,
              {column: newPath},
              where: '$pk = ?',
              whereArgs: [row[pk]],
            );
          }
        }
      }
    });
  }

  /// Export verisinden backup'a dahil edilecek fiziksel dosya yollarını toplar.
  Future<Set<String>> collectPhysicalBackupPaths(String appDataRoot) async {
    final syncData = await exportData();
    final rawData = syncData['data'];

    if (rawData is! Map<String, dynamic>) {
      return {};
    }

    final files = <String>{};

    for (final entry in pathColumnsByTable.entries) {
      final table = entry.key;
      final rows = rawData[table];

      if (rows is! List) {
        continue;
      }

      for (final item in rows) {
        if (item is! Map) {
          continue;
        }

        final rowMap = Map<String, Object?>.from(item);

        for (final column in entry.value) {
          final rawPath = rowMap[column];
          if (rawPath is! String || rawPath.trim().isEmpty) {
            continue;
          }

          if (!isPhysicalFileReference(table, rowMap, column, rawPath.trim())) {
            continue;
          }

          final relative = toForwardSlashPath(rawPath.trim());
          final physicalPath = physicalPathFromBackupRelative(
            appDataRoot,
            relative,
          );

          if (await File(physicalPath).exists()) {
            files.add(relative);
          }
        }
      }
    }

    return files;
  }

  /// Database'deki tüm fiziksel dosya referanslarından eksik olanları sayar.
  Future<int> countMissingPhysicalFiles() async {
    final db = appDatabase.database;
    var missing = 0;

    for (final entry in pathColumnsByTable.entries) {
      final rows = await db.query(entry.key);

      for (final row in rows) {
        final rowMap = Map<String, Object?>.from(row);

        for (final column in entry.value) {
          final rawPath = rowMap[column];
          if (rawPath is! String || rawPath.trim().isEmpty) {
            continue;
          }

          if (!isPhysicalFileReference(
            entry.key,
            rowMap,
            column,
            rawPath.trim(),
          )) {
            continue;
          }

          if (!await File(rawPath.trim()).exists()) {
            missing++;
          }
        }
      }
    }

    return missing;
  }
}
