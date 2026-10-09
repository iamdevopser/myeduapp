# MyEduApp — Design Redesign Plan (Agent 1 Audit)

**Tarih:** 2026-10-08  
**Kaynak talimat:** [`docs/Master Prompt — MyEduApp Tasarım Uygulama ve Geliştirme.md`](../Master%20Prompt%20—%20MyEduApp%20Tasarım%20Uygulama%20ve%20Geliştirme.md)  
**Tasarım referansı:** `docs/design/MyEduApp_design_pages_separated/` (16 görsel)  
**Baseline:** Faz 2 final — [`faz_design_faz2_final_status.md`](faz_design_faz2_final_status.md) (231 test, DB v35, öğrenci portal 08/09/11/12 işlev PASS)

> **Agent 1 kapsamı:** Yalnızca inceleme ve plan. `lib/`, `test/`, `pubspec.yaml` üzerinde değişiklik yapılmadı.

---

## 1. Executive Summary

MyEduApp, Faz 1–2 ile ortak **Design System** (`DesignSystem`, `lib/widgets/design/*`) ve **AppShell** (masaüstü sidebar + mobil drawer + rol bazlı alt navigasyon) üzerinde ilerlemiş durumda. Öğrenci portalı duyuru, takvim, doküman ve detay akışları **gerçek SQLite verisi** ile Faz 2’de işlevsel olarak kapatıldı; sekreter öğrenci detayında notlar, öğretmen mobil akademik takvim ve admin duyuru bloğu güncellendi.

16 referans görselin tamamı incelendi. **Hiçbiri** mevcut uygulamada piksel düzeyinde **MATCH** değil; çoğu **PARTIAL** (doğru ekran/rol, eksik layout/hiyerarşi veya ürün farkı). **1 ekran MISSING:** tasarım **07 Mesajlar** için tam ekran ve veri modeli uygulamada yok (Faz 2 bilinçli kapsam dışı).

Önerilen yol: Mevcut mimariyi koruyarak **küçük fazlar** — önce shell/tokens, sonra hub/liste ekranları (02/13/14/03/04), ardından öğrenci portal cilası, a11y ve 8 breakpoint QA. **07 Mesajlar** için ürün kararı + altyapı olmadan UI üretilmemeli (BLOCKED).

---

## 2. Current Baseline

### 2.1 Faz 2 final (korunacak)

| Alan | Durum | Not |
| --- | --- | --- |
| Testler | 231 passed / 0 failed | `design_faz2_*`, `design_tur*`, migration v35 |
| DB | v35 | `kapak_gorsel_yolu`, mentorluk `veli_toplantisi` |
| 08/09/11/12 öğrenci | İşlev PASS | Bildirim→detay, takvim, viewer, kapak görseli (dosya varsa) |
| 05 notlar | PASS | `SecretaryStudentGradesPanel` |
| 06 öğretmen mobil | PASS | `<1024` ay grid + ders listesi |
| 02 admin duyuru bloğu | PASS (işlev) | `DesignFeedRow` — dashboard geneli hâlâ PARTIAL |
| Responsive test | Widget | 360–1920 (`design_faz2_responsive_test.dart`) |
| A11y | PARTIAL | Semantics nokta atışı; WCAG matrisi yok |
| BLOCKED | Doküman boyutu, öğretmen kapak UI, tam a11y | Final raporda kayıtlı |

### 2.2 Navigation / AppShell

- **`AppShell`** (`lib/widgets/app_shell.dart`): `width < 600` → drawer + isteğe bağlı **mobile bottom nav**; `≥600` → sabit `_AppSidebar` (260px, hover/tap genişleme), `PageHeader`, bildirim zili.
- **`WorkspaceAppShell`**: Rol oturumuna göre `AppShell` parametreleri (teacher/student/secretary/parent/admin).
- **Öğrenci alt nav (5 sekme):** Ana Sayfa, Dersler, **Takvim**, Duyurular, Profil — tasarımda sık görünen **Mesajlar** sekmesi **yok** (bilinçli ürün farkı; Faz 2’de 07’ye dokunulmadı).
- **Route modeli:** Workspace içi `AppState.active*Section` + `navigate*Section` yardımcıları; tam `go_router` envanteri yok — bölüm anahtarları enum tabanlı.

### 2.3 Roller ve yetki

- **`AppRole`:** teacher, student, parent, secretary, admin (+ oturum alanları `AppState`).
- **`AuthorizationService`:** UI ve işlem kapıları (`canAccessAdminWorkspace`, `canCreateAnnouncement`, vb.).
- Giriş: `HomeScreen` → rol diyalogları / `DesignLoginLayout` (hesap tab’ları öğrenci/veli/öğretmen; sekreter/admin ayrı akışlar).

