# ACTION — MYEDUAPP DERS VE ÖĞRENCİ PLATFORMU GELİŞTİRMESİ

Bu action iki ana geliştirmeyi kapsar:

1. Ders Platformu – Yeni İçerik Mimarisi
2. Öğrenci Platformu – Dinamik Kategori, Tarih, Autosave ve Raporlama

project.mdc içindeki tüm proje kuralları bu action için geçerlidir.

---

# 1. DERS PLATFORMU — YENİ İÇERİK MİMARİSİ

## Amaç

Ders Platformunu aşağıdaki hiyerarşik içerik yapısına dönüştür:

Ders
↓
Kurs
↓
Ünite
↓
Konu
↓
Doküman / İçerik

## 1.1 Dersler

Ders Platformu açıldığında mevcut sistemde kayıtlı TÜM DERSLER kart olarak gösterilmeli.

Ders kartında:

- Ders resmi
- Ders adı

bulunmalı.

Ders kartına tıklanınca yalnızca o derse ait kurslar gösterilmeli.

## 1.2 Kurslar

Bir ders seçildiğinde o derse ait farklı akademik yıllardaki kurslar kart olarak gösterilmeli.

Kurs kartında:

- Alt ders adı
- Kurs/ders resmi
- Akademik yıl
- Toplam ünite sayısı

gösterilmeli.

Örnek:

Türkçe
→ Türkçe 7. Sınıf
→ 2026–2027
→ 16 Ünite

Aynı dersin farklı akademik yıllarındaki kursları birbirinden bağımsız içerik yapıları olarak desteklenmeli.

Toplam ünite sayısı mevcut verilerden dinamik hesaplanmalı.

## 1.3 Üniteler

Kurs seçildiğinde yalnızca o kursa ait üniteler gösterilmeli.

Ünite kartında mevcut veri yapısına uygun olarak:

- Ünite numarası
- Ünite adı
- Varsa ünite resmi

gösterilebilir.

## 1.4 Konular ve Dokümanlar

Ünite seçildiğinde:

SOL:
Üniteye ait konular liste/menu olarak gösterilmeli.

SAĞ:
Seçilen konuya ait doküman/içerik gösterilmeli.

Akış:

Ders
→ Kurs
→ Ünite
→ Konu
→ Doküman

Konu değiştirildiğinde sağ taraftaki içerik değişmeli.

Bir konuya mevcut sistemin desteklediği şekilde bir veya daha fazla içerik/doküman bağlanabilmeli.

Mevcut içerik ve doküman sistemi varsa aynen kullanılmalı.

## 1.5 Yönetilebilirlik

Mevcut CRUD/yönetim yapısı varsa yeni içerik hiyerarşisine bağlanmalı.

Yapı ileride:

- Ders ekleme/düzenleme
- Kurs ekleme/düzenleme
- Akademik yıl belirleme
- Ünite ekleme/düzenleme
- Konu ekleme/düzenleme
- Doküman/içerik ekleme/düzenleme

işlemlerini desteklemeli.

Bu action kapsamında mevcut yönetim sistemini gereksiz yere yeniden tasarlama.

---

# 2. ÖĞRENCİ PLATFORMU GELİŞTİRMESİ

## Amaç

Öğrenci Platformunu dinamik kategori, tarih bazlı kayıt, otomatik kayıt ve raporlama destekleyen bir yapıya dönüştür.

## 2.1 Dinamik Kategoriler

Öğrenci Platformundaki mevcut:

- Öğrenci Listesi
- Sınavlar
- Ödevler
- Aktiviteler

gibi bölümler korunmalı.

Kategori sistemi dinamik olmalı.

Kullanıcı/öğretmen uygun mevcut yönetim yapısından:

- Kategori ekleyebilmeli
- Kategori adını değiştirebilmeli
- Kategori silebilmeli
- Kategori sırasını değiştirebilmeli
- Kategoriyi aktif/pasif yapabilmeli

Örneğin:

Öğrenci Listesi
Sınavlar
Ödevler
Aktiviteler
Okuma
Konuşma
Kelime
Proje

gibi yeni kategoriler oluşturulabilmeli.

Yeni kategori eklemek için kod değişikliği gerekmemeli.

