# ACTION — DERS OLUŞTURUCU EKRANINI YENİ DERS MİMARİSİNE UYARLA

Bu action, mevcut Ders Oluşturucu ekranını
MYEDUAPP DERS VE ÖĞRENCİ PLATFORMU GELİŞTİRMESİ action'ında tanımlanan
yeni Ders Platformu içerik hiyerarşisine uyarlamak içindir.

project.mdc kuralları aynen geçerlidir.

## 1. TEMEL HİYERARŞİ

Ders Oluşturucu ve ilgili veri seçimleri aşağıdaki yapıyla uyumlu olmalıdır:

Ders
→ Kurs
→ Akademik Yıl
→ Ünite
→ Konu
→ Doküman / İçerik

Örnek:

Türkçe
→ Türkçe 7. Sınıf
→ 2026–2027
→ Ünite 1
→ Merhaba
→ İçerik

## 2. MEVCUT EKRANI ANALİZ ET

Önce mevcut Ders Oluşturucu ekranının implementasyonunu bul.

Özellikle:
- Ders Oluşturucu widget/page
- Ders/Kurs seçimleri
- Sınıf seçimi
- Ünite seçimi
- Konu seçimi
- İçerik/blok sistemi
- Ders/Ünite/Konu CRUD işlemleri
- Provider/state yönetimi
- Model
- Repository/service
- Database tabloları
- Routing

yapısını analiz et.

Mevcut çalışan blok türlerini ve içerik oluşturma sistemini değiştirme.

## 3. SINIF VE DERS AYRIMINI DÜZELT

Mevcut ekrandaki:

"Sınıf" → "Ders" → "Ünite" → "Konu"

mantığını yeni içerik mimarisiyle uyumlu hale getir.

"Sınıf" bilgisi içerik hiyerarşisinin bağımsız ana seviyesi olmamalı.

Örneğin:

7.SINIFLAR
Türkçe
Ünite
Konu

şeklindeki seçim yapısını doğrudan kullanma.

Bunun yerine mevcut veri yapısı elverdiği ölçüde:

Ders
→ Kurs
→ Akademik Yıl
→ Ünite
→ Konu

seçimleri kullanılmalı.

## 4. KURS MANTIĞI

Bir Ders seçildiğinde yalnızca o derse bağlı kurslar gösterilmeli.

Örneğin:

Ders:
Türkçe

Kurs:
Türkçe 7. Sınıf

Akademik Yıl:
2026–2027

Kurs seçiminden sonra yalnızca seçilen kursa ait üniteler ve konular gösterilmeli.

Farklı akademik yıllardaki aynı kurslar birbirinden bağımsız içerik yapıları olarak ele alınmalı.

Örnek:

Türkçe
├── Türkçe 7. Sınıf
│   ├── 2025–2026
│   └── 2026–2027
└── Türkçe 8. Sınıf
    └── 2026–2027

## 5. ÜNİTE VE KONU SEÇİMİ

Kurs/akademik yıl seçilmeden:

- Ünite seçimi aktif olmamalı.
- Konu seçimi aktif olmamalı.
- İçerik oluşturma alanı açılmamalı.

Kurs seçildikten sonra yalnızca o kursa ait üniteler gösterilmeli.

Ünite seçildikten sonra yalnızca o üniteye ait konular gösterilmeli.

Konu seçildikten sonra mevcut içerik/blok oluşturma sistemi kullanılmalı.

## 6. SAĞ PANEL

Mevcut sağ paneldeki:

- Sınıf Ekle
- Sınıfı Düzenle
- Ders Ekle
- Ünite Ekle
- Konu Ekle

yapısını yeni hiyerarşiye göre düzenle.

Gereksiz "Sınıf Ekle" işlemini içerik hiyerarşisinin ana CRUD işlemi olarak kullanma.

Yeni yapı mümkün olduğunca:

