# MyEduApp — Sekreter Hesabı / FAZ 5
## Duyuru Yönetimi — Analiz + Uygulama Talimatı

> Proje: MyEduApp  
> Faz 4 sonucu: PASS — 119/119 test  
> Kural: Önce analiz et, sonra minimum sürdürülebilir değişiklikleri uygula.

## 1. Amaç

Sekreter hesabına duyuru yönetimi ekle:
- Duyuru listesi
- Yeni duyuru
- Düzenleme
- Detay
- Yayınlama / yayından kaldırma
- Hedef kitle
- Arama / filtreleme
- Responsive Web/Mobile
- Authorization
- Localization
- JSON Sync
- Gerekli migration
- Testler

Mevcut Teacher, Student ve Secretary akışlarını bozma.

## 2. Zorunlu Ön Analiz

Kod yazmadan önce tüm projede aşağıdakileri ara:
- `ogrenci_duyurular`
- `duyuru`, `duyurular`
- `announcement`, `announcements`
- notification/notifications
- öğrenci portalı duyuru ekranları
- öğretmen duyuru ekranları
- duyuru modelleri/servisleri
- hedef kitle, sınıf, şube ilişkileri
- yayın durumu ve tarih alanları

Ayrıca `AppDatabase`, `AppState`, `AuthorizationService`, `SecretaryNavigation`, `SecretaryTabWorkspace`, `DatabaseSyncService` ve localization yapısını incele.

**Özellikle `ogrenci_duyurular` mevcut olduğu için, mevcut yapıyı anlamadan yeni bir `duyurular` tablosu oluşturma.** Mevcut yapı yeterliyse onu genişlet.

## 3. Sekreter Navigation

Mevcut Secretary navigation mimarisine uygun olarak:

**Duyurular**
- Duyuru Listesi
- Yeni Duyuru

ekle.

Paralel yeni navigation sistemi oluşturma.

## 4. Duyuru Verisi

Mevcut model varsa kullan. Yetersizse minimum olarak:
- id
- başlık
- içerik
- oluşturulma tarihi
- yayın tarihi
- güncellenme tarihi
- durum
- hedef kitle

desteklenmeli.

Durum mevcut sistemdeki yapıya uyulmalı; yoksa minimum:
- Taslak
- Yayında
- Yayından kaldırıldı

## 5. Duyuru Listesi

Masaüstünde tablo, mobilde Card/ListTile kullanılabilir.

Göster:
- Başlık
- Hedef kitle
- Durum
- Yayın tarihi
- Güncelleme tarihi

Arama:
- başlık
- içerik

Filtre:
- durum
- hedef kitle
- gerekiyorsa tarih aralığı

## 6. Oluşturma ve Düzenleme

Yeni duyuru oluşturulabilmeli:
- Başlık
- İçerik
- Hedef kitle
- Durum

Varsayılan durum tercihen Taslak.

Boş başlık/içerik kabul edilmemeli.

Taslak düzenlenebilmeli. Yayındaki duyuru için mevcut sistemdeki davranışı koru; gereksiz yeni iş kuralı icat etme.

## 7. Hedef Kitle

Mevcut yapıyı analiz ederek minimum:
- Tüm okul
- Sınıf
- Şube

destekle.

Mevcut sınıf/şube ID'lerini kullan; string kopyalayarak yeni ilişki kurma.

Çoklu hedefleme mevcut yapıyla kolay ve sürdürülebilir şekilde desteklenebiliyorsa ekle; gereksiz karmaşıklık oluşturma.

## 8. Yayınlama

Taslak → Yayınla.

Yayında → Yayından Kaldır.

Durum değişiminde yeni kayıt oluşturma; mevcut duyuruyu update et.

## 9. Silme

Mevcut authorization politikasını incele.

Silme güvenli ve politika açısından uygunsa uygulanabilir. Değilse yayından kaldırma yeterlidir.

Kritik/geri döndürülemez silme sistemi oluşturma.

Final raporunda kararı açıkça belirt.

## 10. Öğrenci Portalı

Mevcut öğrenci portalı duyuru akışını bozma.

Sekreterin oluşturduğu/yayınladığı duyuruların mevcut mekanizma üzerinden görünmesi gerekiyorsa minimum entegrasyonu yap.

Bu fazda yeni portal tasarımı, login değişikliği veya notification sistemi yapma.

Mevcut okundu/okunmadı sistemi varsa koru; yoksa yeni sistem kurmak zorunda değilsin.

## 11. Authorization

`AuthorizationService` kullan.

Gerekli yetenekleri ekle:
- `canViewAnnouncements`
- `canCreateAnnouncement`
- `canEditAnnouncement`
- `canPublishAnnouncement`
- `canUnpublishAnnouncement`
- gerekiyorsa `canDeleteAnnouncement`

Sekreter görüntüleme, oluşturma, düzenleme, yayınlama ve yayından kaldırma yapabilmeli.

Öğretmen/öğrenci yetkilerini gereksiz değiştirme.

## 12. Database / Migration

Önce `ogrenci_duyurular` yapısını analiz et.

Yeni tablo yalnızca gerçekten gerekiyorsa oluştur.

Değişiklik gerekiyorsa migration ekle. Mevcut duyurular, hedefler ve öğrenci portalı davranışı korunmalı.

Faz 4 sonunda DB v29'dur. Değişiklik gerekiyorsa v30 kullanılabilir; migration gerekmiyorsa gereksiz schema bump yapma.

## 13. JSON Sync

