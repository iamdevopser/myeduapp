# MYEDUAPP — FAZ 7

## VELİ PORTALI VE ÖĞRENCİ-VELİ EŞLEŞTİRME

## 1. AMAÇ

MyEduApp içerisinde Veli rolünü gerçek ve güvenli bir kullanıcı/portal yapısına dönüştür.

Bu fazın amacı:

* mevcut veli/parent altyapısını analiz etmek,
* gerekiyorsa veli veri modelini oluşturmak veya mevcut yapıyı genişletmek,
* öğrenci ↔ veli ilişkisinin güvenli şekilde kurulmasını sağlamak,
* Veli login/workspace yapısını oluşturmak,
* Velinin yalnızca kendisine bağlı öğrencilerin bilgilerine erişebilmesini sağlamak,
* duyuru, belge, devam/yoklama ve izin verilen akademik bilgileri salt okunur şekilde göstermek,
* Sekreter/Öğretmen/Öğrenci yetkilerini bozmamaktır.

ÖNEMLİ:

Önce mevcut kodu ve database'i analiz et.

Mevcut veli/parent modeli, tablo, servis veya ekran varsa yeniden kullan.

Aynı amaca hizmet eden ikinci bir veli sistemi oluşturma.

Gereksiz migration, refactor veya yeni authentication sistemi oluşturma.

---

# 2. FAZ ÖNCESİ ZORUNLU AUDIT

İlk aşamada mevcut sistemi analiz et.

Aşağıdakileri tespit et:

* veli ile ilgili database tabloları
* veli model/class yapıları
* öğrenci-veli ilişkisi
* mevcut veli login fonksiyonları
* `AppState` rol yönetimi
* `AppRole`
* `AuthorizationService`
* mevcut Veli/Yönetici kartları
* mevcut Student Portal yapısı
* mevcut duyuru servisi
* mevcut belge servisi
* mevcut yoklama/attendance servisleri
* mevcut akademik bilgi servisleri
* navigation/shell yapısı
* localization
* JSON sync
* database schema versiyonu

Özellikle şu sorular cevaplanmalıdır:

1. Database'de veli tablosu var mı?
2. Öğrenci ile veli arasında mevcut ilişki var mı?
3. Bir öğrencinin birden fazla velisi destekleniyor mu?
4. Bir veli birden fazla öğrenciye bağlı olabilir mi?
5. Veli telefon/e-posta bilgileri mevcut mu?
6. Mevcut veli login fonksiyonu var mı?
7. `AppRole` içerisinde veli zaten var mı?
8. Veli için mevcut workspace veya navigation var mı?
9. Öğrenci Portal'daki hangi servisler veli için yeniden kullanılabilir?
10. Duyuru ve belge hedefleme sistemi veli erişimini destekliyor mu?

Audit sonucuna göre implementasyon yap.

---

# 3. VELİ ROLÜ

Veli için mevcut `AppRole` yapısını kullan.

Yeni ve bağımsız role enum sistemi oluşturma.

Beklenen yapı:

`AppRole.parent`

veya mevcut projedeki naming convention ne ise onu kullan.

`AppState.currentRole` üzerinden Veli oturumu yönetilmelidir.

Veli login sonrası:

`ParentTabWorkspace`

veya mevcut naming convention'a uygun eşdeğer workspace açılmalıdır.

---

# 4. AUTHENTICATION

Mevcut authentication altyapısını analiz et.

Eğer local password/hash sistemi kullanılıyorsa mevcut mekanizmayı mümkün olduğunca yeniden kullan.

Yeni JWT/OAuth/Firebase authentication sistemi oluşturma.

Veli login:

* kimlik doğrulama
* doğru role atanması
* session oluşturulması
* bağlı öğrencilerin yüklenmesi

işlemlerini yapmalıdır.

Yanlış öğrenciye erişim kesinlikle mümkün olmamalıdır.

---

# 5. ÖĞRENCİ ↔ VELİ EŞLEŞTİRME

Öğrenci-veli ilişkisi güvenli şekilde modellenmelidir.

Mevcut sistem uygunsa mevcut ilişkiyi kullan.

Yeni ilişki gerekiyorsa en basit ve genişletilebilir yapı oluştur.

Tercihen ilişki şu ihtiyaçları desteklemelidir:

* bir veli → birden fazla öğrenci
* bir öğrenci → birden fazla veli

