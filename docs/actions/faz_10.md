# FAZ 10 — Hesap, Veli ve Öğrenci-Veli Entegrasyonu

## Audit + Integration

*(Özgün faz tanımı: audit → rapor → minimal düzeltme → test)*

---

# FAZ 10 Audit Report

## A. Current Architecture

| Rol | Workspace | Oturum kimliği |
|-----|-----------|----------------|
| **Admin** | `AdminTabWorkspace` | `sessionAccountId`, `AppRole.admin` |
| **Teacher** | `TeacherTabWorkspace` | Legacy şifre veya `hesaplar` (öğretmen) |
| **Secretary** | `SecretaryTabWorkspace` (4 hub + profil) | Legacy şifre veya `hesaplar` (sekreter) |
| **Student** | Öğrenci portalı | `sessionStudentId`, `sessionClassId` |
| **Parent** | Veli portalı | `sessionParentId`, `selectedStudentId` |

Merkezi **`hesaplar`** (v34) personel ve domain bağlı öğrenci/veli portal kayıtları için kullanılır. Domain kayıtları **`ogrenciler`**, **`veliler`**, ilişki **`ogrenci_veliler`** (UNIQUE `ogrenci_id, veli_id`). Bildirimler **`bildirimler`** (v33).

## B. Account Flow

| Rol | Hesap oluşturma | Giriş doğrulama |
|-----|-----------------|-----------------|
| **Admin** | Bootstrap (`createBootstrapAdmin`) | `AccountAuthService` + kullanıcı adı/e-posta |
| **Teacher** | Admin → `createStaffAccount` | Kullanıcı adı dolu → `AccountAuthService`; boş → `ayarlar` legacy öğretmen hash |
| **Secretary** | Admin → `createStaffAccount` | Aynı (sekreter legacy hash) |
| **Student** | Sekreter → domain `insertStudent` + isteğe bağlı `createStudentPortalAccount` | Numara + `ogrenciler.sifre_hash` (veya varsayılan); `isDomainLoginAllowed` pasif hesabı engeller |
| **Parent** | Sekreter → `createParent` + isteğe bağlı `createParentPortalAccount` | E-posta + `veliler.sifre_hash` (legacy varsayılan) **veya** `AccountAuthService` (e-posta/kullanıcı adı) — Faz 10 düzeltmesi |

**Öğrenci:** `hesaplar` kullanıcı adı UI girişinde kullanılmıyor; numara girişi bilinçli ana yol.

## C. Domain Flow

```text
Sekreter → createStudent (ogrenciler + sifre_hash)
         → createStudentPortalAccountIfNeeded (hesaplar, domain ogrenci/id)

Sekreter → createParent (veliler)
         → linkToStudent (ogrenci_veliler)
         → createParentPortalAccount (hesaplar + veliler sifre_hash sync)
```

- Bir veli **birden fazla** öğrenciye bağlanabilir.
- Bir öğrenci **birden fazla** veliye bağlanabilir.
- Duplicate çift: DB **UNIQUE** + `ConflictAlgorithm.abort`.
- Veli silme: bağlı öğrenci varsa **silinmez** (`deleteParentGuardian`).
- Öğrenci silme: `ogrenci_veliler` **ON DELETE CASCADE** (öğrenci tarafı).
- Veli hesabı (`hesaplar`) öğrenci silinince otomatik silinmez (domain veli).

## D. Duplicate Systems

| Katman | Durum |
|--------|--------|
| `hesaplar.sifre_hash` + `ogrenciler.sifre_hash` / `veliler.sifre_hash` | Portal oluşturulunca **senkron** (`syncDomainPassword`) |
| Legacy `ayarlar` öğretmen/sekreter/öğrenci/veli global hash | Hâlâ geçerli; kullanıcı adı boş girişlerde fallback |
| Öğrenci girişi | `authenticateStudent` + satır bazlı hash + global öğrenci şifresi fallback |
| Veli girişi | Domain e-posta yolu + merkezi hesap yolu (Faz 10) |

