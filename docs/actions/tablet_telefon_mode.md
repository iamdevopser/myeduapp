# 11. RESPONSIVE / TABLET / TELEFON MODE

MyEduApp Öğretmen Platformu masaüstü, tablet ve telefon ekranlarında
sorunsuz çalışmalıdır.

Bu kapsamda mevcut masaüstü tasarımı bozulmadan responsive davranış
eklenmelidir.

Yeni dependency veya responsive framework ekleme.
Mevcut Flutter layout, MediaQuery, LayoutBuilder ve mevcut
component yapılarından yararlan.

## 11.1 BREAKPOINT MANTIĞI

Ekran genişliğine göre üç temel layout davranışı kullanılmalı:

### DESKTOP
Geniş ekranlarda mevcut masaüstü tasarımı korunmalı.

- Sol ana sidebar görünür.
- Ana içerik alanı geniş kullanılır.
- Gerekli çoklu panel yapıları korunur.
- Ders Platformunda Content alanı mümkün olduğunca geniş tutulur.

### TABLET

Tablet ekranlarında özel Tablet Mode davranışı uygulanmalı.

- Ana sidebar daraltılabilir olmalı.
- Sidebar açıkken içerik alanı gereksiz şekilde ezilmemeli.
- Sidebar kapalıyken içerik tam genişliğe yaklaşmalı.
- Ders Platformundaki "Konu Seç" paneli de daraltılabilir/hover
  davranışını korumalı.
- Content alanı mümkün olduğunca geniş tutulmalı.
- Yan paneller gerektiğinde overlay/drawer şeklinde açılabilmeli.
- Masaüstündeki üçlü kolon yapısı tablet ekranına zorla
  sığdırılmamalı.
- Metinler, butonlar ve kartlar taşmamalı.
- Yatay scroll yalnızca gerçekten gerekli içeriklerde kullanılmalı.

### TELEFON

Telefon ekranlarında tek ana içerik alanı kullanılmalı.

- Ana sidebar kalıcı olarak açık olmamalı.
- Sidebar drawer/overlay olarak açılmalı.
- Sayfa içeriği tam genişliği kullanmalı.
- Üçlü veya iki kolonlu desktop layout doğrudan telefona
  küçültülmemeli.
- Paneller gerektiğinde sıralı/tek ekranlı hale getirilmeli.
- Butonlar ve kontroller dokunmatik kullanıma uygun olmalı.
- Metin taşmaları önlenmeli.
- İçerik yatay olarak sıkışmamalı.

---

# 12. ORTAK RESPONSIVE DAVRANIŞ

Responsive tasarım sadece Ana Sayfa için değil,
Öğretmen Platformundaki tüm sayfalarda uygulanmalıdır.

Özellikle:

- Ana Sayfa
- Ders Platformu
- Ders Oluşturucu
- Öğrenci Platformu
- Raporlar
- Kullanım Kılavuzu
- Ayarlar

ekranları mevcut fonksiyonları korunarak responsive hale getirilmelidir.

Aynı responsive yaklaşım mümkün olduğunca ortak component/layout
mantığıyla uygulanmalıdır.

Ancak görev için gerekli değilse yeni genel mimari veya büyük bir
responsive framework oluşturma.

---

# 13. SIDEBAR RESPONSIVE DAVRANIŞI

Ana Sayfadaki mevcut sidebar yapısı temel alınmalıdır.

Desktop:
- Geniş sidebar.

Tablet:
- Daraltılabilir sidebar.
- Hover veya toggle ile genişleyebilir.

Telefon:
- Drawer/overlay sidebar.
- Menü seçildiğinde sidebar otomatik kapanabilir.

Mevcut sidebar icon, text, active state ve navigation davranışı
korunmalıdır.

---

# 14. DERS PLATFORMU RESPONSIVE DAVRANIŞI

Desktop:
- Konu seç paneli
- Geniş Content alanı

Tablet:
- Konu seç paneli daraltılabilir.
- Content alanı öncelikli olmalıdır.