### 2.4 Tema ve tasarım sistemi

- **`AppSpacing`:** mobile `<600`, desktop `≥1024`, `pagePadding`, grid kolonları.
- **`DesignSystem`:** card radius 16, workspace arka plan, `surfaceCardDecoration`, `classAccentPalette`.
- **`AppColors`:** navy sidebar, brand blue.
- **Design widget’lar:** `DesignPortalPageLayout`, `DesignFeedRow`, `DesignGroupedListCard`, `DesignMonthGridCalendar`, `DesignScrollFilterPills`, `DesignHubTile`, `DesignLoginLayout`, `TeacherDesignHomePrimary`, vb.

### 2.5 Localization

- Merkezi `AppLocalizations` + `strings.t('key')`; Faz 2’de `parentMeetingEvent`, `designAnnouncementCoverImage` eklendi.
- Bazı eski ekranlarda hâlâ doğrudan Türkçe veya `MaterialLocalizations` karışımı olabilir (Agent 2’de ekran bazlı tarama).

### 2.6 Test yapısı

- Geniş regression: secretary/admin/parent/teacher platform faz testleri.
- Design odaklı: `design_ui_faz1_test`, `design_tur2–4`, `design_faz2_final`, `design_faz2_responsive`.
- Ekran bazlı: `teacher_menu_screen_test`, `student_portal_ui_test`, `mobile_navigation_p10_test`, vb.
- **Eksik:** Windows-only layout golden’ları; 16 ekranın tamamı için görsel regression yok.

---

## 3. 16 Design Image Audit

Her görsel: `docs/design/MyEduApp_design_pages_separated/<dosya>`

### 01 — `01_giris_ekrani.png`

| Boyut | Değerlendirme |
| --- | --- |
| **Rol** | Tüm roller (segment: Öğrenci / Veli / Öğretmen) |
| **Layout** | Merkez kart, logo, 3’lü rol seçici, kullanıcı adı/şifre, beni hatırla, şifremi unuttum, giriş, kayıt ol |
| **Mevcut** | `HomeScreen` + `DesignLoginLayout`; mobil tam ekran; Windows `HomeBrandPanel` + sağ kart (`desktopSplit`) |
| **Farklar** | Tasarım 3 tab; uygulama sekreter/admin için ek giriş yolları (`HomeRoleGrid` / daha fazla rol). Kayıt ol / şifremi unuttum tasarımda var — ürün akışı kısıtlı olabilir. Sol kampüs görseli: `HomeBrandPanel` farklı kompozisyon. Typography/spacing yakın ama 1:1 değil. |
| **Responsive** | Mobil iyi; desktop split uygun. |
| **A11y** | Form label’ları l10n; focus sırası Agent 2’de doğrulanmalı. |
| **Reuse** | `DesignLoginLayout`, `DesignSystem.cardRadius` |

### 02 — `02_ana_sayfa_dashboard.png`

| Boyut | Değerlendirme |
| --- | --- |
| **Rol** | Admin (“Yönetici”) — tasarım sidebar menüsü genel okul portalı |
| **Layout** | Sidebar + üst arama + KPI 4’lü + “Son Duyurular” liste + sağ mini takvim + yaklaşan etkinlikler |
| **Mevcut** | `AdminHomeScreen` (`admin_tab_workspace` → `AdminNavSection.home`) |
| **Farklar** | KPI ve iki kolonlu yapı var; duyuru satırlarında kategori pill yoğunluğu, sağ kolon oranları, üst bar profil/arama detayı referanstan sapıyor. Sidebar menü öğeleri admin gerçek menüsü ile birebir değil (ürün menüsü daha geniş). |
| **Responsive** | `@1024` iki kolon; mobil KPI 2x2 — Faz 2 tur2 notları. |
| **A11y** | KPI kartlarında semantics eksik olabilir. |

### 03 — `03_ogrenciler.png`

| Boyut | Değerlendirme |
| --- | --- |
| **Rol** | Tasarımda “Yönetici”; uygulamada **Sekreter** öğrenci yönetimi |
| **Layout** | Başlık, arama, Yeni Öğrenci, Filtrele, tablo (avatar, ad, sınıf, veli, durum, işlemler), sayfalama |
| **Mevcut** | `SecretaryStudentsListScreen` (hub: `secretary_students_parents_hub_screen`) |
| **Farklar** | `DesignListPageHeader` kısmen; tablo kolonları/avatar/pagination görsel yoğunluğu PARTIAL. Admin’in ayrı öğrenci listesi yok — rol eşlemesi sekreter. |
| **Responsive** | Desktop tablo; mobil kart/liste geçişi kodda var mı tam denetlenmeli. |
| **Reuse** | `design_list_page_header`, `AppCard`, sekreter tablo widget’ları |

