# FAZ 13 — Application-Wide UI/UX, Content & Navigation Audit

## 1. Amaç

FAZ 12 sonrası MyEduApp’in **tüm rol workspace’lerinde** görsel dil, bilgi mimarisi ve responsive davranışı, kullanıcı referans tasarımına (**MyEduApp** branding) mümkün olduğunca birebir yaklaştırmak; **mevcut business logic, security, authorization ve DB (v34)** altyapısını korumak.

Bu faz **tema rengi değiştirmekten** daha geniş kapsamlıdır: ekran envanteri → navigasyon tutarlılığı → tek design system → sayfa bazlı uygulama.

### KRİTİK KURAL (FAZ 13)

**Önce bu audit tamamlanır; audit onaylanmadan geniş UI refactor yapılmaz.**

Korunacak fazlar:

| Faz | Dokunulmaz alan |
| --- | --- |
| FAZ 10 | Parent email/username login, Parent IDOR |
| FAZ 11 | `mustChangePassword` + `AccountRequiredPasswordChangeScreen` akışı |
| FAZ 12 | Settings/backup `AuthorizationService` + `TeacherBackupAccessDeniedException` |

---

## 2. AUDIT BASELINE

| Metrik | Değer |
| --- | --- |
| Test (son doğrulanan) | **187 passed / 0 failed** |
| DB sürümü | **v34** (`DatabaseSyncService.databaseVersion`) |
| Ana UI referans | `docs/design/myeduapp_ui_reference.png` → `assets/design/` |
| Ders oluşturucu referans | `assets/design_reference/lesson_ui_design.png` |
| `docs/new_updates/faz_13.md` | İlerleme özeti + FINAL STATUS (güncellenir) |

---

## 3. REFERANS TASARIM ÖZETİ

`lesson_ui_design.png` iki ana yüzey gösterir:

1. **Ders Oluşturucu (`AppBuilderScreen`)** — Sol: blok paleti (Metin, PDF, Video, Ödev, Soru, Sınav…); orta: sınıf/ders/konu seçimi + içerik alanı; sağ: “Sınıf/Ders/Konu Ayarları” + mor birincil CTA’lar; üst: geri, başlık, alt başlık, Düzenle/Önizleme segmented control.
2. **Uygulama içeriği editörü** — Koyu üst bar, zengin metin araç çubuğu, favoriler toggle, boş durum illüstrasyonu.

**Renk dili (mockup):** mor/lavanta birincil (`~#6D5BD0` / `#4F46E5` ailesi), açık gri workspace, beyaz kartlar, yumuşak gölge, 12–16px radius.

**Uygulama adı:** mockup’ta **MyEduApp** (kitap ikonu).

**Audit notu:** Mockup verileri (ör. öğrenci adları, notlar) **hardcode edilmeyecek**; tüm KPI/tablo/liste `AppState` / service / DB kaynaklı kalacak.

---

## 4. MEVCUT DESIGN SYSTEM

### 4.1 Merkezi token’lar

| Katman | Dosya | Durum |
| --- | --- | --- |
| Renkler | `lib/theme/app_colors.dart` | Navy sidebar (`#1A2744`), mavi birincil (`#2563EB`), workspace `#F4F6FA` — referansla **kısmen uyumlu** |
| Spacing / breakpoint | `lib/theme/app_spacing.dart` | mobile &lt;600, desktop ≥1024, sidebar 260/72 |
| ThemeData | `lib/theme/app_theme.dart` | M3, kart/input/button/dialog/table — **ana sistem** |
| Kartlar | `lib/widgets/app_card.dart` (`AppCard`, `StatCard`) | Teacher dashboard vb. |
| Boş durum | `lib/widgets/app_empty_state.dart` | Tutarsız kullanım |
| Shell | `lib/widgets/app_shell.dart` + `page_header.dart` | Navy sidebar, üst navbar, mobil drawer |

### 4.2 Paralel / ikincil sistem (birleştirme gerekli)

