ACTION — RAPORLAR SAYFASI UI REDESIGN

Amaç

Mevcut MyEduApp Raporlar sayfasının görsel tasarımını referans görseldeki modele mümkün olduğunca %100 aynı olacak şekilde uygula.

Bu action yalnızca UI/UX ve layout içindir.

KRİTİK: Mevcut raporlama fonksiyonlarının, hesaplamaların, filtrelerin, PDF/Excel export işlemlerinin, SQLite veri yapısının, provider/state yönetiminin ve routing'in çalışma mantığını değiştirme.

project.mdc içindeki tüm kurallar aynen geçerlidir.

1. REFERANS TASARIM

Raporlar sayfası şu yapıya dönüştürülmeli:

Üst başlık: Raporlar

Alt açıklama: Bireysel / Sınıf raporlarını görüntüleyin ve analiz edin.

Sağ üstte: PDF Dışa Aktar ve Excel Dışa Aktar

Altında segmentli seçim:

Bireysel Rapor

Sınıf Raporu

Altında geniş, tek parça filtre paneli

Ardından öğrenci/sınıf özet alanı

Ardından kategori ortalama kartları

Ardından tek ve geniş ana rapor tablosu

Mevcut MyEduApp sidebar/navigation yapısı korunmalı.

2. RAPOR TÜRÜ SEÇİMİ

Bireysel Rapor ve Sınıf Raporu modern segmentli kontrol olarak gösterilmeli.

Seçili bölüm:

belirgin ana vurgu rengi

beyaz yazı

rounded görünüm

Diğer bölüm:

açık/beyaz arka plan

koyu metin

Mevcut seçim ve rapor oluşturma mantığı değiştirilmemeli.

3. FİLTRE PANELİ

Rapor türü seçiminin altında tek ve geniş bir filtre kartı oluştur.

Bireysel raporda mevcut filtreler görsel olarak şu düzende olmalı:

Öğrenci Seç

Tarih Aralığı

Ders

Sınıf

Şube

Sınıf raporunda mevcut filtreler aynı tasarım diliyle düzenlenmeli.

Filtrelerin veri kaynakları ve işlevleri değiştirilmemeli.

4. BİREYSEL ÖĞRENCİ ÖZET KARTI

Bireysel raporda filtrelerin altında geniş bir özet kartı oluştur.

Sol:

mevcut öğrenci ikonu/avatarı

Öğrenci adı

Sınıf / Şube

Sağ:

Rapor Tarihi

Ortalama Genel Başarı

Örnek:

Albu Sofia
7. Sınıf / A Şubesi

2026-08-11 - 2026-09-10
93.2 / 100

Değerler mevcut sistemden alınmalı.

5. KATEGORİ ORTALAMA KARTLARI — EN ÖNEMLİ BÖLÜM

Mevcut rapordaki kategorileri ayrı ayrı alt alta tablolar halinde gösterme.

Bütün puanlanabilir aktif kategoriler yatay olarak yan yana kartlar halinde gösterilmeli.

Örnek:

[Diyalog] [Kelime] [Okuma] [Yazma] [Dinleme] [Konuşma]
Ortalama   Ortalama  Ortalama  Ortalama  Ortalama  Ortalama
  95.0       90.5      92.8      88.7      96.3      93.6

Her kartta:

mevcut icon sistemi

kategori adı

Ortalama

ortalama puanı

bulunmalı.

Kategori sayısı sabit değildir. Mevcut dinamik kategori sistemindeki puanlanabilir kategoriler otomatik olarak gösterilmeli.

Örneğin:

Materyaller

Aktiviteler

Ödevler

Sınavlar

kullanıcı tarafından oluşturulmuş puanlanabilir kategoriler

rapora dahil olabilir.

Öğrenci Listesi gibi puanlanmayan sistem kategorileri ortalama kartına dahil edilmemeli.

Kategori sayısı arttığında responsive davranış korunmalı; gerekirse yatay kaydırma kullanılabilir.

6. ANA RAPOR TABLOSU

Kategori ortalama kartlarının altında tek bir ana tablo bulunmalı.

Kategoriler satır olarak değil, kolon olarak yan yana gösterilmeli.

Örnek:

Tarih | Diyalog | Kelime | Okuma | Yazma | Dinleme | Konuşma | Genel Ortalama
------|---------|--------|-------|-------|---------|---------|----------------
09-10 |   95    |   88   |  90   |  85   |   98    |   92    |      91.2
09-09 |  100    |   92   |  95   |  90   |   97    |   95    |      94.8
09-08 |   90    |   88   |  92   |  85   |   95    |   90    |      90.0

Yani kullanıcı bir bakışta:

hangi kategorilerin bulunduğunu,

her kategorinin ilgili tarihteki puanını,

genel ortalamayı

görebilmeli.

Kategori isimleri kesinlikle ayrı ayrı aşağıdaki gibi alt alta tablolar oluşturmamalı.

7. KATEGORİ ORTALAMASI HESAPLAMA

Seçilen tarih aralığındaki mevcut puanlar kullanılarak her kategori için ortalama gösterilmeli.

Mevcut hesaplama mantığını değiştirme.

Projede mevcut kategori ağırlığı/not hesaplama sistemi varsa aynen kullan.

Eksik verileri mevcut sistem nasıl ele alıyorsa aynı davranışı koru.

