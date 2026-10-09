# FAZ 12 — Application-Wide Authorization & Role Boundary Audit

## 1. Amaç

MyEduApp'te FAZ 11 sonunda:

* **179 test passed**
* **0 failed**
* DB sürümü: **v34**
* Merkezi account sistemi aktif
* `mustChangePassword` Admin / Teacher / Secretary için uygulanıyor
* Parent email/username login çalışıyor
* Parent IDOR koruması mevcut
* Secretary ≠ Admin yetki ayrımı mevcut

FAZ 12'nin amacı:

> Uygulama genelinde Authentication ile Authorization sınırlarını audit etmek ve her rolün yalnızca izin verilen verilere ve işlemlere erişebildiğini doğrulamaktır.

Bu faz yeni bir authorization sistemi kurma fazı değildir.

Mevcut:

* `AuthorizationService`
* `AppRole`
* `AppState.currentRole`
* `sessionAccountId`
* `sessionStudentId`
* `sessionClassId`
* mevcut service katmanı
* mevcut database yapısı

üzerinden audit yapılacaktır.

### KRİTİK KURAL

**Önce audit yapılacak.**

Audit tamamlanmadan:

* kod değiştirme
* DB değiştirme
* migration yapma
* UI redesign yapma

yapılmayacaktır.

---

# 2. AUDIT BASELINE

FAZ 12 başlangıç baseline:

```text
179 passed
0 failed
DB v34
```

İlk işlem:

```bash
flutter test
```

çalıştırılarak baseline doğrulanmalıdır.

Mevcut testler başarısızsa önce bunun FAZ 12 kaynaklı olup olmadığı belirlenmeli ve raporlanmalıdır.

---

# 3. AUTHENTICATION vs AUTHORIZATION

Aşağıdaki ayrımın uygulama genelinde korunup korunmadığını incele:

```text
Authentication
    =
"Bu kullanıcı kim?"

Authorization
    =
"Bu kullanıcı ne yapabilir?"
```

Özellikle sadece:

* sidebar gizleme
* button gizleme
* route gizleme

ile yetkilendirme yapılmadığından emin ol.

Kritik işlemler mümkün olduğunca service katmanında da korunmalı.

---

# 4. ROL MATRİSİ

Mevcut uygulamanın gerçek davranışını aşağıdaki temel beklentiyle karşılaştır.

| Rol       | Temel erişim                                                                 |
| --------- | ---------------------------------------------------------------------------- |
| Admin     | Sistem/account yönetimi                                                      |
| Teacher   | Eğitimci işlemleri ve yetkili öğrenci/akademik veriler                       |
| Secretary | Öğrenci, veli, sınıf/şube, yoklama, duyuru, belge, rapor gibi idari işlemler |
| Student   | Kendi öğrenci verileri                                                       |
| Parent    | Kendisine bağlı öğrencilerin izin verilen verileri                           |

Audit sırasında gerçek kod davranışı farklıysa varsayım yapma.

Önce mevcut davranışı raporla.

---

# 5. ADMIN AUTHORIZATION AUDIT

İncele:

* `AuthorizationService`
* `AccountService`
* `AccountAuthService`
* Admin workspace
* account management
* password management
* audit management
* backup/restore
* system settings

Kontrol et:

* Admin-only işlemler gerçekten service seviyesinde korunuyor mu?
* Teacher Admin fonksiyonlarını çağırabilir mi?
* Secretary Admin fonksiyonlarını çağırabilir mi?
* Student/Parent Admin fonksiyonlarını çağırabilir mi?
* Son admin koruması korunuyor mu?
* Account aktif/pasif işlemleri role tarafından korunuyor mu?
* Staff account creation sadece izin verilen roller için mi?

Özellikle FAZ 9 sonrası kuralı koru:

> Admin personel hesabı olarak yalnızca Teacher / Secretary oluşturabilir.

Student / Parent account creation akışını Secretary tarafına taşıyan mevcut mimariyi değiştirme.

---

# 6. SECRETARY AUTHORIZATION AUDIT

Secretary'nin aşağıdaki alanlarını tek tek kontrol et:

### İzin verilenler

* Student view/add/edit
* Parent view/add/edit
* Student-parent relation
* Class/section yönetimi
* Attendance
* Attendance reports
* Announcements
* Documents
* Reports
* Weekly Schedule
* Profile
* Student/Parent portal account creation

### Kısıtlı / yasak

