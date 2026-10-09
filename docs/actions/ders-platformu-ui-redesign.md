# ACTION — DERS PLATFORMU UI/UX REDESIGN

## KRİTİK TALİMAT

Bu action için project.mdc kuralları geçerlidir.

Ancak burada önemli bir ayrım vardır:

MEVCUT VERİ, DATABASE, MODEL, REPOSITORY, PROVIDER, BUSINESS LOGIC VE ÇALIŞAN FONKSİYONLAR KORUNACAKTIR.

Buna karşılık DERS PLATFORMUNUN UI/UX YAPISI mevcut ekran tasarımını korumak zorunda değildir.

Ders Platformunun sayfa düzeni, navigation yapısı, kart yerleşimi, içerik erişimi, başlıklar, sekmeler, paneller ve responsive UI yapısı aşağıda tarif edilen yeni tasarım modeline göre YENİDEN DÜZENLENECEKTİR.

Bu görev "mevcut UI'ı biraz düzenle" değildir.

Bu görev:
"Mevcut veri ve iş mantığını koruyarak Ders Platformunun UI/UX yapısını yeni tasarım modeline göre yeniden oluştur."

---

# 1. REFERANS TASARIM

Kullanıcının sağladığı Ders Platformu tasarım görseli bu action'ın ana UI/UX referansıdır.

Referans tasarımda temel yapı:

Ders Platformu
↓
Dersler
↓
Kurslar
↓
Üniteler
↓
Konular
↓
Dokümanlar / İçerikler

Bu seviyelerin tamamı aynı Ders Platformu deneyiminin parçalarıdır.

Amaç, kullanıcıya her seviyeye aynı içerik menüsü ve navigation mantığı üzerinden ulaşma imkanı vermektir.

---

# 2. UI/UX YENİDEN TASARIM KURALI

Mevcut Ders Platformu ekranlarının mevcut yerleşimini birebir koruma.

Mevcut kartların, verilerin ve işlevlerin kullanılmasına devam et.

Fakat:

- sayfa layout'u
- navigation
- content hierarchy
- breadcrumb
- tab yapısı
- kart yerleşimi
- header yapısı
- arama alanları
- aksiyon butonları
- detay panelleri
- responsive davranış

referans tasarıma göre yeniden düzenlenebilir ve düzenlenmelidir.

Amaç mevcut ekranı küçük değişikliklerle yamamak değil, mevcut veriyi yeni UI/UX yapısına doğru şekilde taşımaktır.

---

# 3. SOL SIDEBAR / ANA NAVIGATION

Mevcut uygulamanın ana sidebar yapısını koru.

Ders Platformu seçildiğinde Ders Platformuna ait içerik navigation yapısı referans tasarımdaki mantığa uygun çalışmalıdır.

Ders Platformu altında mantıksal olarak:

- Dersler
- Kurslar
- Üniteler
- Konular
- Dokümanlar

seviyelerine erişilebilmelidir.

Ana sidebar ile Ders Platformu iç navigation'ını birbirine karıştırma.

---

# 4. DERS PLATFORMU ANA SAYFA

Ders Platformu ana sayfası "Dersler" seviyesidir.

Sayfada:

Başlık:
Ders Platformu

Alt açıklama:
Eğitim içeriklerinizi yönetin ve düzenleyin.

Üst bölümde:

- Ders arama alanı
- Bildirim/mevcut üst aksiyonlar varsa korunması
- "+ Yeni Ders Ekle" butonu

bulunabilir.

## Ders Kartları

Tüm dersler kart olarak gösterilmelidir.

Her kart:

- Ders resmi
- Ders adı
- Kurs sayısı
- Ünite sayısı
- Konu sayısı
- Aktif/pasif durum bilgisi

gösterebilir.

Örnek:

Türkçe
3 Kurs • 12 Ünite • 48 Konu

Matematik
2 Kurs • 8 Ünite • 32 Konu

Kart yapısı korunacak ancak referans görseldeki daha modern, kompakt ve düzenli görünüm uygulanacaktır.

Ders kartına tıklanınca Ders Detay / Kurslar sayfasına gidilmelidir.

---

# 5. DERS DETAY / KURS SEÇ

Bir ders seçildiğinde yeni sayfa:

Ders Platformu > Türkçe

şeklinde breadcrumb göstermelidir.

Üst bölümde ders bilgi kartı bulunmalıdır.

Bu kartta:

- Ders resmi
- Ders adı
- Ders açıklaması varsa açıklama
- Kurs sayısı
- Ünite sayısı
- Konu sayısı
- Düzenle
- Diğer işlemler

