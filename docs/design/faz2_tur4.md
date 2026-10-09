# FAZ 2 TUR 4 — PARTIAL EKRANLARI PASS SEVİYESİNE TAŞIMA

## 0. GÖREVİN ANA AMACI

Bu turda yeni büyük özellikler geliştirmek yerine, **FAZ 2 Tur 3 ve önceki turlardan kalan PARTIAL durumları kapatılacaktır.**

Ana hedef:

> Mevcut ekranları bozmeden, referans tasarıma ve mevcut proje mimarisine uygun şekilde mümkün olan ekranları **PARTIAL → PASS** seviyesine taşımak.

Özellikle Tur 3'te oluşturulan ortak Design bileşenleri kullanılmalı ve gereksiz yeni UI bileşenleri oluşturulmamalıdır.

---

# 1. ÖNCE ZORUNLU AUDIT

Kod değişikliğine başlamadan önce mevcut durumu incele.

Özellikle şu dosyaları ve ilişkili servis/widget/navigation yapılarını incele:

* `docs/actions/faz_design_faz2_tur3_status.md`
* `docs/actions/`
* `docs/new_updates/`
* Tur 1 ve Tur 2 status raporları
* `StudentAnnouncementsScreen`
* `StudentAnnouncementDetailScreen`
* `student_portal_section_screens`
* `student_portal_service`
* AppShell / sidebar / navigation yapısı
* notification / notification helper yapıları
* doküman ekranları ve veri modeli
* takvim ekranı ve event modeli
* Tur 2'deki 02 / 05 / 06 ekranları

Önce şu soruların cevabını çıkar:

1. Tur 3 PARTIAL maddelerinden hangileri gerçekten kod ile kapatılabilir?
2. Hangileri veri modeli veya backend eksikliği nedeniyle şu anda kapatılamaz?
3. Tur 2'den hangi borçlar hâlâ açık?
4. Mevcut Design widget'larından hangileri tekrar kullanılabilir?
5. Yeni veri modeli gerektiren maddeler var mı?
6. Mevcut testlerin hangi alanları koruması gerekiyor?

### ÖNEMLİ

Audit sonrasında gereksiz mimari değişiklik yapma.

Mevcut çalışan yapıyı yeniden yazma.

Özellikle:

* authentication
* AppShell'in temel mimarisi
* mevcut student portal servisleri
* mevcut notification sistemi
* mevcut SQLite yapısı

gereksiz yere değiştirilmemelidir.

Audit sonucunu kısa bir rapor halinde:

`docs/actions/faz_design_faz2_tur4_audit.md`

dosyasına yaz.

Ardından uygulamaya geç.

---

# 2. TUR 3 — 08 DUYURULARI TAMAMLA

## 2.1 AppShell navigation

Mevcut:

`StudentAnnouncementsScreen`

için AppShell alt menü/navigation yapısını referans tasarıma göre kontrol et.

Tur 3 raporunda belirtilen:

> AppShell alt menü referans 08 ile 1:1 değil.

sorununu çöz.

Ancak mevcut çalışan navigation yapısını bozma.

Öğrenci:

* duyurulara
* ilgili detay ekranına
* geri dönüşe

tutarlı şekilde ulaşabilmelidir.

---

## 2.2 Veli filtresi

Mevcut:

* Tümü
* Okul
* Sınıf
* Veli

filtrelerini incele.

Özellikle:

**Veli filtresinin gerçek veriyle eşleşmesini sağla.**

Eğer mevcut veri modelinde veli hedefleme bilgisi yoksa:

* sahte veri üretme
* yanlış filtre sonucu gösterme
* gereksiz büyük veri modeli değişikliği yapma

Bunun yerine mevcut `hedef_tur` / duyuru hedefleme yapısını kullan.

Gerçek veri desteği mümkün değilse audit/status raporunda açıkça belirt.

---

# 3. TUR 3 — 12 DUYURU DETAYINI TAMAMLA

`StudentAnnouncementDetailScreen` mevcut yapısını koru.

Şunları doğrula:

* geri butonu
* başlık
* hero
* içerik
* Okundu İşaretle
* notification referansı
* localization
* accessibility

## 3.1 Bildirim → Detay

En önemli eksiklerden biri:

> Bildirimden ilgili duyuru detayına geçiş.

Mevcut notification sistemini incele.

Duyurunun `id` bilgisi notification içinde mevcutsa:

**notification → StudentAnnouncementDetailScreen**

akışını kur.

Duyuru bulunamıyorsa:

* crash olmamalı
* kullanıcıya uygun fallback gösterilmeli
* mümkünse notification okunmuş olarak işaretlenmeli.

Yeni bir notification sistemi yazma.

Mevcut `markAsRead` mekanizmasını kullan.

---

# 4. TUR 3 — 11 DOKÜMANLARI TAMAMLA

Mevcut doküman ekranındaki liste yapısını koru.

Tur 3 raporundaki ana eksik:

> Satır onTap henüz dokümanı açmıyor.

Öncelikle mevcut veri modelini incele.

