# MYEDUAPP — FAZ 6

## SEKRETER BELGELER / DOKÜMAN YÖNETİMİ

## 1. AMAÇ

MyEduApp içerisindeki mevcut belge/doküman altyapısını analiz ederek, Sekreter rolü için yetki matrisiyle uyumlu bir **Belgeler / Doküman Yönetimi** modülü oluştur.

Bu fazın temel amacı:

* Sekreterin mevcut belgeleri görüntüleyebilmesi,
* belge arayabilmesi ve filtreleyebilmesi,
* yeni belge yükleyebilmesi,
* belge detaylarını görüntüleyebilmesi,
* izin verilen alanları düzenleyebilmesi,
* belgeyi açabilmesi/indirebilmesi,
* ancak kritik belgeleri silememesidir.

ÖNEMLİ:

Bu faz başlamadan önce mevcut database, service, model, screen ve navigation yapısı mutlaka analiz edilmelidir.

Mevcut belge altyapısı kullanılabiliyorsa YENİ bir paralel belge sistemi oluşturma.

Gereksiz yeni tablo, model, service veya duplicate business logic oluşturma.

---

# 2. FAZ ÖNCESİ ZORUNLU AUDIT

İlk olarak sadece kodu analiz et.

Aşağıdaki alanları tespit et:

* mevcut belge/doküman tabloları
* belge modelleri
* belge servisleri
* mevcut öğretmen belge ekranları
* öğrenci belge ekranları
* mevcut upload/download/open mekanizması
* dosya yolu / storage yaklaşımı
* database schema versiyonu
* JSON sync / backup kapsamı
* mevcut authorization kontrolleri
* mevcut navigation yapısı
* mevcut localization anahtarları

Özellikle şu sorulara cevap bul:

1. Halihazırda belge tablosu var mı?
2. Halihazırda belge servisi var mı?
3. Öğretmenlerin belge yönetimi için mevcut ekranları var mı?
4. Belgeler fiziksel dosya olarak mı, database blob/path olarak mı tutuluyor?
5. Kritik belge kavramı mevcut kodda bulunuyor mu?
6. Belge silme mevcut sistemde nasıl çalışıyor?
7. Sekreter için mevcut belge yetkileri var mı?
8. JSON export/import sırasında belgeler nasıl ele alınıyor?
9. Mevcut sistemde arşivleme/kaldırma mantığı var mı?

Audit sonucuna göre implementasyon stratejisini belirle.

Audit raporunu kod içerisinde ayrı bir dosya olarak oluşturma; final status içerisinde özetle.

---

# 3. SEKRETER YETKİLERİ

Sekreter için aşağıdaki davranış uygulanmalıdır:

ALLOWED:

* canViewDocuments
* canCreateDocument
* canEditDocument
* canOpenDocument
* canDownloadDocument

DENIED:

* canDeleteCriticalDocument

Kritik olmayan belgelerin kaldırılması/silinmesi mevcut authorization mimarisiyle ayrıca değerlendirilmelidir.

Eğer mevcut sistemde yalnızca fiziksel silme varsa, Sekreter için fiziksel silme yetkisi verme.

Bunun yerine mümkünse:

* arşivleme
* kaldırıldı durumu
* pasifleştirme

gibi geri alınabilir yöntem kullan.

Kritik belgeler için Sekreter tarafında hiçbir fiziksel silme kontrolü bulunmamalıdır.

Authorization yalnızca UI seviyesinde değil, service/database işlem seviyesinde de kontrol edilmelidir.

---

# 4. NAVIGATION

Sekreter sidebar/navigation yapısında:

## Belgeler

Sekreterin erişebileceği belge yönetim ekranını ekle.

Mevcut:

* secretary_navigation.dart
* secretary_nav_section.dart
* secretary_tab_workspace.dart
* app_shell.dart

yapısını koru.

Yeni bir bağımsız navigation sistemi oluşturma.

Sidebar ve Navbar tüm belge ekranlarında korunmalıdır.

Ara/detail/add ekranlarında Sidebar/Navbar kaybolmamalıdır.

---

# 5. BELGE LİSTESİ

Yeni veya mevcut belge listesi ekranını Sekreter kullanımına uygun hale getir.

Örnek ekran:

`SecretaryDocumentsListScreen`

Liste aşağıdaki bilgileri gösterebilir:

* Belge adı
* Kategori
* Hedef/kapsam
* Tarih
* Durum
* Kritik mi?
* İşlemler