bulunmalıdır.

Altında ortak content navigation bulunmalıdır:

[Kurslar] [Üniteler] [Konular] [Dokümanlar]

Bu navigation yalnızca görsel amaçlı olmamalıdır.

Her sekme gerçekten çalışmalı ve ilgili içeriği göstermelidir.

Varsayılan sekme:

Kurslar

olmalıdır.

---

# 6. KURSLAR

Seçilen derse ait tüm kurslar kart olarak gösterilmelidir.

Örneğin:

Türkçe
→ Türkçe 7. Sınıf
→ Türkçe 8. Sınıf
→ Türkçe 9. Sınıf

Her kurs kartında:

- Kurs resmi
- Kurs adı
- Akademik yıl
- Ünite sayısı
- Konu sayısı
- Aktif/pasif durum
- İşlem menüsü

bulunmalıdır.

"+ Yeni Kurs Ekle" aksiyonu mevcut sistem kullanılarak çalışmalıdır.

---

# 7. KURS / ÜNİTE SAYFASI

Bir kurs seçildiğinde:

Ders Platformu > Türkçe > Türkçe 7. Sınıf

breadcrumb gösterilmelidir.

Üst bilgi kartında:

- Kurs resmi
- Kurs adı
- Akademik yıl
- Ünite sayısı
- Konu sayısı
- Düzenle
- Diğer işlemler

bulunmalıdır.

Altında yine ortak navigation:

[Üniteler] [Konular] [Dokümanlar]

bulunmalıdır.

Varsayılan görünüm:

Üniteler

olmalıdır.

Üniteler kart/grid yapısında gösterilmelidir.

---

# 8. ÜNİTE LİSTESİ

Üniteler kart yapısında gösterilmelidir.

Her ünite kartında:

- Ünite resmi
- Ünite numarası
- Ünite adı
- Konu sayısı
- İşlem menüsü

bulunmalıdır.

"+ Yeni Ünite Ekle" aksiyonu mevcut CRUD sistemine bağlanmalıdır.

Ünite kartına tıklanınca Ünite Detay sayfası açılmalıdır.

---

# 9. ÜNİTE DETAY / KONU SAYFASI

Bir ünite açıldığında:

Ders Platformu > Türkçe > 7. Sınıf > 1. Ünite

breadcrumb gösterilmelidir.

Üst bölümde:

- Ünite resmi
- Ünite numarası
- Ünite adı
- Konu sayısı
- Düzenle
- Diğer işlemler

bulunmalıdır.

Altında:

[Konular] [Dokümanlar]

navigation bulunmalıdır.

Varsayılan:

Konular

olmalıdır.

Konular kart/list yapısında gösterilmelidir.

---

# 10. KONU DETAY

Bir konu seçildiğinde:

Ders Platformu > Türkçe > 7. Sınıf > 1. Ünite > Konu 1

breadcrumb gösterilmelidir.

Üst bölüm:

- Konu resmi
- Konu adı
- Konu bilgisi
- Konu sayfa/alt içerik sayısı
- Düzenle
- Diğer işlemler

şeklinde olabilir.

Altında:

[İçerik] [Öğrenci Notları] [Etkinlikler] [Davranış Raporu]

gibi mevcut sistemde gerçekten desteklenen alanlar gösterilebilir.

Mevcut içerik görüntüleme sistemi korunmalıdır.

Konuya bağlı doküman/içerik doğrudan geniş content alanında gösterilmelidir.

---

# 11. DOKÜMANLAR

Dokümanlar Ders Platformunun ayrı bir content seviyesidir.

Dokümanlar:

- ilgili ders
- ilgili kurs
- ilgili ünite
- ilgili konu

bağlantıları korunarak gösterilmelidir.

Mevcut doküman/content sistemi yeniden yazılmamalıdır.

Yalnızca yeni UI yapısına bağlanmalıdır.

---

# 12. ORTAK CONTENT NAVIGATION

ÇOK ÖNEMLİ:

Ders Platformundaki tüm ilgili sayfalarda aynı navigation mantığı kullanılmalıdır.

Örneğin:

Ders Detay:

[Kurslar] [Üniteler] [Konular] [Dokümanlar]

Kurs Detay:

[Üniteler] [Konular] [Dokümanlar]

Ünite Detay:

[Konular] [Dokümanlar]

Bu navigation gerçek navigation olmalıdır.

