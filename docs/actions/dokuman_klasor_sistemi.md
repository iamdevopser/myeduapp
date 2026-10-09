# Döküman Klasör Sistemi

## Durum

ÖN ANALİZ AŞAMASI

Bu aşamada KOD DEĞİŞİKLİĞİ YAPILMAYACAKTIR.

---

# 1. Amaç

Ders Platformu > Dökümanlar bölümünde şu anda sisteme eklenmiş dokümanlar
düz bir liste halinde gösterilmektedir.

Bu yapının, mevcut doküman sistemini ve eğitim hiyerarşisini bozmadan,
klasör tabanlı bir içerik organizasyon sistemine dönüştürülmesi planlanmaktadır.

Amaç, öğretmenin mevcut dokümanları ve mevcut ödevleri klasörler içerisinde
organize edebilmesini sağlamaktır.

Örnek:

Dökümanlar
│
├── 📁 9. Sınıf Matematik
│   ├── 📄 Ders Başlarken.pdf
│   ├── 📄 Konu Anlatımı.pdf
│   ├── 📄 Örnek Sorular.pdf
│   ├── 📝 Ödev 1
│   └── 📝 Ödev 2
│
├── 📁 9. Sınıf Fizik
│   ├── 📄 Kuvvet ve Hareket.pdf
│   └── 📝 Ödev 1
│
└── 📁 Genel
    └── 📄 Sınav Kuralları.pdf

---

# 2. Temel Gereksinimler

## 2.1 Klasörler

Öğretmen:

- Yeni klasör oluşturabilmeli.
- Klasör adını değiştirebilmeli.
- Klasörü silebilmeli.
- Klasörün içerisine girebilmeli.
- Klasör içerisindeki içerikleri görebilmeli.

İlk aşamada klasörlerin içerisinde alt klasör desteği gerekli değildir.
Ancak mimari, ileride alt klasör eklenmesine engel olmayacak şekilde
tasarlanmalıdır.

---

# 3. Klasöre İçerik Ekleme

Bir klasör açıldığında öğretmen "İçerik Ekle" işlemini kullanabilmelidir.

İçerik ekleme seçenekleri:

1. Mevcut dokümanlardan seç
2. Mevcut ödevlerden seç
3. Yeni doküman ekle

---

# 4. Mevcut Dokümanların Kullanılması

Sistemde daha önce eklenmiş olan bir doküman tekrar fiziksel olarak
kopyalanmamalıdır.

Örneğin:

H2-1.1.SAAT KAÇTA KALIYORSUNUZ?.pdf

sistemde zaten mevcutsa, bu dosya yeni bir klasöre eklendiğinde:

- PDF tekrar oluşturulmamalı.
- Dosya tekrar kopyalanmamalı.
- Dosya yolu değiştirilmemeli.
- Aynı fiziksel dosyanın ikinci bir kopyası oluşturulmamalı.

Bunun yerine klasör ile mevcut doküman arasında bir ilişki kurulmalıdır.

Aynı dokümanın birden fazla klasörde kullanılabilmesi mümkün olmalıdır.

Örnek:

📁 9. Sınıf Türkçe
    └── 📄 Ortak Tekrar.pdf

📁 Sınava Hazırlık
    └── 📄 Ortak Tekrar.pdf

Her iki klasör de aynı mevcut dokümana referans vermelidir.

---

# 5. Ödevler

Mevcut Ödev sistemi kullanılmalıdır.

Klasör içerisinde dokümanların yanında mevcut ödevler de gösterilebilmelidir.

Örneğin:

📁 9. Sınıf Matematik

    📄 Konu Anlatımı.pdf
    📄 Örnek Sorular.pdf
    📝 Ödev 1
    📝 Ödev 2

Klasör sistemi için yeni veya duplicate bir Ödev modeli oluşturulmamalıdır.

Mevcut Ödev entity/model, repository, provider/service ve ilgili
veritabanı yapısı mümkün olduğunca aynen kullanılmalıdır.

Klasör ile ödev arasında ilişki kurulmalıdır.

Aynı ödevin gerektiğinde birden fazla klasörde kullanılabilmesi mimari
olarak değerlendirilmelidir.

---

# 6. Mevcut Eğitim Hiyerarşisi Korunmalıdır

Mevcut yapı araştırılmalı ve korunmalıdır.

Özellikle:

Kurs
  ↓
Ünite
  ↓
Konu
  ↓
Doküman

ilişkisi bozulmamalıdır.

Klasör sistemi bu yapının yerine geçmemelidir.

Klasör sistemi mevcut doküman ve ödevleri farklı bir şekilde
organize etmek/göstermek için EK BİR ORGANİZASYON KATMANI olmalıdır.

