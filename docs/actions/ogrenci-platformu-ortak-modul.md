# ACTION — ÖĞRENCİ PLATFORMUNU ÖĞRETMEN VE ÖĞRENCİ PANELİNDE ORTAK KULLANMA

project.mdc içindeki tüm kurallar aynen geçerlidir.

## AMAÇ

Mevcut Öğretmen Panelinde çalışan "Öğrenci Platformu"nu,
Öğrenci Panelinde de kullanılabilir hale getir.

Öğrenci Platformunu kopyalama veya ikinci bir implementasyon oluşturma.

Mevcut Öğrenci Platformunu ortak kullanılabilir bir ekran/modül olarak
kullan ve iki panelin de aynı temel implementasyonu kullanmasını sağla.

---

# 1. ÖĞRETMEN PANELİ

Mevcut Öğretmen Panelindeki:

- Ana Sayfa
- Ders Platformu
- Öğrenci Platformu
- Raporlar
- Kullanım Kılavuzu
- Ayarlar

navigation yapısını ve mevcut işlevlerini koru.

Öğretmen Panelindeki mevcut Öğrenci Platformu çalışmaya devam etmeli.

Mevcut öğretmen özelliklerini değiştirme veya kaldırma.

---

# 2. ÖĞRENCİ PANELİ

Öğrenci Paneli sadeleştirilmeli.

Öğrenci Panelinde yalnızca:

1. Ders Platformu
2. Öğrenci Platformu

menüleri bulunmalı.

Mevcut "Öğrenme Paneli" menüsü tamamen kaldırılmalı.

Öğrenme Paneli çalışmadığı için yeniden geliştirilmemeli.

Öğrenme Paneline ait kullanılmayan navigation/route bağlantıları
varsa güvenli şekilde kaldırılmalı.

Ancak Ders Platformu ve Öğrenci Platformunun route'ları ve
çalışan fonksiyonları bozulmamalı.

---

# 3. ORTAK ÖĞRENCİ PLATFORMU

Öğretmen Panelindeki mevcut Öğrenci Platformunu temel al.

Öğrenci Paneli için aynı ekranı kopyalayıp ikinci bir ekran oluşturma.

Aynı:

- widget
- screen
- model
- provider
- repository
- service
- business logic

için duplicate yapı oluşturma.

Mümkün olan en küçük değişiklikle mevcut Öğrenci Platformunu
iki panel tarafından kullanılabilir hale getir.

---

# 4. ROL BAZLI GÖRÜNÜRLÜK

Aynı Öğrenci Platformu kullanılmalı ancak kullanıcı rolüne göre
görünen işlemler değişebilmeli.

## Öğretmen

Mevcut öğretmen yetkileri ve fonksiyonları korunmalı.

Örneğin öğretmen mevcut sistemde:

- sınıf ekleyebiliyorsa
- öğrenci ekleyebiliyorsa
- kategori yönetebiliyorsa
- veri girebiliyorsa
- rapor oluşturabiliyorsa

bunlar çalışmaya devam etmeli.

## Öğrenci

Öğrenci yalnızca kendisine ait bilgileri görebilmeli.

Başka öğrencilerin kişisel veya akademik kayıtlarını görememeli.

Öğrenciye öğretmen yönetim işlemleri gösterilmemeli.

Örneğin öğrenci tarafında:

- Sınıf Ekle
- Öğrenci Ekle
- Öğrenci Sil
- Sınıf Sil
- Kategori Yönetimi
- öğretmen yönetim işlemleri

gibi kontroller görünmemeli.

Mevcut yetkilendirme sistemi varsa onu kullan.

Yeni bir authorization sistemi oluşturma.

---

# 5. VERİ

Öğretmen ve öğrenci mevcut SQLite/veri yapısını kullanmalı.

Yeni database veya duplicate tablo oluşturma.

Mevcut:

- sınıflar
- öğrenciler
- kategoriler
- kayıtlar
- tarihler
- notlar
- görevler
- aktiviteler

korunmalı.

Mevcut offline-first yapı bozulmamalı.

---

# 6. DERS PLATFORMU

Ders Platformuna dokunma.

Mevcut Ders Platformu hem öğretmen hem öğrenci tarafında
çalışmaya devam etmeli.

Bu action kapsamında Ders Platformunun business logic,
database veya içerik yapısını değiştirme.

---

# 7. RESPONSIVE / TABLET / TELEFON

Ortak Öğrenci Platformu mevcut responsive yapıyla uyumlu olmalı.

Desktop:
- mevcut geniş ekran tasarımı korunmalı.

Tablet:
- layout ekran genişliğine uyarlanmalı.

Telefon:
- içerik dar ekrana uygun şekilde tek kolon veya
  mevcut responsive yaklaşım ile gösterilmeli.

Bu action kapsamında yeni bir tasarım sistemi oluşturma.

Mevcut Design System'i kullan.

---

# 8. NAVIGATION SONUCU

Son durumda yapı aşağıdaki gibi olmalı:

## Öğretmen Paneli

Ana Sayfa
Ders Platformu
Öğrenci Platformu
Raporlar
Kullanım Kılavuzu
Ayarlar

## Öğrenci Paneli

Ders Platformu
Öğrenci Platformu

Öğrenci Panelinde "Öğrenme Paneli" bulunmamalı.

---

# 9. KRİTİK KURALLAR

KOPYALA-YAPIŞTIR YAPMA.

Mevcut Öğrenci Platformunun ikinci versiyonunu oluşturma.

Mevcut çalışan sistemi temel al.

Gereksiz refactor yapma.

Yeni dependency ekleme.

Yeni architecture oluşturma.

Yeni database/table oluşturma.

Mevcut business logic'i yeniden yazma.

Sadece gerekli navigation, role-based visibility ve ortak kullanım
değişikliklerini yap.

---

# 10. ANALİZ VE UYGULAMA

Önce mevcut kodu analiz et.

Özellikle:

- Öğretmen Paneli navigation
- Öğrenci Paneli navigation
- Öğrenme Paneli route/screen
- Öğretmen Öğrenci Platformu
- Öğrenci/Teacher role yapısı
- mevcut routing
- provider/state management

dosyalarını tespit et.

Sonra minimum gerekli dosyalarda değişiklik yap.

---

# 11. VALIDATION

Değişikliklerden sonra kontrol et:

- [ ] Öğretmen Paneli açılıyor.
- [ ] Öğretmen Panelindeki mevcut menüler çalışıyor.
- [ ] Öğretmen → Öğrenci Platformu çalışıyor.
- [ ] Öğrenci Paneli açılıyor.
- [ ] Öğrenci Panelinde yalnızca Ders Platformu ve Öğrenci Platformu var.
- [ ] Öğrenme Paneli menüsü kaldırıldı.
- [ ] Öğrenme Paneline ait kullanılmayan route bağlantıları kaldırıldı.
- [ ] Öğrenci → Ders Platformu çalışıyor.
- [ ] Öğrenci → Öğrenci Platformu çalışıyor.
- [ ] Öğrenci başka öğrencilerin verilerini göremiyor.
- [ ] Öğrenci öğretmen yönetim kontrollerini görmüyor.
- [ ] Öğretmenin mevcut yetkileri bozulmadı.
- [ ] Mevcut SQLite verileri korunuyor.
- [ ] Desktop görünümü bozulmadı.
- [ ] Tablet görünümü çalışıyor.
- [ ] Telefon görünümü çalışıyor.

İlgili analyzer/test kontrollerini çalıştır.

Sadece bu action ile ilgili hataları düzelt.

İşlem sonunda değiştirilen dosyaları ve test sonuçlarını
kısaca raporla.