# FAZ 13 §17 — P9 Settings + Notification Center Audit (2026-10-08)

**Baseline:** P8 tamamlandı — `flutter test` 193/0, `flutter analyze` 0 warning, DB **v34**, migration yok.

**Kapsam kaynağı:** `docs/actions/faz_13.md` §17 (P9 satırı), FAZ 12 backup auth, FAZ 8 bildirimler, FAZ 11 hesap şifresi.

---

## 1. Mevcut Settings yapısı

| Bileşen | Dosya | Not |
| --- | --- | --- |
| Ana ekran | `lib/screens/settings_screen.dart` | Route: `/settings`, `SettingsScreen.routeName` |
| Bölüm UI | `lib/widgets/settings_section.dart` | `SettingsSection`, `SettingsRow` |
| SMTP | `lib/widgets/smtp_settings_section.dart` | `ayarlar` anahtarları (`smtp_*`) |
| Shell | `AppShell` + `TeacherNavSection.settings` | `teacher_navigation.dart` → doğrudan `SettingsScreen` |
| Diğer girişler | `app.dart` named route, `app_builder_screen`, `app_viewer_screen` | Öğretmen dışı oturumda route açılabilir (FAZ 12 bilinen düşük risk) |

### Erişim kapısı (UI)

- `AuthorizationService.canAccessTeacherWorkspace` (`isTeacher`) **false** ise: `AppShell` + `teacherSettingsOnly` metni; **hiçbir ayar satırı gösterilmez**.
- Öğrenci / veli / sekreter / admin workspace’lerinde **sidebar’da Settings menüsü yok**; yalnızca öğretmen sidebar’ında “Ayarlar”.

### Mevcut bölümler (öğretmen oturumu)

| Grup | İçerik | Veri / servis |
| --- | --- | --- |
| Dil | TR/EN `DropdownButton` | `AppState.setLocale` → `ayarlar.locale` |
| Görünüm | system/light/dark | `setThemeMode` → `ayarlar.theme_mode` |
| Öğretmen görünen ad | `TextField` | `TeacherDisplayName.settingKey` |
| SMTP | host/port/user/pass/from/ssl, test | `loadSmtpSettings` / `saveSmtpSettings` |
| Güvenlik | Öğretmen / öğrenci / sekreter **portal** şifreleri | `setTeacherPassword`, `setStudentPassword`, `setSecretaryPassword` → `*_password_hash` |
| Otomatik yedek | switch + dakika `TextField` | `setAutoBackup*` → FAZ 12 `_requireTeacherForBackupOperations` |
| Etiketler | dialog liste/sil | `AppState.tags` |
| Soru bankası | nav push | `QuestionBankScreen` |
| Arama | nav push | `GlobalSearchScreen` |
| Yedekleme / geri yükleme | ZIP oluştur / dosya seç + onay | `backupTo`, `buildBackupBytes`, `restoreFrom` → FAZ 12 teacher guard |

### Eksik / tutarsızlıklar

- **Dil/tema** global `ayarlar` tablosunda; UI **yalnızca öğretmen** ayarlar ekranında — diğer roller shell’den değiştiremiyor (P9 beklentisi: rol bazlı “genel” ayarlar olabilir).
- `lock_enabled` / `setLockEnabled` **AppState’te var**, settings UI’da **yok**.
- Veli portal şifresi (`parent_password_hash` / per-parent hash) settings’te **yok**; hesap tabanlı şifre `AccountService.changePasswordAsAccountOwner` + `account_required_password_change_screen`.
- Admin şifre değişimi: `admin_profile_screen` **salt okuma**; self-service `changePasswordAsAccountOwner` profilde bağlı değil.
- Otomatik yedek aralığı alanı: mevcut `autoBackupMinutes` **gösterilmiyor** (yalnızca `onSubmitted`).
- Restore onay diyaloğu: “Cancel” / “OK” **sabit İngilizce** (l10n eksik).
- `saveSmtpSettings` / `loadSmtpSettings`: **servis seviyesinde öğretmen kontrolü yok** (UI öğretmenle gizli; route ile teorik risk — P9’da `AuthorizationService` veya AppState guard düşünülmeli).
- `setTeacherPassword` / `setStudentPassword` / `setSecretaryPassword`: **oturum rolü kontrolü yok** (yalnızca settings UI öğretmene açık).

