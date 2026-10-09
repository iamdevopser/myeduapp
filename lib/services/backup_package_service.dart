import 'dart:convert';
import 'dart:io';

import 'package:archive/archive.dart';
import 'package:crypto/crypto.dart';
import 'package:path/path.dart' as p;

import '../data/local/app_database.dart';
import 'database_sync_service.dart';
import 'file_service.dart';

/// Backup bütünlük / checksum doğrulama hatası.
class BackupIntegrityException implements Exception {
  BackupIntegrityException(this.message);

  final String message;

  @override
  String toString() => message;
}

/// Güvenli restore oturumu (snapshot + staging).
class BackupRestoreSession {
  BackupRestoreSession({
    required this.snapshotRoot,
    required this.stagingRoot,
    required this.databaseJson,
    required this.manifest,
    required this.expectedFileCount,
    required this.extractedFileCount,
  });

  final Directory snapshotRoot;
  final Directory stagingRoot;
  final String databaseJson;
  final Map<String, dynamic> manifest;
  final int expectedFileCount;
  final int extractedFileCount;

  int get zipMissingFileCount =>
      (expectedFileCount - extractedFileCount).clamp(0, expectedFileCount);

  /// Staging dosyalarını gerçek MyEduAppData konumuna uygular.
  Future<void> applyStagingToAppData(String appDataPath) async {
    final filesDir = Directory(p.join(stagingRoot.path, 'files'));
    if (!await filesDir.exists()) {
      return;
    }

    await for (final entity in filesDir.list(recursive: true)) {
      if (entity is! File) {
        continue;
      }

      final relative = p.relative(entity.path, from: filesDir.path);
      final forward = BackupPackageService.toBackupZipEntryPath(relative);
      final targetPath = DatabaseSyncService.physicalPathFromBackupRelative(
        appDataPath,
        forward,
      );
      final targetFile = File(targetPath);
      await targetFile.parent.create(recursive: true);
      await entity.copy(targetFile.path);
    }
  }

  /// Başarılı restore sonrası snapshot ve staging'i temizler.
  Future<void> commit() async {
    if (await snapshotRoot.exists()) {
      await snapshotRoot.delete(recursive: true);
    }
    if (await stagingRoot.exists()) {
      await stagingRoot.delete(recursive: true);
    }
  }

  /// Hata durumunda snapshot'tan geri yükler.
  Future<void> rollback(String appDataPath) async {
    final snapshotData = Directory(p.join(snapshotRoot.path, 'app_data'));
    if (!await snapshotData.exists()) {
      throw BackupIntegrityException('Snapshot verisi bulunamadi.');
    }

    await BackupPackageService.replaceDirectoryContents(
      Directory(appDataPath),
      snapshotData,
    );
  }

  BackupPackageRestoreResult buildResult({
    required int missingPhysicalFileCount,
  }) {
    final totalMissing = zipMissingFileCount + missingPhysicalFileCount;
    return BackupPackageRestoreResult(
      databaseJson: databaseJson,
      databaseJsonBytes: utf8.encode(databaseJson).length,
      expectedFileCount: expectedFileCount,
      restoredFileCount: extractedFileCount,
      missingFileCount: totalMissing,
      zipMissingFileCount: zipMissingFileCount,
      missingPhysicalFileCount: missingPhysicalFileCount,
    );
  }
}

/// MyEduApp database + fiziksel dosya backup paketi.
class BackupPackageService {
  BackupPackageService(this.appDatabase, this.fileService);

  final AppDatabase appDatabase;
  final FileService fileService;

  static const String packageFormat = 'MyEduAppBackup';
  static const int packageVersion = 1;
  static const String checksumAlgorithm = 'sha256';

  static String toBackupZipEntryPath(String relativePath) {
    return DatabaseSyncService.toForwardSlashPath(relativePath.trim());
  }

  static String sha256Hex(List<int> bytes) {
    return sha256.convert(bytes).toString();
  }

  String resolveRelativePath(String appDataPath, String relativePath) {
    return DatabaseSyncService.physicalPathFromBackupRelative(
      appDataPath,
      relativePath,
    );
  }

  static Future<void> replaceDirectoryContents(
    Directory target,
    Directory source,
  ) async {
    if (await target.exists()) {
      await for (final entity in target.list()) {
        await entity.delete(recursive: true);
      }
    } else {
      await target.create(recursive: true);
    }
    await _copyDirectory(source, target);
  }

  static Future<void> _copyDirectory(Directory source, Directory target) async {
    if (!await target.exists()) {
      await target.create(recursive: true);
    }
    await for (final entity in source.list(recursive: false)) {
      if (entity is Directory) {
        final newDir = Directory(p.join(target.path, p.basename(entity.path)));
        await _copyDirectory(entity, newDir);
      } else if (entity is File) {
        final newFile = File(p.join(target.path, p.basename(entity.path)));
        await entity.copy(newFile.path);
      }
    }
  }

