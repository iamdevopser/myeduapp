# ACTION — DERS PLATFORMU UI/NAVIGATION YENİDEN DÜZENLEME

project.mdc içindeki tüm kurallar geçerlidir.

## ÖNEMLİ

Bu görev mevcut Ders Platformunun veri modelini, database yapısını,
repository/service/provider/state management yapısını veya mevcut içerik
verilerini değiştirmek için değildir.

AMA Ders Platformunun mevcut UI/UX yapısı bu action'a göre yeniden
düzenlenmelidir.

"Mevcut UI'ı koru ve küçük değişiklik yap" yaklaşımı UYGULANMAMALIDIR.

Mevcut veri ve mimari korunacak, fakat Ders Platformunun UI/navigation
yapısı aşağıdaki tasarım mantığına göre yeniden düzenlenecektir.

---

# 1. ANA SIDEBAR NAVIGATION

Ders Platformu ana sidebar'da expandable/collapsible bir ana menü olmalıdır.

Ana sidebar sıralaması korunarak Ders Platformu altında şu alt menüler
gösterilmelidir:

Ders Platformu
├── Dersler
├── Kurslar
├── Üniteler
├── Konular
└── Dokümanlar

Ders Platformu ana menüsüne tıklandığında bu alt menüler açılıp kapanmalıdır.

Alt menüler ANA SIDEBAR içerisinde bulunmalıdır.

Alt menüler content alanının üstünde, content alanının içinde veya
breadcrumb alanında oluşturulmamalıdır.

---

# 2. SIDEBAR DAVRANIŞI

Ders Platformu aktifken:

- Ders Platformu ana menüsü expanded durumda olabilir.
- Dersler
- Kurslar
- Üniteler
- Konular
- Dokümanlar

alt menüleri görünmelidir.

Aktif olan alt menü görsel olarak mevcut Design System'e uygun şekilde
belirginleştirilmelidir.

Diğer ana sidebar menüleri:

- Öğrenci Platformu
- Mentörlük
- Raporlar
- Kullanım Kılavuzu
- Ayarlar

mevcut yapıları bozulmadan Ders Platformunun altında/üstünde doğru
hiyerarşide kalmalıdır.

---

# 3. CONTENT ALANI MAKSİMUM KULLANILMALI

Ders Platformu ekranlarının temel amacı içerik göstermektir.

Bu nedenle:

- Content alanı mümkün olan maksimum genişliği kullanmalıdır.
- Gereksiz üst navigation alanı oluşturulmamalıdır.
- Gereksiz büyük header alanları oluşturulmamalıdır.
- Content alanının içine navigation paneli eklenmemelidir.
- Sabit/geniş breadcrumb alanı oluşturulmamalıdır.
- Content alanı gereksiz padding/margin ile küçültülmemelidir.

Özellikle PDF, doküman, ders içeriği ve diğer içerik görüntüleme
ekranlarında içerik mümkün olan maksimum alanı kullanmalıdır.

Mevcut responsive yapı korunarak desktop/tablet/mobile için uygun
maksimum kullanılabilir alan hesaplanmalıdır.

---

# 4. BREADCRUMB

Breadcrumb tamamen kaldırılmak zorunda değildir.

Ancak breadcrumb artık ANA NAVIGATION olarak kullanılmamalıdır.

Varsa yalnızca küçük bir konum göstergesi olarak kullanılabilir:

Ders Platformu > Türkçe > Türkçe 7. Sınıf > 1. Ünite > Konu 1

Breadcrumb:

- content alanını gereksiz şekilde küçültmemeli,
- büyük bir navigation bar oluşturmamalı,
- sidebar alt menülerinin yerine geçmemeli.

Ana navigation görevi SIDEBAR'dadır.

---

# 5. KART YAPISI KORUNACAK

Mevcut Ders/Kurs/Ünite/Konu kartlarının kullanım mantığı korunmalıdır.

Ancak kartların bulunduğu ekranlar yeni sidebar navigation yapısına
uyarlanmalıdır.

Örnek:

Dersler:

[ Türkçe ] [ Matematik ] [ İngilizce ] [ ... ]

Kurslar:

[ Türkçe 7. Sınıf ] [ Türkçe 8. Sınıf ] [ Türkçe 9. Sınıf ]

Üniteler:

[ 1. Ünite ] [ 2. Ünite ] [ 3. Ünite ] ...

Kart yapısı bozulmamalıdır.

---

# 6. HİYERARŞİK İÇERİK AKIŞI

Mevcut veri yapısı korunarak UI şu mantığı desteklemelidir:

Ders
↓
Kurs
↓
Ünite
↓
Konu
↓
Doküman / İçerik

Kullanıcı ister kartlar üzerinden aşağı doğru ilerleyebilmeli,
isterse sidebar alt menülerini kullanabilmelidir.

Sidebar alt menüleri uygun mevcut route/state mekanizmasına bağlanmalıdır.

Yeni bir routing architecture oluşturma.

---

# 7. KONU / DOKÜMAN EKRANI