| Katman | Dosya | Sorun |
| --- | --- | --- |
| Secretary UI | `secretary_ui/secretary_design.dart` | **Indigo** birincil (`#4F46E5`), glass/blur kartlar, farklı workspace bg (`#F8FAFC`) — `AppColors` ile **çift dil** |
| Secretary formlar | `secretary_student_form.dart`, `secretary_parent_form.dart` | Hardcoded `#4F46E5` butonlar |
| Lesson platform | `lesson_platform_page.dart`, `lesson_screen.dart` (legacy) | Eski `#F5F7FB` / beyaz AppBar kalıntıları |
| Student portal widgets | `student_summary_card.dart` | Yerel stiller |

**FAZ 13 hedefi:** `AppTheme` + `AppColors` + ortak widget’ları **genişlet**; Secretary mor/indigo tonunu **tek palete** map et (referans mor veya mevcut navy+mavi hibrit — karar: referans **mor birincil**, navy **sidebar** kalır).

### 4.3 Dark theme

`AppTheme.dark()` yalnızca `ColorScheme.fromSeed` — production’da `themeMode` kullanılıyor ama workspace’ler **light’a optimize**. FAZ 13: light öncelik; dark **deferred**.

---

## 5. BACKGROUND / GÖRSEL ALTYAPI

| Konum | Mevcut davranış |
| --- | --- |
| `HomeScreen` / `HomeBrandPanel` | **Gradient** (slate/blue), özel `_EducationIllustration` (kod çizimi) — **kaliteli, asset gerektirmiyor** |
| Workspace’ler | Düz `AppColors.background` veya `SecretaryDesign.workspaceBackground` |
| `pubspec.yaml` | **Flutter assets tanımlı değil**; `design_reference` PNG yalnızca dokümantasyon |
| `DecorationImage` / `AssetImage` | **lib içinde kullanım yok** |

**Öneri (implementation):**

- Ortak `AppWorkspaceScaffold` / `AppBrandBackground`: login’deki gradient + hafif pattern veya blur overlay; içerik alanında **opak surface** katmanı (okunabilirlik).
- Mobil: gradient `BoxFit.cover` + `SafeArea`; performans için **statik gradient**, ağır blur yalnızca desktop opsiyonel.
- Secretary glass kartlar: blur’u **isteğe bağlı** veya düz `AppCard` ile değiştir (Windows düşük GPU’da jank riski).

---

## 6. NAVIGATION MİMARİSİ

### 6.1 Ortak shell

`AppShell` tüm ana roller için:

- Desktop: sabit navy sidebar (hover expand 72→260) + `PageHeader` + içerik.
- Mobile: `Drawer` + `AppBar` (çift menü butonu riski `leading` custom olduğunda — `app_shell.dart` satır 182–191).
- Teacher: ek `_TeacherNavTabBar` (açık sekme chip’leri) — **referansta yok**, fakat multi-tab teacher UX için **korunmalı**.

### 6.2 Rol bazlı sidebar menüleri

| Rol | Kaynak | Ana maddeler |
| --- | --- | --- |
| **Admin** | `adminSidebarMenuOrder` | Overview, Users, User Add, Profile |
| **Teacher** | `app_shell._teacherItems` | Home, Ders Platformu (alt: subjects/courses/units/topics/documents), Öğrenci Platformu, Akademik Planlar (alt), Mentörlük, Raporlar, Kılavuz, Ayarlar |
| **Secretary** | `secretaryMainMenuOrder` + profile | Home, Öğrenci/Veli hub, Sınıf/Şube hub, Yoklama hub, Profile |
| **Student** | `studentSidebarMenuOrder` | Home, Courses, Weekly schedule, Assignments, Exams, Performance, Attendance, Documents, Announcements, Profile (`lessonPlatform` sidebar’da **yok**, legacy enum) |
| **Parent** | `parentSidebarMenuOrder` | Home, Children, Announcements, Documents, Attendance, Academic, Profile |

### 6.3 Secretary — bilgi mimarisi boşlukları

| Özellik | Sidebar | Erişim |
| --- | --- | --- |
| Duyurular | **Yok** | Dashboard quick action → `announcementList` |
| Belgeler | **Yok** | Dashboard quick action → `documentList` |
| Öğrenci ekle / veli ekle | **Yok** (hub içi) | `openSecretarySection` → hub + slide panel |
| Eski enum’lar (`studentList`, `parentAdd`, …) | Gizli | `AppState.openSecretarySection` canonical hub’a **yönlendiriyor** ✓ |

