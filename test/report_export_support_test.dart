import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:my_edu_app/services/report_excel_service.dart';
import 'package:my_edu_app/utils/desktop_file_reveal.dart';
import 'package:my_edu_app/utils/path_utils.dart';
import 'package:my_edu_app/utils/report_export_support.dart';

void main() {
  test('sanitizeReportFileStem collapses tabs and multiple spaces', () {
    expect(
      sanitizeReportFileStem('Caraus\t\t  Bogdan'),
      'Caraus_Bogdan',
    );
  });

  test('sanitizeWindowsExportFilePath fixes basename in full path', () {
    expect(
      sanitizeWindowsExportFilePath(
        r'C:\out\7A\Caraus        Bogdan_6_7.pdf',
      ),
      r'C:\out\7A\Caraus_Bogdan_6_7.pdf',
    );
  });

  test('windowsExplorerSelectArgument quotes paths with spaces', () {
    expect(
      windowsExplorerSelectArgument(r'C:\Users\a\OneDrive\My Folder\rapor.pdf'),
      r'/select,"C:\Users\a\OneDrive\My Folder\rapor.pdf"',
    );
    expect(
      windowsExplorerSelectArgument(r'C:\out\rapor.pdf'),
      r'/select,C:\out\rapor.pdf',
    );
  });

  test('uniqueExportPathInDirectory avoids existing files', () async {
    final dir = await Directory.systemTemp.createTemp('myeduapp_bulk_pdf_');
    final first = await uniqueExportPathInDirectory(dir.path, 'Ali_1_6A.pdf');
    await File(first).writeAsString('a');
    final second = await uniqueExportPathInDirectory(dir.path, 'Ali_1_6A.pdf');
    expect(second, isNot(first));
    expect(second.contains('(2)'), isTrue);
    await dir.delete(recursive: true);
  });

  test('normalizeReportSavePath appends extension when missing', () {
    expect(
      normalizeReportSavePath(r'C:\out\rapor', 'pdf'),
      r'C:\out\rapor.pdf',
    );
    expect(
      normalizeReportSavePath(r'C:\out\rapor.pdf', 'pdf'),
      r'C:\out\rapor.pdf',
    );
    expect(
      normalizeReportSavePath(r'C:\out\rapor', 'xlsx'),
      r'C:\out\rapor.xlsx',
    );
  });

  test('ReportExcelService writes xlsx to disk', () async {
    final dir = await Directory.systemTemp.createTemp('myeduapp_xlsx_');
    final path = '${dir.path}${Platform.pathSeparator}test_report.xlsx';

    await ReportExcelService().writeWorkbook(
      path: path,
      detailRows: [
        ['A', 'B'],
        ['1', '2'],
      ],
      summaryRows: [
        ['S', 'V'],
        ['x', 'y'],
      ],
    );

    expect(await reportExportFileExists(path), isTrue);
    expect(await File(path).length(), greaterThan(100));
    await dir.delete(recursive: true);
  });
}
