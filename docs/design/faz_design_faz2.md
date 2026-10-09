# FAZ DESIGN — FAZ 2

## Öğretmen/Sekreter Panelleri + Liste/Detay Ekranları + Windows Giriş

MyEduApp'in görsel tasarım dönüşümünün Faz 1'i tamamlanmıştır.

Faz 1 sonucu:

* 01 Giriş: mobil tasarım uygulandı.
* 10 Ayarlar: tasarım uygulandı.
* 15 Mobil Drawer: tasarım uygulandı.
* 16 Erişim Yok: tasarım uygulandı.
* `flutter test`: 216 passed.
* P9/P10 authorization yapısı korunmuştur.
* Notification scope korunmuştur.
* Backup/restore authorization korunmuştur.

Faz 1 dokümantasyonu:

```text
docs/actions/faz_design_cursor_plan.md
docs/actions/faz_13_14.md
```

## TASARIM REFERANSI

Ana referans klasörü:

```text
docs/design/MyEduApp_design_pages_separated/
```

Bu klasördeki tasarım görselleri gerçek UI referansıdır.

Özellikle:

```text
13_ogretmen_paneli.png
14_sekreter_paneli.png
03_ogrenciler.png
04_veliler.png
05_ogrenci_detay.png
02_ana_sayfa_dashboard.png
06_akademik_takvim.png
08_duyurular.png
09_takvim.png
11_dokumanlar.png
12_duyuru_detay.png
01_giris_ekrani.png
```

dosyalarını ilgili ekranların görsel referansı olarak kullan.

---

# 1. ANA AMAÇ

Bu fazın amacı:

> MyEduApp'in mevcut çalışan fonksiyonlarını koruyarak, seçilen ekranları `docs/design/MyEduApp_design_pages_separated/` içindeki referans görsellerle mümkün olduğunca piksel seviyesinde eşleştirmek ve aynı tasarım sistemini mobil + Windows platformlarında tutarlı hale getirmektir.

Bu yalnızca renk veya font değişikliği değildir.

Aşağıdaki unsurlar görsel referansla karşılaştırılmalıdır:

* layout
* spacing
* card ölçüleri
* sidebar
* top bar
* navigation
* typography
* iconlar
* border radius
* border
* shadow
* background
* button ölçüleri
* avatar
* table/list yapısı
* section başlıkları
* empty state
* action alanları
* responsive davranış

---

# 2. KRİTİK KURAL — MEVCUT MİMARİ KORUNACAK

Yeni:

* authentication sistemi
* role sistemi
* authorization sistemi
* backend
* API
* database sistemi
* repository mimarisi
* state management sistemi

oluşturma.

Mevcut:

* `AppShell`
* `WorkspaceAppShell`
* `AppState`
* `AuthorizationService`
* mevcut servisler
* mevcut navigation
* mevcut localization
* mevcut responsive utilities

kullanılmalıdır.

Görsel tasarım için mevcut çalışan business logic değiştirilmemelidir.

---

# 3. HEDEF ROLLER

Bu fazda özellikle:

* Teacher
* Secretary

workspace'leri ele alınacaktır.

Mevcut role authorization korunmalıdır.

Bir Teacher ekranı Secretary'ye yanlışlıkla gösterilmemelidir.

Secretary için mevcut izin modeli değişmemelidir.

UI değişikliği authorization anlamına gelmemelidir.

---

# 4. EKRAN 13 — ÖĞRETMEN PANELİ

Referans:

```text
docs/design/MyEduApp_design_pages_separated/13_ogretmen_paneli.png
```

Mevcut Teacher workspace'i bu görselin yapısına mümkün olduğunca yaklaştır.

Özellikle:

## Sol navigation

* MyEduApp logo/branding
* Ana Sayfa
* Öğrenciler
* Veliler
* Duyurular
* Takvim
* Mesajlar
* Ayarlar
* alt profil alanı
* kullanıcı adı
* rol bilgisi
* logout

## Ana içerik

Görseldeki:

* "Öğretmen Paneli"
* sınıf kartları
* sınıf listesi
* güncel dersler
* ders kartları
* section spacing
* card layout

yaklaşımını uygula.

Mevcut Teacher işlevlerini koru.

Tasarım görselinde olmayan bir özelliği sırf görseli doldurmak için oluşturma.

---

# 5. EKRAN 14 — SEKRETER PANELİ