Sistem için zorunlu çekirdek özellikler yanlışlıkla silinememeli.

Kategori silinirken mevcut veriler varsa veri kaybını önleyecek uyarı/koruma uygulanmalı.

## 2.2 Tarih Bazlı Kayıt

Öğrenci Platformundaki veri girişlerinde tarih seçilebilmeli.

Özellikle:

- Sınavlar
- Ödevler
- Aktiviteler
- Yeni oluşturulan kategoriler

tarih bazlı çalışmalı.

Tarih:

- varsayılan olarak bugün olabilir,
- kullanıcı tarafından değiştirilebilir,
- date picker ile seçilebilir.

Girilen kayıt öğrenci + kategori + tarih ilişkisiyle saklanmalı.

Aynı:

Öğrenci + Kategori + Tarih

için duplicate kayıt oluşturulmamalı.

Mevcut kayıt varsa güncellenmeli.

## 2.3 Tarih Navigasyonu

Kategori ekranlarında tarih değiştirilebilmeli.

Kullanıcı:

- Önceki gün
- Seçilen tarih
- Sonraki gün

arasında hızlıca geçebilmeli.

Seçilen tarihe ait kayıtlar gösterilmeli.

## 2.4 Autosave

Veri değiştirildiğinde otomatik olarak kaydedilmeli.

Örneğin:

Öğrenci seçildi
→ değer girildi/değiştirildi
→ SQLite'a otomatik kaydedildi.

Ayrı bir "Kaydet" butonuna mümkün olduğunca gerek olmamalı.

Autosave:

- uygulama kapanınca veri kaybını önlemeli,
- sayfa değişiminde veriyi korumalı,
- duplicate kayıt oluşturmamalı,
- mevcut kayıtları UPDATE,
- yeni kayıtları INSERT

olarak işlemeli.

## 2.5 Öğrenci Verileri

Her öğrencinin verileri birbirinden bağımsız tutulmalı.

Örneğin:

Ahmet
08.09.2026
Aktivite: 8

Ahmet
09.09.2026
Aktivite: 9

Ahmet
08.09.2026
Ödev: 10

kayıtları birbirinden bağımsız olmalı.

Öğrenci veya kategori değiştiğinde başka öğrencinin/kategorinin kaydı yanlışlıkla değiştirilmemeli.

---

# 3. RAPORLAMA

## 3.1 Bireysel Rapor

Bir öğrenci seçilerek rapor oluşturulabilmeli.

Filtreler:

- Öğrenci
- Başlangıç tarihi
- Bitiş tarihi
- Kategori

kullanılabilmeli.

Raporda mümkün olduğunca:

- Öğrenci
- Sınıf
- Tarih
- Kategori
- Değer
- Not/Açıklama
- Kategori toplamı
- Kategori ortalaması

bulunmalı.

## 3.2 Toplu Rapor

Bir sınıf seçilerek sınıftaki öğrencilerin toplu raporu oluşturulabilmeli.

Filtreler:

- Sınıf
- Başlangıç tarihi
- Bitiş tarihi
- Kategori

olmalı.

Özet rapor en azından:

Öğrenci | Kategori | Ortalama | Toplam

bilgilerini desteklemeli.

---

# 4. PDF EXPORT

Bireysel ve toplu raporlar PDF olarak dışarı aktarılabilmeli.

PDF:

- Türkçe karakterleri desteklemeli.
- Öğrenci/sınıf bilgilerini göstermeli.
- Tarih aralığını göstermeli.
- Tablo yapısını düzgün göstermeli.
- Sayfa taşmalarını önlemeli.

Projede mevcut PDF çözümü varsa kullanılmalı.

---

# 5. EXCEL EXPORT

Bireysel ve toplu raporlar Excel olarak dışarı aktarılabilmeli.

Excel'de en az:

- Öğrenci
- Sınıf
- Tarih
- Kategori
- Değer
- Not/Açıklama

alanları bulunmalı.

Mümkünse ayrıca özet sayfası:

Öğrenci | Kategori | Ortalama

şeklinde oluşturulmalı.

Projede mevcut Excel çözümü varsa kullanılmalı.

---

# 6. VERİ MODELİ