- Ders Ekle / Düzenle
- Kurs Ekle / Düzenle
- Akademik Yıl belirleme/düzenleme
- Ünite Ekle / Düzenle
- Konu Ekle / Düzenle

mantığıyla çalışmalı.

Ancak mevcut çalışan CRUD yapısı varsa sıfırdan oluşturma.
Mevcut yapıyı yeni hiyerarşiye bağla.

## 7. BLOK TÜRLERİ

Sol taraftaki mevcut blok türleri korunmalı:

- Metin
- PDF
- Sunum
- Word
- Görsel
- Video
- Ses
- Web Link
- Ödev
- Soru
- Sınav

Bu action kapsamında blok türlerini yeniden tasarlama.

Mevcut sürükle-bırak / içerik oluşturma mantığını bozma.

Konu seçildikten sonra mevcut içerik oluşturma sistemi çalışmaya devam etmeli.

## 8. EKRAN AKIŞI

Ders Oluşturucu ekranı aşağıdaki akışla çalışmalı:

1. Ders seç
2. Kurs seç
3. Akademik yıl/kurs bağlamını belirle
4. Ünite seç
5. Konu seç
6. Seçilen konuya ait mevcut içerikleri göster
7. Yeni blok ekleme veya mevcut içeriği düzenleme

Her seçim bir önceki seçime bağlı olmalı.

Bir üst seçim değiştirildiğinde alt seçimler güvenli şekilde temizlenmeli.

Örneğin Ders değişirse:

Kurs → Ünite → Konu

seçimleri eski derse ait olarak kalmamalı.

## 9. MEVCUT VERİLERİ KORU

Mevcut Ders, Ünite, Konu ve İçerik kayıtlarını koru.

Mevcut verileri silme veya yeniden oluşturma.

Migration gerekiyorsa backward compatibility korunmalı.

Mevcut içeriklerin yanlış Ders/Kurs/Ünite/Konu ilişkisine düşmesini engelle.

## 10. UI

Mevcut MyEduApp Design System'i kullan.

Ekranın genel tasarımını gereksiz yere değiştirme.

Sadece yeni hiyerarşinin anlaşılır olması için gerekli seçim alanlarını düzenle.

Mevcut:
- typography
- spacing
- colors
- buttons
- dropdown/component
- icons
- responsive yapı

korunmalı.

Yeni component oluşturmak yerine mevcut componentleri yeniden kullan.

## 11. KAPSAM

Bu action yalnızca mevcut Ders Oluşturucu ekranının
yeni Ders Platformu mimarisine uyarlanması içindir.

Öğrenci Platformu, raporlama, PDF/Excel veya başka modüllerde
kapsam dışı değişiklik yapma.

Gereksiz refactor yapma.

## 12. KABUL KRİTERLERİ

- [ ] Ders seçimi ana içerik seviyesidir.
- [ ] Sınıf seçimi içerik hiyerarşisinin ana seviyesi olarak kullanılmıyor.
- [ ] Ders → Kurs → Akademik Yıl → Ünite → Konu hiyerarşisi destekleniyor.
- [ ] Ders seçilmeden kurs seçilemiyor.
- [ ] Kurs seçilmeden ünite seçilemiyor.
- [ ] Ünite seçilmeden konu seçilemiyor.
- [ ] Seçilen kursa ait üniteler gösteriliyor.
- [ ] Seçilen üniteye ait konular gösteriliyor.
- [ ] Konu seçildiğinde mevcut içerik/blok sistemi çalışıyor.
- [ ] Mevcut blok türleri korunuyor.
- [ ] Mevcut içerikler korunuyor.
- [ ] Mevcut CRUD yapısı mümkün olduğunca yeniden kullanılıyor.
- [ ] Gereksiz yeni model/repository/service/component oluşturulmuyor.
- [ ] Mevcut Design System korunuyor.
- [ ] Mevcut çalışan özellikler bozulmuyor.