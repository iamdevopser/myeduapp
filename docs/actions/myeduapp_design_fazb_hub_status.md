# MyEduApp — Faz B (Hub Ekranları) Durum Raporu

Kapsam: `docs/actions/myeduapp_design_redesign_plan.md` §3 (02, 13, 14), §4, §10, §11 "Faz B", §13.
Kural: `lib/data`, `lib/services`, auth, `AuthorizationService`, AppState mantığı, navigasyon/rota/rol mantığı, `AppShell`, öğrenci/veli ekranları, sekreter/öğretmen liste-detay ekranları, ayarlar **değiştirilmedi**. Mesajlar (07) için hiçbir öğe/ekran/placeholder eklenmedi. Yeni ekran/rota yok.

## 0. Mapping (doğrulandı)

| Tasarım | Ekran | Route / section | Widget'lar | Servis / veri |
| --- | --- | --- | --- | --- |
| 02 Admin ana sayfa | `lib/screens/admin_portal/admin_home_screen.dart` → `AdminHomeScreen` (`admin_tab_workspace.dart`: `AdminNavSection.home => AdminHomeScreen()`) | `AdminNavSection.home` | `DesignStatCard`, `DesignSurfaceCard`, `DesignFeedRow` (+`DesignPill`), `DesignGroupedListCard`, `DesignMiniMonthCalendar`, `DesignSectionHeader`, `DesignPageContainer` | `AdminPortalService.loadDashboardStats`, `db.listAnnouncementsForSecretary`, `DesignAcademicCalendarData.load` (değişmedi) |
| 13 Öğretmen paneli | `lib/screens/teacher_menu_screen.dart` → `TeacherMenuScreen` / `_DashboardBody` (`teacher_navigation.dart`: `TeacherNavSection.home => TeacherMenuScreen()`) | `TeacherNavSection.home` | `TeacherDesignHomePrimary` (`DesignClassGridCard`, Güncel Dersler paneli), `DesignCollapsibleSection`, `DesignPageContainer`, mevcut `_ReferenceDashboardStats`, `_AnnouncementsPanel`, `_TeacherHomeDashboardGrid` kartları | `_loadSnapshot` (`db.getStudentClasses`, `getRecentTeacherActivities`, vb.) + AppState bekleyen sınıf defteri dinleyicisi (değişmedi) |
| 14 Sekreter paneli | `lib/screens/secretary_portal/secretary_dashboard_screen.dart` → `SecretaryDashboardScreen` (`secretary_tab_workspace.dart`: `SecretaryNavSection.home`) | `SecretaryNavSection.home` | `DesignHubTile`, `DesignSectionHeader`, `DesignPageContainer`, `DesignSurfaceCard` | `SecretaryStudentService.loadDashboardStats` (değişmedi), `navigateSecretarySection` |

Üç eşleme de kodda doğrulandı; plandaki varsayımla birebir aynı.

## 1. Implemented

### 14 Sekreter (hub-first)
- Sayfa başlığı → üç başlıklı bölüm (`DesignSectionHeader`): **Öğrenci İşlemleri** (Öğrenci Ekle, Öğrenci Düzenle [= öğrenci listesi], Sınıf/Şube, Yoklama), **Veli İşlemleri** (Veli Ekle, Veli Düzenle), **Raporlar** (Devamsızlık Raporu, Duyuru Listesi). Hiçbir eylem eklenmedi/silinmedi; tüm tile'lar eskisiyle aynı `SecretaryNavSection`'a gider.
- 3 KPI kartı (öğrenci, sınıf/şube, bugünün tarihi) hub'ların **altında**, "Genel Bakış" başlığıyla tek kompakt kart şeridine (36 px ikon) taşındı. `loadDashboardStats` verisi aynen yükleniyor (artık `initState`'te bir kez; hub'lar veri beklemeden hemen görünür).
- Grid: 1 sütun (<600), 2 sütun (600–1023), 4 sütun (>=1024); tüm tile'lar eşit genişlik ve `DesignSystem.hubTileMinHeight`.
- `DesignPageContainer` (responsive padding + `contentMaxWidth`), sabit renkler `AppColors` token'larına çevrildi (`SecretaryGlassCard`/`SecretaryDesign` bağımlılığı bu ekrandan kalktı).
- `DesignHubTile`: `button + label` semantics (`excludeSemantics` ile çift okuma yok, `onTap`), renk `AppColors.navy`, spacing `AppSpacing`.

