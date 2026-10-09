# Faz 2 Tur 4 — AUDIT (2026-10-08)

Kaynak prompt: `docs/design/faz2_tur4.md` (kullanıcı yolu: `docs/new_updates/faz2_tur4.md` — repoda `docs/design/faz2_tur4.md`).

Baseline test: **223 passed / 0 failed** (Tur 3).

---

## 1. Tur 3 PARTIAL — kapatılabilirlik

| Madde | Kapatılabilir? | Yaklaşım |
| --- | --- | --- |
| 08 Veli filtresi yanlış eşleme | **Evet** | `hedef_tur`: Okul=`tum_okul`, Sınıf=`sinif`, Veli=`sube`/sınıf hedefli (`section` + `sinif_id`). Sahte `veli` alanı yok. |
| 08 AppShell / alt nav | **Kısmen** | Referans 5 sekme (Takvim var); P10 öğrenci 4 sekme. **Öğrenciye Takvim sekmesi eklenir** (5 sekme); diğer roller 4 kalır. Mesajlar (07) eklenmez. |
| 12 Bildirim → detay | **Evet** | `AppState.pendingStudentAnnouncementOpenId` + `notification_navigation` + `StudentAnnouncementsScreen` tüketimi; yoksa SnackBar. |
| 11 Doküman `onTap` | **Evet** | SQL zaten `i.id` seçiyor; modele `contentId`/`lessonId` eklenir. `AppState.prepareStudentContentViewer` + mevcut `AppViewerScreen` (`studentLessonViewer`). Path boşsa açılmaz (BLOCKED mesajı). |
| 09 Sınav / veli toplantısı event | **Kısmen** | Ayrı event tablosu yok. **Sınav**: `loadExams` + seçili tarih eşleşmesi (mevcut `tarih` alanı). Veli toplantısı: **BLOCKED** (veri yok). |
| 09 Responsive | **Evet** | Portal layout `maxWidth` + widget test genişlikleri. |
| 12 Hero görsel | **BLOCKED** | `ogrenci_duyurular` görsel kolonu yok; ikon hero kalır (PASS değil, PARTIAL kalabilir). |
| 11 Dosya boyutu | **BLOCKED** | Modelde yok; gösterilmez. |

---

## 2. Veri modeli / backend

- Duyuru: `hedef_tur` ∈ `tum_okul`, `sinif`, `sube` — **veli özel türü yok**.
- Doküman: `icerikler` + `dosya_yolu` — açılabilir; boyut alanı yok.
- Takvim: haftalık program + sınav not kolonları; veli toplantısı entity yok.

Yeni SQLite tablosu / auth / API **bu turda yok**.

---

## 3. Tur 2 borçları (02 / 05 / 06)

| Ekran | Durum | Tur 4 aksiyon |
| --- | --- | --- |
| 02 Admin dashboard | PARTIAL | Duyuru satırına `hedef_tur` pill + içerik önizleme (veri var) — **küçük UI** |
| 05 Öğrenci detay | PARTIAL | Notlar sekmesi gerçek not UI — **büyük**; dokunulmaz |
| 06 Akademik takvim | PARTIAL | Öğretmen mobil design takvim — **orta**; sadece öğrenci 09 iyileştirmesi |

---

## 4. Yeniden kullanılacak Design widget’lar

`DesignPortalPageLayout`, `DesignGroupedListCard`, `DesignFeedRow`, `DesignScrollFilterPills`, `DesignMonthGridCalendar`, `DesignSurfaceCard`, `DesignSystem`.

Yeni paralel liste bileşeni **oluşturulmayacak**.

---

## 5. Test koruma alanları

- P9/P10: `settings_notification_p9_test`, `mobile_navigation_p10_test` (öğrenci 5 sekme güncellemesi)
- `notifications_faz8_test`, `student_portal_service_test`
- `design_tur3_test` regression

---

## 6. PASS hedefi gerçekçilik

| Ekran | Tur 4 hedef |
| --- | --- |
| 08 | PASS (filtre + nav + a11y) |
| 12 | PARTIAL→PASS mümkün (görsel hero BLOCKED ise PARTIAL kalabilir) |
| 11 | PASS (açma path varsa); path yoksa satır SnackBar |
| 09 | PARTIAL (sınav eklenir; veli toplantısı BLOCKED) |

---

## 7. Uygulama sırası (onaylandı)

1. Filtre + notification + pending detay  
2. Doküman model + açma  
3. AppShell öğrenci takvim sekmesi  
4. Takvim sınav satırları + responsive/a11y  
5. Admin 02 küçük duyuru satırı  
6. Testler + status  

---

*Audit tamamlandı — implementasyon bu dosyadan sonra başlar.*
