# Faz 2 — FINAL AUDIT (2026-10-08)

Kaynak: `docs/design/faz2_final_kapanis.md`  
Baseline test: **227 passed / 0 failed** (Tur 4)

## Özet tablo

| İş | Mevcut durum | Yapılacak değişiklik | Veri/Mimari | Sonuç (plan) |
| --- | --- | --- | --- | --- |
| **02 Admin duyuru UI** | PARTIAL — pill + önizleme Tur 4 | `DesignFeedRow` / grouped card; Semantics | `listAnnouncementsForSecretary` | **PASS** |
| **05 Not UI** | PARTIAL — hint metni | `getScoreColumns` + `getStudentScores` sekreter detay Notlar sekmesi | Mevcut not tablosu | **PASS** |
| **06 Öğretmen mobil takvim** | Desktop `WeeklySchedulePanel` only | `<1024` → `DesignMonthGridCalendar` + ders listesi | Haftalık program DB | **PASS** |
| **12 Duyuru görseli** | İkon hero | `kapak_gorsel_yolu` migration v35; model/service; detay `FileImage` if exists | SQLite + dosya yolu | **PASS** (görsel yoksa fallback) |
| **09 Veli toplantısı** | Sadece ders/sınav | `mentorluk_etkinlikler` + `tur=veli_toplantisi`; mentorship dialog seçeneği; öğrenci takvimde göster | Tablo mevcut | **PASS** (veri yoksa boş liste) |
| **09 Takvim genel** | PARTIAL | Mentorship + sınav + ders birleşimi; event Semantics | Mevcut | **PASS** |
| **Responsive 8 bp** | Kısmi widget test | `design_faz2_responsive_test.dart` 8 genişlik | — | **PASS** (widget) |
| **A11y / l10n** | Kısmi | Eksik anahtarlar; event type labels | l10n | **PASS** |
| **07 Mesajlar** | Kapsam dışı | Dokunulmaz | — | N/A |

## Tur 1–4 durumu

- Tur 1–2: `faz_design_faz2_status.md`, `faz_design_faz2_tur2_status.md` — 13/14/03/04/01 PARTIAL; 05/02/06 PARTIAL
- Tur 3: 08/11 design list — Tur 4’te 08/11 PASS
- Tur 4: `faz_design_faz2_tur4_audit.md`, `faz_design_faz2_tur4_status.md` — 12 PARTIAL (görsel), 09 PARTIAL

## Duyuru görseli

- `ogrenci_duyurular` şu an görsel kolonu **yok**; dosya yolu pattern’i (`icerikler.dosya_yolu`, `dersler.resim_yolu`) mevcut.
- **Karar:** v35 migration `kapak_gorsel_yolu TEXT NULL`; sekreter/öğretmen insert-update; öğrenci detayda gerçek dosya varsa göster. Sahte URL/görsel **yok**.

## Veli toplantısı

- `mentorluk_etkinlikler` (tarih, saat, baslik, tur, sinif_id) **mevcut**; öğrenci portalına bağlanmamış.
- **Karar:** `MentorshipEventType.parentMeeting = 'veli_toplantisi'`; dialog’a seçenek; öğrenci takviminde sınıf+kapsam sorgusu. Sahte event **yok**.

## 05 Not verisi

- Notlar `not_kolonlari` + `ogrenci_notlar` / `getStudentScores` ile mevcut — sekreter detayda bağlanabilir.

## Riskler

- DB v35 → mevcut migration testleri güncellenmeli
- Öğretmen takvim tüm sınıflar — `DesignAcademicCalendarData.load` without filter (teacher view)

---

*Audit tamamlandı — implementasyon başlıyor.*
