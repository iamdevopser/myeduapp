# MyEduApp — Backup/Restore FAZ 3 Teknik Talimatları

## 1. Amaç

FAZ 1 tamamlandı:

* Windows ↔ Android path normalization
* relative path kullanımı
* DB close/open
* AppState refresh
* Android FilePicker bytes fallback

FAZ 2 tamamlandı:

* snapshot
* staging
* rollback
* SHA-256 checksum
* missing file detection
* missing file warning

FAZ 3'ün amacı, MyEduApp tarafından kullanılan ancak mevcut backup ZIP'ine fiziksel olarak dahil edilmeyen önemli dosyaları backup sistemine dahil etmektir.

Ana hedef:

> Backup → Restore sonrasında uygulamanın kullandığı fiziksel dosyalar da yeni cihazda çalışır durumda olmalıdır.

**FAZ 1 ve FAZ 2 davranışlarını bozma.**

---

# 2. KESİN SINIRLAR

Bu fazda yalnızca fiziksel dosya kapsamını genişlet.

Aşağıdaki özellikleri BU FAZDA YAPMA:

* otomatik backup timer
* scheduled backup
* cloud backup
* Google Drive/OneDrive vb. entegrasyonu
* yeni backup provider
* yeni database sistemi
* UI yeniden tasarımı
* database schema değişikliği
* yeni package ekleme
* mevcut Backup/Restore mimarisini baştan yazma

Mevcut:

* path normalization
* staging
* snapshot
* rollback
* checksum
* missing file detection
* AppState refresh

mekanizmalarını koru ve bunların üzerine ekleme yap.

---

# 3. ÖNCE KODU ANALİZ ET

Önce aşağıdaki dosyaları incele:

```text
lib/services/backup_package_service.dart
lib/services/database_sync_service.dart
lib/services/file_service.dart
lib/providers/app_state.dart
lib/screens/settings_screen.dart
```

Ayrıca aşağıdaki alanların database/model kullanımını kod içinde tespit et:

```text
dersler
ders_gorselleri
uniteler
konular
icerikler
soru_bankasi
sorular
sinavlar
```

Dosya path'lerinin nerede oluşturulduğunu, nerede database'e yazıldığını ve fiziksel dosyanın gerçekte nerede tutulduğunu tespit et.

**Tahmin ederek yeni path sistemi oluşturma.**

---

# 4. DOSYA KAPSAMINI TESPİT ET

FAZ 3 sonunda backup aşağıdaki fiziksel dosya kategorilerini desteklemelidir.

## 4.1 Ders / Course görselleri

* ders görseli
* course cover/image
* mevcut uygulamada kullanılan global course image

Database'de path/reference varsa bu dosyanın fiziksel konumunu tespit et.

---

## 4.2 Ünite görselleri

Unit cover/image olarak kullanılan fiziksel dosyalar backup'a dahil edilmeli.

---

## 4.3 Konu görselleri

Topic cover/image olarak kullanılan fiziksel dosyalar backup'a dahil edilmeli.

---

## 4.4 Ders / Lesson görselleri

Lesson/topic-level image olarak kullanılan fiziksel dosyalar varsa backup'a dahil edilmeli.

---

## 4.5 İçerik dosyaları

FAZ 1'de zaten desteklenen fiziksel içerik sistemini bozma.

Örneğin:

* PDF
* Word
* PowerPoint
* audio
* video
* diğer mevcut fiziksel içerikler

mevcut backup mantığıyla çalışmaya devam etmeli.

---

## 4.6 Soru bankası medyaları

`SoruBankasi/` altında bulunan fiziksel medya dosyalarını backup'a dahil et.

Database'deki `soru_bankasi` ve ilgili soru kayıtlarındaki fiziksel path/reference alanlarını tespit et.

---

## 4.7 Sınav soru sesleri / medyaları

Sorular veya sınavlarla ilişkili fiziksel:

* audio
* image
* video
* diğer medya

dosyalar varsa ve database'de fiziksel path/reference tutuluyorsa backup'a dahil et.

---

# 5. HARİCİ GÖRSELLERİN APPDATA ALTINA ALINMASI

Mevcut analizde course/unit/topic/lesson görsellerinin bazıları dışarıdaki absolute path'ler olarak tutuluyor.

Örnek:

```text
C:\Users\...\Pictures\...
```

veya başka platforma özel absolute path.

Bu dosyalar backup sırasında doğrudan absolute path olarak paketlenmemeli.

Bunun yerine uygulamanın kendi data alanına alınmalı.

Hedef prensip:

