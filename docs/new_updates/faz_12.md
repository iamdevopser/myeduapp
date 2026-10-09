# FAZ 12 — Application-Wide Authorization & Role Boundary Audit

Tam faz tanımı ve audit: [`docs/actions/faz_12.md`](../actions/faz_12.md).

---

# FAZ 12 — FINAL STATUS

**Status:** PASS

**Baseline:**

```text
179 passed / 0 failed (spec)
Doğrulama koşusu: 180 passed / 0 failed (FAZ 12 audit başlangıcı)
DB v34
```

**Final:**

```text
187 passed / 0 failed
```

(+7 `test/faz12_authorization_test.dart`; önceki suite ile birlikte)

**Database:**

```text
v34 (unchanged)
```

**Authorization:**

UI (`AuthorizationService`) + service (`AccountService._requireAdmin`, `ParentPortalService.requireLinked`, `NotificationService` recipient) + oturum kapsamı (`StudentSessionGate`). Yeni RBAC/permission tablosu eklenmedi.

**Admin:**

Hesap yönetimi servis katmanında admin-only; sekreter/öğretmen `listAccounts` / `resetPassword` reddedilir (test).

**Teacher:**

Öğretmen workspace; yedekleme/geri yükleme artık öğretmen oturumu + `TeacherBackupAccessDeniedException` ile korunuyor.

**Secretary:**

Admin işlemleri serviste engelli; öğrenci/veli/idari akışlar değiştirilmedi.

**Student:**

`StudentSessionGate` + `enrollmentBySession`; başka öğrenci ID ile enrollment null (test).

**Parent:**

Faz 10 login + `requireLinked` / `selectParentStudent` korundu (test).

**Session Scope:**

Faz 11 `clearSession`; parent öğrenci seçimi DB doğrulamalı.

**Service Layer:**

F12-02: `backupTo`, `buildBackupBytes`, `restoreFrom`, `setAutoBackupEnabled`, `setAutoBackupMinutes` öğretmen kontrolü.

**Database Access:**

Generic `AppDatabase` — yetki üst katmanda; körlemesine DB auth eklenmedi.

**Notifications:**

Alıcı izolasyonu; başka kullanıcının bildirimi `markAsRead` false (test).

**Documents / Announcements:**

Mevcut `AuthorizationService` bayrakları ve scope mantığı — audit NO ACTION.

**JSON Sync:**

Değişiklik yok.

**Localization:**

`teacherSettingsOnly` (TR/EN).

**Responsive:**

Settings erişim reddi mesajı — minimal.

**Manual Test:**

Öğretmen → Ayarlar → yedekleme OK; öğrenci/veli `/settings` route → yalnızca uyarı metni; sekreter admin kullanıcı listesi yok.

**Risks:**

Global named routes (`/question-bank` vb.) hâlâ öğretmen dışı oturumda açılabilir — düşük öncelik (settings düzeltildi).

**Deferred:**

Question bank / global search route guard; `StudentPortalService.listAllEnrollments` teorik misuse dokümantasyonu.

**Next Phase Recommendation:**

Operasyonel modüller veya legacy auth migration planı — ürün önceliğine göre.

**Değişen dosyalar:**

- `lib/screens/settings_screen.dart`
- `lib/providers/app_state.dart`
- `test/faz12_authorization_test.dart`
- `docs/actions/faz_12.md` (§18 audit)