Referans:

```text
docs/design/MyEduApp_design_pages_separated/14_sekreter_paneli.png
```

Secretary workspace'i aynı tasarım sistemine getir.

Özellikle:

* navigation
* profile area
* Öğrenci İşlemleri
* Veli İşlemleri
* Raporlar
* action cards
* section grouping
* spacing
* iconlar
* card ölçüleri

referans görseldeki yapıya uygun olmalıdır.

Mevcut Secretary authorization ve feature kapsamını değiştirme.

---

# 6. EKRAN 03 — ÖĞRENCİLER

Referans:

```text
docs/design/MyEduApp_design_pages_separated/03_ogrenciler.png
```

Öğrenci liste ekranını görsele yaklaştır.

Özellikle:

* page header
* search
* filter
* Yeni Öğrenci
* table/card görünümü
* avatar
* öğrenci adı
* sınıf
* veli
* durum
* action buttons
* pagination
* spacing

korunmalıdır.

Desktop Windows'ta görseldeki tablo yaklaşımı kullanılabilir.

Mobilde aynı bilgi hiyerarşisi responsive card/list yapısına dönüşebilir.

Ama görsel kimliği korunmalıdır.

---

# 7. EKRAN 04 — VELİLER

Referans:

```text
docs/design/MyEduApp_design_pages_separated/04_veliler.png
```

Veli liste ekranını referansa göre düzenle.

Özellikle:

* search
* Yeni Veli
* filter
* avatar
* ad soyad
* telefon
* öğrenci
* durum
* action
* pagination
* table/card spacing

kontrol edilmelidir.

Mevcut Veli authorization ve veri yapısı korunmalıdır.

---

# 8. EKRAN 05 — ÖĞRENCİ DETAY

Referans:

```text
docs/design/MyEduApp_design_pages_separated/05_ogrenci_detay.png
```

Öğrenci detay ekranını görsel yapıya yaklaştır.

Özellikle:

* geri navigation
* öğrenci profil alanı
* avatar
* ad
* sınıf
* veli bilgileri
* durum
* bilgi blokları
* action buttons
* tab/section düzeni

referansla karşılaştırılmalıdır.

Mevcut öğrenci detay fonksiyonları korunmalıdır.

---

# 9. EKRAN 02 — ANA SAYFA / DASHBOARD

Referans:

```text
docs/design/MyEduApp_design_pages_separated/02_ana_sayfa_dashboard.png
```

Dashboard'u görsele yaklaştır.

Özellikle:

* welcome header
* KPI/stat cards
* announcements
* calendar
* upcoming events
* activity sections
* sağ/sol kolon dengesi
* card spacing
* typography

uygulanmalıdır.

Mevcut dashboard verileri korunmalıdır.

Görselde bulunan ama mevcut uygulamada olmayan gerçek bir feature için sahte veri veya sahte business logic ekleme.

Gerekirse yalnızca mevcut verileri tasarım yapısına yerleştir.

---

# 10. EKRAN 06 — AKADEMİK TAKVİM

Referans:

```text
docs/design/MyEduApp_design_pages_separated/06_akademik_takvim.png
```

Mevcut Academic Calendar ekranını referansa yaklaştır.

Özellikle:

* header
* ay navigation
* günler
* event indicators
* event list
* bottom navigation
* spacing
* typography

kontrol edilmelidir.

---

# 11. EKRAN 08 — DUYURULAR

Referans:

```text
docs/design/MyEduApp_design_pages_separated/08_duyurular.png
```

Duyurular ekranını referansa yaklaştır.

Özellikle:

* filter chips
* announcement cards
* iconlar
* tarih
* kategori
* spacing
* search/action alanları

uygulanmalıdır.

Announcement read/unread backend/DB davranışını değiştirme.

---

# 12. EKRAN 09 — TAKVİM

Referans:

```text
docs/design/MyEduApp_design_pages_separated/09_takvim.png
```

Takvim ekranını referansa yaklaştır.

Mevcut takvim işlevleri korunmalıdır.

---

# 13. EKRAN 11 — DOKÜMANLAR

Referans:

```text
docs/design/MyEduApp_design_pages_separated/11_dokumanlar.png
```

Doküman ekranını görsel referansa göre düzenle.

Özellikle:

* filter
* document cards
* file icon
* tarih
* kategori
* action
* spacing
* responsive list

