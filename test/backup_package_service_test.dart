import 'package:flutter_test/flutter_test.dart';
import 'package:my_edu_app/services/backup_package_service.dart';

void main() {
  group('BackupPackageService checksum', () {
    test('sha256Hex produces stable digest', () {
      final digest = BackupPackageService.sha256Hex([1, 2, 3, 4]);
      expect(digest, isNotEmpty);
      expect(digest.length, 64);
      expect(
        BackupPackageService.sha256Hex([1, 2, 3, 4]),
        digest,
      );
    });

    test('toBackupZipEntryPath normalizes separators', () {
      expect(
        BackupPackageService.toBackupZipEntryPath(r'Siniflar\7A\dosya.pdf'),
        'Siniflar/7A/dosya.pdf',
      );
    });
  });
}