### 04 — `04_veliler.png`

| Boyut | Değerlendirme |
| --- | --- |
| **Rol** | Yönetici görünümü → **Sekreter** veli listesi |
| **Mevcut** | `SecretaryParentsListScreen` |
| **Farklar** | Arama + Yeni Veli + filtre + tablo (telefon, öğrenciler, durum pill) PARTIAL. Sayfalama/toplam metin hizası. |

### 05 — `05_ogrenci_detay.png`

| Boyut | Değerlendirme |
| --- | --- |
| **Rol** | Öğretmen/Sekreter öğrenci detay (mobil kompozisyon) |
| **Mevcut** | `SecretaryStudentDetailScreen` — `DesignPillTabs`, profil, `DesignInfoRow`, Notlar: `SecretaryStudentGradesPanel` |
| **Farklar** | Üst app bar + avatar hiyerarşisi; alt “Düzenle / Mesaj Gönder” — mesaj backend yok (SnackBar). Mobil 1:1 padding ve sekme stili PARTIAL. |
| **Faz 2** | Notlar PASS — bozulmayacak. |

### 06 — `06_akademik_takvim.png`

| Boyut | Değerlendirme |
| --- | --- |
| **Rol** | Öğrenci mobil — “Akademik Takvim”, haftalık şerit + timeline ders kartları, alt nav (Takvim aktif) |
| **Mevcut** | `StudentWeeklyScheduleScreen` → mobil `<1024` `DesignAcademicCalendarView`; sidebar’da `academicPlansWeekly` |
| **Farklar** | Tasarım timeline çizgisi ve ders kartı ikonografi; bottom nav’da “Mesajlar” tasarımda var, uygulamada yok. Öğretmen `academic_plans_screen` ayrı ekran (06 dosya adı öğrenci odaklı). |
| **Reuse** | `design_academic_calendar_view.dart`, `design_academic_calendar_data.dart` |

### 07 — `07_mesajlar.png`

| Boyut | Değerlendirme |
| --- | --- |
| **Rol** | Öğrenci (mobil) |
| **Layout** | Filtre chip’leri (Tümü/Öğretmenler/Yönetim), konu listesi, alt nav |
| **Mevcut** | **MISSING** — `lib/screens` altında mesajlaşma ekranı / servisi yok |
| **Not** | Faz 2 explicit: 07’ye özellik eklenmedi. Tasarım tam uygulama **BLOCKED** (veri + API/SQLite sohbet modeli yok). |

### 08 — `08_duyurular.png`

| Boyut | Değerlendirme |
| --- | --- |
| **Rol** | Öğrenci |
| **Mevcut** | `StudentAnnouncementsScreen` + `DesignPortalPageLayout`, `DesignScrollFilterPills`, `DesignFeedRow` |
| **Farklar** | Faz 2 PASS işlev; görsel pill renkleri, arama ikonu, kart gölgesi ince ayar PARTIAL. Veli filtresi eklendi (Tur 4). |

### 09 — `09_takvim.png`

| Boyut | Değerlendirme |
| --- | --- |
| **Rol** | Öğrenci |
| **Mevcut** | `StudentDesignAcademicCalendarPanel` — ay grid, “bugünün etkinlikleri”, sınav + mentorluk |
| **Farklar** | Kart ikon renkleri, “5dk” hatırlatma tasarımda var — uygulamada yok (ürün). Genel yapı PARTIAL→yakın PASS. |

### 10 — `10_ayarlar.png`

| Boyut | Değerlendirme |
| --- | --- |
| **Rol** | Yönetici mobil ayarlar |
| **Mevcut** | `SettingsScreen` + `DesignSettingsProfileHeader`, `SettingsSection` / `SettingsRow` |
| **Farklar** | Tasarım sade liste (hesap, bildirim, görünüm, dil, yardım, çıkış); uygulama öğretmen yedekleme/SMTP/güvenlik ile daha zengin — doğru rol ayrımı korunmalı. Görsel sade kart PARTIAL. |

### 11 — `11_dokumanlar.png`

