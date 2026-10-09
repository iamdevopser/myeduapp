# MyEduApp — Backup/Restore FAZ 1 Teknik Uygulama Talimatları

## 1. Amaç

MyEduApp'teki mevcut Backup/Restore sistemini, özellikle:

* Windows → Android
* Android → Windows
* Windows → Windows
* Android → Android

senaryolarında çalışacak şekilde düzelt.

Bu fazın amacı **mevcut backup formatını tamamen değiştirmek değil**, mevcut sistemdeki kritik platformlar arası uyumsuzlukları gidermektir.

**FAZ 2 ve FAZ 3 kapsamındaki geliştirmeleri yapma.**

---

# 2. TEMEL KURALLAR

* Mevcut mimariyi koru.
* Mevcut database yapısını bozma.
* Mevcut backup formatını mümkün olduğunca geriye dönük uyumlu tut.
* Gereksiz dosya oluşturma.
* Gereksiz refactor yapma.
* Yeni package ekleme.
* Aynı işi yapan yeni servis/logic oluşturma.
* Mevcut servisleri kullan; duplicate logic oluşturma.
* UI tasarımını değiştirme.
* Backup/Restore dışındaki özelliklere dokunma.
* Mevcut verilerin silinmesine yol açabilecek kontrolsüz işlemler yapma.
* Önce mevcut kodu analiz et, sonra değişiklik yap.
* Değişiklikleri yalnızca FAZ 1 kapsamında tut.

---

# 3. MEVCUT BACKUP MİMARİSİ

Ana backup sistemi:

`lib/services/backup_package_service.dart`

Mevcut backup paketi:

```text
ZIP
├── manifest.json
├── database.json
└── files/
```

Database JSON içinde tablolar bulunuyor.

Mevcut sistemde özellikle `icerikler.dosya_yolu` için path normalization bulunuyor; ancak diğer dosya referanslarının tamamı güvenli şekilde normalize edilmiyor.

Ana problem:

```text
Windows absolute path
D:\...\MyEduAppData\...
```

gibi yolların backup içine girmesi.

Bu yollar Android cihazda geçerli değildir.

---

# 4. PATH KURALI

Backup içine **platforma özel absolute path yazılmamalıdır.**

Örneğin:

```text
D:\MyEduAppData\Siniflar\7A\Matematik\...
```

backup içinde tutulmamalıdır.

Bunun yerine uygulama data root'una göre relative path kullanılmalıdır:

```text
Siniflar/7A/Matematik/Konu/Icerikler/dosya.pdf
```

Path formatında backup içinde mümkün olduğunca:

```text
/
```

kullan.

Windows:

```text
\
```

separator'larını backup'a olduğu gibi yazma.

---

# 5. TÜM DOSYA REFERANSLARINI TESPİT ET

Sadece `icerikler.dosya_yolu` alanını düzeltmek yeterli değildir.

Kod içerisindeki database tablolarında bulunan **tüm fiziksel dosya path referanslarını** tespit et.

Özellikle analiz raporunda belirtilen:

### İçerik dosyaları

* PDF
* Word
* PowerPoint
* video
* audio
* diğer fiziksel içerikler

### Cover/image alanları

* Course image
* Unit image
* Topic image
* Lesson image
* Global course image

### Soru bankası

`SoruBankasi/` altında bulunan fiziksel medya dosyaları.

### Sınav

* question audio
* diğer fiziksel medya referansları

### Diğer

Database içinde absolute path olarak saklanabilecek bütün alanları kontrol et.

**Amaç:** Backup oluşturulurken Windows'a özel path'in backup'a taşınmasını engellemek.

---

# 6. BACKUP PATH NORMALIZATION

Mevcut path normalization logic'ini genişlet.

Bir dosya yolu:

```text
{appDataPath}/...
```

altındaysa backup içine yalnızca appDataPath'e göre relative kısmını yaz.

Örnek:

```text
D:\...\MyEduAppData\Siniflar\7A\Matematik\Icerikler\a.pdf
```

şuna dönüşmeli:

```text
Siniflar/7A/Matematik/Icerikler/a.pdf
```

Aynı mantık farklı platformlarda da çalışmalı.

Android'de örneğin:

```text
/data/user/0/.../app_flutter/MyEduAppData/...
```

gibi gerçek path'in backup içine girmemesi gerekir.

---

# 7. RESTORE PATH RESOLUTION

