# FAZ 11 — Account Security & Login Consistency Audit + Integration

## 1. Amaç

MyEduApp'te FAZ 10 sonunda mevcut durum:

* **173 test başarılı**
* **0 test başarısız**
* DB sürümü: **v34**
* Merkezi hesap sistemi: `hesaplar`
* Audit sistemi: `hesap_denetcilik`
* Roller: Admin, Teacher, Secretary, Student, Parent
* Admin → Teacher/Secretary personel hesabı oluşturuyor.
* Secretary → Student/Parent domain kayıtlarını ve isteğe bağlı portal hesaplarını oluşturuyor.
* Parent login artık email veya username destekliyor.
* ParentPortalService üzerinde IDOR koruması mevcut.

FAZ 11'in amacı yeni bir authentication sistemi kurmak değil; mevcut authentication/account yapısının güvenlik, tutarlılık ve kullanıcı deneyimi açısından **audit edilmesi ve yalnızca gerçekten gerekli eksiklerin minimum değişiklikle tamamlanmasıdır.**

> **KRİTİK KURAL:** Önce audit yapılacak. Audit tamamlanmadan kod değiştirilmez.

---

# 2. FAZ 11 — AUDIT-FIRST

İlk aşamada hiçbir kod, migration, UI veya database değişikliği yapma.

Aşağıdaki alanları mevcut kod üzerinden incele:

### A. Merkezi hesap sistemi

İncele:

* `hesaplar`
* `hesap_denetcilik`
* `AccountService`
* `AccountAuthService`
* `AuthorizationService`
* `AppRole`
* `AppState.currentRole`
* account active/inactive mantığı
* password hash yapısı
* `mustChangePassword`
* password reset/change işlemleri
* son admin koruması
* audit kayıtları

Şu sorulara cevap ver:

1. `mustChangePassword` gerçekten sistemde uygulanıyor mu?
2. Account oluşturulduğunda kullanıcı ilk login'de parola değiştirmeye zorlanıyor mu?
3. Admin tarafından resetlenen parola sonrasında `mustChangePassword` doğru şekilde aktif oluyor mu?
4. Password değiştirildikten sonra flag doğru şekilde kapanıyor mu?
5. Inactive account login yapabiliyor mu?
6. Password işlemleri audit ediliyor mu?
7. Merkezi hesap ile domain password sistemleri arasında güvenlik açısından tutarsızlık var mı?

---

# 3. ROLE BAZLI LOGIN AUDIT

Her rolü ayrı ayrı incele.

## Admin

İncele:

* `AdminBootstrapScreen`
* Admin login
* merkezi account login
* password change
* `mustChangePassword`
* inactive account
* logout/session temizliği

Kontrol et:

* Admin hardcoded password kullanıyor mu?
* Bootstrap yalnızca ilk kurulum için mi?
* Admin password reset/change güvenli mi?
* Son aktif admin koruması devam ediyor mu?

---

## Teacher

İncele:

* merkezi `hesaplar` login
* eski `ayarlar.teacher_password_hash`
* legacy fallback
* `ChangeTeacherPasswordScreen`
* first-login davranışı
* `mustChangePassword`

Özellikle şu durumu tespit et:

> Teacher merkezi account ile giriş yapıyorsa hangi password sistemi geçerli?

Ve:

> Legacy teacher password ile merkezi account password arasında beklenmeyen bir güvenlik açığı veya tutarsızlık var mı?

Legacy sistemi hemen kaldırma.

Önce audit sonucuna göre karar ver.

---

## Secretary

İncele:

* merkezi account login
* eski secretary password mekanizması
* `verifySecretaryPassword`
* `secretary_password_hash`
* `mustChangePassword`
* Secretary account oluşturma
* Secretary student/parent account oluşturma

Özellikle:

* Secretary personel hesabı ile öğrenci/veli portal hesabının birbirine karışmadığını doğrula.
* Secretary'nin admin fonksiyonlarına erişemediğini doğrula.
* Secretary'nin account yönetimi üzerinden personel account oluşturamadığını doğrula.

---

# 4. STUDENT LOGIN AUDIT

Student login akışını ayrıca incele.

Kontrol et:

* Öğrenci hangi identifier ile login oluyor?
* Öğrenci numarası mı?
* Username mevcut mu?
* Student portal account oluşturulurken username nasıl belirleniyor?
* Secretary tarafından oluşturulan optional student account ile login nasıl yapılıyor?
* `hesaplar` ile öğrenci domain password sistemi nasıl ilişkilendiriliyor?
* inactive account davranışı nedir?

Özellikle şu soruya net cevap üret:

> Student için username login gerekli mi, yoksa mevcut öğrenci numarası login'i yeterli ve bilinçli bir tasarım mı?

Bunu audit sonucu olmadan değiştirme.

---

# 5. PARENT LOGIN REGRESSION AUDIT

FAZ 10'da düzeltilen:

* email login
* username login

akışını tekrar doğrula.

Kontrol et:

```text
AppState.loginParent
AccountAuthService
veliler
hesaplar
ParentPortalService
```

Test et:

* email + password
* username + password
* inactive account
* yanlış password
* başka parent'ın student ID'si
* linked olmayan student
* logout sonrası erişim

FAZ 10 IDOR korumasını bozacak hiçbir değişiklik yapılmamalı.

---

# 6. MUST CHANGE PASSWORD — ANA ODAK

Bu FAZ'ın en önemli konusu budur.

Mevcut sistemde `mustChangePassword` alanı/altyapısı varsa:

### Audit et:

* Nerede set ediliyor?
* Nerede okunuyor?
* Login sonrasında kontrol ediliyor mu?
* Kullanıcı password değiştirmeden uygulamaya girebiliyor mu?
* Password değişikliğinden sonra flag kapanıyor mu?
* Logout/login sonrasında davranış doğru mu?
* Admin reset password sonrasında tekrar çalışıyor mu?

Eksikse minimum çözüm tasarla.

### Beklenen güvenli davranış

Örneğin:

```text
Login
  ↓
credentials valid
  ↓
account active?
  ↓
mustChangePassword?
  ├── YES → Change Password Screen
  │          ↓
  │       password changed
  │          ↓
  │       mustChangePassword = false
  │          ↓
  │       normal workspace
  │
  └── NO → normal workspace
```

Kullanıcı `mustChangePassword == true` iken normal workspace'e bypass edememeli.

---

# 7. DEFAULT / TEMPORARY PASSWORD AUDIT

Secretary tarafından oluşturulan:

* Student portal account
* Parent portal account

için default/temporary password mekanizmasını incele.

Şunları belirle:

1. Default password kullanılıyor mu?
2. Kullanıcı ilk login'de değiştirmek zorunda mı?
3. Password açık metin olarak DB'de tutuluyor mu?
4. UI'da gereksiz yere tekrar gösteriliyor mu?
5. Audit log'a password yazılıyor mu?
6. Account oluşturulduktan sonra güvenli onboarding nasıl yapılmalı?

Eğer mevcut tasarım güvenli ve yeterliyse değiştirme.

---

# 8. SESSION / LOGOUT AUDIT

İncele:

* `AppState`
* `currentRole`
* `sessionAccountId`
* `sessionClassId`
* `sessionStudentId`
* logout
* role switch
* workspace navigation

Kontrol et:

* Teacher logout → Student/Secretary/Admin session bilgisi kalıyor mu?
* Parent logout → eski linked student erişimi kalıyor mu?
* Student logout → eski student ID temizleniyor mu?
* Secretary logout → secretary authorization context temizleniyor mu?
* Account değiştirildiğinde eski session state kalıyor mu?

Özellikle session state'in role/ID karışmasına izin vermediğinden emin ol.

---

# 9. AUTHORIZATION AUDIT

Authentication ile authorization'ın birbirine karışmadığını kontrol et.

Her kritik service için:

```text
Authentication
≠
Authorization
```

olmalı.

Özellikle:

* Admin-only işlemler
* Secretary işlemleri
* Teacher işlemleri
* Parent own-data erişimi
* Student own-data erişimi
* account management
* password management

service katmanında korunmalı.

Sadece sidebar/menu gizlemek authorization olarak kabul edilmemeli.

---

# 10. LEGACY AUTHENTICATION AUDIT

Mevcut legacy sistemleri hemen silme.

Özellikle:

* `ayarlar.teacher_password_hash`
* `secretary_password_hash`
* `student_password_hash`
* `veliler.sifre_hash`
* merkezi `hesaplar`

