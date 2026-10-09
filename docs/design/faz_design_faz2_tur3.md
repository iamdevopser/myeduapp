# FAZ DESIGN — FAZ 2 / TUR 3

## Duyurular + Takvim + Dokümanlar + Duyuru Detay

MyEduApp görsel tasarım dönüşümüne devam edilmektedir.

## Önceki durum

### Faz 1

* 01 Mobil Login → PASS
* 10 Settings → PASS
* 15 Mobile Drawer → PASS
* 16 Access Denied → PASS

### Faz 2 / Tur 1

* 13 Teacher Panel → PARTIAL
* 14 Secretary Panel → PARTIAL
* 03 Students → PARTIAL
* 04 Parents → PARTIAL
* 01 Windows Login → PARTIAL

### Faz 2 / Tur 2

* 05 Student Detail → PARTIAL
* 02 Dashboard → PARTIAL
* 06 Academic Calendar → PARTIAL

Son Tur sonucu:

```text
flutter test
219 passed / 0 failed
```

Dead code temizlendi ve Faz 2 Design System genişletildi.

---

# 1. BU TURUN ANA HEDEFİ

Bu turda aşağıdaki dört ekranı referans görsellerle mümkün olduğunca yüksek görsel doğrulukla eşleştir:

```text
08 — Duyurular
09 — Takvim
11 — Dokümanlar
12 — Duyuru Detay
```

Öncelik:

```text
08 → 12 → 09 → 11
```

Özellikle **08 Duyurular** ve **12 Duyuru Detay** aynı görsel tasarım sisteminin iki parçası olarak ele alınmalıdır.

---

# 2. REFERANS GÖRSELLER

Ana klasör:

```text
docs/design/MyEduApp_design_pages_separated/
```

Bu turda mutlaka şu görselleri aç:

```text
08_duyurular.png
09_takvim.png
11_dokumanlar.png
12_duyuru_detay.png
```

Ayrıca ortak tasarım dili için:

```text
02_ana_sayfa_dashboard.png
05_ogrenci_detay.png
13_ogretmen_paneli.png
14_sekreter_paneli.png
```

görsellerini de gerektiğinde karşılaştır.

Referans görseller yalnızca renk referansı değildir.

Şunlar mümkün olduğunca eşleştirilecektir:

* layout
* page padding
* card dimensions
* spacing
* typography
* icon placement
* border radius
* borders
* shadows
* pills
* buttons
* filters
* search
* navigation
* image/hero
* information hierarchy
* responsive behavior

---

# 3. MEVCUT DESIGN SYSTEM

Önce mevcut yapıların tamamını incele:

```text
lib/theme/design_system.dart
lib/widgets/design/
```

Önce mevcut reusable componentleri kullan.

Yeni component oluşturmadan önce aynı işi yapan component olup olmadığını kontrol et.

Örneğin mevcut:

* DesignCard
* DesignStatCard
* DesignListPageHeader
* DesignPillTabs
* DesignInfoRow
* DesignMiniMonthCalendar
* diğer design components

uygunsa bunları genişlet/reuse et.

Amaç:

> Her ekranın ayrı bir tasarım dili oluşturması değil, MyEduApp'in tek bir Design System kullanmasıdır.

---

# 4. MEVCUT MİMARİ KORUNACAK

Bu bir UI/design implementation turudur.

Yeni:

* authentication
* authorization
* role sistemi
* backend
* REST API
* Firebase
* database
* yeni state management
* yeni navigation architecture

oluşturma.

Mevcut:

* AppShell
* WorkspaceAppShell
* AppState
* AuthorizationService
* mevcut services
* mevcut repositories
* mevcut localization
* mevcut notification scope
* mevcut document authorization
* mevcut announcement data

korunmalıdır.

UI değişiklikleri business logic'i bozmamalıdır.

---

# 5. EKRAN 08 — DUYURULAR

Referans:

```text
docs/design/MyEduApp_design_pages_separated/08_duyurular.png
```

Bu turun birinci önceliğidir.

Mevcut announcements ekranını aç ve referans görselle karşılaştır.

## Header

Referanstaki:

* sayfa başlığı
* search
* notification/action alanları
* profile
* spacing

yapısını mümkün olduğunca eşleştir.

## Filter

Referanstaki:

* Tümü
* Okul
* Sınıf
* Veli

veya mevcut uygulamadaki karşılık gelen filter yapısını aynı görsel hiyerarşiye taşı.

Mevcut filter davranışını bozma.

## Announcement Cards

Her announcement card için:

* icon
* kategori
* title
* açıklama
* tarih
* read/unread görünümü
* action

görsel referansa yaklaştırılmalıdır.

Özellikle önceki Tur 2 raporunda eksik kalan:

> kategori pill'leri ve açıklama satırları

