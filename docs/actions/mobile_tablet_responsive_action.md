ACTION — MYEDUAPP RESPONSIVE TABLET / MOBILE UI

Amaç

Mevcut Windows/Desktop görünümünü ve tüm çalışan fonksiyonları koruyarak MyEduApp'i tablet ve telefon ekranlarına gerçek anlamda adaptive hale getir.

project.mdc içindeki tüm kurallar aynen geçerlidir.

Bu action yalnızca responsive/adaptive UI ve mobil kullanım deneyimini kapsar.

1. TEMEL KURALLAR

Database, modeller, repository/service, provider/state management, routing ve business logic değiştirilmemeli.

Autosave, CRUD, raporlama, PDF/Excel export, Ders Platformu, Öğrenci Platformu ve Mentörlük işlevleri korunmalı.

Mevcut Desktop görünümü mümkün olduğunca aynı kalmalı.

Yeni dependency eklenmemeli.

Gereksiz refactor yapılmamalı.

Önce mevcut responsive/layout yapısı analiz edilmeli.

Projede mevcut ortak component veya responsive çözüm varsa yeniden kullanılmalı.

Aynı işlevi yapan yeni component/abstraction gereksiz yere oluşturulmamalı.

2. EKRAN SINIFLANDIRMASI

Mevcut responsive altyapısı varsa onu kullan.

Yoksa minimum değişiklikle:

Desktop: >= 1024 px

Tablet: 600–1023 px

Mobile: < 600 px

Portrait/landscape gerektiğinde dikkate alınmalı.

Amaç yalnızca ekranı küçültmek değil, layout ve kullanım şeklini ekrana göre uyarlamaktır.

3. SIDEBAR / NAVIGATION

Desktop

Mevcut sidebar korunmalı.

Tablet

Sidebar kompakt veya drawer davranışına geçebilmeli. İçerik gereksiz daraltılmamalı.

Mobile

Desktop sidebar sürekli görünmemeli. Üstte mevcut Design System'e uygun ☰ + Sayfa Başlığı yapısı kullanılmalı ve mevcut sidebar menüleri drawer olarak açılmalı.

Mevcut route ve navigation mantığı değiştirilmemeli.

4. ANA SAYFA

Desktop görünümü korunmalı.

Tablet/mobile:

Hızlı işlem butonları uygun grid/tek kolon yapısına geçmeli.

Kartlar ekran genişliğine uyarlanmalı.

Yatay taşma olmamalı.

Daha önce kaldırılmış Hızlı Çalışma Alanları tekrar eklenmemeli.

5. DERS PLATFORMU

Desktop'taki mevcut çoklu panel yapısı korunabilir.

Tablet:

Konu alanı gerektiğinde daraltılmalı.

Content alanına yeterli genişlik bırakılmalı.

Mobile:

Çok kolonlu desktop düzeni zorla kullanılmamalı.

Konu seçimi drawer/list veya uygun tek kolon yapısına geçmeli.

Konu seçildiğinde doküman/içerik mümkün olduğunca ekranın tamamını kullanmalı.

Doküman isimleri için gereksiz ayrı geniş panel oluşturulmamalı.

PDF, video ve diğer içerikler dar alana sıkıştırılmamalı.

Mevcut içerik açma fonksiyonu değişmemeli; yalnızca sunum adaptive olmalı.

6. DERS OLUŞTURUCU

Desktop'taki:
Blok Türleri | Ders Yapısı | Ders/Kurs/Ünite/Konu Ayarları
yapısı korunmalı.

Tablet'te gerektiğinde paneller daraltılabilir/drawer olabilir.

Mobile'da üç kolon aynı anda gösterilmemeli; akış adım adım gösterilebilmeli:
Ders → Kurs → Ünite → Konu → İçerik

Mevcut ekleme, düzenleme, silme, resim ve doküman işlevleri aynen korunmalı.

7. ÖĞRENCİ PLATFORMU

Desktop'taki tablo korunmalı.

Tablet'te tablo responsive hale getirilmeli.

Mobile'da çok geniş tabloyu zorla küçültmek yerine gerektiğinde öğrenci kartı/dikey bilgi yapısı kullanılmalı:

Öğrenci adı

Kategori/Kolon

Puan girişi

Mevcut tarih, gün değiştirme, kolon, puan, autosave, öğrenci ve kategori işlemleri değişmemeli.

