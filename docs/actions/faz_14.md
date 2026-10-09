# FAZ 14 — P7 VELİ PORTALI

## Amaç

FAZ 13 kapsamında Student Portal / P6 çalışmaları tamamlandı.

Mevcut durum:

* Student Shell → PASS
* Student Dashboard → PARTIAL
* Student Courses → PARTIAL
* Student Detail Panels → PARTIAL
* Announcements → PARTIAL
* Documents → PARTIAL
* Academic → PARTIAL
* Notifications → PASS
* Profile → PARTIAL
* Responsive → PARTIAL
* Accessibility → PARTIAL
* Security Regression → PASS
* `flutter test` → 189 passed / 0 failed
* `flutter analyze lib/screens/student_portal` → No issues found

P6'nın kalan `PARTIAL` maddeleri bu fazda zorunlu olarak tamamlanmayacaktır.

Bu fazın amacı:

> **MyEduApp içine Veli Portalı'nı mevcut uygulama mimarisini bozmadan, mevcut öğrenci/öğretmen yetkilendirme yapısını koruyarak ve mümkün olduğunca mevcut servis/veri katmanını yeniden kullanarak eklemek.**

---

# 1. ÇALIŞMA KURALLARI

## 1.1 Önce audit, sonra implementation

İlk görev doğrudan kod yazmak değildir.

Önce mevcut kod tabanını incele ve aşağıdaki başlıkları kapsayan kısa bir audit gerçekleştir:

* Mevcut login / role yapısı
* `AppState`
* `AppShell`
* Öğrenci portalı
* Öğrenci verileri
* Öğrenci-veli ilişkisi için mevcut veri yapıları
* Öğrenci servis/repository katmanı
* Duyurular
* Yoklama
* Ders/program verileri
* Not/akademik performans verileri
* Dokümanlar
* Bildirimler
* SQLite schema ve migration yapısı
* Backup / restore mekanizması
* Mevcut RBAC / authorization
* Mobil drawer / responsive yapı
* Mevcut test altyapısı

Audit sonunda:

```text
docs/actions/faz_14_audit.md
```

dosyasını oluştur.

Audit sırasında:

* Gereksiz yeni tablo oluşturma.
* Mevcut veri modelini yeniden keşfetmeden önce mevcut tabloları incele.
* Mevcut servisleri tekrar yazma.
* Student Portal'daki UI bileşenlerini mümkün olduğunca yeniden kullan.
* Teacher / Student davranışını değiştirme.
* Authentication sistemini değiştirme.
* P7 dışında kalan özellikleri implementation kapsamına alma.

Audit tamamlandıktan sonra implementation'a geç.

---

# 2. VELİ ROLÜ

Mevcut role/session yapısını incele.

Veli için yeni bir role ihtiyacı varsa mevcut mimariye uygun şekilde:

```dart
AppRole.parent
```

veya projedeki mevcut naming convention'a uygun eşdeğer bir rol oluştur.

Ancak mevcut:

* Teacher
* Student
* Secretary
* Admin / mevcut diğer roller

davranışlarını bozma.

Eğer projede zaten uygun bir role abstraction mevcutsa onu genişlet.

Aynı işi yapan ikinci bir authorization sistemi oluşturma.

---

# 3. VELİ GİRİŞİ

Mevcut Home/Login yapısını incele.

Veli için:

> **Veli Girişi**

veya mevcut UI terminology'ye uygun bir login seçeneği ekle.

Login akışı:

```text
Home
 ↓
Veli Girişi
 ↓
Veli doğrulama
 ↓
Parent Session
 ↓
Parent Workspace
```

İlk aşamada mevcut lokal uygulama mimarisine uygun çözüm kullan.

Firebase, REST API, OAuth, JWT veya harici authentication sistemi ekleme.

Eğer mevcut uygulamada veli için kullanılabilecek veri/doğrulama altyapısı yoksa audit raporunda bunu açıkça belirt ve mevcut mimariye uygun minimum çözüm uygula.

---

# 4. VELİ — ÖĞRENCİ EŞLEŞMESİ

Veli portalının temel veri ilişkisi:

```text
Parent
  ↓
Student(s)
```

olmalıdır.

Bir veli birden fazla öğrenciye bağlı olabilir.