* Student deletion approval gerektiren işlemler
* Critical document delete
* Backup/restore
* Teacher password management
* Role management
* Admin account management
* System settings
* Grades
* Exam management
* Teacher daily/annual academic plan editing
* Course-content production
* Question bank
* Mentorship administration

Mevcut fazlarda verilen yetkilerle çelişen bir davranış varsa önce audit raporuna yaz.

---

# 7. TEACHER AUTHORIZATION AUDIT

Teacher'ın:

* öğrenci
* sınıf
* akademik
* not
* plan
* kurs
* doküman
* duyuru
* account

erişimlerini incele.

Özellikle:

> Teacher'ın Secretary veya Admin'e ait idari işlemleri service katmanından çağırması mümkün mü?

Kontrol et.

Teacher UI'da görünmeyen bir fonksiyonun service üzerinden çağrılabilmesi authorization açığı olarak değerlendirilmelidir.

Mevcut Teacher davranışını gereksiz yere yeniden tasarlama.

---

# 8. STUDENT AUTHORIZATION AUDIT

Student portal'daki tüm önemli service çağrılarını incele.

Özellikle:

* profile
* announcements
* documents
* attendance
* academic data
* notifications
* own account

Kontrol et:

```text
sessionStudentId
```

ile erişilen verinin gerçekten login olan öğrenciye ait olup olmadığı.

Aşağıdaki test senaryosunu özellikle araştır:

```text
Student A login
      ↓
Student B ID gönderiliyor
      ↓
Student B data geliyor mu?
```

Geliyorsa CRITICAL/HIGH security finding olarak değerlendir.

Student'ın:

* başka öğrenciyi
* başka sınıfı
* başka parent'ı
* başka hesabı

ID değiştirerek görmesini engelle.

---

# 9. PARENT AUTHORIZATION AUDIT

FAZ 7 ve FAZ 10'daki mevcut korumaları koru.

Özellikle:

* `ParentPortalService`
* `requireLinked`
* `isStudentLinkedToParent`
* parent session
* `sessionAccountId`
* linked student

incele.

Test:

```text
Parent A
  ↓
Student A → ALLOW

Parent A
  ↓
Student B → DENY
```

Ayrıca:

* URL/route üzerinden ID değişimi
* widget callback üzerinden ID değişimi
* service parametresi üzerinden ID değişimi
* doğrudan database/service çağrısı

gibi yolları düşün.

FAZ 10'da düzeltilen:

> Parent email veya username login

akışını değiştirme.

---

# 10. SESSION SCOPE AUDIT

FAZ 11'de kontrol edilen session cleanup'ın yanında bu fazda session'ın **yetki kapsamını** incele.

Kontrol et:

* `currentRole`
* `sessionAccountId`
* `sessionStudentId`
* `sessionClassId`

arasındaki ilişki.

Aşağıdaki kombinasyonların oluşup oluşamayacağını araştır:

```text
Teacher role
+ student session ID

Parent role
+ unrelated student ID

Student role
+ another student ID

Secretary role
+ admin account ID
```

Logout sonrasında değerlerin temizlenmesi zaten FAZ 11 kapsamında doğrulandı.

FAZ 12'de ayrıca:

> Session değerleri temiz olsa bile yanlış değerlerin session'a atanması mümkün mü?

sorusunu cevapla.

---

# 11. ROUTE / NAVIGATION AUTHORIZATION AUDIT

AppShell ve navigation sistemini incele.

Kontrol et:

* Sidebar
* Navbar
* route handling
* direct route access
* deep link
* workspace navigation
* mobile drawer

Bir kullanıcı UI'da menüyü görmüyor diye işlem güvenli kabul edilmemeli.

Örnek:

```text
Secretary
↓
Admin route
↓
Admin screen
```

veya:

```text
Teacher
↓
Secretary route
↓
Secretary operation
```

mümkünse bu HIGH/CRITICAL bulgu olarak değerlendirilmelidir.

---

# 12. SERVICE LAYER AUDIT

Özellikle kritik service'leri tarayarak authorization kontrolü olmayan işlemleri tespit et.

Örnek kategoriler:

* Account
* Student
* Parent
* Attendance
* Documents
* Announcements
* Notifications
* Academic
* Reports
* Classes/Sections
* Backup/Restore
* Settings

Her kritik mutation için:

```text
create
update
delete
archive
publish
restore
reset password
change password
assign
link
unlink
```

authorization davranışını incele.

---

# 13. DATABASE DIRECT ACCESS AUDIT

`AppDatabase` içindeki kritik public metotları incele.

Amaç:

> UI bypass edildiğinde doğrudan database/service katmanından yetkisiz mutation yapılabiliyor mu?

