# MyEduApp — Akademik Planlar ve Öğrenci Platformu Geliştirme Promptu

## AMAÇ

MyEduApp Flutter uygulamasında aşağıdaki iki ana geliştirmeyi mevcut mimariyi bozmadan analiz et, tasarla, uygula ve test et:

1. `Akademik Planlar > Haftalık Ders Planı` sayfasına dikey (up/down) scroll desteği eklemek.
2. `Öğrenci Platformu > Sınıflar` içerisindeki mevcut öğrenci değerlendirme yapısına:
   - `a` = devamsızlık durumunu eklemek,
   - sabit bir `Davranışlar` kategorisi eklemek,
   - Davranışlar ekranını Excel benzeri, yatay/dikey scroll destekli ve öğrenci kolonu sabit (sticky) bir tablo olarak oluşturmak,
   - davranış kayıtlarını kalıcı olarak saklamak,
   - kayıtları raporlarda metinsel olarak gösterebilmek.

ÖNEMLİ: Kodlamaya başlamadan önce projeyi ve mevcut veri akışını mutlaka analiz et. Var olan mimari, state management, repository/service yapısı, modeller, database/API katmanı, routing ve UI bileşenlerini mümkün olduğunca yeniden kullan. Gereksiz yeni mimari oluşturma.

---

# 1. İLK AŞAMA — MEVCUT UYGULAMAYI ANALİZ ET

Önce aşağıdaki konuları kodu inceleyerek tespit et:

### Haftalık Ders Planı
- `Akademik Planlar`
- `Haftalık Ders Planı`
- mevcut tablo/grid widget'ı
- responsive yapı
- mevcut scroll davranışı
- web / tablet / mobil ayrımları

### Öğrenci Platformu
- sınıf oluşturma ve sınıf listeleme yapısı
- sınıf detay ekranı
- öğrenci listesi
- Performans
- Ödev
- Sınav
- mevcut not giriş sistemi
- 1–10 notlarının nerede tutulduğu
- `__` değerinin nasıl temsil edildiği
- öğrenci + tarih + ders ilişkisi
- mevcut raporlama yapısı
- mevcut database/API/service/repository katmanı

Özellikle şu soruların cevabını kod üzerinden bul:

1. Notlar hangi model/entity içerisinde tutuluyor?
2. Öğrenci değerlendirmeleri hangi ekran ve servislerden geçiyor?
3. `__` değeri gerçek bir veri olarak mı tutuluyor, yoksa UI'da mı gösteriliyor?
4. Yeni `a` değeri mevcut yapıya nasıl en az riskle eklenebilir?
5. Davranış kayıtları için mevcut veri modelinden yararlanılabilecek bir yapı var mı?
6. Tarih bilgisi mevcut değerlendirme sisteminde nasıl tutuluyor?
7. Rapor ekranları mevcut değerlendirme verilerini nereden okuyor?
8. Web ve mobil/tablet için mevcut responsive tablo yaklaşımı nedir?

Analiz sonucunda kısa bir teknik değerlendirme oluştur ve ardından uygulamaya geç.

---

# 2. HAFTALIK DERS PLANI — DİKEY SCROLL

`Akademik Planlar > Haftalık Ders Planı` ekranında tablo öğrencinin/öğretmenin ekranına sığmadığında dikey olarak yukarı-aşağı kaydırılabilmeli.

Kurallar:

- Mevcut 8×6 tablo mantığını bozma.
- Üst satırdaki gün isimleri korunmalı.
- Sol taraftaki ders saatleri korunmalı.
- Mevcut sınıf isimleri (`7A`, `8D`, `9B` vb.) korunmalı.
- Dikey scroll desteklenmeli.
- Eğer mevcut yapı zaten yatay scroll içeriyorsa onu bozma.
- Web, tablet ve mobil ekranlarda taşma/overflow hatalarını düzelt.
- Mümkünse header ve saat kolonunun okunabilirliğini koruyacak responsive/sticky yapı kullan.
- Flutter'ın uygun scroll controller / SingleChildScrollView / CustomScrollView / iki eksenli scroll yaklaşımını mevcut mimariye göre seç.

