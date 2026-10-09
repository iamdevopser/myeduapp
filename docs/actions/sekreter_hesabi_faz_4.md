# MyEduApp — Sekreter Hesabı / FAZ 4
## Devamsızlık Yönetimi — Analiz + Uygulama Talimatı

> Proje: MyEduApp  
> Teknoloji: Flutter  
> Faz 3 sonucu: PASS — 113/113 test  
> Önce analiz et, sonra minimum sürdürülebilir değişiklikleri uygula.

---

# 1. AMAÇ

MyEduApp içindeki Sekreter hesabına **Devamsızlık Yönetimi** modülünü ekle.

Bu fazın amacı, sekreterin okul öğrencilerinin günlük devamsızlık kayıtlarını görüntüleyebilmesi, ekleyebilmesi, değiştirebilmesi ve temel filtrelerle yönetebilmesidir.

Mevcut Teacher, Student ve Secretary akışlarını bozma.

Özellikle Faz 2.5'te bilinçli olarak sonraya bırakılan öğrenci login problemlerine dokunma.

---

# 2. UYGULAMADAN ÖNCE ZORUNLU ANALİZ

Kod yazmaya başlamadan önce mevcut yapıyı ayrıntılı olarak incele.

Özellikle aşağıdaki alanlarda mevcut implementasyonu bul:

## 2.1 Veritabanı

Ara:

- `devamsizlik`
- `devamsızlık`
- `attendance`
- `yoklama`
- `devamsizliklar`
- `ogrenci_devamsizlik`
- `ogrenciler`
- `ogrenci_siniflar`
- tarih alanları
- mevcut yoklama/devamsızlık kayıtları

`AppDatabase` içinde mevcut devamsızlık tabloları, CRUD metotları ve migration'ları varsa önce bunları kullan.

**Yeni tablo oluşturmayı ancak mevcut yapının yetersiz olduğu kesinleşirse değerlendir.**

Mevcut devamsızlık verisi varsa kesinlikle kaybetme.

## 2.2 Mevcut ekranlar

Ara:

- attendance
- absence
- yoklama
- devamsızlık
- student detail
- class detail
- teacher attendance

Sekreter için yeni ekran oluşturmadan önce mevcut bir devamsızlık ekranının yeniden kullanılabilir olup olmadığını analiz et.

## 2.3 Mevcut modeller ve servisler

Ara:

- Attendance model
- Absence model
- Student model
- Class model
- Section model
- mevcut servisler
- AppState
- AuthorizationService

## 2.4 Navigation

Şu anki Sekreter sidebar yapısını incele.

Faz 3'te eklenen:

- Veliler
- Veli Listesi
- Veli Ekle
- Veli detay
- Öğrenci → Veliler

yapısını bozma.

Devamsızlık için yeni bir sidebar bölümü ekle.

Önerilen yapı:

**Devamsızlık**
- Günlük Devamsızlık
- Devamsızlık Geçmişi

Ancak mevcut uygulamada daha uygun bir navigation yapısı varsa onu tercih et.

---

# 3. FAZ 4 KAPSAMI

## 3.1 Sekreter sidebar

Sekreter hesabında Devamsızlık bölümü bulunmalı.

Minimum:

- Devamsızlık
  - Günlük Devamsızlık
  - Geçmiş

Sidebar yapısını mevcut `SecretaryNavigation` / `SecretaryNavSection` mimarisine uygun şekilde oluştur.

---

# 4. GÜNLÜK DEVAMSIZLIK

Sekreter bir tarih seçebilmeli.

Varsayılan:

- bugün

Filtreler:

- Tarih
- Sınıf
- Şube

Örneğin:

- 7. sınıf
- 7A

seçildiğinde yalnızca ilgili öğrenciler gösterilsin.

---

# 5. ÖĞRENCİ LİSTESİ

Günlük devamsızlık ekranında öğrenciler gösterilmeli.

Her öğrenci için minimum:

- Öğrenci no
- Öğrenci adı
- Sınıf
- Şube
- Devamsızlık durumu

Örneğin:

| No | Öğrenci | Sınıf | Şube | Durum |
|---|---|---|---|---|
| 101 | Ahmet Yılmaz | 7 | A | Var |
| 102 | Ayşe Demir | 7 | A | Yok |
| 103 | Mehmet Kaya | 7 | A | İzinli |