Yeni puanlama formülü icat etme.

8. GENEL ORTALAMA

Genel ortalama üst öğrenci özet kartında belirgin şekilde gösterilmeli.

Örnek:

93.2 / 100

Bu değer mevcut uygulamadaki gerçek hesaplama sonucundan alınmalı.

Hesaplama algoritmasını değiştirme.

9. SINIF RAPORU

Sınıf Raporu seçildiğinde aynı tasarım dili kullanılmalı.

Öğrenciler satırlar halinde, kategoriler kolonlar halinde gösterilmeli.

Örnek:

Öğrenci | Diyalog | Kelime | Okuma | Yazma | Dinleme | Konuşma | Genel Ortalama
Albu      95        90       93      89      96        94          93.2
Borş      88        91       90      85      92        90          89.3
Bot       92        87       95      90      94        91          91.5

Kolonlar mevcut aktif/puanlanabilir kategorilere göre dinamik oluşturulmalı.

10. GÖRSEL TASARIM DİLİ

Mevcut MyEduApp Design System kullanılmalı.

Referans görünüm:

açık gri/açık arka plan

beyaz kartlar

koyu lacivert metin

mevcut mavi ana vurgu rengi

hafif border

rounded corners

temiz ve dengeli spacing

modern dashboard görünümü

gereksiz çizgi/bölücü azaltılmış

bilgi yoğun ama sade

Mevcut sidebar, ikonlar, navigation ve hover/collapse davranışları bu action kapsamında değiştirilmemeli.

11. RESPONSIVE / TABLET / TELEFON

Mevcut responsive/tablet altyapısını kullan.

Yeni responsive architecture oluşturma.

Desktop

geniş filtre paneli

kategori kartları mümkün olduğunca tek satır

geniş tablo

Tablet

kategori kartları gerektiğinde 2–3 kolon

filtreler gerektiğinde iki satır

tablo yatay kaydırılabilir

Telefon

filtreler dikey

kategori kartları 1 veya 2 kolon

tablo yatay kaydırılabilir

sağa/sola taşan ana sayfa layout'u olmamalı

Overflow hatası oluşmamalı.

12. KESİNLİKLE KORUNACAK FONKSİYONLAR

Aşağıdakilerin çalışma mantığını değiştirme:

Bireysel rapor

Sınıf raporu

Öğrenci seçimi

Sınıf seçimi

Kategori seçimi

Tarih başlangıç/bitiş

Kategori ortalamaları

Genel ortalama

Aylık performans

PDF dışa aktarma

Excel dışa aktarma

Mevcut filtreler

SQLite veri okuma

Provider/state management

Navigation

Sadece görsel yapı ve gerekli layout değiştirilmeli.

13. VERİ / MİMARİ KURALLARI

Database schema değiştirme.

Migration oluşturma.

Yeni repository oluşturma.

Yeni service oluşturma.

Yeni model oluşturma.

Yeni dependency ekleme.

Mevcut hesaplama mantığını yeniden yazma.

Duplicate raporlama mantığı oluşturma.

Aynı veriyi ikinci yapıda saklama.

Gereksiz refactor yapma.

Mevcut veri akışını kullan.

14. UYGULAMA SIRASI

Önce mevcut Raporlar ekranını analiz et.

Yalnızca gerekli dosyaları tespit et:

rapor ekranı

bireysel rapor

sınıf raporu

kategori verileri

puan hesaplama

aylık performans

PDF export

Excel export

responsive yapı

Sonra mevcut componentleri mümkün olduğunca yeniden kullanarak UI'ı referans tasarıma dönüştür.

Aynı işi yapan mevcut component varsa onu kullan.

15. KABUL KRİTERLERİ

Raporlar sayfası referans tasarıma çok yakın/birebir uygulanmış.

Bireysel Rapor / Sınıf Raporu segmentli yapı.

Filtreler tek geniş panelde.

Bireysel öğrenci özet kartı var.

Genel başarı belirgin.

Tüm puanlanabilir kategoriler yan yana ortalama kartlarında.

Her kategorinin ortalaması kendi kartında.

Ana tabloda kategoriler yan yana kolonlarda.

Tarihler satırlarda.

Genel Ortalama son kolon.

Sınıf raporu aynı kategori-kolon modelini kullanıyor.

Dinamik kategoriler destekleniyor.

Puanlanmayan sistem kategorileri ortalamaya yanlışlıkla dahil edilmiyor.

PDF export çalışıyor.

Excel export çalışıyor.

Mevcut hesaplama sonuçları değişmiyor.

Database/veri modeli değişmiyor.

Desktop düzgün.

Tablet düzgün.

Telefon düzgün.

Overflow oluşmuyor.

Mevcut navigation/sidebar bozulmuyor.

Yeni dependency eklenmiyor.

Gereksiz refactor yapılmıyor.

SON KURAL

Bu görev bir Raporlar UI redesign görevidir.

Mevcut çalışan sistem > mevcut veri > mevcut hesaplama mantığı > mevcut architecture > yeni UI tasarımı

UI'ı değiştir; çalışan sistemi değiştirme.

İşlem sonunda kısa olarak:

Değiştirilen dosyaları,

Yapılan UI değişikliklerini,

Test/analyzer sonuçlarını,

Mevcut fonksiyonların korunma durumunu

raporla.