| Boyut | Değerlendirme |
| --- | --- |
| **Rol** | Öğrenci |
| **Mevcut** | `StudentDocumentsScreen` — filtreler, grouped list, `openStudentPortalDocument` |
| **Farklar** | Tasarım **PDF • MB** metadata — **BLOCKED** (modelde boyut yok). Alt nav tasarımda “Dokümanlar” sekmesi; uygulama dokümanları sidebar’dan. |

### 12 — `12_duyuru_detay.png`

| Boyut | Değerlendirme |
| --- | --- |
| **Rol** | Öğrenci |
| **Mevcut** | `StudentAnnouncementDetailScreen` — hero (dosya veya ikon), tarih, gövde, “Okundu işaretle” |
| **Farklar** | Bookmark ikonu tasarımda; kapak görseli gerçek dosyadan — tasarım illüstrasyon. Faz 2 PASS; bookmark PARTIAL. |

### 13 — `13_ogretmen_paneli.png`

| Boyut | Değerlendirme |
| --- | --- |
| **Rol** | Öğretmen |
| **Mevcut** | `TeacherMenuScreen` — `TeacherDesignHomePrimary` (Sınıflarım 2x2 + Güncel Dersler) |
| **Farklar** | Altında hâlâ ek KPI/aktivite/defter içeriği (`_DashboardBody`) — tasarım sade iki panel. Üst arama “Öğrenci Gözetle” uyumlu. Sidebar PARTIAL. |

### 14 — `14_sekreter_paneli.png`

| Boyut | Değerlendirme |
| --- | --- |
| **Rol** | Sekreter |
| **Mevcut** | `SecretaryDashboardScreen` — `DesignHubTile` grupları (öğrenci/veli/rapor) |
| **Farklar** | Üstte 3 KPI kartı tasarımda yok; hub tile düzeni yakın ama spacing/ikon seti PARTIAL. |

### 15 — `15_mobil_menu_drawer.png`

| Boyut | Değerlendirme |
| --- | --- |
| **Rol** | Öğretmen (drawer) |
| **Mevcut** | `AppShell` → `Drawer` + `_AppSidebar(inDrawer: true)` |
| **Farklar** | Faz 1 PASS’a yakın; profil üstte, menü öğeleri rol listelerinden (`teacherSidebarMenuOrder` vb.). Çıkış kırmızı vurgu doğrulanmalı. |

### 16 — `16_hata_erisim_yok.png`

| Boyut | Değerlendirme |
| --- | --- |
| **Rol** | Tüm roller |
| **Mevcut** | `DesignAccessDeniedScreen` (ayarlarda embedded) |
| **Farklar** | Özel kalkan illüstrasyon yerine `Icons.shield_outlined` — en yakın MATCH adayı (işlev + metin). |

---

## 4. Design → Screen/Route Mapping

| # | Görsel | Hedef ekran | Mevcut screen/widget | Navigation / section | Durum | Gerekli değişiklik (özet) |
| --- | --- | --- | --- | --- | --- | --- |
| 01 | `01_giris_ekrani.png` | Giriş | `HomeScreen`, `DesignLoginLayout` | `/` → `HomeScreen` | **PARTIAL** | Spacing/typography; kayıt/şifremi unuttum ürün kararı; brand panel |
| 02 | `02_ana_sayfa_dashboard.png` | Admin ana sayfa | `AdminHomeScreen` | `AdminNavSection.home` | **PARTIAL** | KPI/duyuru/takvim kolon oranı; üst bar; badge |
| 03 | `03_ogrenciler.png` | Öğrenci listesi | `SecretaryStudentsListScreen` | `SecretaryNavSection.students` | **PARTIAL** | Tablo/avatar/pagination/filtre UI |
| 04 | `04_veliler.png` | Veli listesi | `SecretaryParentsListScreen` | `SecretaryNavSection.parents` | **PARTIAL** | Tablo + filtre + durum pill |
| 05 | `05_ogrenci_detay.png` | Öğrenci detay | `SecretaryStudentDetailScreen` | detay route / focus id | **PARTIAL** | Mobil header/alt CTA; mesaj BLOCKED |
| 06 | `06_akademik_takvim.png` | Öğrenci haftalık program | `StudentWeeklyScheduleScreen` | `StudentNavSection.academicPlansWeekly` | **PARTIAL** | Timeline görseli; nav Mesajlar ürün farkı |
| 07 | `07_mesajlar.png` | Mesajlar | — | — | **MISSING** | Ürün+veri modeli; UI BLOCKED |
| 08 | `08_duyurular.png` | Öğrenci duyurular | `StudentAnnouncementsScreen` | `StudentNavSection.announcements` / bottom nav | **PARTIAL** | Piksel cilası; işlev koru |
| 09 | `09_takvim.png` | Öğrenci takvim | `StudentDesignAcademicCalendarPanel` | `MobileBottomNavKey.studentCalendar` | **PARTIAL** | Etkinlik kart stili; hatırlatma yok |
| 10 | `10_ayarlar.png` | Ayarlar | `SettingsScreen` | `/settings`, `TeacherNavSection.settings` | **PARTIAL** | Rol bazlı sade mobil kart |
| 11 | `11_dokumanlar.png` | Öğrenci dokümanlar | `StudentDocumentsScreen` | `StudentNavSection.documents` | **PARTIAL** | Boyut BLOCKED; nav yolu farkı |
| 12 | `12_duyuru_detay.png` | Duyuru detay | `StudentAnnouncementDetailScreen` | `openStudentAnnouncementDetail` | **PARTIAL** | Bookmark opsiyonel; hero koru |
| 13 | `13_ogretmen_paneli.png` | Öğretmen paneli | `TeacherMenuScreen` | `TeacherNavSection.home` | **PARTIAL** | İkincil dashboard içeriği sadeleştir/ayır |
| 14 | `14_sekreter_paneli.png` | Sekreter paneli | `SecretaryDashboardScreen` | `SecretaryNavSection.home` | **PARTIAL** | KPI opsiyonel gizle; hub grid |
| 15 | `15_mobil_menu_drawer.png` | Mobil drawer | `AppShell` drawer + `_AppSidebar` | drawer | **PARTIAL** | Görsel token hizalama |
| 16 | `16_hata_erisim_yok.png` | Erişim reddedildi | `DesignAccessDeniedScreen` | embedded / standalone | **MATCH**\* | \*İllüstrasyon basitleştirilmiş |