**Öneri:** Duyuru/Belge için sidebar’a **ikincil grup** veya footer linkleri ekle; özelliği silme. Dashboard kartları kalabilir.

### 6.4 Teacher — ders platformu

- **Görüntüleme:** `AppViewerScreen` (`AppShell` + lesson platform alt menü).
- **Oluşturma:** `AppBuilderScreen` — `Navigator.push` ile açılıyor; shell’de `teacherSection` **geçilmiyor** → sidebar **kaybolabilir** / tam ekran hissi (audit: builder açıkken teacher context korunmalı).
- **Legacy:** `lesson_screen.dart` — **hiç import edilmiyor** (ölü kod + `.before_*` yedekleri).

### 6.5 Global route’lar (`lib/app.dart`)

| Route | Ekran | Shell |
| --- | --- | --- |
| `/` | `HomeScreen` | Kendi layout |
| `/settings` | `SettingsScreen` | `AppShell` (teacher) |
| `/question-bank` | `QuestionBankScreen` | Scaffold only |
| `/search` | `GlobalSearchScreen` | Scaffold only |
| `/user-guide` | `UserGuideScreen` | `AppShell` |

**Öneri:** Named route ekranlarını aynı shell/back stack politikasına çek veya teacher workspace’ten push yerine tab içi aç.

### 6.6 Auth / gate ekranları (shell dışı — doğru)

- `HomeScreen`, login dialog’ları, `AdminBootstrapScreen`, `AccountRequiredPasswordChangeScreen`, `ChangeTeacherPasswordScreen` — **shell yok** (beklenen).

### 6.7 Mentorship / rapor push stack

- `MentorshipDashboardScreen`, `MentorshipStudentDetailScreen`, `MentorshipBehaviorReportsScreen` — çoğu `AppShell` kullanıyor; student detail **standalone Scaffold** — mobilde sidebar kaybı.

---

## 7. EKRAN ENVANTERİ (İŞLEV ÖZETİ)

### 7.1 Giriş & hesap

| Ekran | İşlev |
| --- | --- |
| `home_screen.dart` | Rol seçimi, account/legacy login |
| `home/*_login_dialog.dart`, `role_account_login_dialog.dart` | Modal giriş |
| `admin_bootstrap_screen.dart` | İlk admin kurulumu |
| `account_required_password_change_screen.dart` | FAZ 11 zorunlu şifre |
| `change_teacher_password_screen.dart` | Legacy öğretmen şifre |

### 7.2 Admin (4 section + bootstrap)

| Section | Ekran | İşlev |
| --- | --- | --- |
| home | `admin_home_screen.dart` | KPI / özet |
| users | `admin_users_list_screen.dart` | Hesap listesi, aktif/pasif |
| userAdd | `admin_user_add_screen.dart` | Personel + portal hesabı |
| profile | `admin_profile_screen.dart` | Admin profil |

### 7.3 Teacher

| Section | Ekran | İşlev |
| --- | --- | --- |
| home | `teacher_menu_screen.dart` | Dashboard, sınıf listesi, defter, aktivite |
| lessonPlatform | `app_viewer_screen.dart` | Müfredat gezinme, materyal/ödev görüntüleme |
| (push) | `app_builder_screen.dart` | **Kurs/ders içerik oluşturma** (blok editör) |
| studentPlatform | `student_platform_screen.dart` | Sınıf bazlı not/yoklama/ödev/kategori (**~3100 satır**) |
| academicPlans | `academic_plans_screen.dart` + paneller | Günlük/yıllık plan, haftalık çizelge |
| mentorship | `mentorship_class_select_screen.dart` → dashboard/detail/reports | Davranış/mentörlük |
| reports | `student_report_screen.dart` | PDF/Excel performans |
| userGuide | `user_guide_screen.dart` | Statik yardım |
| settings | `settings_screen.dart` | Yedekleme, SMTP, etiketler (FAZ 12 gated) |