Ancak mevcut ürün gereksinimi tek veli/tek öğrenci ise gereksiz karmaşıklık ekleme.

İlişki için benzersiz ve güvenilir ID kullan.

İsim üzerinden eşleştirme yapma.

---

# 6. VELİ YETKİLERİ

Veli yalnızca kendi öğrencilerine ait bilgileri görebilir.

ALLOWED:

* kendi hesabını görüntüleme
* bağlı öğrencileri görüntüleme
* öğrenci temel bilgilerini görüntüleme
* duyuruları görüntüleme
* belgeleri görüntüleme
* belgeleri açma/indirme
* devam/yoklama bilgisini görüntüleme
* izin verilen akademik bilgileri görüntüleme

DENIED:

* öğrenci ekleme
* öğrenci silme
* öğrenci bilgilerini değiştirme
* not değiştirme
* not girme
* sınav oluşturma
* sınav düzenleme
* belge silme
* belge düzenleme
* duyuru oluşturma
* duyuru düzenleme
* duyuru silme
* öğretmen yönetimi
* sınıf yönetimi
* sistem ayarları
* rol değiştirme
* database işlemleri
* backup/restore

Veli portalı **salt okunur** ağırlıklı olmalıdır.

---

# 7. AUTHORIZATION GÜVENLİĞİ

En önemli güvenlik kuralı:

Veli yalnızca kendi bağlı olduğu öğrencilerin kayıtlarına erişebilir.

UI seviyesinde öğrenci seçimi yeterli değildir.

Service/database sorgularında da öğrenci ↔ veli ilişkisi kontrol edilmelidir.

Örneğin:

`parentId -> linkedStudentIds -> query`

mantığı kullanılmalıdır.

Veli URL/route veya screen parametresine başka bir `studentId` göndererek başka öğrencinin bilgisine erişememelidir.

IDOR benzeri erişim açığı bırakma.

---

# 8. VELİ WORKSPACE

Mevcut:

* `AppShell`
* `AppState`
* `TabWorkspace`
* navigation
* sidebar/navbar

yapısını koru.

Veli için:

`ParentTabWorkspace`

veya mevcut naming convention'a uygun yapı oluştur.

Sidebar/Navbar tüm Veli ekranlarında korunmalıdır.

Ara ekranlara geçildiğinde shell kaybolmamalıdır.

---

# 9. VELİ SIDEBAR

Önerilen yapı:

## Veli Paneli

* Genel Bakış
* Çocuklarım
* Duyurular
* Belgeler
* Devam Durumu
* Akademik Durum

Mevcut proje navigation standardına uy.

Gereksiz menü oluşturma.

Veliye öğretmen/sekreter/admin menüleri gösterme.

---

# 10. GENEL BAKIŞ

Veli login sonrası dashboard göster.

Dashboard:

* veli adı
* bağlı öğrenci sayısı
* öğrencilerin kısa özeti
* son duyurular
* son belgeler
* son devam bilgisi

gibi salt okunur bilgiler içerebilir.

Mevcut tasarım sistemini kullan.

Yeni bağımsız UI framework oluşturma.

---

# 11. ÇOCUKLARIM

Veli birden fazla öğrenciye bağlıysa öğrencileri listele.

Her öğrenci için:

* ad soyad
* sınıf
* şube
* temel bilgiler

gösterilebilir.

Öğrenci seçildiğinde ilgili öğrenci context'i oluştur.

Seçilen öğrenci:

`AppState` veya mevcut state yönetim mekanizması üzerinden güvenli şekilde tutulmalıdır.

---

# 12. DUYURULAR

Mevcut:

`listStudentAnnouncementsForClasses`

veya mevcut duyuru servislerinden uygun olanı yeniden kullan.

Veli yalnızca bağlı öğrencisinin sınıfına/genel okul kapsamına ait **yayında** olan duyuruları görebilmelidir.

Taslak/kaldırılmış duyurular görünmemelidir.

Veli:

* oluşturamaz
* düzenleyemez
* silemez
* yayınlayamaz

---

# 13. BELGELER

Faz 6'da oluşturulan `SecretaryDocumentService` ve mevcut belge altyapısını analiz et.

Veli yalnızca kendisine/çocuğuna erişim hakkı bulunan belgeleri görebilmelidir.

Belge:

* görüntüleme
* açma
* indirme

