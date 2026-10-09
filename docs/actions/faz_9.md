# FAZ 9 — Yönetici Hesabı ve Kullanıcı/Hesap Yönetimi

## 1. Amaç

FAZ 9'un temel amacı MyEduApp içerisinde gerçek bir **Yönetici/Admin hesabı** ve merkezi **kullanıcı/hesap yönetimi** altyapısı oluşturmaktır.

Mevcut durumda Sekreter, Öğretmen, Öğrenci ve Veli rollerinin uygulama içerisindeki işlevleri büyük ölçüde hazırlanmış olsa da bu rollerin gerçek kullanıcı hesaplarını merkezi olarak oluşturup yönetebilecek bir Yönetici hesabı bulunmadığından uygulamanın gerçek kullanıcı senaryolarıyla test edilmesi zorlaşmaktadır.

Bu fazın sonunda:

> Yönetici hesabıyla giriş yapılabilmeli ve Yönetici üzerinden Sekreter, Öğretmen, Öğrenci ve Veli hesapları oluşturulup yönetilebilmelidir.

Böylece sonraki fazlarda uygulama gerçek kullanıcı hesaplarıyla test edilebilir hale gelecektir.

---

# 2. ÖNEMLİ — Audit First

Kodlamaya başlamadan önce mevcut sistem ayrıntılı şekilde incelenmelidir.

Özellikle aşağıdaki yapılar bulunmalıdır:

### Authentication

* Login ekranları
* mevcut password verification
* password hash yapısı
* `verifyTeacherPassword`
* `verifyStudentPassword`
* `verifySecretaryPassword`
* `loginParent`
* mevcut parent password sistemi
* first-login password change mekanizması

### Role

* `AppRole`
* `AppState.currentRole`
* mevcut role kontrolleri
* `AppShell`
* role-based navigation
* mevcut authorization

### Database

* `AppDatabase`
* mevcut kullanıcıya ait tablolar
* `ayarlar`
* `ogrenciler`
* `veliler`
* `ogrenci_veliler`
* öğretmen tabloları
* secretary yapılandırması
* password hash alanları
* database schema version

### Authorization

* `AuthorizationService`
* mevcut role permission'ları
* Admin için kullanılabilecek mevcut altyapı

### Sync

* `DatabaseSyncService`
* JSON export/import
* schema version
* migration sistemi

### UI

* `HomeScreen`
* `AppShell`
* role navigation
* mevcut sidebar
* mevcut workspace'ler

Audit sonucunda mevcut bir account/user altyapısı bulunursa kesinlikle ikinci bir paralel sistem oluşturulmayacaktır.

---

# 3. Mimari Karar

Bu fazda gereksiz şekilde:

* Firebase
* Supabase
* REST API
* OAuth
* JWT
* harici authentication provider

eklenmeyecektir.

Mevcut uygulama local SQLite mimarisine sahiptir.

Bu faz mevcut mimarinin üzerine merkezi bir **local account management** sistemi kuracaktır.

Ancak ileride server/backend authentication'a geçişi engelleyecek şekilde tasarım yapılmamalıdır.

---

# 4. Admin Role

Mevcut `AppRole` sistemi incelenmelidir.

Admin mevcut değilse:

```text
AppRole.admin
```

eklenmelidir.

Admin rolü sadece UI'da gösterilen bir değer olmamalıdır.

Aşağıdaki katmanlarda gerçek rol olarak desteklenmelidir:

* AppState
* authentication
* AppShell
* navigation
* AuthorizationService
* account management
* database access

---

# 5. İlk Admin Hesabı

En kritik konulardan biri ilk Admin hesabının oluşturulmasıdır.

Mevcut sistem local olduğu için:

> "Admin hesabını kim oluşturacak?"

sorunu çözülmelidir.

Önce mevcut proje içerisinde güvenli bir bootstrap mekanizması olup olmadığı araştırılmalıdır.

Mevcut uygun mekanizma yoksa audit sonucuna göre aşağıdaki yaklaşımlardan en güvenlisi seçilmelidir:

### Tercih

İlk çalıştırmada veya güvenli setup aşamasında Admin hesabı oluşturulmasını sağlayan kontrollü bir bootstrap/setup akışı.

Örneğin:

```text
İlk kurulum
     ↓
Admin hesabı oluştur
     ↓
Admin password hash oluştur
     ↓
Normal Login
```

Admin şifresi:

* plain text olarak database'de tutulmamalı
* mevcut password hash altyapısı kullanılmalı
* hardcoded default password kullanılmamalı
* source code içerisine gerçek credential yazılmamalı

Eğer mevcut sistemin daha güvenli bir bootstrap yöntemi varsa o kullanılmalıdır.

---

# 6. Admin Login

Home/Login yapısı incelenerek Admin girişinin mevcut mimariye uygun şekilde eklenmesi sağlanmalıdır.

Admin:

```text
Admin kullanıcı adı/e-posta
+
Admin şifresi
```

ile login olabilmelidir.

Başarılı login sonrası:

```text
Admin Workspace
```

açılmalıdır.

Admin hesabı diğer rollerle karıştırılmamalıdır.

---

# 7. Admin Workspace

Admin için merkezi bir workspace oluşturulmalıdır.

Önerilen ana bölümler:

```text
Yönetim
├── Genel Bakış
├── Kullanıcılar
├── Öğrenciler
├── Öğretmenler
├── Sekreterler
├── Veliler
└── Sistem / Ayarlar
```

Ancak mevcut sidebar/workspace mimarisi farklıysa mevcut yapı kullanılmalıdır.

Yeni ve paralel navigation sistemi oluşturulmamalıdır.

---

# 8. Kullanıcılar / Accounts

Admin'in temel ekranı:

```text
Kullanıcılar
```

olmalıdır.

Liste:

* ad
* soyad
* kullanıcı adı / email
* rol
* durum
* oluşturulma tarihi
* son giriş bilgisi mevcutsa
* işlem

alanlarını gösterebilir.

Rollere göre filtre:

```text
Tümü
Admin
Öğretmen
Sekreter
Öğrenci
Veli
```

olmalıdır.

Arama desteği eklenmelidir.

---

# 9. Hesap Oluşturma

Admin yeni hesap oluşturabilmelidir.

Temel akış:

```text
Yeni Kullanıcı
      ↓
Rol seç
      ↓
Rol-specific bilgiler
      ↓
Kullanıcı adı / email
      ↓
Şifre
      ↓
Kaydet
```

Ancak mevcut domain modelleri yeniden oluşturulmamalıdır.

Örneğin öğrenci zaten `ogrenciler` tablosunda bulunuyorsa:

> yeni bir Student tablosu oluşturulmayacaktır.

Account bilgisi mevcut domain kaydıyla ilişkilendirilmelidir.

---

# 10. Rol Bazlı Hesap Oluşturma

## Öğretmen

Mevcut öğretmen kaydı varsa hesap ona bağlanmalıdır.

Admin:

* öğretmeni seçebilmeli
* username/email oluşturabilmeli
* password belirleyebilmeli
* hesabı aktif/pasif yapabilmeli

---

## Sekreter

Mevcut secretary password / secretary configuration yapısı audit edilmelidir.

Yeni hesap sistemi mevcut sekretarya yapısını gereksiz yere bozmayacak şekilde entegre edilmelidir.

Admin:

* sekreter hesabı oluşturabilmeli
* username/email belirleyebilmeli
* password oluşturabilmeli
* aktif/pasif yapabilmeli

---

## Öğrenci

Mevcut öğrenci kaydı seçilebilmelidir.

Admin:

```text
Öğrenci kaydı
      ↓
Student account
```

ilişkisini oluşturabilmelidir.

Mevcut `student_password_hash` sistemi varsa migration sırasında korunmalı ve mümkün olduğunca mevcut login davranışı bozulmamalıdır.

---

## Veli

Mevcut `veliler` kaydı kullanılmalıdır.

Yeni bir parent domain tablosu oluşturulmayacaktır.

Mevcut:

* `veliler`
* `ogrenci_veliler`
* parent email
* `sifre_hash`

yapıları audit edilerek account yönetimine bağlanmalıdır.

FAZ 10'da yapılacak kapsamlı veli/öğrenci ilişki yönetimi için temel altyapı bu fazda hazırlanabilir.

---

# 11. Username / Email

Audit sonucunda mevcut sistemde username ve email farklı amaçlarla kullanılıyorsa bunlar birbirine zorla dönüştürülmemelidir.