### 7.4 Secretary

| Canonical UI | Alt bileşenler |
| --- | --- |
| `secretary_tab_workspace.dart` | `AppShell` + section switch |
| Dashboard | `secretary_dashboard_screen.dart` — KPI + quick links |
| Öğrenci/Veli hub | `secretary_students_parents_hub_screen.dart` — tab + slide panel; `secretary_students_list_screen`, `secretary_parents_list_screen`, formlar |
| Sınıf/Şube hub | `secretary_classes_sections_hub_screen.dart` — accordion (eski `secretary_classes_screen` / `secretary_sections_screen` **kullanılmıyor**) |
| Yoklama hub | `secretary_attendance_hub_screen.dart` + daily/history |
| Duyuru/belge | list/add/detail ekranları |
| Profil | `secretary_profile_screen.dart` |

**Ölü / legacy dosyalar (runtime’da bağlı değil):**

- `secretary_home_screen.dart` (dashboard ile değiştirildi)
- `secretary_student_add_screen.dart`, `secretary_parent_add_screen.dart`
- `secretary_classes_screen.dart`, `secretary_sections_screen.dart`
- `lesson_screen.dart` (+ `.before_ui`, `.before_design`)

**Aksiyon:** UI fazında **silme yerine** arşiv veya birleştirme; test/import kırılmasın.

### 7.5 Student

`student_tab_workspace.dart` → `student_portal_section_screens.dart` içinde 10+ section (courses, assignments, exams, …), `student_dashboard_screen.dart`, `student_session_gate.dart`.

### 7.6 Parent

`parent_tab_workspace.dart` → `parent_portal_screens.dart` (7 section).

### 7.7 Ortak / yardımcı

- `notification_center_screen.dart`, `global_search_screen.dart`, `question_bank_screen.dart`
- `student_behaviors_panel.dart` (mentorship içi embed)
- `app_viewer_screen.dart` / `content_preview.dart` (önizleme ağır widget)

**Toplam:** ~84 `lib/screens/**/*.dart` (yedek/legacy dahil).

---

## 8. DUPLICATE / BİRLEŞTİRME ANALİZİ

| Bulgu | Önerilen aksiyon |
| --- | --- |
| Secretary `SecretaryDesign` vs `AppTheme` | Secretary token’ları `AppColors`/`AppTheme` extension’a taşı; glass → `AppCard` variant |
| İki “home” secretary | `SecretaryHomeScreen` kaldır (dosya dead) |
| `lesson_screen` vs `AppViewerScreen` | Legacy dosyaları temizle (faz sonu) |
| Teacher announcements | Hem menü hem `StudentPlatformScreen` push — **koru**, UI tutarlılığı için aynı kart/liste bileşeni |
| Settings | Route + teacher tab — **koru**, FAZ 12 auth aynı |
| Student `lessonPlatform` enum | Sidebar’da yok; courses ile overlap — deep link varsa **redirect** courses |

---

## 9. RESPONSIVE & MOBİL BULGULAR

| Alan | Bulgu | Öncelik |
| --- | --- | --- |
| `AppShell` mobile | Drawer + AppBar; teacher tab bar mobilde **gizli** (yalnızca desktop column) — teacher tab geçişi mobilde yalnızca sidebar’dan |
| `app_builder_screen.dart` | Mobile: 3-tab; tablet/desktop: sabit kolon genişlikleri (168–320px) — **iyi**; referans mor header/toolbar eksik |
| `student_platform_screen.dart` | `width: 420`, `520` sabit paneller — **tablet dar ekranda taşma riski** |
| `teacher_menu_screen.dart` | Grid `LayoutBuilder` — genelde iyi |
| Secretary tablolar | `secretary_paginated_table.dart` — desktop ağırlıklı; mobilde **kart listeye** dönüşüm gerekli |
| Dialog’lar | `AppSpacing.dialogMaxWidth` var; secretary slide panel — mobil uyumlu ✓ |
| Touch target | Sidebar collapsed 72px — ikonlar OK; dense DataTable satırları **risk** |
| Klavye | Form ekranlarında `SingleChildScrollView` tutarsız — audit implementation’da kontrol listesi |

