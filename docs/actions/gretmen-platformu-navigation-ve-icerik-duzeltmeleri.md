# ACTION — ÖĞRETMEN PLATFORMU NAVİGASYON VE İÇERİK GÖSTERİM DÜZELTMELERİ

project.mdc içindeki tüm kurallar aynen geçerlidir.

BU ACTION'IN TEMEL KURALI:

Mevcut çalışan özelliklerin fonksiyonunu, veri akışını, database yapısını,
provider/state management yapısını, repository/service yapısını ve routing
mantığını bozma.

Bu action yeni bir sistem tasarlamak için değil, mevcut Öğretmen Platformunun
navigation ve görsel kullanım deneyimindeki belirlenen sorunları düzeltmek
içindir.

Mevcut component, layout, design system, icon, typography, spacing ve
navigation yapısını mümkün olduğunca yeniden kullan.

Gereksiz refactor yapma.
Yeni dependency ekleme.
Yeni architecture oluşturma.
Aynı işlevi yapan yeni component/service/model oluşturma.

Önce mevcut implementasyonu analiz et, sonra yalnızca gerekli dosyalarda
minimum değişiklik yap.

---

# 1. HIZLI İŞLEMLER — GERİ DÖN BUTONU

Ana Sayfa > Hızlı İşlemler bölümündeki menülerden bir sayfaya geçildiğinde,
açılan sayfada geri dönüş imkanı bulunmalıdır.

Şu anda "Ders Platformu Oluştur" ekranında geri butonu bulunmaktadır.
Diğer Hızlı İşlemler ekranlarında da aynı navigation davranışı
uygulanmalıdır.

## Beklenen davranış

Hızlı İşlemler üzerinden açılan her sayfanın üst bölümünde,
"Ders Oluşturucu" ekranındaki mevcut geri butonuyla aynı mantıkta bir
geri dönüş butonu bulunmalıdır.

Örneğin:

Ana Sayfa
→ Hızlı İşlemler
→ Sınıf Ekle

Sınıf Ekle ekranında:

← geri butonu

bulunmalıdır.

Aynı davranış:

- Sınıf Ekle
- Öğrenci Ekle
- Rapor Oluştur
- Ders Platformu Oluştur

ve Ana Sayfadaki Hızlı İşlemler üzerinden açılan diğer mevcut ekranlar
için de geçerli olmalıdır.

## Önemli

Mevcut geri navigation mekanizması varsa onu kullan.

Yeni navigation sistemi oluşturma.

Geri butonu mümkünse mevcut Ders Oluşturucu ekranındaki header/back
component veya mevcut navigation yaklaşımı yeniden kullanılarak
uygulanmalıdır.

Geri butonuna basıldığında kullanıcı bir önceki ekrana dönmelidir.

Mevcut form, kayıt, veri veya state davranışını değiştirme.

Sayfa doğrudan açıldığında navigation stack davranışını bozma.

---

# 2. ÖĞRETMEN PLATFORMU SIDEBAR — HOVER İLE AÇILIP KAPANMA

Öğretmen Platformunun sol sidebar bölümü collapsible/expandable olmalıdır.

Mevcut sidebar navigation öğeleri korunmalıdır:

- Ana Sayfa
- Ders Platformu
- Öğrenci Platformu
- Raporlar
- Kullanım Kılavuzu
- Ayarlar
- Ana sayfaya dön

## Beklenen tasarım

Sidebar iki durumda çalışmalıdır:

### Kapalı durum

Sidebar daraltıldığında:

- Sadece ikonlar görünür.
- Navigation ikonları korunur.
- İçerik alanı daha geniş hale gelir.
- Aktif menü göstergesi korunur.

### Açık durum

Mouse sidebar üzerine geldiğinde:

- Sidebar genişlemelidir.
- Menü isimleri görünmelidir.
- Mevcut sidebar tasarımı korunmalıdır.
- Logo / MyEduApp alanı mevcut tasarım sistemine uygun şekilde
  genişlemelidir.

### Mouse sidebar dışına çıktığında

Sidebar tekrar daraltılabilir.

Temel davranış:

Sidebar dışarıda:
DAR

Mouse sidebar üzerine gelir:
GENİŞ

Mouse sidebar dışına çıkar:
DAR

## Önemli

Mevcut sidebar navigation fonksiyonları kesinlikle değişmemelidir.

Menülere tıklama davranışı aynı kalmalıdır.

Aktif sayfa göstergesi korunmalıdır.

Sidebar'ın açılıp kapanması route/navigation state'i değiştirmemelidir.