### Yedek artefaktlar (kapsam dışı temizlik)

- `lib/screens/settings_screen.dart.restore_backup`
- `lib/providers/app_state.dart.restore_backup`, `.before_restore_fix`

---

## 2. Mevcut Notification Center yapısı

| Bileşen | Dosya | Not |
| --- | --- | --- |
| Merkez ekran | `lib/screens/notifications/notification_center_screen.dart` | **Standalone `Scaffold` + `AppBar`** — `AppShell` yok |
| Zil | `lib/widgets/notification_bell_button.dart` | `AppShell` header’da; `canViewOwnNotifications` |
| Navigasyon | `lib/utils/notification_navigation.dart` | Duyuru/belge referansına role göre yönlendirme |
| Fan-out | `lib/services/notification_fanout_service.dart` | Duyuru/belge yayınında bildirim üretimi |

### Mevcut işlevler

- Liste: `NotificationService.listForCurrentUser()` (limit 100, tarih DESC).
- Okunmamış göstergesi: kart border + nokta; shell badge `cachedUnreadNotificationCount`.
- Okundu: tap → `markAsRead` sonra referans navigasyonu veya snack “referans yok”.
- Tümünü okundu: AppBar `markAllAsRead`.
- Boş durum / yükleme / hata mesajı (`notificationAccessDenied`).

### Eksik (veri modeli / API yok — uydurma yapılmamalı)

- Bildirim **silme / temizleme** API’si yok (`bildirimler` DELETE yok).
- **Filtre** (tür, okundu/okunmadı) yalnızca client-side yapılabilir; kalıcı filtre yok.
- **Pagination** yok (sabit limit 100).

### Shell uyumsuzluğu (P9 odak)

- Bildirim merkezi açıldığında **sidebar/navbar kaybolur** — P6/P7/P8 pattern’i ile çelişir.
- Erişim reddi ekranı da standalone `Scaffold` (shell yok).

### P6 ile ayrım

- Öğrenci portalı **duyuru** listesi: portal içi içerik; **okundu durumu duyuru satırında persist edilmez** (bilinçli erteleme).
- `bildirimler` tablosu: **in-app notification** kanalı (fan-out); duyuru read-state ile **birleştirilmemeli**.

---

## 3. Mevcut DB / schema

- **Sürüm:** 34 (`DatabaseSyncService.databaseVersion`).
- **Ayarlar:** tablo `ayarlar` (`anahtar`, `deger`) — `getSetting` / `setSetting`.
- **Bildirimler:** migration v33 — `bildirimler` + index `idx_bildirimler_alici`.

Önemli `ayarlar` anahtarları (settings ile ilgili):

- `locale`, `theme_mode`
- `lock_enabled`, `teacher_password_hash`, `password_hash` (legacy), `student_password_hash`, `secretary_password_hash`, `parent_password_hash` (legacy shared)
- `auto_backup_enabled`, `auto_backup_minutes`
- `smtp_host`, `smtp_port`, `smtp_username`, `smtp_password`, `smtp_from_email`, `smtp_use_ssl`
- `TeacherDisplayName.settingKey` (öğretmen görünen ad)

**P9 için migration:** Mevcut model yeterli; **yeni tablo önerilmez**.

**Sync:** `bildirimler` export listesinde (`notifications_faz8_test`).

---

## 4. Mevcut notification model / service

| Katman | Dosya |
| --- | --- |
| Model | `lib/models/in_app_notification.dart` |
| Servis | `lib/services/notification_service.dart` |
| Alıcı | `lib/services/notification_recipient.dart` → `fromAppState` |

**IDOR koruması:** DB sorguları ve `markAsRead` / `markAllAsRead` her zaman `alici_rol` + `alici_id` ile scoped.

**Alıcı kimliği:**