### 02 Admin
- Karşılama (`adminWelcomeNamed` + `adminTodaySummary`, mevcut l10n anahtarları; başlık `header` semantics).
- 4'lü KPI satırı (`DesignStatCard`): içerik genişliği >= 600 → 4 sütun, altı → 2x2. Tint'ler `AppColors` token'ları.
- Sol: "Son Duyurular" (`DesignFeedRow` listesi) — her satırda **hedef kitle hapı** (`DesignPill`; `hedef_tur` → mevcut `announcementTarget*` l10n anahtarları: Tüm Okul / Sınıf (seviye) / Şube (sınıf)). Sağ: mini ay takvimi + Yaklaşan Etkinlikler (mevcut bugünün dersleri verisi).
- >= 1024: iki kolon, `flex 2:1` (eskiden 3:2); altı: yığılı. Mevcut "Kullanıcılar / Kullanıcı Ekle" hızlı bağlantıları korundu.
- Tüm veri yüklemeleri (`_AdminHomeData.load`) aynen duruyor; boş veri → mevcut boş durum metinleri.

### 13 Öğretmen
- `TeacherDesignHomePrimary` en üstte ve net birincil satır: **Sınıflarım 2x2** (artık mobilde de 2 sütun; yalnızca <300 px alanda 1 sütun) + Güncel Dersler. Başlıklar `DesignSectionHeader`.
- Eski `_DashboardBody` içeriği korunarak ikincil hale getirildi, iki `DesignCollapsibleSection` içinde (varsayılan **açık** → mevcut testler aynen geçerli): **Özet ve Duyurular** (KPI'lar + son duyurular) ve **Çalışma Alanı** (Hızlı İşlemler, Son İşlemler, Sınıf Defterim). Başlıklar soluk (`tokens.textSecondary`), 48 px dokunma hedefi, tooltip.
- Bekleyen sınıf defteri isteği (`takePendingClassNotebookClassId` + AppState listener) **değişmedi**; yalnızca `_notebookClassId` değişince "Çalışma Alanı" bölümü otomatik açılır (kullanıcı kapatmışsa defter gizli kalmasın).
- `_loadSnapshot` ve tüm veri yüklemeleri aynen duruyor.

### Paylaşılan bileşenler (yeni/küçük değişiklik)
- Yeni `DesignPill` (kategori hapı), yeni `DesignCollapsibleSection` (aç/kapa; `expanded` semantics, tooltip, `expandToken`).
- `DesignFeedRow`: isteğe bağlı `badge` parametresi (varsayılan null → diğer ekranlar etkilenmez).
- **Paylaşılan bileşen hata düzeltmesi** — `DesignMiniMonthCalendar`: gün başlıkları Pazartesi-ilk sırayla ("P S Ç P C C P") yazılı iken ilk gün ofseti Pazar-ilk hesaplanıyordu (günler yanlış sütunda). Ofset `first.weekday - 1` yapıldı, başlıklar yerel `DateFormat.E` ile üretilip `FittedBox` hücrelerine alındı (taşma yok); ay başlığı `header` semantics. Yalnızca admin ana sayfasında kullanılıyor.
- Yeni l10n anahtarları (tr + en): `secretaryHubOverview`, `designHubSecondarySummary`, `designHubSecondaryWorkspace`, `designSectionExpand`, `designSectionCollapse`.

## 2. Design alignment vs image

- **14**: Başlık, 3 başlıklı bölüm, ikon üstte/başlık altta kartlar, 4/2/4 düzeni görsele uyuyor. Fark: tasarımda KPI yok; biz veriyi silmeden altta kompakt tuttuk. Görseldeki "Akademik Rapor" için mevcut özellik yok → yerine mevcut "Duyuru Listesi" tile'ı korundu (özellik silinmedi); "Akademik Rapor" **ertelendi**. İkon seti görselden farklı olabilir (Material ikonları).
- **02**: Karşılama, 4 KPI, Son Duyurular (kategori hapı ile), sağda takvim + Yaklaşan Etkinlikler, ~2:1 oran uyuyor. Farklar: üst arama/profil çubuğu ve sidebar menüsü (AppShell, Faz C+ kapsamı); "Yaklaşan Etkinlikler" gerçek veri olarak yalnızca bugünün derslerini gösterir (takvimde tarihli etkinlik modeli yok); KPI "Duyuru" değeri son 8 duyuru sayısıdır (mevcut davranış); görseldeki "Toplantı" KPI'ı yerine mevcut "Yaklaşan Etkinlikler" sayısı.
- **13**: Sınıflarım 2x2 + Güncel Dersler sağda görselle uyumlu ve en üstte. Fark: tasarım sadece iki panel gösterir; mevcut ek içerik silinmeden "Özet ve Duyurular" / "Çalışma Alanı" bölümlerinde ikincil olarak durur (varsayılan açık; kullanıcı kapatabilir). Sidebar menüsü PARTIAL (Faz A/ShellFaz).

## 3. Responsive

Test DPR'si varsayılan 3.0 olduğundan (`setSurfaceSize` mantıksal genişliği 1/3 yapar) yeni testler `view.devicePixelRatio = 1.0` ile gerçek mantıksal genişliklerde çalışır.
- Üç ekran için `AppSpacing.qaWidths` (360, 390, 430, 768, 1024, 1280, 1440, 1920) yeniden boyutlandırma taramasında **RenderFlex overflow / istisna yok** (gerçek veriyle: 2 sınıf, 1 duyuru, admin hesabı).
- Sekreter: 360'ta 1 sütun, 1440'ta 4 sütun (aynı satırda 4 tile), tile yükseklikleri eşit.
- Admin: 360'ta KPI 2x2, 1440'ta tek satır 4'lü; 1024'te iki kolon (takvim duyuruların sağında, duyuru kartı takvimden geniş), 360'ta yığılı.
- Öğretmen: 390'da iki sınıf kartı aynı satırda (2x2); 360/1440'ta birincil başlık ikincil bölümlerin üstünde.
- Not: ekran genişliği `MediaQuery` pencere genişliğidir; AppShell sidebar'lı geniş ekranda gerçek içerik genişliği daha dardır (KPI satırı bu yüzden içerik `LayoutBuilder` genişliğine göre kararlaştırıldı).

## 4. Accessibility

- Hub tile: `Semantics(button, label, onTap)`; admin KPI (`DesignStatCard` mevcut `label value`); sınıf kartları zaten `button + label`; feed satırı etiketi `başlık, hedef kitle`.
- Kapat/aç başlığı: `button + expanded + label`, `Tooltip` (genişlet/daralt), min 48 px yükseklik.
- Mini takvim ay başlığı `header`; sayfa başlıkları `header`.
- Dokunma hedefleri: hub tile ≥ 108 px, özet öğeleri ≥ 48 px, bölüm başlığı ≥ 48 px. Admin `ActionChip`'leri temadaki 48 px tap target ile.
- Formal kontrast ölçümü / ekran okuyucu geçişi yapılmadı (Deferred).

## 5. Tests

- `flutter analyze` (tüm proje): **0 error, 431 issue** (baseline 432). Dokunulan dosyalarda yeni uyarı/info yok; kalanlar önceden var olanlar (`teacher_menu_screen.dart` eski uyarıları satır kaymasıyla, `design_mini_month_calendar.dart` `intl` bağımlılık info'su).
- `flutter test`: **254 passed / 0 failed** (baseline 239 + 15 yeni).
- Yeni `test/hub_fazb_test.dart` (15 test):
  - Sekreter: 360 ve 1440 render + 3 bölüm + 8 hub tile + "Genel Bakış" hub'ların altında; tüm QA genişliklerinde taşma yok; 1 sütun (360) / 4 sütun (1440) + eşit tile yüksekliği.
  - Admin: 360/1024/1440 render, 4 KPI, takvim, gerçek duyuru + "Tüm Okul" hedef hapı; tüm QA genişlikleri; KPI 2x2 vs tek satır; 1024 iki kolon vs 360 yığılı.
  - Öğretmen: 360/1440 birincil satır üstte + ikincil bölümler korunmuş (Hızlı İşlemler, Son İşlemler, Sınıf Defterim); tüm QA genişlikleri; 390'da 2x2 sınıf kartları; bölüm daralt/genişlet.
- Mevcut `teacher_menu_screen_test.dart` değiştirilmedi ve geçti (bölümler varsayılan açık).

## 6. Regression check

- Faz 2 (08–12 öğrenci duyuru/doküman/takvim akışları, `design_tur2/3/4`, `design_faz2_final`): ilgili testler yeşil; kullanılan paylaşılan bileşenlerden yalnızca `DesignFeedRow` (opsiyonel `badge`, varsayılan davranış aynı) ve `DesignHubTile` (görsel aynı, semantics iyileşti) dokunuldu.
- Faz A (token/tema/AppShell): `design_tokens_faza_test`, `app_shell_faza_test` yeşil; `AppShell` dosyası değişmedi.
- Sekreter/admin/öğretmen servis ve veri testleri (`secretary_*`, `admin_portal_p8`, `teacher_*`) yeşil.

## 7. Deferred

- 14: görseldeki "Akademik Rapor" tile'ı (mevcut özellik yok; yeni eylem uydurulmadı).
- Sidebar menü farkları (tasarım menüsü ile ürün menüsü), üst arama/profil çubuğu — AppShell/Faz C–H.
- 02: tarihli "Yaklaşan Etkinlikler" için kalıcı etkinlik veri modeli (bugünkü ders listesi kullanılıyor).
- Manuel GUI QA (Windows + mobil) — bu ortamda GUI çalıştırılamadı.
- Formal kontrast / ekran okuyucu denetimi; dark tema altında beyaz sabit `DesignSurfaceCard` zemini.
- `DesignStatCard`/`DesignFeedRow` içindeki kalan sabit gri renkler (beyaz kart üzerinde; token'a taşınması dark tema kararı gerektirir).
- Öğretmen dashboard'ında önceden var olan kullanılmayan kod uyarıları (`_ShortAnalyticsRow` vb.) — kapsam dışı.
- 07 Mesajlar (Faz G) — hiçbir şey eklenmedi.

## 8. Changed files

Değişen (8):
- `lib/screens/admin_portal/admin_home_screen.dart`
- `lib/screens/secretary_portal/secretary_dashboard_screen.dart`
- `lib/screens/teacher_menu_screen.dart`
- `lib/widgets/design/design_hub_tile.dart`
- `lib/widgets/design/design_feed_row.dart`
- `lib/widgets/design/design_mini_month_calendar.dart`
- `lib/widgets/design/teacher_design_home_primary.dart`
- `lib/l10n/app_localizations.dart` (5 anahtar, tr + en)

Yeni (3):
- `lib/widgets/design/design_pill.dart`
- `lib/widgets/design/design_collapsible_section.dart`
- `test/hub_fazb_test.dart`

Doküman: `docs/actions/myeduapp_design_fazb_hub_status.md` (bu rapor).
Toplam: 11 kod/test dosyası + 1 doküman.

## 9. Final status

| Ekran | Durum | Neden |
| --- | --- | --- |
| 14 Sekreter | **PASS** | Hub-first, mevcut tüm eylemler korunur, KPI ikincil; "Akademik Rapor" tile'ı mevcut özellik olmadığından bilinçli ertelendi |
| 02 Admin | **PASS** | Düzen, KPI, hedef hapı, 2:1 kolon; üst bar/sidebar farkı Faz C+ |
| 13 Öğretmen | **PASS** | Birincil satır net üstte, ikincil içerik bölümlenmiş ve korunmuş |

**FAZ B — PASS**

Analyze 0 hata (431 issue), testler 254/254 yeşil, QA genişliklerinde taşma yok. Manuel GUI doğrulaması yapılamadı (Deferred'de); kırık bir şey tespit edilmediği için tek başına PARTIAL nedeni değildir.