Doküman gerçekten local path / URI / dosya referansı içeriyorsa:

* ilgili dokümanı aç
* mevcut platform yapısına uygun şekilde aç
* web ve mobil davranışını mümkün olduğunca uyumlu tut.

Eğer modelde gerçek dosya içeriği/path bilgisi yoksa:

* sahte dosya üretme
* olmayan bir viewer yazma.

Bu durumda eksikliği status raporunda açıkça belirt.

Doküman satırları erişilebilir olmalı.

---

# 5. TUR 3 — 09 TAKVİMİ TAMAMLA

Mevcut:

`DesignMonthGridCalendar`

yapısını koru.

## 5.1 Responsive

Özellikle:

* 360
* 390
* 430
* 768
* 1024
* 1280
* 1440
* 1920

genişliklerini dikkate al.

Amaç:

Mobilde takvim kullanılabilir kalmalı.

Desktop'ta gereksiz daralmamalı.

Kartlar işlevlerine göre yeterli genişlikte olmalı.

Overflow olmamalı.

Horizontal scroll gerekiyorsa bilinçli kullanılmalı.

---

## 5.2 Event modeli

Mevcut takvimde:

* ders
* sınav
* veli toplantısı

ayrımlarının gerçekten veri modeli tarafından desteklenip desteklenmediğini incele.

Özellikle:

> Sınav / veli toplantısı ayrı event modeli yok.

durumunu çözmek için önce mevcut model ve veri kaynaklarını analiz et.

Eğer mevcut altyapı kolayca destekliyorsa minimal bir çözüm uygula.

Ancak bu konu büyük bir veri modeli/mimari değişikliği gerektiriyorsa:

**bu turda zorla uygulama.**

Audit raporunda:

* mevcut durum
* gerekli mimari değişiklik
* önerilen sonraki faz

şeklinde belirt.

---

# 6. RESPONSIVE QA

Bu turda responsive kontrolünü genişlet.

En azından kod seviyesinde şu breakpoint'leri kontrol et:

* 360
* 390
* 430
* 768
* 1024
* 1280
* 1440
* 1920

Özellikle:

* AppShell
* duyurular
* duyuru detay
* dokümanlar
* takvim
* filtre pill'leri
* grouped list
* feed row
* calendar cell
* action button

kontrol edilmeli.

Şu sorunlara özellikle bak:

* overflow
* RenderFlex overflow
* aşırı dar kart
* gereksiz geniş kart
* metin taşması
* butonların sıkışması
* küçük ekranlarda erişilemeyen kontroller
* desktop'ta gereksiz boşluk
* tablet breakpoint sorunları

Mevcut Design widget'larını mümkün olduğunca iyileştir.

Aynı davranış farklı ekranlarda tekrar ediyorsa ortak widget üzerinden çöz.

---

# 7. ACCESSIBILITY

Tur 3'te eklenen accessibility desteğini genişlet.

Özellikle:

### Duyurular

* arama
* filter pills
* feed rows
* unread state

### Duyuru detay

* geri
* mark as read
* başlık
* içerik

### Dokümanlar

* doküman satırı
* doküman türü
* tarih
* açma action'ı

### Takvim

* gün hücreleri
* seçili gün
* etkinlik bilgisi
* haftalık ders kartları

Semantics etiketleri anlamlı olmalı.

Sadece widget'ı Semantics içine almak yeterli değil; kullanıcı açısından ne yaptığı anlaşılmalı.

---

# 8. TUR 2 BORÇLARI

Tur 3 tamamlandıktan sonra Tur 2 status raporlarını incele.

Özellikle açık kalan:

* 02
* 05
* 06

ekranlarını kontrol et.

Burada amaç yeni tasarım üretmek değil.

Mevcut Tur 1 / Tur 2 referanslarına göre:

**PARTIAL → PASS**

yapılabilecek küçük ve güvenli eksikleri tamamla.

Ancak bir Tur 2 maddesi büyük mimari değişiklik gerektiriyorsa onu zorla bu tura alma.

---

# 9. VELİ PORTALI

Bu turda Veli Portalı için büyük kapsamlı yeni özellik geliştirme yapma.

Ancak öğrenci portalında oluşturulan ortak Design bileşenlerinin veli portalında tekrar kullanılabilir olup olmadığını kontrol et.

Özellikle:

* `DesignPortalPageLayout`
* `DesignGroupedListCard`
* `DesignFeedRow`
* `DesignScrollFilterPills`
* `DesignMonthGridCalendar`

gibi bileşenlerin portal bağımsız kullanılabilir olması tercih edilir.

Eğer veli tarafında aynı UI zaten varsa ve küçük bir ortaklaştırma ile düzeltilebiliyorsa yap.

Büyük refactor yapma.

---

# 10. 07 MESAJLAR

**07 Mesajlar bu turda ana geliştirme kapsamına alınmayacaktır.**

Mevcut yapıyı bozacak değişiklik yapma.

Sadece Tur 4'te yapılan ortak navigation / design değişiklikleri nedeniyle regression oluşup oluşmadığını kontrol et.

---

# 11. TASARIM KURALLARI