Mevcut veri modelinde olmayan alanları sırf UI için database'e ekleme.

---

# 6. ARAMA VE FİLTRELEME

Belge listesinde:

### Arama

Belge adına göre arama.

Mevcut altyapı uygunsa:

* açıklama
* kategori

gibi alanlarda da arama yapılabilir.

### Filtreler

Mevcut veri modelinin izin verdiği ölçüde:

* kategori
* belge türü
* hedef/kapsam
* durum
* kritik / normal

filtreleri eklenebilir.

Filtreler:

* desktop'ta düzenli yatay yapı
* mobilde Wrap / responsive yapı

kullanmalıdır.

---

# 7. BELGE EKLEME

Sekreter yeni belge oluşturabilmelidir.

Form mevcut belge modeline göre tasarlanmalıdır.

Muhtemel alanlar:

* belge adı
* açıklama
* kategori
* hedef
* dosya
* kritik belge durumu

Ancak mevcut modelde olmayan alanları otomatik olarak ekleme.

Dosya yükleme mekanizması mevcut sistem kullanılarak yapılmalıdır.

Form validasyonları:

* belge adı boş olamaz
* gerekli alanlar boş bırakılamaz
* dosya gerekiyorsa dosya seçilmeden kayıt yapılamaz

Başarılı kayıt sonrası liste güncellenmelidir.

---

# 8. BELGE DETAYI

Belge detay ekranı oluştur veya mevcut ekranı yeniden kullan.

Göster:

* belge adı
* açıklama
* kategori
* hedef
* oluşturulma tarihi
* güncelleme tarihi
* durum
* kritik bilgisi
* dosya bilgisi

İşlemler:

* Aç
* İndir
* Düzenle

Kritik belge için:

* Sil/Kaldır butonu Sekreter'e gösterilmemeli
  veya disabled + açıklayıcı bilgi gösterilmelidir.

---

# 9. BELGE DÜZENLEME

Sekreter aşağıdaki alanları mevcut authorization kurallarına göre düzenleyebilir:

* başlık/ad
* açıklama
* kategori
* hedef
* diğer kritik olmayan metadata

Kritik belge özelliğini değiştirme yetkisi mevcut güvenlik modeline göre sınırlandırılmalıdır.

Bir belgeyi kritik hale getirmenin yetki yükseltmesine yol açmamasına dikkat et.

---

# 10. KRİTİK BELGE SİLME KORUMASI

Bu fazın en önemli güvenlik kurallarından biridir.

Sekreter:

* kritik belgeyi silemez
* fiziksel olarak silemez
* delete service çağrısı yapamaz

UI'da buton gizlense bile service katmanında ayrıca authorization kontrolü bulunmalıdır.

Örneğin mantık:

`if role == secretary && document.isCritical => deny`

şeklinde güvenli şekilde uygulanmalıdır.

Mevcut authorization service kullanılmalıdır.

Yeni ve bağımsız bir role-check sistemi oluşturma.

---

# 11. RESPONSIVE UI

Desktop ve mobil görünüm ayrı ayrı kontrol edilmelidir.

Desktop:

* tablo görünümü tercih edilebilir.

Mobil:

* kart/list tile görünümü kullanılabilir.

Uzun dosya isimleri layout'u bozmamalıdır.

Butonlar taşmamalıdır.

Form alanları dar ekranlarda düzgün stack edilmelidir.

Mevcut:

* AppCard
* AppSpacing
* AppShell
* phone breakpoint

yapılarını kullan.

Hard-coded ekran genişliklerinden kaçın.

---

# 12. LOCALIZATION

TR / EN desteğini koru.

Yeni metinleri doğrudan widget içine hard-code etme.

Gerekli localization anahtarlarını:

`app_localizations.dart`

üzerinden ekle.

Örneğin:

* Belgeler
* Belge Ekle
* Belge Düzenle
* Belge Detayı
* Ara
* Kategori
* Durum
* Kritik Belge
* Aç
* İndir
* Düzenle
* Sil
* Arşivle
* Bu belge kritik olduğu için silinemez
* Dosya seç
* Dosya gerekli
* Başlık gerekli

gibi metinleri TR/EN olarak tanımla.

Mevcut naming convention'a uy.

---

# 13. DATABASE

Önce mevcut belge tablosunu analiz et.

Gerekmiyorsa schema version artırma.

Migration sadece gerçekten yeni database alanı gerekiyorsa yapılmalıdır.