Özellikle:

* delete student
* update student
* create account
* disable account
* password reset
* document delete
* document archive
* announcement publish
* parent relation
* attendance mutation
* settings mutation

gibi işlemleri kontrol et.

Ancak:

> Her `AppDatabase` metoduna authorization eklemek zorunlu değildir.

Eğer database repository/service abstraction'ın altında bilinçli olarak generic bir katmansa bunu audit raporunda belirt.

Gereksiz mimari refactor yapma.

---

# 14. NOTIFICATION AUTHORIZATION AUDIT

FAZ 8 notification sistemini kontrol et.

Özellikle:

* recipient isolation
* `alici_rol`
* `alici_id`
* unread count
* mark read
* notification listing

Kontrol et:

```text
User A
↓
User B notification
↓
DENY
```

olmalı.

Admin, Teacher, Secretary, Student ve Parent recipient scope'larının birbirine karışmadığını doğrula.

---

# 15. DOCUMENT AUTHORIZATION AUDIT

FAZ 6 sistemini kontrol et.

Özellikle:

* critical documents
* archive
* delete
* download
* view
* Secretary access
* Teacher access
* Student access
* Parent access

Critical document'ların Secretary tarafından silinememesi korunmalı.

Parent/Student yalnızca izin verilen document scope'una erişebilmeli.

---

# 16. ANNOUNCEMENT AUTHORIZATION AUDIT

FAZ 5 sistemini kontrol et.

Özellikle:

* create
* edit
* publish
* unpublish
* target
* grade
* branch
* student visibility

Kontrol et:

> Student/Parent sadece kendileri için yayınlanmış duyuruları görebiliyor mu?

Secretary'nin publish/unpublish yetkisi korunuyor mu?

Teacher'ın announcement davranışı FAZ 5'teki bilinçli davranışla uyumlu mu?

---

# 17. ACCOUNT AUTHORIZATION AUDIT

`hesaplar` üzerinde:

* create
* update
* deactivate
* password reset
* password change
* role assignment

işlemlerini kontrol et.

Özellikle:

```text
Secretary
→ create staff account
```

mümkün olmamalı.

```text
Teacher
→ create admin
```

mümkün olmamalı.

```text
Student
→ modify own role
```

mümkün olmamalı.

```text
Parent
→ modify linked account role
```

mümkün olmamalı.

---

# 18. AUDIT RAPORU

**Durum: Tamamlandı** (kod incelemesi + mevcut testler).

## Executive Summary

Rol sınırları çoğunlukla **service + oturum** ile korunuyor: `AccountService._requireAdmin`, `ParentPortalService.requireLinked`, `NotificationService` alıcı filtresi, `StudentSessionGate` oturum kapsamı. **HIGH:** `/settings` global route ve `SettingsScreen` yedekleme/geri yükleme + global şifre/etiket/soru bankası bölümleri **öğretmen oturumu kontrolü olmadan** erişilebilir. **NO ACTION:** Parent Faz 10, Account admin ayrımı, notification IDOR (Faz 8 testleri), secretary portal account API tasarımı.

## Baseline

```text
179 passed / 0 failed (doğrulama: flutter test — FAZ 12 başlangıcı)
DB v34
```

## Current Authorization Architecture

| Katman | Rol |
|--------|-----|
| `AuthorizationService` | UI yetki bayrakları (sekreter/öğretmen/veli/öğrenci/admin) |
| `AccountService` | Admin-only hesap yönetimi; portal hesap oluşturma admin zorunlu değil (sekreter) |
| `ParentPortalService` | `requireLinked` IDOR |
| `NotificationService` | Oturum/fixed recipient |
| `StudentSessionGate` | `sessionStudentId` + `sessionClassId` kapsamı |
| `AppDatabase` | Generic CRUD; yetki üst katmanlarda |

## Role Matrix (özet)

| Rol | Service koruması | UI |
|-----|------------------|-----|
| Admin | `AccountService._requireAdmin` | Admin workspace + sessionAccountId |
| Teacher | Workspace bayrakları; backup **eksik** | Teacher shell |
| Secretary | Admin account API reddedilir | Secretary hub |
| Student | Gate + enrollment identity | Student portal |
| Parent | `requireLinked` + `selectParentStudent` | Parent portal |

## Admin / Secretary / Teacher / Student / Parent Audit

