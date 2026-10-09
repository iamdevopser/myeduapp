# ACTION — MYEDUAPP ÖĞRENCİ PLATFORMU GELİŞTİRME VE DÜZELTMELER

Bu action yalnızca Öğrenci Platformundaki aşağıdaki geliştirme ve düzeltmeleri kapsar.

project.mdc içindeki tüm proje kuralları bu action için geçerlidir.

Mevcut çalışan sistemi, database yapısını, modelleri, repository/service yapısını,
provider/state management yapısını, routing'i ve mevcut Design System'i koru.

Önce mevcut implementasyonu analiz et.
Aynı işlevi yapan yeni yapı oluşturma.
Mevcut yapıyı mümkün olduğunca yeniden kullan.
Minimum değişiklikle uygula.

---

# 1. SINIFLARIN AÇILIR / KAPANIR YAPILMASI

Öğrenci Platformunun sol panelindeki sınıflar expandable/collapsible
(accordion) yapıda olmalı.

Her sınıf bir başlık olarak gösterilmeli.

Örnek:

▼ 7. Sınıf
   2026–27 / A

   Öğrenci Listesi
   Materyaller
   Aktiviteler
   Ödevler
   Sınavlar
   + Kategori Ekle

▶ 7. Sınıf
   2026–27 / B

Sınıf başlığına tıklandığında:

- Açık ise kapanmalı.
- Kapalı ise açılmalı.

Birden fazla sınıf aynı anda açık kalabilmeli.
Bir sınıf açıldığında diğer sınıfları zorunlu olarak kapatma.

Sınıfın mevcut:

- düzenle
- ayarlar
- sil

işlevleri korunmalı.

Sınıfların açılıp kapanma durumu mümkün olduğunca mevcut UI/state yapısı
kullanılarak yönetilmeli.

Gereksiz yeni state management yapısı oluşturma.

---

# 2. SINIF SIRALAMASI

Sınıflar her zaman aşağıdaki kurala göre sıralanmalı:

1. Sınıf numarası küçükten büyüğe.
2. Aynı sınıf numarası içindeki şubeler A'dan H'ye.

Örnek:

4A
4B
4C
4D
5A
5B
7A
7B
7F
8A
10A
11B
12A

Özellikle:

- 4B, 5B'den önce gelmeli.
- 7A, 7F'den önce gelmeli.
- 7F, 8A'dan önce gelmeli.
- 9A, 10A'dan önce gelmeli.
- 10A, 11A'dan önce gelmeli.

Alfabetik string sıralaması kullanma.

Örneğin "10. Sınıf" ile "2. Sınıf" karşılaştırılırken
string sıralaması nedeniyle yanlış sonuç oluşmamalı.

Sınıfların database'e eklenme sırası liste sırasını değiştirmemeli.

Mevcut sınıf kayıtlarını değiştirme veya yeniden oluşturma.
Yalnızca listeleme sıralamasını düzelt.

---

# 3. SABİT KATEGORİ SIRASI

Öğrenci Platformundaki sistem kategorileri her zaman aşağıdaki sırada
gösterilmeli:

1. Öğrenci Listesi
2. Materyaller
3. Aktiviteler
4. Ödevler
5. Sınavlar

Bu sıra kullanıcı tarafından değiştirilememeli.

Bu beş kategori sistem kategorisi olarak korunmalı.

Özellikle:

- Öğrenci Listesi 1. sırada kalmalı.
- Materyaller her zaman Öğrenci Listesinin hemen altında bulunmalı.
- Aktiviteler her zaman Materyallerden sonra bulunmalı.
- Ödevler her zaman Aktivitelerden sonra bulunmalı.
- Sınavlar her zaman Ödevlerden sonra bulunmalı.

Kullanıcının oluşturduğu yeni kategoriler bu beş sabit kategorinin
altında gösterilmeli.

Örneğin:

Öğrenci Listesi
Materyaller
Aktiviteler
Ödevler
Sınavlar
Katılım
Derse Hazırlık
Konuşma

Yeni kategoriler kendi aralarında mevcut kategori yönetim sistemindeki
sıralama mantığıyla yönetilebilir.

Ancak hiçbir kullanıcı kategorisi sistem kategorilerinin üzerine
çıkamamalı.

---

