# FAZ DESIGN — FAZ 2 / TUR 2

## Öğrenci Detay + Dashboard + Akademik Takvim

MyEduApp görsel tasarım dönüşümünün Faz 2'si devam etmektedir.

Faz 2 başlangıç turunda:

* 13 Öğretmen Paneli → PARTIAL
* 14 Sekreter Paneli → PARTIAL
* 03 Öğrenciler → PARTIAL
* 04 Veliler → PARTIAL
* 01 Windows Giriş → PARTIAL
* 05 Öğrenci Detay → FAIL
* 02 Dashboard → FAIL
* 06 Akademik Takvim → FAIL
* 08 Duyurular → FAIL
* 09 Takvim → FAIL
* 11 Dokümanlar → FAIL
* 12 Duyuru Detay → FAIL
* 07 Mesajlar → N/A / kapsam dışı

Faz 1:

* 01 Mobil Giriş → PASS
* 10 Ayarlar → PASS
* 15 Mobil Drawer → PASS
* 16 Erişim Yok → PASS

Faz 2 başlangıç test sonucu:

```text
flutter test
216 passed / 0 failed
```

Yeni Faz 2 dosyalarında analyze error yoktur.

Ancak aşağıdaki kullanılmayan kodlar temizlenmelidir:

* `_HubActionCard`
* `_ClassCompactRow`
* `_ScheduleSidebarPanel`

---

# 1. REFERANS TASARIMLAR

Ana tasarım klasörü:

```text
docs/design/MyEduApp_design_pages_separated/
```

Bu turda öncelikli referanslar:

```text
05_ogrenci_detay.png
02_ana_sayfa_dashboard.png
06_akademik_takvim.png
```

Bunları gerçek görsel referans olarak kullan.

Sadece mevcut Flutter ekranını "güzelleştirme".

Referans görsel ile mevcut ekranı karşılaştır ve mümkün olduğunca aynı:

* layout
* spacing
* typography
* card dimensions
* colors
* border radius
* shadows
* icon placement
* navigation
* section hierarchy
* button placement
* information density

oluştur.

---

# 2. MEVCUT MİMARİYİ KORU

Bu çalışma bir UI/design implementation çalışmasıdır.

Yeni:

* authentication
* authorization
* role
* backend
* REST API
* Firebase
* database
* state-management framework

oluşturma.

Mevcut:

* AppShell
* WorkspaceAppShell
* AppState
* AuthorizationService
* mevcut services
* mevcut repositories
* mevcut localization
* mevcut Design System
* mevcut responsive utilities

kullanılmalıdır.

Business logic değiştirilmemelidir.

---

# 3. ORTAK DESIGN SYSTEM

Faz 2 başlangıcında oluşturulan:

```text
lib/theme/design_system.dart
lib/widgets/design/
```

yapılarını önce incele.

Yeni bir component oluşturmadan önce aynı işlevi yapan mevcut component olup olmadığını kontrol et.

Amaç:

> Ekranları birbirinden bağımsız tasarlamak değil, ortak MyEduApp Design System oluşturmak.

Gerekirse mevcut componentleri geliştir.

---

# 4. EKRAN 05 — ÖĞRENCİ DETAY

Referans:

```text
docs/design/MyEduApp_design_pages_separated/05_ogrenci_detay.png
```

Bu turun birinci önceliğidir.

Mevcut öğrenci detay ekranını aç ve referans görsel ile karşılaştır.

Özellikle:

## Header

* geri butonu
* sayfa başlığı
* sağdaki action alanları
* spacing
* icon boyutları

## Student Profile

Referanstaki:

* avatar
* öğrenci adı
* sınıf
* öğrenci bilgileri
* status
* profil hiyerarşisi

yaklaşımını koru.

## Information Cards

Kartların:

* genişliği
* yüksekliği
* radius
* border
* shadow
* iç padding
* icon/text hizası

referansa mümkün olduğunca yaklaştırılmalıdır.