Mevcut domain kuralları korunmalıdır.

Account sistemi destekliyorsa:

* username
* email

ayrı alanlar olabilir.

Unique olması gereken alanlar database/service seviyesinde doğrulanmalıdır.

---

# 12. Password Yönetimi

Admin:

* yeni password belirleyebilir
* password değiştirebilir
* password reset başlatabilir

Password:

* plain text tutulmayacak
* mevcut secure hash mekanizması kullanılacak
* UI state içinde gereksiz tutulmayacak
* loglara yazılmayacak

Admin'in bir kullanıcı için yeni password belirlemesi gerekiyorsa mümkünse kullanıcı ilk login'de password değiştirmeye zorlanabilir.

Mevcut `ChangeTeacherPasswordScreen` gibi mekanizmalar audit edilerek yeniden kullanılmalıdır.

---

# 13. Aktif / Pasif Hesap

Admin hesabı silmek yerine mümkün olduğunca:

```text
active
inactive
```

durumu kullanmalıdır.

Pasif kullanıcı:

* login olamamalı
* mevcut domain kaydı silinmemeli
* geçmiş verileri korunmalı
* notification geçmişi gereksiz şekilde silinmemeli

Admin hesabı için de güvenlik nedeniyle son aktif Admin hesabının pasifleştirilmesi engellenmelidir.

---

# 14. Account Silme

Bu fazda fiziksel kullanıcı/account silme işlemi varsayılan olarak yapılmamalıdır.

Çünkü:

* geçmiş kayıtlar
* duyurular
* belgeler
* bildirimler
* attendance
* academic data
* audit records

kullanıcı hesabıyla ilişkili olabilir.

Tercih:

```text
Deactivate
```

ve gerekiyorsa ileride ayrı bir güvenli deletion workflow.

---

# 15. Authorization

`AuthorizationService` genişletilmelidir.

Admin için temel yetki:

```text
Admin
 ├── manage users
 ├── create accounts
 ├── edit accounts
 ├── reset passwords
 ├── activate/deactivate accounts
 ├── view system users
 └── manage permitted system settings
```

Ancak:

> Admin yetkisi UI seviyesinde kontrol edilmekle sınırlı olmamalıdır.

Service/database operasyonlarında da role kontrolü yapılmalıdır.

---

# 16. Role Değiştirme

Admin kullanıcı rolünü değiştirebilecekse bu işlem dikkatli yapılmalıdır.

Örneğin:

```text
Teacher → Secretary
Student → Teacher
```

gibi domain değişiklikleri doğrudan yapılmamalıdır.

Önce audit sonucunda:

* account role
* domain entity
* role-specific data

arasındaki ilişki belirlenmelidir.

Bir domain kaydının yanlışlıkla başka role dönüştürülmesi engellenmelidir.

Gerekirse:

> Hesap rolü değiştirme yerine hesabı pasifleştir + yeni role uygun hesap oluştur

yaklaşımı kullanılmalıdır.

---

# 17. Son Admin Koruması

Sistemde en az bir aktif Admin bulunmalıdır.

Şu işlem engellenmelidir:

```text
Tek aktif Admin
     ↓
Deactivate
     ↓
❌
```

Aynı şekilde son Admin hesabının yanlışlıkla silinmesi mümkün olmamalıdır.

---

# 18. Audit Log

Admin tarafından yapılan kritik account işlemleri mümkünse audit log ile kaydedilmelidir.

Minimum:

* account created
* password reset
* account activated
* account deactivated
* role-related change

Mevcut audit log altyapısı varsa kullanılmalıdır.

Yeni audit sistemi oluşturulması ancak mevcut altyapı yoksa değerlendirilmelidir.

---

# 19. Notification Entegrasyonu

FAZ 8 Notification sistemiyle uyumlu olmalıdır.

Örneğin hesap oluşturulduğunda veya önemli bir hesap işlemi gerçekleştiğinde notification gerekiyorsa mevcut `NotificationService` kullanılabilir.

Ancak gereksiz notification spam oluşturulmamalıdır.

Özellikle bu fazda:

* password'un kendisi
* temporary credential
* secret information

notification içine yazılmamalıdır.

---

# 20. Database

