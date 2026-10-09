import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:path/path.dart' as p;

import '../data/local/app_database.dart';
import '../models/app_role.dart';
import '../services/file_service.dart';
import '../utils/desktop_file_reveal.dart';
import 'notification_fanout_service.dart';

class SecretaryDocument {
  const SecretaryDocument({
    required this.id,
    required this.name,
    required this.type,
    required this.path,
    required this.createdAt,
    required this.updatedAt,
    required this.archived,
    required this.critical,
    this.description,
    this.category,
    this.scope,
  });

  final int id;
  final String name;
  final String type;
  final String path;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool archived;
  final bool critical;
  final String? description;
  final String? category;
  final String? scope;

  static SecretaryDocument fromMap(Map<String, Object?> row) {
    return SecretaryDocument(
      id: row['id'] as int,
      name: row['ad'] as String,
      type: row['tur'] as String,
      path: row['dosya_yolu'] as String,
      createdAt: DateTime.parse(row['olusturma_tarihi'] as String),
      updatedAt: DateTime.parse(
        (row['guncelleme_tarihi'] as String?) ??
            (row['olusturma_tarihi'] as String),
      ),
      archived: (row['arsiv'] as int? ?? 0) == 1,
      critical: (row['kritik'] as int? ?? 0) == 1,
      description: row['aciklama'] as String?,
      category: row['belge_kategori'] as String?,
      scope: row['belge_kapsam'] as String?,
    );
  }
}

class SecretaryDocumentService {
  SecretaryDocumentService(this._db, this._files);

  final AppDatabase _db;
  final FileService _files;

  Future<List<SecretaryDocument>> list({
    String? search,
    String? category,
    bool? archived,
    bool? critical,
  }) async {
    final rows = await _db.listSecretaryDocuments(
      search: search,
      category: category,
      archived: archived,
      critical: critical,
    );
    return rows.map(SecretaryDocument.fromMap).toList();
  }

  Future<SecretaryDocument?> getById(int id) async {
    if (!await _db.isSecretaryDocument(id)) return null;
    final row = await _db.getContentById(id);
    if (row == null) return null;
    return SecretaryDocument.fromMap(row);
  }

  Future<List<String>> distinctCategories() async {
    final docs = await this.list();
    final set = <String>{};
    for (final d in docs) {
      final c = d.category?.trim();
      if (c != null && c.isNotEmpty) set.add(c);
    }
    final categories = set.toList();
    categories.sort();
    return categories;
  }

  Future<int> createFromFile({
    required String title,
    required String sourcePath,
    String? description,
    String? category,
    String? scope,
  }) async {
    final path = await _files.copyFileToContentDir(
      sourcePath: sourcePath,
      className: AppDatabase.secretaryDocumentsClassName,
      lessonName: AppDatabase.secretaryDocumentsLessonName,
    );
    final type = _files.typeForFile(path);
    final id = await _db.insertSecretaryDocument(
      name: title,
      type: type,
      path: path,
      description: description,
      category: category,
      scope: scope,
    );
    await NotificationFanoutService(_db).onDocumentCreated(id);
    return id;
  }

  Future<void> updateMetadata({
    required int id,
    required String title,
    String? description,
    String? category,
    String? scope,
  }) {
    return _db.updateSecretaryDocumentMetadata(
      contentId: id,
      name: title,
      description: description,
      category: category,
      scope: scope,
    );
  }

  Future<bool> deleteForRole(int id, AppRole? role) {
    return _db.tryDeleteContentForRole(
      contentId: id,
      roleName: role?.name ?? '',
    );
  }

  Future<bool> archiveForSecretary(int id, AppRole? role) {
    return _db.tryArchiveSecretaryDocument(
      contentId: id,
      roleName: role?.name ?? '',
    );
  }

  Future<bool> openDocument(SecretaryDocument doc) async {
    final file = File(doc.path);
    if (!await file.exists()) return false;
    if (Platform.isWindows) {
      final result = await Process.run('cmd', [
        '/c',
        'start',
        '',
        file.absolute.path,
      ]);
      return result.exitCode == 0;
    }
    return revealSavedFileInSystemFileManager(doc.path);
  }

  Future<String?> pickSaveCopyPath(SecretaryDocument doc) async {
    final file = File(doc.path);
    if (!await file.exists()) return null;
    final suggested = p.basename(doc.path);
    return FilePicker.platform.saveFile(
      dialogTitle: 'İndir',
      fileName: suggested,
    );
  }

  Future<bool> copyToPath(SecretaryDocument doc, String targetPath) async {
    final file = File(doc.path);
    if (!await file.exists()) return false;
    await file.copy(targetPath);
    return true;
  }
}
