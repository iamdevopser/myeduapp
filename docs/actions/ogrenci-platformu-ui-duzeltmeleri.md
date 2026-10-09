# ACTION — ÖĞRENCİ PLATFORMU UI / LAYOUT DÜZELTMELERİ

project.mdc içindeki tüm proje kuralları aynen geçerlidir.

Bu action yalnızca mevcut Öğrenci Platformunun görsel/layout problemlerini düzeltmek içindir.

ÖNEMLİ:
- Mevcut çalışan fonksiyonları değiştirme.
- Database, model, repository, provider, servis ve routing mantığını değiştirme.
- Mevcut autosave, tarih, kategori, öğrenci, not ve raporlama mantığını bozma.
- Yeni dependency ekleme.
- Yeni mimari oluşturma.
- Gereksiz refactor yapma.
- Önce mevcut UI implementasyonunu analiz et.
- Sadece gerekli UI/layout dosyalarında minimum değişiklik yap.
- Mevcut Design System, renkler, typography, iconlar ve component yapısını koru.

---

# 1. ÖĞRENCİ PLATFORMU KOLON BOŞLUKLARI

Mevcut Öğrenci Platformunda sabit kategorilerden
(Öğrenci Listesi, Materyaller, Aktiviteler, Ödevler, Sınavlar)
birine yeni kolon eklendiğinde kolonlar arasında gereğinden fazla yatay boşluk oluşuyor.

Örneğin:

Diyalog
        [çok büyük boşluk]
Kelime
        [çok büyük boşluk]

Bu layout düzeltilmelidir.

## İstenen davranış

Kolonlar mümkün olduğunca kompakt ve düzenli görünmeli.

- Kolon genişlikleri gereksiz şekilde büyük olmamalı.
- Her kolon yalnızca içeriğinin ihtiyaç duyduğu makul genişliği kullanmalı.
- Kolonlar arasında gereksiz boş alan bırakılmamalı.
- Başlık, puan/değer alanı ve mevcut kolon işlemleri birbirine dengeli yerleştirilmeli.
- Öğrenci adı alanı yeterli genişliğini korumalı.
- Kolonlar birbirine çok yaklaşmamalı; ancak mevcut görüntüdeki büyük boşluk kesinlikle kaldırılmalı.
- Edit/delete/clear gibi mevcut kolon işlemleri korunmalı.
- Kolon ekleme, silme, düzenleme ve veri girme fonksiyonları kesinlikle değişmemeli.

## Responsive davranış

Masaüstünde:
- Kullanılabilir yatay alanı verimli kullan.
- Kolonlar gereksiz şekilde ekranın tamamına yayılmamalı.
- Çok sayıda kolon olduğunda tablo düzgün şekilde yatay scroll desteklemeli.

Tablet modunda:
- Kolon genişlikleri daha kompakt olmalı.
- Öğrenci adı ve kolon başlıkları okunabilir kalmalı.
- Çok sayıda kolon varsa yatay scroll kullanılmalı.
- Ekranı sıkıştırarak kolon içeriklerini kullanılmayacak kadar daraltma.

Telefon modunda:
- Mevcut fonksiyonlar korunmalı.
- Tablo kullanılabilir kalmalı.
- Gerektiğinde yatay scroll kullanılmalı.
- Öğrenci adı ve aktif kolon verisi erişilebilir olmalı.
- Sabit genişlik nedeniyle ekran taşması oluşturma.

---

# 2. KOLON LAYOUT İLKESİ

Mevcut tablo/grid implementasyonunu bul ve hangi widget/layout yapısının kolonlara gereğinden fazla genişlik verdiğini tespit et.

Öncelik:

1. Mevcut layout'u düzelt.
2. Mevcut componentleri kullan.
3. Gerekiyorsa mevcut kolon genişliği hesaplamasını iyileştir.
4. Gereksiz yeni table/grid sistemi oluşturma.

Özellikle şu tip problemlere dikkat et:

- Expanded kullanımından kaynaklanan gereksiz genişlik
- Sabit büyük width değerleri
- Gereksiz SizedBox/spacing
- Her kolonun ekran genişliğinin eşit büyük bir bölümünü alması
- Header ve data cell genişliklerinin farklı hesaplanması
- Kolon action butonları için gereğinden fazla alan ayrılması

Header ile ilgili data hücrelerinin yatay hizası korunmalı.

---

# 3. KOLON BAŞLIKLARI

Kolon başlığı:

Kolon Adı
Açıklama

şeklinde mevcut sistemde destekleniyorsa kompakt şekilde gösterilmeli.

Açıklama metni kolonlar arasında ekstra genişlik oluşturacak şekilde layout'u büyütmemeli.

Uzun açıklamalarda:
- text overflow kontrolü,
- maxLines,
- ellipsis
veya mevcut Design System'deki uygun çözüm kullanılabilir.

Ancak açıklamanın görünürlüğü tamamen kaldırılmamalıdır.

---

# 4. MEVCUT İŞLEVLERİN KORUNMASI

Bu UI değişikliği aşağıdaki fonksiyonların hiçbirini değiştirmemeli:

- Öğrenci listesi
- Öğrenci ekleme/düzenleme/silme
- Kategori sistemi
- Kolon ekleme
- Kolon düzenleme
- Kolon silme
- Kolon sıralama
- Tarih seçimi
- Önceki/sonraki tarih
- Autosave
- Öğrenci puan/değer girişleri
- Mevcut kayıtların güncellenmesi
- PDF raporları
- Excel raporları
- Sınıf yönetimi
- Sınıf sıralaması
- Kategori sıralaması

Sadece bunların mevcut UI üzerindeki yerleşimi düzeltilmelidir.

---

# 5. TABLET / PHONE RESPONSIVE MODE

Mevcut uygulamaya zarar vermeden responsive davranışı kontrol et.

Breakpoint veya responsive yardımcıları projede zaten varsa onları kullan.

Yeni responsive architecture oluşturma.

Genel davranış:

DESKTOP
→ geniş ve rahat tablo

TABLET
→ kompakt tablo + gerektiğinde horizontal scroll

PHONE
→ kompakt tablo + horizontal scroll

Tablet ve telefonda:
- sidebar mevcut tasarım kararlarına uygun davranmalı,
- içerik ekran dışına taşmamalı,
- butonlar erişilebilir kalmalı,
- metinler kesilmemeli veya anlamsız şekilde sıkıştırılmamalı.

---

# 6. VALIDATION

Değişiklikten sonra özellikle şu senaryoları kontrol et:

1. Aktiviteler aç.
2. Birden fazla kolon ekle.
3. Kolonlar arasındaki gereksiz boşluğu kontrol et.
4. Kolon başlıklarını kontrol et.
5. Öğrenci değerlerini gir.
6. Autosave'in çalıştığını kontrol et.
7. Tarih değiştir.
8. Tekrar eski tarihe dön ve verilerin korunduğunu kontrol et.
9. Kolon düzenle/sil işlemlerini kontrol et.
10. Çok sayıda kolon ekle.
11. Yatay scroll davranışını kontrol et.
12. Tablet genişliğinde layout'u kontrol et.
13. Telefon genişliğinde layout'u kontrol et.
14. Mevcut diğer Öğrenci Platformu fonksiyonlarının çalıştığını kontrol et.

Görev tamamlandığında sadece ilgili analyzer/test kontrollerini çalıştır.

Hata varsa yalnızca bu UI değişikliğiyle ilgili hataları düzelt.

Kapsam dışı hiçbir refactor yapma.