- **Admin:** Personel oluşturma servis + UI sınırlı; son admin koruması testli. **NO ACTION**
- **Secretary:** `listAccounts` / `resetPassword` → `AccountAccessDeniedException`. Öğrenci/veli domain OK. **NO ACTION**
- **Teacher:** İdari secretary API’leri UI’da yok; doğrudan `AccountService` admin gerektirir. **NO ACTION**
- **Student:** `enrollmentBySession` yanlış ID → null; gate boş durum. **NO ACTION** (ek test)
- **Parent:** Faz 7/10 `requireLinked`. **NO ACTION**

## Session Scope Audit

`clearSession` tüm kimlikleri temizler (Faz 11). `setUnlocked` öğrenci dışı rollerde student/parent session sıfırlar. `selectParentStudent` bağlantı doğrular. **NO ACTION**

## Route/Navigation Audit

`MaterialApp` routes: `/settings`, `/question-bank` global — **HIGH** settings backup.

## Service Layer / DB / Notification / Document / Announcement / Account

- Notifications: DB `alici_rol` + `alici_id`; mark read scoped. **NO ACTION**
- Documents: Secretary `canDeleteCriticalDocument => false` (AuthorizationService). **NO ACTION**
- Announcements: Secretary publish; student/parent scoped loaders. **NO ACTION**
- Account: Staff create admin-only; secretary `actorAccountId:0` portal API bilinçli. **NO ACTION**

## Findings

| ID | Severity | Area | Mevcut | Beklenen | Risk | Uygula? |
|----|----------|------|--------|----------|------|---------|
| F12-01 | **HIGH** | Settings route | Backup/restore/tags/QB herkese açık route | Yalnızca öğretmen workspace | Veri sızıntısı / restore | **Evet** |
| F12-02 | **HIGH** | AppState backup | `backupTo`/`restoreFrom` rol kontrolü yok | Teacher-only | Programatik bypass | **Evet** |
| F12-03 | **NO ACTION** | Parent IDOR | `requireLinked` | — | — | Hayır |
| F12-04 | **NO ACTION** | Account admin | `_requireAdmin` | — | — | Hayır |
| F12-05 | **NO ACTION** | Student gate | Session gate | — | — | Hayır |
| F12-06 | **LOW** | StudentPortalService | `listAllEnrollments` tüm okul | Gate ile sınırlı kullanım | Teorik misuse | Hayır |
| F12-07 | **NO ACTION** | Faz 10/11 | Parent login, mustChangePassword | — | — | Hayır |

**Implementation:** F12-01, F12-02 + `test/faz12_authorization_test.dart`.

---

# 19. IMPLEMENTATION RULE

Audit tamamlanmadan implementation başlatma.

Audit sonrası:

### CRITICAL

Mutlaka düzelt.

### HIGH

Bu faz kapsamında düzelt.

### MEDIUM

Doğrudan authorization/security etkisi varsa düzelt.

### LOW

Kod değişikliği gerektirmiyorsa backlog'a bırak.

### NO ACTION

Mevcut davranış bilinçli ve güvenliyse değiştirme.

---

# 20. MINIMUM CHANGE PRINCIPLE

Bu fazın temel prensibi:

> Mevcut çalışan sistemi yeniden tasarlama.

Şunları yapma:

* Yeni authorization framework
* Yeni RBAC sistemi
* Yeni Permission tablosu
* Yeni User tablosu
* Yeni authentication sistemi
* Firebase
* Supabase
* REST
* JWT
* OAuth
* Cloud auth
* Gereksiz DB migration
* Repository mimarisini baştan yazma
* Secretary UI redesign
* Parent portal redesign
* Student portal redesign

Mevcut:

```text
AppRole
AuthorizationService
AppState
AccountService
AccountAuthService
ParentPortalService
Secretary services
```

yeniden kullanılmalıdır.

---

# 21. DATABASE

Hedef:

> **DB v34 olarak kalmalı.**

Authorization düzeltmesi için database değişikliği gerekmiyorsa migration oluşturma.

Eğer gerçekten zorunlu bir migration ortaya çıkarsa:

* neden gerekli olduğu
* migration numarası
* mevcut data etkisi
* JSON sync etkisi
* rollback/recovery

audit raporunda açıkça belirtilmeli.

---

# 22. JSON / BACKUP / SYNC

Authorization değişikliklerinin:

* JSON export
* JSON import
* ZIP backup
* restore

üzerindeki etkisini kontrol et.

Özellikle:

> Backup/restore işlemlerinin Secretary/Teacher/Student/Parent tarafından yanlışlıkla yapılabildiği bir yol var mı?

kontrol et.

Admin-only olması gereken işlemler korunmalı.