### 9.1 Kurs Oluşturma Platformu (`AppBuilderScreen`) — özel inceleme

- **İşlev:** Ders → kurs → ünite → konu hiyerarşisi; sol blok paleti; orta drop zone; sağ CRUD ayar paneli; preview modu.
- **Genişlik:** Desktop üç kolon toplamı ~800px+ sabit yan panel — **≥1280 ideal**; 1024’te orta kolon daralır (Expanded flex 3).
- **Referans gap:** Mor üst başlık bandı, blok listesi görsel hiyerarşisi, sağ panel “Sınıf Ekle” hero butonu, boş durum illüstrasyonu — kodda **fonksiyonel** ama görsel olarak sade.
- **Nav:** Builder açıkken `teacherSection` null — sidebar teacher menüsü **görünmüyor** (yüksek öncelik düzeltme).

---

## 10. BRANDING

| Kontrol | Sonuç |
| --- | --- |
| `appTitle` / `MaterialApp.title` | **MyEduApp** ✓ |
| `msix_config.display_name` | **MyEduApp** ✓ |
| Eski “MyEdu” (uygulama adı) | **Bulunamadı** |
| `MyEducare` | PDF export açıklama metninde **harici ürün adı** — değiştirme (iş kuralı) |

---

## 11. ERİŞİLEBİLİRLİK & İÇERİK

- L10n: `app_localizations.dart` tek dosya TR/EN — UI audit’te yeni key’ler eklenecek.
- Semantik: çoğu `IconButton` tooltip var; tablolar **screen reader** için `DataTable` sınırlı.
- Boş/loading/error: `SecretaryDashboard` FutureBuilder spinner; ortak `AppEmptyState` **her yerde değil**.
- İçerik önizleme: `content_preview.dart` — ayrı UX adası (video/PDF/webview).

---

## 12. PERFORMANS RİSKLERİ

- Secretary `BackdropFilter` glass kartlar — çok kartlı listelerde repaint.
- `student_platform_screen.dart` monolith rebuild.
- `AppViewerScreen` ~2400 satır — section değişiminde ağır build.
- Test izolasyonu (FAZ 12 sonrası 187 pass) — UI değişikliklerinde widget test güncellemesi gerekebilir.

---

## 13. IMPLEMENTATION PLANI (AUDIT SONRASI)

### Faz A — Design system birleştirme (düşük risk)

1. `AppColors`: referans mor birincil token (`brandPrimary`) + secretary alias.
2. `AppTheme`: elevated card shadow, badge, segmented button (builder header).
3. `AppWorkspaceBackground` widget; home gradient’i paylaş.
4. `SecretaryDesign` → ince wrapper veya deprecate; formlarda theme `FilledButton`.

### Faz B — Shell & navigation

1. `AppBuilderScreen`: `teacherSection: lessonPlatform` + back stack tutarlılığı.
2. Secretary sidebar: duyuru + belge maddeleri (veya “İdari” alt grubu).
3. Mobile: teacher tab bar veya bottom nav **değerlendirme** (deferred if sidebar yeterli).
4. Named routes: shell wrapper veya teacher workspace’e embed.

### Faz C — Sayfa dönüşümleri (referans sırası)

1. **AppBuilderScreen** + blok paleti (referans 1:1).
2. **HomeScreen** login (referans login yok — brand panel güçlendirme).
3. **TeacherMenuScreen** dashboard kartları.
4. **Secretary** hub/listeler → ortak tablo/kart responsive.
5. **Admin / Parent / Student** dashboard ve listeler.
6. **Student platform** genişlik refactor (420/520 → breakpoint tabanlı).

### Faz D — Temizlik

- Ölü secretary/lesson dosyalarını kaldır veya `legacy/` taşı.
- `settings_screen.dart.restore_backup` vb. yedekleri repo dışı.

### Test stratejisi

- Her faz sonu: `flutter test` → **0 failed**.
- UI testleri: `teacher_menu_screen_test`, `secretary_tab_workspace_test` — finder/layout güncelle; **auth assertion değiştirme**.

---

## 14. RİSKLER & DEFERRED

