# ACTION — ÖĞRENCİ PLATFORMU VE DERS PLATFORMU UI DÜZELTMELERİ

project.mdc içindeki tüm kurallar aynen geçerlidir.

Bu action mevcut çalışan özellikleri bozmadan yalnızca belirtilen UI/layout ve
gerekli minimum veri bağlantısı düzeltmelerini kapsar.

==================================================
1. ÖĞRENCİ PLATFORMU — KOLON LAYOUT
==================================================

Öğrenci Platformunda sabit kategorilerde kolon eklendiğinde kolonlar arasında
gereğinden fazla yatay boşluk oluşuyor.

Örneğin:

Diyalog                    Kelime

arasında gereksiz büyük boşluk oluşuyor.

Bu layout düzeltilmelidir.

İstenen:

- Kolonlar gereksiz şekilde genişlememeli.
- Kolonlar arasındaki boşluk minimum ve dengeli olmalı.
- Öğrenci adı alanı yeterli genişliğini korumalı.
- Kolon başlığı, veri alanı ve mevcut edit/delete/clear işlemleri korunmalı.
- Header ve veri hücrelerinin yatay hizası korunmalı.
- Kolon sayısı arttığında ekranı sıkıştırmak yerine mevcut yapıya uygun
  horizontal scroll kullanılmalı.
- Çok sayıda kolon olduğunda kolonlar kullanılabilir genişlikte kalmalı.
- "Her kolon ekranın eşit genişliğini alsın" yaklaşımı kullanılmamalı.
- İçeriğe uygun kompakt kolon genişliği tercih edilmeli.

Özellikle mevcut Expanded, SizedBox, width, spacing veya benzeri layout
kullanımlarından hangisinin gereksiz boşluk oluşturduğunu tespit et.

Mevcut tablo/grid sistemini değiştirme.
Yeni tablo/grid sistemi oluşturma.

==================================================
2. TABLET / PHONE RESPONSIVE UI
==================================================

Mevcut uygulamaya responsive/tablet davranışı eklenirken mevcut fonksiyonlar
bozulmamalıdır.

Projede mevcut responsive yardımcıları veya breakpoint yapısı varsa onları
kullan.

Yeni responsive architecture veya dependency oluşturma.

Desktop:
- Geniş ve rahat layout.
- Kolonlar gereksiz şekilde ekranın tamamına yayılmamalı.

Tablet:
- Kompakt layout.
- Gerektiğinde horizontal scroll.
- Butonlar ve veri alanları kullanılabilir kalmalı.

Phone:
- İçerik ekran dışına taşmamalı.
- Gerektiğinde horizontal scroll kullanılmalı.
- Mevcut işlevlere erişim korunmalı.

==================================================
3. DERS OLUŞTURMA PLATFORMU — BAĞIMSIZ GÖRSELLER
==================================================

Ders Oluşturma Platformunda Ders, Kurs, Ünite ve Konu birbirinden bağımsız
görsel alanlarına sahip olmalıdır.

Doğru yapı:

Ders
→ Ders Görseli

Kurs
→ Kurs Görseli

Ünite
→ Ünite Görseli

Konu
→ Konu Görseli

Mevcut problem:

Kurs Ekle ekranında seçilen görsel hem Ders Seç hem de Kurs Seç alanında
aynı görsel olarak kullanılabiliyor.

Bu davranış düzeltilmelidir.

Bir entity'nin görseli başka bir entity'nin görselini değiştirmemelidir.

==================================================
4. DERS EKLE / DERSİ DÜZENLE
==================================================

Ders Ekle ve Dersi Düzenle ekranlarında:

- Ders adı
- Ders görseli

alanları bulunmalı.

Ders görseli yalnızca ilgili Ders kaydına ait olmalıdır.

Örneğin:

Türkçe → Ders Görseli A
Matematik → Ders Görseli B

birbirinden bağımsız olmalıdır.

==================================================
5. KURS EKLE / KURSU DÜZENLE
==================================================

Kurs Ekle ve Kursu Düzenle ekranlarında:

- Kurs adı
- Akademik yıl
- Sınıf
- Kurs görseli

alanları bulunmalıdır.

Kurs görseli yalnızca ilgili Kurs kaydına ait olmalıdır.

Kurs görseli değiştirildiğinde:

- Ders görseli değişmemeli.
- Başka kurs değişmemeli.
- Ünite değişmemeli.
- Konu değişmemeli.

==================================================
6. ÜNİTE EKLE / ÜNİTEYİ DÜZENLE
==================================================

Ünite Ekle ve Üniteyi Düzenle ekranlarında:

- Ünite adı
- Ünite numarası/sırası
- Ünite görseli

