# MyEduApp — Öğrenci Paneli Tasarım ve Uygulama

## AMAÇ
Mevcut Öğretmen Paneli ile aynı MyEduApp tasarım dilini kullanan; öğrencinin ihtiyaçlarına göre sade, modern, responsive ve çoklu öğretmen/ders yapısını destekleyen bir Öğrenci Paneli oluştur.

KODLAMAYA BAŞLAMADAN ÖNCE mevcut Flutter projesini analiz et. Authentication, role-based routing, sidebar/navbar, theme, responsive yapı, öğrenci-öğretmen-sınıf ilişkileri ve mevcut veri modellerini incele. Mevcut çalışan sistemi bozma ve varsayım yaparak yeni mimari oluşturma.

## 1. TASARIM FELSEFESİ
Öğretmen Paneli: Yönet → Oluştur → Değerlendir → Raporla
Öğrenci Paneli: Görüntüle → Takip Et → Tamamla → Geri Bildirim Al

Öğrenci paneli öğretmen panelinin küçültülmüş kopyası olmamalı. Mevcut öğretmen panelindeki koyu lacivert sidebar, mavi primary renk, beyaz içerik, rounded card, typography, spacing, icon ve navbar tasarım dili korunmalı.

## 2. ÖĞRENCİ SIDEBAR
- Ana Sayfa
- Derslerim
- Akademik Planlar
  - Haftalık Ders Programım
- Ödevlerim
- Sınavlarım
- Performansım
- Devamsızlıklarım
- Dokümanlar
- Duyurular
- Profilim

Öğrenciye Öğrenci Ekle, Sınıf Ekle, Ders Platformu Oluştur, Rapor Oluştur, Sınıf Defteri, not girme, davranış kaydetme ve sınıf yönetimi gibi öğretmen işlemlerini gösterme.

## 3. ANA SAYFA
Üstte:
“Hoş geldin, [Öğrenci Adı]”
ve gerçek verilere göre kısa özet.

4 özet kartı:
- Derslerim
- Bekleyen Ödevler
- Yaklaşan Sınavlar
- Devamsızlık

Kartlar tıklanabilir olmalı ve gerçek verilerden beslenmeli.

Alt bölümler:
- Bugünkü Dersler
- Yaklaşan Ödevler
- Yaklaşan Sınavlar
- Son Duyurular

Bugünkü derslerde mümkünse saat, ders, öğretmen ve sınıf/grup göster.

## 4. ÇOKLU ÖĞRETMEN / DERS / SINIF
Öğrenci birden fazla öğretmene bağlı olabilir. Örneğin Matematik → Ali Öğretmen, Türkçe → Ayşe Öğretmen, Fen → Mehmet Öğretmen.

Tüm dersler tek dashboardda birleşmeli; ancak her ders, ödev, sınav ve duyuruda ilgili öğretmen açıkça gösterilmeli.

Örneğin:
Matematik
Denklem Çalışması
Ali Öğretmen
Son teslim: 3 Ekim

Öğretmenleri ayrı dashboardlara bölme.

Birden fazla sınıf/grup ilişkisi varsa mevcut veri modeline göre doğru ayır. Örneğin 8-A Matematik ile 8-B Robotik birbirine karışmamalı.

Gerekiyorsa ders/öğretmen filtreleri ekle, fakat gereksiz filtre kalabalığı oluşturma.

## 5. DERSLERİM
Öğrencinin bağlı olduğu tüm dersleri göster:
- ders adı
- öğretmen
- sınıf/grup
- gerekiyorsa ders saati

Ders detayında mevcut sistem destekliyorsa materyaller, ödevler, sınavlar ve duyurular gösterilebilir.

## 6. AKADEMİK PLANLAR
“Haftalık Ders Programım” bulunmalı. Öğretmen tarafındaki mevcut Weekly Schedule veri ve bileşenlerini mümkün olduğunca yeniden kullan. Öğrenci sadece kendi programını görmeli.

## 7. ÖDEVLERİM
Tümü / Bekleyen / Tamamlanan / Geciken filtreleri gerekiyorsa eklenebilir.

Her kayıtta:
- ders
- öğretmen
- ödev
- teslim tarihi
- durum

göster.

## 8. SINAVLARIM
Yaklaşan sınavlar, geçmiş sınavlar ve mevcut sınav sonuçları gösterilmeli. Ders, öğretmen, sınav, tarih ve sonuç bilgileri kullanılmalı.

## 9. PERFORMANSIM
Öğrenci yalnızca kendi performansını görmeli. Ders bazında performans, ödev, sınav ve mevcut değerlendirmeler gösterilebilir.

Mevcut not sistemi:
- 1–10 = not
- __ = not verilmedi
- a = devamsız

Öğrenci UI'ında __ → “Henüz not girilmedi”, a → “Devamsız” gösterilebilir. `a` ortalamaya dahil edilmemeli.

## 10. DEVAMSIZLIKLARIM
Öğrenci kendi devamsızlık kayıtlarını görebilmeli. Tarih, ders, öğretmen ve durum gösterilebilir. Başka öğrencilerin kayıtları görünmemeli.