---

# 23. LOCALIZATION / RESPONSIVE

Bu faz UI redesign değildir.

Ancak authorization nedeniyle yeni UI mesajları eklenirse:

* TR
* EN

localization kullanılmalı.

Örnek:

* Access denied
* Unauthorized action
* Admin only
* Permission denied

Responsive olarak:

* desktop
* tablet
* mobile

ekranlarda authorization/error ekranlarının kırılmadığı kontrol edilmeli.

---

# 24. TEST

Yeni testler yalnızca audit sonucunda gerekli olan alanlara eklenmeli.

Minimum güvenlik testleri:

### Admin

* Admin-only operation allowed
* non-admin blocked

### Secretary

* Secretary allowed operation
* Admin-only operation blocked

### Teacher

* Teacher allowed operation
* Secretary/Admin operation blocked

### Student

* own data allowed
* another student blocked

### Parent

* linked student allowed
* unlinked student blocked
* IDOR blocked

### Account

* unauthorized role assignment blocked
* unauthorized account creation blocked
* unauthorized password management blocked

### Session

* role/session scope mismatch blocked

### Notifications

* recipient isolation

### Documents

* critical document restrictions

### Announcements

* target/visibility isolation

---

# 25. TEST EXPECTATION

Başlangıç:

```text
179 passed
0 failed
```

Final hedef:

```text
flutter test

0 failed
```

Mevcut testlerden hiçbirini silme veya sadece testleri geçmek için gevşetme.

Security testlerinde gerçek authorization kontrolü bulunmalı.

---

# 26. MANUAL TEST

Audit ve implementation sonrasında:

## Admin

* [ ] Admin workspace
* [ ] Account management
* [ ] Staff account creation
* [ ] Admin-only operation

## Teacher

* [ ] Teacher workspace
* [ ] Admin route blocked
* [ ] Secretary route blocked
* [ ] Authorized student data

## Secretary

* [ ] Student management
* [ ] Parent management
* [ ] Attendance
* [ ] Documents
* [ ] Announcements
* [ ] Admin route blocked
* [ ] Staff account management blocked

## Student

* [ ] Own profile
* [ ] Own announcements
* [ ] Own documents
* [ ] Own attendance
* [ ] Another student blocked

## Parent

* [ ] Own account
* [ ] Linked child
* [ ] Unlinked child blocked
* [ ] Another parent blocked

## Session

* [ ] Logout
* [ ] Role switch
* [ ] Student ID scope
* [ ] Account ID scope

## Responsive

* [ ] Desktop
* [ ] Tablet
* [ ] Mobile

---

# 27. FINAL STATUS

Implementation tamamlandıktan sonra:

```text
docs/new_updates/faz_12.md
```

dosyasının sonuna:

# FAZ 12 — FINAL STATUS

ekle.

Şu bilgileri yaz:

```text
Status: PASS / PASS WITH NOTES / BLOCKED

Baseline:
179 passed / 0 failed

Final:
X passed / 0 failed

Database:
v34 / changed to vXX

Authorization:
...

Admin:
...

Teacher:
...

Secretary:
...

Student:
...

Parent:
...

Session Scope:
...

Service Layer:
...

Database Access:
...

Notifications:
...

Documents:
...

Announcements:
...

JSON Sync:
...

Localization:
...

Responsive:
...

Manual Test:
...

Risks:
...

Deferred:
...

Next Phase Recommendation:
...
```

---

# 28. FAZ 12 SONUÇ KRİTERİ

FAZ 12 başarılı sayılabilmesi için:

1. Audit tamamlanmış olmalı.
2. Audit raporu `docs/actions/faz_12.md` içinde bulunmalı.
3. Gerçek CRITICAL/HIGH authorization açıkları düzeltilmiş olmalı.
4. FAZ 10 Parent IDOR koruması korunmalı.
5. FAZ 11 password enforcement korunmalı.
6. Admin/Secretary ayrımı korunmalı.
7. DB gereksiz yere değiştirilmemeli.
8. Tüm testler yeşil olmalı.
9. `flutter test` sonucu **0 failed** olmalı.
10. Final status `docs/new_updates/faz_12.md` içinde bulunmalı.

## Ana prensip

> **UI'da görünmemesi yetki olmadığı anlamına gelmez.**
>
> Kritik işlemler için gerçek authorization sınırı service/business katmanında da doğrulanmalıdır.

FAZ 12'nin amacı bu sınırların gerçekten var olduğunu kanıtlamak ve yalnızca eksik olanları düzeltmektir.