| Rol | `userId` |
| --- | --- |
| student | `sessionStudentId` |
| parent | `sessionParentId` |
| teacher, secretary | `0` |
| admin | `sessionAccountId` |

**AppState:** `notificationRevision`, `refreshUnreadNotifications`, `bumpNotificationRevision` (mark sonrası).

---

## 5. Mevcut role / authorization sınırları

`lib/services/authorization_service.dart` (P9 ile ilgili):

| Bayrak | Koşul |
| --- | --- |
| `canAccessTeacherWorkspace` | `isTeacher` |
| `canViewOwnNotifications` | teacher **veya** student workspace **veya** (secretary + unlocked) **veya** parent **veya** admin |
| Backup (FAZ 12) | `AppState._requireTeacherForBackupOperations` — teacher + unlocked |

**Settings kritik işlemler:**

- Backup/restore/auto-backup: **servis** katmanında öğretmen — ✓ test (`faz12_authorization_test`).
- Portal şifreleri / SMTP / tags / question bank: **yalnızca UI** öğretmen settings’te — servis guard **kısmi/eksik**.

**Admin hesap işlemleri:** `AccountService` + `_requireAdmin` (P8); settings ekranından bağımsız.

**Veli/öğrenci veri scope:** P7/P10 parent-student link — settings P9’da değiştirilmez.

---

## 6. Mevcut password / security ayarları

| Akış | Mekanizma | Yetki |
| --- | --- | --- |
| Öğretmen portal şifresi | SHA-256 (runes) settings hash + default `ogretmen` | UI: öğretmen settings |
| Öğrenci portal (shared) | `student_password_hash` / default `ogrenci` | UI: öğretmen settings |
| Sekreter portal (shared) | `secretary_password_hash` | UI: öğretmen settings |
| Öğrenci numara+şifre (Faz 2.5) | DB `authenticateStudent` + domain login | Giriş ekranı |
| Veli | per-parent hash + legacy shared | Giriş; şifre değişimi **hesap** üzerinden |
| Admin / staff / portal hesapları | `hesaplar` hash, `mustChangePassword` | `loginRoleAccount`, `account_required_password_change_screen`, `AccountService.changePasswordAsAccountOwner` |
| Admin başka kullanıcı şifresi | `AccountService` reset (admin) | P8 kullanıcı yönetimi |

**P9 kuralı:** Hash algoritmasını değiştirme; plain-text saklama yok; yeni auth sistemi yok.

---

## 7. Mevcut backup / restore bağlantıları

| Katman | Dosya |
| --- | --- |
| Paket | `lib/services/backup_package_service.dart` |
| ZIP / dizin | `lib/services/backup_service.dart` |
| Sync meta | `lib/services/database_sync_service.dart` |
| AppState | `backupTo`, `buildBackupBytes`, `restoreFrom`, `beginSafeRestore` akışı, `_refreshAfterRestore` |

**UI:** Yalnızca `settings_screen.dart` (öğretmen).

**Güvenlik:** Restore öncesi onay diyaloğu; `BackupIntegrityException` → kullanıcı mesajı.

**P9:** Mekanizmayı yeniden yazma; admin-only restore **yok** (tasarım: öğretmen oturumu) — FAZ 12 ile uyumlu.

---

## 8. Responsive problemler

| Alan | Bulgu |
| --- | --- |
| Settings `ListView` | Geniş padding `AppSpacing.xl`; kartlar `isExpanded` dropdown — **360–430** genelde OK |
| Backup butonları | `Column` stretch — mobilde dikey stack ✓ |
| Etiket dialog | Sabit `420×260` — küçük ekranda taşma riski düşük (dialog) |
| Notification Center | `AppSpacing.pagePadding(width)`; kart padding `width < 600` — iyi başlangıç |
| AppBar “Tümünü okundu” | Dar ekranda `TextButton.icon` label **sıkışabilir** (360px) — P9’da `compact` veya icon-only + tooltip |
| Notification shell | Full-screen scaffold — mobil drawer erişimi **kaybolur** |

---

## 9. Accessibility problemler

