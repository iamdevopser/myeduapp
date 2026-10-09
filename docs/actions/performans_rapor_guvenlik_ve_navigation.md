# MyEduApp – Performans, Rapor, Not Güvenliği ve Öğrenci Senkronizasyonu

## TEMEL KURAL – MİNİMUM DEĞİŞİKLİK / MİNİMUM MALİYET

Bu görevde öncelik mevcut MyEduApp mimarisini korumaktır.

ÖNCE mevcut ilgili kodları analiz et, SONRA yalnızca gerekli dosyalarda minimum değişiklik yap.

Kesinlikle:
- Gereksiz refactor yapma.
- Çalışan kodu yeniden yazma.
- Yeni architecture oluşturma.
- Duplicate logic oluşturma.
- Yeni package ekleme.
- Database yapısını gereksiz yere değiştirme.
- Backup/restore sistemine dokunma.
- İlgisiz dosyalara dokunma.

Mevcut database, modeller, repository/service yapısı, navigation sistemi ve çalışan UI mümkün olduğunca korunmalıdır.

Bir özellik mevcut mekanizma ile çözülebiliyorsa yeni mekanizma oluşturma.

---

# 1. NAVBAR'DA AÇIK MENÜLERİN SEKME OLARAK TUTULMASI

Mevcut Sidebar ana menülerinden birine tıklandığında mevcut açık menünün kapanması yerine, ana menü Navbar'da bir sekme/button olarak açılmalıdır.

Örnek:

[ Öğrenci Platformu × ] [ Ders Platformu × ] [ Raporlar × ]

## Kurallar

- Sidebar'dan bir ana menü açıldığında Navbar'a bir sekme eklenir.
- Açılan sekme aktif olur.
- Zaten açık olan ana menü tekrar seçilirse ikinci sekme oluşturulmaz; mevcut sekme aktif hale getirilir.
- Her sekmenin sağ tarafında `×` kapatma butonu bulunur.
- `×` tıklanınca yalnızca o sekme kapanır.
- Aktif sekme kapatılırsa uygun başka bir açık sekmeye geçilir.
- Açık sekmeler kullanıcı tarafından kapatılmadıkça açık kalır.

## Ana menü / alt menü ayrımı

Navbar sekmeleri yalnızca ANA MENÜLER için oluşturulmalıdır.

Örneğin:

Öğrenci Platformu
- Öğrenci Listesi
- Performans
- Ödevler
- Sınavlar

için yalnızca:

[ Öğrenci Platformu × ]

sekmesi bulunmalıdır.

Öğrenci Listesi, Performans, Ödevler ve Sınavlar ayrı Navbar sekmeleri olmamalıdır.

## Durumun korunması

Mümkün olan mevcut navigation/state mekanizmasını kullan.

Bir ana menüden diğerine geçildiğinde önceki menünün mevcut state'i gereksiz yere sıfırlanmamalıdır.

Örneğin Öğrenci Platformu içinde seçilmiş sınıf/menü/filtre gibi mevcut state zaten korunabiliyorsa bu davranış korunmalıdır.

Mevcut navigation sistemi uygunsa onun üzerine minimum değişiklikle kurulmalıdır.

Yeni ve paralel bir navigation framework oluşturma.

## Responsive

Desktop, tablet ve mobil görünüm mevcut responsive yapıyı bozmamalıdır.

Navbar'daki sekmeler ekran daraldığında taşma oluşturuyorsa mevcut tasarıma uygun yatay kaydırma veya mevcut responsive çözüm kullanılmalıdır.

---

# 2. PERFORMANS KOLONLARI

Performans tablosu şu yapıda olmalıdır:

Öğrenci | Materyal | Aktivite 1 | Aktivite 2 | Aktivite 3 | ...

## Sabit kolonlar

- Materyal sabit olmalıdır.
- İlk Aktivite kolonu olan Aktivite 1 de sabit olmalıdır.
- Performans açıldığında en az:

Öğrenci | Materyal | Aktivite 1

görülmelidir.

## Kolon Ekle

`Kolon Ekle` butonu yalnızca yeni aktivite kolonları eklemelidir.

İlk tıklama:
Aktivite 2

İkinci:
Aktivite 3

Üçüncü:
Aktivite 4

şeklinde devam etmelidir.

Asla:
- ikinci Materyal
- ikinci Aktivite 1

oluşturulmamalıdır.

Aktivite 1 silinmemelidir.

Aktivite 2 ve sonrası mevcut CRUD davranışına göre silinebilir/düzenlenebilir.

Mevcut aktivite kolonları ve notları korunmalıdır.

Mevcut ScoreDropdown kullanılmaya devam etmelidir.

ScoreDropdown:
- 10 → 1
- boş/— seçeneği
- overlay/floating
- tablo yüksekliğini değiştirmeme
- mevcut save mekanizmasını kullanma

