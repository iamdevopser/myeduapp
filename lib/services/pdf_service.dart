import 'dart:io';

import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../data/models/content_with_tags.dart';

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
}