| Alan | Bulgu |
| --- | --- |
| Settings dropdowns | Semantics/tooltip yok; standart Material |
| `SwitchListTile` auto-backup | OK (platform semantics) |
| Notification kartları | `InkWell` + metin; okunmamış nokta **semantics label yok** |
| Zil | `tooltip: notificationsMenu` ✓ |
| Mark all read | Metin buton; küçük ekranda touch target kontrolü |
| Restore confirm | İngilizce sabit butonlar — l10n + semantics |

**Borç:** P6/P7/P8 genel semantic turu — P9’da **yalnızca dokunulan** settings/notification widget’ları.

---

## 10. Test kapsamı

| Dosya | Kapsam |
| --- | --- |
| `test/notifications_faz8_test.dart` | Schema v34, oluşturma, izolasyon, mark read/all, dedup, fan-out |
| `test/faz12_authorization_test.dart` | Başka alıcının bildirimini okuma **false**; backup öğrenci oturumunda **denied** |
| `test/admin_account_management_faz9_test.dart` | Hesap şifre hash (ilgili) |

**Eksik (P9 hedefi):**

- Widget/integration: `SettingsScreen` açılışı, öğretmen dışı `/settings` mesajı
- Servis: SMTP/portal şifre çağrıları yetkisiz oturumda (eklenmeli mi — plan kararı)
- Notification Center widget smoke
- Rol regression matrisi (admin/teacher/student/parent/secretary) — çoğu servis testi mevcut; **UI route + shell** yok

**Mevcut sayı:** 193 test (P8 sonrası).

---

## 11. P9 implementation planı

Sıra: **PLAN → IMPLEMENTATION → TEST → ANALYZE → QA → DOC → FINAL STATUS**

### 11.1 Settings — mimari

1. **Rol-duyarlı settings ekranı** (tek dosya veya ortak `SettingsBody`):
   - **Tüm unlocked roller (veya ürün kararı):** Dil + tema (`setLocale` / `setThemeMode` — zaten global).
   - **Öğretmen only:** SMTP, portal şifreleri, tags, question bank, global search link, auto-backup, backup/restore, teacher display name.
   - **Admin:** Dil/tema + profil ekranına link veya gömülü `changePasswordAsAccountOwner` (mevcut hesap akışı); **backup UI öğretmen kuralında kalır**.
   - **Student / parent / secretary:** Dil/tema; şifre için **hesap** varsa `AccountRequiredPasswordChange` pattern / profil — **yeni hash sistemi yok**.

2. **Shell:**
   - Settings’i ilgili workspace `AppShell` ile aç (`teacherSection` / `studentSection` / …); erişim reddinde **doğru rol sidebar’ı**, öğretmen shell’i zorlamama.

3. **Navigation (opsiyonel minimal):**
   - Student/parent/admin profil veya drawer’a “Ayarlar” — yalnızca genel bölümler.

4. **AuthorizationService genişletme (öneri):**
   - `canManageTeacherSettings`, `canManageBackupRestore`, `canManagePortalPasswords`, `canManageSmtpSettings` — UI **ve** AppState guard (`saveSmtpSettings`, portal password setters) için.

5. **UX düzeltmeleri:**
   - Auto-backup minutes controller ile mevcut değer.
   - Restore confirm l10n.
   - Settings grupları: Genel (dil/tema), Görünüm (tema altında veya birleşik), Bildirimler (yalnızca merkeze link — push notification prefs **yok**), Güvenlik, Veri/Backup (öğretmen).

### 11.2 Notification Center

1. **`AppShell` sarmalayıcı:** `NotificationCenterScreen` içeriğini shell child yap; başlık `PageHeader` veya shell title; geri navigasyon drawer ile uyumlu.
2. **Rol parametresi:** `teacherSection` / `studentSection` / … push anında `NotificationBellButton`’dan aktarım (veya `AppState.currentRole` ile shell seçimi).
3. **Mobil AppBar aksiyonları:** Mark-all-read responsive (tooltip, `Semantics`).
4. **Filtre/temizleme:** **Yapma** (DB API yok); isteğe bağlı client-only “show unread” toggle (scope dışı sayılabilir — minimal tut).
5. **Admin bildirim navigasyonu:** `notification_navigation.dart` duyuru için admin `break` — bilinçli; P9’da iyileştirme yalnızca mevcut referans türleriyle.