Aynı kullanıcı için **paralel auth yolları** var; kasıtlı geriye dönük uyumluluk. Tek `hesaplar` tablosu “ikinci sistem” değil, genişletme.

## E. Security Findings

| Bulgu | Seviye | Not |
|-------|--------|-----|
| Veli portal `ParentPortalService.requireLinked` tüm studentId sorgularında | **No action** | Mevcut; `parent_portal_faz7_test` |
| Pasif `hesaplar` → öğrenci girişi engeli | **No action** | `isDomainLoginAllowed` |
| Pasif veli hesabı | **No action** | Auth + domain allow |
| Veli girişi yalnızca e-posta; portal **kullanıcı adı** çalışmıyordu | **Critical → Fixed** | `AppState.loginParent` + `AccountAuthService` |
| `mustChangePassword` staff/admin hesap girişinde UI yok | **Medium** | Alan DB’de; ilk giriş ekranı sonraki faz |
| Sekreter `AccountService(actorAccountId: 0)` portal oluşturma | **Low** | Admin `_requireAdmin` bypass yok; sadece public portal API |
| Notification IDOR | **No action** | Faz 8 alıcı filtresi |

## F. Data Integrity Findings

| Bulgu | Seviye |
|-------|--------|
| Duplicate `ogrenci_id`+`veli_id` | **No action** — UNIQUE |
| Duplicate domain hesap | **No action** — `getAccountForDomain` + validation |
| Veli e-posta değişince giriş | **Low** — e-posta `veliler` üzerinden; hesap e-postası ayrı alan |
| Portal veli e-posta olmadan | **Medium** — kullanıcı adı girişi (Faz 10) ile kısmen giderildi |

## G. UX Findings

| Bulgu | Seviye |
|-------|--------|
| Sekreter hub / slide panel | **No action** — korunacak |
| Veli giriş alanı “e-posta veya kullanıcı adı” | **Fixed** — l10n + dialog |
| Admin yalnızca personel oluşturma metni | **No action** — uyumlu |

## H. Sync Findings

`DatabaseSyncService.exportTables`: `ogrenciler`, `veliler`, `ogrenci_veliler`, `hesaplar`, `hesap_denetcilik`, `bildirimler` dahil. Şifreler yalnızca hash. Plaintext yok. **No action** (format değişikliği gerekmedi).

## I. Recommended Changes

| Öğe | Seviye | Faz 10 aksiyonu |
|-----|--------|-----------------|
| Veli merkezi hesap girişi | Critical | **Uygulandı** |
| Faz 10 entegrasyon testleri | High | **Uygulandı** |
| İlk giriş şifre değiştirme (staff/admin) | Medium | Rapor / Faz 11 |
| Öğrenci kullanıcı adı ile giriş | Low | Rapor / isteğe bağlı |
| Sekreter işlemleri için `hesap_denetcilik` | Low | Rapor — yeni audit sistemi yok |
| Yeni öğrenci/veli için bildirim fan-out | Low | Rapor — Faz 8 kapsamı dışı |

### Rol sorumluluk tablosu (doğrulandı)

| Rol | Hesap yönetimi | Domain kayıt | Portal |
|-----|----------------|--------------|--------|
| Admin | Personel (öğretmen/sekreter), reset, aktif/pasif | Hayır | Admin paneli |
| Teacher | Hayır | Öğrenci görüntüleme (öğretmen) | Öğretmen workspace |
| Secretary | Hayır (listAccounts ❌) | Öğrenci, veli, ilişki, sınıf, yoklama, duyuru, belge | İsteğe bağlı öğrenci/veli `hesaplar` |
| Student | Hayır | — | Numara + şifre |
| Parent | Hayır | — | E-posta/kullanıcı adı + şifre |

---

# Implementation (Faz 10)

### Problem
Sekreter `createParentPortalAccount` ile kullanıcı adı tanımlanıyordu; `loginParent` yalnızca `veliler.email` + domain hash kullanıyordu → kullanıcı adı ile giriş imkânsız.

### Root cause
Veli girişi Faz 9 öncesi e-posta modeline kilitli; `AccountAuthService` veli rolü için bağlanmamıştı.