Eğer migration gerekiyorsa:

* yeni schema version
* migration fonksiyonu
* eski verilerin korunması
* null/default değerlerin güvenli belirlenmesi
* upgrade testi

eklenmelidir.

Mevcut belgeler kaybolmamalıdır.

---

# 14. JSON SYNC / BACKUP

Mevcut:

`DatabaseSyncService`

yapısını incele.

Belgeler zaten export/import kapsamındaysa yeniden implementasyon yapma.

Yeni alan eklendiyse JSON sync'in bu alanı kapsadığından emin ol.

Export/import sırasında:

* belge metadata'sı
* kritik durumu
* durum
* gerekli ilişkiler

korunmalıdır.

---

# 15. AUTHORIZATION

AuthorizationService'e mevcut mimariye uygun şekilde gerekli yetkileri ekle.

Sekreter:

* belge görüntüleme → ALLOW
* belge oluşturma → ALLOW
* belge düzenleme → ALLOW
* belge açma → ALLOW
* belge indirme → ALLOW
* kritik belge silme → DENY

Authorization kontrolünü:

1. Navigation
2. Screen/UI
3. Service/business logic

seviyelerinde tutarlı hale getir.

UI'da butonu gizlemek tek başına güvenlik olarak kabul edilmez.

---

# 16. TESTLER

Yeni test dosyası oluştur:

`test/secretary_documents_faz6_test.dart`

Testlerde en az aşağıdaki senaryolar bulunmalı:

### Authorization

* Sekreter belge görüntüleyebilir.
* Sekreter belge oluşturabilir.
* Sekreter belge düzenleyebilir.
* Sekreter belge açabilir.
* Sekreter belge indirebilir.
* Sekreter kritik belgeyi silemez.

### Data

* Belge listesi doğru yükleniyor.
* Arama çalışıyor.
* Filtreler çalışıyor.
* Yeni belge oluşturuluyor.
* Düzenleme çalışıyor.
* Kritik belge bilgisi korunuyor.

### Regression

* Faz 5 duyuruları çalışmaya devam ediyor.
* Faz 2–4 sekreter özellikleri bozulmuyor.
* Öğretmen login çalışıyor.
* Öğrenci login çalışıyor.
* Teacher announcement sistemi bozulmuyor.

---

# 17. TEST STANDARDI

Çalışmanın sonunda:

`flutter test`

çalıştır.

Beklenti:

* yeni testlerin tamamı PASS
* mevcut testlerin hiçbirinde regression olmaması
* 0 failed

Mevcut test sayısını raporla.

Herhangi bir test başarısızsa bunu gizleme ve başarısızlığın nedenini final status'te açıkça belirt.

---

# 18. UI MANUEL TEST CHECKLIST

Kod tamamlandıktan sonra aşağıdakileri manuel olarak kontrol edilebilecek şekilde bırak:

### Sekreter

* Login
* Sidebar → Belgeler
* Belge listesi
* Arama
* Filtre
* Yeni belge
* Dosya seçme
* Kaydet
* Detay
* Düzenle
* Aç
* İndir
* Kritik belge
* Kritik belge silme engeli
* Mobil görünüm

### Regression

* Duyurular
* Öğrenci yönetimi
* Faz 2–4 ekranları
* Öğretmen login
* Öğrenci login

---

# 19. KAPSAM DIŞI

Bu fazda aşağıdakileri implement etme:

* Veli portalı
* Bildirim sistemi
* Öğretmen yönetimi
* Öğrenci silme onayı
* Duyuru okundu takibi
* Faz 2.5 login UX
* Günlük/Yıllık akademik plan
* Yeni rol sistemi
* Gereksiz database refactor
* Gereksiz UI redesign

Bunlar sonraki fazlarda ele alınacaktır.

---

# 20. GELİŞTİRME PRENSİPLERİ

1. Önce mevcut kodu oku.
2. Mevcut belge altyapısını mümkün olduğunca yeniden kullan.
3. Duplicate service oluşturma.
4. Duplicate model oluşturma.
5. Gereksiz migration yapma.
6. AuthorizationService'i merkez olarak kullan.
7. UI authorization ile service authorization aynı kurala sahip olmalı.
8. Faz 5'i bozma.
9. Mevcut teacher/student davranışlarını değiştirme.
10. Responsive yapıyı koru.
11. TR/EN localization zorunlu.
12. Test yazmadan fazı tamamlanmış kabul etme.

---

# 21. FINAL STATUS