---

# 3. TÜM NOTLARIN KESİN OLARAK KAYDEDİLMESİ

Bu görevde veri kaybı kabul edilemez.

Aşağıdaki tüm notlar database'e kesin olarak kaydedilmelidir:

- Materyal
- Aktivite 1+
- Ödev
- Sınav

Not seçildiğinde:

1. Mevcut save/repository/database mekanizması çağrılmalı.
2. Database yazma işlemi başarıyla tamamlanmalı.
3. Başarılı kayıt UI/state'e yansıtılmalı.
4. Save başarısızsa işlem sessizce başarılı kabul edilmemeli.
5. Kullanıcı uygun şekilde bilgilendirilmeli.
6. Sayfadan çıkıp tekrar girildiğinde değer database'den okunmalıdır.

Not yalnızca memory/state içinde tutulmamalıdır.

Menüler arasında geçiş:
Performans → Ödevler → Sınavlar → Performans

yapıldığında notlar kaybolmamalıdır.

Uygulama yeniden açıldığında daha önce başarıyla kaydedilmiş notlar korunmalıdır.

Mevcut auto-save mekanizması varsa onu kullan ve yalnızca gerekli noktayı düzelt.

Yeni not kayıt sistemi oluşturma.

---

# 4. GÜNLÜK ORTALAMA VE TARİH ARALIĞI

Bir öğrencinin belirli bir günde aldığı tüm numerik notlar eşit ağırlıklı kabul edilmelidir.

Dahil:

- Materyal
- tüm Aktiviteler
- Ödev
- Sınav

Örnek:

Materyal = 8
Aktivite 1 = 10
Aktivite 2 = 7
Ödev = 9
Sınav = 6

Günlük ortalama:

(8 + 10 + 7 + 9 + 6) / 5 = 8.00

Boş/— notlar hesaba katılmamalıdır.

Hiç not yoksa:
- 0 kabul edilmemeli.
- Ortalama boş/— gösterilmelidir.

## Tarih aralığı

Rapor ekranında başlangıç ve bitiş tarihi seçilebilmelidir.

Örneğin:

01.09.2026 → 13.09.2026

Önce her günün günlük ortalaması hesaplanmalıdır.

Sonra yalnızca not bulunan günlerin günlük ortalamaları eşit ağırlıklı olarak genel ortalamaya dönüştürülmelidir.

Örnek:

09.09 → 8.00
10.09 → 7.50
11.09 → 9.00

Genel:

(8.00 + 7.50 + 9.00) / 3 = 8.17

Not bulunmayan günler genel ortalamaya dahil edilmemelidir.

Bir günde 5 not, diğer günde 1 not olması günlerin ağırlığını değiştirmemelidir.

---

# 5. RAPORDA TÜM NOTLARIN DETAYI

Rapor yalnızca ortalama göstermemelidir.

Ortalamanın nasıl oluştuğu görülebilmelidir.

Özellikle Performans altında:

- Materyal
- Aktivite 1
- Aktivite 2
- Aktivite 3
- ...

notları açıklamalarıyla birlikte gösterilmelidir.

Örnek:

09.09.2026 | Materyal  | Kitap etkinliği          | 10
09.09.2026 | Aktivite  | Tahtada problem çözme    | 9
09.09.2026 | Aktivite  | Grup çalışması           | 8
10.09.2026 | Aktivite  | Sözlü katılım            | 10

## Her detay kaydında mutlaka

- Tarih
- Not türü
- Açıklama/kolon adı
- Not değeri

bulunmalıdır.

Tarih kesinlikle çıkarılmamalıdır.

Açıklama mevcut `not_kolonlari` veya mevcut ilgili veri kaynağından alınmalıdır.

Örneğin:

Aktivite 1 → "Tahtada problem çözme"

raporda yalnızca "Aktivite 1" yazmak yerine açıklama kullanılmalıdır.

Açıklama yoksa mevcut kolon adı fallback olarak kullanılabilir.

---

# 6. RAPORDA NOT TÜRLERİ

Rapor aşağıdaki tüm not türlerini gösterebilmelidir:

PERFORMANS
- Materyal
- Aktivite 1+
- açıklama
- tarih
- not

ÖDEV
- açıklama
- tarih
- not

SINAV
- açıklama
- tarih
- not

Günlük Ortalama

## Performans ortalaması

Performans grubu ayrıca kendi ortalamasını gösterebilir.

Performans ortalaması:

Materyal + Aktiviteler

üzerinden hesaplanmalıdır.

## Genel günlük ortalama

Günlük genel ortalama:

Materyal + Aktiviteler + Ödev + Sınav

üzerinden hesaplanmalıdır.

Bu iki hesap birbirine karıştırılmamalıdır.

---

# 7. ÖĞRENCİ SINIF LİSTESİNİN KORUNMASI