# 4. MATERYALLER KATEGORİSİ

"Materyaller" adlı yeni sistem kategorisini oluştur.

Materyaller:

- Öğrenci Listesinin hemen altında bulunmalı.
- Sistem kategorisi olmalı.
- Silinememeli.
- Sistem kategorilerinin sırası gibi sabit konumda bulunmalı.
- Kategori yönetim ekranında sistem kategorisi olarak gösterilmeli.

Mevcut Öğrenci Listesi, Aktiviteler, Ödevler ve Sınavlar işlevlerini bozma.

Materyaller de diğer öğrenci takip kategorileri gibi tarih bazlı çalışmalı
ve mevcut puan/not giriş sistemiyle uyumlu olmalı.

---

# 5. KATEGORİLERDE TARİH BAZLI KAYIT

Öğrenci Platformundaki veri girişleri tarih bazlı çalışmaya devam etmeli.

Özellikle:

- Materyaller
- Aktiviteler
- Ödevler
- Sınavlar
- Kullanıcı tarafından oluşturulan diğer takip kategorileri

seçilen tarihe göre kayıt tutmalı.

Tarih varsayılan olarak bugün olabilir.

Kullanıcı önceki/sonraki günlere geçebilmeli.

Aynı:

Öğrenci + Kategori + Tarih

için duplicate kayıt oluşturulmamalı.

Mevcut kayıt UPDATE edilmeli.

---

# 6. TÜM ÖĞRENCİLERİN GÖSTERİLMESİ

Öğrenci Listesinde örneğin 26 öğrenci bulunuyorsa,
diğer takip kategorilerinde de sınıftaki TÜM öğrenciler gösterilmeli.

Bir kategoride yalnızca ilk 12 öğrencinin görünmesi gibi bir problem olmamalı.

Öğrenci sayısı sabit 12 kabul edilmemeli.

Sınıfta:

1 öğrenci
10 öğrenci
26 öğrenci
veya mevcut sistemin desteklediği daha fazla öğrenci

bulunması halinde tüm öğrenciler gösterilmeli.

Liste scroll edilebilir olmalı.

Mevcut öğrenci sıralaması korunmalı.

---

# 7. KATEGORİ KOLONLARINDA AÇIKLAMA

Kategori yönetiminde yeni bir kolon/kategori oluşturulurken
kategori adı yanında açıklama girilebiliyor.

Bu açıklama database/model içinde saklanmalı ve ekranda da gösterilmeli.

Şu anda açıklama girildiği halde ilgili kategori ekranında görünmüyorsa
bu problemi düzelt.

Önemli:

Açıklama alanını kategori oluşturma/düzenleme panelinden kaldırma.

Açıklama, kategori tanımının bir parçası olarak kalmalı.

Kategori ekranında kolon başlığında mümkün olduğunca şu yapı kullanılmalı:

Kategori Adı
Açıklama

Örneğin:

Materyaller
Kitabını ve gerekli ders materyallerini getirme durumu

Aktiviteler
Ders içi aktivitelere katılım

Başlık alanı dar ise mevcut Design System'e uygun şekilde
açıklama ikinci satırda daha küçük metin olarak gösterilebilir.

Responsive alanda açıklama tamamen kaybolmamalı.

Gerekirse mevcut tooltip/overflow çözümü kullanılabilir.

Ancak açıklamanın kullanıcı tarafından erişilebilir olması zorunlu.

Yeni bir açıklama gösterim sistemi oluşturmak yerine
mevcut UI component yapısını mümkün olduğunca kullan.

---

# 8. AUTOSAVE

Kategori ekranlarında yapılan puan/değer/not değişiklikleri
otomatik kaydedilmeli.

Ayrı bir Kaydet butonuna ihtiyaç olmamalı.

Değer değiştiğinde:

- Yeni kayıt → INSERT
- Mevcut kayıt → UPDATE

yapılmalı.

Sayfa değiştirildiğinde veya uygulama kapatıldığında
kaydedilmiş veriler kaybolmamalı.

Duplicate kayıt oluşturulmamalı.

---

# 9. AYLIK GENEL NOT ORTALAMASI

Öğrenci performansı her ay için ayrı değerlendirilmeli.

Her öğrencinin aylık kategori ortalamaları hesaplanmalı.

