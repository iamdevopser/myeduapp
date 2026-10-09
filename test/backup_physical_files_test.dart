import 'package:flutter_test/flutter_test.dart';
import 'package:my_edu_app/services/database_sync_service.dart';

void main() {
  group('DatabaseSyncService physical file references', () {
    test('skips URL paths', () {
      expect(
        DatabaseSyncService.isPhysicalFileReference(
          'icerikler',
          {'tur': 'link', 'dosya_yolu': 'https://example.com/doc'},
          'dosya_yolu',
          'https://example.com/doc',
        ),
        isFalse,
      );
    });

    test('skips link and text content types', () {
      expect(
        DatabaseSyncService.isPhysicalFileReference(
          'icerikler',
          {'tur': 'link', 'dosya_yolu': 'https://x.com'},
          'dosya_yolu',
          'https://x.com',
        ),
        isFalse,
      );
      expect(
        DatabaseSyncService.isPhysicalFileReference(
          'icerikler',
          {'tur': 'text', 'dosya_yolu': ''},
          'dosya_yolu',
          '',
        ),
        isFalse,
      );
    });

    test('includes image paths for dersler', () {
      expect(
        DatabaseSyncService.isPhysicalFileReference(
          'dersler',
          {'resim_yolu': 'Gorseller/Dersler/a.png'},
          'resim_yolu',
          'Gorseller/Dersler/a.png',
        ),
        isTrue,
      );
    });

    test('includes soru bankasi media paths', () {
      expect(
        DatabaseSyncService.isPhysicalFileReference(
          'soru_bankasi',
          {'gorsel_yolu': 'SoruBankasi/img.png'},
          'gorsel_yolu',
          'SoruBankasi/img.png',
        ),
        isTrue,
      );
      expect(
        DatabaseSyncService.isPhysicalFileReference(
          'sorular',
          {'ses_yolu': 'SoruBankasi/audio.mp3'},
          'ses_yolu',
          'SoruBankasi/audio.mp3',
        ),
        isTrue,
      );
    });

    test('mediaCategoryForTable maps known tables', () {
      expect(
        DatabaseSyncService.mediaCategoryForTable('ders_gorselleri'),
        'DersGorselleri',
      );
      expect(
        DatabaseSyncService.mediaCategoryForTable('uniteler'),
        'Uniteler',
      );
      expect(
        DatabaseSyncService.mediaCategoryForTable('soru_bankasi'),
        'SoruBankasi',
      );
    });
  });
}