Restore sırasında backup'taki relative path tekrar mevcut cihazın `appDataPath` köküne bağlanmalıdır.

Örnek:

Backup:

```text
Siniflar/7A/Matematik/Icerikler/a.pdf
```

Windows restore:

```text
<Windows appDataPath>/Siniflar/7A/Matematik/Icerikler/a.pdf
```

Android restore:

```text
<Android appDataPath>/Siniflar/7A/Matematik/Icerikler/a.pdf
```

Sonuçta database içinde **mevcut cihazın gerçek path'i** bulunmalıdır.

---

# 8. ESKİ ABSOLUTE PATH'LERİ DESTEKLE

Eski backup dosyalarında absolute Windows path bulunabilir.

Restore sırasında:

* relative path → mevcut appDataPath'e bağla
* eski Windows absolute path → mümkünse appDataPath'e göre relative hale getir
* dışarıdaki gerçek dosya yollarını otomatik olarak Android'de geçerliymiş gibi kabul etme

Özellikle şu hatayı oluşturma:

```text
<appDataPath>/D:\old\path\file.pdf
```

Absolute path'in relative path gibi birleştirilmesine izin verme.

Path türünü önce tespit et.

---

# 9. FILES KLASÖRÜ

Restore sırasında ZIP içindeki:

```text
files/
```

klasörünün içeriğini mevcut cihazın appDataPath'i altına çıkar.

Örneğin:

```text
files/Siniflar/7A/Matematik/Icerikler/a.pdf
```

şuna dönüşmeli:

```text
<appDataPath>/Siniflar/7A/Matematik/Icerikler/a.pdf
```

Database içindeki path de aynı hedefi göstermeli.

---

# 10. DATABASE KAPATMA / AÇMA

Restore başlamadan önce açık SQLite database bağlantısının durumunu kontrol et.

Restore işlemi sırasında database dosyasının başka bir işlem tarafından açık tutulması platforma bağlı problemlere neden olabilir.

Gerekliyse:

1. Database bağlantısını kapat.
2. Restore işlemini gerçekleştir.
3. Database işlemlerini tamamla.
4. Database'i yeniden aç.

Mevcut database helper/singleton mimarisini bozma.

Yeni bir database sistemi oluşturma.

---

# 11. DATABASE IMPORT

Mevcut JSON import sistemini kullan.

Ancak import edilen path alanlarında:

```text
absolute path
```

ile

```text
relative path
```

ayrımını doğru yap.

Relative path'leri:

```text
appDataPath + relativePath
```

mantığıyla çöz.

Absolute path'leri kör şekilde mevcut root ile birleştirme.

---

# 12. APP STATE REFRESH

Restore tamamlandıktan sonra yalnızca database'i değiştirmek yeterli değildir.

Uygulamanın bellekte tuttuğu state'lerin restore edilen database ile senkron olması gerekir.

Restore sonrası mevcut `AppState` mekanizmasını kullanarak gerekli state'leri yeniden yükle.

Özellikle:

* classes
* students
* courses
* lessons
* contents
* tasks
* exams
* question banks
* reports
* mentoring
* diğer restore edilen database verileri

uygulama yeniden başlatılmadan görünür hale gelmeli.

Mevcut provider/state mimarisini koru.

Yeni global state sistemi oluşturma.

---

# 13. FILE PICKER — FAZ 1 SINIRI

Mevcut FilePicker kullanımını kontrol et.

Android'de kullanıcı ZIP seçtiğinde:

```text
path == null
```

olabilecek durumları dikkate al.

Mevcut kodda yalnızca `result.files.single.path` kullanılıyorsa bunun Android'de sorun çıkarıp çıkarmadığını kontrol et.

FAZ 1'de gerekli minimum düzeltmeyi yap.

Ancak FAZ 3'te planlanan kapsamlı bytes-based FilePicker fallback sistemini burada oluşturma.

---

# 14. SECURITY / PATH SAFETY

Restore edilen path'in appDataPath dışına çıkmasına izin verme.

Örneğin backup içinde kötü niyetli veya bozuk bir path bulunursa:

```text
../../somewhere/file
```

veya benzeri traversal yolları doğrudan filesystem'e yazılmamalı.

Path çözümünde hedef yolun appDataPath altında kaldığını kontrol et.

Bu kontrol mevcut mimariyle uyumlu ve minimum değişiklikle yapılmalı.

---