Amaç:
Kullanıcı haftalık ders programını küçük ekranlarda da rahatça yukarı-aşağı inceleyebilsin.

---

# 3. MEVCUT NOT SİSTEMİNE `a` DEVAMSIZLIK DURUMU EKLE

Öğrenci Platformu içerisindeki mevcut:

- Öğrenci Listesi
- Performans
- Ödev
- Sınav

değerlendirme kategorilerinde şu yapı mevcut:

- `1`–`10` = not
- `__` = not verilmedi

Buna ek olarak:

- `a` = öğrenci o gün derse gelmedi / devamsız

durumu eklenecek.

## Kurallar

- `a` değerini `__` ile karıştırma.
- `__` = değerlendirme/not girilmemiş.
- `a` = öğrenci o gün derste yoktu.
- Mevcut 1–10 notları çalışmaya devam etmeli.
- Eski kayıtların anlamı değişmemeli.
- UI'da kullanıcı için açık ve anlaşılır şekilde göster.
- Veri modelinde mümkünse string ile her şeyi karıştırmak yerine mevcut mimariye uygun typed enum/status yapısı tercih et.
- Ancak mevcut backend/database yapısı string tabanlıysa gereksiz migration oluşturmadan güvenli bir çözüm uygula.
- `a` değeri raporlarda da doğru şekilde yorumlanmalı.
- Mevcut not hesaplama/ortalama mantığını bozma. Devamsızlık `a`, not olarak ortalamaya dahil edilmemeli.
- `__` de not olmadığı için mevcut hesaplama mantığı korunmalı.

Öncelik:
Mevcut veriler geriye dönük uyumlu kalmalı.

---

# 4. YENİ SABİT KATEGORİ — DAVRANIŞLAR

Her oluşturulmuş sınıfın değerlendirme/kategori yapısına sabit:

`Davranışlar`

kategorisini ekle.

Bu kategori normal 1–10 not sistemi gibi çalışmayacak.

Davranışlar:
- puan değildir,
- not değildir,
- checkbox tabanlı olay/kayıt sistemidir.

`Davranışlar` her sınıf için erişilebilir olmalı.

---

# 5. DAVRANIŞLAR EKRANI — EXCEL BENZERİ TABLO

Kullanıcı `Davranışlar` kategorisine tıkladığında Excel benzeri bir tablo açılmalı.

Temel yapı:

- 1. kolon = Öğrenci
- 2. kolon ve sonrası = davranış kolonları
- her öğrenci + davranış kesişiminde checkbox
- checkbox işaretlenirse o davranışın öğrencide gerçekleştiği kaydedilmeli
- tekrar tıklanırsa kayıt kaldırılmalı

Örnek:

| Öğrenci | Aktif Katılım | İş Birliği | Saygılı İletişim | Kurallara Uyma | Derste Konuşma |
|---|---|---|---|---|---|
| Ahmet Yılmaz | ☑ | ☐ | ☑ | ☐ | ☐ |
| Mehmet Kaya | ☐ | ☑ | ☐ | ☑ | ☑ |

---

# 6. EN ÖNEMLİ UI KURALI — ÖĞRENCİ KOLONU SABİT

Tablonun 1. kolonu olan `Öğrenci` kolonu sticky/fixed olmalı.

Kullanıcı tabloyu sağa/sola kaydırdığında:

- davranış kolonları yatay olarak hareket etmeli,
- öğrenci isimlerinin bulunduğu kolon sabit kalmalı.

Örneğin kullanıcı sağa kaydırdığında:

`Öğrenci | Aktif Katılım | İş Birliği`

yerine:

`Öğrenci | Dersi Bölme | Dikkat Dağıtma | Ödevini Yapmama`

gibi sonraki kolonlar görünmeli.

Ancak `Öğrenci` kolonu her zaman görünür kalmalı.

Bu özellik özellikle mobil ve tablet ekranlarda kritik.

---

# 7. İKİ EKSENLİ SCROLL

Davranışlar tablosu:

- dikey scroll: öğrenci listesi için
- yatay scroll: davranış kolonları için

desteklemeli.

Öğrenci sayısı arttığında yukarı-aşağı,
davranış sayısı arttığında sağa-sola kaydırılabilmeli.

Mümkünse:

- davranış başlıkları üstte sticky,
- öğrenci isimleri solda sticky,
- sol-üst köşe hücresi (`Öğrenci`) sticky

olacak şekilde Excel benzeri yapı oluştur.

Flutter'ın mevcut mimarisine en uygun çözümü seç.

---

# 8. RESPONSIVE TASARIM

Tabloyu tüm kolonları zorla ekran genişliğine sıkıştıracak şekilde tasarlama.

Öncelik:

1. Öğrenci kolonunun okunabilirliği
2. Davranış kolonlarının kullanılabilir genişlikte olması
3. Yatay scroll
4. Öğrenci kolonunun sticky kalması

Davranış isimleri çok uzunsa:
- başlık iki satıra bölünebilir,
- uygun text overflow kullanılabilir,
- tooltip/long press ile tam isim gösterilebilir.

Ancak checkbox hücreleri çok küçük hale gelmemeli.

Web, tablet ve mobil cihazlarda:
- overflow hatası olmamalı,
- RenderFlex overflow olmamalı,
- tablo ekranı kullanılabilir kalmalı.

---

# 9. İLK DAVRANIŞ LİSTESİ

Başlangıçta aşağıdaki 12 davranışı kullan:

## Olumlu davranışlar

1. Aktif katılım
2. Sorumluluk alma
3. İş birliği
4. Arkadaşına yardımcı olma
5. Saygılı iletişim
6. Kurallara uyma

## Geliştirilmesi gereken davranışlar

7. Derste konuşma
8. Dersi bölme
9. Geç kalma
10. Dikkat dağıtma
11. Ödevini yapmama
12. Kurallara uymama

Bu listeyi kod içinde ekran widget'ına hard-code etmek yerine mümkünse davranış modeli/config yapısı üzerinden tanımla.

Davranışların ayrıca bir `type/category` alanı olması tercih edilir:

- `positive`
- `needs_improvement`

Ancak mevcut mimari farklıysa buna uygun çözüm seç.

---

# 10. DAVRANIŞ KAYITLARININ VERİ MODELİ

Checkbox'ın sadece UI state olarak kalmasına izin verme.

Her işaretleme kalıcı olarak kaydedilmeli.

En azından aşağıdaki mantıksal bilgiler tutulmalı:

- classId
- studentId
- behaviorId
- date
- lesson/session bilgisi mevcut sistemde varsa ilgili ID
- createdAt / updatedAt gerekiyorsa
- öğretmen/user bilgisi mevcut sistemde tutuluyorsa ilgili kullanıcı ID'si

Mantıksal kayıt:

`student + class + behavior + date (+ lesson/session)`

ilişkisine dayanmalı.

Aynı davranışın farklı günlerde tekrar kaydedilebilmesi gerekir.

Örneğin:

- 1 Ekim → Ahmet → Aktif Katılım
- 2 Ekim → Ahmet → Aktif Katılım
- 3 Ekim → Ahmet → Aktif Katılım

üç ayrı tarihsel kayıt olabilmeli.

Aynı gün aynı davranışın iki kez kaydedilmesini engelle.

Bu nedenle uygun bir unique/idempotency mantığı uygula.

---

# 11. TARİH / GÜN SEÇİMİ

Davranışlar ekranında davranışların hangi güne ait olduğu kesin olarak belirlenmeli.