**Özet sayım:** 16 görsel incelendi · **MATCH: 1** (16, işlevsel) · **PARTIAL: 14** · **MISSING: 1** (07)

---

## 5. Current vs Target Gaps

| Kategori | Mevcut | Hedef (16 görsel) | Boşluk |
| --- | --- | --- | --- |
| **Navigation** | Rol menüleri + 5’li öğrenci bottom nav (Mesajlar yok) | Tasarım sık 5’li nav + Mesajlar | Ürün kararı gerekli; AppShell yapısı korunur |
| **Sidebar** | Navy, geniş menü, hover collapse | Aynı dil, sabit genişlik görsel | Aktif pill radius, logo alanı |
| **Hub/dashboard** | Admin/sekreter/öğretmen farklı yoğunluk | Sade KPI + kart/grid | 02/13/14 sadeleştirme |
| **Listeler** | Sekreter tabloları işlevsel | Zengin tablo + avatar + pagination UI | 03/04 |
| **Öğrenci portal** | Design system list/takvim PASS | Piksel + metadata (boyut) | 11 BLOCKED kısmi |
| **Mesajlaşma** | Yok | Tam inbox | MISSING/BLOCKED |
| **Tokens** | `DesignSystem` + `AppSpacing` | Tutarlı radius/shadow/type | Merkezi token audit |
| **A11y** | Kısmi Semantics | WCAG odaklı | Matris + touch 48dp |

---

## 6. Responsive / Mobile / Windows Audit

### 6.1 Breakpoint politikası (mevcut)

| Genişlik | Sınıf | Shell davranışı |
| --- | --- | --- |
| 360–599 | Mobile | Drawer, bottom nav (rol izin verirse), tek kolon |
| 600–1023 | Tablet | Sidebar, çoğu içerik 2 kolon |
| ≥1024 | Desktop | Sidebar + geniş içerik; admin 2 kolon |

Master prompt ek: 768, 1280, 1440, 1920 — `design_faz2_responsive_test` portal widget’larında kısmen var; **16 ekran tam matrisi yok**.

### 6.2 Ekran bazlı notlar

| Ekran | Dar mobil | Geniş telefon | Küçük desktop | Geniş Windows |
| --- | --- | --- | --- | --- |
| 01 | Tam ekran kart | OK | Split panel | Split — OK |
| 02 | KPI 2x2, stack | Stack duyuru/takvim | 2 kolon @1024 | Max-width içerik kontrolü |
| 03–04 | Tablo → kart riski | Yatay scroll riski | Tam tablo | Geniş tablo boşluk |
| 05 | Scroll + pill tabs | OK | Sekme yatay | Centered max width |
| 06–09 | Bottom nav + scroll | Takvim grid | Sidebar + içerik | Öğrenci: sidebar ağır — bottom nav öncelik |
| 10 | Tek kart | OK | Settings iki kolon olabilir | SMTP bölümleri geniş |
| 11 | Liste | Filtre wrap | Sidebar erişim | Doküman list max-width 960 |
| 13–14 | Hub tek kolon | 2 kolon tile | Sidebar + grid | Tile 3–4 kolon |
| 15 | Drawer tam ekran | OK | N/A (sidebar) | N/A |
| 16 | Merkez | OK | OK | OK |

