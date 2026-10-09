import 'dart:convert';
import 'dart:io';

/// MyEduApp cihazlar arası JSON veri aktarım altyapısı.
class JsonSyncService {
  static const String formatName = 'MyEduApp';
  static const int formatVersion = 1;

  static Map<String, dynamic> createSyncData({
    required Map<String, dynamic> data,
    String? appVersion,
    int databaseVersion = 9,
  }) {
    return {
      'format': formatName,
      'formatVersion': formatVersion,
      'appVersion': appVersion,
      'databaseVersion': databaseVersion,
      'exportedAt': DateTime.now().toUtc().toIso8601String(),
      'data': data,
    };
  }

  static Future<void> writeJsonFile({
    required String filePath,
    required Map<String, dynamic> syncData,
  }) async {
    final file = File(filePath);

    const encoder = JsonEncoder.withIndent('  ');
    final jsonString = encoder.convert(syncData);

    await file.writeAsString(jsonString, flush: true);
  }

  static Future<Map<String, dynamic>> readJsonFile(String filePath) async {
    final file = File(filePath);

    if (!await file.exists()) {
      throw FileSystemException('Senkronizasyon dosyası bulunamadı.', filePath);
    }

    final content = await file.readAsString();

    if (content.trim().isEmpty) {
      throw const FormatException('Senkronizasyon dosyası boş.');
    }

    final decoded = jsonDecode(content);

    if (decoded is! Map<String, dynamic>) {
      throw const FormatException('Geçersiz MyEduApp JSON formatı.');
    }

    validateSyncData(decoded);

    return decoded;
  }

  static void validateSyncData(Map<String, dynamic> syncData) {
    if (syncData['format'] != formatName) {
      throw const FormatException(
        'Bu dosya geçerli bir MyEduApp senkronizasyon dosyası değil.',
      );
    }

    final version = syncData['formatVersion'];

    if (version is! int) {
      throw const FormatException('Senkronizasyon format sürümü bulunamadı.');
    }

    if (version > formatVersion) {
      throw FormatException(
        'Bu senkronizasyon dosyası daha yeni bir MyEduApp '
        'sürümüne ait. Dosya formatı: , '
        'desteklenen format: .',
      );
    }

    final data = syncData['data'];

    if (data is! Map<String, dynamic>) {
      throw const FormatException(
        'Senkronizasyon verileri bulunamadı veya geçersiz.',
      );
    }
  }
}