ANA SINIF ÖĞRENCİ LİSTESİ source of truth olarak korunmalıdır.

Performans, Ödevler ve Sınavlar kendi öğrenci listesini ana sınıf listesinin yerine kullanmamalıdır.

Bir öğrenci:

- Performans'tan
- Ödevler'den
- Sınavlar'dan

silinse bile ANA SINIF LİSTESİNDEN SİLİNMEMELİDİR.

Alt menüdeki silme işlemi ile sınıf üyeliğinin silinmesi birbirinden ayrı olmalıdır.

## Önemli

Bir öğrencinin alt menüden görünürlüğü/kaydı kaldırılırken geçmiş notları silinmemelidir.

Örneğin:

BOT Nicolae

09.09 Aktivite 1 = 9
10.09 Aktivite 2 = 8
11.09 Ödev = 10

alt menüden kaldırılırsa bu notlar database'den silinmemelidir.

---

# 8. GERİ / İLERİ SONRASI OTOMATİK SENKRONİZASYON

Kullanıcı:

Sınıf Listesi
→ Performans
→ Öğrenci kaldırıldı
→ Geri
→ İleri / Performans

yaptığında Performans tekrar açıldığında güncel ana sınıf listesiyle senkronize edilmelidir.

Ana sınıfta bulunan öğrenci alt menüde eksikse tekrar görünmelidir.

Örnek:

Ana sınıf:

BOT
BRICEAC
CAPATINA
CARAUS

Performans:

BOT
BRICEAC
CARAUS

Tekrar açıldığında:

BOT
BRICEAC
CAPATINA
CARAUS

olmalıdır.

CAPATINA'nın eski notları korunmalıdır.

Aynı kural:

- Ödevler
- Sınavlar

için de uygulanmalıdır.

Navigation nedeniyle öğrenci verisi kaybolmamalıdır.

---

# 9. VERİ SİLME KURALI

Alt menüde öğrencinin listeden çıkarılması:

Öğrencinin sınıftan silinmesi

anlamına gelmemelidir.

Öğrencinin gerçek sınıftan silinmesi yalnızca ana sınıf/öğrenci yönetimi üzerinden yapılmalıdır.

Alt menülerdeki geçici/ilişkisel kayıtlar silinse bile:

- ana öğrenci
- geçmiş notlar
- not kolonları
- backup/restore verileri

gereksiz şekilde silinmemelidir.

---

# 10. TESTLER

Minimum gerekli testleri ekle veya mevcut testleri güncelle.

Öncelikli testler:

1. Performans açıldığında Materyal + Aktivite 1 görünmeli.
2. Kolon Ekle → Aktivite 2 → Aktivite 3 → Aktivite 4.
3. Aktivite 1 silinememeli.
4. Mevcut activity notları korunmalı.
5. Verilen not sayfadan çıkıp tekrar girildiğinde korunmalı.
6. Performans → Ödev → Sınav → Performans geçişinde notlar korunmalı.
7. Günlük ortalama tüm not türlerini eşit ağırlıkla hesaba katmalı.
8. Boş notlar hesaba katılmamalı.
9. Tarih aralığı genel ortalaması günlük ortalamaların eşit ağırlıklı ortalaması olmalı.
10. Not olmayan günler genel ortalamaya katılmamalı.
11. Performans detayında tarih + tür + açıklama + not görünmeli.
12. Öğrenci alt menüden silinse bile ana sınıf listesinden silinmemeli.
13. Geri/ileri sonrası eksik öğrenci otomatik olarak yeniden görünmeli.
14. Öğrenci geri geldiğinde eski notları korunmalı.

Sonunda:

flutter test
flutter analyze

çalıştır.

---

# 11. UYGULAMA STRATEJİSİ

Çalışmaya başlamadan önce yalnızca bu görevle ilgili mevcut dosyaları ve ilgili kod akışlarını analiz et.

Öncelikli olarak:

- Sidebar/navigation
- Navbar
- Student Platform
- Performans
- Student Report
- not_kolonlari
- ogrenci_notlari
- öğrenci-sınıf ilişkisi
- mevcut save mekanizması

incelenmelidir.

Bütün projeyi gereksiz yere tarama.

Mevcut çalışan mekanizmayı kullan.

Minimum dosya değişikliği yap.

Bir problemi mevcut küçük bir değişiklikle çözebiliyorsan daha büyük refactor yapma.

Yeni package EKLEME.

Database migration ancak mevcut yapıyla çözüm mümkün değilse ve gerçekten gerekliyse yapılmalıdır.

Backup/restore koduna dokunma; bu görev için zorunlu olmadıkça backup sistemi değiştirilmemelidir.

İşlem sonunda değiştirilen dosyaları ve neden değiştirildiğini kısa şekilde raporla.

Test ve analyze sonucunu raporla.