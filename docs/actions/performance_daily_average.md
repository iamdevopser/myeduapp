# Performans + Günlük Not Ortalaması Geliştirmesi

## AMAÇ

Mevcut Öğrenci Platformu yapısını bozmadan iki geliştirme yapılacaktır:

1. Performans tablosunda Materyal + en az bir sabit Aktivite kolonu bulunması.
2. Materyal, Aktivite, Ödev ve Sınav notlarının öğrenci bazında günlük ve tarih aralığına göre ortalamalarının raporlanması.

Mevcut veri yapısı, notlar, CRUD işlemleri, backup/restore sistemi ve çalışan özellikler korunmalıdır.

---

# 1. PERFORMANS TABLOSU

Mevcut Performans tablosu:

Öğrenci | Materyal | Aktivite 1 | ...

şeklinde çalışmalıdır.

## Sabit kolonlar

Performans tablosunda şu iki kolon HER ZAMAN bulunmalıdır:

Öğrenci | Materyal | Aktivite 1

- Materyal tek ve sabit kolondur.
- Aktivite 1 tek ve sabit kolondur.
- Aktivite 1 hiçbir zaman tamamen kaldırılmamalıdır.
- Eğer mevcut veride hiç activity kolonu yoksa otomatik olarak Aktivite 1 oluşturulmalıdır.
- Eğer mevcut activity kolonları varsa mevcut ilk activity kolonu Aktivite 1 olarak kullanılmalıdır.
- Mevcut activity verileri silinmemelidir.

## Dinamik kolonlar

"Kolon Ekle" butonuna basıldığında:

- İlk eklenen yeni kolon Aktivite 2 olmalıdır.
- Sonraki kolonlar Aktivite 3, Aktivite 4, ... şeklinde devam etmelidir.
- Kolon Ekle hiçbir zaman yeni bir Materyal kolonu oluşturmamalıdır.
- Kolon Ekle hiçbir zaman ikinci bir Aktivite 1 oluşturmamalıdır.

Örnek:

Öğrenci | Materyal | Aktivite 1 | Aktivite 2 | Aktivite 3 | Aktivite 4
       |          | sabit      | eklenebilir | eklenebilir | eklenebilir

## Aktivite 1 davranışı

Aktivite 1 kolonunun kendisi zorunlu/sabit olmalıdır.

Aktivite 1 silinemez.

Eğer mevcut CRUD sisteminde activity silme özelliği varsa:
- Aktivite 2 ve sonrası silinebilir.
- Aktivite 1 için silme işlemi engellenmelidir.
- Mevcut veriler korunmalıdır.

Aktivite isimlerinin mevcut sistemde düzenlenebilmesi destekleniyorsa bu özellik korunmalıdır.

## Not girişi

Materyal ve bütün Aktivite kolonlarında mevcut ScoreDropdown kullanılmaya devam etmelidir.

ScoreDropdown:
- 10 → 1 sıralaması
- "—" = boş/not verilmemiş
- overlay/floating açılmalı
- tablo yüksekliğini değiştirmemeli
- mevcut otomatik kaydetme mekanizmasını kullanmalı

Ödevler ve Sınavlar ayrı menüler olarak kalmalıdır ve aynı ScoreDropdown kullanılmaya devam etmelidir.

---

# 2. GÜNLÜK NOT ORTALAMASI

Bir öğrencinin belirli bir tarihte aldığı bütün NUMERİK notlar günlük ortalamaya dahil edilmelidir.

Dahil edilecek not türleri:

- Materyal
- Aktivite 1
- Aktivite 2
- Aktivite 3
- ...
- Ödev
- Sınav

Not türlerinin ağırlığı birbirinden farklı olmayacaktır.

Her verilen not = 1 eşit ağırlık.

Örnek:

Öğrenci A:

Materyal = 8
Aktivite 1 = 10
Aktivite 2 = 7
Ödev = 9
Sınav = 6

Günlük ortalama:

(8 + 10 + 7 + 9 + 6) / 5 = 8.0

## Boş notlar

"—" veya null/boş olan notlar ortalamaya dahil edilmemelidir.

Örneğin:

Materyal = 8
Aktivite 1 = 10
Aktivite 2 = —
Ödev = 6
Sınav = —

Ortalama:

(8 + 10 + 6) / 3 = 8.0

## Hiç not yoksa

O gün öğrenciye hiç numerik not verilmemişse:

- Ortalama hesaplanmamalı.
- 0 kabul edilmemeli.
- Rapor ekranında "—" veya mevcut sistemdeki uygun boş değer gösterilmelidir.

---

# 3. GÜNLÜK RAPOR

Öğrencinin günlük not raporunda günlük ortalama gösterilmelidir.

Örnek:

Tarih        Günlük Ortalama
09.09.2026   8.00
10.09.2026   7.50
11.09.2026   9.00
12.09.2026   8.25
13.09.2026   8.00

