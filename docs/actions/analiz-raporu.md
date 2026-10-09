# MyEduApp Backup/Restore Sistem Analiz Raporu

> **Tarih:** 13 Eylül 2026  
> **Kaynak talimat:** `docs/actions/backup_analiz.md`  
> **Kapsam:** Mevcut sistemin analizi — kod değişikliği yapılmamıştır.  
> **Odak:** Windows ↔ Android backup/restore uyumluluğu

---

## Mevcut Durum ↔ Hedef Durum

| Boyut | Mevcut durum | Hedef durum |
|--------|--------------|-------------|
| Backup formatı | ZIP: `manifest.json` + `database.json` + `files/` | Aynı format, platformdan bağımsız |
| Veri | 24 tablo JSON export | Tüm tablolar + tüm fiziksel dosyalar |
| Dosya yolları | Sadece `icerikler.dosya_yolu` normalize; diğerleri mutlak kalabilir | Tüm dosya referansları `MyEduAppData` göreli |
| Fiziksel dosyalar | Sadece `icerikler` tablosundaki mevcut dosyalar | PDF, medya, soru bankası, kapak görselleri dahil |
| Windows → Android | Kritik uyumsuzluk riski (mutlak Windows path) | Android sandbox altında çalışan path |
| Restore güvenliği | Rollback yok; DB kapatılmıyor | Güvenli restore + tutarlı state yenileme |

---

## A. Mevcut Backup Sistemi

### İki ayrı yedekleme mekanizması

1. **`BackupPackageService`** (`lib/services/backup_package_service.dart`) — Ayarlar ekranındaki ana yedekleme
2. **`BackupService`** (`lib/services/backup_service.dart`) — Tüm `MyEduAppData` klasörünü ZIP'ler; ayarlarda **kullanılmıyor**, sadece ders/konu dışa aktarımında `createZipFromDirectory` ile kullanılıyor

### Ana backup paketi yapısı

```
MyEduApp_Backup.zip
├── manifest.json      (format: MyEduAppBackup, version: 1)
├── database.json      (24 tablo JSON)
└── files/
    └── Siniflar/...   (göreli yollar)
```

### Akış (`AppState.backupTo` → `createPackage`)

1. `DatabaseSyncService.exportData()` ile tüm tablolar JSON'a aktarılır
2. `collectContentFiles()` yalnızca `icerikler` tablosundaki `dosya_yolu` kayıtlarına bakar
3. Fiziksel dosya varsa ZIP'e `files/{relativePath}` olarak eklenir
4. `manifest.json` içinde `fileCount` yazılır

### SQLite konumu

- Dosya: `{MyEduAppData}/myeduapp.sqlite`
- **Windows:** `exe` dizininin yanında `MyEduAppData/`
- **Android/iOS:** `getApplicationDocumentsDirectory()/MyEduAppData/`
- Backup'a **binary `.sqlite` dosyası dahil değil**; veri `database.json` üzerinden taşınır

> Not: `database_helper.dart` dosyası yoktur; karşılığı `lib/data/local/app_database.dart` dosyasıdır.

### Fiziksel dosya konumları

