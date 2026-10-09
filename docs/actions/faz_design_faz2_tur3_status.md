# Faz 2 Tur 3 — FINAL STATUS (2026-10-08)

Prompt: [`docs/design/faz_design_faz2_tur3.md`](../design/faz_design_faz2_tur3.md)

## Süreç

| Adım | Durum |
| --- | --- |
| PLAN | ✓ 08 → 12 → 09 → 11 |
| IMPLEMENTATION | ✓ öğrenci portalı 08/12/09/11 design list + detay |
| TEST | ✓ `flutter test` (aşağıda) |
| ANALYZE | ✓ Tur 3 dosyalarında 0 error (mevcut info/warning) |
| RESPONSIVE QA | **Kısmi** — widget test 360/390/430; 8 genişlik manuel turu yapılmadı |
| ACCESSIBILITY QA | **Kısmi** — Semantics pill/satır/takvim günü, tooltip arama/mark-read |
| DOCUMENTATION | ✓ bu dosya + ana doküman güncellemeleri |

## Ekran sonuçları

| # | Ekran | Durum | Not |
| --- | --- | --- | --- |
| **08** | Duyurular | **PARTIAL** | `StudentAnnouncementsScreen`: `DesignPortalPageLayout`, filtre pill’leri (Tümü/Okul/Sınıf/Veli), gruplu `DesignGroupedListCard` + `DesignFeedRow`, arama, okunmamış vurgusu (bildirim `listForCurrentUser`). AppShell alt nav referans 08 ile birebir değil (P10). |
| **12** | Duyuru detay | **PARTIAL** | `StudentAnnouncementDetailScreen`: başlık/tarih, içerik kutusu, ikon hero (DB görseli yok — sahte foto yok). **Okundu İşaretle** → P9 `markAsRead` (duyuru referanslı bildirim). |
| **09** | Takvim | **PARTIAL** | Öğrenci haftalık program `<1024`: `DesignMonthGridCalendar` + gün etkinlik listesi (haftalık program verisi). ≥1024 grid korundu. Sınav/veli toplantısı ayrı model yok. |
| **11** | Dokümanlar | **PARTIAL** | `StudentDocumentsScreen`: aynı layout sistemi; tip+tarih meta (dosya boyutu modelde yok). Doküman açma/detay henüz bağlanmadı (`onTap` boş). |

## Önceki ekran regression

- Faz 1 (01 mobil, 10, 15, 16): **PASS** (suite içinde)
- Tur 1–2 ekranları: kod değişmedi; **PARTIAL** durumları korunuyor

## Test / analyze

| | |
|---|---|
| **flutter test** | **223 passed / 0 failed** (219 baseline + 4 `design_tur3_test`) |
| **flutter analyze** (Tur 3 yolları) | 0 error; pre-existing `intl` info, `student_portal_service` unused import uyarıları |

## Responsive

| Genişlik | Kontrol |
| --- | --- |
| 360–430 | `design_tur3_test` pill + feed + ay grid |
| 768–1920 | `CustomScrollView`, gruplu kart tam genişlik, filtre yatay scroll |

## Accessibility

- `DesignScrollFilterPills` / `DesignMonthGridCalendar` gün hücreleri: `Semantics`
- `DesignFeedRow`: `semanticsLabel`, `button` when tappable
- Detay: `FilledButton` + mark-read label; arama `tooltip`

## Değişen / yeni dosyalar

**Yeni**

- `lib/widgets/design/design_scroll_filter_pills.dart`
- `lib/widgets/design/design_feed_row.dart`
- `lib/widgets/design/design_grouped_list_card.dart`
- `lib/widgets/design/design_portal_page_layout.dart`
- `lib/widgets/design/design_month_grid_calendar.dart`
- `lib/utils/student_portal_announcement_ui.dart`
- `lib/utils/student_announcement_notification.dart`
- `lib/screens/student_portal/student_announcement_detail_screen.dart`
- `test/design_tur3_test.dart`
- `docs/actions/faz_design_faz2_tur3.md`
- `docs/actions/faz_design_faz2_tur3_status.md`

**Güncellenen**

- `lib/services/student_portal_service.dart` (`StudentPortalAnnouncement` id + `hedef_tur`)
- `lib/screens/student_portal/student_portal_section_screens.dart`
- `lib/utils/student_navigation.dart`
- `lib/l10n/app_localizations.dart`
- `docs/actions/faz_design_faz2_status.md`
- `docs/actions/faz_design_cursor_plan.md`
- `docs/actions/faz_13_14.md`

## Eklenen testler

- `test/design_tur3_test.dart` (4): filter pills 360px, feed row, month grid, announcement filter unit

## Kalan technical debt

- 08/11: veli filtresi öğrenci verisinde tam “Veli” kategorisi yok (mevcut alanlara yaklaşık eşleme)
- 11: doküman satırı → mevcut indirme/görüntüleme akışına `onTap` bağlama
- 12: gerçek duyuru görseli alanı yok; bildirimden detay açma (`openStudentAnnouncementDetailById`) AppShell scope ile tam entegre değil
- 09: hafta sonu / sınav etkinlikleri; desktop takvim görünümü referans 09 ile hizalı değil
- Tur 2 borçları (02/05/06) açık
- Tam 8 genişlik manuel QA
- Veli portalı aynı design list (isteğe bağlı sonraki tur)

## Korunan

- P9 `listForCurrentUser` / `markAsRead`, document authorization, AppShell, mevcut servisler, yeni backend/DB yok
- **07 Mesajlar** dokunulmadı