arasındaki ilişkiyi dokümante et.

Her biri için:

| Sistem                    | Rol          | Kullanım | Merkezi Account ile ilişki | Kaldırılabilir mi? |
| ------------------------- | ------------ | -------- | -------------------------- | ------------------ |
| Legacy teacher password   | Teacher      | ?        | ?                          | Audit              |
| Legacy secretary password | Secretary    | ?        | ?                          | Audit              |
| Student password          | Student      | ?        | ?                          | Audit              |
| Parent password           | Parent       | ?        | ?                          | Audit              |
| `hesaplar`                | Staff/Portal | ?        | ?                          | Ana sistem         |

Amaç:

> Bir sonraki aşamada legacy auth kaldırılacaksa güvenli migration yolu belirlemek.

Bu FAZ'da sırf temizlik amacıyla legacy sistemi kaldırma.

---

# 11. AUDIT RAPORU

**Durum: Tamamlandı.** Kod incelemesi + mevcut test suite (173 passed baseline).

## Executive Summary

Mimari tutarlı; Faz 10 parent email/username ve IDOR korunuyor. **Kritik eksik:** `hesaplar.sifre_degistir` (`mustChangePassword`) login sonrası **Admin / Teacher / Secretary** merkezi hesap girişinde **uygulanmıyor** — kullanıcı doğrudan workspace’e giriyor. Legacy öğretmen varsayılan şifre akışı (`ChangeTeacherPasswordScreen`) yalnızca kullanıcı adı boş girişte çalışıyor. `clearSession()` oturum alanlarını temizliyor (NO ACTION). DB v34 değişikliği gerekmedi.

## Current Authentication Architecture

| Katman | Rol |
|--------|-----|
| `AccountAuthService` | Admin, Teacher, Secretary (kullanıcı adı), Parent (email/username Faz 10) |
| Legacy `ayarlar` hash | Teacher/Secretary boş kullanıcı adı |
| `ogrenciler.sifre_hash` + numara | Student |
| `veliler.sifre_hash` + email | Parent legacy |
| `isDomainLoginAllowed` | Pasif `hesaplar` → öğrenci/veli domain girişi engeli |

## Role-by-Role Login Audit

### Admin

Bootstrap + `loginRoleAccount`; hardcoded şifre yok. `mustChangePassword` bootstrap’ta false. **HIGH:** Login sonrası zorunlu şifre ekranı yok.

### Teacher

Kullanıcı adı → `hesaplar`; boş → legacy + varsayılan `ogretmen` → `ChangeTeacherPasswordScreen`. **HIGH:** Merkezi hesap + `mustChangePassword=true` bypass.

### Secretary

Teacher ile aynı pattern; profil “şifre değiştir” admin’e yönlendiriyor (bilinçli). **HIGH:** `mustChangePassword` bypass.

### Student

Öğrenci numarası + şifre; `hesaplar` kullanıcı adı UI’da yok — **bilinçli tasarım (NO ACTION)**. Pasif hesap testli.

### Parent

`loginParent`: legacy email, sonra `AccountAuthService` (Faz 10). IDOR: `ParentPortalService.requireLinked`. **NO ACTION** (regresyon yok).

## mustChangePassword Audit

| Soru | Sonuç |
|------|--------|
| Set ediliyor mu? | `createStaffAccount` default true; `resetPassword` true; portal hesapları default false |
| Login sonrası kontrol? | **Hayır** (staff/admin) |
| Bypass? | **Evet** — workspace direkt |
| Flag kapanıyor mu? | DB API var; owner change akışı eksik |
| Admin reset sonrası? | Flag set; enforcement eksik |

## Temporary/Default Password Audit

Öğrenci formu varsayılan portal şifresi; hash DB’de. Plaintext log/audit yok. Sekreter veli/öğrenci portalında `mustChangePassword` false — kabul edilebilir (LOW/deferred).

## Session Security Audit

`clearSession()` → role, account, student, class, parent, secretary focus, notifications cache temizleniyor. `setUnlocked(false)` → `clearSession()`. **NO ACTION.**

## Authorization Audit

`AccountService._requireAdmin` personel yönetimi; sekreter portal API `actorAccountId: 0` yalnızca domain portal oluşturma. Parent IDOR servis katmanında. **NO ACTION.**

