# Öğretmen Platformu ve Doküman Sistemi

## 1. Amaç

MyEduApp içindeki Öğretmen Platformu ve Ders Platformu > Dökümanlar
sistemini geliştirmek.

Bu doküman, uygulanacak özelliklerin ana teknik şartnamesidir.
Agent her fazda bu dosyayı referans almalıdır.

---

# 2. Genel Kurallar

- Mevcut mimariyi koru.
- Mevcut çalışan özellikleri bozma.
- Offline-first yaklaşımı koru.
- Mevcut database, model, repository, service ve UI patternlerini mümkün
  olduğunca yeniden kullan.
- Gereksiz refactor yapma.
- Gereksiz yeni package ekleme.
- Aynı işlev için ikinci bir model/service sistemi oluşturma.
- Mevcut veri ve geriye dönük uyumluluk korunmalı.
- Backup/restore sistemi yeni verilerle uyumlu olmalı.
- Responsive UI korunmalı.
- Önce mevcut kodu analiz et, sonra değişiklik yap.
- Bir özellik mevcut sistemle yapılabiliyorsa yeni sistem oluşturma.
- Her faz sonunda testleri çalıştır ve sonucu raporla.
- Bir sonraki faza otomatik geçme.

---

# 3. Mevcut Sistemle Korunması Gereken İlişkiler

Mevcut:

Course → Unit → Topic → Document

hiyerarşisi korunacaktır.

Yeni klasör sistemi bu yapının yerine geçmez.

Klasörler yalnızca dokümanları ve ödevleri farklı bir mantıksal
organizasyon altında gruplamak için ek bir katmandır.

Bir doküman birden fazla klasörde bulunabilir.

Fiziksel dosya kopyalanmamalıdır.

---

# 4. Döküman Klasör Sistemi

## 4.1 Klasör CRUD

Kullanıcı:

- klasör oluşturabilmeli
- klasör adını değiştirebilmeli
- klasör silebilmeli
- klasör içine girebilmeli
- üst klasöre dönebilmeli

Klasör silindiğinde:

- doküman silinmez
- ödev silinmez
- fiziksel dosya silinmez
- Course → Unit → Topic → Document ilişkisi değişmez

Yalnızca klasör ilişkileri kaldırılır.

---

## 4.2 Nested Folders

Klasörler sınırsız derinlikte iç içe olabilir.

Örnek:

9. Sınıf
└── Matematik
    └── 1. Ünite
        └── Konu 1

Mevcut database'de:

`dokuman_klasorleri.parent_id`

yapısı kullanılmalıdır.

Nested klasör için yeni database tablosu veya alternatif hiyerarşi
oluşturulmayacaktır.

---

# 5. Klasör İçeriği

Klasör içerisinde:

- Dokümanlar
- Ödevler

görülebilir.

Klasör ekranında:

`+ İçerik Ekle`

butonu bulunmalıdır.

Seçenekler:

1. Yeni Doküman
2. Mevcut Dokümanlar
3. Mevcut Ödevler

---

# 6. Mevcut Dokümanları Klasöre Ekleme

Mevcut dokümanlar fiziksel olarak kopyalanmayacaktır.

Mevcut:

`dokuman_klasor_ogeleri`

junction yapısı kullanılmalıdır.

Yeni bir doküman tablosu oluşturulmayacaktır.

## Çoklu seçim

Kullanıcı aynı işlemde birden fazla doküman seçebilmelidir.

Picker aşağıdaki özelliklere sahip olmalıdır:

- doküman arama
- çoklu seçim
- seçilen doküman sayısı
- tümünü seç
- seçimi temizle
- mümkünse Course / Unit / Topic filtreleri

Seçim tamamlandığında junction kayıtları transaction/batch mantığıyla
eklenmelidir.

Aynı dokümanın aynı klasöre tekrar eklenmesi duplicate oluşturmamalıdır.

---

# 7. Ödevlerin Klasörlere Eklenmesi

Mevcut Ödev sistemini yeniden kullan.

Yeni bir assignment/ödev modeli oluşturma.

Mevcut assignment ilişkilerinin klasör sistemiyle entegre edilmesi
gerekiyorsa mevcut mimariye en az müdahaleyle junction/relationship
kullan.

Ödev klasörden kaldırıldığında ödevin kendisi silinmemelidir.

---

# 8. PDF / Doküman Okuma Konumu

Kullanıcı bir PDF/dokümanı açtığında son okuduğu konum kaydedilmelidir.

Kullanıcı dokümanı kapatıp daha sonra tekrar açtığında:

> Kaldığınız yerden devam et

mantığı uygulanmalıdır.

UI'da paperclip yerine mümkünse bookmark simgesi kullanılmalıdır.

Örneğin:

🔖 12. sayfada kaldınız

veya uygun mevcut UI patterni.

## Database

Okuma konumu `icerikler` tablosuna ek kolon olarak eklenmemelidir.

Ayrı:

`icerik_okuma`

tablosu kullanılmalıdır.

Temel yapı:

- `icerik_id` PRIMARY KEY
- `son_sayfa`
- `guncelleme_tarihi`
- nullable `ekstra_json`

`icerik_id`:

`icerikler(id)`

ile foreign key olmalıdır ve:

`ON DELETE CASCADE`

kullanılmalıdır.

v17 tasarımında kullanıcı ID eklenmeyecektir.

---

# 9. Sınıf Defteri

Öğretmen Platformu içinde:

`Sınıf Defterim`

alanı bulunmalıdır.

Bu sistem genel bir not uygulaması değildir.

Notlar belirli bir sınıfa ait olmalıdır.

Örnek:

9A
- 20 Eylül: Matematik konusu işlendi.
- 21 Eylül: Ödev kontrol edildi.

9B
- 20 Eylül: ...

Her sınıfın defteri birbirinden bağımsızdır.

Mevcut `notlar` tablosu kullanılmayacaktır.

Yeni:

`sinif_defteri_notlari`

tablosu kullanılmalıdır.

Temel alanlar:

- `id`
- `sinif_id`
- `metin`
- `not_tarihi`
- `olusturma_tarihi`
- `guncelleme_tarihi`

`sinif_id`:

`ogrenci_siniflar(id)`

ile ilişkili olmalıdır.

`ON DELETE CASCADE`.

`not_tarihi`:

`YYYY-MM-DD`

formatında tutulmalıdır.

Aynı sınıfta aynı gün birden fazla not bulunabilir.

---

# 10. Öğretmen Son İşlemleri

Ders Platformu ana sayfasında:

`Son İşlemler`

alanı bulunmalıdır.

Amaç kullanıcının yakın zamanda yaptığı işlemleri hızlıca görmesidir.

Örnek işlemler:

- PDF açıldı
- Performans güncellendi
- Ödev oluşturuldu
- Klasör oluşturuldu
- Doküman klasöre eklendi
- Sınıf defterine not eklendi

Yeni:

`ogretmen_son_islemler`

tablosu kullanılmalıdır.

Alanlar:

- `id`
- `tur`
- `baslik`
- `hedef_tur`
- `hedef_id`
- `ek_veri`
- `olusturma_tarihi`

Bu tabloda FK kullanılmayacaktır.

Hedef kayıt silinse bile activity kaydı korunabilir.

UI'da başlangıçta yaklaşık son 5–10 kayıt gösterilebilir.

Database'de gereksiz büyümeyi önlemek için uygulama seviyesinde
örneğin son 100 kayıt tutulabilir.

Activity sistemini bütün uygulamaya tek seferde yayma.

Her ilgili özellik implement edilirken kendi activity kaydı ayrıca
eklenebilir.

---

# 11. Ders Platformu Ana Sayfası

Ana sayfa mümkün olduğunca sade ve kullanışlı kalmalıdır.

Bilgi yığını oluşturma.

## Sınıflarım

Mevcut büyük kart yapısı yerine daha kompakt bir liste/satır görünümü
kullanılmalıdır.

Amaç aynı alanda daha fazla sınıf gösterebilmektir.

---

## Hızlı İşlemler

Mevcut hızlı işlem alanı korunmalı ve yeni özellikler mevcut tasarıma
uygun şekilde eklenmelidir.

---

## Son İşlemler

Yakın zamanda gerçekleştirilen işlemler kompakt şekilde gösterilmelidir.

Bir işleme tıklanabiliyorsa ilgili içeriğe deep-link yapılabilir.

Hedef kayıt artık mevcut değilse uygulama hata vermemeli.

---

## Sınıf Defterim

Öğretmenin seçtiği sınıfa ait notlar gösterilir.

Sınıf değiştirildiğinde yalnızca o sınıfa ait defter gösterilmelidir.

---

## Kısa Analizler

Ana sayfada detaylı raporlar yerine kısa özetler gösterilebilir.

Örnek:

- Performans
- Ödevler
- Sınavlar
- Devamsızlık
- Dokümanlar

Mevcut hesaplama/service yapıları varsa tekrar hesaplama sistemi
oluşturma.

Ana sayfa yalnızca kısa özet göstermelidir.

Detay gerekiyorsa ilgili rapor sayfasına yönlendirilmelidir.

---

# 12. Backup / Restore

Yeni database yapıları mevcut backup/restore sistemine dahil edilmelidir.

Yeni tablolar:

- `icerik_okuma`
- `sinif_defteri_notlari`
- `ogretmen_son_islemler`

export/import sisteminde yer almalıdır.

FK bağımlılıklarına uygun export/import/delete sırası kullanılmalıdır.

Eski backup dosyaları çalışmaya devam etmelidir.

Eski backup içinde yeni tablolar yoksa import işlemi hata vermemelidir.

Fiziksel doküman dosyaları yeniden kopyalanmamalıdır.

---

# 13. Database Version

Mevcut database:

v16

Yeni yapılar:

v17

v16 → v17 migration yalnızca additive olmalıdır.

Mevcut tablolara gereksiz ALTER yapılmamalıdır.

Yeni tablolar oluşturulmalıdır.

Mevcut veriler değiştirilmemelidir.

Yeni kurulumda v17 tabloları oluşturulmalıdır.

---

# 14. v17 Tabloları

## 14.1 icerik_okuma

```text
icerik_id          INTEGER PRIMARY KEY
son_sayfa          INTEGER NOT NULL DEFAULT 1
guncelleme_tarihi  TEXT NOT NULL
ekstra_json        TEXT NULL