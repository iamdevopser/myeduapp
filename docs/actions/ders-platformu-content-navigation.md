# ACTION — DERS PLATFORMU ORTAK CONTENT NAVIGATION VE RESPONSIVE UI

project.mdc içindeki tüm kurallar bu action için aynen geçerlidir.

Bu görev yalnızca mevcut Ders Platformunun navigasyon ve içerik gösterim yapısını geliştirmek içindir.

AMAÇ:

Mevcut kart yapısını ve mevcut Ders Platformu işlevlerini koruyarak;

Ders
→ Kurs
→ Ünite
→ Konu
→ Doküman / İçerik

hiyerarşisini bütün sayfalarda aynı ortak navigasyon yapısıyla kullanılabilir hale getir.

Ana hedef:
Kullanıcı Ders Platformunda hangi seviyede olursa olsun aynı Content Navigation yapısından diğer seviyelere hızlıca ulaşabilsin.

--------------------------------------------------
1. ÖNCE MEVCUT SİSTEMİ ANALİZ ET
--------------------------------------------------

Önce mevcut implementasyonu analiz et.

Özellikle yalnızca gerekli dosyalarda:

- Ders Platformu ana sayfası
- Ders kartları
- Kurs kartları
- Ünite kartları
- Konu ekranı
- Doküman/içerik görüntüleme
- mevcut routing/navigation
- mevcut sidebar
- mevcut responsive/tablet/mobile yapısı
- mevcut Design System
- mevcut image/image picker sistemi

tespit edilmelidir.

Mevcut modelleri, repository/service/provider/state management yapılarını yeniden oluşturma.

Aynı işlevi yapan yeni model, service, repository veya component oluşturma.

Mevcut çalışan veri yapısını değiştirme.

Gereksiz refactor yapma.

--------------------------------------------------
2. MEVCUT KART YAPISI KORUNACAK
--------------------------------------------------

Ders Platformundaki mevcut kart tasarımı korunmalıdır.

Aşağıdaki yapı kart tabanlı kalmalıdır:

Dersler → Ders Kartları

Kurslar → Kurs Kartları

Üniteler → Ünite Kartları

Konular → mevcut konu yapısı

Kartların:

- görseli
- başlığı
- mevcut bilgi alanları
- rounded design
- spacing
- typography
- mevcut renk sistemi
- mevcut action butonları

gereksiz yere değiştirilmemelidir.

Amaç kartları kaldırmak veya yeni bir tasarım sistemi oluşturmak değildir.

Sadece navigasyon ve içerik alanı daha kullanışlı hale getirilecektir.

--------------------------------------------------
3. ORTAK CONTENT NAVIGATION
--------------------------------------------------

Ders Platformundaki içerik ekranlarında ortak bir navigation/breadcrumb yapısı oluştur.

Ana yapı:

Ders Platformu
→ Ders
→ Kurs
→ Ünite
→ Konu
→ Doküman / İçerik

Örnek:

Ders Platformu > Türkçe > Türkçe 7. Sınıf > 1. Ünite > Konu 1

Navigation her seviyede mevcut konumu göstermelidir.

Örneğin Ders ekranında:

Ders Platformu > Dersler

Kurs ekranında:

Ders Platformu > Türkçe > Kurslar

Ünite ekranında:

Ders Platformu > Türkçe > Türkçe 7. Sınıf > Üniteler

Konu ekranında:

Ders Platformu > Türkçe > Türkçe 7. Sınıf > 1. Ünite > Konular

gibi çalışmalıdır.

--------------------------------------------------
4. BREADCRUMB NAVIGATION DAVRANIŞI
--------------------------------------------------

Breadcrumb içerisindeki önceki seviyeler tıklanabilir olmalıdır.

Örneğin:

Ders Platformu > Türkçe > Türkçe 7. Sınıf > 1. Ünite > Konu 1

kullanıcı "Türkçe"ye tıklarsa Türkçe dersinin kursları açılmalıdır.

"Türkçe 7. Sınıf"a tıklarsa ilgili kurs/ünite yapısına dönmelidir.

"1. Ünite"ye tıklarsa ilgili ünite ekranına dönmelidir.

Mevcut navigation/routing yapısı mümkün olduğunca kullanılmalıdır.

Yeni ve paralel bir routing sistemi oluşturma.

--------------------------------------------------
5. KONU EKRANI — ÖNEMLİ DEĞİŞİKLİK
--------------------------------------------------

