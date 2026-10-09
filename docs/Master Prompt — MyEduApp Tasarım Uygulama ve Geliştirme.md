# MyEduApp — 16 Tasarım Görseline Göre Tasarım Uygulama ve Geliştirme

## 1. ANA AMAÇ

MyEduApp Flutter projesini, aşağıdaki tasarım referanslarını esas alarak yeniden düzenle:

`docs/design/MyEduApp_design_pages_separated/`

Bu klasörde bulunan **16 tasarım görselinin tamamını** ilgili uygulama ekranlarıyla eşleştir ve ekranları görsellerle mümkün olduğunca birebir aynı görsel dilde uygula.

Amaç yalnızca birkaç ekranı güzelleştirmek değildir.

Amaç:

* 16 tasarım görselinin tamamını uygulamaya geçirmek,
* mevcut çalışan işlevleri korumak,
* mevcut gerçek veri kaynaklarını kullanmak,
* tüm roller için doğru menü ve erişim yapısını korumak,
* mobil / tablet / Windows Desktop responsive yapıyı tamamlamak,
* erişilebilirliği iyileştirmek,
* mevcut tasarım sistemini tutarlı hale getirmek,
* mevcut testleri korumak ve gerekli yeni testleri eklemek,
* sonunda temiz ve doğrulanabilir bir uygulama bırakmaktır.

---

# 2. KESİN KURALLAR

## 2.1 Tasarım görselleri ana görsel referanstır

`docs/design/MyEduApp_design_pages_separated/` klasöründeki 16 görseli incele.

Her görsel için:

* ilgili Flutter ekranını tespit et,
* mevcut ekran ile görseli karşılaştır,
* eksik UI parçalarını belirle,
* yanlış yerleşimleri düzelt,
* renkleri düzelt,
* typography değerlerini düzelt,
* spacing değerlerini düzelt,
* kart yapılarını düzelt,
* ikon kullanımını düzelt,
* butonları düzelt,
* navigation görünümünü düzelt,
* responsive davranışı tasarım mantığına uygun hale getir.

Görselde olmayan yeni bir UI sistemi icat etme.

Mevcut uygulamanın çalışan işlevlerini tasarım uğruna kaldırma.

---

# 3. MEVCUT MİMARİ KORUNACAK

Aşağıdaki mevcut mimariyi koru ve mümkün olduğunca yeniden kullan:

* AppShell
* WorkspaceAppShell
* AppState
* AuthorizationService
* mevcut servisler
* mevcut repository/database yapısı
* mevcut SQLite altyapısı
* mevcut localization sistemi
* mevcut theme sistemi
* mevcut responsive yardımcıları
* mevcut AppSpacing ve tasarım yardımcıları
* mevcut navigation yapısı
* mevcut role/session sistemi

Yeni:

* authentication sistemi,
* role sistemi,
* permission sistemi,
* backend,
* API,
* Firebase,
* yeni database mimarisi

oluşturma.

Mevcut sistem yeterli değilse yalnızca mevcut mimariye minimum ve güvenli genişletme yap.

---

# 4. FAZ 2 SONRASI MEVCUT DURUM KORUNACAK

Faz 2 final çalışmasının sonuçlarını başlangıç noktası kabul et.

Mevcut durum:

* 231 test başarılı,
* testlerde 0 failure,
* Flutter analyze sonucunda yeni error yok,
* mevcut yaklaşık 434 info seviyesindeki uyarılar mevcut durumdur,
* database migration v35'e ulaşmıştır,
* duyuru kapak görseli altyapısı vardır,
* veli toplantısı veri tipi vardır,
* öğrenci notları gerçek veriden okunmaktadır,
* öğretmen mobil takvim düzenlemesi yapılmıştır,
* 08 / 09 / 11 / 12 ekranları final çalışmasına dahil edilmiştir,
* responsive test altyapısı vardır.

Faz 2'de PASS olan işlevleri bozma.

Faz 2'deki gerçek veri kullanımını koru.

Sahte veri oluşturma.

Mevcut database yapısını gereksiz yere değiştirme.

---

# 5. 16 EKRANIN TAMAMI KAPSAMDA

Klasördeki 16 tasarım görselinin tamamını tek tek ele al.

Önce ekran envanteri oluştur.

Her ekran için aşağıdaki bilgileri tespit et:

1. Görsel dosyası
2. İlgili Flutter screen/widget
3. İlgili route/navigation
4. İlgili rol veya roller
5. Mevcut durum
6. Tasarımla arasındaki farklar
7. Yapılacak değişiklikler
8. Veri kaynağı
9. Responsive gereksinimler
10. Accessibility gereksinimleri
11. Test gereksinimleri

Özellikle daha önce Faz 2 kapsamı dışında bırakılmış hub/panel ekranlarını artık kapsam içine al:

* giriş ekranları,
* dashboard/hub ekranları,
* öğrenci ekranları,
* veli ekranları,
* öğretmen ekranları,
* sekreter ekranları,
* diğer tasarım klasöründeki tüm ekranlar.

