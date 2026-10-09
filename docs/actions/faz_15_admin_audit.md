# FAZ 15 / FAZ 13 §17 — P8 Admin Portalı Audit (2026-10-08)

## 1. Mevcut Admin mimarisi

| Katman | Dosya / yapı |
| --- | --- |
| Rol | `AppRole.admin`, `AppState.isAdmin`, `sessionAccountId` |
| Giriş | `home_screen.dart` → `AdminBootstrapScreen` (ilk kurulum) veya `admin_login_dialog` + `loginRoleAccount` |
| Workspace | `AdminTabWorkspace` → `AppShell` (`adminSection`) |
| Nav | `AdminNavSection`: home, users, userAdd, profile |
| AuthZ | `AuthorizationService`: `canAccessAdminWorkspace`, `canManageAccounts` |
| Veri | `AccountService` (hesaplar CRUD), `AppDatabase` (öğrenci/veli sayıları) |

Admin portalı **hesap/rol yönetimi** odaklı; öğrenci/sınıf CRUD sekreter panelinde.

---

## 2. Mevcut Admin ekranları

| Ekran | Dosya | İşlev |
| --- | --- | --- |
| Bootstrap | `admin_bootstrap_screen.dart` | İlk admin hesabı |
| Ana sayfa | `admin_home_screen.dart` | Hesap sayısı metni (minimal) |
| Kullanıcı listesi | `admin_users_list_screen.dart` | Arama, rol filtresi, tablo/mobil kart |
| Kullanıcı ekle | `admin_user_add_screen.dart` | Staff/student/parent portal hesapları |
| Profil | `admin_profile_screen.dart` | Minimal ListTile |

**Yok (kasıtlı):** Admin içinde öğretmen dersi, yoklama girişi, sekreter formları — P8’de sekreter/teacher ekranlarını kopyalamayız.

---

## 3. Mevcut yetkiler

- `canAccessAdminWorkspace`: admin + unlocked + sessionAccountId
- `canManageAccounts`: aynı scope
- `AccountService` işlemleri `actorAccountId` ile; son admin pasifleştirme engeli (test)
- Teacher/Student/Parent/Secretary: `AuthorizationService` değişmedi

---

## 4. Eksik ekranlar (P8 beklentisi vs gerçek)

| Beklenti (genel liste) | Durum |
| --- | --- |
| Öğrenci/öğretmen/sınıf yönetimi UI | Sekreter’de; admin’de **yok** — P8 kapsamına alınmaz |
| Backup/restore UI | `settings_screen` (P9) |
| Raporlar | Sekreter/öğretmen |
| **Dashboard KPI** | Eksik — P8’de `countAllStudents`, sınıf, veli, hesap rolleri |
| **Profil zenginleştirme** | PARTIAL |
| **Hızlı işlemler** | Eksik — nav mevcut bölümlere link |

---

## 5. Eksik navigation/shell

- Shell: **tamam** (`AppShell` + drawer)
- Nav: 4 madde yeterli P8 için; yeni modül eklenmez

---

## 6. Yeniden kullanılabilir servisler

| Servis | Kullanım |
| --- | --- |
| `AccountService.listAccounts` | KPI aktif/toplam hesap |
| `AppDatabase.countAllStudents`, `getStudentClasses` | Öğrenci/sınıf KPI |
| `SecretaryStudentService.loadDashboardStats` pattern | Referans; admin için ince `AdminPortalService` |
| `ReferenceStatCard`, `AppSpacing.pagePadding` | P6/P7 UI |
| `StudentProfileHeader` / `StudentProfileInfoRow` | Profil (salt okuma) |

---

## 7. DB / schema

- **v34**, migration **gerekmez** P8 için
- `hesaplar`, `ogrenciler`, `ogrenci_siniflar`, `veliler` mevcut

---

## 8. Güvenlik / RBAC riskleri

| Risk | Mitigasyon |
| --- | --- |
| UI-only admin | Ekranlar `canManageAccounts` / `canAccessAdminWorkspace` kontrolü |
| IDOR hesap düzenleme | `AccountService` actor scoped; mevcut FAZ 9 testleri |
| Admin → öğrenci verisi | P8’de yeni read API eklenirse **sadece aggregate COUNT**, satır bazlı öğrenci listesi admin portalına eklenmez |

---

## 9. Responsive

- `admin_users_list_screen`: mobil kart / masaüstü yatay scroll DataTable — **iyi**
- `admin_home_screen`: tek kart — **zayıf** → KPI grid P8
- `admin_user_add_screen`: incelenecek; form `pagePadding` var

---

## 10. Accessibility

- Kullanıcı listesi: IconButton **tooltip** mevcut
- Profil/dashboard: P8’de header + overflow kontrolü

---

## 11. Test kapsamı

- `admin_account_management_faz9_test.dart` — login, RBAC, hesap CRUD
- `faz12_authorization_test.dart` — admin workspace flag
- **Gap:** dashboard stats servisi → `admin_portal_p8_test.dart`

---

## 12. P8 implementation sırası

1. `AdminPortalService` + `AdminDashboardStats` (read-only aggregate)
2. `AdminHomeScreen` — ReferenceStatCard + quick actions + auth guard
3. `AdminProfileScreen` — hesap bilgisi + header
4. Test + `flutter test` / `flutter analyze`
5. `docs/actions/faz_13.md` §17 P8 güncelle

---

## 13. P8 kapsamı dışı

- Öğrenci/öğretmen/sınıf/veli CRUD admin UI (sekreter)
- Duyuru/belge/yoklama admin modülü
- Backup UI (P9)
- Yeni analytics backend
- DB migration
- Firebase/OAuth

---

*Audit tamamlandı — implementation onaylı.*

---

## P8 implementation (2026-10-08)

- `lib/services/admin_portal_service.dart` — aggregate KPI
- `admin_home_screen.dart` — ReferenceStatCard dashboard
- `admin_profile_screen.dart` — profil header + satırlar
- `test/admin_portal_p8_test.dart`
- Migration: **yok**