Mevcut konu ekranındaki gereksiz geniş konu panelini kaldır veya minimum genişliğe indir.

Konu seçimi için ana sayfadaki sidebar hover mantığına benzer bir yapı kullan.

Amaç:

Konu listesinin content alanından gereksiz genişlik almamasıdır.

Önerilen yapı:

SOL:
Dar konu navigation alanı

SAĞ:
Geniş content alanı

Örnek:

┌────────────────┬─────────────────────────────────────┐
│ Konular        │                                     │
│                │  Türkçe / Ünite 1 / Konu 1         │
│ ● Konu 1       │                                     │
│   Konu 2       │  KONU İÇERİĞİ                       │
│   Konu 3       │                                     │
│   Konu 4       │  Doküman burada doğrudan açılır.    │
│                │                                     │
└────────────────┴─────────────────────────────────────┘

Konu navigation mümkün olduğunca dar olmalıdır.

Content alanı mümkün olan en geniş alanı kullanmalıdır.

--------------------------------------------------
6. KONUYA TIKLANDIĞINDA DOKÜMAN DOĞRUDAN CONTENT ALANINDA AÇILACAK
--------------------------------------------------

Kullanıcı bir konuya tıkladığında:

Konu
→ bağlı doküman/içerik
→ doğrudan content alanında açılmalıdır.

Dokümanların isimlerini göstermek için content alanından ayrı geniş bir panel oluşturma.

Önceki yapıda olduğu gibi:

Konu listesi
+
Doküman listesi
+
dar content alanı

şeklinde üçlü ve gereksiz alan tüketen yapı kullanılmamalıdır.

Content alanı mümkün olduğunca geniş tutulmalıdır.

Bir konuda birden fazla doküman varsa mevcut doküman navigation sistemi korunabilir ancak content alanını gereksiz şekilde daraltmamalıdır.

--------------------------------------------------
7. İÇERİK ALANI
--------------------------------------------------

Content viewer mümkün olan en geniş alanı kullanmalıdır.

Özellikle:

- PDF
- görsel
- Word/doküman
- mevcut içerik blokları
- diğer mevcut content türleri

mevcut sistem nasıl destekliyorsa aynı şekilde çalışmaya devam etmelidir.

Mevcut content rendering sistemi değiştirilmemelidir.

Sadece yerleşim alanı optimize edilmelidir.

--------------------------------------------------
8. SAYFALAR ARASI TUTARLILIK
--------------------------------------------------

Aynı navigation mantığı bütün Ders Platformu seviyelerinde kullanılmalıdır.

Akış:

Dersler
↓
Kurslar
↓
Üniteler
↓
Konular
↓
Doküman / İçerik

Kullanıcı her seviyede nerede olduğunu anlayabilmelidir.

Sayfalar birbirinden tamamen farklı navigation mantıkları kullanmamalıdır.

--------------------------------------------------
9. ÜST BAR
--------------------------------------------------

Mevcut üst bar korunmalıdır.

Ancak Ders Platformu içinde gerekli olduğu yerde:

- geri
- breadcrumb
- arama
- mevcut action butonları

aynı görsel sistem içerisinde düzenlenebilir.

Mevcut sidebar kaldırılmamalıdır.

Mevcut global navigation değiştirilmemelidir.

--------------------------------------------------
10. RESPONSIVE / TABLET / MOBILE
--------------------------------------------------

Bu geliştirme mevcut responsive/tablet/mobile sistemine uyumlu olmalıdır.

Desktop:

Sol tarafta dar konu navigation
+
geniş content alanı

Tablet:

Konu navigation daha kompakt hale gelmeli.

Content alanı ekranın büyük bölümünü kullanmalı.

Mobil:

Desktop'taki geniş sol panel kesinlikle aynen kullanılmamalıdır.

Mobilde konu navigation:

- drawer
- compact expandable menu
- dropdown
- mevcut responsive navigation sisteminin uygun çözümü

ile açılabilmelidir.

Konu seçildikten sonra navigation kapanabilir ve content tam genişliğe yakın kullanılmalıdır.

Mobilde:

- yatay taşma
- kesilmiş content
- ekran dışına çıkan buton
- okunamayan text
- aşırı küçük dokunma alanları

oluşmamalıdır.

Tablet ve mobil dokunmatik kullanım için buton ve navigation alanları yeterli touch target'a sahip olmalıdır.

Yeni bir responsive framework veya dependency ekleme.

