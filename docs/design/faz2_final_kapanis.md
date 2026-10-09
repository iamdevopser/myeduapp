FAZ 2 — FINAL KAPANIŞ
0. GÖREVİN ANA AMACI

Bu görev FAZ 2'nin kalan tüm işlerini tamamlamak ve Faz 2'yi kapatmak içindir.

Yeni bir ara tur oluşturma.

Aşağıdaki işler bu görev kapsamında zorunludur:

02 duyuru UI eksiklerini tamamla.
05 not UI eksiklerini tamamla.
06 öğretmen mobil takvimini tamamla.
Duyuru görseli altyapısını tamamla veya teknik olarak gerçekten mümkün değilse BLOCKED olarak raporla.
Veli toplantısı event modelini tamamla veya teknik olarak gerçekten mümkün değilse BLOCKED olarak raporla.
Öğrenci ve öğretmen ekranlarının 8 breakpoint responsive kontrolünü tamamla.
Accessibility son kontrolünü tamamla.
Localization kontrolünü tamamla.
Regression testlerini tamamla.
Tüm testleri çalıştır.
flutter analyze çalıştır.
Faz 2 final status raporunu oluştur.
1. ZORUNLU ÖN AUDIT

Kod değişikliğine başlamadan önce audit yapılacaktır.

İncelenecek belgeler:

docs/actions/faz_design_faz2_tur1_status.md
docs/actions/faz_design_faz2_tur2_status.md
docs/actions/faz_design_faz2_tur3_status.md
docs/actions/faz_design_faz2_tur4_audit.md
docs/actions/faz_design_faz2_tur4_status.md

Dosya isimleri farklıysa docs/actions/ altında ilgili Faz 2 raporlarını bul ve incele.

Audit sonucu:

docs/actions/faz_design_faz2_final_audit.md

dosyasına yazılacaktır.

Audit aşağıdaki tabloyu içerecektir:

İş	Mevcut Durum	Yapılacak Değişiklik	Veri/Mimari Gereksinimi	Sonuç

Audit tamamlanmadan kod değiştirilmeyecektir.

2. 02 — DUYURULAR

Tur 2'de PARTIAL kalan duyuru ekranını tamamla.

Zorunlu işler:

duyuru pill tasarımını tamamla
duyuru önizleme metnini tamamla
mevcut Design System'e uygun spacing kullan
typography'yi referansa uygun hale getir
responsive davranışı düzelt
accessibility etiketlerini tamamla
mevcut localization sistemine ekle

Yeni bir duyuru tasarım sistemi oluşturma.

Mevcut ortak Design widget'larını kullan.

Final hedef:

02 = PASS

3. 05 — NOT UI

05 ekranını referansa göre tamamla.

Zorunlu kontroller:

desktop UI
tablet UI
mobil UI
kart/list/table genişlikleri
empty state
loading state
error state
typography
spacing
accessibility
localization

Mevcut veri modelindeki gerçek not verilerini kullan.

Veri modelinde bulunmayan notları üretme.

UI tamamlanmış ancak veri modeli eksikse eksikliği açıkça raporla.

Final hedef:

05 = PASS

Gerçek bir teknik veri engeli varsa:

05 = BLOCKED

olarak raporla.

4. 06 — ÖĞRETMEN MOBİL TAKVİM

06 ekranındaki öğretmen mobil takvimini tamamla.

Zorunlu ekran genişlikleri:

360
390
430

Kontrol edilecek alanlar:

gün seçimi
takvim grid'i
ders/event kartları
event bilgileri
touch target'lar
spacing
text overflow
horizontal overflow
accessibility

Mevcut:

DesignMonthGridCalendar

ve diğer ortak Design widget'larını kullan.

İkinci bir bağımsız takvim sistemi oluşturma.

Final hedef:

06 = PASS

5. DUYURU GÖRSELİ

12 Duyuru Detay ekranındaki görsel eksikliğini çöz.

Önce mevcut:

announcement model
SQLite schema
migration sistemi
announcement service
attachment/document altyapısı
dosya saklama sistemi

