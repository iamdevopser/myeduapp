import '../data/local/app_database.dart';
import 'academic_plan_document_reader.dart';

enum AcademicPlanImportKind { daily, annual }

class AcademicPlanImportResult {
  const AcademicPlanImportResult({
    required this.parsedCount,
    required this.importedCount,
    required this.skippedCount,
  });

  final int parsedCount;
  final int importedCount;
  final int skippedCount;
}

class AcademicPlanImportService {
  AcademicPlanImportService({AcademicPlanDocumentReader? reader})
    : _reader = reader ?? AcademicPlanDocumentReader();

  final AcademicPlanDocumentReader _reader;

  Future<List<Map<String, Object?>>> parseFile({
    required String path,
    required AcademicPlanImportKind kind,
  }) async {
    final ext = path.split('.').last.toLowerCase();
    if (ext == 'csv' || ext == 'xlsx' || ext == 'xls') {
      final rows = await _reader.readTableRows(path);
      var plans = kind == AcademicPlanImportKind.daily
          ? _parseDailyTable(rows)
          : _parseAnnualTable(rows);
      if (plans.isEmpty) {
        final text = await _reader.readPlainText(path);
        plans = kind == AcademicPlanImportKind.daily
            ? _parseDailyText(text)
            : _parseAnnualText(text);
      }
      return plans;
    }
    final text = await _reader.readPlainText(path);
    return kind == AcademicPlanImportKind.daily
        ? _parseDailyText(text)
        : _parseAnnualText(text);
  }

  Future<AcademicPlanImportResult> importIntoDatabase({
    required AppDatabase db,
    required String path,
    required AcademicPlanImportKind kind,
  }) async {
    final plans = await parseFile(path: path, kind: kind);
    var imported = 0;
    var skipped = 0;
    for (final plan in plans) {
      if (!_hasMeaningfulContent(plan, kind)) {
        skipped++;
        continue;
      }
      if (kind == AcademicPlanImportKind.daily) {
        await db.insertDailyPlan(plan);
      } else {
        await db.insertAnnualPlan(plan);
      }
      imported++;
    }
    return AcademicPlanImportResult(
      parsedCount: plans.length,
      importedCount: imported,
      skippedCount: skipped,
    );
  }

  bool _hasMeaningfulContent(
    Map<String, Object?> plan,
    AcademicPlanImportKind kind,
  ) {
    if (kind == AcademicPlanImportKind.daily) {
      return _nonEmpty(plan['konu']) ||
          _nonEmpty(plan['hedefler']) ||
          _nonEmpty(plan['etkinlikler']) ||
          _nonEmpty(plan['notlar']);
    }
    return _nonEmpty(plan['unite_konu']) ||
        _nonEmpty(plan['hedefler']) ||
        _nonEmpty(plan['planlanan_donem']) ||
        _nonEmpty(plan['notlar']);
  }

  bool _nonEmpty(Object? value) =>
      value != null && value.toString().trim().isNotEmpty;

  List<Map<String, Object?>> _parseDailyTable(List<List<String>> rows) {
    if (rows.isEmpty) return [];
    final header = rows.first.map(_normalizeKey).toList();
    final plans = <Map<String, Object?>>[];
    for (var i = 1; i < rows.length; i++) {
      final row = rows[i];
      if (row.every((c) => c.trim().isEmpty)) continue;
      final map = <String, Object?>{};
      for (var c = 0; c < header.length && c < row.length; c++) {
        _applyDailyField(map, header[c], row[c].trim());
      }
      _applyDailyRowHeuristics(map, row);
      _ensureDailyDefaults(map);
      plans.add(map);
    }
    if (plans.isEmpty && rows.length == 1) {
      return _parseDailyText(rows.first.join('\n'));
    }
    return plans;
  }

  List<Map<String, Object?>> _parseAnnualTable(List<List<String>> rows) {
    if (rows.isEmpty) return [];
    final header = rows.first.map(_normalizeKey).toList();
    final plans = <Map<String, Object?>>[];
    for (var i = 1; i < rows.length; i++) {
      final row = rows[i];
      if (row.every((c) => c.trim().isEmpty)) continue;
      final map = <String, Object?>{};
      for (var c = 0; c < header.length && c < row.length; c++) {
        _applyAnnualField(map, header[c], row[c].trim());
      }
      _applyAnnualRowHeuristics(map, row);
      _ensureAnnualDefaults(map);
      plans.add(map);
    }
    if (plans.isEmpty) {
      return _parseAnnualTableByPosition(rows);
    }
    return plans;
  }