Bu nedenle UI yalnızca tek öğrenci varsayımıyla tasarlanmamalıdır.

Örnek:

```text
Veli
 ├── Ahmet — 7A
 ├── Ayşe — 9B
 └── Mehmet — 11C
```

Birden fazla öğrenci varsa veli portalında öğrenci seçimi yapılabilmelidir.

Tek öğrenci varsa seçim ekranı gerekmeyebilir.

Mevcut veri modelinde veli-öğrenci ilişkisi bulunmuyorsa:

* gerekli DB modelini tasarla,
* migration gerekiyorsa migration ekle,
* backup/restore uyumluluğunu kontrol et,
* ilişkiyi öğrencinin mevcut ID yapısıyla bağla.

Yeni ilişki için gereksiz duplicate student data oluşturma.

---

# 5. PARENT SHELL

Student Portal'daki shell yapısını referans al.

Mümkün olduğunca:

```text
AppShell
AppWorkspaceBackground
Drawer / Navigation
Top Navbar
Notification Bell
Responsive Layout
```

yapısını yeniden kullan.

Veli portalında shell kaybolmamalıdır.

Desktop:

```text
┌──────────────┬──────────────────────────┐
│ Sidebar      │ Navbar                   │
│              ├──────────────────────────┤
│ Dashboard    │                          │
│ Öğrenciler   │     Content              │
│ Devam        │                          │
│ Akademik     │                          │
│ Duyurular    │                          │
│ Belgeler     │                          │
│ Profil       │                          │
└──────────────┴──────────────────────────┘
```

Mobile:

* Drawer kullanılabilir.
* Content tam genişliğe uyum sağlamalı.
* Sidebar desktop'a özel sabit genişlik varsaymamalı.

---

# 6. VELİ DASHBOARD

Ana veli dashboard'u hazırlanmalıdır.

Dashboard'da mümkün olduğunca mevcut veriler kullanılmalıdır.

Önerilen bölümler:

### Öğrenci özeti

* Öğrenci adı
* Sınıf
* Öğrenci numarası
* Profil bilgisi

### Bugünün özeti

* Bugünkü dersler
* Yoklama durumu
* Yaklaşan sınav/etkinlik varsa
* Önemli duyurular

### Akademik özet

* Genel performans
* Son notlar
* Ders bazlı durum

### Devam durumu

* Devamsızlık özeti
* Gerekirse son yoklama kayıtları

### Duyurular

Son önemli duyurular.

### Hızlı işlemler

Örneğin:

```text
Akademik Durum
Devam Durumu
Duyurular
Belgeler
Öğrenci Profili
```

Student Portal'daki `ReferenceStatCard` ve benzeri UI yapılarını uygunsa yeniden kullan.

---

# 7. ÖĞRENCİ SEÇİCİ

Bir veli birden fazla öğrenciye sahipse:

```text
Öğrenci Seç
```

alanı oluştur.

Seçilen öğrenci değiştiğinde:

* dashboard
* akademik bilgiler
* devam
* ders/program
* duyurular
* belgeler

gibi öğrenciye bağlı içerikler seçilen öğrenciye göre değişmelidir.

Seçili öğrenci state'i merkezi ve kontrollü tutulmalıdır.

Her ekranın kendi bağımsız öğrenci state'ini oluşturma.

---

# 8. VELİ — AKADEMİK

Veli:

### Görebilir

* Notlar
* Ders bazlı performans
* Akademik özet
* Sınav sonuçları
* Öğrencinin akademik ilerlemesi

### Değiştiremez

* Not
* Sınav sonucu
* Öğretmen planı
* Akademik kayıt
* Ders içeriği

UI seviyesinde sadece read-only göster.

Backend / repository / service seviyesinde de mümkün olduğunca write path bulunmamalıdır.

---

# 9. VELİ — DEVAM / YOKLAMA

Veli öğrencinin:

* günlük devam durumu
* devamsızlık toplamı
* son yoklama kayıtları

gibi bilgilerini görebilmelidir.

Veli:

* yoklama oluşturamaz
* yoklama değiştiremez
* yoklama silemez

Mevcut attendance servislerini yeniden kullan.

Yeni duplicate attendance logic oluşturma.

---

# 10. VELİ — HAFTALIK PROGRAM

Öğrencinin haftalık programını görüntüle.

Responsive davranış:

### Mobile

Yatay taşma gerekiyorsa mevcut kontrollü horizontal scroll kullanılabilir.

Ancak:

* ekran dışına taşan kritik bilgi
* kırılan text
* aşırı dar hücre
* okunamayan ders bilgisi

oluşmamalıdır.

### Tablet/Desktop

Daha geniş grid/table düzeni kullanılabilir.

Mevcut Student Academic program UI'sı uygunsa yeniden kullanılabilir.

Veli burada sadece görüntüleme yetkisine sahip olmalıdır.

---

# 11. VELİ — DUYURULAR

Mevcut announcement yapısını incele.

Veli:

* duyuruları görebilir
* duyuru detayını açabilir

Veli:

* duyuru oluşturamaz
* duyuru düzenleyemez
* duyuru silemez

P6'da kalan:

> read/unread DB state

özelliğini bu faza zorunlu olarak dahil etme.

Eğer mevcut model bunu destekliyorsa kullan.

Desteklemiyorsa P7 kapsamında yeni read-state sistemi oluşturma; ayrı iş olarak bırak.

---

# 12. VELİ — BELGELER

Mevcut student document yapısını kullan.

Veli:

* kendisine bağlı öğrencinin erişilebilir belgelerini görebilir.

Ancak P6'da belirtilen:

> belge viewer / download model + servis akışı

bu fazın zorunlu kapsamı değildir.

Mevcut document sistemi gerçekten açma/indirme destekliyorsa veliye de aynı read-only davranışı ver.

Desteklemiyorsa sahte download/viewer oluşturma.

Audit dosyasına eksikliği yaz.

---

# 13. VELİ — BİLDİRİMLER

Mevcut:

```text
NotificationBellButton
```

ve notification altyapısını incele.

Veliye ait bildirimler varsa mevcut sistemi kullan.

Yeni notification engine oluşturma.

Bildirim yoksa P7 kapsamında gereksiz yeni notification backend geliştirme.

---

# 14. VELİ — PROFİL

Veli profil ekranı oluştur.

Gösterilebilecek bilgiler:

* Ad soyad
* İletişim bilgileri
* Bağlı öğrenciler
* Gerekli hesap bilgileri

Kişisel bilgilerin düzenlenmesine mevcut veri modelinin izin verip vermediğini kontrol et.

Yetkisiz alanlara edit UI ekleme.

---

# 15. GÜVENLİK / AUTHORIZATION

Bu bölüm kritik.

Veli hiçbir zaman başka öğrencinin verisine erişememelidir.

Örnek:

```text
Parent A
 └── Student 1

Parent A → Student 1 ✅
Parent A → Student 2 ❌
```

Student ID değiştirerek başka öğrencinin verisine erişilememelidir.

Authorization yalnızca UI visibility ile yapılmamalıdır.

Mümkün olan servis/repository seviyelerinde de bağlı öğrenci kontrolü uygulanmalıdır.

Özellikle kontrol edilmesi gerekenler:

* student details
* grades
* attendance
* schedule
* announcements
* documents
* academic records
* notifications

Teacher ve Student yetkileri değişmemelidir.

---

# 16. RESPONSIVE TASARIM

P6'daki responsive yaklaşımı devam ettir.

En az şu genişlikleri düşün:

```text
360 px
390 px
430 px
768 px
1024 px+
```

Özellikle:

* dashboard cards
* student selector
* academic tables
* attendance
* weekly schedule
* announcements
* documents

alanlarını kontrol et.

Kartları sırf tüm ekranlara sığdırmak için gereğinden fazla daraltma.

Bir bileşenin işlevi için daha fazla yatay alan gerekiyorsa responsive breakpoint ile layout değiştir.

---

# 17. ACCESSIBILITY

P6'da bırakılan accessibility çalışmalarının tamamını bu faza zorunlu olarak taşımıyoruz.

Ancak P7'de yeni eklenen tüm UI:

* semantic label
* button semantics
* tooltip gerektiğinde
* yeterli touch target
* keyboard navigation mümkün olduğunda
* text overflow kontrolü

açısından kontrol edilmelidir.

Yeni accessibility borcu oluşturma.

---

# 18. TESTLER

Yeni testler ekle.

En az:

### Role

```text
Parent role oluşturuluyor mu?
Parent login doğru workspace'e gidiyor mu?
```