incelenecektir.

Mevcut mimari destekliyorsa

Aşağıdaki işlemler yapılacaktır:

DB alanını ekle.
Migration oluştur.
Modeli güncelle.
Service/repository katmanını güncelle.
Duyuru oluşturma/güncelleme akışını güncelle.
Detail ekranını güncelle.
Görsel varsa gerçek görseli göster.
Görsel yoksa mevcut fallback icon/hero göster.
Test ekle.

Migration mevcut schema yaklaşımına uygun olacaktır.

Mevcut veriler korunacaktır.

Mevcut mimari desteklemiyorsa

Sahte görsel ekleme.

Sahte URL ekleme.

Hardcoded fotoğraf ekleme.

Bunun yerine:

12 Duyuru Detay = BLOCKED

olarak raporla ve gerekli mimariyi açıkla.

6. VELİ TOPLANTISI EVENT MODELİ

09 Takvim'deki veli toplantısı eksikliğini çöz.

Mevcut calendar/event modelini incele.

Event sistemi aşağıdaki türleri destekleyecek şekilde düzenlenecektir:

Ders
Sınav
Veli Toplantısı

Mevcut naming convention kullanılacaktır.

Veli toplantısı için gerekli minimum alanlar:

tarih
saat
başlık
mevcut sistem destekliyorsa sınıf/öğrenci bağlantısı

Takvim:

veli toplantısını gösterecek
event türünü ayırt edecek
seçili günde gösterecek
accessibility label sağlayacak
Veritabanı mevcut yapıyla genişletilebiliyorsa

Gerekli:

model
migration
service
repository
UI
test

değişikliklerini yap.

Gerçek backend/data source yoksa

Sahte event üretme.

UI'da hardcoded veli toplantısı gösterme.

Bu durumda:

09 Takvim = BLOCKED

olarak raporla.

7. 09 — TAKVİM FINAL

Takvim aşağıdaki genişliklerin tamamında kontrol edilecektir:

360
390
430
768
1024
1280
1440
1920

Kontrol:

month grid
selected day
lesson events
exam events
parent meeting events
event indicators
weekly lesson cards
spacing
text overflow
horizontal overflow
accessibility

Final hedef:

09 = PASS

Gerçek veri modeli engeli varsa ilgili engel BLOCKED olarak raporlanacaktır.

8. RESPONSIVE FINAL QA

Aşağıdaki 8 breakpoint zorunlu olarak kontrol edilecektir:

360
390
430
768
1024
1280
1440
1920

Aşağıdaki ekranların tamamı kontrol edilecektir:

Öğrenci
Ana Sayfa
Dersler
Takvim
Duyurular
Duyuru Detay
Dokümanlar
Profil
Öğretmen
Dashboard
05
06
Takvim
Navigation
Ortak
AppShell
Sidebar
Mobile navigation
Filters
Cards
Lists
Dialogs

Kontrol edilecek problemler:

RenderFlex overflow
clipped content
text overflow
aşırı dar kart
gereksiz geniş kart
horizontal overflow
yanlış breakpoint
bozuk spacing
erişilemeyen action
küçük touch target
desktop'ta gereksiz boşluk

Bulunan responsive problemleri düzelt.

Final hedef:

Responsive = PASS

9. PORTAL LAYOUT

Tur 4'te eklenen:

maxWidth: 960

uygulamasını tüm portal ekranlarında kontrol et.

Her ekran aynı genişliğe zorlanmayacaktır.

İşlevine göre uygun layout kullanılacaktır:

dashboard
list
table
detail
form
calendar

Kartların işlevsel genişliği korunacaktır.

Dar kart problemi varsa düzelt.

Final hedef:

Portal layout = PASS

10. ACCESSIBILITY FINAL

Aşağıdaki alanların tamamı kontrol edilecektir:

Navigation
sidebar
bottom navigation
back button
Lists
announcement row
feed row
document row
grade row
Calendar
day cell
selected day
event
event type
Actions
search
filter
pills
mark read
document open
Forms
label
error
button