## Legacy Authentication Audit

| Sistem | Rol | Merkezi ilişki | Faz 11 |
|--------|-----|----------------|--------|
| teacher_password_hash | Teacher | Paralel fallback | Koru |
| secretary_password_hash | Secretary | Paralel fallback | Koru |
| ogrenciler.sifre_hash | Student | Portal sync | Koru |
| veliler.sifre_hash | Parent | Portal sync | Koru |
| hesaplar | Staff/portal | Ana | mustChangePassword enforce |

## Findings

| ID | Severity | Area | Current Behavior | Risk | Recommendation | Action |
|----|----------|------|------------------|------|----------------|--------|
| F11-01 | **CRITICAL** | mustChangePassword | Staff/admin account login ignores flag | Geçici şifreyle kalıcı erişim | Login → zorunlu değişim → workspace | **Fix** |
| F11-02 | **HIGH** | AccountService | Owner şifre güncelleme + audit yok | Zorunlu akış tamamlanamaz | `changePasswordAsAccountOwner` | **Fix** |
| F11-03 | **NO ACTION** | Student | Numara login | — | Bilinçli | — |
| F11-04 | **NO ACTION** | Parent | Faz 10 akışı | — | Koru | — |
| F11-05 | **NO ACTION** | Session | clearSession tam | — | — | — |
| F11-06 | **LOW** | Parent portal | mustChangePassword false | Varsayılan şifre | Sonraki faz | Deferred |
| F11-07 | **NO ACTION** | JSON sync | Hash export mevcut | — | — | — |
| F11-08 | **MEDIUM** | Teacher legacy | Varsayılan şifre ekranı | Eski kurulum | Legacy koru | NO ACTION |

**Implementation kararı:** F11-01, F11-02 uygulanacak. Test: mustChangePassword, reset, inactive, parent regression, session cleanup.

---

# 12. IMPLEMENTATION KARARI

Audit tamamlandıktan sonra yalnızca gerçekten gerekli değişiklikleri uygula.

Öncelik:

### CRITICAL

Mutlaka düzelt.

### HIGH

Bu FAZ kapsamında düzelt.

### MEDIUM

Güvenlik veya login tutarlılığını doğrudan etkiliyorsa düzelt.

### LOW

Kod değişikliği gerektirmiyorsa backlog'a bırak.

### NO ACTION

Mevcut tasarım bilinçliyse değiştirme.

---

# 13. MUHTEMEL IMPLEMENTATION

Audit sonucunda doğrulanırsa aşağıdaki minimum değişiklikler yapılabilir:

### A. mustChangePassword

Gerekliyse:

* Login sonrası zorunlu password change
* bypass engelleme
* password update
* flag reset
* logout/session davranışı
* admin reset sonrası yeniden zorunlu değişiklik

### B. Login consistency

Gerekliyse:

* Admin / Teacher / Secretary merkezi login davranışını standardize et.
* Parent FAZ 10 email/username login'i koru.
* Student login'i yalnızca audit gerekli görürse değiştir.

### C. Session cleanup

Eksikse role/session ID'lerinin logout'ta güvenli şekilde temizlenmesini düzelt.

### D. Authorization

Eksik kritik service-level authorization varsa minimum şekilde ekle.

---

# 14. YAPILMAYACAKLAR

Bu FAZ kapsamında:

* Yeni authentication sistemi oluşturma.
* Firebase ekleme.
* Supabase ekleme.
* REST/JWT/OAuth ekleme.
* Cloud authentication ekleme.
* Yeni user/account tablosu oluşturma.
* Yeni password sistemi oluşturma.
* Parent için ikinci portal sistemi oluşturma.
* Student için ikinci account sistemi oluşturma.
* Mevcut `hesaplar` sistemini kopyalama.
* Gereksiz DB migration oluşturma.
* Secretary hub'ını yeniden tasarlama.
* UI'ı baştan yazma.
* FAZ 10'da çalışan Parent IDOR korumasını değiştirme.
* Legacy auth'u audit sonucu olmadan kaldırma.

---

# 15. DATABASE

Öncelikli hedef:

> **DB version değişmemeli.**

Sadece gerçekten gerekli bir schema değişikliği ortaya çıkarsa migration gerekip gerekmediğini audit raporunda açıkça belirt.