### Student relation

```text
Parent kendi öğrencisini görebiliyor mu?
Bağlı olmayan öğrenciyi göremiyor mu?
Birden fazla öğrenci seçilebiliyor mu?
```

### Read-only

```text
Parent grade değiştiremiyor
Parent attendance değiştiremiyor
Parent announcement değiştiremiyor
Parent document silemiyor
```

### UI

```text
Parent shell
Parent dashboard
Student selector
Responsive critical widgets
```

### Regression

Mevcut test suite tamamen çalıştırılmalı.

Hedef:

```text
flutter test
```

→ mevcut testlerin tamamı PASS

Ayrıca:

```text
flutter analyze
```

çalıştır.

---

# 19. P7 KAPSAMI DIŞINDAKİLER

Aşağıdakileri bu fazda kendiliğinden geliştirme:

* Online ödeme
* Mesajlaşma/chat
* Öğretmen-veli mesajlaşması
* Push notification backend
* Firebase
* REST API
* OAuth/JWT
* Cloud authentication
* E-devlet entegrasyonu
* Belge upload sistemi
* Belge viewer/download altyapısının baştan yazılması
* Duyuru read/unread persistence
* Geniş analytics sistemi
* Yeni admin paneli
* Öğretmen portalı yeniden tasarımı
* Student Portal P6 partial maddelerinin tamamının bitirilmesi

Bunlardan biri mevcut mimaride zorunlu hale geliyorsa implementation'a başlamadan önce audit dosyasına gerekçesini yaz.

---

# 20. DOKÜMANTASYON

Implementation tamamlandığında:

```text
docs/actions/faz_14.md
```

güncellenmeli.

Ayrıca:

```text
docs/new_updates/faz_14.md
```

dosyası bu promptun kayıtlı versiyonu olarak bulunmalı.

`faz_14.md` içinde en az:

* P7 kapsamı
* değişen dosyalar
* yeni DB/migration varsa detayları
* yeni role bilgisi
* authorization yaklaşımı
* test sonucu
* analyze sonucu
* responsive QA sonucu
* bilinen partial/technical debt
* sonraki faz önerisi

bulunmalı.

---

# 21. DEĞİŞEN DOSYALAR

Implementation sırasında değişen dosyaları gerçek durum üzerinden listele.

Dosya listesini önceden varsayma.

Özellikle:

```text
lib/...
test/...
docs/actions/faz_14.md
docs/new_updates/faz_14.md
```

şeklinde gerçek path'leri yaz.

---

# 22. SON RAPOR

Implementation bittikten sonra terminal çıktılarıyla birlikte şu formatta raporla:

```text
FAZ 14 — P7 STATUS

Parent Role              PASS / PARTIAL
Parent Login             PASS / PARTIAL
Parent-Student Relation  PASS / PARTIAL
Parent Shell             PASS / PARTIAL
Parent Dashboard         PASS / PARTIAL
Student Selector         PASS / PARTIAL
Academic                 PASS / PARTIAL
Attendance               PASS / PARTIAL
Weekly Schedule          PASS / PARTIAL
Announcements            PASS / PARTIAL
Documents                PASS / PARTIAL
Notifications             PASS / PARTIAL
Profile                  PASS / PARTIAL
Responsive               PASS / PARTIAL
Accessibility            PASS / PARTIAL
Authorization            PASS / PARTIAL
Security Regression      PASS / FAIL

flutter test             X passed / Y failed
flutter analyze          result
```

Sonuçlar tahmin edilmemeli; gerçek terminal çıktıları kullanılmalıdır.

---

# 23. BAŞARI KRİTERİ

P7 başarılı kabul edilir eğer:

1. Veli login akışı çalışıyorsa.
2. Veli workspace'i mevcut shell mimarisiyle açılıyorsa.
3. Veli kendi öğrencilerini görebiliyorsa.
4. Birden fazla öğrenci destekleniyorsa.
5. Akademik bilgiler read-only görüntülenebiliyorsa.
6. Attendance read-only görüntülenebiliyorsa.
7. Haftalık program görüntülenebiliyorsa.
8. Duyurular görüntülenebiliyorsa.
9. Mevcut belge altyapısı uygunsa belgeler görüntülenebiliyorsa.
10. Veli başka öğrencinin verisine erişemiyorsa.
11. Teacher / Student / Secretary davranışlarında regression oluşmuyorsa.
12. Responsive layout kritik ekranlarda çalışıyorsa.
13. Yeni UI accessibility açısından temel gereksinimleri karşılıyorsa.
14. Test suite PASS oluyorsa.
15. `flutter analyze` yeni hata üretmiyorsa.
16. Dokümantasyon güncellenmişse.