```text
Harici dosya
     ↓
MyEduAppData altında uygulama kontrollü konum
     ↓
Database'de relative/platform-safe path
     ↓
Backup ZIP
```

Ancak mevcut kullanıcı dosyalarının taşınması sırasında:

* dosyayı kaybetme
* database path'ini boşa çıkarma
* mevcut çalışan görseli bozma

risklerini önle.

---

# 6. DOSYA KOPYALAMA

Mevcut `FileService` fonksiyonlarını incele.

Örneğin mevcut:

```text
FileService.copyFileToContentDir()
```

benzeri mekanizmalar varsa bunları yeniden kullan.

Aynı işi yapan ikinci bir file-copy sistemi oluşturma.

Yeni fiziksel dosya root'u gerekiyorsa mevcut `MyEduAppData` yapısıyla uyumlu bir alt klasör kullan.

Örneğin:

```text
MyEduAppData/
├── Siniflar/
├── SoruBankasi/
├── ...
```

Mevcut klasör yapısını incelemeden sabit yeni yapı oluşturma.

---

# 7. DATABASE PATH KURALI

Backup içindeki tüm fiziksel dosya referansları:

```text
relative path
+
forward slash
```

olmalıdır.

Örneğin:

```text
D:\...\MyEduAppData\...
```

yerine:

```text
Dersler/Matematik/images/course.png
```

gibi relative path kullanılmalı.

Gerçek klasör yapısını mevcut uygulamaya göre belirle.

---

# 8. HARİCİ DOSYA PATH'LERİ

Database'de mevcut eski absolute path'ler bulunabilir.

Yeni sistem:

```text
MyEduAppData içindeki dosya
```

ile

```text
MyEduAppData dışındaki dosya
```

arasındaki farkı tespit etmeli.

MyEduAppData dışındaki dosya için:

1. Dosyanın gerçekten var olup olmadığını kontrol et.
2. Dosya varsa uygulama kontrollü MyEduAppData konumuna kopyala.
3. Database'deki path'i yeni relative path'e güncelle.
4. Backup sisteminin bu yeni dosyayı paketlemesini sağla.
5. Eski harici dosyayı kullanıcı izni olmadan silme.

Dosya bulunamıyorsa:

* database path'ini rastgele değiştirme
* dosya oluşturuyormuş gibi davranma
* missing file mekanizmasına bırak
* kullanıcıya uygun şekilde bildir

---

# 9. BACKUP DOSYA TOPLAMA

Mevcut `BackupPackageService` dosya toplama mekanizmasını genişlet.

Backup oluştururken:

```text
Database references
        ↓
Physical file references
        ↓
Relative path
        ↓
Existing file?
        ↓
ZIP / files/
```

mantığı kullanılmalı.

Dosya yalnızca database'de path bulunduğu için ZIP'e eklenmiş kabul edilmemeli.

Fiziksel dosyanın gerçekten var olduğu doğrulanmalı.

---

# 10. DUPLICATE DOSYA KONTROLÜ

Aynı fiziksel dosya birden fazla database kaydı tarafından kullanılıyorsa ZIP'e birden fazla kez ekleme.

Mümkün olduğunca:

```text
physical path
→
unique backup path
```

eşleştirmesi oluştur.

Aynı dosya farklı kayıtlar tarafından kullanılıyorsa database referansları aynı backup path'i kullanabilmeli.

---

# 11. DOSYA ADI ÇAKIŞMALARI

Farklı klasörlerde aynı dosya adı bulunabilir:

```text
image.png
image.png
```

Bunların backup sırasında birbirinin üzerine yazılmasına izin verme.

Relative directory yapısını koru.

Backup path:

```text
<relative directory>/image.png
```

olmalı.

---

# 12. ZIP PATH GÜVENLİĞİ

FAZ 1'deki path traversal korumasını koru.

ZIP entry path'leri:

```text
../
../../
absolute Windows path
absolute Unix path
```

gibi güvenli olmayan yollar içeriyorsa restore etme.

Tüm ZIP fiziksel dosyaları mevcut `appDataPath` altında kalmalı.

---

# 13. CHECKSUM

FAZ 2'de oluşturulan checksum mekanizmasını tüm yeni fiziksel dosyalara da uygula.

Yeni backup'ta:

```text
manifest.json
```

içerisindeki checksum yapısına yeni dosyalar da dahil edilmeli.

Örneğin:

```text
course image
unit image
topic image
question media
exam audio
```

gibi dosyalar checksum kapsamına girmeli.

Mevcut:

```text
checksumAlgorithm: "sha256"
fileChecksums
```

yapısını koru.

Yeni bir checksum sistemi oluşturma.

---

# 14. RESTORE