kontrol edilmelidir.

Mevcut document authorization korunmalıdır.

---

# 14. EKRAN 12 — DUYURU DETAY

Referans:

```text
docs/design/MyEduApp_design_pages_separated/12_duyuru_detay.png
```

Duyuru detay ekranını referansa yaklaştır.

Özellikle:

* hero/image
* title
* date
* category
* content
* CTA/action
* read state

görsel hiyerarşisi korunmalıdır.

Mevcut announcement davranışı değiştirilmemelidir.

---

# 15. WINDOWS GİRİŞ EKRANI

Faz 1'de:

* mobil giriş tasarımı uygulanmış,
* Windows girişinde `HomeRoleGrid` kalmıştır.

Bu fazda Windows giriş ekranını da tasarım sistemiyle uyumlu hale getir.

Referans:

```text
docs/design/MyEduApp_design_pages_separated/01_giris_ekrani.png
```

Ancak mobil ekranı Windows'a birebir ölçeklemek yerine:

> aynı tasarım dili + aynı görsel hiyerarşi + Windows için uygun geniş layout

uygulanmalıdır.

Örneğin:

* sol branding/illustration
* sağ login card
* rol seçimi
* username
* password
* remember me
* forgot password
* login button

aynı tasarım sistemini kullanmalıdır.

Mevcut login/security logic kesinlikle değiştirilmemelidir.

---

# 16. RESPONSIVE TASARIM

Bu fazda yalnızca desktop görüntüsü hedeflenmeyecektir.

Kontrol:

### Mobile

* 360 px
* 390 px
* 430 px

### Tablet

* portrait
* landscape

### Windows/Desktop

* 1280 px
* 1440 px
* 1920 px

Özellikle:

* card width
* sidebar
* topbar
* table → responsive card
* drawer
* bottom navigation
* page padding
* dialog
* form
* action buttons

kontrol edilmelidir.

---

# 17. PIXEL-ACCURACY YAKLAŞIMI

Referans görseldeki değerleri yaklaşık olarak değil, mümkün olduğunca ölçerek uygula.

Özellikle:

* renkler
* font size
* font weight
* line height
* border radius
* spacing
* card elevation
* icon size
* button height
* sidebar width
* topbar height

kontrol edilmelidir.

Ancak platforma özgü Flutter rendering farklılıkları nedeniyle gerçek fiziksel piksel eşleşmesi mümkün değilse:

> görsel oran + layout + spacing + renk + typography + component hierarchy

maksimum düzeyde korunmalıdır.

"Benzer" tasarım yeterli kabul edilmemelidir.

---

# 18. TASARIM SİSTEMİ

Tek tek ekranlara rastgele stil verme.

Mümkün olduğunca ortak reusable componentler oluştur veya mevcut componentleri genişlet:

* AppSidebar
* AppTopBar
* AppCard
* StatCard
* ProfileHeader
* SearchField
* FilterChip
* PrimaryButton
* SecondaryButton
* EmptyState
* ResponsiveTable/Card
* SectionHeader

Ancak bu componentlerden biri zaten mevcutsa yenisini oluşturma.

Amaç:

> 16 ekranın tamamında tek bir MyEduApp Design System oluşmasıdır.

---

# 19. ICON / IMAGE KURALI

Referans görseldeki icon anlamları korunmalıdır.

Mevcut proje assetleri varsa kullanılmalıdır.

Yeni asset gerekiyorsa:

* mevcut asset sistemini kullan,
* gereksiz dependency ekleme,
* icon anlamını değiştirme.

Logo, branding ve mevcut uygulama identity korunmalıdır.

---

# 20. BUSINESS LOGIC KURALI

Bu faz görsel/UI fazıdır.

Aşağıdaki davranışları bozma:

* login
* role authorization
* Settings authorization
* backup/restore
* notification scope
* Student/Parent/Secretary authorization
* Teacher authorization
* database işlemleri
* existing CRUD
* navigation guards

Görsel değişiklik için business logic değiştirmek gerekiyorsa önce mevcut yapıyı incele ve minimum değişiklik yap.

---

# 21. TEST

Mevcut testlerin tamamı çalıştırılmalıdır:

```bash
flutter test
```

Hedef:

```text
0 failed
```

Faz 1 sonunda:

```text
216 passed
```