izinlidir.

Belge:

* düzenleme
* arşivleme
* silme

izinli değildir.

Özellikle genel okul belgeleri ile öğrenciye özel belgelerin erişim kapsamını doğru ayır.

---

# 14. DEVAM / YOKLAMA

Mevcut attendance/yoklama servislerini analiz et.

Veli:

* bağlı öğrencinin devam durumunu
* devamsızlık kayıtlarını
* varsa tarih bazlı devam durumunu

salt okunur görebilir.

Mevcut veri modelinde olmayan yeni attendance özellikleri oluşturma.

Veli attendance kaydı değiştiremez.

---

# 15. AKADEMİK DURUM

Mevcut öğrenci akademik veri yapısını analiz et.

Veli için yalnızca mevcut sistemde güvenli biçimde erişilebilen bilgileri göster.

Örneğin:

* dersler
* notlar
* genel akademik özet

gösterilebilir.

Ancak bu fazda:

* not girme
* not düzenleme
* not silme
* sınav oluşturma

yapma.

Mevcut akademik yapı yeterince hazır değilse yalnızca mevcut güvenli bilgileri göster ve eksik alanları FINAL STATUS'te belirt.

---

# 16. ÖĞRENCİ CONTEXT GÜVENLİĞİ

Bir Veli birden fazla öğrenciye bağlıysa öğrenci değiştirilebilir.

Ancak her seçim öncesinde:

`selectedStudentId ∈ linkedStudentIds`

kontrolü yapılmalıdır.

Screen'e dışarıdan gelen ID güvenilir kabul edilmemelidir.

---

# 17. RESPONSIVE

Desktop:

* sidebar
* içerik alanı
* dashboard kartları
* tablo/listeler

Mobile:

* drawer/navigation
* kart/list tile
* stack edilmiş içerik

kullanılmalıdır.

Mevcut:

* `AppCard`
* `AppSpacing`
* `AppShell`
* `phoneBreakpoint`

yapılarını kullan.

Hard-coded width kullanma.

Kartlar işlevine göre yeterli genişlikte olmalıdır.

---

# 18. LOCALIZATION

TR / EN desteği zorunludur.

Yeni metinleri widget içine hard-code etme.

`app_localizations.dart` üzerinden ekle.

Gerekli örnekler:

* Veli Paneli
* Genel Bakış
* Çocuklarım
* Duyurular
* Belgeler
* Devam Durumu
* Akademik Durum
* Öğrenci seç
* Son duyurular
* Son belgeler
* Devamsızlık
* Notlar
* Bu öğrenciye erişim yetkiniz yok
* Öğrenci bulunamadı

Mevcut naming convention'a uy.

---

# 19. DATABASE

Önce mevcut database'i analiz et.

Gerekmiyorsa schema version artırma.

Veli için yeni tablo/ilişki gerçekten gerekiyorsa migration ekle.

Migration gerekiyorsa:

* schema version
* migration fonksiyonu
* eski verilerin korunması
* default/null değerler
* upgrade testi

zorunludur.

Mevcut v31 verileri kaybolmamalıdır.

---

# 20. JSON SYNC

`DatabaseSyncService` yapısını incele.

Yeni veli tabloları/ilişkileri oluşturulduysa JSON export/import kapsamına dahil et.

Aşağıdakiler korunmalıdır:

* veli
* öğrenci-veli ilişkisi
* gerekli metadata

Mevcut export/import davranışını bozma.

---

# 21. AUTHORIZATION SERVICE

AuthorizationService'e mevcut naming convention ile gerekli parent yetkilerini ekle.

Örneğin:

* `canViewOwnStudents`
* `canViewStudentAnnouncements`
* `canViewStudentDocuments`
* `canViewAttendance`
* `canViewAcademicStatus`

İsimler mevcut sistem standardına göre belirlenmelidir.

Kesinlikle:

`canEditStudent`

veya veliye yönetim yetkisi veren benzer izinleri aktif hale getirme.

---

# 22. TESTLER

Yeni test dosyası:

`test/parent_portal_faz7_test.dart`

En az şu senaryolar test edilmelidir:

## Authentication

* Veli login başarılı.
* Yanlış veli bilgisi reddediliyor.
* Login sonrası role doğru atanıyor.
* Parent workspace açılıyor.

## Student relationship