  static Future<Directory> _createSnapshot(String appDataPath) async {
    final snapshotRoot = await Directory.systemTemp.createTemp(
      'myeduapp_snapshot_',
    );
    final snapshotData = Directory(p.join(snapshotRoot.path, 'app_data'));
    final source = Directory(appDataPath);
    if (!await source.exists()) {
      await source.create(recursive: true);
    }
    await _copyDirectory(source, snapshotData);
    return snapshotRoot;
  }

  Future<List<String>> collectPhysicalBackupFiles(String appDataPath) async {
    final syncService = DatabaseSyncService(appDatabase);
    final files = await syncService.collectPhysicalBackupPaths(appDataPath);
    return files.toList();
  }

  /// ZIP içeriğini oluşturur; dosyaya yazmaz (Android SAF save için).
  Future<BackupPackageBuildResult> buildPackageBytes({
    required String appDataPath,
  }) async {
    final syncService = DatabaseSyncService(appDatabase);

    await syncService.migrateExternalPathsForBackup(
      appDataRoot: appDataPath,
      fileService: fileService,
    );

    final syncData = await syncService.exportData();

    final contentFiles = await collectPhysicalBackupFiles(appDataPath);

    final fileChecksums = <String, String>{};
    final packagedFileBytes = <String, List<int>>{};

    for (final relativePath in contentFiles) {
      final physicalPath = resolveRelativePath(appDataPath, relativePath);
      final file = File(physicalPath);
      if (!await file.exists()) {
        continue;
      }
      final bytes = await file.readAsBytes();
      fileChecksums[relativePath] = sha256Hex(bytes);
      packagedFileBytes[relativePath] = bytes;
    }

    final manifest = <String, dynamic>{
      'format': packageFormat,
      'formatVersion': packageVersion,
      'createdAt': DateTime.now().toUtc().toIso8601String(),
      'databaseVersion': syncData['databaseVersion'],
      'databaseFile': 'database.json',
      'filesDirectory': 'files',
      'fileCount': contentFiles.length,
      if (fileChecksums.isNotEmpty) ...{
        'checksumAlgorithm': checksumAlgorithm,
        'fileChecksums': fileChecksums,
      },
    };

    final archive = Archive();

    final databaseJson = const JsonEncoder.withIndent('  ').convert(syncData);
    final databaseBytes = utf8.encode(databaseJson);

    archive.addFile(
      ArchiveFile('database.json', databaseBytes.length, databaseBytes),
    );

    final manifestJson = const JsonEncoder.withIndent('  ').convert(manifest);
    final manifestBytes = utf8.encode(manifestJson);

    archive.addFile(
      ArchiveFile('manifest.json', manifestBytes.length, manifestBytes),
    );

    var packagedFiles = 0;
    var missingFiles = 0;

    for (final relativePath in contentFiles) {
      final bytes = packagedFileBytes[relativePath];
      if (bytes == null) {
        missingFiles++;
        continue;
      }

      archive.addFile(ArchiveFile('files/$relativePath', bytes.length, bytes));
      packagedFiles++;
    }

    final encoded = ZipEncoder().encode(archive);

    if (encoded == null) {
      throw Exception('ZIP paketi olusturulamadi.');
    }

    return BackupPackageBuildResult(
      encoded: encoded,
      databaseJsonBytes: databaseBytes.length,
      expectedFileCount: contentFiles.length,
      packagedFileCount: packagedFiles,
      missingFileCount: missingFiles,
    );
  }

  Future<BackupPackageResult> createPackage({
    required String outputPath,
    required String appDataPath,
  }) async {
    final built = await buildPackageBytes(appDataPath: appDataPath);

    final outputFile = File(outputPath);

    await outputFile.parent.create(recursive: true);
    await outputFile.writeAsBytes(built.encoded, flush: true);

    return BackupPackageResult(
      outputPath: outputPath,
      databaseJsonBytes: built.databaseJsonBytes,
      expectedFileCount: built.expectedFileCount,
      packagedFileCount: built.packagedFileCount,
      missingFileCount: built.missingFileCount,
      packageSize: built.packageSize,
    );
  }