## 11. DAVRANIŞLAR / GELİŞİM
Öğretmen tarafındaki Davranışlar sistemi öğrenciye yönetim ekranı olarak gösterilmemeli.

Mevcut sistemde öğrenciye görünür geri bildirim desteği varsa Performansım veya Gelişimim içinde göster:
Olumlu:
- Aktif katılım
- İş birliği
- Saygılı iletişim

Geliştirilmesi gereken:
- Derste konuşma
- Dikkat dağıtma

Öğretmenin her davranış kaydını otomatik olarak öğrenciye gösterme. Visibility/publish/visibleToStudent benzeri mevcut yapı varsa kullan; yoksa mevcut mimariye uygun şekilde gelecekte bu ayrımı destekleyecek yapı oluştur.

## 12. DOKÜMANLAR
Öğrencinin erişebildiği PDF, ders materyali, çalışma kağıdı ve öğretmen belgelerini göster. Mümkünse dosya adı, ders, öğretmen ve tarih bilgilerini göster.

## 13. DUYURULAR
Öğrencinin yetkili olduğu duyuruları göster. Öğretmen, ders, başlık, tarih ve içerik bilgileri kullanılabilir.

## 14. PROFİLİM
Mevcut öğrenci modelindeki ad, soyad, öğrenci numarası, sınıf, e-posta ve varsa profil fotoğrafını göster. Öğrenci yetkisi olmayan alanları değiştirememeli.

## 15. GÜVENLİK
Öğrenci başka öğrencilerin not, ödev, sınav, devamsızlık, davranış veya kişisel bilgilerini görememeli.

Frontend'de gizlemek yeterli değildir. Mevcut backend/database authorization ve security rules yapısını analiz et ve gerekiyorsa düzelt.

## 16. RESPONSIVE
Desktop:
- mevcut öğretmen paneline benzer sidebar + navbar
- geniş dashboard
- kart gridleri

Tablet:
- uygun daraltılmış sidebar
- 2 kolonlu kartlar

Mobil:
- 1 kolon
- mevcut uygulamanın uygun navigation yaklaşımı

RenderFlex, horizontal overflow ve text overflow olmamalı.

## 17. REUSABLE COMPONENTLER
Mevcut reusable widgetları araştır ve kullan. Gerekirse StudentDashboardHeader, StudentSummaryCard, TodayLessonsCard, UpcomingAssignmentsCard, UpcomingExamsCard, AnnouncementsCard, StudentCourseCard, StudentTeacherBadge gibi bileşenler oluştur. Aynı işi yapan mevcut widget varsa tekrar oluşturma.

## 18. MOCK DATA
Production ekranında hard-coded öğrenci/öğretmen/ders/ödev bilgisi bırakma. Gerçek backend/database verilerini kullan.

## 19. ÖNCE ANALİZ
Önce şu yapıların mevcut kodlarını bul ve incele:
- Öğretmen dashboard
- Öğrenci ekranları
- authentication
- role-based routing
- sidebar/navbar
- theme
- responsive helperlar
- Student
- Teacher
- Class
- Assignment
- Exam
- Performance
- Attendance
- Announcement
- Document
- Academic Plan

Sonra mevcut mimariye entegre ederek geliştir.

## 20. TEST
Test et:
- öğrenci login
- dashboard
- tek öğretmen
- birden fazla öğretmen
- birden fazla ders
- birden fazla sınıf/grup varsa doğru gösterim
- ödevler
- sınavlar
- performans
- devamsızlık
- haftalık ders programı
- dokümanlar
- duyurular
- profil
- desktop/tablet/mobil
- yetkisiz öğrenci verisine erişim

## 21. TAMAMLAMA KRİTERİ
Öğrenci paneli:
- Öğretmen Paneli ile aynı MyEduApp branding'ine sahip olmalı.
- Daha sade ve öğrenci odaklı olmalı.
- Çoklu öğretmenleri desteklemeli.
- Çoklu ders/sınıf ilişkilerini desteklemeli.
- Gerçek verileri kullanmalı.
- Öğrenci yalnızca kendi verilerine erişebilmeli.
- Responsive çalışmalı.
- Authentication ve Öğretmen Paneli bozulmamalı.

Ana sayfa temel yapısı:
Hoş geldin, [Ad]
[Derslerim] [Bekleyen Ödevler] [Yaklaşan Sınavlar] [Devamsızlık]
[Bugünkü Dersler] [Yaklaşan Ödevler]
[Yaklaşan Sınavlar] [Son Duyurular]

## 22. SON RAPOR
İş sonunda kısa rapor ver:
1. Analiz edilen dosyalar
2. Değiştirilen dosyalar
3. Oluşturulan componentler
4. Dashboard yapısı
5. Çoklu öğretmen yaklaşımı
6. Çoklu sınıf/ders yaklaşımı
7. Yetkilendirme/veri izolasyonu
8. Responsive davranış
9. Test sonuçları
10. Kalan riskler

KODLAMAYA BAŞLAMADAN ÖNCE ANALİZ ET. VARSAYIM YAPMA. MEVCUT ÇALIŞAN SİSTEMİ BOZMA.