| Risk | Mitigasyon |
| --- | --- |
| Çift theme sistemi kalırsa görsel drift | Faz A zorunlu |
| Builder sidebar kaybı | Faz B.1 |
| Monolith screen refactor regression | Küçük PR’lar, test |
| Dark mode | Deferred |
| Tam mockup rich text toolbar | Mevcut blok editör scope’u — kademeli |

---

## 15. AUDIT SONUCU

| Kriter | Durum |
| --- | --- |
| Ekran envanteri | ✓ |
| Navigation haritası | ✓ |
| Design system analizi | ✓ |
| Background altyapısı | ✓ (gradient kod tabanlı) |
| Responsive gap listesi | ✓ |
| Branding | ✓ MyEduApp |
| Security fazları | ✓ dokunulmaz işaretlendi |
| Kod değişikliği (audit aşaması) | **Yok** |

**Sonraki adım:** Faz A implementation (design system + `AppWorkspaceBackground` + Secretary token birleştirme), ardından `AppBuilderScreen` referans uyumu.

---

## 16. IMPLEMENTATION DURUMU (2026-10-07 tur 2)

| Alan | Durum | Not |
| --- | --- | --- |
| `AppWorkspaceBackground` | ✓ | `AppShell` içerik alanı (tüm roller) |
| `brandPrimary` | ✓ | Theme Filled/Outlined, `AppCard`, dashboard |
| Teacher Dashboard | ✓ | Hero welcome + 4 KPI satırı; 2 kolon grid; “Kısa Analizler” kartı KPI’ya taşındı |
| Student Platform | ✓ kısmi | Sidebar %30 clamp 240–380; dialog maxWidth responsive |
| Course Creator | ✓ kısmi | Shell background; mor hiyerarşi korunuyor |
| Secretary | ✓ kısmi | Dashboard KPI rengi; glass kart sistemi aynı |
| Button system | ✓ kısmi | Global `FilledButton` → `brandPrimary` |
| AppShell | ✓ | Tek background katmanı |
| Mobile | PARTIAL | Dashboard 1–2 kolon; student platform mobil bar aynı |
| Tests | Güncellendi | `teacher_menu_screen_test` izole DB + yeni dashboard metinleri |
| Sidebar profil | ✓ | `AppSidebarProfile` — shell altı avatar + rol |
| Giriş marka | ✓ kısmi | `homeBrandTagline` referans sloganı |
| Öğrenci portalı (P6) | ✓ kısmi | Dashboard KPI (`ReferenceStatCard`), responsive kartlar, profil/duyuru/belge UI, haftalık program yükseklik düzeltmesi |

### P6 — Öğrenci portalı (2026-10-07)

| Alan | Durum | Not |
| --- | --- | --- |
| Shell | ✓ | Mevcut `AppShell` + `AppWorkspaceBackground` + drawer |
| Dashboard | ✓ kısmi | Hero + özet + KPI + bölüm kartları, Tümünü gör |
| Dersler | ✓ kısmi | Responsive grid / liste, `StudentCourseCard` |
| Detay panelleri | ✓ kısmi | `StudentPortalActivityCard`, profil satır responsive |
| Duyurular | ✓ kısmi | `ExpansionTile` kartları |
| Belgeler | ✓ kısmi | Tip/tarih chip; içerik açma modelde id yok |
| Akademik / performans | PARTIAL | Mevcut veri listeleri; tablo genişliği sınırlı |
| Bildirimler | ✓ | Shell `NotificationBellButton` (değişmedi) |
| Profil | ✓ kısmi | Avatar header + responsive bilgi satırları |
| Responsive | ✓ kısmi | 360+ mobil kart düzeni; haftalık program yatay scroll |
| Accessibility | PARTIAL | ExpansionTile; ek semantic label turu gerekir |
| Security | ✓ | Servis/auth katmanına dokunulmadı |

---

## 17. EKRAN ÖNCELİK PLANI (rollout)

Referans: `docs/design/myeduapp_ui_reference.png` (+ Ders Oluşturucu mor paneli ayrı).

