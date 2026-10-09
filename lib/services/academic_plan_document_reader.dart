import 'dart:io';

import 'package:archive/archive.dart';
import 'package:csv/csv.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';
import 'package:xml/xml.dart';

/// Reads academic plan files (Excel, Word, PDF, CSV, text) into plain text or tables.
class AcademicPlanDocumentReader {
  Future<String> readPlainText(String path) async {
    final ext = _extension(path);
    switch (ext) {
      case 'txt':
        return File(path).readAsString();
      case 'csv':
        final rows = await readTableRows(path);
        return rows.map((r) => r.join('\t')).join('\n');
      case 'docx':
        return _readDocxText(path);
      case 'pdf':
        return _readPdfText(path);
      case 'xlsx':
      case 'xls':
        final rows = await readTableRows(path);
        return rows.map((r) => r.join('\t')).join('\n');
      default:
        throw UnsupportedError(ext);
    }
  }

  Future<List<List<String>>> readTableRows(String path) async {
    final ext = _extension(path);
    if (ext == 'csv') {
      final content = await File(path).readAsString();
      final lines = content
          .split(RegExp(r'\r?\n'))
          .map((line) => line.trim())
          .where((line) => line.isNotEmpty)
          .toList();
      return lines
          .map((line) {
            final row = const CsvToListConverter().convert(line);
            if (row.isEmpty) return <String>[];
            return row.first.map((cell) => cell?.toString() ?? '').toList();
          })
          .where((row) => row.isNotEmpty)
          .toList();
    }
    if (ext == 'xlsx' || ext == 'xls') {
      return _readXlsxRows(path);
    }
    final text = await readPlainText(path);
    return _textBlocksToPseudoTable(text);
  }

  String _extension(String path) =>
      path.split('.').last.toLowerCase().split(RegExp(r'[^a-z0-9]')).first;

  Future<String> _readDocxText(String path) async {
    final bytes = await File(path).readAsBytes();
    final archive = ZipDecoder().decodeBytes(bytes);
    final file = archive.files.firstWhere(
      (element) => element.name == 'word/document.xml',
      orElse: () => ArchiveFile('word/document.xml', 0, []),
    );
    if (!file.isFile || file.content is! List<int>) {
      return '';
    }
    final xmlString = String.fromCharCodes(file.content as List<int>);
    final document = XmlDocument.parse(xmlString);
    final textNodes = document.findAllElements('w:t');
    return textNodes.map((e) => e.innerText).join('\n');
  }

  Future<String> _readPdfText(String path) async {
    final bytes = await File(path).readAsBytes();
    final document = PdfDocument(inputBytes: bytes);
    final extractor = PdfTextExtractor(document);
    final buffer = StringBuffer();
    for (var i = 0; i < document.pages.count; i++) {
      buffer.writeln(extractor.extractText(startPageIndex: i));
    }
    document.dispose();
    return buffer.toString();
  }

  Future<List<List<String>>> _readXlsxRows(String path) async {
    final bytes = await File(path).readAsBytes();
    final archive = ZipDecoder().decodeBytes(bytes);
    final shared = <String>[];
    final sharedFile = archive.files.cast<ArchiveFile?>().firstWhere(
      (f) => f?.name == 'xl/sharedStrings.xml',
      orElse: () => null,
    );
    if (sharedFile != null && sharedFile.isFile) {
      final doc = XmlDocument.parse(
        String.fromCharCodes(sharedFile.content as List<int>),
      );
      for (final si in doc.findAllElements('si')) {
        final parts = si.findAllElements('t').map((t) => t.innerText);
        shared.add(parts.join());
      }
    }

    final sheetFile = archive.files.firstWhere(
      (f) => f.name == 'xl/worksheets/sheet1.xml',
      orElse: () => ArchiveFile('xl/worksheets/sheet1.xml', 0, []),
    );
    if (!sheetFile.isFile) return [];

    final sheetDoc = XmlDocument.parse(
      String.fromCharCodes(sheetFile.content as List<int>),
    );
    final rowMap = <int, Map<int, String>>{};
    for (final cell in sheetDoc.findAllElements('c')) {
      final ref =
          cell.getAttribute('r') ??
          cell.getAttribute('ref'); // some exporters use different attrs
      if (ref == null) continue;
      final coords = _cellRef(ref);
      if (coords == null) continue;
      final value = _cellValue(cell, shared);
      rowMap.putIfAbsent(coords.row, () => {})[coords.col] = value;
    }

    if (rowMap.isEmpty) return [];
    final maxRow = rowMap.keys.reduce((a, b) => a > b ? a : b);
    final rows = <List<String>>[];
    for (var r = 1; r <= maxRow; r++) {
      final cols = rowMap[r];
      if (cols == null || cols.isEmpty) {
        rows.add([]);
        continue;
      }
      final maxCol = cols.keys.reduce((a, b) => a > b ? a : b);
      rows.add([for (var c = 1; c <= maxCol; c++) cols[c] ?? '']);
    }
    return rows;
  }

  String _cellValue(XmlElement cell, List<String> shared) {
    final type = cell.getAttribute('t');
    if (type == 'inlineStr' || cell.findElements('is').isNotEmpty) {
      return cell.findAllElements('t').map((t) => t.innerText).join();
    }
    final vNodes = cell.findElements('v');
    final v = vNodes.isNotEmpty
        ? vNodes.first.innerText
        : cell.getAttribute('v');
    if (v == null || v.isEmpty) return '';
    if (type == 's') {
      final index = int.tryParse(v);
      if (index != null && index >= 0 && index < shared.length) {
        return shared[index];
      }
    }
    return v;
  }

  ({int row, int col})? _cellRef(String ref) {
    final match = RegExp(r'^([A-Z]+)(\d+)$').firstMatch(ref);
    if (match == null) return null;
    final letters = match.group(1)!;
    final row = int.parse(match.group(2)!);
    var col = 0;
    for (var i = 0; i < letters.length; i++) {
      col = col * 26 + (letters.codeUnitAt(i) - 64);
    }
    return (row: row, col: col);
  }

  List<List<String>> _textBlocksToPseudoTable(String text) {
    final lines = text
        .split('\n')
        .map((l) => l.trim())
        .where((l) => l.isNotEmpty)
        .toList();
    if (lines.isEmpty) return [];
    return [lines];
  }
}
