# MyEduApp — FAZ 3.1: Android Backup Save Fix

## 1. Amaç

FAZ 3 backup sisteminde Android'de Backup işleminin tamamlanmaması sorununu düzelt.

Mevcut problem:

* `FilePicker.platform.saveFile()` Android/iOS'ta `bytes` gerektiriyor.
* `settings_screen.dart` içinde `saveFile()` çağrısına `bytes` gönderilmiyor.
* Bu nedenle Android'de `ArgumentError` oluşuyor.
* `state.backupTo()` hiç çalışmıyor.
* ZIP dosyası hiç oluşturulmuyor.

Bu fazın amacı yalnızca bu problemi çözmektir.

---

## 2. Kesin sınırlar

### Yapılacak

* Android'de backup ZIP'ini `FilePicker` üzerinden kullanıcı tarafından seçilen konuma doğru şekilde kaydet.
* Windows'taki mevcut backup davranışını koru.
* Mevcut FAZ 1, FAZ 2 ve FAZ 3 davranışlarını koru.
* Mevcut checksum, migration, physical-file collection, staging ve rollback sistemlerine dokunma.
* Backup başarı/başarısız mesajlarını koru.
* Restore koduna dokunma; mevcut Android restore bytes fallback'i çalışmaya devam etmeli.

### Yapılmayacak

* Otomatik backup ekleme.
* FAZ 4 özellikleri.
* Cloud backup.
* Database schema değişikliği.
* `formatVersion` değiştirme.
* Yeni package ekleme.
* Backup ZIP formatını değiştirme.
* Backup klasör yapısını değiştirme.
* Windows backup akışını yeniden tasarlama.
* `BackupPackageService` içinde gereksiz refactor.
* `File(path).writeAsBytes()` ile Android SAF yoluna ikinci kez yazma.
* Kullanıcıdan storage permission isteme; SAF kullanımı yeterlidir.

---

## 3. Önce mevcut kodu incele

Öncelikle şu dosyaları oku:

```text
lib/screens/settings_screen.dart
lib/providers/app_state.dart
lib/services/backup_package_service.dart
```

Ayrıca `file_picker` 8.3.7'nin mevcut Android `saveFile` davranışını doğrula.

FAZ 3 kodunun mevcut yapısını değiştirmeden yalnızca gerekli Android save akışını düzelt.

---

## 4. Doğru Android backup akışı

Android'de işlem şu mantıkta olmalı:

```text
Backup butonu
    ↓
Backup verisini/ZIP bytes'ını oluştur
    ↓
FilePicker.platform.saveFile(
    fileName: ...,
    bytes: encodedZipBytes
)
    ↓
Android SAF
    ↓
Kullanıcı hedef konumu seçer
    ↓
Plugin bytes'ı seçilen URI'ye yazar
    ↓
Backup tamamlandı
```

### Kritik kural

Android'de:

```text
saveFile(bytes: ...)
```

kullanıldığında dönen `path` değerini tekrar:

```dart
File(path).writeAsBytes(...)
```

ile yazma.

Android'deki SAF URI ile gerçek filesystem path aynı şey değildir.

---

## 5. Mevcut `BackupPackageService` tasarımını koru

Mevcut `createPackage()` fonksiyonunun FAZ 1–3 kapsamında yaptığı işlemler korunmalı:

* external path migration
* database export
* physical file collection
* duplicate prevention
* ZIP oluşturma
* manifest
* SHA-256 checksum
* `files/`
* path normalization
* forward slash
* path traversal protection

Bu mekanizmaları yeniden yazma.

Gerekirse `BackupPackageService` içinde ZIP bytes üretimini mevcut `createPackage()` mantığından küçük ve kontrollü şekilde ayır.

Ancak aynı ZIP oluşturma mantığını ikinci kez kopyalama.

**Tek ZIP üretim mantığı bulunmalı.**

---

## 6. Önerilen mimari

Mevcut yapıya göre en az değişiklikle aşağıdaki prensibi uygula:

### Windows

Mevcut akışı koru:

```text
FilePicker.saveFile()
        ↓
path
        ↓
BackupPackageService.createPackage(outputPath: path)
```

Windows davranışı değişmemeli.

### Android

ZIP bytes önce hazırlanmalı:

```text
BackupPackageService
        ↓
ZIP bytes
        ↓
FilePicker.platform.saveFile(
    fileName: ...,
    bytes: zipBytes,
)
```

Android'de ZIP'i ayrıca filesystem path üzerinden tekrar yazma.

---

## 7. Önemli tasarım tercihi

`BackupPackageService` zaten backup'ın tüm içeriğini oluşturduğu için aynı backup üretim mantığını tekrar `SettingsScreen` içine taşıma.

`SettingsScreen` sadece UI/file-picker katmanı olarak kalmalı.

Örneğin mantık şu ayrımda olabilir:

```text
BackupPackageService
    → backup bytes üretir

SettingsScreen
    → Windows'ta hedef path alır
    → Android'de bytes ile SAF saveFile çağırır
```

Mevcut mimariye en uygun ve en küçük değişikliği seç.

Gereksiz yeni servis veya yeni abstraction oluşturma.

---

## 8. Windows davranışı kesinlikle korunmalı

Windows'ta:

```dart
FilePicker.platform.saveFile(...)
```

ile kullanıcı konum seçmeye devam etmeli.

Örneğin:

```text
C:\Users\...\Downloads\myeduapp_backup_....zip
```

veya kullanıcının seçtiği başka bir klasör.

Windows için mevcut `outputPath` davranışını bozma.

---

## 9. Android kullanıcı deneyimi

Android'de kullanıcı Backup butonuna bastığında:

1. Backup hazırlanmalı.
2. Android sistem dosya kaydetme arayüzü açılmalı.
3. Kullanıcı klasör/hedef seçebilmeli.
4. ZIP seçilen konuma kaydedilmeli.
5. Başarılıysa mevcut `backupSuccess` mesajı gösterilmeli.
6. Kullanıcı iptal ederse backup iptal edilmeli; hata olarak gösterilmemeli.
7. Gerçek bir hata oluşursa mevcut `backupFailed` mesajı kullanılmalı.

Dosya adı mevcut yapıyı korumalı:

```text
myeduapp_backup_<timestamp>.zip
```

---

## 10. İptal davranışı

Kullanıcı Android save dialog'unu iptal ederse:

```text
path == null
```

veya ilgili plugin sonucuna göre işlem sonlandırılmalı.

Bu durum:

```text
backupFailed
```

olarak gösterilmemeli.

---

## 11. Restore'a dokunma

Mevcut restore:

```text
pickFiles(
    withData: true
)
```

ve:

```text
picked.bytes
    ↓
temporary ZIP
    ↓
restoreFrom()
```

mantığını koru.

Restore tarafında gereksiz değişiklik yapma.

---

## 12. Testler

Mevcut testleri koru.

Çalıştır:

```powershell
flutter test
```

ve:

```powershell
flutter analyze
```

### Beklenen

```text
flutter test → tüm testler PASS
flutter analyze → 0 error
```

Mevcut `info` seviyesindeki uyarılar sorun değildir.

---

## 13. Android gerçek cihaz testi

Bu fazın en önemli testi gerçek Android cihazda yapılmalıdır.

### Test 1 — Basit backup

1. Android uygulamasını çalıştır.
2. Backup'a bas.
3. Android save dialog'unun açıldığını doğrula.
4. `Download` klasörünü seç.
5. Backup'ı kaydet.
6. Uygulamanın başarı mesajını gösterdiğini doğrula.
7. Android dosya yöneticisinden ZIP'i bul.
8. ZIP'i açmayı dene.

Beklenen:

```text
myeduapp_backup_<timestamp>.zip
```

gerçekten `Download` içinde bulunmalı.

---

### Test 2 — Fiziksel dosyalar

Android'de backup almadan önce mümkünse:

* bir içerik PDF'i,
* bir ders görseli,
* bir ünite görseli,
* bir konu görseli,
* soru bankası görseli/sesi,
* sınav sorusu sesi

oluştur.

Sonra backup al.

ZIP'i açıp:

```text
manifest.json
database.json
files/
```

olduğunu doğrula.

Fiziksel dosyaların `files/` altında bulunduğunu doğrula.

---

### Test 3 — Android restore

Android'de oluşturulan backup ZIP'ini:

* başka bir Android kurulumunda veya
* Windows uygulamasında

restore et.

Kontrol et:

* database verileri,
* öğrenciler,
* sınıflar,
* içerik dosyaları,
* ders görselleri,
* ünite görselleri,
* konu görselleri,
* soru bankası medya,
* sınav sesleri.

çalışıyor mu.

---

### Test 4 — Windows backup

Windows'ta mevcut backup akışının değişmediğini doğrula:

```text
Backup
↓
Save dialog
↓
klasör seç
↓
ZIP oluştur
```

Windows backup ZIP'i daha sonra restore edilebilmeli.

---

## 14. ZIP bütünlüğü

Android'de oluşturulan ZIP'in:

* açılabildiğini,
* `manifest.json` içerdiğini,
* `database.json` içerdiğini,
* `files/` içerdiğini,
* checksum bilgilerinin bulunduğunu

kontrol et.

`formatVersion`:

```text
1
```

olarak kalmalı.

---

## 15. Kod kalitesi

Şunları özellikle kontrol et:

* Aynı ZIP üretme kodu iki yerde bulunmasın.
* Android için gereksiz temporary file oluşturma.
* SAF dosyasını filesystem path gibi kullanma.
* Yeni package ekleme.
* Mevcut FAZ 1–3 servislerini yeniden yazma.
* Gereksiz constructor değişiklikleri yapma.
* Backup formatını değiştirme.
* Restore'u bozabilecek değişiklik yapma.

---

## 16. Son rapor

İşlem sonunda aşağıdakileri raporla:

### Değiştirilen dosyalar

Dosya bazında listele.

### Android çözümü

Android backup'ın artık nasıl kaydedildiğini açıkla.

### Windows

Windows davranışının korunup korunmadığını belirt.

### Testler

```text
flutter test:
flutter analyze:
```

sonuçlarını ver.

### Gerçek cihaz testi

Kod ortamında yapılamadıysa açıkça:

```text
Android gerçek cihaz testi kullanıcı tarafından yapılmalı.
```

de.

Kod tarafından doğrulanmayan bir testi başarılı olarak raporlama.

### FAZ 1–3

FAZ 1, FAZ 2 ve FAZ 3 davranışlarının korunup korunmadığını belirt.

---

## 17. Başarı kriteri

FAZ 3.1 tamamlanmış sayılır ancak aşağıdakilerin tamamı sağlanırsa:

* Android Backup butonu hata vermeden çalışıyor.
* Android save dialog açılıyor.
* Kullanıcı hedef konum seçebiliyor.
* ZIP gerçekten seçilen konuma kaydediliyor.
* ZIP açılabiliyor.
* Physical files backup'a dahil.
* SHA-256 checksum korunuyor.
* Windows backup davranışı bozulmamış.
* Restore davranışı bozulmamış.
* Eski backup uyumluluğu bozulmamış.
* `formatVersion: 1` korunmuş.
* `flutter test` başarılı.
* `flutter analyze` 0 error.
* Yeni package eklenmemiş.
* Otomatik backup/FAZ 4 eklenmemiş.