Bir dokümanın mevcut Kurs → Ünite → Konu ilişkisi varsa bu ilişki
korunmalıdır.

---

# 7. Dosya Depolama

Mevcut offline-first dosya depolama sistemi korunmalıdır.

Mevcut fiziksel dosya/path yapısı araştırılmalıdır.

Klasör oluşturulması fiziksel işletim sistemi klasörü oluşturulması
anlamına gelmemelidir.

Klasörler öncelikle uygulamanın veritabanındaki mantıksal klasörler
olmalıdır.

PDF veya diğer dosyaların fiziksel konumları mevcut sistem tarafından
yönetilmeye devam etmelidir.

---

# 8. Database

Önce mevcut database yapısı ayrıntılı olarak analiz edilmelidir.

Özellikle aşağıdakiler bulunmalıdır:

- Doküman tabloları
- Doküman ilişkileri
- Ödev tabloları
- Ödev ilişkileri
- Kurs tabloları
- Ünite tabloları
- Konu tabloları
- Migration/version yapısı
- Foreign key ilişkileri
- Dosya/path alanları

Yeni database yapısı ancak mevcut yapı analiz edildikten sonra
önerilmelidir.

Muhtemel tasarım:

Folder
  ↓
FolderItem
  ↓
Existing Document / Existing Assignment

gibi bir ilişki yapısı olabilir.

Ancak bu sadece bir tasarım fikridir.

Mevcut proje analiz edilmeden bu yapıyı doğrudan uygulama.

Mevcut mimariye en uygun ve minimum değişiklik gerektiren çözümü öner.

---

# 9. Mimari Kurallar

Aşağıdaki kurallar kesinlikle korunmalıdır:

- Mevcut mimariyi bozma.
- Offline-first yapıyı koru.
- Backward compatibility korunmalı.
- Mevcut veriler korunmalı.
- Mevcut dokümanlar kaybolmamalı.
- Mevcut ödevler kaybolmamalı.
- Mevcut Kurs → Ünite → Konu → Doküman ilişkileri korunmalı.
- Gereksiz refactor yapma.
- Duplicate logic oluşturma.
- Aynı işlevi yapan ikinci bir repository/service/model oluşturma.
- Yeni package ekleme.
- Mevcut package'leri değiştirme.
- Gereksiz migration oluşturma.
- Mevcut çalışan özellikleri değiştirme.
- Minimum gerekli dosyaya dokun.
- Mevcut UI davranışlarını gereksiz yere değiştirme.
- Responsive yapı korunmalı.
- Desktop/tablet/mobile davranışı korunmalı.

---

# 10. Önce İncelenecek Yapılar

Projede aşağıdaki yapıların tamamını bul ve analiz et:

## UI

1. Ders Platformu ana ekranı
2. Dökümanlar ekranı
3. Doküman kartları/listesi
4. Doküman ekleme ekranı
5. Doküman görüntüleme/açma işlemleri
6. Ödevler ekranı
7. Ödev oluşturma/düzenleme ekranları
8. İlgili navigation/routing yapısı

## Data / Model

9. Doküman entity/model sınıfları
10. Ödev entity/model sınıfları
11. Kurs entity/model
12. Ünite entity/model
13. Konu entity/model
14. İlişki modelleri

## Database

15. Doküman tabloları
16. Ödev tabloları
17. Kurs tabloları
18. Ünite tabloları
19. Konu tabloları
20. Foreign key ilişkileri
21. Database version
22. Migration sistemi
23. Seed/default data varsa ilgili yapı

## Repository / Service / Provider

24. Doküman repository
25. Doküman provider/service
26. Ödev repository
27. Ödev provider/service
28. İlgili state management yapısı

## File Storage

29. Fiziksel dosya/path sistemi
30. Backup/restore sistemi ile dokümanların ilişkisi
31. Dosya silme işlemleri
32. Dosya taşıma/kopyalama işlemleri

---

# 11. Analiz Sırasında Özellikle Kontrol Edilecek Konular

Aşağıdaki sorulara cevap bulunmalıdır:

1. Mevcut dokümanlar hangi database tablosunda tutuluyor?

2. Dokümanın fiziksel dosya yolu nerede tutuluyor?

3. Dokümanın Kurs → Ünite → Konu ilişkisi nasıl kuruluyor?

4. Mevcut Ödevler hangi tabloda tutuluyor?

5. Ödevlerin dokümanlarla mevcut bir ilişkisi var mı?

6. Dokümanların başka yerlerde kullanılması destekleniyor mu?

7. Database'de many-to-many ilişki oluşturmak için mevcut bir pattern var mı?

8. Mevcut migration/version sistemi nasıl çalışıyor?

9. Yeni klasör sistemi için en az kaç yeni tablo/model gerekiyor?