durumu korunmalıdır veya yeni testler eklenmişse toplam sayı artabilir.

Yeni UI testleri ekle.

Özellikle:

* Teacher panel
* Secretary panel
* Student list
* Parent list
* Student detail
* Dashboard
* Calendar
* Announcements
* Documents
* Login
* responsive navigation

test edilmelidir.

---

# 22. ANALYZE

Çalıştır:

```bash
flutter analyze
```

Yeni:

* error
* warning
* unused import
* dead code
* deprecated API

oluşturulmamalıdır.

Pre-existing sorunları yeni sorunlardan ayır.

---

# 23. ACCESSIBILITY

Kontrol et:

* Semantics
* tooltip
* touch target
* keyboard/focus
* form labels
* navigation labels
* contrast
* icon-only buttons

---

# 24. DOCUMENTATION

Güncelle:

```text
docs/actions/faz_design_cursor_plan.md
docs/actions/faz_13_14.md
```

Gerekirse yeni bir Faz 2 status dokümanı oluştur.

Dokümantasyonda her ekranı ayrı değerlendir:

```text
01 Login             PASS/PARTIAL/FAIL
02 Dashboard         PASS/PARTIAL/FAIL
03 Students          PASS/PARTIAL/FAIL
04 Parents           PASS/PARTIAL/FAIL
05 Student Detail    PASS/PARTIAL/FAIL
06 Academic Calendar PASS/PARTIAL/FAIL
07 Messages          OUT OF SCOPE
08 Announcements     PASS/PARTIAL/FAIL
09 Calendar          PASS/PARTIAL/FAIL
10 Settings          PASS
11 Documents         PASS/PARTIAL/FAIL
12 Announcement      PASS/PARTIAL/FAIL
13 Teacher Panel     PASS/PARTIAL/FAIL
14 Secretary Panel   PASS/PARTIAL/FAIL
15 Drawer            PASS
16 Access Denied     PASS
```

---

# 25. FINAL STATUS

Final rapor şu formatta olmalıdır:

```text
FAZ DESIGN — FAZ 2 STATUS

01 Login               PASS/PARTIAL/FAIL
02 Dashboard           PASS/PARTIAL/FAIL
03 Students            PASS/PARTIAL/FAIL
04 Parents             PASS/PARTIAL/FAIL
05 Student Detail      PASS/PARTIAL/FAIL
06 Academic Calendar   PASS/PARTIAL/FAIL
07 Messages            OUT OF SCOPE
08 Announcements       PASS/PARTIAL/FAIL
09 Calendar             PASS/PARTIAL/FAIL
10 Settings             PASS
11 Documents            PASS/PARTIAL/FAIL
12 Announcement Detail  PASS/PARTIAL/FAIL
13 Teacher Panel        PASS/PARTIAL/FAIL
14 Secretary Panel      PASS/PARTIAL/FAIL
15 Mobile Drawer        PASS
16 Access Denied        PASS

Windows Login           PASS/PARTIAL/FAIL
Responsive              PASS/PARTIAL/FAIL
Accessibility            PASS/PARTIAL/FAIL

flutter test             X passed / Y failed
flutter analyze          result

Files Changed:
- ...

Tests Added:
- ...

Documentation:
- ...

Technical Debt:
- ...

Final Assessment:
PASS / PARTIAL / FAIL
```

Gerçekten tamamlanmayan bir ekran PASS olarak raporlanmamalıdır.

---

# 26. KAPSAM DIŞI

Bu fazda:

* 07 Mesajlar için yeni backend oluşturma
* yeni authentication
* yeni authorization
* yeni database
* Firebase
* REST API
* OAuth/JWT
* yeni role sistemi
* unrelated business feature
* notification backend değişikliği

yapılmayacaktır.

07 Mesajlar ekranı ayrı bir fazda değerlendirilecektir.

---

# 27. SON HEDEF

Bu faz sonunda amaç:

> MyEduApp'in ana Windows ve mobil ekranlarının aynı profesyonel tasarım sistemine sahip olması ve referans görsellerdeki UI yapısına mümkün olduğunca birebir yaklaşmasıdır.

Sadece "güzel" bir UI oluşturma.

Referans görselleri aç, mevcut ekranı aç, karşılaştır ve farkları tek tek kapat.

Önce mevcut sistemi anla.

Sonra minimum güvenli değişiklikle uygula.