**Overflow riskleri:** Uzun sekreter tablo satırları, öğretmen dashboard çoklu bölüm, login `Wrap` (düzeltilmiş). Agent 2’de her ekran için `LayoutBuilder` + `SingleChildScrollView` denetimi.

---

## 7. Accessibility Audit

| Konu | Mevcut | Tasarım hedefi | Aksiyon |
| --- | --- | --- | --- |
| Contrast | Navy/beyaz iyi; gri subtitle orta | Okunaklı metin | `onSurfaceVariant` denetimi |
| Touch target | Design chip’ler ~40dp | ≥48dp | `DesignScrollFilterPills` min height |
| Semantics | Duyuru, doküman, takvim kısmi | Tüm nav + liste | `Semantics` wrapper planı |
| Keyboard | Desktop Flutter default | Sidebar focus order | `FocusTraversalGroup` hub formlar |
| Form labels | l10n `InputDecoration` | Explicit labels | Sekreter formları tarama |
| Error feedback | SnackBar | SnackBar + semantics live region | Koru |
| Screen reader | Test yok | TalkBack/VoiceOver turu | Manuel QA fazı |
| Tooltip | Bazı `IconButton` | Tüm ikon aksiyonlar | `PageHeader` actions |

Faz 2 final: **Accessibility = PARTIAL** — bu plan tamamlanmadan PASS iddia edilmemeli.

---

## 8. Component & UI Architecture Analysis

### 8.1 Mevcut yeniden kullanım (öncelikli)

| Bileşen | Konum | Kullanım alanı |
| --- | --- | --- |
| `AppShell` / drawer / bottom nav | `app_shell.dart`, `app_mobile_bottom_nav.dart` | Tüm workspace |
| `DesignPortalPageLayout` | design | 08, 11 benzeri liste sayfaları |
| `DesignFeedRow` + `DesignGroupedListCard` | design | 08, 02 duyuru, admin liste |
| `DesignListPageHeader` | design | 03, 04 başlık satırı |
| `DesignStatCard` | design | 02 KPI |
| `DesignHubTile` | design | 14 sekreter hub |
| `TeacherDesignHomePrimary` | design | 13 |
| `DesignPillTabs` / `DesignInfoRow` | design | 05 |
| `DesignMonthGridCalendar` / `DesignAcademicCalendarView` | design | 06, 09, 06 öğretmen mobil |
| `DesignLoginLayout` | home | 01 |
| `DesignAccessDeniedScreen` | screens | 16 |
| `DesignSettingsProfileHeader` | widgets | 10 |
| `PageHeader` | widgets | Shell üst başlık |
| `AppEmptyState` | widgets | Boş durumlar |

### 8.2 Önerilen yeni bileşenler (yalnızca plan)

| Bileşen | Gerekçe | Duplicate önleme |
| --- | --- | --- |
| `DesignDataTableScaffold` | 03/04 ortak arama+filtre+tablo+pagination | Sekreter listelerini birleştir |
| `DesignTimelineLessonRow` | 06 timeline görünümü | `DesignAcademicCalendarView` içinde refactor |
| `DesignKpiRow` | 02/14 tutarlı KPI | `DesignStatCard` wrap |
| `DesignSettingsListCard` | 10 mobil kart | `SettingsSection` stil eşlemesi |

**Strateji:** Önce mevcut `design_*` genişlet; yeni dosya yalnızca 2+ ekran kullanacaksa.

### 8.3 Kaçınılacaklar

- `AppShell` / `AppState` / auth yeniden yazımı
- Rol menülerinin tasarım uğruna birleştirilmesi (admin ≠ sekreter menü)
- Her ekran için kopya “card” widget’ı

---

## 9. Risks / Dependencies

| Risk | Etki | Azaltma |
| --- | --- | --- |
| 07 Mesajlar MISSING | Tasarım-nav uyumsuzluğu | Ürün kararı: sekme gizle veya BLOCKED rapor; sahte thread yok |
| Faz 2 regression | Bildirim→duyuru, v35, notlar | Her faz sonu `flutter test` 231+ |
| Sidebar vs bottom nav çift UI | Öğrenci kafa karışıklığı | Tasarım referansına göre mobilde bottom nav öncelik |
| Doküman boyutu BLOCKED | 11 görsel metadata | Şema değişikliği ayrı onay (v36?) |
| Öğretmen dashboard şişkinliği | 13 sade görünüm | İkincil bölümleri collapse veya alt sayfa |
| Piksel 1:1 beklentisi | PARTIAL kalır | Önce layout/spacing, sonra görsel detay |
| 434 analyze info | Gürültü | Yeni error/warning sıfır hedef |

