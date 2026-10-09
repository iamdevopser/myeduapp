# MyEduApp — Faz A (Token + Shell) Durum Raporu

Kapsam: `docs/actions/myeduapp_design_redesign_plan.md` §2.4, §8, §11 "Faz A".
Kural: `lib/data`, `lib/services`, auth, `AuthorizationService`, AppState iş mantığı, navigasyon/rota/rol mantığı, Mesajlar (07) ve ekran iş mantığı **değiştirilmedi**.

## 1. Implemented

- Tek bir tasarım token sistemi (mevcut `AppColors` / `AppSpacing` / `DesignSystem` genişletildi; paralel sistem yok).
- `AppDesignTokens` `ThemeExtension` (light + dark), `context.tokens` erişimcisi, `app_theme.dart` içinde iki temada kayıtlı.
- Tipografi ölçeği (`AppTypography`) ve `TextTheme` eşlemesi.
- Responsive temel: `AppBreakpoint`, `AppSpacing.breakpoint`, `qaWidths`, `horizontalPagePadding`.
- `AppShell` hizalaması: token kullanımı, erişilebilir sidebar/drawer öğeleri, geniş ekranda içerik max genişliği (`constrainContent`).
- Genel amaçlı `DesignPageContainer` / `DesignSectionHeader` (henüz hiçbir ekranda kullanılmıyor).

## 2. Design Token Changes

