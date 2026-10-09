# Sınıf Şube ve Navbar Alt Menü Sıralaması

## Amaç

İki UI sorununu minimum kod değişikliğiyle düzelt:

1. Sınıf Defterim sınıf seçiminde şubeleri göster ve doğru sırala.
2. Navbar ana menüleri değiştirmeden alt menülerin sıralamasını düzelt.

## Genel kurallar

- Mevcut mimariyi koru.
- Offline-first yapıyı bozma.
- Yeni veritabanı tablosu/kolonu oluşturma.
- Mevcut sınıf/şube verisini kullan.
- Mevcut navbar ana menü sırasını değiştirme.
- Gereksiz refactor yapma.
- Aynı sıralama mantığı zaten mevcutsa onu yeniden kullan.
- Yeni dependency ekleme.
- Önce mevcut kodu analiz et, sonra minimum değişiklik yap.
- İlgisiz dosyalara dokunma.

## 1. Sınıf Defterim – Şube gösterimi

Mevcut Sınıf Defterim > Sınıf Seç dropdown/listesini analiz et.

Şu anda yalnızca sınıf seviyesi gösteriliyorsa sınıfın mevcut şube/section bilgisini de göster.

Örnek hedef görünüm:

7. Sınıf A
7. Sınıf B
7. Sınıf C
8. Sınıf A
8. Sınıf B
8. Sınıf C
9. Sınıf A
9. Sınıf B
9. Sınıf C

Gerçek veritabanındaki mevcut şube değerlerini kullan.

Sıralama:
1. Sınıf seviyesi küçükten büyüğe.
2. Aynı sınıf seviyesinde şube A, B, C... şeklinde.
3. Şube değeri olmayan kayıt varsa kaydı kaybetme; mevcut davranışı koruyarak uygun şekilde listenin sonunda göster.

Gösterilen label mevcut sınıf/şube bilgisini temsil etmeli. Veritabanı modelini değiştirme.

Başka ekranlarda kullanılan sınıf sıralamasını gereksiz yere değiştirme.

## 2. Navbar – Alt menü sıralaması

Mevcut navbar ana menülerinin sırasını değiştirme.

Alt menülerin nereden üretildiğini ve hangi veri/model/listeden geldiğini analiz et.

Alt menüler için stabil ve tutarlı bir sıra uygula.

Öncelik:
- Uygulamada zaten tanımlı bir sıra/index/order varsa onu kullan.
- Yoksa mevcut ürün hiyerarşisine uygun açık ve deterministik bir sıra oluştur.
- Aynı alt menü listesi birden fazla yerde oluşturuluyorsa mümkünse ortak mevcut yapıyı kullan.
- Her rebuild/reload sonrasında sıra değişmemeli.
- Map/Set/DB dönüş sırasına tesadüfen bağlı olma.

Özellikle Ders Platformu alt menülerinin birbirine karışmadığını doğrula.

Ana menü sırası aynen korunmalı.

## Test

Değişikliklerden sonra:

- Sınıf Defterim dropdown/listesinde gerçek sınıf + şube değerlerinin doğru göründüğünü test et.
- En az 7, 8 ve 9. sınıf örnekleriyle sınıf → şube sırasını doğrula.
- Navbar ana menü sırasının değişmediğini doğrula.
- Alt menülerin deterministik ve beklenen sırada olduğunu doğrula.
- Mevcut ilgili testleri çalıştır.
- `flutter analyze` ilgili değişen dosyalarda temiz olmalı.
- Tam `flutter test` çalıştır.

Yeni bir sorun veya veri modeli problemi ortaya çıkarsa üretim kodunu genişletmeden önce dur ve raporla.

## Rapor

Sonunda:
- Yapılan değişiklikler
- Değişen dosyalar
- Sıralama mantığı
- Test sonuçları
- Analyze sonucu
- Varsa sorunlar

raporla ve sonraki faza otomatik geçme.