  List<Map<String, Object?>> _parseAnnualTableByPosition(
    List<List<String>> rows,
  ) {
    final plans = <Map<String, Object?>>[];
    var start = 0;
    if (rows.isNotEmpty && _rowLooksLikeAnnualHeader(rows.first)) {
      start = 1;
    }
    for (var i = start; i < rows.length; i++) {
      final row = rows[i];
      if (row.every((c) => c.trim().isEmpty)) continue;
      final map = <String, Object?>{};
      _fillAnnualFromRowPosition(map, row);
      _ensureAnnualDefaults(map);
      if (_hasMeaningfulContent(map, AcademicPlanImportKind.annual)) {
        plans.add(map);
      }
    }
    return plans;
  }

  bool _rowLooksLikeAnnualHeader(List<String> row) {
    final keys = row.map(_normalizeKey).where((k) => k.isNotEmpty);
    for (final key in keys) {
      if (key.contains('ogretim') ||
          key.contains('egitim') ||
          key.contains('academic') ||
          key.contains('unite') ||
          key.contains('unit') ||
          key.contains('donem') ||
          key.contains('period') ||
          key == 'year' ||
          key == 'yil') {
        return true;
      }
    }
    return false;
  }

  void _fillAnnualFromRowPosition(Map<String, Object?> map, List<String> row) {
    if (row.isEmpty) return;
    if (row.length >= 1 && _nonEmpty(row[0])) {
      map['ogretim_yili'] = row[0].trim();
    }
    if (row.length >= 2 && _nonEmpty(row[1])) {
      map['unite_konu'] = row[1].trim();
    }
    if (row.length >= 3 && _nonEmpty(row[2])) {
      map['planlanan_donem'] = row[2].trim();
    }
    if (row.length >= 4 && _nonEmpty(row[3])) {
      map['ders_saati'] = int.tryParse(
        row[3].trim().replaceAll(RegExp(r'[^\d]'), ''),
      );
    }
    if (row.length >= 5 && _nonEmpty(row[4])) {
      map['hedefler'] = row[4].trim();
    }
    if (row.length >= 6) {
      final tail = row.sublist(5).where((c) => c.trim().isNotEmpty).join(' ');
      if (tail.isNotEmpty) map['notlar'] = tail;
    }
    if (row.length == 1) {
      map['unite_konu'] = row[0].trim();
      map.remove('ogretim_yili');
    }
  }

  List<Map<String, Object?>> _parseDailyText(String text) {
    final sections = text.split(RegExp(r'\n-{3,}\n|\n\n+'));
    final plans = <Map<String, Object?>>[];
    for (final section in sections) {
      final map = _parseKeyValueSection(section);
      _ensureDailyDefaults(map);
      if (_hasMeaningfulContent(map, AcademicPlanImportKind.daily)) {
        plans.add(map);
      }
    }
    if (plans.isEmpty && text.trim().isNotEmpty) {
      final map = <String, Object?>{'notlar': text.trim()};
      _ensureDailyDefaults(map);
      plans.add(map);
    }
    return plans;
  }

  List<Map<String, Object?>> _parseAnnualText(String text) {
    final sections = text.split(RegExp(r'\n-{3,}\n|\n\n+'));
    final plans = <Map<String, Object?>>[];
    for (final section in sections) {
      final map = _parseKeyValueSection(section);
      _ensureAnnualDefaults(map);
      if (_hasMeaningfulContent(map, AcademicPlanImportKind.annual)) {
        plans.add(map);
      }
    }
    if (plans.isEmpty && text.trim().isNotEmpty) {
      final map = <String, Object?>{
        'unite_konu': text.trim().split('\n').first,
      };
      _ensureAnnualDefaults(map);
      if (text.contains('\n')) {
        map['notlar'] = text.trim();
      }
      plans.add(map);
    }
    return plans;
  }

  Map<String, Object?> _parseKeyValueSection(String section) {
    final map = <String, Object?>{};
    for (final line in section.split('\n')) {
      final trimmed = line.trim();
      if (trimmed.isEmpty) continue;
      final sep = trimmed.indexOf(':');
      if (sep <= 0) continue;
      final key = _normalizeKey(trimmed.substring(0, sep));
      final value = trimmed.substring(sep + 1).trim();
      _applyDailyField(map, key, value);
      _applyAnnualField(map, key, value);
    }
    return map;
  }