Kullanıcı bulunduğu seviyeden diğer içerik seviyelerine doğrudan geçebilmelidir.

Aynı navigation bileşeninin farklı sayfalarda mümkün olduğunca yeniden kullanılması tercih edilir.

Duplicate navigation component oluşturma.

---

# 13. BREADCRUMB

Breadcrumb her seviyede gösterilmelidir.

Örnek:

Ders Platformu > Türkçe

Ders Platformu > Türkçe > Türkçe 7. Sınıf

Ders Platformu > Türkçe > Türkçe 7. Sınıf > 1. Ünite

Ders Platformu > Türkçe > Türkçe 7. Sınıf > 1. Ünite > Konu 1

Breadcrumb elemanları tıklanabilir olmalıdır.

Kullanıcı önceki seviyeye geri dönebilmelidir.

---

# 14. RESİM SİSTEMİ — ÇOK ÖNEMLİ

Ders, Kurs, Ünite ve Konu birbirinden bağımsız resimlere sahip olmalıdır.

Bir entity'nin resmi başka entity'nin resmini değiştirmemelidir.

Aşağıdaki dört seviyenin kendi resmi olmalıdır:

Ders
Kurs
Ünite
Konu

Örnek:

Ders:
Türkçe → Türkçe ders resmi

Kurs:
Türkçe 7. Sınıf → 7. sınıf kurs resmi

Ünite:
1. Ünite → Üniteye özel resim

Konu:
Tanışma ve Selamlaşma → Konuya özel resim

Kurs ekleme ekranında resim seçildiğinde bu resim yalnızca KURSA ait olmalıdır.

Ders resmi otomatik olarak değiştirilmemelidir.

Ünite resmi yalnızca Üniteye ait olmalıdır.

Konu resmi yalnızca Konuya ait olmalıdır.

Mevcut veri modelinde tek bir image alanı nedeniyle bu ayrım yapılamıyorsa:

Önce mevcut model/database yapısını analiz et.

Backward compatibility korunarak minimum gerekli veri modeli değişikliği yap.

Yeni duplicate model oluşturma.

Mevcut resimleri kaybetme.

---

# 15. YÖNETİM / CRUD

Yeni UI mevcut CRUD işlemlerine bağlanmalıdır.

Ders:

- ekle
- düzenle
- sil

Kurs:

- ekle
- düzenle
- sil

Ünite:

- ekle
- düzenle
- sil

Konu:

- ekle
- düzenle
- sil

işlemleri mevcut sistem üzerinden çalışmalıdır.

UI yeniden tasarlanırken mevcut CRUD business logic yeniden yazılmamalıdır.

---

# 16. KART YAPISI

Kart sistemi korunmalıdır.

Ancak kartlar referans tasarım gibi:

- daha kompakt
- düzenli
- modern
- bilgi hiyerarşisi net
- resim + başlık + metadata
- işlem menüsü

şeklinde tasarlanmalıdır.

Kartların gereksiz yere aşırı büyük olmasını önle.

Ekranda mümkün olduğunca fazla içeriğin düzenli şekilde görünmesini sağla.

---

# 17. RESPONSIVE TASARIM

Aynı UI mantığı:

Desktop
Tablet
Mobile

ekranlarında responsive çalışmalıdır.

Desktop:

- geniş grid
- üst navigation
- yan içerik alanları

Tablet:

- daha az kolon
- uygun kart genişliği

Mobile:

- tek/iki kolon
- yatay taşma olmadan
- gerektiğinde yatay scroll
- kompakt header
- bottom sheet / drawer yalnızca gerçekten gerekiyorsa

kullanılmalıdır.

Desktop UI'ı küçültüp mobile'a sıkıştırma.

Mobile için uygun responsive layout oluştur.

---

# 18. MOBİL

Mobilde Ders Platformu:

Dersler
↓
Kurslar
↓
Üniteler
↓
Konular
↓
Dokümanlar

akışını bozmadan çalışmalıdır.

Kartlar mobil genişliğe uyum sağlamalıdır.

Content navigation gerekiyorsa yatay scroll/tab yapısına dönüşebilir.

Breadcrumb mobilde gerektiğinde kompaktlaştırılabilir ancak navigation erişimi korunmalıdır.

---

# 19. MEVCUT VERİ KORUMA

Kesinlikle:

- mevcut dersleri silme
- mevcut kursları silme
- mevcut üniteleri silme
- mevcut konuları silme
- mevcut dokümanları silme
- mevcut öğrenci verilerine dokunma
- mevcut database kayıtlarını sıfırlama
- demo data oluşturmak için gerçek verileri değiştirme