Örneğin Eylül 2026:

Materyaller → 8.5
Aktiviteler → 9.0
Ödevler → 8.0
Sınavlar → 7.5

Aylık Genel Ortalama:

8.25 / 10

şeklinde hesaplanmalı.

Önemli:

O ay içerisinde hiç veri bulunmayan kategori genel ortalamaya
0 olarak dahil edilmemeli.

Örneğin:

Materyaller → 8.5
Aktiviteler → 9.0
Ödevler → 8.0
Sınavlar → veri yok

Genel Ortalama:

(8.5 + 9.0 + 8.0) / 3 = 8.50

olmalı.

Mevcut projede kategori ağırlıkları veya mevcut bir notlandırma
formülü bulunuyorsa önce onu analiz et ve mevcut iş mantığını bozma.

Mevcut ağırlıklı notlandırma sistemi aylık genel not için zaten
tanımlanmışsa aynen kullan.

Aylık hesaplama için mevcut sistemde bir ağırlık bulunmuyorsa
yalnızca veri bulunan kategorilerin aylık ortalamasını eşit ağırlıkla
hesapla.

Yeni bir alternatif notlandırma sistemi oluşturma.

---

# 10. AYLIK NOTLARIN SAKLANMASI

Aylık genel ortalama hesaplanırken mevcut günlük kayıtların
üzerine yazılmamalı.

Günlük kayıtlar korunmalı.

Aylık özet gerektiğinde mevcut günlük kayıtlardan hesaplanabilir.

Gereksiz yeni database tablosu oluşturma.

Mevcut veri modelinde aylık özet saklanması için uygun alan/yapı
zaten varsa onu kullan.

Yeni bir tablo gerçekten zorunlu değilse oluşturma.

---

# 11. AYLIK PERFORMANS GÖRÜNTÜLEME

Öğrenci performans/rapor ekranında mümkün olduğunca aylık
performans geçmişi gösterilebilmeli.

Örneğin:

Eylül 2026    8.25
Ekim 2026     8.60
Kasım 2026    8.40
Aralık 2026   9.00

Aylık değerler 1–10 sistemiyle uyumlu olmalı.

Mevcut rapor/grafik componenti varsa onu kullan.

Yeni grafik kütüphanesi veya dependency ekleme.

---

# 12. PDF VE EXCEL RAPORLARI

Mevcut bireysel ve toplu PDF/Excel rapor sistemini bozma.

Aylık genel ortalama mevcut rapor yapısına uygun şekilde
raporlara eklenebilecek durumdaysa ekle.

Bireysel raporda mümkünse:

Öğrenci
Sınıf
Dönem/Tarih Aralığı
Kategori
Kategori Ortalaması
Aylık Genel Ortalama

bilgileri desteklenmeli.

Toplu raporda mümkünse:

Öğrenci
Kategori
Kategori Ortalaması
Aylık Genel Ortalama

bilgileri desteklenmeli.

Mevcut PDF/Excel implementasyonlarını yeniden oluşturma.

---

# 13. KATEGORİ YÖNETİMİ

Kategori Yönet ekranında:

Sistem kategorileri:

Öğrenci Listesi
Materyaller
Aktiviteler
Ödevler
Sınavlar

şeklinde sabit sırada bulunmalı.

Sistem kategorileri:

- Silinememeli.
- Sabit sıraları değiştirilememeli.
- Gerekli ise düzenleme yalnızca desteklenen alanlarla sınırlı olmalı.

Kullanıcı kategorileri:

- Eklenebilmeli.
- Düzenlenebilmeli.
- Silinebilmeli.
- Sıralanabilmeli.

Kullanıcının oluşturduğu kategoriler sistem kategorilerinin arasına
girememeli.

Mevcut kategori yönetim ekranının tasarımını mümkün olduğunca koru.

---

# 14. VERİ GÜVENLİĞİ VE BACKWARD COMPATIBILITY

Mevcut:

- Sınıflar
- Öğrenciler
- Kategoriler
- Günlük kayıtlar
- Notlar
- Açıklamalar

korunmalı.

Mevcut verileri silme.

Destructive migration yapma.

Yeni alan gerekiyorsa backward compatibility korunmalı.

Eski kayıtların yeni sistemde okunabilmesini sağla.