Mevcut uygulamada değerlendirmeler tarih bazlı tutuluyorsa mevcut tarih seçme mekanizmasını kullan.

Yoksa uygun ve sade bir tarih seçici ekle.

Örneğin:

`← 1 Ekim 2026 →`

veya mevcut uygulamanın tasarımına uygun bir date picker.

Kullanıcı farklı bir güne geçtiğinde o güne ait checkbox kayıtları yüklenmeli.

---

# 12. RAPORLAMA

Kaydedilen davranışlar ileride raporlarda yazılı olarak gösterilebilmeli.

Örneğin:

`Ahmet Yılmaz — 1 Ekim 2026`
- Aktif katılım
- Arkadaşına yardımcı olma
- Saygılı iletişim

veya dönem bazında:

`Ahmet Yılmaz`
- Aktif katılım: 6 kez
- İş birliği: 4 kez
- Derste konuşma: 3 kez
- Ödevini yapmama: 2 kez

Mevcut raporlama mimarisini incele ve yeni davranış verilerinin bu mimariye entegre edilebileceği şekilde kodla.

Eğer mevcut rapor ekranında henüz uygun bölüm yoksa gereksiz büyük bir rapor sistemi yazma; veri modelini ve servis katmanını gelecekte raporlamaya hazır şekilde oluştur.

---

# 13. VERİTABANI / BACKEND

Önce mevcut backend/database yapısını tespit et.

Yeni tablo/collection gerekiyorsa mevcut naming convention'a uy.

Örneğin mantıksal olarak:

`behaviors`

ve

`student_behavior_records`

gibi bir yapı gerekebilir; fakat mevcut projedeki isimlendirme ve veri mimarisine göre karar ver.

Yeni migration gerekiyorsa migration oluştur.

Güvenlik kuralları mevcutsa:
- öğretmen yalnızca yetkili olduğu sınıfların davranış kayıtlarını okuyabilmeli/yazabilmeli.
- başka sınıfların verilerine erişim oluşmamalı.

Mevcut auth ve authorization sistemini bozma.

---

# 14. PERFORMANS

Sınıfta 30–50+ öğrenci ve 12+ davranış olduğunda ekran kullanılabilir kalmalı.

Gereksiz yere bütün tabloyu her checkbox tıklamasında yeniden oluşturma.

Uygun:
- lazy rebuild,
- local state + debounce,
- optimistic UI,
- batched writes

gibi mevcut mimariye uygun optimizasyonlar değerlendirilebilir.

Ancak gereksiz karmaşıklık ekleme.

Checkbox'a basıldığında kullanıcı anında işaretlemeyi görmeli.

Kayıt başarısız olursa kullanıcıya anlaşılır hata gösterilmeli ve UI state güvenilir şekilde geri alınmalı.

---

# 15. TASARIM DİLİ

MyEduApp'ın mevcut:
- renkleri,
- typography,
- card,
- button,
- spacing,
- icon,
- navigation,
- responsive

tasarım sistemini kullan.

Yeni ekranı mevcut uygulamadan bağımsız bir tasarım gibi oluşturma.

Özellikle `Davranışlar` ekranı mevcut Öğrenci Platformu ile görsel olarak bütünleşmeli.

---

# 16. GERİYE DÖNÜK UYUMLULUK

Uygulamadaki mevcut:

- sınıflar
- öğrenciler
- performans kayıtları
- ödev kayıtları
- sınav kayıtları
- notlar
- `__` kayıtları

bozulmamalı.

Yeni `a` değeri eski kayıtları değiştirmemeli.

Yeni Davranışlar sistemi mevcut not hesaplamalarını etkilememeli.

---

# 17. TEST

Uygulama kodlandıktan sonra mutlaka:

### Haftalık Ders Planı
- web
- tablet
- mobil
- dikey scroll
- varsa yatay scroll
- overflow kontrolü