Konu veya doküman açıldığında content alanı maksimum kullanılmalıdır.

Özellikle PDF/doküman görüntüleme ekranında:

- Doküman görüntüleyici mümkün olan maksimum genişlik ve yüksekliği
  kullanmalıdır.
- Sol tarafta gereksiz geniş navigation paneli oluşturulmamalıdır.
- Sidebar dışında ikinci bir ana navigation oluşturulmamalıdır.
- Konu/doküman listesi gerekiyorsa mevcut sistemdeki yapıyı kullanarak
  mümkün olan en kompakt şekilde gösterilmelidir.

Amaç:

SIDEBAR = NAVIGATION
CONTENT = İÇERİK

olmalıdır.

---

# 8. MOBİL / TABLET

Desktop sidebar yapısı mobilde aynen sıkıştırılmamalıdır.

Responsive davranış:

Desktop:
Sol tarafta genişletilebilir sidebar.

Tablet:
Kompakt sidebar veya mevcut responsive navigation.

Mobile:
Sidebar drawer/hamburger navigation kullanılabilir.

Mobilde:

Ders Platformu
  ├ Dersler
  ├ Kurslar
  ├ Üniteler
  ├ Konular
  └ Dokümanlar

aynı hiyerarşide erişilebilir olmalıdır.

Content alanı mobil ekranda mümkün olan maksimum alanı kullanmalıdır.

---

# 9. TASARIM REFERANSI

UI/UX yeniden düzenlenirken temel tasarım mantığı:

- Sol sidebar navigation
- Ders Platformu expandable menu
- Dersler/Kurslar/Üniteler/Konular/Dokümanlar alt menüleri
- Büyük ve temiz content alanı
- Kart tabanlı Ders/Kurs/Ünite/Konu yapısı
- Minimal header
- Minimal breadcrumb
- Maksimum content alanı
- Desktop/tablet/mobile responsive yapı

olmalıdır.

Bu yapı mevcut ekranların sadece üzerine birkaç widget eklenerek
oluşturulmamalıdır.

Gerekli mevcut Ders Platformu ekranlarının UI layout'u bu tasarım
mantığına göre yeniden düzenlenmelidir.

---

# 10. MEVCUT VERİ VE MİMARİ KORUNACAK

Aşağıdakilere gereksiz şekilde dokunma:

- SQLite database
- mevcut tablolar
- mevcut modeller
- repository
- service
- provider
- state management
- mevcut içerik kayıtları
- PDF/document sistemi
- mevcut CRUD mantığı
- mevcut authentication
- mevcut routing architecture

Ancak mevcut UI layout'u bu yeni navigation yapısının uygulanmasını
engelliyorsa ilgili UI dosyalarını yeniden düzenlemek serbesttir.

UI değişikliği gerektiğinde mevcut architecture üzerinde minimum gerekli
değişiklik yapılmalıdır.

---

# 11. ÖNEMLİ — ESKİ UI'YI KORUMA TALİMATI DEĞİL

Bu action'da:

"Mevcut Ders Platformu UI'ını mümkün olduğunca koru"

şeklinde davranma.

DOĞRU YAKLAŞIM:

"Mevcut veri ve architecture'ı koru,
Ders Platformu UI/UX layout'unu bu action'da tanımlanan yeni tasarıma
uygun şekilde yeniden düzenle."

---

# 12. ACCEPTANCE CRITERIA

- [ ] Ders Platformu ana sidebar'da expandable menüdür.
- [ ] Dersler alt menüsü Ders Platformu altında görünür.
- [ ] Kurslar alt menüsü Ders Platformu altında görünür.
- [ ] Üniteler alt menüsü Ders Platformu altında görünür.
- [ ] Konular alt menüsü Ders Platformu altında görünür.
- [ ] Dokümanlar alt menüsü Ders Platformu altında görünür.
- [ ] Alt menüler content alanında oluşturulmamıştır.
- [ ] Alt menüler breadcrumb yerine ana navigation olarak çalışır.
- [ ] Breadcrumb varsa yalnızca yardımcı konum göstergesidir.
- [ ] Content alanı maksimum kullanılabilir alanı kullanır.
- [ ] PDF/doküman görüntüleme alanı mümkün olan maksimum boyuttadır.
- [ ] Gereksiz büyük header/navigation alanları kaldırılmıştır.
- [ ] Ders/Kurs/Ünite/Konu kart yapısı korunmuştur.
- [ ] Ders → Kurs → Ünite → Konu → Doküman akışı korunmuştur.
- [ ] Desktop responsive yapı çalışır.
- [ ] Tablet responsive yapı çalışır.
- [ ] Mobile responsive yapı çalışır.
- [ ] Mevcut database verileri korunmuştur.
- [ ] Mevcut içerikler kaybolmamıştır.
- [ ] Mevcut CRUD işlemleri bozulmamıştır.
- [ ] Mevcut PDF/document görüntüleme çalışmaya devam eder.
- [ ] Gereksiz dependency eklenmemiştir.
- [ ] Gereksiz architecture refactor yapılmamıştır.