Telefon:
- Konu listesi ayrı bir drawer/overlay/panel olarak açılmalı.
- Kullanıcı konu seçtiğinde konu paneli kapanmalı.
- Seçilen konuya ait Content tam genişliğe yakın açılmalı.

Kullanıcı telefonda veya tablette:

Konu → Doküman listesi → Doküman

şeklinde gereksiz ikinci bir seçim yapmamalıdır.

Akış:

Konu seç
↓
Content alanında doğrudan aç

olmalıdır.

---

# 15. ÖĞRENCİ PLATFORMU RESPONSIVE DAVRANIŞI

Öğrenci listeleri ve kategori tabloları mobil/tablet ekranlara
uyumlu olmalıdır.

Desktop:
- Tablo görünümü korunabilir.

Tablet:
- Tablo kullanılabilir ancak sütun genişlikleri kontrollü olmalı.
- Gereksiz sütunlar sıkıştırılmamalı.

Telefon:
- Öğrenci kayıtları gerektiğinde kart/list item şeklinde
  dikey gösterilebilir.
- Mevcut veri giriş fonksiyonları korunmalı.
- Tarih seçimi, kategori seçimi ve autosave çalışmaya devam etmeli.
- Öğrenci sayısı ne olursa olsun tüm öğrenciler erişilebilir olmalı.
- 26 öğrencilik sınıf telefonda da eksiksiz görüntülenebilmeli.

Mevcut veri giriş mantığı değiştirilmemelidir.

---

# 16. RAPORLAR RESPONSIVE DAVRANIŞI

Rapor filtreleri desktop'ta yatay düzenlenebilir.

Tablet ve telefonda:

- Filtreler dikey veya wrap layout'a geçmeli.
- Butonlar taşmamalı.
- PDF/Excel işlemleri erişilebilir kalmalı.

Rapor oluşturma mantığı değiştirilmemelidir.

---

# 17. DOKUNMATİK KULLANIM

Tablet ve telefonlarda:

- Tıklanabilir alanlar yeterli dokunma alanına sahip olmalı.
- Hover'a bağımlı kritik bir fonksiyon bulunmamalı.
- Hover sadece yardımcı bir davranış olmalı.
- Mobil cihazlarda hover yerine tap/toggle kullanılmalı.
- Küçük icon butonları erişilebilir olmalı.

---

# 18. RESPONSIVE TASARIM KURALLARI

Kesinlikle:

- Desktop layout'u küçültüp telefona sıkıştırma.
- Sabit genişlikler nedeniyle taşma oluşturma.
- İçeriği kesme.
- Öğrenci listesini sınırlandırma.
- Doküman/content alanını gereksiz daraltma.
- Mevcut navigation'ı bozma.
- Yeni dependency ekleme.
- Mevcut database/model/provider/repository yapısını değiştirme.

Öncelik:

Desktop
→ mevcut tasarım korunur.

Tablet
→ mevcut tasarım kontrollü şekilde daraltılır.

Telefon
→ aynı fonksiyonlar tek kolon/drawer mantığına adapte edilir.

---

# 19. RESPONSIVE TEST

Değişikliklerden sonra en az şu ekran genişlikleri dikkate alınmalı:

- Desktop: 1920 px
- Desktop: 1366 px
- Tablet yatay: yaklaşık 1024 px
- Tablet dikey: yaklaşık 768 px
- Telefon: yaklaşık 430 px
- Küçük telefon: yaklaşık 375 px

Amaç belirli piksel değerlerine bağımlı bir tasarım oluşturmak değil;
layout'un farklı ekran genişliklerinde düzgün davranmasını sağlamaktır.

Özellikle kontrol et:

- Sidebar
- Navigation
- Kartlar
- Butonlar
- Dropdownlar
- Ders Platformu
- Konu paneli
- Content alanı
- Öğrenci listesi
- Kategori tabloları
- Tarih seçiciler
- Rapor filtreleri
- PDF/Excel butonları

Hiçbir önemli içerik taşmamalı veya ekran dışına çıkmamalıdır.