Mevcut veriler yeni UI içerisinde görünmelidir.

---

# 20. ANALİZ VE UYGULAMA SIRASI

Önce repository'yi analiz et.

Özellikle:

1. Ders Platformu ekranları
2. Ders modelleri
3. Kurs modelleri
4. Ünite modelleri
5. Konu modelleri
6. Doküman/content modelleri
7. Image/file alanları
8. CRUD işlemleri
9. Provider/state management
10. Routing
11. Responsive layout sistemleri

tespit edilmelidir.

Ardından yeni UI bu mevcut veri akışına bağlanmalıdır.

ÖNCE ANALİZ ET.

SONRA UYGULA.

Gereksiz dosyaları değiştirme.

---

# 21. ÇOK ÖNEMLİ — ESKİ UI'YI KORUMA KURALI BU ACTION İÇİN GEÇERLİ DEĞİL

project.mdc'deki:

"Mevcut UI / navigation yapısını mümkün olduğunca koru"

gibi genel kurallar veri kaybını ve mimari bozulmayı önlemek amacıyla geçerlidir.

Ancak bu action açıkça Ders Platformu UI/UX redesign istediği için:

DERS PLATFORMU UI/UX YAPISI YENİDEN DÜZENLENMELİDİR.

Eski Ders Platformu ekranının layout'unu sadece küçük değişikliklerle koruma.

Referans tasarımdaki yapı esas alınmalıdır.

Korunması gereken:

- database
- mevcut veri
- modeller
- repository
- service
- provider
- business logic
- CRUD mantığı
- mevcut çalışan content sistemi

Yeniden tasarlanması gereken:

- Ders Platformu UI
- sayfa layoutları
- navigation
- kart yerleşimleri
- content navigation
- headerlar
- breadcrumb yerleşimi
- responsive görünüm
- mobil görünüm
- bilgi hiyerarşisi

---

# 22. KABUL KRİTERLERİ

- [ ] Ders Platformu ana sayfası referans tasarıma uygun yeni UI'a sahip.
- [ ] Dersler kart/grid olarak gösteriliyor.
- [ ] Ders kartında bağımsız ders resmi bulunuyor.
- [ ] Ders seçildiğinde Kurslar görünümü açılıyor.
- [ ] Kurslar kart/grid olarak gösteriliyor.
- [ ] Her kursun bağımsız resmi bulunuyor.
- [ ] Ders resmi ve kurs resmi birbirinden bağımsız.
- [ ] Kurs seçildiğinde Üniteler görünümü açılıyor.
- [ ] Üniteler kart/grid olarak gösteriliyor.
- [ ] Her ünitenin bağımsız resmi bulunuyor.
- [ ] Ünite seçildiğinde Konular görünümü açılıyor.
- [ ] Her konunun bağımsız resmi bulunuyor.
- [ ] Konu seçildiğinde mevcut içerik sistemi geniş content alanında açılıyor.
- [ ] Dokümanlara ortak navigation üzerinden ulaşılabiliyor.
- [ ] Ortak content navigation tüm seviyelerde çalışıyor.
- [ ] Breadcrumb tüm seviyelerde çalışıyor.
- [ ] Breadcrumb elemanları tıklanabilir.
- [ ] Mevcut CRUD işlemleri çalışıyor.
- [ ] Mevcut veriler korunuyor.
- [ ] Mevcut içerikler kaybolmuyor.
- [ ] Ders/Kurs/Ünite/Konu resimleri birbirine karışmıyor.
- [ ] Desktop görünüm referans tasarıma uygun.
- [ ] Tablet görünüm responsive.
- [ ] Mobile görünüm responsive.
- [ ] Gereksiz dependency eklenmedi.
- [ ] Gereksiz architecture refactor yapılmadı.
- [ ] Mevcut database sıfırlanmadı.
- [ ] İlgili analyzer/test kontrolleri çalıştırıldı.

---

# 23. SON KURAL

Bu görevi küçük UI düzeltmeleri olarak uygulama.

REFERANS TASARIMI ANA TASARIM HEDEFİ OLARAK KABUL ET.

Mevcut sistemi yeni tasarıma uydur.

Veri ve business logic korunacak.

UI/UX yeniden düzenlenecek.

İşlem sonunda:

1. Değiştirilen dosyaları
2. Yapılan UI/UX değişikliklerini
3. Veri/model değişikliklerini
4. Test/analyzer sonuçlarını

kısaca raporla.