  void _applyDailyField(Map<String, Object?> map, String key, String value) {
    switch (key) {
      case 'tarih':
      case 'date':
        map['tarih'] = value;
      case 'konu':
      case 'topic':
        map['konu'] = value;
      case 'hedefler':
      case 'objectives':
      case 'learningobjectives':
        map['hedefler'] = value;
      case 'etkinlikler':
      case 'activities':
        map['etkinlikler'] = value;
      case 'materyaller':
      case 'materials':
        map['materyaller'] = value;
      case 'odev':
      case 'homework':
      case 'homeworks':
        map['odev'] = value;
      case 'notlar':
      case 'notes':
      case 'note':
        map['notlar'] = value;
      case 'sinif':
      case 'class':
      case 'classgroup':
      case 'sinifmetin':
        map['sinif_metin'] = value;
      case 'ders':
      case 'subject':
      case 'konumetin':
      case 'brans':
        map['konu_metin'] = value;
      default:
        break;
    }
  }

  void _applyAnnualField(Map<String, Object?> map, String key, String value) {
    switch (key) {
      case 'ogretimyili':
      case 'egitimyili':
      case 'academicyear':
      case 'year':
      case 'yil':
        map['ogretim_yili'] = value;
      case 'unite':
      case 'unitekonu':
      case 'unit':
      case 'unittopic':
      case 'topic':
      case 'konu':
        map['unite_konu'] = value;
      case 'planlanandonem':
      case 'period':
      case 'plannedperiod':
      case 'week':
        map['planlanan_donem'] = value;
      case 'derssaati':
      case 'lessonhours':
      case 'hours':
        map['ders_saati'] = int.tryParse(
          value.replaceAll(RegExp(r'[^\d]'), ''),
        );
      case 'hedefler':
      case 'objectives':
        map['hedefler'] = value;
      case 'notlar':
      case 'notes':
        map['notlar'] = value;
      case 'sinif':
      case 'class':
        map['sinif_metin'] = value;
      case 'ders':
      case 'subject':
        map['konu_metin'] = value;
      default:
        break;
    }
  }

  void _ensureDailyDefaults(Map<String, Object?> map) {
    map['tarih'] ??= AppDatabase.scoreDateKey(DateTime.now());
    map['konu_metin'] ??= '';
    map['sinif_metin'] ??= '';
    map['konu'] ??= '';
    map['hedefler'] ??= '';
    map['etkinlikler'] ??= '';
    map['materyaller'] ??= '';
    map['odev'] ??= '';
    map['notlar'] ??= '';
  }

  void _ensureAnnualDefaults(Map<String, Object?> map) {
    final year = DateTime.now().year;
    map['ogretim_yili'] ??= '$year-${year + 1}';
    map['konu_metin'] ??= '';
    map['sinif_metin'] ??= '';
    map['unite_konu'] ??= '';
    map['planlanan_donem'] ??= '';
    map['hedefler'] ??= '';
    map['notlar'] ??= '';
  }

  void _applyDailyRowHeuristics(Map<String, Object?> map, List<String> row) {
    if (row.isEmpty) return;
    final dateLike = RegExp(r'^\d{4}-\d{2}-\d{2}$');
    if (dateLike.hasMatch(row.first.trim())) {
      map['tarih'] = row.first.trim();
    }
  }

  void _applyAnnualRowHeuristics(Map<String, Object?> map, List<String> row) {
    if (row.length >= 2 && _nonEmpty(row[1])) {
      map['unite_konu'] ??= row[1].trim();
    }
    if (row.length >= 1 && _nonEmpty(row[0])) {
      map['ogretim_yili'] ??= row[0].trim();
    }
  }

  String _normalizeKey(String raw) {
    var s = raw.replaceAll('\uFEFF', '').toLowerCase().trim();
    const tr = {
      'ı': 'i',
      'ğ': 'g',
      'ü': 'u',
      'ş': 's',
      'ö': 'o',
      'ç': 'c',
      'İ': 'i',
      'Ğ': 'g',
      'Ü': 'u',
      'Ş': 's',
      'Ö': 'o',
      'Ç': 'c',
    };
    for (final entry in tr.entries) {
      s = s.replaceAll(entry.key, entry.value);
    }
    return s.replaceAll(RegExp(r'[^a-z0-9]'), '');
  }
}