Mevcut sistemde sınıf/şube adlandırması farklıysa mevcut veri modeline uy.

---

# 6. DEVAMSIZLIK DURUMLARI

Mevcut sistemde tanımlı durumlar varsa onları kullan.

Yoksa minimum olarak:

- Var
- Yok
- İzinli

durumlarını destekle.

Durumları string olarak her yerde tekrar etmek yerine mümkünse merkezi enum/constants yapısı kullan.

Ancak mevcut mimaride daha uygun bir yaklaşım varsa onu bozma.

---

# 7. TOPLU İŞLEM

Sekreterin günlük işlemi hızlı yapabilmesi için toplu işlem desteği ekle.

Minimum:

- Tümünü Var yap
- Tümünü Yok yap

Eğer mevcut veri modelinde İzinli destekleniyorsa:

- Tümünü İzinli yap

Toplu işlem sırasında mevcut kayıtların üzerine kontrollü şekilde yaz.

Gereksiz yeni kayıt üretme.

---

# 8. TEK ÖĞRENCİ DÜZENLEME

Her öğrenci için durum ayrı ayrı değiştirilebilmeli.

Örneğin:

Ahmet → Var  
Ayşe → Yok  
Mehmet → İzinli

Değişiklik kaydedildiğinde aynı tarih + öğrenci için duplicate kayıt oluşmamalı.

Bunun için:

- mevcut kaydı update et
- yoksa insert et

mantığı kullanılmalı.

---

# 9. DEVAMSIZLIK GEÇMİŞİ

Sekreter geçmiş devamsızlık kayıtlarını görüntüleyebilmeli.

Minimum filtreler:

- Başlangıç tarihi
- Bitiş tarihi
- Sınıf
- Şube
- Öğrenci

Liste minimum:

- Tarih
- Öğrenci
- Sınıf/Şube
- Durum

Gösterim masaüstünde tablo, mobilde kart/list formatında olabilir.

---

# 10. ÖĞRENCİ BAZLI GEÇMİŞ

Bir öğrenci seçildiğinde o öğrencinin devamsızlık geçmişi görüntülenebilmeli.

Minimum:

- Tarih
- Durum

ve mümkünse:

- Toplam Yok
- Toplam İzinli

özetleri gösterilebilir.

Ancak gelişmiş raporlama bu fazın konusu değildir.

---

# 11. AUTHORIZATION

`AuthorizationService` mevcut yapısını kullan.

Sekreter için uygun yetenekleri ekle:

- `canViewAttendance`
- `canCreateAttendance`
- `canEditAttendance`
- `canDeleteAttendance` gerekiyorsa

Sekreterin devamsızlık yönetimine erişimi olmalı.

Önerilen politika:

- Sekreter: görüntüleme + ekleme + düzenleme
- Silme: Faz 4 içinde ayrı bir "hard delete" gerekmiyorsa yapma

Tercihen yanlış kaydı silmek yerine durum güncellemesi kullanılmalı.

Öğretmen ve öğrenci yetkilerini bu fazda gereksiz şekilde değiştirme.

---

# 12. VERİTABANI

Mevcut attendance/devamsızlık yapısı yeterliyse yeni tablo oluşturma.

Yetersizse minimum ve sürdürülebilir bir yapı oluştur.

Yeni tablo gerekiyorsa en azından şu mantığı desteklemeli:

- id
- ogrenci_id
- tarih
- durum
- created_at
- updated_at

Mevcut isimlendirme standartlarına uy.

Aynı öğrenci + aynı tarih için tek kayıt olmalı.

Bunun için database seviyesinde mümkünse UNIQUE constraint kullan.

Örneğin mantıksal olarak:

`UNIQUE(ogrenci_id, tarih)`

Ancak mevcut uygulamanın geçmiş verileri ve migration stratejisi buna engelse önce güvenli migration planı oluştur.

---

# 13. MIGRATION

Schema değişikliği gerekiyorsa migration ekle.

Mevcut verileri koru.

Migration sırasında:

