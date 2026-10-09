import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:my_edu_app/services/pdf_service.dart';

void main() {
  test('writePdfBytesResilient writes PDF bytes to target path', () async {
    final dir = await Directory.systemTemp.createTemp('myeduapp_pdf_test_');
    final target = '${dir.path}${Platform.pathSeparator}report_test.pdf';
    const bytes = [0x25, 0x50, 0x44, 0x46]; // %PDF

    final result = await PdfService.writePdfBytesResilient(target, bytes);

    expect(result.savedPath, target);
    expect(result.sharingRetryCount, 0);
    expect(await File(target).readAsBytes(), bytes);

    await dir.delete(recursive: true);
  });

  test('writePdfBytesResilient uses alternate name when primary is locked', () async {
    if (!Platform.isWindows) return;

    final dir = await Directory.systemTemp.createTemp('myeduapp_pdf_lock_');
    final target = '${dir.path}${Platform.pathSeparator}locked.pdf';
    final primary = File(target);
    await primary.writeAsBytes([1, 2, 3]);

    final handle = await primary.open(mode: FileMode.write);
    try {
      const bytes = [0x25, 0x50, 0x44, 0x46];
      final result = await PdfService.writePdfBytesResilient(target, bytes);

      expect(result.savedPath, '${dir.path}${Platform.pathSeparator}locked (1).pdf');
      expect(await File(result.savedPath).readAsBytes(), bytes);
    } finally {
      await handle.close();
      await dir.delete(recursive: true);
    }
  });
}
