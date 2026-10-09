# ACTION — DERS OLUŞTURUCU HATALARI VE KURS/ÜNİTE SEÇİM DÜZELTMELERİ

Bu action mevcut Ders Oluşturucu ekranındaki belirlenen hataları düzeltmek
ve mevcut Ders Platformu mimarisiyle uyumlu hale getirmek içindir.

project.mdc kuralları aynen geçerlidir.

ÖNEMLİ:
Mevcut çalışan sistemi yeniden tasarlama.
Mevcut model, provider, repository, service, database ve UI componentlerini
öncelikle bul ve mümkün olduğunca aynen kullan.
Sadece aşağıdaki sorunları düzelt.
Gereksiz refactor yapma.

---

# 1. DERS EKLE / KURS EKLE PANEL HATASI

Mevcut ekranda "Ders Ekle" butonuna basıldığında yanlışlıkla
"Kurs Ekle" paneli açılıyor.

Bu hatayı düzelt.

"Ders Ekle" butonu gerçekten Ders Ekle işlemini açmalı.

"Kurs Ekle" butonu gerçekten Kurs Ekle işlemini açmalı.

Buton → dialog/panel eşleşmelerini kontrol et.

Mevcut CRUD işlemlerini yeniden oluşturma.
Yanlış callback, handler, dialog veya state bağlantısını düzelt.

---

# 2. SAĞ PANEL SIRALAMASI

Sağ taraftaki yönetim panelindeki bölümlerin sırası tam olarak:

1. Kurs Ekle
2. Ders Ekle
3. Ünite Ekle
4. Konu Ekle

olmalı.

Mevcut:

Ders Ekle
Kurs Ekle
Ünite Ekle
Konu Ekle

sırasını değiştir.

Bu yalnızca UI sıralamasıdır.
Butonların mevcut işlevlerini koru.

---

# 3. KURS EKLE PANELİ

"Kurs Ekle" panelini mevcut ekran görüntüsündeki hatalı alanlarla
uyumlu olacak şekilde düzelt.

## 3.1 İlk alan

Mevcut:

"Ders adı"

yerine:

"Kurs Adı"

yazmalı.

Bu alan serbest metin olmamalı.

Aşağıdaki kurslardan biri seçilebilmeli:

- Matematik
- Fizik
- Kimya
- Biyoloji
- Bilgisayar
- İngilizce
- Türkçe

Seçim mevcut Design System'deki uygun dropdown/select componentiyle yapılmalı.

Yeni bir component oluşturma.

## 3.2 Sınıf

Mevcut "Kurs sınıfı" alanında:

1
2
3
4
5
6
7
8
9
10
11
12

sınıfları seçilebilir olmalı.

Ekranda görünen değerler kullanıcı açısından anlaşılır olmalı.

Mevcut veri modelindeki sınıf alanıyla uyumlu şekilde kaydet.

Mevcut sınıf kayıtları varsa gereksiz yere silme veya yeniden oluşturma.

## 3.3 Akademik Yıl

" Eğitim yılı " alanını akademik yıl seçimine dönüştür.

Seçilebilir değerler:

2026–27
2027–28
2028–29
2029–30
2030–31
2031–32
2032–33
2033–34
2034–35
2035–36
2036–37
2037–38
2038–39
2039–40
2040–41
2041–42
2042–43
2043–44
2044–45
2045–46
2046–47
2047–48
2048–49
2049–50

Toplam 24 akademik yıl seçilebilir olmalı.

Görüntü formatı:

2026–27

şeklinde olmalı.

Mevcut database alanının desteklediği formatı önce kontrol et.
Gerekirse mevcut yapıyla uyumlu şekilde sakla.

---

# 4. KURS KAYDI

Kurs kaydedilirken en azından şu bilgiler doğru ilişkilendirilmeli:

Kurs Adı
+
Sınıf
+
Akademik Yıl
+
Varsa mevcut kurs resmi

Örnek:

Türkçe
7. Sınıf
2026–27

Bu kayıt daha sonra Ders Platformunda doğru kurs olarak
görülebilmeli.

Aynı kurs + sınıf + akademik yıl kombinasyonu için gereksiz
duplicate kayıt oluşturma.

Mevcut duplicate kontrol mekanizması varsa onu kullan.

---

# 5. ÜNİTE → KONU FİLTRELEME HATASI

Mevcut önemli hata:

Bir ünite seçildiğinde o üniteye ait konular yerine
diğer ünitelerde bulunan konular da listeleniyor.

Bunu düzelt.

Konu listesi yalnızca seçilen Ünite ID'sine bağlı konuları göstermeli.

Mantık:

Seçilen Kurs
→ Seçilen Ünite
→ SADECE bu Üniteye bağlı Konular

Örnek:

Ünite 1 açılırsa:

- Ünite 1 / Konu A
- Ünite 1 / Konu B
- Ünite 1 / Konu C

gösterilmeli.

Ünite 2'nin konuları kesinlikle gösterilmemeli.

Ünite 2 açılırsa yalnızca:

- Ünite 2 / Konu A
- Ünite 2 / Konu B

gösterilmeli.

---

# 6. KONU FİLTRELEMEDE VERİ İLİŞKİSİ

Önce mevcut Konu modelini ve Ünite-Konu ilişkisini bul.