* Veli kendi öğrencisini görebiliyor.
* Birden fazla bağlı öğrenci destekleniyorsa tamamı görülebiliyor.
* Başka öğrencinin ID'si ile erişim reddediliyor.

## Announcements

* Sadece yayınlanmış ve hedefle eşleşen duyurular görünüyor.
* Taslak görünmüyor.
* Kaldırılmış görünmüyor.
* Veli duyuru oluşturamıyor.

## Documents

* Yetkili belgeler görünüyor.
* Yetkisiz öğrenci belgesi görünmüyor.
* Veli belgeyi açabiliyor/indirebiliyor.
* Veli belgeyi silemiyor/düzenleyemiyor.

## Attendance

* Bağlı öğrencinin devam bilgisi görüntüleniyor.
* Başka öğrencinin devam bilgisi görüntülenemiyor.

## Academic

* İzin verilen akademik bilgiler görüntüleniyor.
* Veli not değiştiremiyor.

## Regression

* Faz 6 belgeleri çalışıyor.
* Faz 5 duyuruları çalışıyor.
* Faz 2–4 özellikleri bozulmuyor.
* Öğretmen login çalışıyor.
* Öğrenci login çalışıyor.
* Sekreter login çalışıyor.

---

# 23. TEST STANDARDI

Sonunda:

`flutter test`

çalıştır.

Beklenti:

* yeni testler PASS
* mevcut testler PASS
* 0 failed

Önceki baseline:

**FAZ 6 → 134 passed / 0 failed**

Yeni sonuçla karşılaştır.

Test sayısındaki değişimi FINAL STATUS'te belirt.

---

# 24. MANUEL TEST

### Veli

* Login
* Workspace
* Sidebar
* Genel Bakış
* Çocuklarım
* öğrenci seçimi
* Duyurular
* Belgeler
* Belge açma
* Belge indirme
* Devam Durumu
* Akademik Durum
* Mobil görünüm

### Güvenlik

* başka öğrenci ID'si ile erişim
* başka öğrencinin duyurusu
* başka öğrencinin belgesi
* başka öğrencinin attendance bilgisi

### Regression

* Sekreter login
* Öğretmen login
* Öğrenci login
* Faz 5
* Faz 6

---

# 25. KAPSAM DIŞI

Bu fazda:

* veliye veri düzenleme
* öğrenci silme
* öğrenci ekleme
* not düzenleme
* sınav yönetimi
* öğretmen yönetimi
* belge silme
* duyuru oluşturma
* sistem ayarları
* rol yönetimi
* backup/restore
* bildirim kanalları
* push notification
* SMS
* e-mail notification

implement etme.

---

# 26. GELİŞTİRME PRENSİPLERİ

1. Önce mevcut kodu oku.
2. Mevcut veli altyapısını yeniden kullan.
3. Duplicate parent model oluşturma.
4. Duplicate authentication sistemi oluşturma.
5. Duplicate student/announcement/document service oluşturma.
6. AuthorizationService merkez olarak kullanılmalı.
7. UI authorization tek başına güvenlik değildir.
8. Student ID erişimi service seviyesinde doğrulanmalı.
9. Faz 5 ve Faz 6 bozulmamalı.
10. TR/EN zorunlu.
11. Responsive zorunlu.
12. Test yazılmadan faz tamamlanmış kabul edilmez.
13. Gereksiz database migration yapma.

---

# 27. FINAL STATUS

İşlem sonunda:

# FAZ 7 STATUS

PASS / FAIL

## Ön Analiz

Mevcut veli/öğrenci ilişkisinin özeti.

## Database

Schema ve migration durumu.

## Authentication

Veli login durumu.

## Parent Workspace

Workspace ve navigation.

## Student Relationship

Veli → öğrenci erişim modeli.

## Announcements

Veli duyuru erişimi.

## Documents

Veli belge erişimi.

## Attendance

Devam bilgisi.

## Academic

Akademik görüntüleme.

## Authorization

Veli izinleri ve erişim izolasyonu.

## Responsive

Desktop/mobile.

## Localization

TR/EN.

## JSON Sync

Durum.

## Test

Önceki baseline:
134 passed / 0 failed

Yeni test sonucu.

## Manuel Test Gerektirenler

Liste.

## Riskler

Varsa.

## Faz 8'e Kalanlar

Sonraki işlerin kısa özeti.