### DO NOT CHANGE (RISK)

- Authentication akışı (`HomeScreen`, diyaloglar, `AppState` session)
- `AuthorizationService` kuralları
- SQLite şema (v35) — kapak görseli, mentorluk türleri, not tabloları
- P9 bildirim fan-out ve `notification_navigation.dart`
- Öğrenci 5 sekmeli bottom nav + takvim sekmesi (Faz 4)
- Backup/restore, SMTP, öğretmen platform veri modeli
- **Sahte veri seed** tasarım için

---

## 10. Priority Matrix

| P | Ekran | Problem | Önerilen çözüm | Bağımlılık | Karmaşıklık | Regression | Test |
| --- | --- | --- | --- | --- | --- | --- | --- |
| P0 | Tümü | Token tutarsızlığı | `DesignSystem` audit + `Theme` bağlama | — | M | Düşük | widget smoke |
| P0 | 08–12 | Faz 2 kırılması | Yalnızca stil; logic dokunma | Faz 2 PASS | S | **Yüksek** | design_tur3/4/final |
| P1 | 15, shell | Drawer/sidebar görsel | `_AppSidebar` stil, aktif item | AppShell | M | Orta | mobile_navigation_p10 |
| P1 | 13 | Dashboard kalabalık | Primary row öne; geri kalan collapse | Teacher data | M | Orta | teacher_menu_screen_test |
| P1 | 14 | KPI fazlalığı | Hub-first layout; KPI opsiyonel | Secretary nav | S | Düşük | secretary tests |
| P1 | 02 | Admin dashboard | 2 kolon oran, duyuru badge | AdminPortalService | M | Orta | admin_portal_p8 |
| P2 | 03, 04 | Liste UI | `DesignDataTableScaffold` | Secretary services | L | Orta | secretary faz tests |
| P2 | 05 | Mobil detay | Header/CTA layout | Notlar panel | M | Orta | yeni widget test |
| P2 | 06 | Timeline | `DesignAcademicCalendarView` polish | weekly schedule DB | M | Orta | design_tur2 |
| P2 | 01 | Giriş | Split + tab görünüm | — | S | Orta | design_ui_faz1 |
| P3 | 10 | Ayarlar sade kart | Rol bazlı bölüm gizleme | auth flags | M | Düşük | settings manual |
| P3 | 11 | Doküman metadata | BLOCKED boyut veya kaldır | DB | — | Düşük | student portal |
| P3 | 09 | Takvim kartları | İkon/tipografi | mentorship load | S | Orta | responsive test |
| — | 07 | MISSING | Ürün+model | Backend/SQLite chat | XL | — | BLOCKED |
| P2 | 16 | İllüstrasyon | Opsiyonel asset | — | S | Düşük | design_ui_faz1 |

---

## 11. Recommended Implementation Phases

### Faz A — Foundation (Agent 2 başlangıç)

- Design token tablosu (radius, shadow, type scale) ↔ `ThemeData` eşlemesi
- `AppShell` sidebar/drawer/header görsel hizalama (15, tüm roller)
- Dokümantasyon: ekran checklist

### Faz B — Hub ekranları

- **02** `AdminHomeScreen` layout
- **13** `TeacherMenuScreen` sadeleştirme + `TeacherDesignHomePrimary`
- **14** `SecretaryDashboardScreen` hub-first

### Faz C — Sekreter listeler

- **03** `SecretaryStudentsListScreen`
- **04** `SecretaryParentsListScreen`
- Ortak tablo scaffold

### Faz D — Detay ve giriş

- **05** mobil layout (notlar sekmesine dokunmadan)
- **01** `DesignLoginLayout` / `HomeBrandPanel`

### Faz E — Öğrenci portal cilası (Faz 2 koruma modu)

- **06** timeline görünümü
- **08–09–11–12** yalnızca UI; bildirim, filtre, viewer, kapak yolu regression testleri zorunlu
- **11** boyut: BLOCKED veya v36 planı (onaylı)

### Faz F — Ayarlar ve hata

- **10** rol bazlı sade mobil
- **16** opsiyonel görsel asset

### Faz G — 07 Mesajlar (koşullu)