Mevcut DB yapısı detaylı şekilde audit edilmelidir.

Eğer gerçek bir merkezi account tablosu mevcut değilse, rol ve domain modellerini gereksiz şekilde birbirine bağlamadan ortak account yönetimi sağlayacak minimal bir yapı oluşturulabilir.

Örneğin:

```text
accounts
```

ancak bu sadece audit sonucunda gerçekten gerekli olduğu doğrulanırsa yapılmalıdır.

Yeni account tablosu oluşturulacaksa minimum olarak:

* id
* username/email
* role
* password_hash
* active
* created_at
* updated_at

gibi alanlar değerlendirilebilir.

Kesin schema audit sonucuna göre belirlenmelidir.

---

# 21. Migration

Yeni DB yapısı gerekiyorsa:

* schema version artırılmalı
* migration yazılmalı
* mevcut password/hash verileri korunmalı
* mevcut teacher/student/parent login davranışları bozulmamalı
* eski database açılabilmeli

Migration sırasında mevcut kullanıcıların erişimini kaybetmesine izin verilmemelidir.

---

# 22. JSON Sync

Account sistemi `DatabaseSyncService` ile uyumlu hale getirilmelidir.

Ancak güvenlik açısından password hash verisinin JSON backup/sync kapsamında nasıl ele alındığı özellikle audit edilmelidir.

Plain password kesinlikle export edilmemelidir.

Mevcut sync mimarisindeki güvenlik kuralları korunmalıdır.

---

# 23. Home Screen / Role Selection

Mevcut HomeScreen incelenmelidir.

Admin login:

* mevcut role card sistemine uygun olabilir
* veya güvenlik nedeniyle ayrı Admin login olabilir

Karar audit sonucunda verilmelidir.

Admin login ekranının öğrenci/veli/öğretmen login akışını bozmasına izin verilmemelidir.

---

# 24. Responsive

Admin workspace:

* desktop
* tablet
* mobile

ekranlarda kullanılabilir olmalıdır.

Özellikle kullanıcı tablosu mobile'da doğrudan taşma yapmamalıdır.

Desktop:

```text
DataTable / geniş liste
```

Mobile:

```text
User Card / compact list
```

yaklaşımı kullanılabilir.

Mevcut responsive component'ler kullanılmalıdır.

---

# 25. Localization

TR/EN desteği eksiksiz yapılmalıdır.

Yeni metinler hardcoded bırakılmamalıdır.

Örneğin:

* Yönetici
* Kullanıcılar
* Yeni Kullanıcı
* Hesap
* Aktif
* Pasif
* Şifre
* Şifre Değiştir
* Şifre Sıfırla
* Hesabı Aktifleştir
* Hesabı Pasifleştir
* Rol
* Admin
* Öğretmen
* Sekreter
* Öğrenci
* Veli

gibi alanlar localization üzerinden yönetilmelidir.

---

# 26. Security

Kesinlikle yapılmaması gerekenler:

* plain password database
* hardcoded admin password
* hardcoded admin credentials
* password'u loglama
* başka kullanıcının account bilgisine UI parametresiyle erişim
* yalnızca UI authorization
* admin hesabını silerek sistemi sahipsiz bırakma

---

# 27. Testler

Yeni test dosyası:

```text
test/admin_account_management_faz9_test.dart
```

veya mevcut test yapısına uygun isim kullanılmalıdır.

Minimum testler:

### Admin

* Admin login başarılı.
* yanlış password reddediliyor.
* Admin workspace açılıyor.

### Account creation

* Teacher account oluşturulabiliyor.
* Secretary account oluşturulabiliyor.
* Student account oluşturulabiliyor.
* Parent account oluşturulabiliyor.

### Password

* password hash olarak tutuluyor.
* plain password DB'ye yazılmıyor.
* password reset çalışıyor.

### Active / inactive

* aktif account login olabilir.
* inactive account login olamaz.

### Authorization

* Admin account management yapabilir.
* Secretary account management yapamaz.
* Teacher account management yapamaz.
* Student account management yapamaz.
* Parent account management yapamaz.

### Last admin protection

* son aktif Admin pasifleştirilemez.
* son Admin silinemez.

### Isolation

Bir kullanıcının account bilgileri başka kullanıcı tarafından yönetilemez.

