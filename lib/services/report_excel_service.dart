import 'dart:convert';
import 'dart:io';

import 'package:archive/archive.dart';
import 'package:path/path.dart' as p;

class ReportExcelService {
  Future<void> writeWorkbook({
    required String path,
    required List<List<String>> detailRows,
    required List<List<String>> summaryRows,
    List<List<String>>? dailyAverageRows,
    List<List<String>>? monthlyOverallRows,
    List<List<String>>? monthlyCategoryRows,
  }) async {
    final extraSheets = <({String name, List<List<String>> rows})>[];
    if (dailyAverageRows != null && dailyAverageRows.length > 1) {
      extraSheets.add((name: 'GunlukOrtalama', rows: dailyAverageRows));
    }
    if (monthlyOverallRows != null && monthlyOverallRows.length > 1) {
      extraSheets.add((name: 'AylikPerformans', rows: monthlyOverallRows));
    }
    if (monthlyCategoryRows != null && monthlyCategoryRows.length > 1) {
      extraSheets.add((name: 'AylikKategori', rows: monthlyCategoryRows));
    }

    final archive = Archive();
    final contentTypes = utf8.encode(_contentTypes(extraSheets.length));
    archive.addFile(
      ArchiveFile('[Content_Types].xml', contentTypes.length, contentTypes),
    );
    final rels = utf8.encode(_rels);
    archive.addFile(ArchiveFile('_rels/.rels', rels.length, rels));
    final workbook = utf8.encode(_workbook(extraSheets));
    archive.addFile(ArchiveFile('xl/workbook.xml', workbook.length, workbook));
    final workbookRels = utf8.encode(_workbookRels(extraSheets.length));
    archive.addFile(
      ArchiveFile(
        'xl/_rels/workbook.xml.rels',
        workbookRels.length,
        workbookRels,
      ),
    );
    final sheet1 = utf8.encode(_sheetXml(detailRows));
    archive.addFile(
      ArchiveFile('xl/worksheets/sheet1.xml', sheet1.length, sheet1),
    );
    final sheet2 = utf8.encode(_sheetXml(summaryRows));
    archive.addFile(
      ArchiveFile('xl/worksheets/sheet2.xml', sheet2.length, sheet2),
    );
    for (var i = 0; i < extraSheets.length; i++) {
      final sheetIndex = i + 3;
      final sheetXml = utf8.encode(_sheetXml(extraSheets[i].rows));
      archive.addFile(
        ArchiveFile(
          'xl/worksheets/sheet$sheetIndex.xml',
          sheetXml.length,
          sheetXml,
        ),
      );
    }
    final encoded = ZipEncoder().encode(archive);
    if (encoded == null) {
      throw const FileSystemException('Excel dosyası oluşturulamadı.');
    }
    final directory = Directory(p.dirname(path));
    if (!await directory.exists()) {
      await directory.create(recursive: true);
    }
    await File(path).writeAsBytes(encoded, flush: true);
  }

  static String _contentTypes(int extraSheetCount) {
    final overrides = <String>[
      '<Override PartName="/xl/workbook.xml" ContentType="application/vnd.openxmlformats-officedocument.spreadsheetml.sheet.main+xml"/>',
      '<Override PartName="/xl/worksheets/sheet1.xml" ContentType="application/vnd.openxmlformats-officedocument.spreadsheetml.worksheet+xml"/>',
      '<Override PartName="/xl/worksheets/sheet2.xml" ContentType="application/vnd.openxmlformats-officedocument.spreadsheetml.worksheet+xml"/>',
    ];
    for (var i = 0; i < extraSheetCount; i++) {
      overrides.add(
        '<Override PartName="/xl/worksheets/sheet${i + 3}.xml" ContentType="application/vnd.openxmlformats-officedocument.spreadsheetml.worksheet+xml"/>',
      );
    }
    return '''<?xml version="1.0" encoding="UTF-8"?>
<Types xmlns="http://schemas.openxmlformats.org/package/2006/content-types">
  <Default Extension="rels" ContentType="application/vnd.openxmlformats-package.relationships+xml"/>
  <Default Extension="xml" ContentType="application/xml"/>
  ${overrides.join('\n  ')}
</Types>''';
  }

  static const _rels = '''<?xml version="1.0" encoding="UTF-8"?>
<Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships">
  <Relationship Id="rId1" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/officeDocument" Target="xl/workbook.xml"/>
</Relationships>''';

  static String _workbook(
    List<({String name, List<List<String>> rows})> extraSheets,
  ) {
    final sheets = <String>[
      '<sheet name="Kayitlar" sheetId="1" r:id="rId1"/>',
      '<sheet name="Ozet" sheetId="2" r:id="rId2"/>',
    ];
    for (var i = 0; i < extraSheets.length; i++) {
      final sheetId = i + 3;
      sheets.add(
        '<sheet name="${extraSheets[i].name}" sheetId="$sheetId" r:id="rId$sheetId"/>',
      );
    }
    return '''<?xml version="1.0" encoding="UTF-8"?>
<workbook xmlns="http://schemas.openxmlformats.org/spreadsheetml/2006/main" xmlns:r="http://schemas.openxmlformats.org/officeDocument/2006/relationships">
  <sheets>
    ${sheets.join('\n    ')}
  </sheets>
</workbook>''';
  }

  static String _workbookRels(int extraSheetCount) {
    final rels = <String>[
      '<Relationship Id="rId1" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/worksheet" Target="worksheets/sheet1.xml"/>',
      '<Relationship Id="rId2" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/worksheet" Target="worksheets/sheet2.xml"/>',
    ];
    for (var i = 0; i < extraSheetCount; i++) {
      final sheetId = i + 3;
      rels.add(
        '<Relationship Id="rId$sheetId" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/worksheet" Target="worksheets/sheet$sheetId.xml"/>',
      );
    }
    return '''<?xml version="1.0" encoding="UTF-8"?>
<Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships">
  ${rels.join('\n  ')}
</Relationships>''';
  }

  String _sheetXml(List<List<String>> rows) {
    final buffer = StringBuffer()
      ..writeln('<?xml version="1.0" encoding="UTF-8"?>')
      ..writeln(
        '<worksheet xmlns="http://schemas.openxmlformats.org/spreadsheetml/2006/main">',
      )
      ..writeln('<sheetData>');
    for (var r = 0; r < rows.length; r++) {
      buffer.writeln('<row r="${r + 1}">');
      for (var c = 0; c < rows[r].length; c++) {
        final ref = '${_columnName(c)}${r + 1}';
        buffer.writeln(
          '<c r="$ref" t="inlineStr"><is><t>${_escape(rows[r][c])}</t></is></c>',
        );
      }
      buffer.writeln('</row>');
    }
    buffer
      ..writeln('</sheetData>')
      ..writeln('</worksheet>');
    return buffer.toString();
  }

  String _columnName(int index) {
    var n = index;
    final chars = StringBuffer();
    do {
      chars.writeCharCode(65 + (n % 26));
      n = n ~/ 26 - 1;
    } while (n >= 0);
    return chars.toString().split('').reversed.join();
  }

  String _escape(String value) {
    return value
        .replaceAll('&', '&amp;')
        .replaceAll('<', '&lt;')
        .replaceAll('>', '&gt;')
        .replaceAll('"', '&quot;');
  }
}