Restore sırasında yeni dosya kategorileri de mevcut staging mekanizmasına dahil edilmeli.

Akış:

```text
ZIP
 ↓
Validate
 ↓
Snapshot
 ↓
Staging
 ↓
Checksum
 ↓
Commit
 ↓
Database import
 ↓
Path resolution
 ↓
Missing file check
 ↓
AppState refresh
```

FAZ 2'deki güvenli restore akışını değiştirme.

---

# 15. RESTORE PATH RESOLUTION

Backup:

```text
Dersler/Matematik/images/course.png
```

gibi relative path içeriyorsa restore:

```text
<current appDataPath>/Dersler/Matematik/images/course.png
```

şeklinde çözülmeli.

Android'de Windows path'i oluşturulmamalı.

Windows'ta Android path'i oluşturulmamalı.

---

# 16. DATABASE IMPORT

Restore edilen yeni fiziksel dosyaların database referansları mevcut platformun gerçek path sistemine doğru bağlanmalı.

Database'de uygulamanın çalışma zamanında kullandığı path formatı mevcut uygulamanın mevcut beklentisine uygun olmalı.

Backup formatındaki relative path ile runtime'daki fiziksel path'i birbirine karıştırma.

---

# 17. WEBLINK / URL KORUMASI

FAZ 1'deki davranışı koru.

Şunları fiziksel dosya gibi paketleme:

```text
http://...
https://...
```

Weblink içerikleri URL olarak kalmalı.

Benzer şekilde `link` / `text` tipi içeriklerin mevcut davranışını bozma.

---

# 18. MISSING FILE

FAZ 2'deki missing file sistemini genişlet.

Yeni fiziksel dosya kategorilerinde:

```text
database reference var
+
physical file yok
```

durumu tespit edilmeli.

Restore sonucundaki mevcut:

```text
missingFileCount
```

mekanizmasını kullan.

Yeni duplicate counter oluşturma.

---

# 19. ESKİ BACKUP UYUMLULUĞU

FAZ 1 ve FAZ 2'de olduğu gibi eski backup'lar çalışmaya devam etmeli.

Örneğin eski backup'ta:

```text
course image yok
```

ise restore başarısız olmamalı.

Eksik dosya backup'ın eski format/kapsamından kaynaklanıyorsa mevcut missing-file davranışı kullanılabilir.

Eski backup'ların yeni fiziksel dosya kategorilerini içermemesi normaldir.

---

# 20. ESKİ HARİCİ PATH'LER

Eski database'de:

```text
C:\Users\...\image.png
```

gibi harici absolute path bulunabilir.

Restore edilen backup içinde dosyanın kendisi mevcut değilse:

* Windows'taki eski absolute path'i Android'de geçerliymiş gibi kullanma.
* `<appDataPath>/C:\...` oluşturma.
* Path traversal/security kurallarını ihlal etme.
* Dosya bulunamıyorsa missing file olarak değerlendir.

Yeni oluşturulan backup'larda ise mümkün olan dosyaları MyEduAppData altına al ve relative path kullan.

---

# 21. DOSYA TAŞIMA GÜVENLİĞİ

Harici görselleri MyEduAppData içine alırken:

* kaynak dosyayı başarıyla okuyabildiğini kontrol et
* hedef klasörü oluştur
* dosyayı kopyala
* kopyanın gerçekten oluştuğunu doğrula
* başarılı kopyalamadan sonra database path'ini değiştirme

İşlem sırasında hata olursa database'i yarım bırakma.

FAZ 2 snapshot/rollback mekanizmasıyla uyumlu hareket et.

---

# 22. APPSTATE

Restore sonrasında FAZ 1'deki tam AppState refresh mekanizmasını koru.

Özellikle görseller ve içerikler restore edildiğinde UI:

* eski path'i cache'lememeli
* yeni path'i kullanmalı
* uygulama yeniden başlatılmadan mümkün olduğunca güncel veriyi göstermeli

Mevcut provider/state mimarisini kullan.

---

# 23. UI

Mevcut Settings backup/restore UI'ını koru.

Gerekli yeni kullanıcı mesajları varsa mevcut localization sistemine ekle.

Yeni bir ekran oluşturma.

Mevcut:

* başarı mesajları
* missing file warning
* corrupted backup warning

ile uyumlu davran.

---

# 24. YENİ PACKAGE YOK

Yeni package ekleme.

Mevcut projede bulunan:

```text
archive
file_picker
path_provider
path
crypto
```

gibi paketleri mevcut amaçları doğrultusunda kullan.

Önce pubspec'i kontrol et.

---

# 25. TESTLER

Mevcut testleri bozma.

Çalıştır:

```text
flutter test
flutter analyze
```

Yeni fiziksel dosya backup/restore davranışı için testler ekle.

En azından:

### Test 1 — Content file

```text
PDF/Word/etc.
→ Backup
→ ZIP
→ files/
→ Restore
→ dosya mevcut
```

### Test 2 — Course image

```text
Course image
→ Backup
→ ZIP içinde mevcut
→ Restore
→ image mevcut
```

### Test 3 — Unit image

```text
Unit image
→ Backup
→ Restore
```

### Test 4 — Topic image

```text
Topic image
→ Backup
→ Restore
```

### Test 5 — Question media

```text
Question media
→ Backup
→ Restore
```

### Test 6 — Exam audio

```text
Exam audio
→ Backup
→ Restore
```

Uygulamada gerçekten mevcut olan dosya türleri için test oluştur.

Kodda bulunmayan bir dosya türünü zorla ekleme.

---

# 26. CROSS-PLATFORM TEST

Gerçek cihaz testi özellikle önemlidir.

### Windows → Android

```text
Backup
↓
Android
↓
Restore
↓
Dosyaları aç
```

### Android → Windows

```text
Backup
↓
Windows
↓
Restore
↓
Dosyaları aç
```

Özellikle görsel, PDF ve diğer fiziksel dosyaların gerçekten açıldığını kontrol et.

---

# 27. BACKUP ZIP KONTROLÜ

Test sırasında ZIP'i manuel olarak aç ve kontrol et.

Şunları doğrula:

```text
manifest.json
database.json
files/
```

ve `files/` altında beklenen yeni dosyaların bulunduğunu kontrol et.

`database.json` içinde fiziksel dosyaların:

```text
D:\
C:\
C:\Users\
/data/user/0/
```

gibi platforma özel absolute path'lerle tutulmadığını doğrula.

---

# 28. BAŞARI KRİTERLERİ

FAZ 3 tamamlanmış sayılması için:

* [ ] Course görselleri backup'a dahil.
* [ ] Unit görselleri backup'a dahil.
* [ ] Topic görselleri backup'a dahil.
* [ ] Lesson görselleri backup'a dahil.
* [ ] Mevcut global course görselleri destekleniyor.
* [ ] Soru bankası fiziksel medyaları destekleniyor.
* [ ] Sınav soru sesleri/medyaları destekleniyor.
* [ ] Mevcut içerik dosyaları çalışmaya devam ediyor.
* [ ] Harici görseller mümkün olduğunca MyEduAppData altına alınıyor.
* [ ] Yeni backup'larda fiziksel dosya referansları relative.
* [ ] ZIP path'leri forward-slash.
* [ ] Checksum yeni dosyaları da kapsıyor.
* [ ] Restore staging/rollback mekanizmasını kullanıyor.
* [ ] Missing file detection yeni dosya kategorilerini kapsıyor.
* [ ] URL/weblink davranışı korunuyor.
* [ ] Eski backup'lar çalışmaya devam ediyor.
* [ ] Windows → Android fiziksel dosya restore çalışıyor.
* [ ] Android → Windows fiziksel dosya restore çalışıyor.
* [ ] `flutter test` başarılı.
* [ ] `flutter analyze` 0 error.
* [ ] FAZ 4 veya otomatik backup gibi yeni kapsam eklenmiyor.

---

# 29. ÖNEMLİ: GEREKSİZ KOD YAZMA

Uygulamada gerçekten kullanılan ve database'de fiziksel dosya referansı bulunan dosya türlerini tespit et.

Kodda bulunmayan veya kullanılmayan varsayımsal özellikler için sistem oluşturma.

Mevcut:

```text
BackupPackageService
DatabaseSyncService
FileService
AppState
```

mimarisini koru.

Aynı işi yapan yeni service oluşturma.

---

# 30. SON RAPOR

İşlem sonunda kısa bir rapor ver:

### Değiştirilen dosyalar

Dosya + yapılan değişiklik.

### Yeni backup kapsamı

Hangi fiziksel dosya türlerinin artık backup'a dahil olduğu.

### Path migration

Harici absolute path'lerin nasıl ele alındığı.

### Checksum

Yeni fiziksel dosyaların checksum kapsamına nasıl alındığı.

### Restore

Yeni dosyaların Windows/Android'de nasıl restore edildiği.

### Testler

Çalıştırılan testler ve sonuçları.

### Manuel testler

Windows → Android ve Android → Windows sonuçları.

### Kalan problemler

FAZ 3 sonrasında gerçekten kalan problemleri belirt.

**FAZ 3 kapsamı dışındaki özellikleri uygulama.**