- mevcut öğrenciler korunmalı
- mevcut sınıf/şube ilişkileri korunmalı
- mevcut devamsızlık kayıtları korunmalı
- duplicate kayıtlar varsa güvenli şekilde ele alınmalı

Schema versiyonunu güncelle.

Şu anda Faz 3 sonunda DB sürümü 28.

Gerekiyorsa Faz 4 için v29 kullan.

---

# 14. JSON SYNC

`DatabaseSyncService` yapısını incele.

Devamsızlık tablosu yeni veya değişmişse:

- export
- import
- schema version

işlemlerini güncelle.

Mevcut sync yapısını bozma.

---

# 15. RESPONSIVE TASARIM

Web ve mobil kullanımını birlikte düşün.

## Desktop

Tablo görünümü kullanılabilir.

## Mobile

Yatay taşan büyük tablo yerine:

- Card
- ListTile
- compact row

gibi yapı kullan.

Filtreler mobilde dikey veya wrap olarak düzenlenebilir.

Tarih seçici mobil kullanım için uygun olmalı.

---

# 16. UI / UX

Mevcut MyEduApp tasarım sistemini kullan.

Yeni ve bağımsız bir tema oluşturma.

Mevcut:

- AppShell
- Sidebar
- Navbar
- AppSpacing
- localization
- mevcut button/input/card bileşenleri

kullanılmalı.

Loading durumları olmalı.

DB işlemleri sırasında kullanıcıya uygun feedback verilmeli.

Hata durumları sessizce yutulmamalı.

Başarılı kayıtta snackbar veya mevcut feedback mekanizması kullanılabilir.

---

# 17. LOKALİZASYON

Hardcoded Türkçe metinleri mümkün olduğunca localization sistemine ekle.

Özellikle:

- Devamsızlık
- Günlük Devamsızlık
- Geçmiş
- Var
- Yok
- İzinli
- Tümünü Var Yap
- Tümünü Yok Yap
- Tarih
- Başlangıç
- Bitiş
- Sınıf
- Şube
- Öğrenci
- Durum

Mevcut localization yaklaşımına uy.

---

# 18. TESTLER

En az aşağıdaki testleri ekle.

## Database

- attendance insert
- attendance update
- same student + same date duplicate prevention
- attendance list by date
- attendance filtering

## Secretary service

- daily attendance loading
- save/update attendance
- bulk update
- history filtering
- student attendance history

## Authorization

- secretary can view attendance
- secretary can create attendance
- secretary can edit attendance
- secretary cannot perform unauthorized actions

## Regression

Mutlaka:

`flutter test`

çalıştır.

Faz 3'teki 113 testin kırılmadığını doğrula.

---

# 19. ÖNEMLİ — FAZ SINIRI

Bu fazda aşağıdakileri YAPMA:

- Veli login
- Veli Portal
- SMS
- E-posta bildirimi
- Push notification
- Gelişmiş raporlama
- Öğretmen yönetimi
- Öğretmen attendance yetkilerini genişletme
- Duyurular
- Belgeler
- Academic Plans
- Weekly Schedule
- Öğrenci silme approval
- Öğrenci login sistemi değişiklikleri
- Faz 2.5'te ertelenen global öğrenci şifresi / numara çakışması UX
- Büyük çaplı UI redesign
- Cloud authentication
- Firebase
- REST API

Bunlar sonraki fazlarda ele alınacak.

---

# 20. ÖNEMLİ MİMARİ KURAL

Kod yazmadan önce mevcut attendance/devamsızlık implementasyonunu tamamen ara.

Eğer mevcut yapı zaten bazı özellikleri sağlıyorsa:

**yeniden yazma.**

Mevcut kodu genişlet.

Aynı işi yapan ikinci bir:

- model
- service
- table
- repository
- screen

oluşturma.

Özellikle:

- `AppDatabase`
- `AuthorizationService`
- `AppState`
- `SecretaryNavigation`
- `SecretaryTabWorkspace`
- `DatabaseSyncService`

mevcut mimariye uygun şekilde genişletilmeli.

---

# 21. VERİ GÜVENLİĞİ

Sekreter yalnızca yetkili okul verisini görebilmeli.

Öğrenci listesinin tamamı devamsızlık ekranına yükleniyorsa mevcut okul/sınıf kapsamı mantığını kontrol et.

