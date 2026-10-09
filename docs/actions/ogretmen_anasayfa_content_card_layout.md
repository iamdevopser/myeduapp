# Öğretmen Anasayfa – Content Card Dashboard Layout

## Amaç

Öğretmen ana sayfasındaki aşağıdaki 5 bölümü alt alta göstermek yerine
Content Card tabanlı kompakt bir dashboard düzenine dönüştür:

1. Hızlı İşlemler
2. Sınıflarım
3. Kısa Analizler
4. Son İşlemler
5. Sınıf Defterim

Amaç, masaüstünde 5 bölümün tamamının mümkün olduğunca aynı anda
ekranda görülebilmesidir.

## Yerleşim

Desktop:
- 5 Content Card aynı satırda göster.
- Sıra kesinlikle:
  Hızlı İşlemler → Sınıflarım → Kısa Analizler → Son İşlemler → Sınıf Defterim
- Kartlar mevcut kullanılabilir genişliği paylaşmalı.
- Kartlar gereksiz şekilde tüm sayfa genişliğine yayılmamalı.
- Kart yükseklikleri mümkün olduğunca dengeli ve kompakt olmalı.
- Sayfanın başlangıcında bu 5 kartın tamamı görünür olacak şekilde tasarla.

Responsive:
- Geniş masaüstünde 5 kolon.
- Daha dar ekranlarda 5 kartı sıkıştırma.
- Tablet için uygun şekilde 2 veya 3 kolon.
- Mobilde 1 kolon.
- Mevcut responsive davranış bozulmamalı.

## Kart içerikleri

Mevcut 5 bölümün içeriklerini ve işlevlerini değiştirme.

Sadece mevcut bölümleri Content Card içine taşı ve kompaktlaştır.

### Hızlı İşlemler
Mevcut hızlı işlem butonları/aksiyonları korunacak.

### Sınıflarım
Mevcut sınıf listesi korunacak.
Sınıf + şube gösterimi ve mevcut sıralama korunacak.

### Kısa Analizler
Mevcut analiz metrikleri ve hesaplama servisleri korunacak.
Yeni hesaplama mantığı oluşturma.

### Son İşlemler
Mevcut son işlem kayıtları ve tıklanabilir deep-link davranışı korunacak.

### Sınıf Defterim
Mevcut sınıf seçimi, not listesi, ekleme/düzenleme/silme işlevleri korunacak.
Sınıf + şube gösterimi korunacak.

## Kart yüksekliği ve taşan içerik

Kartlar dashboard'un yüksekliğini gereksiz artırmamalı.

Bir kartın içeriği kartın görünür alanına sığmıyorsa:
- kart içinde sınırlı liste göster,
- mevcut işlevleri koruyarak uygun "Tümünü Gör" / devam et yaklaşımı kullan
veya
- kartın kendi içinde kontrollü scroll kullan.

Ana sayfanın tamamını aşağı doğru uzatan büyük listeler oluşturma.

## Tasarım

- Mevcut uygulamanın Content Card / Card tasarım dilini kullan.
- Yeni bir tasarım sistemi oluşturma.
- Mevcut renkler, typography, spacing ve border/radius yaklaşımı korunmalı.
- Kartlar görsel olarak aynı aileye ait olmalı.
- Başlıklar kısa ve okunabilir olmalı.
- Gereksiz boşlukları azalt.
- Kartların içindeki mevcut fonksiyonları kaldırma.

## Veri ve mimari

- Yeni veritabanı değişikliği yapma.
- Mevcut servisleri/API'leri kullan.
- Yeni business logic oluşturma.
- Mevcut `_loadSnapshot`, activity, notebook, class ve quick-action yapılarını yeniden kullan.
- Gereksiz refactor yapma.
- Yeni dependency ekleme.

## Kontrol

Değişiklikten sonra:

1. Desktop geniş ekranda 5 kartın aynı anda görünmesini kontrol et.
2. Kartların içeriklerinin kullanılabilir olduğunu kontrol et.
3. Sınıf + şube gösteriminin korunduğunu kontrol et.
4. Son İşlemler deep-linklerinin çalıştığını kontrol et.
5. Sınıf Defterim ekleme/düzenleme/silme işlevlerini kontrol et.
6. Tablet görünümünü kontrol et.
7. Mobil görünümü kontrol et.
8. `flutter test` çalıştır.
9. `flutter analyze` çalıştır.

Mevcut işlevlerde regresyon varsa düzelt.

İlgisiz kodlara dokunma.

## Durdurma

Bu görev yalnızca dashboard yerleşimini değiştirsin.
Yeni özellik ekleme.

İşlem sonunda:
- değişen dosyaları,
- yapılan UI değişikliklerini,
- test sonucunu,
- analyze sonucunu

raporla ve burada dur.