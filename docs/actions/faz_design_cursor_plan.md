# MyEduApp — `cursor_tasarım.png` uygulama planı

Kaynak görseller: `docs/design/MyEduApp_design_pages_separated/` (16 ekran).

Metodoloji: PLAN → IMPLEMENTATION → TEST → ANALYZE → RESPONSIVE QA → ACCESSIBILITY QA → DOCUMENTATION → FINAL STATUS.

## Ekran haritası

| # | Dosya | Tasarım özeti | Mevcut kod | Faz durumu |
| --- | --- | --- | --- | --- |
| 01 | `01_giris_ekrani.png` | Rol sekmeli giriş kartı | `home_screen.dart`, `design_login_layout.dart` | Faz 1 ✓ mobil |
| 02 | `02_ana_sayfa_dashboard.png` | Admin KPI + duyuru + takvim | `admin_home_screen`, secretary dashboard | Faz 2 |
| 03 | `03_ogrenciler.png` | Öğrenci listesi | Sekreter öğrenci ekranları | Faz 2 |
| 04 | `04_veliler.png` | Veli listesi | Sekreter veli | Faz 2 |
| 05 | `05_ogrenci_detay.png` | Öğrenci detay | Sekreter/student profil | Faz 2 |
| 06 | `06_akademik_takvim.png` | Akademik takvim | `academic_plans_*` | Faz 2 |
| 07 | `07_mesajlar.png` | Mesajlar | Kısmi / yok | Kapsam dışı (yeni backend yok) |
| 08 | `08_duyurular.png` | Duyuru listesi | `StudentAnnouncementsScreen` (design list) | Faz 2 Tur 3 **PARTIAL** |
| 09 | `09_takvim.png` | Takvim | Öğrenci `DesignMonthGridCalendar` | Faz 2 Tur 3 **PARTIAL** |
| 10 | `10_ayarlar.png` | Profil + ayar satırları | `settings_screen.dart`, `design_settings_profile_header.dart` | Faz 1 ✓ mobil kart + profil |
| 11 | `11_dokumanlar.png` | Belgeler | `StudentDocumentsScreen` (design list) | Faz 2 Tur 3 **PARTIAL** |
| 12 | `12_duyuru_detay.png` | Duyuru detay | `StudentAnnouncementDetailScreen` | Faz 2 Tur 3 **PARTIAL** |
| 13 | `13_ogretmen_paneli.png` | Öğretmen dashboard | `teacher_menu_screen.dart` | Faz 2 |
| 14 | `14_sekreter_paneli.png` | Sekreter hub | `secretary_dashboard_screen.dart` | Faz 2 |
| 15 | `15_mobil_menu_drawer.png` | Drawer + profil üstte | `app_shell.dart` drawer | Faz 1 ✓ |
| 16 | `16_hata_erisim_yok.png` | Erişim reddedildi | `design_access_denied_screen.dart` | Faz 1 ✓ |

## Kurallar (değişmez)

- Yeni auth/RBAC/DB altyapısı yok.
- P9/P10: `AuthorizationService`, `AppState`, `AppShell`, bildirim scope, FAZ 12 backup.
- Mobil `<600px` bottom nav (P10) + drawer (tasarım 15) birlikte.

## Faz 1 — tamamlandı

- Plan dokümanı
- Mobil giriş UI (01) — `design_login_layout.dart`, rol sekmeleri l10n düzeltmesi
- Erişim reddi (16) — `design_access_denied_screen.dart`; ayarlarda `embedded`
- Drawer profil üst + kırmızı çıkış + yuvarlatılmış kenar (15) — `app_shell.dart`
- Ayarlar profil başlığı + mobil tek kart (10)
- `test/design_ui_faz1_test.dart` (2 widget test)
- P9/P10 davranışı korundu

## Faz 2 — devam edecek

- Dashboard KPI/grid hizalama (02, 13, 14)
- Liste/detay kartları (03–05, 08, 11, 12)
- Takvim widget (06, 09)
- Masaüstü giriş ekranını tasarım 01 ile hizalama (şu an masaüstü `HomeRoleGrid`)

## FINAL STATUS (tasarım prompt — 8 adım)

| Adım | Durum |
| --- | --- |
| PLAN | ✓ `faz_design_cursor_plan.md` |
| IMPLEMENTATION | **Kısmi** — Faz 1 (6 ekran); Faz 2 açık |
| TEST | ✓ **223 passed** (`flutter test`, Tur 3) |
| ANALYZE | ✓ değişen dosyalarda yeni hata yok (önceden var olan `app_shell` uyarıları) |
| RESPONSIVE QA | **Kısmi** — mobil giriş/drawer/ayarlar; 360/390/430 manuel matrisi yapılmadı |
| ACCESSIBILITY QA | **Kısmi** — erişim reddi semantik; tam matris yapılmadı |
| DOCUMENTATION | ✓ bu dosya |
| %100 tasarım 1:1 | **Hayır** — 07 mesajlar kapsam dışı; 02–06, 08–09, 11–14 Faz 2 |

**Faz 2 tur durumları:** `faz_design_faz2_status.md`, Tur 2 `faz_design_faz2_tur2_status.md`, Tur 3 `faz_design_faz2_tur3_status.md`

**Son güncelleme:** 2026-10-08 (Tur 3)