`DatabaseSyncService` yapısını incele.

Duyuru tabloları/ilişkileri değişirse export/import ve schema version desteğini güncelle.

## 14. Responsive / UI

Mevcut:
- AppShell
- Navbar
- Sidebar
- AppSpacing
- Card
- Button
- Input
- Dialog
- localization

yapılarını kullan.

Yeni tema oluşturma.

Mobilde form alanları dikey ve hedef kitle seçimleri kullanılabilir olmalı.

Loading/error state ve mevcut snackbar/feedback mekanizmasını kullan.

## 15. Localization

TR/EN localization sistemini kullan.

En az:
- Duyurular
- Duyuru Listesi
- Yeni Duyuru
- Duyuru Detayı
- Başlık
- İçerik
- Hedef Kitle
- Tüm Okul
- Sınıf
- Şube
- Taslak
- Yayında
- Yayından Kaldırıldı
- Yayınla
- Yayından Kaldır
- Düzenle
- Sil
- Kaydet
- Arama
- Filtre
- Başlangıç Tarihi
- Bitiş Tarihi

Hardcoded metinleri mümkün olduğunca localization'a taşı.

## 16. Testler

Database:
- oluşturma
- güncelleme
- durum değişimi
- yayınlama
- yayından kaldırma
- hedef kitle
- mevcut duyuruların korunması

Service:
- list
- search
- filter
- create
- update
- publish
- unpublish

Authorization:
- secretary view/create/edit/publish/unpublish
- yetkisiz delete/policy

Regression:
`flutter test`

Faz 4'teki 119 testin tamamı geçmeli.

## 17. Manuel Test

Gerçek uygulamada:
1. Sekreter login
2. Duyuru listesi
3. Mevcut duyurular
4. Taslak oluştur
5. Düzenle
6. Yayınla
7. Yayından kaldır
8. Arama
9. Durum/hedef filtreleri
10. Sınıf hedefli duyuru
11. Şube hedefli duyuru
12. Öğrenci portalında görünüm
13. Kapat/aç sonrası kalıcılık
14. Mobil/dar ekran
15. Teacher login
16. Student login
17. Faz 2/3/4 sekreter ekranları

## 18. Faz Sınırı

YAPMA:
- Veli login/portal
- Push notification
- SMS
- E-posta gönderim sistemi
- Bildirim merkezi
- Gelişmiş raporlama
- Öğretmen yönetimi
- Academic Plans
- Weekly Schedule
- Öğrenci silme approval
- Faz 2.5 öğrenci login değişiklikleri
- Global öğrenci şifresi değişikliği
- Cloud auth/Firebase/REST
- Büyük UI redesign

Duyuru ile ilgili öğrenci portalı entegrasyonu yalnızca minimum düzeyde olabilir.

## 19. Mimari Kural

Aynı işi yapan ikinci tablo/model/service/repository/screen oluşturma.

Özellikle mevcut:
- `ogrenci_duyurular`
- `AppDatabase`
- `StudentPortalService`
- `AppState`
- `AuthorizationService`
- `DatabaseSyncService`

yapılarını dikkatle incele ve mevcut mimariye entegre ol.

## 20. Uygulama Sırası

1. Mevcut duyuru tablolarını/sorgularını bul.
2. `ogrenci_duyurular` kullanımını tüm projede ara.
3. Öğrenci portalı akışını analiz et.
4. Hedefleme modelini analiz et.
5. DB değişikliği gerekip gerekmediğini belirle.
6. Gerekliyse migration.
7. Model/service.
8. Authorization.
9. Navigation.
10. Liste.
11. Oluşturma/düzenleme.
12. Yayınlama/yayından kaldırma.
13. Arama/filtre.
14. Responsive.
15. Localization.
16. JSON Sync.
17. Testler.
18. `flutter test`.

## 21. Final Rapor

Aşağıdaki formatta rapor ver:

# FAZ 5 STATUS

**PASS / FAIL**

## Ön Analiz
Mevcut duyuru altyapısı; özellikle `ogrenci_duyurular`, öğrenci portalı ve hedefleme nasıl çalışıyordu?

## Database
Hangi tablo/alan değişti? Yeni tablo varsa neden?

## Migration
Schema versiyonu ve gerekçesi.

## Duyuru Listesi
Yapılanlar.

## Duyuru Oluşturma
Yapılanlar.

## Düzenleme
Yapılanlar.

## Yayınlama
Yapılanlar.

## Hedef Kitle
Desteklenen hedefler.

## Filtreleme
Yapılanlar.

## Student Portal
Mevcut akış nasıl korundu?

## Authorization
Eklenen yetkiler.

## Responsive
Web/Mobile durumu.

## JSON Sync
Değişiklikler.

## Localization
Eklenenler.

## Eklenen / Değiştirilen Dosyalar
Liste.

## Test Sonucu
`flutter test`
`XXX passed`
`0 failed`

## Manuel Test Gerektirenler
Liste.

## Riskler
Liste.

## Faz 6'ya Kalanlar
Öneriler.

## 22. Son Kural

**Önce analiz, sonra uygulama.**

Özellikle `ogrenci_duyurular` yapısını anlamadan yeni duyuru tablosu oluşturma.

Mevcut öğrenci portalını bozma.

Minimum sürdürülebilir değişikliklerle ilerle.

Faz 5 dışında hiçbir özelliği genişletme.

Teacher, Student, Secretary, Faz 2, Faz 2.5, Faz 3 ve Faz 4 davranışlarını koru.
