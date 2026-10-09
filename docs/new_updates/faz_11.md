# FAZ 11 — Account Security & Login Consistency

Tam faz tanımı ve audit raporu: [`docs/actions/faz_11.md`](../actions/faz_11.md).

Özet: Mevcut `hesaplar` + legacy auth audit edildi; `mustChangePassword` staff/admin/secretary merkezi girişinde zorunlu hale getirildi; Faz 10 parent ve yetki ayrımları korundu. DB **v34** değişmedi.

---

# FAZ 11 — FINAL STATUS

**Status:** PASS

**Baseline:**

```text
173 passed / 0 failed
```

**Final:**

```text
179 passed / 0 failed
```

**Database:**

```text
v34 (unchanged)
```

**Authentication:**

Merkezi `AccountAuthService` + legacy fallback (öğretmen/sekreter boş kullanıcı adı), öğrenci numara, veli email/username (Faz 10). Yeni auth sistemi eklenmedi.

**mustChangePassword:**

- `createStaffAccount` / `resetPassword` → flag true.
- Admin, Teacher, Secretary merkezi login: `mustChangePassword` true ise `AccountRequiredPasswordChangeScreen` (workspace bypass yok).
- `AccountService.changePasswordAsAccountOwner` → hash güncelleme, flag false, domain sync (öğrenci/veli hesapları), audit `password_changed`.

**Admin:**

Bootstrap + login; zorunlu şifre akışı merkezi hesap ile uyumlu. Personel yönetimi değişmedi.

**Teacher:**

Legacy varsayılan şifre → `ChangeTeacherPasswordScreen` (kullanıcı adı boş). Merkezi hesap → Faz 11 zorunlu değişim ekranı.

**Secretary:**

Merkezi hesap + legacy korundu; zorunlu şifre ekranı eklendi. Öğrenci/veli portal oluşturma ayrımı değişmedi.

**Student:**

Numara + şifre; username login eklenmedi (bilinçli). Pasif hesap engeli aynı.

**Parent:**

Email ve username login (Faz 10) regresyon testleri geçti. IDOR değişmedi.

**Session Security:**

`clearSession()` account/student/class/parent/role temizliği doğrulandı (test). Logout davranışı aynı.

**Authorization:**

`AccountService._requireAdmin` ve parent `requireLinked` korundu. Sekreter ≠ admin.

**JSON Sync:**

Export/import değişmedi; password yalnızca hash.

**Localization:**

`changePassword`, `changePasswordRequired`, `newPassword`, `confirmPassword` mevcut anahtarlar kullanıldı; veli `parentLoginEmailOrUsername` korundu.

**Responsive:**

Zorunlu şifre ekranı `SingleChildScrollView` + max width 400 (öğretmen ekranı ile uyumlu).

**Manual Test:**

Spec §20 checklist — Admin/Teacher/Secretary `mustChangePassword`; Parent email/username; inactive account; logout session temizliği manuel smoke önerilir.

**Risks:**

- Legacy ve merkezi auth yan yana karmaşıklık devam ediyor.
- Veli/öğrenci portal hesaplarında `mustChangePassword` hâlâ default false (varsayılan şifre riski düşük öncelik).

**Deferred:**

- Parent/student portal için isteğe bağlı `mustChangePassword` onboarding.
- Öğrenci username ile giriş.
- Sekreter profilinden self-service şifre (admin reset).

**Next Phase Recommendation:**

Operasyonel bildirimler, akademik modüller veya mobil readiness — ürün önceliğine göre; legacy auth kaldırma için migration planı ayrı faz.

**New tests:** `test/faz11_account_security_test.dart` (6 tests).

**New/changed code:**

- `lib/services/account_service.dart` — `changePasswordAsAccountOwner`
- `lib/screens/account_required_password_change_screen.dart`
- `lib/utils/role_workspace_navigation.dart`
- `lib/screens/home_screen.dart` — `_afterAccountLogin`