  /// Güvenli restore: snapshot + staging + checksum doğrulama.
  ///
  /// Database kapalı olmalıdır. Snapshot başarısızsa exception fırlatır.
  Future<BackupRestoreSession> beginSafeRestore({
    required String packagePath,
    required String appDataPath,
  }) async {
    final prepared = await _readAndValidatePackage(packagePath);

    Directory snapshotRoot;
    try {
      snapshotRoot = await _createSnapshot(appDataPath);
    } catch (e) {
      throw BackupIntegrityException(
        'Geri yukleme oncesi snapshot olusturulamadi: $e',
      );
    }

    final stagingRoot = await Directory.systemTemp.createTemp(
      'myeduapp_staging_',
    );

    try {
      final extractedFileCount = await _extractArchiveFilesToStaging(
        archive: prepared.archive,
        stagingRoot: stagingRoot,
        appDataPath: appDataPath,
      );

      await _verifyStagingChecksums(
        manifest: prepared.manifest,
        stagingRoot: stagingRoot,
      );

      return BackupRestoreSession(
        snapshotRoot: snapshotRoot,
        stagingRoot: stagingRoot,
        databaseJson: prepared.databaseJson,
        manifest: prepared.manifest,
        expectedFileCount:
            (prepared.manifest['fileCount'] as num?)?.toInt() ?? 0,
        extractedFileCount: extractedFileCount,
      );
    } catch (e) {
      if (await stagingRoot.exists()) {
        await stagingRoot.delete(recursive: true);
      }
      if (await snapshotRoot.exists()) {
        await snapshotRoot.delete(recursive: true);
      }
      rethrow;
    }
  }

  /// Database'deki tüm fiziksel dosya referanslarından eksik olanları sayar.
  Future<int> countMissingPhysicalFiles() async {
    final syncService = DatabaseSyncService(appDatabase);
    return syncService.countMissingPhysicalFiles();
  }

  /// ZIP backup paketini belirtilen hedefe geri yükler (araç/test kullanımı).
  Future<BackupPackageRestoreResult> restorePackage({
    required String packagePath,
    required String appDataPath,
    bool importDatabase = true,
  }) async {
    final prepared = await _readAndValidatePackage(packagePath);

    final stagingRoot = await Directory.systemTemp.createTemp(
      'myeduapp_restore_staging_',
    );

    try {
      final extractedFileCount = await _extractArchiveFilesToStaging(
        archive: prepared.archive,
        stagingRoot: stagingRoot,
        appDataPath: appDataPath,
      );

      await _verifyStagingChecksums(
        manifest: prepared.manifest,
        stagingRoot: stagingRoot,
      );

      final filesDir = Directory(p.join(stagingRoot.path, 'files'));
      if (await filesDir.exists()) {
        await for (final entity in filesDir.list(recursive: true)) {
          if (entity is! File) {
            continue;
          }
          final relative = p.relative(entity.path, from: filesDir.path);
          final forward = toBackupZipEntryPath(relative);
          final targetPath = resolveRelativePath(appDataPath, forward);
          final targetFile = File(targetPath);
          await targetFile.parent.create(recursive: true);
          await entity.copy(targetFile.path);
        }
      }

      if (importDatabase) {
        final syncService = DatabaseSyncService(appDatabase);
        await syncService.importFromJsonString(
          prepared.databaseJson,
          rootPath: appDataPath,
        );
      }

      final expectedFileCount =
          (prepared.manifest['fileCount'] as num?)?.toInt() ?? 0;

      return BackupPackageRestoreResult(
        databaseJson: prepared.databaseJson,
        databaseJsonBytes: utf8.encode(prepared.databaseJson).length,
        expectedFileCount: expectedFileCount,
        restoredFileCount: extractedFileCount,
        missingFileCount: (expectedFileCount - extractedFileCount).clamp(
          0,
          expectedFileCount,
        ),
        zipMissingFileCount: (expectedFileCount - extractedFileCount).clamp(
          0,
          expectedFileCount,
        ),
        missingPhysicalFileCount: 0,
      );
    } finally {
      if (await stagingRoot.exists()) {
        await stagingRoot.delete(recursive: true);
      }
    }
  }

  Future<
    ({Archive archive, Map<String, dynamic> manifest, String databaseJson})
  >
  _readAndValidatePackage(String packagePath) async {
    final packageFile = File(packagePath);

    if (!await packageFile.exists()) {
      throw FileSystemException('Backup paketi bulunamadi.', packagePath);
    }

    final archiveBytes = await packageFile.readAsBytes();
    final archive = ZipDecoder().decodeBytes(archiveBytes);

    ArchiveFile? manifestFile;
    ArchiveFile? databaseFile;

    for (final file in archive) {
      if (file.name == 'manifest.json') {
        manifestFile = file;
      } else if (file.name == 'database.json') {
        databaseFile = file;
      }
    }

    if (manifestFile == null) {
      throw const FormatException('Backup paketinde manifest.json bulunamadi.');
    }

    if (databaseFile == null) {
      throw const FormatException('Backup paketinde database.json bulunamadi.');
    }

    final manifestBytes = manifestFile.content as List<int>;
    final manifestJson = utf8.decode(manifestBytes);
    final manifest = jsonDecode(manifestJson);

    if (manifest is! Map<String, dynamic>) {
      throw const FormatException('manifest.json gecersiz.');
    }

    if (manifest['format'] != packageFormat) {
      throw FormatException('Desteklenmeyen backup formati: ');
    }

    if (manifest['formatVersion'] != packageVersion) {
      throw FormatException('Desteklenmeyen backup surumu: ');
    }

    final databaseBytes = databaseFile.content as List<int>;
    final databaseJson = utf8.decode(databaseBytes);

    return (archive: archive, manifest: manifest, databaseJson: databaseJson);
  }