Bu tur boyunca:

### Yap

* mevcut Design System'i kullan
* ortak widget'ları yeniden kullan
* responsive davranışı iyileştir
* accessibility ekle
* mevcut localization sistemini kullan
* mevcut service/repository yapılarını kullan
* mevcut renk, spacing, typography sistemine uy

### Yapma

* rastgele yeni renkler
* ekran bazlı farklı tasarım dili
* gereksiz shadow/card çeşitleri
* hardcoded sahte veri
* sahte doküman
* sahte sınav
* sahte veli toplantısı
* mevcut servis yerine paralel servis
* gereksiz büyük refactor
* authentication mimarisini değiştirme
* SQLite mimarisini yeniden yazma

---

# 12. TEST

Değişikliklerden sonra mutlaka:

```bash
flutter test
```

çalıştır.

Ardından:

```bash
flutter analyze
```

çalıştır.

Tur 3 başlangıç noktası:

**223 passed / 0 failed**

olduğu için regression kabul edilemez.

Hedef:

* mevcut testler: PASS
* yeni testler: PASS
* analyze: 0 error

Yeni davranış eklendiğinde uygun widget/unit test ekle.

Özellikle test eklenmesi gereken alanlar:

1. duyuru filtreleri
2. notification → duyuru detay
3. mark-as-read
4. doküman action
5. calendar responsive davranışı
6. accessibility semantics

---

# 13. TEST SAYISINDAKİ DEĞİŞİMİ RAPORLA

Final raporunda:

```text
flutter test:
X passed / Y failed
```

şeklinde gerçek sonucu yaz.

223 testten farklı bir sayı çıkarsa:

* kaç test eklendi
* kaç test değiştirildi
* neden değiştirildi

açıkla.

---

# 14. DOKÜMANTASYON

Tur sonunda:

`docs/actions/faz_design_faz2_tur4_status.md`

oluştur.

Şu bölümler mutlaka olsun:

## Genel Durum

* PASS
* PARTIAL
* BLOCKED

olarak net sonuç.

## 08 Duyurular

* önceki durum
* yapılanlar
* kalanlar
* final durum

## 12 Duyuru Detay

aynı format.

## 09 Takvim

aynı format.

## 11 Dokümanlar

aynı format.

## Responsive

Hangi genişliklerin kontrol edildiğini belirt.

## Accessibility

Tamamlanan accessibility kontrollerini belirt.

## Tur 2 Borçları

02 / 05 / 06 durumlarını ayrı ayrı belirt.

## 07 Mesajlar

Dokunulmadığını açıkça belirt.

## Test

Gerçek test sonucu.

## Analyze

Gerçek analyze sonucu.

## Değişen Dosyalar

Yeni/değişen dosyaları listele.

## Kalan Borç

Bir sonraki tur için kalan işleri önem sırasına göre listele.

---

# 15. BAŞARI KRİTERİ

Tur sonunda mümkün olduğunca şu hedefe ulaş:

### 08 Duyurular

**PASS**

### 12 Duyuru Detay

**PASS**

### 11 Dokümanlar

**PASS** veya gerçek veri modeli nedeniyle BLOCKED

### 09 Takvim

**PASS** veya event modeli nedeniyle açıkça PARTIAL

### Responsive

**PASS**

### Accessibility

**PASS**

### Tur 2 — 02/05/06

Mümkün olanlar **PASS**

### 07 Mesajlar

**Dokunulmadı**

---

# 16. EN ÖNEMLİ KURAL

Bu turda kapsamı kontrol altında tut.

Bir ekranı PASS yapmak için:

> mevcut mimari + mevcut veri + mevcut Design System

kullanılabiliyorsa uygula.

Ama bir gereksinim:

> yeni backend + yeni DB modeli + büyük refactor + yeni authentication mimarisi

gerektiriyorsa bunu zorla yapma.

Bunun yerine:

1. mevcut eksikliği tespit et
2. neden PASS olamadığını açıkla
3. gerekli mimariyi raporla
4. sonraki faz için öner

---

# FINAL ÇIKTI

Tur sonunda bana şu bilgileri özetle:

```text
FAZ 2 TUR 4 — FINAL STATUS

08 Duyurular: PASS / PARTIAL / BLOCKED
12 Duyuru Detay: PASS / PARTIAL / BLOCKED
09 Takvim: PASS / PARTIAL / BLOCKED
11 Dokümanlar: PASS / PARTIAL / BLOCKED

Responsive: PASS / PARTIAL
Accessibility: PASS / PARTIAL

Tur 2:
02: ...
05: ...
06: ...

07 Mesajlar: Dokunulmadı

flutter test:
...

flutter analyze:
...

Değişen dosyalar:
...

Kalan borç:
...
```

**Öncelik sırası:**

1. Regression güvenliği
2. Tur 3 PARTIAL ekranlarını kapatma
3. Responsive
4. Accessibility
5. Tur 2 borçları
6. Ancak gerekiyorsa küçük ortak component iyileştirmeleri

Yeni özellik geliştirmek bu turun amacı değildir.
