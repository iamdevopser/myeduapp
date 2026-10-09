# MyEduApp

Windows masaüstü için tamamen offline eğitim içerik yönetimi uygulaması.

## Mimari

- `AppState` tüm UI ekranlarına veri sağlar (provider + ChangeNotifier).
- `AppDatabase` SQLite şemasını ve CRUD işlemlerini yönetir.
- `FileService` dosya kopyalama, klasör taşıma ve silme işlerini yürütür.
- `BackupService` ZIP yedekleme ve geri yükleme işlemlerini yürütür.
- `PdfService` ders içeriklerini PDF olarak dışa aktarır.
- `AppLocalizations` TR/EN metinlerini tek noktadan sağlar.

## Klasör Yapısı

```

## Ekranlar ve Widget Yapısı

- `HomeScreen`: sınıf/ders seçimi ve yönetimi
- `LessonScreen`: içerik listesi, arama, etiket filtresi, +Ekle, sıralama
- `SettingsScreen`: dil, güvenlik, yedekleme/geri yükleme
- `LockScreen`: opsiyonel şifre kilidi
lib/
  app.dart
  main.dart
  l10n/
    app_localizations.dart
  data/
    local/app_database.dart
    models/
      class_model.dart
      lesson_model.dart
      content_item.dart
      content_with_tags.dart
      tag_model.dart
  providers/
    app_state.dart
  screens/
    home_screen.dart
    lesson_screen.dart
    lock_screen.dart
    settings_screen.dart
  services/
    app_paths.dart
    backup_service.dart
    file_service.dart
    pdf_service.dart
    security_service.dart
  utils/
    path_utils.dart
```

## pubspec.yaml Özeti

Kullanılan başlıca paketler:

- `sqflite_common_ffi` (SQLite)
- `path_provider` + `path`
- `file_picker`
- `archive` (ZIP yedekleme)
- `pdf` (PDF dışa aktarma)
- `intl` + `flutter_localizations`
- `provider`

## SQLite Şeması

```
siniflar(id, ad, olusturma_tarihi)
dersler(id, sinif_id, ad, sira, olusturma_tarihi)
icerikler(id, ders_id, ad, tur, dosya_yolu, sira, olusturma_tarihi)
etiketler(id, ad)
icerik_etiketleri(icerik_id, etiket_id)
ayarlar(anahtar, deger)
```

## Dosya Saklama Yapısı

```
/MyEduAppData/
  /Siniflar/
    /Sinif_Adi/
      /Ders_Adi/
        /Icerikler/
```

## Windows Build (.exe)

1. `flutter pub get`
2. `flutter build windows`
3. Çıktı: `build/windows/x64/runner/Release/` klasörü

## Taşınabilir Kullanım (USB, Harici Disk, Smartboard)

Uygulama **taşınabilir (portable)** modda çalışır. Tüm veriler exe ile aynı dizinde tutulur.

**USB / Flash disk / Harici diskten çalıştırmak için:**

1. `build\windows\x64\runner\Release\` klasörünün **tamamını** USB’ye veya harici diske kopyalayın
2. `my_edu_app.exe` dosyasına çift tıklayarak uygulamayı başlatın
3. İlk çalıştırmada `MyEduAppData` klasörü otomatik oluşturulur; tüm sınıflar, dersler ve içerikler burada saklanır
4. USB’yi başka PC, laptop veya Smartboard’a takarak aynı verilerle kullanmaya devam edebilirsiniz

**Gereksinimler:** Windows 10/11 (PC, Laptop, Smartboard). Ek kurulum gerekmez.

## Kurulum Paketi (tek tıkla, kullanıcı için)

Kullanıcı **sadece kurulum dosyasına tıklasın**, ek işlem yapmasın diye tek EXE kurulum paketi üretmek için:

```powershell
.\tools\build_full_installer.ps1
```

**Gerekli:** Flutter, Inno Setup 6. Inno yoksa: `winget install JRSoftware.InnoSetup`

**Çıktı (`dist/`):**

- **`MyEduApp-Setup.exe`** – Tek tıkla kurulum. Kullanıcı indirir, çalıştırır, UAC’te “Evet” der; runtime kontrolü, sertifika, MSIX kurulumu ve uygulama açılışı otomatik yapılır.
- **`MyEduApp-Kurulum.zip`** – Alternatif: ZIP dağıtımı. Kullanıcı ZIP’i açar, `KURULUMU_BASLAT.bat`’a çift tıklar.

Kurulum talimatları: `dist/KURULUM_TALIMATLARI.txt`