- **Renk (`AppColors`)**: `surfaceElevated`, `primary` (= `primaryBlue`), `secondary` (= `accentPurple`), `accent` (= `brandPrimary`), `borderSubtle`, `borderStrong`, `divider`, `success`, `warning`, `error`, `info`. Dark karşılıklar: `AppColorsDark`.
- **Tipografi (`lib/theme/app_typography.dart`)**: `display` 32/w800, `heading` 22/w800 (pageTitle), `title` 18/w700 (sectionTitle), `body` 14, `bodySmall` 13, `label` 14/w600, `caption` 12; hepsinde satır yüksekliği (height) tanımlı.
- **Spacing**: `xxxl` 48, `minTouchTarget` 48, `contentMaxWidth` 1280, `readableMaxWidth` 960.
- **Radius (`AppRadius`, `app_spacing.dart`)**: small 8, medium 12, large 16, card 16, pill 999. `AppSpacing.cardRadius` = 12 ve `DesignSystem.cardRadius` = 16 (değerler korundu, token'a bağlandı).
- **Gölge / kenarlık (`design_system.dart`)**: `AppShadows.card/elevated/dialog` (`DesignSystem.cardShadow` = `AppShadows.card`), `AppBorders.defaultSide/subtle/strong`.
- **Tema (`app_theme.dart`)**: light/dark tek ortak builder; `colorScheme`, scaffold, `textTheme`, card, input, filled/outlined/text buton min 48 px yükseklik, icon button 48x48, görünür `focusColor`, divider, chip, tooltip.
- **Part 1 sapmaları (bilinçli)**:
  - `AppColors.background` `#F4F6FA` → `#F1F5F9` (workspace zemini ile aynı).
  - Light tema primary `#007BFF` → `#2563EB` (beyaz metinle kontrast ~4.0 → ~5.2). Sidebar hâlâ doğrudan `referenceBlue` kullanıyor.
  - Metin boyutları: `bodySmall` 12 → 13, `labelMedium` 12/w600, `headlineSmall` 22, `displaySmall` 32; diğer roller Material varsayılanı veya korunmuş (bodyLarge/titleMedium 16, titleLarge 22).
  - Butonlar min 48 px yükseklik, icon button 48x48.
  - Dark tema `ColorScheme.fromSeed` ile kaldı; primary/secondary/surface/error/outline dark token'lardan override edildi.

## 3. App Shell Changes

- `AppShell.constrainContent` (varsayılan `true`): içerik alanı yalnızca shell genişliği >= 1440 iken `contentMaxWidth` (1280) ile ortalanır. Uygulama `Padding` ile yapılır (Align değil) → yükseklik sıkı kalır, Expanded/scroll çocuklar etkilenmez. < 1440 davranışı değişmedi. Arka plan tam genişlikte.
- `app_viewer_screen.dart` ve `app_builder_screen.dart`: yalnızca `constrainContent: false` parametresi geçildi (full-bleed).
- Sidebar/drawer öğeleri ortak `_SidebarInkItem` ile: min 48 px, `Semantics(button, selected, label, onTap)`, seçili hap `AppRadius.medium`, klavye odağında 2 px beyaz çerçeve + `focusColor`, daraltılmış sidebar'da `Tooltip`. Grup üst öğeleri (Ders Platformu, Akademik Planlar) ve alt öğeler aynı yapıya taşındı; grup aç/kapa düğmesi 48 px.
- Kullanılmayan `_SecretarySidebarGroup` ölü kodu silindi (2 analyzer uyarısı azaldı).
- Marka başlığı ve drawer profil alanı `Semantics(header: true)`; daraltılmış sidebar'da marka ikonu 48 px, tooltip + button semantics.
- Çıkış öğesi: `AppColors.accentRed` → `AppColors.error` (aynı değer).
- Öğretmen sekme çubuğu/chip: `context.tokens` + `AppRadius`, chip'e button/selected semantics.
- `PageHeader`: token renkleri (`context.tokens`), compact yükseklik `minTouchTarget`.
- `AppMobileBottomNav`: etiketler her zaman görünür (`alwaysShow`), yükseklik 80, token renkleri; öğeler/sıra değişmedi. `NavigationDestination` zaten button + selected semantics sağlar.
- Menü düğmesi tooltip'i (`MaterialLocalizations`) korundu.
- `DesignSurfaceCard`: API değişmedi; `AppRadius.card` / `AppShadows` / `AppBorders` kullanıyor (görsel aynı).
- Yeni: `lib/widgets/design/design_page_container.dart` — `DesignPageContainer` (responsive yatay padding, max genişlik, opsiyonel scroll), `DesignSectionHeader` (`DesignSystem.sectionTitle` + trailing, `Semantics(header)`). Eşdeğeri yoktu (`DesignListPageHeader` farklı amaçlı).

## 4. Responsive Foundation

- `AppBreakpoint { smallMobile <390, largeMobile <600, tablet <1024, smallDesktop <1440, largeDesktop >=1440 }`.
- `AppSpacing.breakpoint(width)`, `AppSpacing.qaWidths = [360, 390, 430, 768, 1024, 1280, 1440, 1920]`.
- `AppSpacing.horizontalPagePadding(width)`: 12 / 16 / 24 / 24 / 32.
- Mevcut `isMobile/isTablet/isDesktop/layoutSize/pagePadding` aynı sonuçları döndürür (599/600/1023/1024 testle doğrulandı).

## 5. Accessibility Foundation

- Minimum dokunma hedefi 48 px: tema butonları, icon button, sidebar/drawer öğeleri, grup toggle, alt navigasyon.
- Semantics: nav öğeleri `button + selected + label`; başlık/profil `header`; sekme chip'leri `button + selected`.
- Klavye odağı: sidebar öğelerinde görünür çerçeve; temada `focusColor`.
- Daraltılmış sidebar: etiketler tooltip ile.
- Dark tema için kontrast gözetilerek seçilmiş token'lar (formal kontrast denetimi yapılmadı → Deferred).

## 6. Tests

- `flutter analyze` (tüm proje): **0 error**, 432 issue (Faz A öncesi 434; hepsi önceden var olan info/warning). Dokunulan dosyalarda yeni uyarı/info yok (`app_shell.dart` eski 2 uyarısı silindi; `app_viewer_screen`/`app_builder_screen` listelenenler önceden vardı, yalnızca satır numarası 1 kaydı).
- `flutter test`: **239 passed / 0 failed** (baseline 231 + 8 yeni).
- Yeni testler:
  - `test/design_tokens_faza_test.dart` (4): 8 QA genişliği için breakpoint sınıflandırması, `isMobile/isTablet/isDesktop` 599/600/1023/1024, `AppDesignTokens` light+dark temada kayıtlı, `copyWith`/`lerp`.
  - `test/app_shell_faza_test.dart` (4): 360/430/1024/1920 genişliklerinde `AppShell` istisnasız render; 360'ta drawer + bottom nav, 1024'te sidebar (tooltip'li); nav öğesi semantics (button/selected/label) ve >= 48 px yükseklik; içerik max genişliği yalnızca 1920'de 1280, `constrainContent: false` ile kapalı, 1280'de kısıtlama yok.

## 7. Regression Check

Duyurular, takvim, dokümanlar, notlar, öğrenci akışları, sekreter/öğretmen ekranları ve auth: iş mantığı ve ekran kodu **değiştirilmedi** (`lib/data`, `lib/services`, auth, `AuthorizationService`, AppState dokunulmadı; yalnızca `app_viewer_screen`/`app_builder_screen` içinde tek satır `constrainContent: false`). Tüm mevcut testler yeşil (239/239). Not: Tema değişikliği (primary mavi, 48 px butonlar, bodySmall 13) tüm ekranlara dolaylı görsel etki eder; widget testlerinde taşma/kırılma çıkmadı.

## 8. Deferred Items

- Ekranların `DesignPageContainer` / `DesignSectionHeader`'a taşınması.
- Hub / liste / detay ekranı yeniden tasarımları (Faz B–H).
- Windows ve mobilde manuel GUI QA (bu ortamda GUI çalıştırılamadı; yalnızca QA genişliklerinde widget testleri).
- Tam erişilebilirlik denetimi (formal kontrast ölçümü, ekran okuyucu geçişi, öğretmen sekme çubuğundaki küçük kapatma ikonu hedefi).
- Sidebar profil alanındaki ve ekranlardaki sabit renklerin (`Colors.white`, hardcoded hex) tokenlara taşınması; dark tema ekranlarda hâlâ kısmen açık sabit renkler içerir.
- 07 Mesajlar (Faz G) — hiçbir şey eklenmedi.
- `app_viewer_screen`/`app_builder_screen` dışındaki geniş grid ekranları (ör. akademik planlar haftalık tablo) >= 1440'ta 1280 ile sınırlanır; sorun görülürse ekran bazında `constrainContent: false`.

## 9. Changed Files

Part 1:
- `lib/theme/app_colors.dart`, `lib/theme/app_spacing.dart`, `lib/theme/design_system.dart`, `lib/theme/app_theme.dart` (değişti)
- `lib/theme/app_typography.dart`, `lib/theme/app_design_tokens.dart` (yeni)
- `test/design_tokens_faza_test.dart` (yeni)

Part 2:
- `lib/widgets/app_shell.dart`, `lib/widgets/app_mobile_bottom_nav.dart`, `lib/widgets/page_header.dart`, `lib/widgets/design/design_surface_card.dart` (değişti)
- `lib/theme/design_system.dart` (tekrar; kart dekorasyonu token'lara bağlandı)
- `lib/screens/app_viewer_screen.dart`, `lib/screens/app_builder_screen.dart` (yalnızca `constrainContent: false`)
- `lib/widgets/design/design_page_container.dart`, `test/app_shell_faza_test.dart` (yeni)
- `docs/actions/myeduapp_design_faza_token_shell_status.md` (bu rapor)

Toplam: 15 kod/test dosyası + 1 doküman.

## 10. Final Status

**FAZ A — PASS**

Tüm hedefler uygulandı; analyze 0 hata, testler 239/239 yeşil. Manuel GUI doğrulaması yapılamadı (Deferred'de belirtildi); bu tek başına PARTIAL nedeni değildir, çünkü kırık bir şey tespit edilmedi.