Gereksiz migration yapma.

Eğer migration zorunluysa:

* migration numarası
* upgrade
* downgrade/recovery yaklaşımı
* JSON sync etkisi
* mevcut verilerin korunması

dokümante edilmeli.

---

# 16. JSON / BACKUP / SYNC

`DatabaseSyncService` ve mevcut JSON/ZIP backup mekanizmasını kontrol et.

Yeni alan eklenirse:

* export
* import
* backup
* restore

ile uyumunu kontrol et.

Password hash gibi güvenlik açısından hassas verilerin export mekanizmasındaki mevcut davranışını ayrıca audit et.

---

# 17. LOCALIZATION

Yeni UI eklenirse:

* Türkçe
* İngilizce

desteklenmeli.

Hardcoded kullanıcı-facing string bırakma.

Özellikle:

* Change Password
* Current Password
* New Password
* Confirm Password
* Password Required
* First Login
* Password Reset
* Account Inactive

gibi ifadeleri localization üzerinden yönet.

---

# 18. RESPONSIVE / MOBILE

Bu FAZ'ın ana konusu UI redesign değildir.

Ancak password change/login ekranlarında:

* desktop
* tablet
* mobile

layout'un kırılmadığını kontrol et.

Özellikle:

* keyboard açılması
* küçük ekran
* portrait
* form overflow
* password fields

kontrol edilmeli.

---

# 19. TEST

FAZ 11 öncesi baseline:

```text
173 passed
0 failed
```

Önce mevcut testleri çalıştır.

Sonra değişiklik yap.

Yeni testler gerekiyorsa ekle.

Özellikle test edilmesi gerekenler:

### mustChangePassword

* true → login → forced change
* wrong current password
* weak password
* password mismatch
* successful change
* flag false after change
* logout/login after change

### Account

* active account
* inactive account
* reset password
* reset → mustChangePassword

### Role isolation

* Admin
* Teacher
* Secretary
* Student
* Parent

### Parent regression

* email login
* username login
* inactive account
* IDOR

### Session

* logout clears role
* logout clears account ID
* logout clears student ID
* logout clears class ID

Hedef:

```text
flutter test

0 failed
```

---

# 20. MANUAL TEST CHECKLIST

Audit/implementation sonrasında:

### Admin

* [ ] Admin login
* [ ] Password change
* [ ] Reset password
* [ ] mustChangePassword
* [ ] inactive account

### Teacher

* [ ] Central account login
* [ ] Legacy fallback
* [ ] Password change
* [ ] Logout

### Secretary

* [ ] Central account login
* [ ] Student creation
* [ ] Parent creation
* [ ] Optional portal account
* [ ] Logout

### Student

* [ ] Login
* [ ] Portal access
* [ ] Logout

### Parent

* [ ] Email login
* [ ] Username login
* [ ] Linked child
* [ ] Unlinked child blocked
* [ ] Logout

### Security

* [ ] inactive account blocked
* [ ] role escalation blocked
* [ ] IDOR blocked
* [ ] session IDs cleared

### Responsive

* [ ] Desktop
* [ ] Tablet
* [ ] Mobile

---

# 21. FINAL REPORT

Implementation tamamlandıktan sonra:

```text
docs/new_updates/faz_11.md
```

dosyasını oluştur/güncelle.

Sonuna mutlaka:

# FAZ 11 — FINAL STATUS

ekle.

Şu bilgileri açıkça yaz:

```text
Status: PASS / PASS WITH NOTES / BLOCKED

Baseline:
173 passed / 0 failed

Final:
X passed / 0 failed

Database:
v34 / changed to vXX

Authentication:
...

mustChangePassword:
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

Session Security:
...

Authorization:
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

# 22. SON KURAL

FAZ 11'in temel prensibi:

> **Önce mevcut authentication mimarisini anla → audit raporunu çıkar → güvenlik açısından gerçek eksikleri belirle → minimum gerekli değişikliği yap → tüm testleri çalıştır → sonucu raporla.**

Mevcut çalışan sistem, sırf daha temiz görünsün diye yeniden tasarlanmayacak.

Özellikle **173 testin tamamının yeşil olması** korunacak.

FAZ 10'da düzeltilen Parent username/email login ve IDOR koruması regresyona uğramayacak.