Her interactive widget anlamlı Semantics bilgisine sahip olacaktır.

Final hedef:

Accessibility = PASS

11. LOCALIZATION FINAL

Kullanıcıya görünen yeni hiçbir string hardcoded bırakılmayacaktır.

Yeni metinler localization sistemine eklenecektir.

Kontrol edilecek metinler:

sınav
veli toplantısı
duyuru
doküman
empty state
error
accessibility label
button
status

Final hedef:

Localization = PASS

12. TEST

Kod değişiklikleri tamamlandıktan sonra zorunlu olarak:

flutter test

çalıştır.

Tur 4 başlangıç:

227 passed / 0 failed

Final hedef:

0 failed

Yeni özellikler için test ekle.

Zorunlu test alanları:

02 duyuru
05 not UI
06 mobil takvim
duyuru görseli
veli toplantısı event
takvim rendering
notification → duyuru detay
accessibility
responsive davranış
13. ANALYZE

Zorunlu:

flutter analyze

Final hedef:

0 error

Yeni warning/error oluşmuşsa düzelt.

Mevcut ve ilgisiz info mesajlarını raporla.

14. REGRESSION

Aşağıdakiler mutlaka test edilecektir:

öğrenci login
öğretmen login
öğrenci navigation
öğretmen navigation
AppShell
notification
announcement list
announcement detail
document viewer
student calendar
teacher calendar

Mevcut çalışan özellik bozulmayacaktır.

15. 07 MESAJLAR

07 Mesajlar'a yeni özellik eklenmeyecektir.

Sadece aşağıdaki değişikliklerden kaynaklanan regression kontrol edilecektir:

AppShell
AppState
navigation
Design widget'ları
16. SAHTE VERİ YASAĞI

Kesinlikle oluşturulmayacak:

sahte duyuru görseli
sahte veli toplantısı
sahte sınav
sahte not
sahte doküman
hardcoded demo data

Gerçek veri altyapısı varsa kullan.

Gerçek veri altyapısı yoksa ilgili özellik BLOCKED olarak raporlanacaktır.

17. BÜYÜK REFACTOR YASAĞI

Aşağıdaki yapılar gereksiz yere yeniden yazılmayacaktır:

AppShell
AppState
authentication
navigation
SQLite mimarisi
Design System

Değişiklikler mevcut mimariyle uyumlu olacaktır.

18. FINAL RAPOR

İş sonunda:

docs/actions/faz_design_faz2_final_status.md

oluştur.

Aşağıdaki tablo zorunludur:

Alan	Final
02 Duyurular	PASS/PARTIAL/BLOCKED
05 Not UI	PASS/PARTIAL/BLOCKED
06 Öğretmen Mobil Takvim	PASS/PARTIAL/BLOCKED
08 Duyurular	PASS/PARTIAL/BLOCKED
09 Takvim	PASS/PARTIAL/BLOCKED
11 Dokümanlar	PASS/PARTIAL/BLOCKED
12 Duyuru Detay	PASS/PARTIAL/BLOCKED
Responsive	PASS/PARTIAL/BLOCKED
Accessibility	PASS/PARTIAL/BLOCKED
Localization	PASS/PARTIAL/BLOCKED

Ayrıca:

Tamamlanan İşler
BLOCKED İşler

Her BLOCKED iş için:

teknik neden
mevcut eksik altyapı
gerekli sonraki adım
Kalan PARTIAL İşler
Test
flutter test:
...

flutter analyze:
...
Değişen Dosyalar
DB Migration

Varsa migration numarası ve değişiklikleri belirt.

19. FAZ 2 KAPANIŞ

Bu görev tamamlandığında Faz 2'nin final durumu net olacaktır.

PASS olması gereken alanlar PASS yapılacaktır.

Gerçek teknik engeli bulunan alanlar BLOCKED olarak raporlanacaktır.

Yapay PASS verilmesi yasaktır.

Faz 2'nin kalan UI, responsive, accessibility, localization, test ve regression işleri bu görev kapsamında tamamlanacaktır.