Sol sınıf/kategori paneli tablet'te daraltılabilir; mobile'da drawer/uygun seçim paneli olabilir.

8. RAPORLAR

Desktop tabloları korunmalı.

Tablet'te responsive tablo veya kontrollü yatay scroll kullanılabilir.

Mobile'da geniş tablolar gereksiz yere sıkıştırılmamalı. Kategori ortalamaları gerektiğinde dikey/karte dayalı gösterilebilir.

Rapor hesaplama mantığı, PDF ve Excel export değiştirilmemeli.

9. MENTÖRLÜK

Mevcut Mentörlük desktop işlevi korunmalı.

Tablet/mobile:

sınıf seçimi

takvim

bireysel etkinlik

grup etkinliği

öğrenci seçimi

davranış raporu

tek ekrana sıkıştırılmamalı. Gerektiğinde adım adım navigation kullanılmalı.

10. FORM / DIALOG

Desktop dialog görünümü korunmalı.

Tablet'te ekranı aşmamalı.

Mobile'da geniş dialoglar ekran genişliğine uyarlanmalı; gerekiyorsa near-full-screen olmalı. İçerik scroll edilebilir olmalı. Klavye açıldığında inputlar erişilebilir kalmalı.

Özellikle sınıf, öğrenci, kolon, ders/kurs/ünite/konu, resim ve rapor filtreleri kontrol edilmeli.

11. TOUCH / MOBILE UX

Kontroller parmakla rahat seçilmeli.

Küçük tıklama alanlarından kaçınılmalı.

Hover'a bağlı kritik işlev bulunmamalı.

Hover yalnızca pointer kullanılan cihazlarda yardımcı davranış olmalı.

Mevcut renk, typography, icon, spacing, radius ve component dili korunmalı.

12. KART / GRID

Desktop çoklu kolon, tablet daha az kolon, mobile tek kolon yaklaşımı kullanılmalı.

Sabit pixel genişlikleri ekranı taşırmamalı.

13. OVERFLOW / KEYBOARD

Ana sayfalarda:

yatay taşma,

ekran dışına çıkan buton,

ekran dışına çıkan dialog,

klavye altında kalan input,

erişilemeyen action

olmamalı.

Uzun listelerde mevcut scrolling yaklaşımı korunmalı; gereksiz nested scroll oluşturulmamalı.

14. DATA / LOGIC

Bu action kapsamında database veya migration yapılmamalı.

Responsive ihtiyaç nedeniyle yalnızca widget/layout katmanı değiştirilmeli.

15. UYGULAMA SIRASI

Önce yalnızca gerekli mevcut dosyaları analiz et:

Ana layout

Sidebar/navigation

Responsive componentler

Ana Sayfa

Ders Platformu

Ders Oluşturucu

Öğrenci Platformu

Raporlar

Mentörlük

Ortak card/table/dialog/form componentleri

Önce mevcut reusable çözüm olup olmadığını tespit et. Sonra minimum dosya değişikliğiyle uygula.

Her sayfayı yeniden yazma.

16. KABUL KRİTERLERİ

Desktop görünümü bozulmadı.

Tablet portrait çalışıyor.

Tablet landscape çalışıyor.

Mobile portrait çalışıyor.

Mobile landscape temel kullanımda çalışıyor.

Desktop sidebar korunuyor.

Tablet/mobile navigation uygun.

Ders Platformu mobilde uygun tek/az kolon yapısında.

Content/doküman yeterli alan kullanıyor.

Ders Oluşturucu mobilde üç kolonu zorla göstermiyor.

Öğrenci Platformunda tüm öğrenciler erişilebilir.

Mobil puan girişi kullanılabilir.

Raporlar mobilde okunabilir.

Mentörlük tablet/mobile kullanılabilir.

Dialoglar ekrana sığıyor.

Klavye inputları kapatmıyor.

Gereksiz yatay taşma yok.

Database/business logic değişmedi.

Mevcut CRUD/autosave/report/export çalışıyor.

Yeni dependency eklenmedi.

Gereksiz refactor yapılmadı.

flutter analyze kontrol edildi.

Sonuç

Agent sonunda kısaca:

responsive yaklaşımı,

değiştirilen dosyaları,

desktop/tablet/mobile kontrolünü,

flutter analyze sonucunu
raporlamalı.