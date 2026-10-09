import 'dart:developer' as developer;
import 'dart:io';
import 'dart:typed_data';

import 'package:path/path.dart' as p;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../data/models/content_with_tags.dart';
import 'student_report_pdf_labels.dart';

/// Result of writing PDF bytes to disk (student report export).
class PdfBytesWriteResult {
  const PdfBytesWriteResult({
    required this.savedPath,
    required this.sharingRetryCount,
  });

  final String savedPath;
  final int sharingRetryCount;
}

class PdfLabels {
  const PdfLabels({
    required this.classLabel,
    required this.lessonLabel,
    required this.contentsTitle,
    required this.emptyMessage,
  });

  final String classLabel;
  final String lessonLabel;
  final String contentsTitle;
  final String emptyMessage;
}

class PdfService {
  Future<void> exportLessonPdf({
    required String className,
    required String lessonName,
    required List<ContentWithTags> contents,
    required String targetPath,
    required PdfLabels labels,
  }) async {
    final doc = pw.Document();
    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        build: (context) => [
          pw.Text('MyEduApp', style: pw.TextStyle(fontSize: 18)),
          pw.SizedBox(height: 8),
          pw.Text('${labels.classLabel}: $className'),
          pw.Text('${labels.lessonLabel}: $lessonName'),
          pw.SizedBox(height: 12),
          pw.Text(labels.contentsTitle, style: pw.TextStyle(fontSize: 14)),
          pw.SizedBox(height: 8),
          if (contents.isEmpty)
            pw.Text(labels.emptyMessage)
          else
            pw.Column(
              children: contents
                  .map(
                    (item) => pw.Container(
                      margin: const pw.EdgeInsets.only(bottom: 6),
                      child: pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Text('• ${item.content.name}'),
                          pw.Text(
                            '  Etiketler: ${item.tags.map((e) => e.name).join(', ')}',
                            style: pw.TextStyle(fontSize: 10),
                          ),
                        ],
                      ),
                    ),
                  )
                  .toList(),
            ),
        ],
      ),
    );
    final file = File(targetPath);
    await file.writeAsBytes(await doc.save());
  }

  static const int _maxSharingRetries = 5;
  static const int _sharingBackoffBaseMs = 120;

  static bool _isWindowsSharingViolation(Object error) {
    if (error is PathAccessException) {
      return error.osError?.errorCode == 32;
    }
    if (error is FileSystemException) {
      return error.osError?.errorCode == 32;
    }
    return false;
  }

  static Future<void> _delaySharingBackoff(int attemptIndex) {
    final ms = _sharingBackoffBaseMs * (attemptIndex + 1);
    return Future<void>.delayed(Duration(milliseconds: ms));
  }

  /// Writes [bytes] to [file] with retry on Windows sharing violation (errno 32).
  static Future<int> _writeFileBytesWithSharingRetry(
    File file,
    List<int> bytes,
  ) async {
    var sharingRetries = 0;
    for (var attempt = 0; attempt <= _maxSharingRetries; attempt++) {
      try {
        await file.writeAsBytes(bytes, flush: true);
        return sharingRetries;
      } catch (e) {
        if (!_isWindowsSharingViolation(e) || attempt == _maxSharingRetries) {
          if (_isWindowsSharingViolation(e)) {
            developer.log(
              'PDF writeAsBytes sharing violation after $sharingRetries retries',
              name: 'PdfService',
              error: e,
            );
          }
          rethrow;
        }
        sharingRetries++;
        await _delaySharingBackoff(attempt);
      }
    }
    return sharingRetries;
  }

  /// Temp file in target directory → rename to final path (retries on errno 32).
  static Future<int> _commitTempFileToTarget(
    File tempFile,
    String targetPath,
  ) async {
    final target = File(targetPath);
    var sharingRetries = 0;
    for (var attempt = 0; attempt <= _maxSharingRetries; attempt++) {
      try {
        if (await target.exists()) {
          await target.delete();
        }
        await tempFile.rename(targetPath);
        return sharingRetries;
      } catch (e) {
        if (!_isWindowsSharingViolation(e) || attempt == _maxSharingRetries) {
          if (_isWindowsSharingViolation(e)) {
            developer.log(
              'PDF commit rename sharing violation after $sharingRetries retries '
              'target=$targetPath',
              name: 'PdfService',
              error: e,
            );
          }
          rethrow;
        }
        sharingRetries++;
        await _delaySharingBackoff(attempt);
      }
    }
    return sharingRetries;
  }

  static Future<PdfBytesWriteResult> _writePdfToTargetPath(
    String targetPath,
    List<int> bytes,
  ) async {
    final directory = p.dirname(targetPath);
    await Directory(directory).create(recursive: true);
    final tempPath = p.join(
      directory,
      '.myeduapp_${DateTime.now().microsecondsSinceEpoch}.pdf.tmp',
    );
    final tempFile = File(tempPath);
    var sharingRetries = 0;
    try {
      sharingRetries += await _writeFileBytesWithSharingRetry(tempFile, bytes);
      sharingRetries += await _commitTempFileToTarget(tempFile, targetPath);
      return PdfBytesWriteResult(
        savedPath: targetPath,
        sharingRetryCount: sharingRetries,
      );
    } finally {
      if (await tempFile.exists()) {
        try {
          await tempFile.delete();
        } catch (_) {}
      }
    }
  }

  /// Writes [bytes] to [path]; retries sharing violations; falls back to `name (n).pdf`.
  static Future<PdfBytesWriteResult> writePdfBytesResilient(
    String path,
    List<int> bytes,
  ) async {
    try {
      return await _writePdfToTargetPath(path, bytes);
    } catch (e) {
      if (!_isWindowsSharingViolation(e)) {
        rethrow;
      }
    }

    final dot = path.lastIndexOf('.');
    final base = dot > 0 ? path.substring(0, dot) : path;
    final ext = dot > 0 ? path.substring(dot) : '.pdf';
    for (var i = 1; i <= 20; i++) {
      final alternate = '$base ($i)$ext';
      try {
        return await _writePdfToTargetPath(alternate, bytes);
      } catch (e) {
        if (!_isWindowsSharingViolation(e)) {
          rethrow;
        }
      }
    }
    developer.log(
      'PDF export failed: primary and alternate paths exhausted',
      name: 'PdfService',
      error: path,
    );
    throw PathAccessException(
      path,
      const OSError(
        'The process cannot access the file because it is being used by another process.',
        32,
      ),
      'Cannot write PDF after retries and alternate names.',
    );
  }

  Future<Uint8List> buildStudentReportPdfBytes({
    required String title,
    required String subtitle,
    required StudentReportPdfLabels labels,
    required List<String> headers,
    required List<List<String>> rows,
    required List<String> summaryHeaders,
    required List<List<String>> summaryRows,
    List<String>? dailyAverageHeaders,
    List<List<String>>? dailyAverageRows,
    List<String>? monthlyOverallHeaders,
    List<List<String>>? monthlyOverallRows,
    List<String>? monthlyCategoryHeaders,
    List<List<String>>? monthlyCategoryRows,
  }) async {
    final theme = _turkishTheme();
    final doc = pw.Document(theme: theme);
    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        build: (context) => [
          pw.Text('MyEduApp', style: pw.TextStyle(fontSize: 18)),
          pw.SizedBox(height: 6),
          pw.Text(labels.catalogNotice, style: const pw.TextStyle(fontSize: 9)),
          pw.SizedBox(height: 10),
          pw.Text(title, style: const pw.TextStyle(fontSize: 14)),
          pw.Text(subtitle, style: const pw.TextStyle(fontSize: 11)),
          pw.SizedBox(height: 12),
          if (rows.isEmpty)
            pw.Text(subtitle)
          else
            pw.TableHelper.fromTextArray(
              headers: headers,
              data: rows,
              headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold),
              cellStyle: const pw.TextStyle(fontSize: 9),
              headerDecoration: const pw.BoxDecoration(
                color: PdfColor.fromInt(0xFFEFF2FB),
              ),
              cellAlignment: pw.Alignment.centerLeft,
            ),
          if (summaryRows.isNotEmpty) ...[
            pw.SizedBox(height: 16),
            pw.Text(labels.summarySection, style: pw.TextStyle(fontSize: 13)),
            pw.SizedBox(height: 8),
            pw.TableHelper.fromTextArray(
              headers: summaryHeaders,
              data: summaryRows,
              headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold),
              cellStyle: const pw.TextStyle(fontSize: 9),
              headerDecoration: const pw.BoxDecoration(
                color: PdfColor.fromInt(0xFFEFF2FB),
              ),
            ),
          ],
          if (dailyAverageRows != null &&
              dailyAverageHeaders != null &&
              dailyAverageRows.isNotEmpty) ...[
            pw.SizedBox(height: 16),
            pw.Text(
              labels.dailyAverageSection,
              style: pw.TextStyle(fontSize: 13),
            ),
            pw.SizedBox(height: 8),
            pw.TableHelper.fromTextArray(
              headers: dailyAverageHeaders,
              data: dailyAverageRows,
              headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold),
              cellStyle: const pw.TextStyle(fontSize: 9),
              headerDecoration: const pw.BoxDecoration(
                color: PdfColor.fromInt(0xFFEFF2FB),
              ),
            ),
          ],
          if (monthlyOverallRows != null &&
              monthlyOverallHeaders != null &&
              monthlyOverallRows.isNotEmpty) ...[
            pw.SizedBox(height: 16),
            pw.Text(
              labels.monthlyPerformanceSection,
              style: pw.TextStyle(fontSize: 13),
            ),
            pw.SizedBox(height: 8),
            pw.TableHelper.fromTextArray(
              headers: monthlyOverallHeaders,
              data: monthlyOverallRows,
              headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold),
              cellStyle: const pw.TextStyle(fontSize: 9),
              headerDecoration: const pw.BoxDecoration(
                color: PdfColor.fromInt(0xFFEFF2FB),
              ),
            ),
          ],
          if (monthlyCategoryRows != null &&
              monthlyCategoryHeaders != null &&
              monthlyCategoryRows.isNotEmpty) ...[
            pw.SizedBox(height: 16),
            pw.Text(
              labels.monthlyCategorySection,
              style: pw.TextStyle(fontSize: 13),
            ),
            pw.SizedBox(height: 8),
            pw.TableHelper.fromTextArray(
              headers: monthlyCategoryHeaders,
              data: monthlyCategoryRows,
              headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold),
              cellStyle: const pw.TextStyle(fontSize: 9),
              headerDecoration: const pw.BoxDecoration(
                color: PdfColor.fromInt(0xFFEFF2FB),
              ),
            ),
          ],
        ],
      ),
    );
    return Uint8List.fromList(await doc.save());
  }

  Future<PdfBytesWriteResult> exportStudentReportPdf({
    required String targetPath,
    required String title,
    required String subtitle,
    required StudentReportPdfLabels labels,
    required List<String> headers,
    required List<List<String>> rows,
    required List<String> summaryHeaders,
    required List<List<String>> summaryRows,
    List<String>? dailyAverageHeaders,
    List<List<String>>? dailyAverageRows,
    List<String>? monthlyOverallHeaders,
    List<List<String>>? monthlyOverallRows,
    List<String>? monthlyCategoryHeaders,
    List<List<String>>? monthlyCategoryRows,
  }) async {
    final bytes = await buildStudentReportPdfBytes(
      title: title,
      subtitle: subtitle,
      labels: labels,
      headers: headers,
      rows: rows,
      summaryHeaders: summaryHeaders,
      summaryRows: summaryRows,
      dailyAverageHeaders: dailyAverageHeaders,
      dailyAverageRows: dailyAverageRows,
      monthlyOverallHeaders: monthlyOverallHeaders,
      monthlyOverallRows: monthlyOverallRows,
      monthlyCategoryHeaders: monthlyCategoryHeaders,
      monthlyCategoryRows: monthlyCategoryRows,
    );
    return writePdfBytesResilient(targetPath, bytes);
  }

  pw.ThemeData _turkishTheme() {
    final regular = _loadWindowsFont(r'C:\Windows\Fonts\arial.ttf');
    final bold = _loadWindowsFont(r'C:\Windows\Fonts\arialbd.ttf') ?? regular;
    if (regular == null) {
      return pw.ThemeData.withFont(
        base: pw.Font.helvetica(),
        bold: pw.Font.helveticaBold(),
      );
    }
    return pw.ThemeData.withFont(base: regular, bold: bold);
  }

  pw.Font? _loadWindowsFont(String path) {
    final file = File(path);
    if (!file.existsSync()) {
      return null;
    }
    return pw.Font.ttf(ByteData.sublistView(file.readAsBytesSync()));
  }
}