10. FolderItem yapısının mevcut database mimarisine uygun olup olmadığı
    araştırılmalı.

11. Aynı klasörde hem doküman hem ödev tutulması için en temiz ve
    minimum değişiklik gerektiren yapı nedir?

12. Mevcut backup/restore sistemi yeni klasör ilişkilerini otomatik olarak
    kapsayabilecek mi?

13. Mevcut dokümanların silinmesi durumunda klasör ilişkileri nasıl
    davranmalı?

14. Bir klasör silindiğinde içindeki doküman ve ödevler silinmemeli;
    yalnızca klasör ilişkisi kaldırılmalıdır.

15. Bir doküman sistemden tamamen silindiğinde ilgili klasör ilişkilerinin
    nasıl temizleneceği belirlenmelidir.

---

# 12. Analiz Raporu

Analiz tamamlandıktan sonra aşağıdaki formatta ayrıntılı bir rapor hazırla:

## A. Mevcut Yapı

Döküman sisteminin şu an nasıl çalıştığını açıkla.

## B. İlgili Dosyalar

Her ilgili dosyanın:

- tam path'i
- görevi
- neden ilgili olduğu

belirtilsin.

## C. Mevcut Database Yapısı

İlgili tabloları, alanları ve ilişkileri açıkla.

## D. Mevcut Ödev Yapısı

Ödevlerin nasıl tutulduğunu ve Döküman sistemiyle nasıl
ilişkilendirilebileceğini açıkla.

## E. Önerilen Minimum Mimari

Klasör sistemini mevcut mimariye en az müdahale ile nasıl ekleyeceğini
açıkla.

## F. Yeni Database Değişiklikleri

Gerekli yeni tablolar/model/relations varsa belirt.

Her yeni alan için neden gerekli olduğunu açıkla.

## G. Değişmesi Gereken Dosyalar

Sadece gerçekten değiştirilmesi gereken dosyaları listele.

## H. Değişmemesi Gereken Dosyalar

Korunması gereken mevcut dosyaları belirt.

## I. Migration Planı

Yeni database yapısı gerekiyorsa migration stratejisini açıkla.

Mevcut kullanıcı verilerinin nasıl korunacağını belirt.

## J. Backup / Restore Uyumluluğu

Yeni klasör ve ilişki verilerinin mevcut backup/restore sistemine
nasıl dahil edileceğini açıkla.

## K. UI Planı

Dökümanlar ana ekranının ve klasör içi ekranın nasıl çalışacağını
açıkla.

Önerilen yapı örneğin:

Dökümanlar

[+ Yeni Klasör]    [Ara...]

📁 9. Sınıf Matematik
📁 9. Sınıf Fizik
📁 Türkçe
📁 Genel

Klasöre girildiğinde:

← Dökümanlar / 9. Sınıf Matematik

[+ İçerik Ekle]

📄 Ders Başlarken.pdf
📄 Konu Anlatımı.pdf
📝 Ödev 1
📝 Ödev 2

şeklinde olabilir.

Bu sadece UI fikridir; mevcut uygulamanın tasarım sistemine uygun
çözüm öner.

## L. Riskler

- Data migration
- Existing data compatibility
- Backup/restore
- File deletion
- Orphan records
- Navigation
- Responsive UI
- Performance

gibi riskleri belirt.

## M. Uygulama Aşamaları

Uygulamayı minimum risk ile hangi fazlara ayıracağını belirt.

Örneğin:

FAZ 1 – Database / Model
FAZ 2 – Repository / Service
FAZ 3 – Folder UI
FAZ 4 – Document selection
FAZ 5 – Assignment selection
FAZ 6 – Backup / Restore
FAZ 7 – Testing

Ancak gerçek fazları mevcut proje analizine göre belirle.

---

# 13. KRİTİK KURAL – BU AŞAMADA KOD DEĞİŞTİRME

Bu dokümanın mevcut aşaması yalnızca ÖN ANALİZ aşamasıdır.

Agent bu aşamada:

- Kod değiştirmemeli.
- Yeni Dart dosyası oluşturmamalı.
- Mevcut Dart dosyalarını değiştirmemeli.
- Database migration çalıştırmamalı.
- Database şemasını değiştirmemeli.
- Mevcut verileri değiştirmemeli.
- Dosya silmemeli.
- Dosya taşımamalı.
- Package eklememeli.
- pubspec değiştirmemeli.
- UI uygulamamalı.
- Testleri değiştirmemeli.

Sadece mevcut projeyi incelemeli ve yukarıdaki formatta analiz raporu
sunmalıdır.

Uygulama aşamasına ancak analiz sonucu incelendikten ve ayrıca onay
verildikten sonra geçilecektir.