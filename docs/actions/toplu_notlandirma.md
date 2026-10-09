# MyEduApp – Toplu ve Grup Notlandırma

## 1. AMAÇ

Mevcut notlandırma sistemine iki yeni işlem ekle:

1. Birden fazla seçilen öğrenciye aynı notu verme.
2. Sınıftaki tüm öğrencilere aynı notu verme.

Mevcut tek öğrenci notlandırma sistemi korunmalıdır.

---

## 2. TEMEL KURAL – MİNİMUM MALİYET

ÖNCE mevcut notlandırma, ScoreDropdown, öğrenci listesi ve database save mekanizmasını analiz et.

SONRA yalnızca gerekli dosyalarda minimum değişiklik yap.

Kesinlikle:

- Gereksiz refactor yapma.
- Çalışan kodu yeniden yazma.
- Yeni architecture oluşturma.
- Duplicate not kayıt sistemi oluşturma.
- Yeni package ekleme.
- Gereksiz database migration yapma.
- İlgisiz dosyalara dokunma.
- Backup/restore sistemine dokunma.

Mevcut mekanizmalar mümkün olduğunca yeniden kullanılmalıdır.

---

# 3. GRUP OLARAK NOT VERME

Öğretmen öğrenci listesinden birden fazla öğrenci seçebilmelidir.

Örnek:

☑ Öğrenci A
☑ Öğrenci B
☑ Öğrenci C
☐ Öğrenci D
☐ Öğrenci E

Ardından:

"Seçilenlere Not Ver"

işlemi kullanılmalıdır.

Öğretmen mevcut ScoreDropdown üzerinden bir not seçer:

10
9
8
7
6
5
4
3
2
1
—

Seçilen öğrencilerin tamamına aynı not uygulanmalıdır.

Örneğin:

A → 9
B → 9
C → 9

D ve E kesinlikle değiştirilmemelidir.

---

# 4. TÜM ÖĞRENCİLERE NOT VERME

Öğretmen "Tümünü Seç" seçeneğini kullanarak sınıftaki tüm öğrencileri seçebilmelidir.

Örneğin:

Tümünü Seç
→ Aktivite 1
→ 10

sonucunda bütün öğrencilerin Aktivite 1 notu 10 olmalıdır.

Bu işlem de grup notlandırması ile aynı mevcut save mekanizmasını kullanmalıdır.

İki ayrı not kayıt sistemi oluşturma.

---

# 5. HANGİ NOT KOLONUNA UYGULANACAĞI

Toplu not işlemi aktif/seçili not kolonu üzerinden yapılmalıdır.

Örnek:

Aktivite 2 seçili:

Seçilen öğrenciler
→ Aktivite 2
→ 9

yalnızca Aktivite 2'yi değiştirmelidir.

Materyal seçili:

Seçilen öğrenciler
→ Materyal
→ 8

yalnızca Materyal notunu değiştirmelidir.

Başka kolonlardaki notlar kesinlikle değiştirilmemelidir.

---

# 6. PERFORMANS

Performans tablosundaki mevcut yapı korunmalıdır:

Öğrenci | Materyal | Aktivite 1 | Aktivite 2 | ...

Toplu not verme:

- Materyal
- Aktivite 1
- Aktivite 2
- Aktivite 3
- ...

için çalışmalıdır.

Aktivite 1 sabit kolon olma özelliğini korumalıdır.

Dinamik aktivite kolonları için de aynı toplu notlandırma kullanılmalıdır.

---

# 7. ÖDEV VE SINAV

Mevcut Ödevler ve Sınavlar menülerindeki notlandırma sistemi korunmalıdır.

Mevcut mimari buna uygunsa toplu/grup notlandırma burada da kullanılmalıdır.

Aynı ScoreDropdown ve aynı mevcut database save mekanizması kullanılmalıdır.

Ödev/Sınav için yeni ayrı bir not sistemi oluşturma.

---

# 8. SCORE DROPDOWN

Mevcut `ScoreDropdown` kullanılmalıdır.

Yeni dropdown/component oluşturma.

Mevcut davranış korunmalıdır:

10
9
8
7
6
5
4
3
2
1
—

Dropdown overlay/floating olarak açılmalıdır.

Tablonun yüksekliğini değiştirmemelidir.

---

# 9. DATABASE KAYIT GÜVENLİĞİ

TOPLU NOTLANDIRMA SIRASINDA EN ÖNEMLİ KURAL:

Verilen hiçbir not yalnızca UI/state içinde bırakılmamalıdır.

Her seçilen öğrenci için mevcut database/repository save mekanizması kullanılmalıdır.

Örneğin 4 öğrenci seçildiyse:

Öğrenci 1 → save
Öğrenci 2 → save
Öğrenci 3 → save
Öğrenci 4 → save

işlemleri gerçekten database'e yazılmalıdır.