### Minimal fix
- `AppState.loginParent`: legacy e-posta yolu korundu; başarısızlıkta / e-posta kaydı yoksa `AccountAuthService` (`AppRole.parent`, `domain_id` → `veli_id`).
- Veli giriş dialogu: `parentLoginEmailOrUsername` (TR/EN).

### Test
`test/faz10_integration_test.dart` (7 test).

---

# FAZ 10 — Final Status

## Audit Summary
Mevcut Admin + Sekreter + domain + `hesaplar` mimarisi tutarlı; asıl entegrasyon açığı veli portal kullanıcı adı girişindeydi. Yeni tablo/model/auth sistemi eklenmedi.

## Role Separation
Admin yalnızca personel (`createStaffAccount` servis kısıtı + UI). Sekreter öğrenci/veli/ilişki/portal oluşturur; `AccountService._requireAdmin` sekreterin hesap yönetimini engeller.

## Account Architecture
`hesaplar` + `AccountAuthService` + domain `ogrenci`/`veli` bağlantısı; legacy ayarlar hash’leri korunuyor.

## Parent Account Integration
Portal hesabı `domain_tur=veli`, `domain_id=veli.id`; şifre `veliler.sifre_hash` ile senkron. Giriş: e-posta (legacy) veya kullanıcı adı/e-posta (`hesaplar`).

## Student Account Integration
Domain şifre zorunlu kayıt; portal hesabı isteğe bağlı; giriş öncelikle öğrenci numarası. Pasif hesap engeli aktif.

## Student-Parent Relations
`ogrenci_veliler` UNIQUE; çoklu ilişki destekli; silme kuralları CASCADE/RESTRICT uyumlu.

## Authorization
`AuthorizationService` sekreter veli/öğrenci; admin workspace ayrı.

## IDOR Security
`ParentPortalService.requireLinked` — testlerle doğrulandı.

## Password Management
SHA-256 hash; admin reset; sekreter portal oluşturma plain text saklamaz.

## First Login / Password Change
Staff admin hesaplarında `sifre_degistir` set edilebilir; **UI akışı henüz tam değil** (Faz 9 açık kalem).

## Active/Inactive Accounts
`AccountAuthService` ve `isDomainLoginAllowed` pasif girişi engeller (öğrenci + veli test).

## Audit Log
`hesap_denetcilik`: hesap oluşturma, reset, aktif/pasif. Sekreter domain CRUD kaydı yok (kapsam dışı).

## Database
**v34** — Faz 10’da migration yok.

## JSON Sync
Değişiklik yok; tablolar export listesinde.

## Notifications
Faz 8 duyuru/belge fan-out; yeni öğrenci/veli kaydı için otomatik bildirim yok (kapsam dışı).

## Secretary UX
Hub + slide panel korundu; değişiklik yok.

## Admin UX
Personel odaklı kullanıcı ekleme korundu.

## Responsive / Localization
Veli giriş etiketi TR/EN güncellendi.

## Tests

```text
Previous baseline: 166 passed / 0 failed
Current: 173 passed / 0 failed
```

(+7 `faz10_integration_test.dart`)

## Manual Tests
Spec §25: Admin personel; sekreter öğrenci/veli/bağlantı; veli çocuk erişimi; pasif veli; kullanıcı adı ile veli girişi (yeni).

## Risks
- Dual auth (legacy + hesap) karmaşıklığı devam ediyor.
- Öğrenci portal kullanıcı adı girişi hâlâ UI’da yok.

## Remaining Work
- Staff/admin `mustChangePassword` ekranı.
- İsteğe bağlı: öğrenci kullanıcı adı girişi.
- Sekreter domain işlemleri için mevcut audit genişletmesi (düşük öncelik).

## FAZ 11 Recommendation
Audit sonucuna göre öncelik: **(1)** zorunlu ilk giriş şifre değiştirme akışı, **(2)** operasyonel bildirimler veya akademik/rapor modülleri — ürün önceliğine göre seçilecek; Faz 11 önceden sabitlenmedi.
