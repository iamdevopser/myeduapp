# MyEduApp — Backup/Restore FAZ 2 Teknik Talimatları

## 1. Amaç

FAZ 1 tamamlanmıştır ve Windows ↔ Android çift yönlü backup/restore testi başarıyla yapılmıştır.

FAZ 2'nin amacı mevcut Backup/Restore sistemini **hata durumlarında güvenli, geri alınabilir ve doğrulanabilir** hale getirmektir.

Bu fazda:

* restore öncesi snapshot
* restore sırasında güvenli staging
* hata durumunda rollback
* backup bütünlük/checksum kontrolü
* eksik dosya tespiti ve kullanıcı uyarısı

uygulanacaktır.

**FAZ 3'e geçme.**

---

# 2. KESİN SINIRLAR

Bu fazda:

* Mevcut backup formatını gereksiz yere değiştirme.
* `formatVersion` değerini değiştirme.
* Yeni backup dosya türleri ekleme.
* Course/unit/topic/lesson cover görsellerini backup'a ekleme.
* Soru bankası fiziksel medyalarını backup'a ekleme.
* Sınav seslerini backup'a ekleme.
* Otomatik backup timer oluşturma.
* UI tasarımını yeniden düzenleme.
* Yeni package ekleme.
* Database mimarisini değiştirme.

FAZ 1'de yapılan path normalization, DB close/open ve AppState refresh davranışlarını **bozma**.

---

# 3. ÖNCE MEVCUT KODU İNCELE

Önce aşağıdaki dosyaları ve ilgili backup/restore çağrı zincirini incele:

```text
lib/services/backup_package_service.dart
lib/services/database_sync_service.dart
lib/providers/app_state.dart
lib/screens/settings_screen.dart
lib/services/file_service.dart
```

Gerekirse ilgili database helper/path dosyalarını da incele.

Önce mevcut restore akışını tam olarak anla.

FAZ 1 değişikliklerini geri alma veya yeniden yazma.

---

# 4. RESTORE ÖNCESİ SNAPSHOT

Restore başlamadan önce mevcut uygulama verilerinin güvenli bir snapshot'ını oluştur.

Snapshot en azından:

* mevcut SQLite database
* uygulamanın restore ile değiştirilecek fiziksel dosyaları

için geri dönüş imkanı sağlamalıdır.

Snapshot geçici bir güvenli klasörde tutulabilir.

Snapshot'ın amacı:

```text
Mevcut durum
     ↓
SNAPSHOT
     ↓
RESTORE
     ↓
Başarılı → snapshot temizle
Hata → snapshot'tan geri dön
```

olmalıdır.

Snapshot işlemi başarısız olursa restore işlemine devam etme.

---

# 5. RESTORE İŞLEMİ ATOMIC OLMALI

Mevcut restore mantığında dosyaların yazılması ve database import edilmesi sırasında hata oluşursa uygulamanın yarım restore durumunda kalmasını engelle.

İstenen davranış:

```text
1. Backup seç
2. Backup doğrula
3. Mevcut veriyi snapshot al
4. Restore için staging hazırla
5. Dosyaları staging'e çıkar
6. Database restore/import işlemini gerçekleştir
7. Gerekli doğrulamaları yap
8. Başarılıysa staging → gerçek konum
9. AppState yenile
10. Başarılıysa snapshot'ı temizle
```

Herhangi bir kritik adım başarısız olursa:

```text
HATA
 ↓
RESTORE DURDUR
 ↓
SNAPSHOT GERİ YÜKLE
 ↓
DATABASE YENİDEN AÇ
 ↓
APPSTATE YENİLE
```

---

# 6. DATABASE GÜVENLİĞİ

FAZ 1'deki DB close/open mekanizmasını koru.

Restore öncesi:

```text
DB close
```

Restore sonrası:

```text
DB open
```

gerekiyorsa hata durumunda da DB'nin tekrar kullanılabilir durumda olduğundan emin ol.

Rollback sonrasında:

* database connection yeniden açılmalı
* AppState yeniden yüklenmeli
* uygulama eski durumuyla çalışmaya devam etmeli

---

# 7. ROLLBACK

Restore işleminin herhangi bir kritik aşamasında hata oluşursa mevcut kullanıcı verileri korunmalı.

Örnek:

```text
Snapshot başarılı
↓
ZIP açıldı
↓
Dosyalar staging'e çıkarıldı
↓
Database import başladı
↓
Database import FAILED
```

Bu durumda:

```text
Yeni/yarım restore edilen durum
        ↓
AT
        ↓
Snapshot
```

geri yüklenmeli.

Rollback sırasında başka bir hata oluşursa bunu sessizce yutma.

Kullanıcıya restore işleminin başarısız olduğunu bildir.

---

# 8. STAGING KURALI

Mümkün olduğunca ZIP içindeki dosyaları doğrudan gerçek `MyEduAppData` konumuna yazma.

Önce geçici/staging alana çıkar.

Staging içinde:

* ZIP path güvenliği
* path traversal kontrolü
* dosya bütünlüğü
* beklenen dosyaların varlığı

kontrol edilsin.

Kontroller başarılı olduktan sonra gerçek veriye uygulanmalı.

FAZ 1'deki güvenli path çözümleme mekanizmasını kullan.

---

# 9. BACKUP CHECKSUM / BÜTÜNLÜK

Mevcut backup formatını bozma.

Ancak checksum/bütünlük kontrolü için mevcut `crypto` package kullanılabiliyorsa onu kullan.

Yeni package ekleme.

Amaç en azından backup içerisindeki fiziksel dosyaların bozulmuş/değişmiş olup olmadığını tespit edebilmek.

Mevcut `manifest.json` yapısını incele.

Eğer mevcut yapı minimum bir metadata alanı eklenerek genişletilebiliyorsa bunu yap.

Ancak:

* gereksiz format değişikliği yapma
* mevcut backup'ların restore edilmesini bozma
* `formatVersion` değerini değiştirme

Yeni checksum alanları eski backup'larda bulunmuyorsa restore işlemi başarısız olmamalı.

Eski backup:

```text
checksum yok
```

→ eski backup olarak kabul edilip restore edilebilir.

Yeni backup:

```text
checksum mevcut
```

→ checksum doğrulaması yapılmalı.

---

# 10. CHECKSUM DOĞRULAMA

Checksum bulunan dosyalarda:

```text
ZIP'deki dosya
      ↓
SHA-256
      ↓
manifest checksum
```

karşılaştırması yap.

Uyuşmazlık varsa restore işlemini güvenli şekilde durdur.

Snapshot'tan rollback yap.

Kullanıcıya backup'ın bozuk veya değiştirilmiş olduğunu bildir.

---

# 11. MISSING FILE KONTROLÜ

Restore sonrasında database'de fiziksel dosya referansı bulunan fakat gerçek dosyası bulunmayan kayıtları tespit et.

Örneğin:

```text
database.json
    ↓
Siniflar/7A/.../test.pdf
    ↓
files/.../test.pdf YOK
```

durumunu tespit et.

`missingFileCount` gibi mevcut mekanizma varsa onu kullan.

Yeni duplicate mekanizma oluşturma.

---

# 12. EKSİK DOSYA UYARISI

`missingFileCount > 0` durumunda kullanıcıya açık bir uyarı göster.

Örneğin:

```text
Restore tamamlandı ancak bazı dosyalar bulunamadı.
Eksik dosya sayısı: X
```

Uyarı restore işleminin tamamen başarısız olduğu anlamına gelmemeli.

Çünkü database restore edilmiş olabilir.

Ancak kullanıcıya eksik fiziksel dosyalar açıkça bildirilmeli.

Mevcut UI/dialog/snackbar yapısını kullan.

Yeni bir UI framework oluşturma.

---

# 13. BACKUP OLUŞTURMA SIRASINDA CHECKSUM

Yeni oluşturulan backup'larda mümkünse ZIP'e dahil edilen fiziksel dosyalar için checksum üret.

Checksum hesabı:

```text
dosya bytes
    ↓
SHA-256
    ↓
manifest
```

şeklinde olmalı.

Checksum path'i backup içindeki relative path ile ilişkilendir.

Platforma özel absolute path checksum metadata'sına yazılmamalı.

---

# 14. RESTORE SONRASI DOĞRULAMA

Restore başarılı kabul edilmeden önce minimum şu kontrolleri yap:

### Database

* DB tekrar açılabiliyor mu?
* JSON import tamamlandı mı?

### Dosyalar

* Beklenen staging dosyaları mevcut mu?
* Checksum varsa doğru mu?
* Database'deki fiziksel path'ler gerçek dosyalara karşılık geliyor mu?

### Application state

* AppState yeniden yüklenebiliyor mu?

Kontrollerden kritik biri başarısızsa rollback yap.

---

# 15. BAŞARILI RESTORE

Her şey başarılıysa:

```text
Restore başarılı
↓
Database açık
↓
AppState güncel
↓
Dosyalar doğru
↓
Snapshot artık gereksiz
↓
Snapshot temizle
```

Snapshot'ı yalnızca başarılı restore doğrulandıktan sonra sil.

---

# 16. HATA YÖNETİMİ

Restore sırasında exception oluşursa:

* exception'ı sessizce yutma
* stack trace/debug bilgisini uygun şekilde logla
* kullanıcıya anlaşılır hata mesajı göster
* rollback dene
* rollback sonrası database'i tekrar aç
* AppState'i yeniden yükle

Kullanıcıya teknik stack trace gösterme.

---

# 17. MEVCUT BACKUP'LAR

Eski backup'lar çalışmaya devam etmeli.

Özellikle:

```text
formatVersion: 1
```

olan mevcut backup'lar restore edilebilmeli.

Checksum içermeyen eski backup:

```text
checksum doğrulaması atlanır
```