### 11.3 Test planı

- `test/settings_notification_p9_test.dart` (önerilen ad):
  - Teacher backup denied when student session (mevcut — regression).
  - Settings: non-teacher sees denial OR general sections only (implementation’a göre assert).
  - `saveSmtpSettings` / password setters throw when not teacher (if guards added).
  - Notification list isolation (mevcut faz8/faz12 — regression import veya tek smoke).
  - Widget: pump `SettingsScreen` teacher + `NotificationCenter` with `AppShell` mock/provider.

### 11.4 Analyze / deprecation

- `DropdownButtonFormField.value` — settings’te `DropdownButton` kullanılıyor (farklı widget); P9 dosyalarına dokunulursa admin/parent’daki deprecation **güvenliyse** güncelle; kapsam dışı geniş refactor yok.

### 11.5 Dokümantasyon

- `docs/actions/faz_13.md` §17 P9 satırı + P9 alt tablo (implementation sonrası).
- Bu audit dosyası **korunur**; final raporda değişen dosya listesi.

---

## 12. P9 kapsamı dışındaki işler

| Konu | Neden |
| --- | --- |
| P10 mobil bottom nav | §17 deferred |
| P11 legacy ekran temizliği | Ayrı öncelik |
| Duyuru read/unread persist (öğrenci portal listesi) | P6 bilinçli erteleme |
| `bildirimler` silme / arşiv API | Model yok |
| Firebase / push / REST bildirim | Yeni altyapı |
| Backup’ı admin-only yapma | FAZ 12 öğretmen kuralı |
| `lock_enabled` UI ekleme | Ürün kararı gerekir; audit’te zorunlu değil |
| Question bank / global search route guard (tüm roller) | FAZ 12 deferred |
| Tam app-wide accessibility refactor | P6/P7/P8 borcu |
| Yeni settings tablosu veya auth sistemi | Yasak |
| `settings_screen.dart.restore_backup` silme | P11 temizlik |

---

## Özet riskler (implementation öncesi)

1. **UI-only authorization** portal şifreleri ve SMTP için — P9’da servis guard tamamlanmalı.
2. **Notification Center** shell dışı — UX ve mobil drawer.
3. **Non-teacher** dil/tema erişimi yok — P9 kullanıcı beklentisi ile hizalanmalı.
4. **Admin/hesap şifresi** settings ile profil arasında kopukluk.

---

*Audit tamamlandı — implementation başlamadan önce bu plan onaylanabilir veya doğrudan §11 sırası uygulanır.*

---

## Implementation durumu (2026-10-08)

| §11 maddesi | Durum |
| --- | --- |
| Rol-duyarlı Settings + `WorkspaceAppShell` | ✓ |
| `AuthorizationService` bayrakları (locale/SMTP/backup/portal) | ✓ |
| AppState servis guard (SMTP, portal şifre, locale/tema) | ✓ |
| Notification Center → AppShell | ✓ |
| Delete/filter API | Yapılmadı (kapsam dışı) |
| Sidebar’da öğrenci/veli “Ayarlar” menüsü | Yapılmadı — `/settings` route + genel bölümler |
| Admin profilde şifre değişimi UI | Yapılmadı — mevcut hesap akışı |
| `test/settings_notification_p9_test.dart` | ✓ (unit; tam ekran widget smoke CI’da yavaş — authorization + servis) |

**DB / migration:** Yok — schema **v34**

**Değişen dosyalar:**

- `lib/screens/settings_screen.dart`
- `lib/screens/notifications/notification_center_screen.dart`
- `lib/services/authorization_service.dart`
- `lib/providers/app_state.dart`
- `lib/utils/workspace_app_shell.dart` (yeni)
- `lib/l10n/app_localizations.dart`
- `test/settings_notification_p9_test.dart` (yeni)
- `docs/actions/faz_13.md`