### Existing roles

Faz 1–8 login akışları bozulmamalıdır.

---

# 28. Regression

Özellikle aşağıdaki testler korunmalıdır:

* Faz 5 Announcements
* Faz 6 Documents
* Faz 7 Parent Portal
* Faz 8 Notifications

Önceki baseline:

```text
155 passed / 0 failed
```

Yeni testler eklendikten sonra gerçek sonuç raporlanmalıdır.

---

# 29. Manuel Test — KRİTİK

Bu fazın amacı gerçek hesaplarla uygulamayı test edilebilir hale getirmek olduğu için manuel test özellikle önemlidir.

### Senaryo 1 — İlk Admin

Temiz/uygun test database üzerinde:

```text
Initial setup
↓
Admin oluştur
↓
Admin login
```

çalışmalıdır.

### Senaryo 2 — Sekreter

Admin:

```text
Yeni Sekreter
```

oluşturur.

Sonra logout:

```text
Sekreter login
```

yapılır.

Sekreter workspace kontrol edilir.

### Senaryo 3 — Öğretmen

Admin öğretmen hesabı oluşturur.

Logout → öğretmen login.

Teacher platform kontrol edilir.

### Senaryo 4 — Öğrenci

Admin öğrenci hesabını oluşturur/bağlar.

Logout → öğrenci login.

Student portal kontrol edilir.

### Senaryo 5 — Veli

Admin veli hesabını oluşturur/bağlar.

Logout → veli login.

Parent Portal kontrol edilir.

### Senaryo 6 — Pasif hesap

Admin hesabı pasifleştirir.

Kullanıcı login olmaya çalışır.

Login engellenmelidir.

### Senaryo 7 — Password reset

Admin password reset yapar.

Yeni password ile login test edilir.

### Senaryo 8 — Yetki

Sekreter/öğretmen/öğrenci/veli account management ekranına erişmeye çalışır.

Erişim engellenmelidir.

### Senaryo 9 — Notification

FAZ 8 bildirimleri bozulmamalıdır.

### Senaryo 10 — Mobile

Admin workspace mobile ekranda test edilir.

---

# 30. Test Database

Gerçek kullanıcı yönetimini test edebilmek için gerekiyorsa development/test database için kontrollü seed/setup mekanizması hazırlanabilir.

Ancak:

* production credential
* gerçek password
* hardcoded secret

source code'a eklenmemelidir.

---

# 31. Kapsam Dışı

FAZ 9'da aşağıdakiler tam olarak uygulanmayacaktır:

* kapsamlı Veli Yönetimi
* gelişmiş öğrenci-veli eşleştirme ekranı
* parent communication
* push notification
* SMS
* email
* OAuth
* Firebase Auth
* cloud authentication
* multi-school SaaS architecture
* gelişmiş audit dashboard

Bunlar sonraki fazlara bırakılacaktır.

---

# 32. FAZ 10'a Hazırlık

FAZ 9 sonunda aşağıdaki yapıların kullanılabilir olması hedeflenmektedir:

```text
Admin
 ├── Teacher accounts
 ├── Secretary accounts
 ├── Student accounts
 └── Parent accounts
```

Böylece FAZ 10:

**Veli Yönetimi / Öğrenci–Veli İlişki Yönetimi**

gerçek kullanıcı hesapları üzerinden geliştirilebilecektir.

---

# 33. Final Status

Implementation tamamlandıktan sonra bu dosyanın sonuna:

```text
FAZ 9 — Final Status
```

eklenmelidir.

Raporda:

* Audit sonucu
* Admin architecture
* Bootstrap yöntemi
* Authentication
* Account model
* Database
* Migration
* Admin Workspace
* User Management
* Password Management
* Active/Inactive
* Authorization
* Last Admin Protection
* Audit Log
* Notification Integration
* JSON Sync
* Responsive
* Localization
* Tests
* Manual Tests
* Risks
* Remaining Work
* FAZ 10 önerisi

belirtilmelidir.

Test sonucu gerçek değerle yazılmalıdır.

Örneğin:

```text
Previous baseline: 155 passed / 0 failed
Current: XXX passed / 0 failed
```

**Gerçek test sonucu alınmadan PASS yazılmayacaktır.**
