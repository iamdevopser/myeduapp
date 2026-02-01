Sen Flutter Desktop (Windows) konusunda uzman, kıdemli (senior) bir yazılım geliştiricisisin.

Benden, Windows PC üzerinde çalışan, tamamen offline bir masaüstü uygulaması geliştirmeni istiyorum.
Uygulamanın adı: "MyEduApp"

==================================================
KULLANILACAK TEKNOLOJİLER
==================================================
- Flutter Desktop (Windows)
- Dart
- SQLite (sqflite veya drift)
- Local filesystem (dart:io)
- path_provider
- file_picker
- archive (ZIP yedekleme)
- pdf (PDF çıktı alma)
- flutter_localizations + intl (çoklu dil)

İnternet, cloud, API veya harici servis KULLANILMAYACAK.

==================================================
GENEL GEREKSİNİMLER
==================================================
- Uygulama %100 offline çalışmalı
- Tüm veriler kullanıcının bilgisayarında saklanmalı
- Uygulama kapatılsa bile veri kaybı olmamalı
- Windows masaüstü uyumlu olmalı
- Güvenli ve genişletilebilir mimari kullanılmalı

==================================================
1️⃣ ANA SAYFA – BAŞLANGIÇ EKRANI
==================================================

- Uygulama açıldığında büyük bir başlık göster:
  "MyEduApp'e Hoş Geldiniz"

- Altında iki aşamalı seçim alanı bulunmalı

--------------------------------------------------
AŞAMA 1: SINIF SEÇ / YÖNET
--------------------------------------------------

- Dropdown: "Sınıf Seç"
- Sınıflar kullanıcı tarafından:
  - Oluşturulabilir
  - Güncellenebilir
  - Silinebilir

- Yanında buton:
  "⚙ Sınıfları Yönet"

Sınıf silme uyarısı:
"Sınıfa ait tüm dersler ve içerikler var.
Silmek istiyor musunuz?"
[✔ Evet, her şeyi sil] [✖ Hayır, iptal]

--------------------------------------------------
AŞAMA 2: DERS SEÇ / YÖNET
--------------------------------------------------

- Dropdown: "Ders Seç"
- Sadece seçilen sınıfa ait dersler listelenir
- Sınıf seçilmeden pasif olur

- Yanında buton:
  "⚙ Dersleri Yönet"

Ders silme uyarısı:
"Bu derse ait içerikler mevcut.
Silmek istiyor musunuz?"
[✔ Evet, içerikleri sil] [✖ Hayır, iptal]

==================================================
2️⃣ DERS İÇERİK EKRANI
==================================================

- Seçilen sınıf ve ders üst kısımda net şekilde gösterilmeli
- Büyük bir "+ Ekle" butonu bulunmalı

==================================================
3️⃣ + EKLE BUTONU
==================================================

Kullanıcı şunları ekleyebilmeli:
- Dosya
- Klasör

Desteklenen dosyalar:
- PDF
- Word (.doc, .docx)
- PowerPoint (.ppt, .pptx)
- Ses (.mp3, .wav)
- Video (.mp4, .avi)

==================================================
4️⃣ GELİŞMİŞ İÇERİK ÖZELLİKLERİ
==================================================

🔁 SÜRÜKLE – BIRAK SIRALAMA
- İçerikler drag & drop ile sıralanabilmeli
- Sıralama bilgisi SQLite’ta saklanmalı

🔍 DERS İÇİ ARAMA
- Dosya adına göre anlık arama
- Etikete göre filtreleme

🧩 ETİKET (TAG) SİSTEMİ
- Her içerik için birden fazla etiket
- Etiket ekle / sil / düzenle
- Etiketler veritabanında tutulmalı

==================================================
5️⃣ YEDEKLEME VE GERİ YÜKLEME
==================================================

📦 TEK TIK YEDEK AL (ZIP)
- "Yedek Al" butonu
- Aşağıdakiler ZIP içine alınmalı:
  - SQLite veritabanı
  - Tüm dosyalar
- Kullanıcı kayıt konumunu seçebilmeli

☁️ MANUEL YEDEKTEN GERİ YÜKLE
- "Yedekten Geri Yükle" butonu
- Kullanıcı ZIP dosyası seçer
- Mevcut veriler üzerine yazılmadan önce uyarı gösterilir
- Geri yükleme sonrası uygulama otomatik yenilenir

==================================================
6️⃣ PDF ÇIKTI ALMA
==================================================

🖨 PDF ÇIKTI ÖZELLİĞİ
- Ders içeriğinin tamamı PDF olarak dışa aktarılabilmeli
- PDF içinde:
  - Sınıf adı
  - Ders adı
  - İçerik listesi
  - Etiketler
- Kullanıcı PDF kaydetme konumunu seçebilmeli

==================================================
7️⃣ GÜVENLİK
==================================================

🔐 ŞİFRE İLE UYGULAMA KİLİTLEME
- Uygulama açılışında opsiyonel şifre ekranı
- Şifre SQLite içinde hash’li şekilde saklanmalı
- Ayarlardan:
  - Şifre ekle
  - Şifre değiştir
  - Şifreyi devre dışı bırak

==================================================
8️⃣ ÇOKLU DİL DESTEĞİ
==================================================

🌍 ÇOKLU DİL (I18N)
- En az şu diller desteklensin:
  - Türkçe (varsayılan)
  - İngilizce
- Tüm metinler localization dosyalarından gelsin
- Ayarlar ekranından dil değiştirilebilsin
- Dil tercihi lokal olarak saklansın

==================================================
9️⃣ DOSYA SAKLAMA YAPISI
==================================================

/MyEduAppData/
   /Siniflar/
      /Sinif_Adi/
         /Ders_Adi/
            /Icerikler/

Dosyalar kopyalanmalı, orijinal dosyalara dokunulmamalı

==================================================
🔟 VERİTABANI (SQLite)
==================================================

TABLO: siniflar
- id
- ad
- olusturma_tarihi

TABLO: dersler
- id
- sinif_id
- ad
- sira
- olusturma_tarihi

TABLO: icerikler
- id
- ders_id
- ad
- tur
- dosya_yolu
- sira
- olusturma_tarihi

TABLO: etiketler
- id
- ad

TABLO: icerik_etiketleri
- icerik_id
- etiket_id

TABLO: ayarlar
- anahtar
- deger

==================================================
11️⃣ ÇIKTI VE DOKÜMANTASYON
==================================================

Aşağıdakileri üret:
1. Mimari açıklama
2. Tam klasör yapısı
3. pubspec.yaml
4. Flutter ekranları ve widget yapısı
5. SQLite şeması
6. Temiz, yorumlu, üretim seviyesinde kod
7. Windows build (.exe) alma adımları

==================================================
ÖNEMLİ KURALLAR
==================================================
- İnternet varsayma
- Cloud / API kullanma
- Kodlar modüler ve genişletilebilir olsun
- Bu uygulama kişisel eğitim içerik yönetimi içindir