Responsive davranış mevcut sistemle uyumlu olmalıdır.

Tablet / küçük ekran davranışını bozacak bir değişiklik yapma.

Mevcut sidebar component'i varsa onu genişlet.
Yeni bir sidebar sistemi oluşturma.

Animasyon mevcut design system ile uyumlu, kısa ve sade olmalıdır.
Gereksiz karmaşık animasyon kullanma.

---

# 3. ANA SAYFA — HIZLI ÇALIŞMA ALANLARI KALDIRILMALI

Ana Sayfadaki:

"Hızlı Çalışma Alanları"

bölümü kaldırılmalıdır.

Bunun nedeni, aynı alanların zaten sol sidebar navigation içinde
bulunmasıdır.

Örneğin:

- Ders Platformu
- Öğrenci Platformu
- Materyaller
- Ödevler
- Raporlar

gibi alanların Ana Sayfada tekrar kart olarak gösterilmesine gerek yoktur.

## Yapılacak işlem

Sadece:

"Hızlı Çalışma Alanları"

bölümünü ve bu bölüme ait kartları kaldır.

Ana Sayfanın diğer mevcut bölümlerini koru.

Özellikle:

- Hoş geldiniz alanı
- Hızlı İşlemler
- Sınıflarım
- mevcut diğer işlevsel alanlar

gereksiz yere değiştirilmemelidir.

Ana Sayfa daha sade ve boşlukları daha dengeli kullanan bir yapıya
dönüştürülmelidir.

Hızlı İşlemler bölümü çalışmaya devam etmelidir.

---

# 4. DERS PLATFORMU — ÜNİTE / KONU / DOKÜMAN FİLTRELEME HATASI

Mevcut Ders Platformunda önemli bir içerik gösterim problemi bulunmaktadır.

Mevcut yapı:

Ders
→ Kurs
→ Ünite
→ Konu
→ Doküman

şeklindedir.

Bir ünite açıldığında o üniteye ait konular listelenmektedir.

Ancak şu anda ünite açıldığında, o ünite içindeki farklı konulara ait
dokümanlar topluca gösterilebilmektedir.

Bu davranış düzeltilmelidir.

## Beklenen davranış

Ünite açıldığında:

SOL PANEL:

Sadece o üniteye ait konular gösterilmelidir.

Örneğin:

Ünite 1

- Açılış Dersi
- Konu 2
- Konu 3
- Konu 4

SAĞ PANEL:

Seçilen konuya ait dokümanlar gösterilmelidir.

Örneğin:

Açılış Dersi seçildiğinde:

- 7.SINIF - GİRİŞ.pdf
- Açılış Dersi ile ilişkili diğer mevcut içerikler

gösterilebilir.

Konu 2 seçildiğinde:

- Yalnızca Konu 2'ye bağlı dokümanlar

gösterilmelidir.

Konu 3 seçildiğinde:

- Yalnızca Konu 3'e bağlı dokümanlar

gösterilmelidir.

## Kesin kural

Bir konunun dokümanı başka bir konuda gösterilmemelidir.

Bir ünitedeki bütün dokümanlar tek listede topluca gösterilmemelidir.

Doküman sorgusu/filtrelemesi mutlaka:

Kurs + Ünite + Konu

bağlamına göre yapılmalıdır.

Mevcut database ilişkileri ve içerik bağlantıları kullanılmalıdır.

## Konu seçimi

Kullanıcı konu değiştirdiğinde sağ taraftaki doküman listesi anında
seçilen konuya göre güncellenmelidir.

Eğer seçilen konunun hiç dokümanı yoksa:

"Bu konuya ait içerik bulunmuyor."

benzeri mevcut design system'e uygun bir empty state gösterilebilir.

Uygun mevcut component varsa onu kullan.

## İlk açılış

Ünite ilk açıldığında mevcut UX'e en uygun şekilde:

- ilk konu otomatik seçilebilir

veya

- kullanıcıdan konu seçmesi istenebilir.

Ancak sağ panelde farklı konuların dokümanları topluca
gösterilmemelidir.

---

# 5. VERİ BÜTÜNLÜĞÜ

Bu düzeltme sırasında:

- Mevcut doküman kayıtlarını silme.
- Mevcut konu kayıtlarını silme.
- Mevcut ünite kayıtlarını değiştirme.
- Database schema'yı gereksiz yere değiştirme.
- Migration oluşturma.
- Mevcut içerik ilişkilerini bozma.
- Dokümanları yeniden oluşturma.
- Aynı dokümanın duplicate kaydını oluşturma.