Mevcut responsive altyapıyı kullan.

--------------------------------------------------
11. KARTLAR RESPONSIVE OLMALI
--------------------------------------------------

Kart yapısı korunacak ancak ekran genişliğine göre otomatik uyum sağlamalıdır.

Desktop:
Bir satırda birden fazla kart.

Tablet:
Ekrana uygun sayıda kart.

Mobile:
Tek veya uygun sayıda kart.

Kartların sabit desktop genişliği nedeniyle mobilde taşma oluşmamalıdır.

Mevcut grid/list altyapısı varsa onu kullan.

--------------------------------------------------
12. GÖRSEL REFERANS
--------------------------------------------------

Tasarımın hedefi mevcut kart yapısını koruyan modern, sade ve tutarlı bir eğitim platformu görünümüdür.

Ana prensipler:

- mevcut kart yapısını koru
- ortak Content Navigation oluştur
- breadcrumb kullan
- konu navigation'ını daralt
- konu seçildiğinde content'i doğrudan göster
- content alanını mümkün olduğunca büyüt
- tüm sayfalarda aynı navigation mantığını kullan
- desktop/tablet/mobile responsive davranışı koru
- mevcut Design System'i kullan

Görsel olarak hedeflenen mantık:

Dersler
→ Kartlar

Ders seç
→ Ders bilgisi + Kurs kartları

Kurs seç
→ Kurs bilgisi + Ünite kartları

Ünite seç
→ Ünite bilgisi + Konu kartları

Konu seç
→ Dar konu navigation + geniş content alanı

--------------------------------------------------
13. ARAMA VE NAVIGATION
--------------------------------------------------

Mevcut arama özelliği varsa korunmalıdır.

Yeni bir arama sistemi oluşturma.

Arama sonuçları mevcut içerik yapısıyla uyumlu olmalıdır.

--------------------------------------------------
14. VERİ VE BACKWARD COMPATIBILITY
--------------------------------------------------

Database schema değiştirme.

Mevcut:

- dersler
- kurslar
- üniteler
- konular
- dokümanlar
- içerikler
- görseller

korunmalıdır.

Mevcut kayıtların navigation içinde doğru seviyeye bağlandığını doğrula.

Özellikle:

Kurs → doğru Ders

Ünite → doğru Kurs

Konu → doğru Ünite

Doküman → doğru Konu

ilişkilerinin doğru kullanıldığını kontrol et.

Bir konunun dokümanlarını başka bir konuya göstermeme.

Bir ünitenin konularını başka ünitelerden getirmeme.

--------------------------------------------------
15. VALIDATION
--------------------------------------------------

Değişikliklerden sonra aşağıdaki akışları test et:

1. Ders Platformu açılır.
2. Tüm dersler kart olarak görünür.
3. Bir ders seçilir.
4. O derse ait kurslar görünür.
5. Bir kurs seçilir.
6. O kursa ait üniteler görünür.
7. Bir ünite seçilir.
8. Yalnızca o üniteye ait konular görünür.
9. Bir konu seçilir.
10. Konuya bağlı içerik doğrudan content alanında açılır.
11. Content alanı gereksiz şekilde daralmaz.
12. Breadcrumb çalışır.
13. Breadcrumb üzerinden önceki seviyelere dönülebilir.
14. Farklı konular arasında hızlı geçiş yapılabilir.
15. Mevcut dokümanlar açılabilir.
16. Mevcut veriler kaybolmaz.
17. Desktop görünüm kontrol edilir.
18. Tablet görünüm kontrol edilir.
19. Mobile görünüm kontrol edilir.
20. Yatay overflow oluşmadığı kontrol edilir.

--------------------------------------------------
16. SCOPE CONTROL
--------------------------------------------------

Bu action dışında:

- Öğrenci Platformu
- Raporlar
- Mentörlük
- Database'in ilgisiz bölümleri
- başka modüller
- authentication
- yeni backend
- cloud sistemleri

değiştirilmemelidir.

Sadece Ders Platformunun bu action kapsamındaki navigation, layout ve responsive davranışı değiştirilmelidir.

--------------------------------------------------
17. SON KONTROL
--------------------------------------------------

Görev tamamlandığında:

- değiştirilen dosyaları listele
- yapılan değişiklikleri kısa şekilde açıkla
- çalıştırılan test/analyzer sonuçlarını bildir
- varsa kalan problemi belirt

Gereksiz dosya değişikliği yapma.