### Not Sistemi
- 1–10
- `__`
- `a`
- ortalama hesaplama
- eski kayıtların görüntülenmesi

### Davranışlar
- sınıf açma
- öğrenci listesi
- davranış kolonları
- checkbox işaretleme
- checkbox kaldırma
- tarih değiştirme
- farklı tarihte farklı kayıt
- sayfa yeniden açıldığında kayıtların gelmesi
- yatay scroll
- dikey scroll
- öğrenci kolonunun sticky olması
- web/tablet/mobil görünüm
- kayıt hatası yönetimi

test edilmeli.

Mümkünse mevcut test altyapısına uygun unit/widget/integration testleri ekle.

---

# 18. KOD KALİTESİ

Kodlama sırasında:

- mevcut dosyaları gereksiz yere yeniden yazma,
- duplicate component oluşturma,
- mevcut reusable widget'ları araştırmadan yeni widget oluşturma,
- mevcut service/repository yapısını bypass etme,
- hard-coded öğrenci/veri kullanma,
- test amaçlı sahte veriyi production kodunda bırakma,
- TODO bırakıp özelliği tamamlanmış kabul etme.

Yeni dosya gerekiyorsa mevcut proje klasörleme standardına uy.

---

# 19. UYGULAMA SIRASI

Şu sırayı izle:

1. Proje mimarisini analiz et.
2. Mevcut Öğrenci Platformu veri akışını analiz et.
3. Haftalık Ders Planı scroll sorununu düzelt.
4. `a` devamsızlık desteğini ekle.
5. Davranış veri modelini oluştur.
6. Davranış kayıt servis/repository katmanını oluştur.
7. Davranışlar kategorisini sınıf ekranına ekle.
8. Excel benzeri Davranışlar tablosunu oluştur.
9. Sticky öğrenci kolonu + yatay/dikey scroll uygula.
10. Tarih bazlı davranış yükleme/kaydetme işlemini tamamla.
11. Raporlama veri akışını hazırla.
12. Responsive testleri yap.
13. Mevcut özelliklerde regresyon kontrolü yap.

---

# 20. TAMAMLAMA KRİTERİ

İş tamamlandı sayılabilmesi için:

- `Akademik Planlar > Haftalık Ders Planı` dikey scroll ile kullanılabiliyor olmalı.
- Öğrenci değerlendirmelerinde `1–10`, `__` ve `a` birbirinden doğru şekilde ayrılmalı.
- `a` devamsızlık olarak kaydedilmeli ve not ortalamasına dahil edilmemeli.
- Her sınıfta `Davranışlar` kategorisi bulunmalı.
- Davranışlar ekranında öğrenciler satır, davranışlar kolon olmalı.
- Öğrenci kolonu sticky olmalı.
- Tablo yatay ve dikey scroll desteklemeli.
- Checkbox tıklaması kalıcı olarak kaydedilmeli.
- Aynı davranış farklı günlerde tekrar kaydedilebilmeli.
- Sayfa yeniden açıldığında kayıtlar doğru yüklenmeli.
- Web/tablet/mobil responsive çalışmalı.
- Mevcut sınıf, öğrenci ve not sistemleri bozulmamalı.
- Kod lint/analyzer/test kontrollerinden mümkün olduğunca temiz geçmeli.

İş bitiminde bana:
1. Değiştirilen dosyaları,
2. Yapılan temel değişiklikleri,
3. Veri modeli/database değişikliklerini,
4. Test sonuçlarını,
5. Varsa migration gereksinimlerini,
6. Varsa kalan riskleri

kısa ve maddeli şekilde raporla.

ÖNEMLİ:
Kodu yazmadan önce analiz et. Mevcut uygulamadaki gerçek yapıya göre karar ver. Varsayım yaparak yeni bir mimari oluşturma. Mevcut sistemle en uyumlu ve sürdürülebilir çözümü uygula.