Sorun mümkünse yalnızca mevcut sorgunun/filtrelemenin yanlış
uygulanmasından kaynaklanıyorsa sorguyu düzelt.

Mevcut içerik verilerinin doğru ilişkilendirilmesini temel al.

---

# 6. UI TASARIMI

Bu action kapsamında yeni bir tasarım dili oluşturma.

Mevcut MyEduApp Design System kullanılmalıdır.

Korunacaklar:

- Renkler
- Typography
- Icon sistemi
- Border radius
- Spacing
- Button yapıları
- Header yapıları
- Card yapıları
- Sidebar görsel dili
- Aktif menü göstergeleri

Yapılacak değişiklikler mevcut ekranlarla görsel olarak uyumlu
olmalıdır.

Özellikle geri butonu, mevcut Ders Oluşturucu ekranındaki geri
butonuyla görsel ve davranışsal olarak tutarlı olmalıdır.

---

# 7. KAPSAM KONTROLÜ

Bu action kapsamında aşağıdakileri yapma:

- Yeni feature ekleme
- Database yeniden tasarlama
- Architecture değiştirme
- Provider mimarisini değiştirme
- Repository yeniden yazma
- Navigation sistemini baştan yazma
- Design system değiştirme
- Yeni dependency ekleme
- İlgisiz ekranları refactor etme
- Çalışan özellikleri yeniden yazma

Sadece bu action'da belirtilen sorunları düzelt.

---

# 8. UYGULAMA SIRASI

Önce mevcut implementasyonu analiz et:

1. Ana Sayfa
2. Hızlı İşlemler navigation
3. Ders Oluşturucu header/back yapısı
4. Sidebar component
5. Ders Platformu
6. Ünite → Konu → Doküman veri akışı
7. İlgili provider/state
8. İlgili repository/service sorguları

Daha sonra minimum gerekli dosyalarda değişiklik yap.

Önce navigation ve UI problemlerini düzelt.

Sonra Ders Platformundaki konu/doküman filtreleme problemini düzelt.

Son olarak mevcut analyzer/test kontrollerini çalıştır.

---

# 9. KABUL KRİTERLERİ

## Navigation

- [ ] Ders Platformu Oluştur ekranında geri butonu çalışıyor.
- [ ] Sınıf Ekle ekranında geri butonu bulunuyor.
- [ ] Öğrenci Ekle ekranında geri butonu bulunuyor.
- [ ] Rapor Oluştur ekranında geri butonu bulunuyor.
- [ ] Hızlı İşlemler üzerinden açılan diğer ilgili ekranlarda geri butonu
      bulunuyor.
- [ ] Geri butonları mevcut Ders Oluşturucu tasarımıyla uyumlu.
- [ ] Geri navigation mevcut route/state davranışını bozmuyor.

## Sidebar

- [ ] Sidebar daraltılabiliyor.
- [ ] Dar durumda ikonlar görünmeye devam ediyor.
- [ ] Mouse sidebar üzerine geldiğinde genişliyor.
- [ ] Menü isimleri geniş durumda görünüyor.
- [ ] Mouse dışarı çıktığında daralıyor.
- [ ] Aktif menü göstergesi korunuyor.
- [ ] Navigation davranışı değişmiyor.
- [ ] Mevcut responsive davranış bozulmuyor.

## Ana Sayfa

- [ ] "Hızlı Çalışma Alanları" bölümü kaldırıldı.
- [ ] Sidebar menüleri çalışmaya devam ediyor.
- [ ] Hızlı İşlemler korunuyor.
- [ ] Sınıflarım bölümü korunuyor.
- [ ] Diğer mevcut işlevler korunuyor.

## Ders Platformu

- [ ] Ünite açıldığında yalnızca o üniteye ait konular gösteriliyor.
- [ ] Seçilen konuya ait dokümanlar gösteriliyor.
- [ ] Farklı konuların dokümanları topluca gösterilmiyor.
- [ ] Konu değiştirildiğinde doküman listesi değişiyor.
- [ ] Dokümanlar yanlış konu altında görünmüyor.
- [ ] Mevcut doküman kayıtları korunuyor.
- [ ] Mevcut içerik sistemi çalışmaya devam ediyor.

## Genel

- [ ] Mevcut database korunuyor.
- [ ] Mevcut veriler korunuyor.
- [ ] Offline-first yapı korunuyor.
- [ ] Yeni dependency eklenmedi.
- [ ] Gereksiz refactor yapılmadı.
- [ ] Mevcut Design System korundu.
- [ ] İlgili analyzer/test kontrolleri başarılı.