# 15. DOSYA TİPLERİ KONUSU

FAZ 1'de temel hedef:

**Database'deki fiziksel dosya referanslarının doğru path'e dönüştürülmesidir.**

Mevcut backup'ın yalnızca `icerikler` fiziksel dosyalarını dahil ettiği tespit edilmiş durumda.

Aşağıdaki dosyaların backup'a dahil edilmesi:

* course covers
* unit covers
* topic covers
* lesson covers
* global course images
* question bank media
* exam audio

**FAZ 3 kapsamındadır.**

Bu fazda kapsamlı yeni dosya toplama sistemi yazma.

Ancak mevcut kodda path normalization yapılırken bu alanların yapısına zarar verme.

---

# 16. BACKWARD COMPATIBILITY

Mevcut backup'ların restore edilebilmesi korunmalı.

Özellikle:

```text
manifest.json
database.json
files/
```

formatı korunmalı.

Mevcut kullanıcı backup'larının yalnızca yeni path resolution mantığı nedeniyle bozulmasına izin verme.

---

# 17. DEĞİŞTİRİLEBİLECEK DOSYALAR

Öncelikli olarak şu dosyaları incele:

```text
lib/services/backup_package_service.dart
lib/services/database_sync_service.dart
lib/services/file_service.dart
lib/services/json_sync_service.dart
lib/providers/app_state.dart
lib/screens/settings_screen.dart
lib/screens/app_builder_screen.dart
```

Gerekmedikçe başka dosyalara dokunma.

Özellikle:

```text
lib/data/local/app_database.dart
lib/data/local/app_paths.dart
```

dosyalarını ancak gerçekten gerekli olduğu kanıtlanırsa değiştir.

---

# 18. TEST

Kod değişikliklerinden sonra:

```text
flutter analyze
flutter test
```

çalıştır.

Mevcut testlerin tamamının geçmesini sağla.

Mümkünse backup/restore ile ilgili mevcut testleri de çalıştır.

---

# 19. MANUEL TEST SENARYOLARI

En azından aşağıdaki senaryoları doğrula:

### Test 1

Windows:

```text
Backup oluştur
↓
Windows'tan restore et
```

### Test 2

Windows:

```text
Backup oluştur
↓
Android'e aktar
↓
Restore et
```

### Test 3

Android:

```text
Backup oluştur
↓
Windows'a aktar
↓
Restore et
```

### Test 4

Restore sonrası uygulamayı kapatıp tekrar aç.

Verilerin ve dosya referanslarının hâlâ doğru olduğunu kontrol et.

### Test 5

Restore edilen fiziksel bir dosyayı uygulama içinden aç.

Örneğin:

```text
PDF
```

dosyasının gerçekten açıldığını doğrula.

---

# 20. BAŞARI KRİTERLERİ

FAZ 1 tamamlanmış sayılması için:

* [ ] Windows absolute path'leri yeni backup'a taşınmıyor.
* [ ] Backup path'leri platform bağımsız relative path.
* [ ] Restore sırasında relative path'ler mevcut cihazın appDataPath'ine bağlanıyor.
* [ ] Eski absolute path'ler yanlış şekilde root ile birleştirilmiyor.
* [ ] `files/` içeriği doğru hedefe çıkarılıyor.
* [ ] Database restore sırasında gerekli bağlantı yönetimi yapılıyor.
* [ ] Restore sonrası AppState yenileniyor.
* [ ] Uygulamayı yeniden başlatmadan restore edilen veriler görünür oluyor.
* [ ] Path traversal engelleniyor.
* [ ] Mevcut backup formatı korunuyor.
* [ ] Mevcut veritabanı yapısı bozulmuyor.
* [ ] `flutter analyze` başarılı.
* [ ] `flutter test` başarılı.
* [ ] FAZ 2 ve FAZ 3'e ait özellikler uygulanmıyor.

---

# 21. SON RAPOR

İşlem sonunda kısa bir rapor ver:

### Değiştirilen dosyalar

Her dosya ve yapılan değişikliğin 1 cümlelik açıklaması.

### Backup/Restore değişiklikleri

Hangi path ve restore problemlerinin düzeltildiği.

### Testler

Çalıştırılan komutlar ve sonuçları.

### Kalan problemler

FAZ 1 dışında kalan ve sonraki fazlara bırakılan problemler.

**Kod değişiklikleri dışında yeni bir mimari önerisi uygulama.**