## Action Buttons

Referanstaki:

* Düzenle
* Mesaj Gönder
* diğer mevcut action'lar

aynı görsel hiyerarşiye taşınmalıdır.

Ancak referansta olmayan gerçek bir business action oluşturma.

## Responsive

Mobilde referanstaki bilgi hiyerarşisini koru.

Desktop'ta kartlar gereksiz şekilde daralmamalıdır.

---

# 5. EKRAN 02 — DASHBOARD

Referans:

```text
docs/design/MyEduApp_design_pages_separated/02_ana_sayfa_dashboard.png
```

İkinci önceliktir.

Mevcut dashboard verilerini kullan.

Referans görseldeki yapıya yaklaş:

## Üst bölüm

* welcome message
* kullanıcı bilgisi
* header action'ları
* search
* notification
* profile

## KPI Cards

Referanstaki stat card yapısını incele.

Her kart için:

* icon
* sayı
* label
* küçük açıklama
* renk
* spacing

uygula.

Mevcut dashboard'da bulunan gerçek verileri kullan.

Sahte KPI üretme.

## Duyurular

Referanstaki announcement/activity card yapısını mevcut duyuru verilerine uygula.

## Calendar

Referanstaki sağ kolon calendar yapısını mümkün olduğunca mevcut calendar verileriyle oluştur.

## Upcoming Events

Mevcut event verileri varsa referanstaki card yapısına yerleştir.

## Desktop Layout

Desktop'ta:

* ana içerik
* sağ kolon

arasındaki oranları referansa yaklaştır.

Kartların işlevlerine göre aşırı dar kalmasına izin verme.

## Mobile

Desktop layout'u basitçe küçültme.

Mobilde bilgi hiyerarşisini koruyan tek/iki kolonlu responsive yapı kullan.

---

# 6. EKRAN 06 — AKADEMİK TAKVİM

Referans:

```text
docs/design/MyEduApp_design_pages_separated/06_akademik_takvim.png
```

Üçüncü önceliktir.

Mevcut Academic Calendar implementation'ını incele.

Referanstaki:

* üst header
* ay navigation
* gün satırı
* tarih hücreleri
* selected day
* event indicator
* event list
* bottom navigation
* card/container spacing

yapısını mümkün olduğunca eşleştir.

Mevcut academic calendar verileri korunmalıdır.

Yeni akademik veri modeli oluşturma.

---

# 7. PIXEL ACCURACY

Her ekran için şu kontrol yapılmalıdır:

### Geometry

* page padding
* card width
* card height
* column gap
* row gap
* sidebar width
* header height

### Typography

* font family
* font size
* weight
* line height
* text hierarchy

### Visual

* background
* border
* radius
* shadow
* icon
* badge
* pill

### Interaction

* hover
* pressed
* selected
* disabled
* focus

Mümkün olduğunca referans görseldeki oranları kullan.

Flutter platform rendering farklılıkları nedeniyle fiziksel pixel-level birebir mümkün olmayan durumlarda:

> geometry + spacing + typography + visual hierarchy

önceliklidir.

---

# 8. RESPONSIVE

Bu turda gerçek responsive kontrol yapılmalıdır.

Kontrol edilecek genişlikler:

```text
360
390
430
768
1024
1280
1440
1920
```

Her ekran için kontrol:

* horizontal overflow
* RenderFlex overflow
* clipped text
* clipped card
* inaccessible button
* dialog overflow
* keyboard overlap
* navigation overlap

Responsive kodda mevcut:

```text
AppSpacing
```

ve diğer responsive utilities kullanılmalıdır.

---

# 9. ACCESSIBILITY

Bu turda en azından:

* Semantics
* button labels
* icon labels
* tooltip
* touch target
* focus
* keyboard navigation
* text contrast

kontrol edilmelidir.

Özellikle:

* geri butonu
* profile action
* edit
* message
* calendar navigation
* selected date

anlamlı accessibility label'a sahip olmalıdır.

---