| Veri tipi | Konum | DB alanı | Backup'a dahil? |
|-----------|-------|----------|-----------------|
| PDF, Word, PPT, medya | `Siniflar/{sınıf}/{ders}/{konu}/Icerikler/` | `icerikler.dosya_yolu` | Evet (varsa) |
| Weblink | URL string | `icerikler.dosya_yolu` | Hayır (dosya değil; JSON'da kalır) |
| Ders/konu/ünite kapakları | **Harici** FilePicker path | `dersler/uniteler/konular.resim_yolu` | **Hayır** |
| Ders görseli (global) | **Harici** path | `ders_gorselleri.resim_yolu` | **Hayır** |
| Soru bankası medya | `SoruBankasi/` | `soru_bankasi.gorsel_yolu`, `ses_yolu` | **Hayır** |
| Sınav soru sesleri | Değişken | `sorular.ses_yolu` | **Hayır** |
| Öğrenci fotoğrafı | — | `ogrenciler` tablosunda alan yok | — |

İçerik dosyaları `FileService.copyFileToContentDir()` ile `MyEduAppData` altına kopyalanır ve DB'ye **mutlak path** yazılır. Kapak görselleri ise FilePicker path'i olduğu gibi kaydedilir (`lib/screens/app_builder_screen.dart`).

### Path normalizasyonu (export)

Sadece `icerikler` tablosunda, path içinde `\MyEduAppData\` (veya platform separator) varsa göreliye çevrilir (`lib/services/database_sync_service.dart`, `_prepareRowForExport`).

### Otomatik yedekleme

Ayarlar UI'da toggle var (`autoBackupEnabled`, `autoBackupMinutes`) ancak **arka planda çalışan timer/servis yok** — sadece ayar olarak saklanıyor.

### İlgili paketler (`pubspec.yaml`)

| Paket | Rol |
|-------|-----|
| `archive` | ZIP oluşturma/okuma |
| `file_picker` | Backup seç/kaydet |
| `path_provider` | Android veri kökü |
| `path` | Path normalizasyonu |
| `sqflite_common_ffi` | SQLite (tüm platformlarda FFI) |
| `crypto` | Şifre hash (backup checksum için kullanılmıyor) |

---

## B. Mevcut Restore Sistemi

### Akış (`settings_screen.dart` → `AppState.restoreFrom` → `restorePackage`)

1. FilePicker ile `.zip` seçilir (`result.files.single.path!`)
2. Onay dialogu
3. `restorePackage()`:
   - ZIP okunur, `manifest.json` / `database.json` doğrulanır
   - `files/` altındaki dosyalar `appDataPath` altına yazılır
   - `DatabaseSyncService.importFromJsonString()` ile DB güncellenir
4. Kısmi state yenileme: sınıflar, etiketler, seçili derse bağlı ünite/konu/içerik

### Import mantığı

- Transaction içinde `deleteOrder` ile tablolar silinir, sonra `exportTables` sırasıyla insert
- `ConflictAlgorithm.replace` kullanılır
- Import sonrası `ensurePlatformDefaults()` çağrılır

### Path çözümleme (import)

`lib/services/database_sync_service.dart`, `_prepareRowForImport`:

- Göreli path → `rootPath` ile birleştirilir
- **Mutlak path → olduğu gibi bırakılır** (satır 96–98)

Bu, Windows → Android uyumsuzluğunun ana nedeni.

### SQLite bağlantısı

- **Mevcut `app_state.dart`:** Restore öncesi `close()` **yok**
- Eski `app_state.dart.restore_backup` varyantında `close()` / `open()` vardı; bu kaldırılmış
- DB dosyası replace edilmez; açık bağlantı üzerinden DELETE + INSERT yapılır

### State yenileme

Kısmi: mentorluk, sınavlar, soru bankası, favoriler vb. için tam reload yok. Seçim `_rebindSelection()` ile güncellenir.

---

## C. Windows → Android Uyumluluk Sorunları

### 1. Mutlak Windows path'lerin korunması (KRİTİK)

Export normalizasyonu başarısız olursa veya eski backup'ta mutlak path varsa, import bunları **değiştirmiyor**. Android'de `D:\...\file.pdf` gibi path'ler dosya sisteminde yok → PDF/medya açılmaz.

Normalizasyonun başarısız olabileceği durumlar:

- Path'te `MyEduAppData` marker'ı yok
- Zaten göreli ama yanlış kök (nadir)
- Export öncesi DB'de mutlak path, marker eşleşmezse ZIP'te de mutlak kalır

### 2. Yedeklenmeyen dosya türleri

Kapak görselleri, soru bankası medyası, sınav sesleri ZIP'e **hiç eklenmez**. Android'de bu referanslar ya geçersiz mutlak path ya da var olmayan harici dosyaya işaret eder.

### 3. `collectContentFiles` + `resolveRelativePath` riski

Export sonrası path hâlâ mutlaksa (`D:\...`), `resolveRelativePath` şunu üretir:

`{appDataPath}\D:\...\file.pdf` → geçersiz birleşik path → dosya ZIP'e **eklenmez**, DB'de path kalır.

### 4. ZIP entry separator

Windows backup'ta ZIP içi path'lerde `\` kullanılabilir. `resolveRelativePath` bunu normalize ediyor; bu kısım genelde sorun çıkarmaz.

### 5. Android FilePicker

`lib/screens/settings_screen.dart`:

```dart
if (result == null || result.files.single.path == null) {
  return;
}
```

- `path == null` durumunda sessiz çıkış (hata mesajı yok)
- Seçilen ZIP, uygulama kontrollü alana **kopyalanmıyor**; doğrudan picker cache path'i okunuyor
- Bazı Android sürümlerinde/cihazlarda `path` null, `bytes` dolu olabilir

### 6. Veri kökü farkı

| Platform | `MyEduAppData` kökü |
|----------|---------------------|
| Windows | `{exe_dir}/MyEduAppData` |
| Android | `/data/data/.../app_flutter/MyEduAppData` |

Göreli path + doğru import ile uyumlu; mutlak path ile uyumsuz.

### 7. `sqflite_common_ffi` her platformda

`main.dart` Android'de de FFI kullanıyor. Backup ile doğrudan ilgili değil ama restore sırasında yoğun transaction'da ek risk faktörü olabilir.

---

## D. Eksik veya Riskli Noktalar

| # | Risk | Önem |
|---|------|------|
| 1 | Import sırasında mutlak path korunması | Kritik |
| 2 | Sadece `icerikler` fiziksel dosyaları yedekleniyor | Kritik |
| 3 | Kapak görselleri harici path olarak saklanıyor | Yüksek |
| 4 | Restore öncesi DB `close()` yok | Orta |
| 5 | Rollback yok; restore öncesi snapshot yok | Kritik |
| 6 | Dosyalar DB import'tan **önce** yazılıyor; DB transaction fail → dosya/DB uyumsuzluğu | Yüksek |
| 7 | `deleteOrder` mentorluk tablolarını silmiyor | Orta |
| 8 | Bütünlük kontrolü yok (checksum/hash) | Orta |
| 9 | `missingFileCount > 0` olsa da restore devam eder | Orta |
| 10 | Otomatik yedekleme implementasyonu yok | Düşük |
| 11 | Restore sonrası kısmi state refresh | Orta |
| 12 | `BackupService.restoreBackup` (tam klasör replace) kullanılmıyor | Bilgi |

---

## E. Önerilen Backup Formatı

Mevcut `MyEduAppBackup` v1 yapısı korunabilir; içerik genişletilmeli:

```json
// manifest.json (önerilen v2)
{
  "format": "MyEduAppBackup",
  "formatVersion": 2,
  "createdAt": "...",
  "databaseVersion": 14,
  "appPlatform": "windows",
  "fileCount": 142,
  "files": [
    { "path": "Siniflar/.../file.pdf", "sha256": "..." }
  ]
}
```

**Kurallar:**

- Tüm dosya referansları ZIP içinde **forward-slash göreli** path (`Siniflar/...`)
- Path içeren tüm DB kolonları export'ta normalize, import'ta `rootPath` ile birleştir
- `http://` / `https://` linkler dosya sayılmaz
- İsteğe bağlı SHA256 (mevcut `crypto` paketi yeterli)

---

## F. Önerilen Restore Akışı

```
1. FilePicker → Android'de bytes/path → app temp'e kopyala
2. Mevcut durumun snapshot'ı (opsiyonel mini-backup veya DB+files staging)
3. manifest + database.json doğrula (format, version, databaseVersion)
4. DB bağlantısını kapat
5. files/ → appDataPath (transaction dışı, staging klasöründe toplanabilir)
6. database.json import (tüm path'ler rootPath'e bağlansın; mutlak Windows path rewrite)
7. Kayıt sayısı + kritik dosya varlığı doğrulama
8. DB yeniden aç
9. AppState tam reload (tüm listeler + selection rebind)
10. Hata → snapshot'tan rollback
```

**Path rewrite (import):** Mutlak path'te `MyEduAppData` sonrası suffix alınsın; Android/Windows köküne join edilsin. Harici mutlak path'ler için uyarı + skip veya migration.

---

## G. Değiştirilmesi Gereken Dosyalar

| Dosya | Değişiklik |
|-------|------------|
| `lib/services/database_sync_service.dart` | Tüm path kolonları için export/import normalizasyonu; `deleteOrder`'a mentorluk tabloları; mutlak path rewrite |
| `lib/services/backup_package_service.dart` | Tüm dosya referanslarını topla; integrity check; restore sırası ve hata yönetimi |
| `lib/providers/app_state.dart` | Restore öncesi/sonrası `close()`/`open()`; tam state reload |
| `lib/screens/settings_screen.dart` | Android `bytes` fallback; restore hata/ilerleme UI |
| `lib/screens/app_builder_screen.dart` | Kapak görsellerini `MyEduAppData` altına kopyala (kalıcı çözüm) |
| `lib/services/file_service.dart` | Kapak görseli kopyalama helper |
| `lib/services/json_sync_service.dart` | Format v2, checksum desteği (opsiyonel) |
| `tool/test_restore_backup_package.dart` | Windows→Android path senaryoları için test genişletme |

**Dokunulmayabilir (şimdilik):** `app_database.dart` schema (v14 uyumlu), `app_paths.dart` (Android kökü doğru).

---

## H. Gerekli Yeni Paketler

**Yeni paket gerekmez.** Mevcut paketler yeterli:

| Paket | Rol |
|-------|-----|
| `archive` | ZIP oluşturma/okuma |
| `file_picker` | Backup seç/kaydet |
| `path_provider` | Android veri kökü |
| `path` | Path normalizasyonu |
| `sqflite_common_ffi` | SQLite |
| `crypto` | SHA256 checksum (şu an sadece şifre hash) |

---

## I. Veri Kaybını Önlemek İçin Önlemler

1. Restore öncesi otomatik snapshot (mini ZIP veya staging)
2. DB import'u transaction içinde; dosya taşıma atomik staging + commit
3. Restore onayından sonra "geri alınamaz" uyarısı + snapshot varlığı
4. `missingFileCount > 0` ise kullanıcıya uyarı; isteğe bağlı iptal
5. Import öncesi `databaseVersion` uyumluluk kontrolü
6. Kapak/soru bankası dosyalarını kaynakta `MyEduAppData` altına kopyalama
7. Eski backup'lar için mutlak path migration katmanı
8. Restore sonrası smoke test (kayıt sayısı, örnek PDF path `File.exists`)

---

## J. Test Edilmesi Gereken Senaryolar

1. **Windows backup → Android restore** — tam içerik (PDF, video, audio)
2. **Android backup → Windows restore** — ters yön
3. Büyük backup (100+ PDF) — bellek ve süre
4. Eksik fiziksel dosya ile backup — uyarı ve davranış
5. Bozuk ZIP / eksik `manifest.json` — güvenli hata
6. Restore iptal / ortasında hata — rollback
7. Android FilePicker `path == null`, `bytes` dolu
8. Weblink içerik — URL korunumu
9. Soru bankası görsel/ses — restore sonrası oynatma
10. Kapak görselleri — görünürlük
11. Mentorluk verileri — restore sonrası tutarlılık
12. Restore sonrası uygulama restart — kalıcılık
13. `tool/test_restore_backup_package.dart` ile otomatik doğrulama

---

## Özet

### 1. Mevcut sistem nasıl çalışıyor?

Ayarlar ekranı `BackupPackageService` ile ZIP oluşturur: 24 tablo `database.json`'a export edilir; yalnızca `icerikler` tablosundaki fiziksel dosyalar `files/` altına eklenir. Restore ZIP'i okur, dosyaları `MyEduAppData` altına yazır, JSON'u açık SQLite bağlantısına import eder. Veri kökü platforma göre değişir (Windows: exe yanı; Android: app documents). Eski tam-klasör `BackupService` ayarlarda kullanılmıyor.

### 2. Sorunun muhtemel nedenleri

- Import'ta **mutlak Windows path'lerin korunması** (`_prepareRowForImport`)
- Backup'a **sadece `icerikler` dosyalarının** dahil edilmesi; kapak/soru bankası/medya hariç
- Kapak görsellerinin **harici FilePicker path** olarak saklanması
- Export normalizasyonunun yalnızca `icerikler` ve yalnızca `MyEduAppData` marker'ı ile sınırlı olması
- Android FilePicker'da `path == null` ve ZIP'in app-controlled alana kopyalanmaması

### 3. Veri kaybı riskleri

- Restore öncesi snapshot/rollback **yok** — başarısız restore mevcut veriyi bozabilir
- Dosyalar DB'den önce yazılıyor; DB transaction fail → dosya/DB uyumsuzluğu
- Eksik dosyalı backup sessizce restore edilebilir (`missingFileCount` engel değil)
- Mentorluk tabloları `deleteOrder`'da yok → eski veri kalabilir veya FK sorunu
- Restore sırasında DB kapatılmıyor → yoğun import'ta tutarsızlık riski

### 4. Değiştirilmesi gereken dosyalar

Öncelik sırasıyla: `database_sync_service.dart`, `backup_package_service.dart`, `app_state.dart`, `settings_screen.dart`, `app_builder_screen.dart` + `file_service.dart`. Test: `tool/test_restore_backup_package.dart`.

### 5. Uygulanması gereken düzeltme planı

**Faz 1 — Kritik (Windows ↔ Android):**

- Export/import'ta tüm path kolonlarını göreli yap; import'ta mutlak Windows path'leri `MyEduAppData` suffix'ine rewrite et
- `collectContentFiles` → tüm DB dosya referanslarını tara (`icerikler`, `soru_bankasi`, `sorular`, `resim_yolu` kolonları)
- Restore'da DB `close()`/`open()`; tam AppState reload

**Faz 2 — Güvenlik:**

- Restore öncesi snapshot
- Staging + atomik commit
- `missingFileCount` uyarısı

**Faz 3 — Kalıcı veri modeli:**

- Kapak görsellerini `MyEduAppData` altına kopyala
- Android FilePicker `bytes` fallback
- Manifest v2 + opsiyonel checksum

**Faz 4 — Test:**

- Windows backup → Android restore manuel + otomatik test script