Filtreleme mümkünse:

unitId == selectedUnitId

mantığıyla yapılmalı.

Eğer mevcut sistemde farklı bir ilişki alanı kullanılıyorsa
mevcut yapıya uy.

Konu listesini sadece isim üzerinden filtreleme.

Yanlışlıkla tüm konuları döndüren mevcut query/provider/repository
mantığını düzelt.

Yeni repository/service oluşturma.

---

# 7. SEÇİM STATE TEMİZLİĞİ

Ünite değiştirildiğinde:

- önceki Konu seçimi temizlenmeli,
- konu listesi yeni Üniteye göre yeniden yüklenmeli,
- eski Ünitenin Konusu gösterilmemeli.

Örneğin:

Ünite 1
→ Konu A seçili

Ünite 2 seçildiğinde:

Konu A seçili kalmamalı.

Konu seçimi sıfırlanmalı ve yalnızca Ünite 2 konuları gösterilmeli.

Benzer şekilde üst seviye seçim değişikliklerinde alt seçimler
eski bağlamdan taşınmamalı.

---

# 8. KURS / ÜNİTE / KONU İLİŞKİSİ

Yeni ve mevcut yapı aşağıdaki mantığı korumalı:

Ders
→ Kurs
→ Sınıf
→ Akademik Yıl
→ Ünite
→ Konu
→ Doküman / İçerik

Kurs seçildiğinde yalnızca seçilen kursa bağlı üniteler gösterilmeli.

Ünite seçildiğinde yalnızca seçilen üniteye bağlı konular gösterilmeli.

Konu seçildiğinde yalnızca seçilen konuya bağlı mevcut
doküman/içerik gösterilmeli.

---

# 9. MEVCUT BLOK SİSTEMİ

Aşağıdaki mevcut blok türlerine dokunma:

- Metin
- PDF
- Sunum
- Word
- Görsel
- Video
- Ses
- Web Link
- Ödev
- Soru
- Sınav

Mevcut içerik oluşturma ve sürükle-bırak davranışını değiştirme.

Sadece doğru Konu seçildiğinde doğru içeriğin açılmasını sağla.

---

# 10. MEVCUT VERİLER

Mevcut:

- Dersler
- Kurslar
- Sınıflar
- Üniteler
- Konular
- Dokümanlar
- İçerikler

silinmemeli.

Migration gerekiyorsa mevcut verileri koru.

Mevcut kayıtların ilişkilerini bozma.

---

# 11. UI KORUMA

Mevcut MyEduApp Design System'i koru.

Mevcut:

- renkler
- typography
- spacing
- dropdown
- button
- dialog
- icon
- navigation

componentlerini kullan.

Yeni tasarım sistemi oluşturma.

Sadece istenen alan isimleri, seçim seçenekleri,
buton sırası ve filtreleme davranışını düzelt.

---

# 12. KAPSAM

Bu action yalnızca:

1. Ders Ekle / Kurs Ekle yanlış panel hatası
2. Sağ panel buton sırası
3. Kurs Ekle formu
4. Kurs seçenekleri
5. Sınıf seçenekleri
6. Akademik yıl seçenekleri
7. Ünite → Konu filtreleme
8. Seçim state temizliği

içindir.

Öğrenci Platformuna dokunma.

Raporlama sistemine dokunma.

PDF/Excel sistemine dokunma.

İlgisiz refactor yapma.

Yeni dependency ekleme.

---

# 13. KABUL KRİTERLERİ

- [ ] Ders Ekle butonu Ders Ekle panelini açıyor.
- [ ] Kurs Ekle butonu Kurs Ekle panelini açıyor.
- [ ] Sağ panel sırası: Kurs Ekle → Ders Ekle → Ünite Ekle → Konu Ekle.
- [ ] Kurs Ekle panelinde "Kurs Adı" yazıyor.
- [ ] Kurs Adı seçim alanında Matematik bulunuyor.
- [ ] Fizik bulunuyor.
- [ ] Kimya bulunuyor.
- [ ] Biyoloji bulunuyor.
- [ ] Bilgisayar bulunuyor.
- [ ] İngilizce bulunuyor.
- [ ] Türkçe bulunuyor.
- [ ] Sınıf alanında 1–12 arası sınıflar seçilebiliyor.
- [ ] Akademik yıl alanında 2026–27 bulunuyor.
- [ ] Akademik yıl alanında 2049–50 bulunuyor.
- [ ] 2026–27 ile 2049–50 arasındaki tüm akademik yıllar seçilebiliyor.
- [ ] Kurs kaydı doğru kurs + sınıf + akademik yıl ilişkisiyle oluşturuluyor.
- [ ] Ünite seçildiğinde yalnızca o üniteye bağlı konular gösteriliyor.
- [ ] Başka ünitelerin konuları gösterilmiyor.
- [ ] Ünite değiştirildiğinde eski konu seçimi temizleniyor.
- [ ] Kurs değiştirildiğinde eski ünite/konu state'i taşınmıyor.
- [ ] Mevcut içerik/blok sistemi çalışmaya devam ediyor.
- [ ] Mevcut veriler korunuyor.
- [ ] Mevcut Design System korunuyor.
- [ ] Gereksiz dosya/dependency/refactor yapılmıyor.