bu turda ele alınmalıdır.

Ancak mevcut veri modelinde açıklama yoksa sahte içerik üretme.

Mevcut announcement alanlarını kullan.

## Read / Unread

P9'da korunan:

```text
listForCurrentUser
markAsRead
```

scope davranışını değiştirme.

Yeni read/unread database modeli oluşturma.

## Responsive

Desktop:

* referanstaki geniş card/list yapısı

Mobile:

* aynı information hierarchy
* daha dar card
* uygun padding
* overflow olmadan

uygulanmalıdır.

---

# 6. EKRAN 12 — DUYURU DETAY

Referans:

```text
docs/design/MyEduApp_design_pages_separated/12_duyuru_detay.png
```

Bu ekran 08 ile aynı Design System'i kullanmalıdır.

## Hero / Image

Referansta bulunan:

* büyük görsel
* rounded container
* image ratio
* spacing

yapısını mevcut announcement image/asset yapısıyla uygula.

Mevcut announcement'ta görsel yoksa sahte görsel üretme.

## Header / Back

* geri butonu
* başlık
* action alanı
* spacing

referansa uygun olmalıdır.

## Metadata

* kategori
* tarih
* durum

referanstaki hierarchy ile gösterilmelidir.

## Content

Announcement içeriği:

* title
* description/content
* paragraphs
* spacing

referansa uygun şekilde gösterilmelidir.

## CTA

Referanstaki:

```text
Okundu olarak işaretle
```

veya mevcut karşılığı varsa aynı görsel hiyerarşiyle uygulanmalıdır.

Mevcut `markAsRead` behavior kullanılmalıdır.

Yeni notification/announcement backend oluşturma.

---

# 7. EKRAN 09 — TAKVİM

Referans:

```text
docs/design/MyEduApp_design_pages_separated/09_takvim.png
```

Mevcut Calendar ekranını incele.

Referanstaki:

* header
* month/year
* navigation
* selected date
* day cells
* event indicators
* today's events
* event cards
* bottom navigation / desktop navigation

yapısını eşleştir.

Mevcut calendar/event verilerini kullan.

Yeni event modeli oluşturma.

## Important

Tur 2'de Academic Calendar için:

* ay navigation
* gün seçimi
* header

konularında teknik borç bırakılmıştı.

Bu turda 09 Takvim'i yaparken 06 Academic Calendar'daki mevcut componentleri mümkün olduğunca ortaklaştır.

İki farklı calendar için iki ayrı tasarım sistemi oluşturma.

---

# 8. EKRAN 11 — DOKÜMANLAR

Referans:

```text
docs/design/MyEduApp_design_pages_separated/11_dokumanlar.png
```

Mevcut document screen'i referansla karşılaştır.

## Header

* title
* search
* filter
* actions

## Filters

Mevcut document scope ve authorization korunarak:

* Tümü
* Okul
* Sınıf
* Veli
* diğer mevcut kategoriler

referans yapısına yaklaştırılmalıdır.

## Document Cards

Kartlarda:

* file icon
* document name
* type
* size
* date
* category
* action

görsel hierarchy'ye uygun olmalıdır.

Mevcut document data modelinde bulunmayan bilgileri sahte olarak oluşturma.

## Authorization

Mevcut document authorization korunmalıdır.

UI üzerinden gizlemek yeterli değildir; servis katmanı davranışı değişmemelidir.

---

# 9. RESPONSIVE TASARIM

Bu turda gerçek responsive QA yapılmalıdır.

Kontrol genişlikleri:

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

Her ekran için:

* horizontal overflow
* RenderFlex overflow
* clipped text
* card overflow
* button overflow
* image overflow
* dialog overflow
* keyboard overlap
* navigation overlap

kontrol edilmelidir.

---

# 10. MOBILE

Mobil tasarım:

> Desktop ekranın küçültülmüş hali olmamalıdır.

Referans görsellerdeki mobil bilgi hiyerarşisi korunmalıdır.

Özellikle:

* bottom navigation
* drawer
* page padding
* card width
* filter chips
* search
* action buttons

uygun şekilde adapte edilmelidir.

---

# 11. WINDOWS / DESKTOP

Windows'ta:

* geniş layout
* sidebar
* topbar
* table/list
* multi-column content

kullanılmalıdır.

Ancak referans mobil düzeni desktop'a doğrudan büyütme.

---

# 12. ACCESSIBILITY

Kontrol et:

* Semantics
* button labels
* icon labels
* tooltip
* touch target
* keyboard focus
* keyboard navigation
* text contrast

Özellikle:

* back button
* filter buttons
* announcement cards
* calendar navigation
* date selection
* document actions
* mark-as-read

erişilebilir olmalıdır.

---

# 13. TEST