alanları bulunmalıdır.

Her ünite kendi görseline sahip olmalıdır.

Örneğin:

1. Ünite → Görsel A
2. Ünite → Görsel B
3. Ünite → Görsel C

birbirinden bağımsız olmalıdır.

==================================================
7. KONU EKLE / KONUYU DÜZENLE
==================================================

Konu Ekle ve Konuyu Düzenle ekranlarında:

- Konu adı
- Konu görseli

alanları bulunmalıdır.

Her konu kendi bağımsız görseline sahip olmalıdır.

Bir konunun görseli değiştirildiğinde diğer konular, ünite, kurs veya ders
etkilenmemelidir.

==================================================
8. GÖRSELLERİN DOĞRU YERDE GÖSTERİLMESİ
==================================================

Ders Platformunda:

Ders Seç
→ Ders görseli

Kurs Seç
→ Kurs görseli

Ünite listesi
→ Ünite görseli

Konu listesi
→ Konu görseli

kullanılmalıdır.

Üst seviyedeki görsel alt seviyeye otomatik olarak atanmış gibi
davranmamalıdır.

Bir entity'nin görseli yoksa güvenli placeholder kullanılabilir.

==================================================
9. DATABASE / MODEL KORUMASI
==================================================

Önce mevcut Ders/Kurs/Ünite/Konu model ve repository yapısını analiz et.

Mevcut image/imagePath/imageUrl alanlarının nasıl kullanıldığını tespit et.

Gerekiyorsa mevcut mimariye minimum ve backward-compatible değişiklik yap.

Mevcut veriler kaybolmamalıdır.

Mevcut kayıtlar yeni yapıyla açılabilmelidir.

Gereksiz migration yapma.

Yeni duplicate model, repository veya service oluşturma.

Mevcut image picker/storage mekanizması varsa aynen kullan.

Yeni dependency ekleme.

==================================================
10. ÖNEMLİ — FONKSİYONLARI BOZMA
==================================================

Aşağıdaki mevcut özelliklerin business logic'i değiştirilmemelidir:

- Ders oluşturma
- Kurs oluşturma
- Ünite oluşturma
- Konu oluşturma
- Doküman ekleme
- İçerik oluşturma
- Ders seçme
- Kurs seçme
- Ünite seçme
- Konu seçme
- Öğrenci listesi
- Kategori sistemi
- Kolon ekleme
- Kolon düzenleme
- Kolon silme
- Not/değer girişi
- Autosave
- Tarih sistemi
- Raporlama
- Sınıf yönetimi

Sadece gerekli UI/layout ve görsel sahipliği düzeltmeleri yapılmalıdır.

==================================================
11. VALIDATION
==================================================

Öğrenci Platformu:

- Bir sınıf aç.
- Aktiviteler gibi sabit bir kategori aç.
- En az 2-3 kolon ekle.
- Kolonlar arasındaki boşluğu kontrol et.
- Değer gir.
- Autosave'i kontrol et.
- Tarih değiştir.
- Eski tarihe dön.
- Verinin korunduğunu kontrol et.
- Kolon düzenle/sil işlemlerini kontrol et.
- Çok sayıda kolon ekle.
- Horizontal scroll'u kontrol et.
- Tablet genişliğini kontrol et.
- Telefon genişliğini kontrol et.

Ders Platformu:

- Bir Ders oluştur ve Ders Görseli A ekle.
- Bir Kurs oluştur ve Kurs Görseli B ekle.
- Bir Ünite oluştur ve Ünite Görseli C ekle.
- Bir Konu oluştur ve Konu Görseli D ekle.
- Ders Seç bölümünde A görünmeli.
- Kurs Seç bölümünde B görünmeli.
- Ünite bölümünde C görünmeli.
- Konu bölümünde D görünmeli.
- Herhangi bir görsel değiştirildiğinde diğerleri değişmemeli.

==================================================
12. ÇALIŞMA PRENSİBİ
==================================================

Önce mevcut implementasyonu analiz et.

Sadece görev için gerekli dosyaları değiştir.

Mevcut çalışan kodu yeniden yazma.

Gereksiz refactor yapma.

Yeni dependency ekleme.

Yeni architecture oluşturma.

Mevcut Design System'i koru.

Mevcut database ve business logic'i koru.

Görev tamamlandıktan sonra yalnızca ilgili analyzer/test kontrollerini
çalıştır.

Kapsam dışı sorunları düzeltme.

İşlem sonunda:

1. Değiştirilen dosyalar
2. Yapılan değişiklikler
3. Test/analyzer sonucu

kısa şekilde raporlanmalıdır.