Ancak gerçek ekran-görsel eşleşmesini **dosya adlarını ve mevcut kodu inceleyerek belirle**.

Tahmin ederek yanlış ekranı başka görsele bağlama.

---

# 6. UI UYGULAMA

Her ekranı ilgili tasarım görseline göre oluştur veya güncelle.

Aşağıdaki değerleri görsel referansa göre düzenle:

* background
* card background
* border
* border radius
* shadow
* icon size
* icon placement
* typography
* font weight
* font size
* line height
* spacing
* padding
* margin
* section spacing
* button height
* input height
* navigation height
* sidebar width
* navbar height
* card width
* content max width
* empty states
* loading states
* error states

Tasarımda kartların belirgin ve net olması gerekiyorsa mevcut kartları gereksiz derecede soluk veya dar bırakma.

Tasarımda geniş içerik alanı gerekiyorsa kartları işlevini bozacak şekilde daraltma.

Özellikle:

* dashboard,
* öğrenci listeleri,
* öğrenci detay,
* öğretmen paneli,
* sekreter paneli,
* veli paneli,
* kurs/ders/akademik alanlar

gibi yoğun içerikli ekranlarda kullanılabilir genişlik sağla.

---

# 7. NAVIGATION

Responsive navigation davranışını tasarım referansına göre uygula.

## Desktop

* Sidebar kullan.
* Navbar yapısını koru.
* Role-based menüleri doğru göster.
* Aktif menü/submenu durumunu doğru göster.

## Tablet

* Sidebar'ın tasarım sistemine uygun daraltılmış davranışını uygula.
* Gerekirse drawer/collapsed navigation kullan.

## Mobile

* Mobile bottom navigation kullanılması gereken ekranlarda bottom navigation uygula.
* Drawer gereken ekranlarda drawer kullan.
* Desktop sidebar'ı küçük ekranda zorla göstermeye çalışma.
* Role-based menüleri koru.

Navigation değişiklikleri mevcut route/back/forward davranışını bozmayacak.

---

# 8. ROLLER

Aşağıdaki roller için mevcut yetki mantığını koru:

* Admin
* Teacher
* Student
* Parent
* Secretary

Bir role ait olmayan menü veya aksiyonu başka role açma.

AuthorizationService mevcutsa onu kullan.

UI seviyesinde gizlemek yeterli değilse mevcut authorization katmanını da koru.

Yeni authorization mimarisi oluşturma.

---

# 9. RESPONSIVE

Aşağıdaki ekran genişliklerinde tüm 16 ekranı kontrol et:

### Mobile

* 360 px
* 390 px
* 430 px

### Tablet

* portrait
* landscape

### Desktop

* küçük desktop
* geniş desktop

Aşağıdaki problemleri kabul etme:

* overflow
* RenderFlex overflow
* taşan text
* kesilen buton
* ekran dışına çıkan kart
* yatay scroll gerektiren normal içerik
* dar kart nedeniyle kullanılamayan form
* üst üste binen navigation
* modal/dialog taşması
* klavye açıldığında formun kullanılamaması

Responsive layout için mevcut yardımcıları ve Flutter layout prensiplerini kullan.

---

# 10. ACCESSIBILITY

Her ekran için aşağıdakileri uygula:

* semantic label
* doğru tooltip
* yeterli touch target
* keyboard navigation
* focus davranışı
* form label'ları
* butonların anlamlı label'ları
* navigation öğelerinin anlamlı semantics bilgileri
* hata mesajlarının erişilebilir olması
* boş durumların anlaşılır olması

Touch target'ları gereksiz derecede küçültme.

---

# 11. DARK/LIGHT THEME

Mevcut theme sistemini kullan.

Hardcoded renkleri gereksiz şekilde ekleme.

Tasarımın light/dark davranışını mevcut theme yapısına bağla.

Mevcut dark mode'u bozma.

---

# 12. LOCALIZATION

Yeni kullanıcıya görünen metinleri localization sistemine ekle.

Hardcoded Türkçe/İngilizce metinleri mümkün olduğunca doğrudan widget içine yazma.

Mevcut localization yapısını kullan.

Yeni key eklenmesi gerekiyorsa mevcut naming convention'a uy.

---

# 13. GERÇEK VERİ KURALI

UI tasarımını tamamlamak için sahte veri üretme.

Örneğin:

* sahte öğrenci,
* sahte veli,
* sahte not,
* sahte duyuru,
* sahte toplantı,
* sahte öğretmen,
* sahte kurs,
* sahte attendance

ekleme.

Gerçek veri yoksa:

* mevcut empty state'i kullan,
* loading state'i kullan,
* uygun placeholder/empty state göster,
* gerekiyorsa BLOCKED/PARTIAL olarak raporla.

Tasarım görselindeki örnek içerikleri gerçek database verisiymiş gibi seed etme.

---

# 14. VERİ VE İŞLEV KORUMA

Tasarım değişikliği sırasında aşağıdaki mevcut özellikleri bozma:

* login
* role selection
* student session
* teacher session
* secretary session
* parent flow
* dashboard data
* student detail
* grades
* attendance
* announcements
* calendar
* documents
* academic plans
* teacher features
* secretary features
* existing authorization
* database synchronization
* backup/restore
* localization

Bir ekranın UI'sini değiştirmek için business logic'i gereksiz yere yeniden yazma.

---

# 15. KOD KALİTESİ

Yeni widget/component gerekiyorsa mevcut tasarım sistemine uygun reusable component oluştur.

Aynı UI'yı farklı ekranlarda tekrar tekrar kopyalama.

Ancak gereksiz büyük refactor yapma.

Her değişiklik:

* okunabilir,
* test edilebilir,
* responsive,
* theme uyumlu,
* localization uyumlu

olmalı.

---

# 16. ÇALIŞMA SIRASI

Çalışmayı aşağıdaki sırayla tamamla:

## 1 — PLAN

Önce:

* 16 görseli incele,
* mevcut Flutter ekranlarını incele,
* route/navigation yapısını incele,
* ilgili widget/component'leri bul,
* mevcut tasarım sistemiyle karşılaştır,
* ekran bazlı fark analizi çıkar,
* uygulanacak planı oluştur.

Bu aşamada mevcut kodu gereksiz şekilde değiştirme.

---

## 2 — IMPLEMENTATION

Planı uygulamaya geçir.

Her ekranı ilgili görsele göre düzelt.

Önce ortak:

* theme
* spacing
* card
* button
* typography
* navigation

yapılarını düzelt.

Ardından ekran bazlı uygulamayı tamamla.

---

## 3 — TEST

Mevcut testleri çalıştır.

Gerekli yeni widget/screen/responsive testlerini ekle.

Özellikle:

* navigation
* role access
* responsive
* widget rendering
* mevcut data flows

kontrol edilsin.

---

## 4 — ANALYZE

Çalıştır:

`flutter analyze`

Yeni:

* error
* warning

oluşturma.

Mevcut info seviyesindeki uyarıları yeni sorun gibi raporlama.

---

## 5 — RESPONSIVE QA

16 ekranın tamamını:

* 360
* 390
* 430
* tablet portrait
* tablet landscape
* küçük desktop
* geniş desktop

üzerinde kontrol et.

---

## 6 — ACCESSIBILITY QA

16 ekranın tamamında:

* semantics
* tooltip
* touch target
* keyboard/focus
* form labels
* navigation labels

kontrol et.

---

## 7 — DOCUMENTATION

Gerekli dokümantasyonu güncelle.

Aşağıdaki gibi bir final raporu oluştur:

`docs/actions/myeduapp_design_redesign_final_status.md`

Raporda:

* 16 ekranın tamamı
* ekran bazlı PASS/PARTIAL/BLOCKED
* değişen dosyalar
* responsive durumu
* accessibility durumu
* test sonucu
* analyze sonucu
* mevcut teknik borçlar
* BLOCKED nedenleri
* kalan işler

bulunsun.

---

# 17. BLOCKED / PARTIAL KURALI

Bir özellik gerçekten teknik olarak tamamlanamıyorsa BLOCKED olarak raporla.

Örneğin:

* mevcut veri modelinde gerekli bilgi yoksa,
* mevcut backend/API desteği yoksa,
* dosya/veri altyapısı gerçekten eksikse.

Ancak sırf zor olduğu için BLOCKED verme.

Tasarım değişikliği yapılabilecekse uygula.

Sahte veri ile BLOCKED durumu kapatma.

---

# 18. TEST BAŞARI KRİTERLERİ

Final durumda:

* `flutter test` başarılı olmalı.
* Mevcut testler bozulmamalı.
* Yeni testler geçmeli.
* `flutter analyze` yeni error/warning üretmemeli.
* Responsive kontroller tamamlanmalı.
* Accessibility kontrolleri tamamlanmalı.
* 16 tasarım görselinin tamamı değerlendirilmiş olmalı.
* Tüm değişiklikler raporlanmalı.

---

# 19. FİNAL STATUS

Final raporda her ekran için:

| Ekran | Tasarım | İşlev | Responsive | Accessibility | Test | Durum |
| ----- | ------- | ----- | ---------- | ------------- | ---- | ----- |

tablosu oluştur.

Durum yalnızca:

* PASS
* PARTIAL
* BLOCKED

olabilir.

BLOCKED/PARTIAL durumlarında gerçek teknik nedeni açıkça yaz.

---

# 20. ÖNEMLİ SINIR

Bu çalışma yalnızca MyEduApp içindir.

Academix ile hiçbir dosyayı veya mimariyi karıştırma.

Mevcut MyEduApp kod tabanını esas al.

Tasarım görsellerini esas al.

Faz 2 final durumunu başlangıç noktası kabul et.

Yeni authentication/backend/role sistemi oluşturma.

Sahte veri oluşturma.

Mevcut çalışan özellikleri bozma.

Amaç 16 ekranın tamamını aynı tasarım sisteminde, responsive ve erişilebilir şekilde tamamlamaktır.