# 10. DEAD CODE CLEANUP

Faz 2 başlangıç turundan kalan kullanılmayan kodları incele:

```text
_HubActionCard
_ClassCompactRow
_ScheduleSidebarPanel
```

Gerçekten kullanılmıyorsa kaldır.

Eğer ilerleyen bir ekran için gerekli olacaksa neden korunması gerektiğini belirle.

Kullanılmayan kod bırakıp warning üretme.

---

# 11. TEST

Mevcut testlerin tamamını çalıştır:

```bash
flutter test
```

Hedef:

```text
0 failed
```

Özellikle regression:

* login
* Settings
* Drawer
* Access Denied
* Teacher
* Secretary
* Student
* Parent
* Authorization
* Notification
* Backup/Restore

korunmalıdır.

Yeni UI testleri ekle:

```text
Student Detail
Dashboard
Academic Calendar
```

mümkün olduğunca widget seviyesinde test edilmelidir.

---

# 12. ANALYZE

Çalıştır:

```bash
flutter analyze
```

Yeni warning/error oluşmamalıdır.

Özellikle Faz 2 başlangıç raporundaki üç unused declaration artık warning üretmemelidir.

---

# 13. DOCUMENTATION

Güncelle:

```text
docs/actions/faz_design_cursor_plan.md
docs/actions/faz_13_14.md
```

Ve bu turun sonucunu:

```text
docs/actions/faz_design_faz2_tur2_status.md
```

dosyasına yaz.

---

# 14. EKRAN DURUMU

Final raporda:

```text
05 Öğrenci Detay       PASS/PARTIAL/FAIL
02 Dashboard           PASS/PARTIAL/FAIL
06 Akademik Takvim     PASS/PARTIAL/FAIL
```

olarak raporla.

Önceki ekranların regression durumunu ayrıca belirt:

```text
13 Teacher Panel       PASS/PARTIAL/FAIL
14 Secretary Panel     PASS/PARTIAL/FAIL
03 Students            PASS/PARTIAL/FAIL
04 Parents             PASS/PARTIAL/FAIL
01 Windows Login       PASS/PARTIAL/FAIL
10 Settings            PASS
15 Drawer              PASS
16 Access Denied       PASS
```

---

# 15. FINAL STATUS

Aşağıdaki formatı kullan:

```text
FAZ DESIGN — FAZ 2 / TUR 2 STATUS

05 Öğrenci Detay       PASS/PARTIAL/FAIL
02 Dashboard           PASS/PARTIAL/FAIL
06 Akademik Takvim     PASS/PARTIAL/FAIL

Regression:
13 Teacher Panel       PASS/PARTIAL/FAIL
14 Secretary Panel     PASS/PARTIAL/FAIL
03 Students            PASS/PARTIAL/FAIL
04 Parents             PASS/PARTIAL/FAIL
01 Windows Login       PASS/PARTIAL/FAIL
10 Settings            PASS
15 Drawer              PASS
16 Access Denied       PASS

Responsive             PASS/PARTIAL/FAIL
Accessibility           PASS/PARTIAL/FAIL

flutter test            X passed / Y failed
flutter analyze         result

Dead Code:
- ...

Files Changed:
- ...

Tests Added:
- ...

Technical Debt:
- ...

Final Assessment:
PASS / PARTIAL / FAIL
```

Gerçekte tamamlanmayan hiçbir ekran PASS olarak işaretlenmemelidir.

---

# 16. SONRAKİ FAZ

Bu turun sonunda 05 + 02 + 06 tamamlandıktan sonra sıradaki tasarım ekranları:

```text
08 Duyurular
09 Takvim
11 Dokümanlar
12 Duyuru Detay
```

olacaktır.

07 Mesajlar halen kapsam dışıdır.

Önce bu üç ekranın görsel kalitesini mümkün olduğunca yükselt.

Yeni feature geliştirme yerine mevcut feature'ların referans tasarıma aktarılmasına odaklan.