Öğrenci login/session mekanizmasına dokunma.

Devamsızlık verisi yalnızca mevcut öğrenci ID'leriyle ilişkilendirilmeli.

Invalid `ogrenci_id` kayıtları oluşturma.

---

# 22. UYGULAMA SIRASI

Aşağıdaki sırayı takip et:

### Adım 1
Mevcut attendance/devamsızlık kodunu analiz et.

### Adım 2
Mevcut DB yapısını analiz et.

### Adım 3
Mevcut servis/model yapılarını analiz et.

### Adım 4
Gerekli minimum migration'ı belirle.

### Adım 5
Database işlemlerini tamamla.

### Adım 6
Service katmanını tamamla.

### Adım 7
Authorization ekle.

### Adım 8
Secretary navigation ekle.

### Adım 9
Günlük Devamsızlık ekranını yap.

### Adım 10
Geçmiş ekranını yap.

### Adım 11
Responsive düzenle.

### Adım 12
Localization ekle.

### Adım 13
Testleri yaz.

### Adım 14
`flutter test` çalıştır.

### Adım 15
Mevcut Teacher / Student / Secretary akışlarında regresyon kontrolü yap.

---

# 23. MANUEL TEST

Kodlama sonunda mümkünse gerçek uygulamada aşağıdakileri kontrol et:

1. Sekreter ile giriş.
2. Devamsızlık → Günlük Devamsızlık.
3. Bugünün öğrencilerinin gelmesi.
4. Sınıf/şube filtresi.
5. Bir öğrenciyi Yok yap.
6. Aynı öğrenciyi tekrar Var yap.
7. Aynı tarih için duplicate oluşmadığını kontrol et.
8. Tümünü Yok yap.
9. Tümünü Var yap.
10. Geçmiş ekranına gir.
11. Tarih aralığı filtrele.
12. Öğrenci filtrele.
13. Mobil/dar ekranı kontrol et.
14. Uygulamayı kapat/aç ve kayıtların korunup korunmadığını kontrol et.
15. Teacher login ve Student login akışını kontrol et.
16. Secretary Faz 2 ve Faz 3 ekranlarının açıldığını kontrol et.

---

# 24. FAZ 3 REGRESYONU

Özellikle şu mevcut özellikler korunmalı:

- Sekreter Dashboard
- Öğrenci listesi
- Öğrenci ekleme
- Öğrenci düzenleme
- Sınıflar
- Şubeler
- Veli listesi
- Veli ekleme
- Veli düzenleme
- Öğrenci ↔ Veli ilişkisi
- Veli → Öğrenciler
- Öğrenci → Veliler
- Faz 2.5 öğrenci login
- Teacher login
- Student login

---

# 25. FINAL RAPOR

İşlem sonunda aşağıdaki formatta rapor ver:

# FAZ 4 STATUS

**PASS / FAIL**

## Ön Analiz
Mevcut attendance/devamsızlık yapısı neydi?

## Database
Hangi tablo/alan/migration değişti?

## Migration
Schema hangi versiyona geldi?

## Günlük Devamsızlık
Neler yapıldı?

## Geçmiş
Neler yapıldı?

## Toplu İşlem
Neler yapıldı?

## Öğrenci Geçmişi
Neler yapıldı?

## Authorization
Hangi yetkiler eklendi?

## Responsive
Web/mobile tarafında ne yapıldı?

## JSON Sync
Ne değişti?

## Localization
Ne eklendi?

## Eklenen / Değiştirilen Dosyalar
Listele.

## Test Sonucu
Örneğin:

`flutter test`

`XXX passed`
`0 failed`

## Manuel Test Gerektirenler
Varsa listele.

## Riskler
Varsa listele.

## Faz 5'e Kalanlar
Sonraki faz için önerileri listele.

---

# 26. SON KURAL

**Önce analiz, sonra uygulama.**

Mevcut kodu görmeden yeni attendance mimarisi varsayma.

Minimum değişiklikle sürdürülebilir çözüm oluştur.

Faz 4 dışında hiçbir özelliği genişletme.

Mevcut Teacher, Student, Secretary, Faz 2, Faz 2.5 ve Faz 3 davranışlarını koru.