Database kayıt işlemi başarıyla tamamlanmadan toplu işlem başarılı kabul edilmemelidir.

Bir veya daha fazla kayıt başarısız olursa:

- sessizce başarılı gösterme
- kullanıcıya uygun hata bildir
- başarıyla kaydedilmiş kayıtları bozma

Mevcut auto-save mekanizması varsa onu kullan.

Yeni kayıt sistemi oluşturma.

---

# 10. UI SEÇİMİ

Mevcut UI tasarımına en az müdahale eden çözüm kullanılmalıdır.

Öğrenci satırlarında checkbox kullanılabilir.

Tablonun üst kısmında uygun şekilde:

- Tümünü Seç
- Seçimi Temizle
- Seçilenlere Not Ver

işlemleri bulunabilir.

Mevcut tasarımda daha uygun bir seçim mekanizması varsa onu tercih et.

Yeni büyük bir UI sistemi oluşturma.

---

# 11. SEÇİM DURUMU

Toplu işlem tamamlandıktan sonra seçili öğrencilerin seçimi temizlenebilir.

Ama:

- Notların kendisi temizlenmemelidir.
- Database kayıtları korunmalıdır.
- UI güncel notları göstermelidir.

Kullanıcı yeni bir grup seçerek tekrar toplu not verebilmelidir.

---

# 12. VERİ KORUMA

Toplu not işlemi yalnızca:

SEÇİLEN ÖĞRENCİLER
+
SEÇİLEN NOT KOLONU

üzerinde işlem yapmalıdır.

Kesinlikle:

- başka öğrencilerin notlarını değiştirme
- başka kolonları değiştirme
- öğrenci kayıtlarını silme
- sınıf listesini değiştirme
- not kolonlarını silme
- geçmiş notları silme
- backup/restore verisini değiştirme

yapılmamalıdır.

---

# 13. TARİH

Toplu olarak verilen bütün notlar mevcut tekli not verme sisteminde kullanılan aynı tarih mekanizmasıyla kaydedilmelidir.

Yeni ve farklı bir tarih sistemi oluşturma.

Toplu verilen notların raporlarda normal notlardan hiçbir farkı olmamalıdır.

Dolayısıyla toplu verilen notlar:

- günlük ortalamaya
- tarih aralığı ortalamasına
- detaylı rapora

normal notlar gibi dahil edilmelidir.

---

# 14. RAPOR UYUMLULUĞU

Toplu verilen notlar raporda normal not olarak görünmelidir.

Örneğin:

09.09.2026 | Aktivite | Grup çalışması | 9

şeklinde mevcut raporlama sistemi tarafından gösterilmelidir.

Toplu verilmiş olması raporda özel veya farklı bir not türü oluşturmamalıdır.

---

# 15. TEST

Minimum gerekli testleri ekle/güncelle.

Test senaryoları:

### Grup

1. 3 öğrenci seç.
2. Aktivite 1 seç.
3. 9 ver.
4. Yalnızca seçilen 3 öğrencinin notu 9 olmalı.

### Tüm sınıf

5. Tüm öğrencileri seç.
6. Materyal seç.
7. 8 ver.
8. Tüm öğrencilerin Materyal notu 8 olmalı.

### Kolon güvenliği

9. Aktivite 2 seç.
10. 10 ver.
11. Materyal ve Aktivite 1 notları değişmemeli.

### Mevcut notların korunması

12. Seçilmeyen öğrencilerin mevcut notları değişmemeli.

### Database

13. Toplu not ver.
14. Sayfadan çık.
15. Tekrar gir.
16. Notların tamamı korunmalı.

### Navigation

17. Toplu not ver.
18. Performans → Ödevler → Sınavlar → Performans geçişi yap.
19. Notlar korunmalı.

### Rapor

20. Toplu verilen notların günlük ve tarih aralığı ortalamasına dahil olduğu doğrulanmalı.

### Hata

21. Save hatası oluştuğunda işlem sessizce başarılı kabul edilmemeli.

Sonunda:

flutter test

flutter analyze

çalıştır.

---

# 16. UYGULAMA STRATEJİSİ

Önce mevcut şu yapıları analiz et:

- Performans öğrenci tablosu
- mevcut öğrenci seçim/listeme yapısı
- ScoreDropdown
- mevcut tekli not save fonksiyonu
- repository/database save fonksiyonu
- Ödevler
- Sınavlar

Sadece gerekli dosyaları değiştir.

Mevcut tekli notlandırma fonksiyonunu mümkün olduğunca yeniden kullan.

Örneğin mevcut bir:

saveStudentScore(...)

fonksiyonu varsa toplu işlemi bunun üzerinden kur.

Aynı save mantığını ikinci kez yazma.

Yeni package ekleme.

Database migration yapmadan çözülebiliyorsa migration yapma.

Backup/restore sistemine dokunma.

İşlem sonunda değiştirilen dosyaları ve kısa gerekçelerini raporla.