ancak diğer güvenlik kontrolleri uygulanmaya devam eder.

---

# 18. DOSYA KAPSAMI

Bu fazda mevcut backup'a dahil edilen dosyaların güvenli restore edilmesi hedefleniyor.

FAZ 3'te yapılacak:

* cover images
* course images
* unit images
* topic images
* lesson images
* question bank media
* exam audio

gibi fiziksel dosyaların backup'a eklenmesini **BU FAZDA YAPMA.**

---

# 19. DEĞİŞTİRİLECEK DOSYALAR

Öncelikle mevcut dosyalardan ilerle.

Muhtemel dosyalar:

```text
lib/services/backup_package_service.dart
lib/services/database_sync_service.dart
lib/providers/app_state.dart
lib/screens/settings_screen.dart
```

Gerekirse:

```text
lib/services/file_service.dart
```

Yeni dosya gerekiyorsa yalnızca gerçekten gerekli olduğunda oluştur.

---

# 20. TESTLER

Değişikliklerden sonra:

```text
flutter analyze
flutter test
```

çalıştır.

Mevcut tüm testleri koru.

Yeni kritik logic için mümkünse test ekle.

Özellikle test et:

### Test 1 — Normal restore

```text
Backup
→ Restore
→ Başarılı
```

### Test 2 — Corrupted checksum

```text
Backup
→ dosya değiştirilir/bozulur
→ Restore
→ checksum failure
→ rollback
```

### Test 3 — Eksik fiziksel dosya

```text
Backup
→ files içinden bir dosya çıkarılır
→ Restore
→ missingFileCount > 0
→ kullanıcı uyarısı
```

### Test 4 — Database import failure

Database import'un kontrollü şekilde başarısız olduğu senaryoda:

```text
Restore
→ hata
→ rollback
→ eski database
→ eski AppState
```

kontrol edilmeli.

### Test 5 — Eski backup

Checksum bulunmayan mevcut format v1 backup restore edilmeli.

### Test 6 — Windows → Android

FAZ 1'de başarıyla test edilen senaryo korunmalı.

### Test 7 — Android → Windows

FAZ 1'de başarıyla test edilen senaryo korunmalı.

---

# 21. GERİYE DÖNÜK UYUMLULUK

FAZ 1'de çalışan şu özellikleri bozma:

* Windows → Android
* Android → Windows
* relative path restore
* MyEduAppData marker
* URL/weblink preservation
* path traversal protection
* Android FilePicker bytes fallback
* DB close/open
* AppState refresh

---

# 22. BAŞARI KRİTERLERİ

FAZ 2 tamamlanmış sayılması için:

* [ ] Restore öncesi snapshot oluşturuluyor.
* [ ] Snapshot başarısızsa restore başlamıyor.
* [ ] Restore staging üzerinden güvenli şekilde ilerliyor.
* [ ] Kritik restore hatasında rollback çalışıyor.
* [ ] Rollback sonrası database tekrar açılıyor.
* [ ] Rollback sonrası AppState yenileniyor.
* [ ] Yeni backup'larda checksum/bütünlük metadata'sı oluşturuluyor.
* [ ] Checksum bulunan backup'larda doğrulama yapılıyor.
* [ ] Bozuk checksum restore'u durduruyor.
* [ ] Eski checksum'sız backup'lar çalışmaya devam ediyor.
* [ ] Eksik fiziksel dosyalar tespit ediliyor.
* [ ] `missingFileCount > 0` durumunda kullanıcı uyarılıyor.
* [ ] Windows → Android çalışmaya devam ediyor.
* [ ] Android → Windows çalışmaya devam ediyor.
* [ ] `flutter analyze` başarılı.
* [ ] `flutter test` başarılı.
* [ ] FAZ 3 özellikleri uygulanmıyor.

---

# 23. ÖNEMLİ UYGULAMA PRENSİBİ

Bu fazı tek seferde büyük bir refactor haline getirme.

Mevcut Backup/Restore kodunu mümkün olduğunca koru.

Önce:

1. snapshot
2. staging
3. rollback
4. checksum
5. missing file warning

şeklinde mevcut akışa minimum müdahale ile ekle.

Her değişiklikten sonra mevcut davranışın korunduğunu kontrol et.

**Çalışan FAZ 1 kodunu gereksiz yere yeniden tasarlama.**

---

# 24. İŞLEM SONU RAPORU

İşlem sonunda kısa bir rapor ver:

### Değiştirilen dosyalar

Dosya + yapılan değişiklik.

### Snapshot / rollback

Nasıl uygulandığı.

### Checksum

Nasıl uygulandığı ve hangi dosyaların doğrulandığı.

### Missing files

Nasıl tespit edildiği ve kullanıcıya nasıl bildirildiği.

### Testler

Çalıştırılan testler ve sonuçları.

### Kalan problemler

FAZ 3'e bırakılan problemler.

**FAZ 3'e ait hiçbir geliştirmeyi uygulama.**