Günlük ortalama sadece o gün girilmiş numerik notlardan hesaplanmalıdır.

Mevcut öğrenci raporu yapısı mümkün olduğunca korunmalıdır.

---

# 4. TARİH ARALIĞI / GENEL ORTALAMA

Rapor ekranına tarih aralığı seçme özelliği eklenmelidir.

Kullanıcı:

- Başlangıç tarihi
- Bitiş tarihi

seçebilmelidir.

Örneğin:

01.09.2026 → 13.09.2026

seçildiğinde öğrencinin bu aralıktaki günlük ortalamaları hesaplanmalıdır.

## Genel ortalama hesabı

ÖNCE her günün günlük ortalaması hesaplanır.

SONRA seçilen aralıktaki mevcut günlük ortalamalar eşit ağırlıkla ortalanır.

Örnek:

09.09 = 8.00
10.09 = 7.50
11.09 = 9.00

Genel ortalama:

(8.00 + 7.50 + 9.00) / 3 = 8.17

Bir gün içinde 5 not, başka bir gün içinde 1 not bulunması günlerin ağırlığını değiştirmemelidir.

Not bulunmayan günler genel ortalamaya dahil edilmemelidir.

Örneğin:

09.09 = 8.00
10.09 = —
11.09 = 9.00

Genel ortalama:

(8.00 + 9.00) / 2 = 8.50

10.09 günü 0 olarak kabul edilmemelidir.

---

# 5. RAPORDA GÖSTERİM

Mümkün olduğunca mevcut Student Report yapısı kullanılmalıdır.

Raporda en azından şu bilgiler bulunmalıdır:

Öğrenci
Seçilen tarih aralığı
Günlük ortalamalar
Genel Ortalama

Örnek:

Öğrenci: BOT Nicolae

Tarih Aralığı:
01.09.2026 - 13.09.2026

Günlük Ortalamalar:
09.09.2026 → 8.00
10.09.2026 → 7.50
11.09.2026 → 9.00
13.09.2026 → 8.50

Genel Ortalama: 8.25

---

# 6. VERİ MODELİ

Yeni ve gereksiz bir not sistemi oluşturma.

Mevcut:

- not_kolonlari
- ogrenci_notlari
- materials
- activity
- homework
- exam

yapıları ve mevcut ilişkiler kullanılmalıdır.

Mevcut backup/restore formatı değiştirilmemelidir.

Gereksiz database migration oluşturma.

Eğer Activity 1'in zorunlu olması için migration gerekiyorsa mevcut migration sistemine uygun minimal migration yapılmalıdır.

Mevcut notlar kesinlikle silinmemelidir.

---

# 7. HESAPLAMA MANTIĞI

Günlük ortalama hesaplama kodunu tek bir yerde merkezi hale getir.

Aynı hesaplama mantığını:

- Student Report
- tarih aralığı raporu
- genel ortalama
- varsa sınıf raporu

için tekrar tekrar yazma.

Duplicate calculation logic oluşturma.

Sadece numerik 1–10 notları hesaba kat.

---

# 8. PERFORMANS

20–30 öğrencili sınıflarda ve çok sayıda activity kolonunda tablo kullanılabilir durumda kalmalıdır.

Tarih aralığı raporunda gereksiz şekilde bütün database'i tekrar tekrar sorgulama.

Mevcut repository/database servis mimarisini kullan.

Yeni package ekleme.

---

# 9. GERİYE DÖNÜK UYUMLULUK

Mevcut:

- öğrenci kayıtları
- notlar
- activity kolonları
- material kolonları
- homework notları
- exam notları
- raporlar
- backup/restore

bozulmamalıdır.

Eski backup dosyaları çalışmaya devam etmelidir.

---

# 10. TEST

Önce mevcut yapıyı analiz et.

Sonra minimum gerekli dosyalara müdahale et.

Test senaryoları:

1. Performans açıldığında:
   Öğrenci | Materyal | Aktivite 1
   görülmeli.

2. Kolon Ekle:
   ilk tıklama → Aktivite 2
   ikinci → Aktivite 3
   üçüncü → Aktivite 4

3. Aktivite 1 silinememeli.

4. Aktivite 2+ silinebilmeli.

5. Eski activity notları korunmalı.

6. Materyal + Aktivite 1 + Aktivite 2 notları aynı gün için ortalanmalı.

7. Ödev ve Sınav notları da aynı günlük ortalamaya dahil edilmeli.

8. Boş notlar hesaba katılmamalı.

9. Hiç not yoksa ortalama 0 olmamalı.

10. Tarih aralığı genel ortalaması günlük ortalamaların eşit ağırlıklı ortalaması olmalı.

11. Not olmayan günler genel ortalamaya dahil edilmemeli.

12. flutter test

13. flutter analyze

Mevcut çalışan özellikleri bozacak gereksiz refactor yapma.