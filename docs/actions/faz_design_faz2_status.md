# Faz 2 — Tur 1 STATUS (2026-10-08)

> **Final kapanış:** [`faz_design_faz2_final_status.md`](faz_design_faz2_final_status.md) (2026-10-08, 231 test)

Kaynak prompt: `docs/design/faz_design_faz2.md`

## Süreç

| Adım | Durum |
| --- | --- |
| PLAN | ✓ Prompt + mevcut ekran/görsel eşleme |
| IMPLEMENTATION | Kısmi (öncelik 1–5 + 12 Windows login başlangıcı) |
| TEST | ✓ `flutter test` → **223 passed / 0 failed** (Tur 3) |
| ANALYZE | ✓ Faz 2 dosyalarında yeni error yok (proje geneli uyarılar devam) |
| RESPONSIVE QA | **Kısmi** — kodda breakpoint’ler kullanıldı; 360–1920 manuel matris yapılmadı |
| ACCESSIBILITY QA | **Kısmi** — hub/sınıf kartlarında `Semantics(button)`; tam matris yapılmadı |
| DOCUMENTATION | ✓ bu dosya + `faz_design_cursor_plan.md` güncellemesi önerilir |

## Ekran değerlendirmesi

| # | Referans | Durum | Not |
| --- | --- | --- | --- |
| 13 | Öğretmen paneli | **PARTIAL** | Birincil satır: Sınıflarım grid + Güncel Dersler; üst arama; KPI/hızlı işlemler altta. Sidebar/topbar referansla tam 1:1 değil. |
| 14 | Sekreter paneli | **PARTIAL** | Dikey hub kartları + bölüm başlıkları; KPI satırı hâlâ var; 4’lü grid yoğunluğu referanstan sapabilir. |
| 03 | Öğrenciler | **PARTIAL** | Sayfa başlığı + arama/filtre kartı tasarım token’ları; tablo kolonları/avatar/pill durum referansla tam değil. |
| 04 | Veliler | **PARTIAL** | Başlık + arama + Yeni Veli; tablo görünümü kısmen. |
| 05 | Öğrenci detay | **PARTIAL** | Tur 2 — `faz_design_faz2_tur2_status.md` |
| 02 | Admin dashboard | **PARTIAL** | Tur 2 — `faz_design_faz2_tur2_status.md` |
| 06 | Akademik takvim | **PARTIAL** | Tur 2 — `faz_design_faz2_tur2_status.md` |
| 08 | Duyurular | **PARTIAL** | Tur 3 — `faz_design_faz2_tur3_status.md` |
| 09 | Takvim | **PARTIAL** | Tur 3 — öğrenci ay grid + etkinlik listesi |
| 11 | Dokümanlar | **PARTIAL** | Tur 3 — design grouped list |
| 12 | Duyuru detay | **PARTIAL** | Tur 3 — `StudentAnnouncementDetailScreen` |
| 01 | Windows giriş | **PARTIAL** | Sol marka + sağ `DesignLoginLayout` (`desktopSplit`); `HomeRoleGrid` “diğer roller” ile korundu. |
| 07 | Mesajlar | N/A | Kapsam dışı |
| Faz 1 (01 mobil, 10, 15, 16) | — | **PASS** | Regression: 216 test |

## Değişen / eklenen dosyalar

**Yeni**

- `lib/theme/design_system.dart`
- `lib/widgets/design/design_surface_card.dart`
- `lib/widgets/design/design_class_grid_card.dart`
- `lib/widgets/design/design_hub_tile.dart`
- `lib/widgets/design/design_list_page_header.dart`
- `lib/widgets/design/teacher_design_home_primary.dart`
- `docs/actions/faz_design_faz2_status.md`

**Güncellenen**

- `lib/screens/teacher_menu_screen.dart`
- `lib/screens/secretary_portal/secretary_dashboard_screen.dart`
- `lib/screens/secretary_portal/secretary_students_list_screen.dart`
- `lib/screens/secretary_portal/secretary_parents_list_screen.dart`
- `lib/screens/home_screen.dart`
- `lib/screens/home/design_login_layout.dart`
- `lib/l10n/app_localizations.dart`
- `test/teacher_menu_screen_test.dart`
- `test/design_ui_faz1_test.dart`

## Testler

- Mevcut suite: **216 passed**
- Faz 1: `test/design_ui_faz1_test.dart` (2 widget)
- Güncellenen: `test/teacher_menu_screen_test.dart`

## Teknik borç

- 05, 02, 06, 08, 09, 11, 12 ekranları Faz 2 devamı
- Sekreter/öğrenci tablolarında avatar, durum pill, pagination footer referans hizası
- Öğretmen sidebar menü öğeleri (Öğrenciler/Veliler/Mesajlar) tasarım 13 ile birebir değil (mevcut `AppShell` menüsü)
- Tam responsive/a11y matrisi (360, 390, 430, tablet, 1280, 1440, 1920)
- `secretary_dashboard_screen.dart` içinde kullanılmayan `_HubActionCard` (dead code — sonraki turda temizlenebilir)

## Korunan davranışlar

- P9/P10 authorization, backup, notification scope
- DB / auth / yeni backend yok