  Future<int> _extractArchiveFilesToStaging({
    required Archive archive,
    required Directory stagingRoot,
    required String appDataPath,
  }) async {
    var extractedFileCount = 0;

    for (final file in archive) {
      if (!file.name.startsWith('files/')) {
        continue;
      }

      final relativePath = file.name.substring('files/'.length);

      if (relativePath.trim().isEmpty) {
        continue;
      }

      final forward = toBackupZipEntryPath(relativePath);
      DatabaseSyncService.physicalPathFromBackupRelative(appDataPath, forward);

      final targetPath = p.join(
        stagingRoot.path,
        'files',
        forward.replaceAll('/', p.separator),
      );
      final targetFile = File(targetPath);

      await targetFile.parent.create(recursive: true);

      final bytes = file.content as List<int>;
      await targetFile.writeAsBytes(bytes, flush: true);

      extractedFileCount++;
    }

    return extractedFileCount;
  }

  Future<void> _verifyStagingChecksums({
    required Map<String, dynamic> manifest,
    required Directory stagingRoot,
  }) async {
    final rawChecksums = manifest['fileChecksums'];
    if (rawChecksums == null) {
      return;
    }

    if (rawChecksums is! Map) {
      throw BackupIntegrityException('manifest checksum verisi gecersiz.');
    }

    final algorithm = manifest['checksumAlgorithm'];
    if (algorithm != null && algorithm != checksumAlgorithm) {
      throw BackupIntegrityException(
        'Desteklenmeyen checksum algoritmasi: $algorithm',
      );
    }

    final filesDir = Directory(p.join(stagingRoot.path, 'files'));

    for (final entry in rawChecksums.entries) {
      final relativePath = toBackupZipEntryPath(entry.key.toString());
      final expected = entry.value?.toString();
      if (expected == null || expected.isEmpty) {
        continue;
      }

      final physicalPath = p.join(
        filesDir.path,
        relativePath.replaceAll('/', p.separator),
      );
      final file = File(physicalPath);

      if (!await file.exists()) {
        throw BackupIntegrityException('Backup dosyasi eksik: $relativePath');
      }

      final bytes = await file.readAsBytes();
      final actual = sha256Hex(bytes);

      if (actual != expected) {
        throw BackupIntegrityException(
          'Backup dosyasi bozuk veya degistirilmis: $relativePath',
        );
      }
    }
  }
}

class BackupPackageBuildResult {
  const BackupPackageBuildResult({
    required this.encoded,
    required this.databaseJsonBytes,
    required this.expectedFileCount,
    required this.packagedFileCount,
    required this.missingFileCount,
  });

  final List<int> encoded;
  final int databaseJsonBytes;
  final int expectedFileCount;
  final int packagedFileCount;
  final int missingFileCount;

  int get packageSize => encoded.length;

  bool get success =>
      missingFileCount == 0 && packagedFileCount == expectedFileCount;
}

class BackupPackageResult {
  const BackupPackageResult({
    required this.outputPath,
    required this.databaseJsonBytes,
    required this.expectedFileCount,
    required this.packagedFileCount,
    required this.missingFileCount,
    required this.packageSize,
  });

  final String outputPath;
  final int databaseJsonBytes;
  final int expectedFileCount;
  final int packagedFileCount;
  final int missingFileCount;
  final int packageSize;

  bool get success =>
      missingFileCount == 0 && packagedFileCount == expectedFileCount;
}

class BackupPackageRestoreResult {
  const BackupPackageRestoreResult({
    this.databaseJson,
    required this.databaseJsonBytes,
    required this.expectedFileCount,
    required this.restoredFileCount,
    required this.missingFileCount,
    this.zipMissingFileCount = 0,
    this.missingPhysicalFileCount = 0,
  });

  final String? databaseJson;
  final int databaseJsonBytes;
  final int expectedFileCount;
  final int restoredFileCount;
  final int missingFileCount;
  final int zipMissingFileCount;
  final int missingPhysicalFileCount;

  bool get success =>
      missingFileCount == 0 && restoredFileCount == expectedFileCount;
}
