import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:my_edu_app/utils/desktop_file_reveal.dart';

void main() {
  test('revealSavedFileInSystemFileManager succeeds for existing file', () async {
    final dir = await Directory.systemTemp.createTemp('myeduapp_reveal_');
    final file = File('${dir.path}${Platform.pathSeparator}sample.pdf');
    await file.writeAsBytes([0x25, 0x50, 0x44, 0x46]);

    final ok = await revealSavedFileInSystemFileManager(file.path);

    expect(ok, isTrue);
    await dir.delete(recursive: true);
  });
}