| Öncelik | Ekran / alan | Dosya(lar) | Durum |
| --- | --- | --- | --- |
| P0 | Global shell — sidebar profil, navy, çıkış | `app_shell.dart`, `app_sidebar_profile.dart` | ✓ |
| P1 | Giriş / rol seçim — marka paneli | `home_screen.dart`, `home_brand_panel.dart`, `home_role_card.dart` | ✓ kısmi |
| P2 | Öğretmen ana sayfa — KPI, duyuru, sınıf grid | `teacher_menu_screen.dart` | ✓ |
| P3 | Öğrenci platformu — araç çubuğu, tablo | `student_platform_screen.dart` | ✓ kısmi |
| P4 | Ders Oluşturucu — mor builder + shell | `app_builder_screen.dart` | ✓ kısmi |
| P5 | Sekreter paneli — 2×3 hub + rapor kartları | `secretary_dashboard_screen.dart` | ✓ kısmi |
| P6 | Öğrenci portalı | `student_tab_workspace.dart`, section ekranları | ✓ kısmi |
| P7 | Veli portalı | `parent_portal_screens.dart` | ✓ kısmi |
| P8 | Yönetici | `admin_*_screen.dart` | ✓ kısmi |
| P9 | Ayarlar / bildirimler | `settings_screen.dart`, `notification_center_screen.dart` | ✓ kısmi |
| P10 | Mobil bottom nav + UX/RBAC | `app_mobile_bottom_nav.dart`, `app_shell.dart` | ✓ kısmi |
| P11 | Temizlik — ölü ekranlar | `lesson_screen.dart`, legacy secretary | ⏳ |

Her tamamlanan öncelik: `flutter test` (0 failed), `flutter analyze lib/` (yeni hata yok).

### P8 — Yönetici portalı (2026-10-08)

Audit: `docs/actions/faz_15_admin_audit.md`

| Alan | Durum |
| --- | --- |
| Shell | PASS — `AdminTabWorkspace` + `AppShell` |
| Dashboard | PARTIAL — `AdminPortalService` KPI + hızlı işlemler |
| Kullanıcı yönetimi | PASS — mevcut liste/ekle (FAZ 9) |
| Öğrenci/öğretmen CRUD UI | N/A — sekreter paneli |
| Authorization | PASS — `AccountService._requireAdmin` |
| DB migration | Yok (v34) |

### P9 — Ayarlar + Bildirim Merkezi (2026-10-08)

Audit: `docs/actions/faz_15_p9_audit.md`

| Alan | Durum |
| --- | --- |
| Rol-duyarlı Settings | PASS — dil/tema tüm workspace; öğretmen-only bölümler korundu |
| SMTP / portal şifre guard | PASS — `TeacherSettingsAccessDeniedException` + `AuthorizationService` |
| Backup / restore | PASS — FAZ 12 öğretmen koruması aynı |
| Notification Center | PASS — `WorkspaceAppShell`; scope servis katmanında |
| AppShell entegrasyonu | PASS — sidebar/drawer bildirim + ayarlar |
| Responsive | PARTIAL — dar ekranda mark-all-read icon; genel layout mevcut |
| Accessibility | PARTIAL — bildirim kartı Semantics; kapsamlı tur yok |
| DB migration | Yok (v34) |
| Test | `test/settings_notification_p9_test.dart` (+7); toplam **200** passed |

### P10 — Mobil navigation + UX/RBAC (2026-10-08)

Kaynak: `docs/actions/faz_13_14.md`

| Alan | Durum |
| --- | --- |
| Mobile bottom nav | PASS — `<600px`, rol bazlı 4 destination |
| Settings drawer shortcut | PASS — student/parent/secretary/admin + `openAppSettings` |
| Admin şifre değiştir | PASS — `changePasswordAsAccountOwner` |
| Teacher display name guard | PASS — `AppState.setTeacherDisplayName` |
| Responsive / a11y | PARTIAL — kod incelemesi + mevcut pattern; tam manuel matris yok |
| DB migration | Yok (v34) |
| Test | `mobile_navigation_p10_test.dart`, `settings_authorization_p10_test.dart`; toplam **214** passed |

---

*Audit tarihi: 2026-10-07 — FAZ 13 Phase 0*