Mevcut öğrenci-sınıf ilişkilerini bozma.

---

# 15. UYGULAMA SIRASI

Önce yalnızca ilgili mevcut implementasyonları analiz et:

1. Öğrenci Platformu ana ekranı
2. Sınıf listesi
3. Sınıf oluşturma
4. Öğrenci listesi
5. Kategori yönetimi
6. Kategori veri giriş ekranları
7. Kategori/kolon modeli
8. Açıklama alanının database/model/repository akışı
9. Not/değer kayıt sistemi
10. Tarih sistemi
11. Autosave
12. Mevcut raporlama
13. Mevcut PDF/Excel sistemi
14. Database modelleri ve migration yapısı

Daha sonra yalnızca gerekli dosyaları değiştir.

Öncelik:

A. Sınıfların açılır/kapanır yapısı
B. Sınıf sıralaması
C. Sabit kategori sırası
D. Materyaller kategorisi
E. Tüm öğrencilerin kategori ekranlarında gösterilmesi
F. Kategori açıklamalarının ekranda gösterilmesi
G. Autosave/tarih kontrolü
H. Aylık genel ortalama
I. Mevcut raporlama ile entegrasyon
J. Validation

---

# 16. KABUL KRİTERLERİ

## Sınıflar

- [ ] Sınıflar açılıp kapanabiliyor.
- [ ] Birden fazla sınıf açık kalabiliyor.
- [ ] Sınıf numaraları küçükten büyüğe sıralanıyor.
- [ ] Aynı sınıftaki şubeler A'dan H'ye sıralanıyor.
- [ ] 4B, 5B'den önce geliyor.
- [ ] 7A, 7F'den önce geliyor.
- [ ] 9A, 10A'dan önce geliyor.

## Kategoriler

- [ ] Öğrenci Listesi 1. sırada.
- [ ] Materyaller 2. sırada.
- [ ] Aktiviteler 3. sırada.
- [ ] Ödevler 4. sırada.
- [ ] Sınavlar 5. sırada.
- [ ] Bu beş kategori sabit.
- [ ] Kullanıcı kategorileri bu beş kategorinin altında.
- [ ] Materyaller silinemiyor.

## Öğrenciler

- [ ] Öğrenci Listesinde bulunan tüm öğrenciler diğer kategorilerde de gösteriliyor.
- [ ] Liste 12 öğrenci ile sınırlandırılmıyor.
- [ ] 26 öğrencinin tamamı gösterilebiliyor.
- [ ] Scroll düzgün çalışıyor.

## Açıklamalar

- [ ] Yeni kategori/kolon oluştururken açıklama girilebiliyor.
- [ ] Açıklama database/model içinde korunuyor.
- [ ] Açıklama kategori ekranında görünür.
- [ ] Açıklama dar alanlarda kaybolmuyor.
- [ ] Mevcut Design System kullanılıyor.

## Tarih ve Autosave

- [ ] Kategoriler tarih bazlı çalışıyor.
- [ ] Önceki/sonraki gün çalışıyor.
- [ ] Değerler otomatik kaydediliyor.
- [ ] Duplicate kayıt oluşmuyor.
- [ ] Uygulama/sayfa değişiminde kayıt kaybolmuyor.

## Aylık Not

- [ ] Her öğrencinin aylık kategori ortalaması hesaplanabiliyor.
- [ ] Aylık genel ortalama hesaplanabiliyor.
- [ ] Veri olmayan kategoriler 0 kabul edilmiyor.
- [ ] Mevcut notlandırma/ağırlık sistemi varsa korunuyor.
- [ ] Genel ortalama 1–10 sistemiyle uyumlu.
- [ ] Aylık geçmiş görüntülenebiliyor.

## Genel

- [ ] Mevcut database korunuyor.
- [ ] Mevcut öğrenciler korunuyor.
- [ ] Mevcut sınıflar korunuyor.
- [ ] Mevcut notlar korunuyor.
- [ ] Mevcut kategoriler korunuyor.
- [ ] Offline-first yapı korunuyor.
- [ ] Mevcut Design System korunuyor.
- [ ] Yeni dependency eklenmiyor.
- [ ] Gereksiz refactor yapılmıyor.
- [ ] Mevcut çalışan özellikler bozulmuyor.