- **BLOCKED** until: mesaj modeli, servis, yetki, bildirim entegrasyonu tanımı
- UI implementasyonu ürün onayı sonrası

### Faz H — QA kapanış

- 8 breakpoint × 16 ekran manuel/matris
- A11y turu
- `docs/actions/myeduapp_design_redesign_final_status.md`

---

## 12. Test & QA Plan

### Her implementasyon fazı sonunda

| Kontrol | Komut / araç |
| --- | --- |
| Analyzer | `flutter analyze` — yeni error/warning 0 |
| Regression | `flutter test` — ≥231, 0 failed |
| Design widget | `design_tur*`, `design_faz2_*` |
| Navigation | `mobile_navigation_p10_test`, `app_role_session_test` |
| Rol | `admin_account_management_faz9`, secretary/parent faz tests |
| Öğrenci portal | `student_portal_service_test`, `design_tur4` (bildirim id) |

### Yeni test önerileri (Agent 2)

- `golden` veya `testWidgets` genişlik matrisi: 02, 03, 13, 14 @ 360/1024/1280
- `SecretaryStudentDetailScreen` notlar sekmesi smoke (Faz 2)
- `DesignAccessDeniedScreen` semantics
- Windows: `binding.setSurfaceSize` ile split login

### Manuel QA

- Öğrenci: login → duyuru → bildirim → detay → okundu → takvim → doküman aç
- Öğretmen: panel → akademik plan mobil genişlik
- Sekreter: liste → detay → notlar
- Admin: dashboard veri boş/ dolu empty state

---

## 13. Protected Existing Features

Aşağıdakiler redesign sırasında **değiştirilmemeli** (yalnızca UI sarmalayıcı):

1. Oturum: `AppState` (teacher/student/secretary/parent/admin, `sessionStudentId`, pending announcement id)
2. `AuthorizationService` ve sekreter/admin capability bayrakları
3. SQLite v35: `kapak_gorsel_yolu`, `ogrenci_notlar`, `mentorluk_etkinlikler`, duyuru hedef_tur
4. `StudentPortalService` kapsam sorguları (duyuru, ödev, sınav, mentorluk)
5. `NotificationFanoutService` + `notification_navigation.dart`
6. `prepareStudentContentViewer` / `AppViewerScreen` doküman akışı
7. Öğrenci bottom nav 5 sekme (Takvim dahil)
8. Öğretmen `<1024` mobil takvim (`academic_plans_screen`)
9. `SecretaryStudentGradesPanel` veri bağlantısı
10. Sekreter duyuru kapak `FilePicker` (gerçek yol)
11. Backup/restore, import/export, öğretmen platform v17

---

## 14. Agent 2 Implementation Handoff

### Okuma sırası

1. Bu plan + `faz_design_faz2_final_status.md`
2. İlgili görsel(ler) `MyEduApp_design_pages_separated/`
3. Hedef `lib/screens/...` ve mevcut `lib/widgets/design/...`

### Çalışma kuralları

- Küçük PR mantığında fazlar (Bölüm 11)
- Önce UI diff; servis değişikliği yalnızca BLOCKED çözümü için ve onaylı
- Her ekran bitiminde: test + kısa not `myeduapp_design_redesign_final_status.md` taslağı
- 07 Mesajlar: **implement etme** ürün onayı olmadan

### Definition of Done (ekran)

- Layout/spacing referansa yakın
- l10n yeni metinler
- Responsive 360 + 1024 doğrulandı
- Semantics kritik kontroller
- Regression yeşil

---

## 15. Final Agent 1 Status

| Madde | Sonuç |
| --- | --- |
| Görseller incelendi | **16 / 16** |
| MATCH / PARTIAL / MISSING | **1 / 14 / 1** |
| Plan dosyası | `docs/actions/myeduapp_design_redesign_plan.md` |
| Kod değişikliği | **Yapılmadı** (`lib/`, `test/`, `pubspec.yaml` dokunulmadı) |
| Kritik bulgular | (1) **07 Mesajlar MISSING/BLOCKED** (2) Öğrenci nav’da Mesajlar yok — tasarım farkı (3) 11 doküman boyutu BLOCKED (4) 03/04 rolü sekreter, görsel admin (5) Faz 2 öğrenci akışları regression riski yüksek — koruma zorunlu |
| Önerilen fazlar | A Foundation → B Hub → C Lists → D Detail/Login → E Student polish → F Settings/16 → G Messages (koşullu) → H QA |

**Agent 1 tamamlandı.** Agent 2 bu belgeyi uygulama rehberi olarak kullanabilir.