İşlem sonunda aşağıdaki formatta final status üret:

# FAZ 6 STATUS

PASS / FAIL

## Ön Analiz

Mevcut belge altyapısının özeti.

## Database

Değişiklik yapıldıysa schema bilgisi.

## Navigation

Sekreter Belgeler ekranı.

## Documents

Liste / arama / filtre / ekleme / düzenleme / detay.

## Authorization

Sekreter izinleri ve kritik belge koruması.

## Responsive

Desktop / mobile.

## Localization

TR/EN.

## JSON Sync

Durum.

## Test

flutter test sonucu.

## Manuel Test Gerektirenler

Liste.

## Riskler

Varsa.

## Faz 7'ye Kalanlar

Sonraki işlerin kısa özeti.

---

# FAZ 6 STATUS (tamamlanma)

PASS

## Ön Analiz

Belgeler mevcut `icerikler` tablosunda (ders içerikleri); öğretmen tarafında `FileService.copyFileToContentDir`, klasör senkronu (`dokuman_klasorleri` / `dokuman_klasor_ogeleri`) ve ders ekranları kullanılıyor. Sekreter modülü için paralel tablo açılmadı; `Okul Belgeleri` / `Evraklar` dersi (`ayarlar`: `secretary_documents_sinif_id`, `secretary_documents_ders_id`) altında `icerikler` yeniden kullanıldı.

## Database

Schema **31** (`_migrateSecretaryDocumentsV31`): `icerikler` alanları — `kritik`, `aciklama`, `guncelleme_tarihi`, `belge_kategori`, `belge_kapsam`. `DatabaseSyncService.databaseVersion = 31`; export/import `icerikler` dahil mevcut akışta.

## Navigation

`SecretaryNavSection`: `documentList`, `documentAdd`, `documentDetail`; sidebar grubu `secretaryDocumentsMenuOrder`; `AppShell` Belgeler menüsü; `SecretaryTabWorkspace` ekran switch’leri; `openSecretaryDocumentDetail` / `openSecretaryDocumentAdd`.

## Documents

- Liste: arama, kategori, arşiv, kritik filtreleri; masaüstü `DataTable`, mobil kartlar.
- Ekle: dosya seçimi (`file_picker`), metadata; düzenle: metadata (dosya değişmez).
- Detay: aç, indir, düzenle, arşivle (kritik değilse); sekreter için sil düğmesi servis engeliyle snackbar.

## Authorization

`AuthorizationService`: görüntüleme/oluşturma/düzenleme/aç/indir (sekreter+kilit açık); `canDeleteCriticalDocument` / sekreter fiziksel silme **false**; `canPhysicallyDeleteDocument` öğretmen. DB: `tryDeleteContentForRole` sekreter → her zaman false; `tryArchiveSecretaryDocument` kritik → false.

## Responsive

`AppSpacing.phoneBreakpoint`, `AppCard`, `AppShell` — duyuru modülü ile aynı desen.

## Localization

TR/EN: `secretaryDocumentsMenu`, `documentSearch`, `documentCriticalLabel`, `documentCriticalDeleteBlocked`, vb. (`app_localizations.dart`).

## JSON Sync

Sürüm 31; belge satırları `icerikler` üzerinden yedeklenir (ek tablo yok).

## Test

`flutter test`: **134 passed**, 0 failed. Yeni: `test/secretary_documents_faz6_test.dart` (**8** test). Mevcut suite’te DB/sync sürüm beklentileri 31’e güncellendi.

## Manuel Test Gerektirenler

Sekreter giriş → Belgeler menüsü; dosya seç/kaydet; aç/indir (OS); kritik belge silme/arşiv engeli UI; mobil drawer; regression: duyurular, öğrenci/veli/devamsızlık, öğretmen/öğrenci login.

## Riskler

- Kritik bayrağı şu an DB’de (sekreter UI’da oluşturulamaz); öğretmen/admin tarafında kritik işaretleme UI’sı yok — manuel DB veya sonraki faz.
- `openDocument` Windows `start` / diğer platformlarda dosya yöneticisi; sandbox ortamlarda manuel doğrulama gerekir.
- Sekreter belgeleri öğretmen ders listesinde `Okul Belgeleri` altında görünebilir (aynı `icerikler`).

## Faz 7'ye Kalanlar

Veli portalı, bildirimler, kritik belge işaretleme yetkisi, öğrenci/veli belge görünürlüğü, gelişmiş raporlama; gereksiz refactor yok.