---

# 24. UYGULAMA PRENSİBİ

Bu fazda temel prensip:

> **Önce mevcut sistemi anla → mevcut mimariyi mümkün olduğunca yeniden kullan → minimum yeni veri modeli oluştur → authorization'ı koru → responsive UI oluştur → test et → raporla.**

Özellikle mevcut Student Portal'da P6 sırasında oluşturulan:

* UI componentleri
* shell yapısı
* responsive patternler
* card patternleri
* service/repository yapıları

uygunsa yeniden kullanılmalıdır.

Aynı UI veya business logic'in ikinci kopyasını oluşturma.

**Önce `docs/actions/faz_14_audit.md` oluştur ve audit'i tamamla. Ardından implementation'a geç.**

---

# 25. P7 IMPLEMENTATION DURUMU (2026-10-07)

Audit: `docs/actions/faz_14_audit.md`

| Alan | Durum | Not |
| --- | --- | --- |
| Parent Role | PASS | Mevcut `AppRole.parent` |
| Parent Login | PASS | Home + `loginParent` / hesap |
| Parent-Student Relation | PASS | `ogrenci_veliler` + servis `requireLinked` |
| Parent Shell | PASS | `ParentTabWorkspace` + `AppShell` |
| Parent Dashboard | PARTIAL | KPI + ders/duyuru özet; P6 tam dashboard değil |
| Student Selector | PASS | `ParentStudentPicker` + `selectParentStudent` |
| Academic | PARTIAL | Read-only not listesi |
| Attendance | PASS | Özet + kayıtlar |
| Weekly Schedule | PASS | Yeni `ParentWeeklyScheduleScreen` |
| Announcements | PARTIAL | `StudentAnnouncementCard`; read/unread yok |
| Documents | PARTIAL | Sekreter belge aç/kopyala; öğrenci içerik viewer yok |
| Notifications | PASS | Shell bell (değişmedi) |
| Profile | PARTIAL | Header + bağlı öğrenciler |
| Responsive | PARTIAL | Belge tile mobil; manuel QA önerilir |
| Accessibility | PARTIAL | Tooltip belge aksiyonları |
| Authorization | PASS | `ParentPortalService` + testler |
| Security Regression | PASS | 191 test |

**DB / migration:** Yok (v34)

**Değişen dosyalar (P7 tur):**

- `docs/actions/faz_14_audit.md` (yeni)
- `lib/services/parent_portal_service.dart`
- `lib/utils/parent_nav_section.dart`
- `lib/utils/parent_navigation.dart`
- `lib/screens/parent_portal/parent_tab_workspace.dart`
- `lib/screens/parent_portal/parent_portal_screens.dart`
- `lib/screens/parent_portal/widgets/parent_document_tile.dart` (yeni)
- `lib/l10n/app_localizations.dart`
- `test/parent_portal_p7_test.dart` (yeni)
- `docs/new_updates/faz_14.md`

**flutter test:** 191 passed / 0 failed (2026-10-07)

**flutter analyze:** `lib/screens/parent_portal` — 0 issue (unused import düzeltildi); `parent_portal_screens.dart` Dropdown `value` info (önceden var)

**Sonraki faz:** P8 Admin portalı UI hizalama (FAZ 13 §17)

---

## FAZ 14 — P7 STATUS (final)

```
Parent Role              PASS
Parent Login             PASS
Parent-Student Relation  PASS
Parent Shell             PASS
Parent Dashboard         PARTIAL
Student Selector         PASS
Academic                 PARTIAL
Attendance               PASS
Weekly Schedule          PASS
Announcements            PARTIAL
Documents                PARTIAL
Notifications            PASS
Profile                  PARTIAL
Responsive               PARTIAL
Accessibility            PARTIAL
Authorization            PASS
Security Regression      PASS

flutter test             191 passed / 0 failed
flutter analyze          parent_portal: No issues found
```