Mevcut database/model/repository yapısını önce tespit et.

Yeni yapı gerekiyorsa mevcut yapıyı mümkün olan en küçük değişiklikle genişlet.

İçerik Platformu için:

Ders
→ Kurs
→ Ünite
→ Konu
→ Doküman

Öğrenci Platformu için:

Öğrenci
→ Kategori
→ Tarih
→ Kayıt

ilişkilerinin mevcut sistemle uyumlu şekilde desteklenmesi yeterlidir.

Aynı işlevi yapan yeni model, tablo, repository veya service oluşturma.

Migration gerekiyorsa mevcut verileri koruyarak gerçekleştir.

---

# 7. UYGULAMA SIRASI

Önce mevcut kodu analiz et.

Özellikle:

1. Ders Platformu
2. Öğrenci Platformu
3. Database modelleri
4. Repository/service yapıları
5. Provider/state management
6. Routing
7. Mevcut PDF/Excel çözümleri
8. Mevcut CRUD ekranları

için yalnızca gerekli dosyaları tespit et.

Sonra şu sırayla uygula:

### A. Ders Platformu

Ders
→ Kurs
→ Ünite
→ Konu
→ Doküman

akışını oluştur.

### B. Öğrenci Platformu

Dinamik kategori
→ Tarih
→ Autosave

sistemini oluştur.

### C. Raporlama

Bireysel/toplu
→ PDF
→ Excel

özelliklerini oluştur.

### D. Validation

Mevcut verilerle test et.

Yeni veri ekleme/düzenleme/silme işlemlerini test et.

Navigation ve mevcut özelliklerin bozulmadığını kontrol et.

---

# 8. KABUL KRİTERLERİ

## Ders Platformu

- [ ] Tüm dersler kart olarak gösteriliyor.
- [ ] Ders kartında resim ve ad bulunuyor.
- [ ] Ders seçildiğinde ilgili kurslar gösteriliyor.
- [ ] Kurs kartında alt ders adı bulunuyor.
- [ ] Kurs kartında resim bulunuyor.
- [ ] Kurs kartında akademik yıl bulunuyor.
- [ ] Toplam ünite sayısı dinamik hesaplanıyor.
- [ ] Farklı akademik yıllardaki kurslar ayrıştırılıyor.
- [ ] Kurs seçildiğinde üniteler gösteriliyor.
- [ ] Ünite seçildiğinde konular solda gösteriliyor.
- [ ] Konu seçildiğinde doküman sağda gösteriliyor.
- [ ] Mevcut içerik/doküman sistemi korunuyor.

## Öğrenci Platformu

- [ ] Mevcut öğrenci listesi korunuyor.
- [ ] Mevcut sınavlar korunuyor.
- [ ] Mevcut ödevler korunuyor.
- [ ] Mevcut aktiviteler korunuyor.
- [ ] Yeni kategori eklenebiliyor.
- [ ] Kategori düzenlenebiliyor.
- [ ] Kategori silinebiliyor.
- [ ] Kategori sıralanabiliyor.
- [ ] Her kategoride tarih seçilebiliyor.
- [ ] Veriler tarihe göre saklanıyor.
- [ ] Autosave çalışıyor.
- [ ] Duplicate kayıt oluşmuyor.
- [ ] Veriler uygulama kapatıldığında korunuyor.

## Raporlama

- [ ] Bireysel rapor oluşturulabiliyor.
- [ ] Toplu sınıf raporu oluşturulabiliyor.
- [ ] Bireysel PDF oluşturulabiliyor.
- [ ] Toplu PDF oluşturulabiliyor.
- [ ] Bireysel Excel oluşturulabiliyor.
- [ ] Toplu Excel oluşturulabiliyor.
- [ ] Türkçe karakterler doğru görüntüleniyor.

## Genel

- [ ] Mevcut veriler korunuyor.
- [ ] Offline-first yapı korunuyor.
- [ ] Mevcut Design System korunuyor.
- [ ] Mevcut navigation korunuyor.
- [ ] Gereksiz dependency eklenmiyor.
- [ ] Gereksiz refactor yapılmıyor.
- [ ] Mevcut çalışan özellikler bozulmuyor.