Çalıştır:

```bash
flutter test
```

Önceki baseline:

```text
219 passed / 0 failed
```

korunmalıdır.

Yeni testler ekle:

```text
test/design_tur3_test.dart
```

ve mümkün olduğunca:

* Announcements
* Announcement Detail
* Calendar
* Documents

widget seviyesinde test edilmelidir.

Authorization regression da korunmalıdır.

---

# 14. ANALYZE

Çalıştır:

```bash
flutter analyze
```

Yeni error/warning oluşturma.

Pre-existing info ile yeni warning/error'ları birbirinden ayır.

---

# 15. DOCUMENTATION

Güncelle:

```text
docs/actions/faz_design_cursor_plan.md
docs/actions/faz_13_14.md
docs/actions/faz_design_faz2_status.md
```

Yeni durum dosyası:

```text
docs/actions/faz_design_faz2_tur3_status.md
```

oluştur.

---

# 16. EKRAN STATUS

Final raporda:

```text
08 Duyurular          PASS/PARTIAL/FAIL
09 Takvim             PASS/PARTIAL/FAIL
11 Dokümanlar         PASS/PARTIAL/FAIL
12 Duyuru Detay       PASS/PARTIAL/FAIL
```

olarak belirt.

Önceki ekran regression:

```text
05 Öğrenci Detay      PASS/PARTIAL/FAIL
02 Dashboard          PASS/PARTIAL/FAIL
06 Academic Calendar  PASS/PARTIAL/FAIL
13 Teacher Panel      PASS/PARTIAL/FAIL
14 Secretary Panel    PASS/PARTIAL/FAIL
03 Students           PASS/PARTIAL/FAIL
04 Parents            PASS/PARTIAL/FAIL
01 Windows Login      PASS/PARTIAL/FAIL
10 Settings           PASS
15 Drawer             PASS
16 Access Denied      PASS
```

07 Messages:

```text
N/A — OUT OF SCOPE
```

---

# 17. PIXEL ACCURACY

Her ekran için görsel farkları kapat.

Kontrol:

### Geometry

* width
* height
* padding
* margin
* gap
* alignment

### Typography

* size
* weight
* line-height
* hierarchy

### Visual

* background
* border
* radius
* shadow
* icon
* pill
* badge

### Interaction

* hover
* pressed
* selected
* disabled
* focus

"Yaklaşık benzer" sonucu yeterli değildir.

Flutter platform rendering farkları nedeniyle gerçek fiziksel pixel equality mümkün değilse bile görsel oran ve hierarchy maksimum düzeyde korunmalıdır.

---

# 18. SONRAKİ TEKNİK BORÇ

Bu turda mevcut teknik borçlar unutulmamalıdır:

### 05

* gerçek Notlar UI/data bağlantısı
* Devamsızlık sekmesinin tam ekran davranışı

### 06

* öğretmen mobil grid
* ay navigation + selected day synchronization
* header/search uyumu

### 13/14/03/04

* referansla tam sidebar/topbar/table hizalaması
* pixel polish

Bu turda bunları gereksiz yere yeniden açma.

Ancak yeni yaptığın componentler bu borçları artırmamalıdır.

---

# 19. FINAL STATUS

Şu formatta raporla:

```text
FAZ DESIGN — FAZ 2 / TUR 3 STATUS

08 Duyurular          PASS/PARTIAL/FAIL
09 Takvim             PASS/PARTIAL/FAIL
11 Dokümanlar         PASS/PARTIAL/FAIL
12 Duyuru Detay       PASS/PARTIAL/FAIL

Regression:
05 Öğrenci Detay      PASS/PARTIAL/FAIL
02 Dashboard          PASS/PARTIAL/FAIL
06 Academic Calendar  PASS/PARTIAL/FAIL
13 Teacher Panel      PASS/PARTIAL/FAIL
14 Secretary Panel    PASS/PARTIAL/FAIL
03 Students           PASS/PARTIAL/FAIL
04 Parents            PASS/PARTIAL/FAIL
01 Windows Login      PASS/PARTIAL/FAIL
10 Settings           PASS
15 Drawer             PASS
16 Access Denied      PASS

07 Messages           N/A

Responsive            PASS/PARTIAL/FAIL
Accessibility         PASS/PARTIAL/FAIL

flutter test          X passed / Y failed
flutter analyze       result

Files Changed:
- ...

Tests Added:
- ...

Technical Debt:
- ...

Final Assessment:
PASS / PARTIAL / FAIL
```

Gerçekten tamamlanmayan hiçbir ekranı PASS olarak raporlama.

Bu turun amacı 08/09/11/12 ekranlarını bitirmek ve 16 ekranlık tasarım setinin büyük bölümünü çalışan ortak Design System'e taşımaktır.
