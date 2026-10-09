# FAZ 13 — UI/UX & Design System Alignment

## FAZ 13 — FINAL STATUS (in progress)

| Alan | Durum |
| --- | --- |
| Phase 0 audit | ✓ `docs/actions/faz_13.md` |
| Baseline tests | 187+ passed (P6 sonrası koşu gerekli) |
| DB version | v34 |
| AppShell background | ✓ global `AppWorkspaceBackground` |
| P0–P5 | ✓ kısmi (§17) |
| **P6 Öğrenci portalı** | ✓ kısmi (aşağıda) |
| P7–P11 | ⏳ |

### P6 — Öğrenci portalı (2026-10-07)

| Bileşen | Durum |
| --- | --- |
| Öğrenci Shell | PASS — `StudentTabWorkspace` + `AppShell` drawer/sidebar |
| Dashboard | PARTIAL — `ReferenceStatCard` KPI, özet metni, Tümünü gör |
| Dersler | PARTIAL — responsive grid + `StudentCourseCard` |
| Detay panelleri | PARTIAL — `StudentPortalActivityCard`, profil responsive satırlar |
| Duyurular | PARTIAL — `StudentAnnouncementCard` (ExpansionTile) |
| Belgeler | PARTIAL — `StudentDocumentCard`; aç/indir içerik id modelde yok |
| Akademik | PARTIAL — performans/yoklama listeleri; haftalık program scroll |
| Bildirimler | PASS — shell bell (logic değişmedi) |
| Profil | PARTIAL — `StudentProfileHeader` + `StudentProfileInfoRow` |
| Responsive | PARTIAL — mobil kart düzeni; 360/390/430 manuel QA önerilir |
| Accessibility | PARTIAL — temel yapı; ek tooltip/semantic turu kaldı |
| Security Regression | PASS — auth/RBAC/servis değişmedi |

Yeni test: `test/student_portal_ui_test.dart`

### Remaining FAZ 13

- P7 Veli portalı, P8 Admin, P9 Ayarlar/bildirim merkezi
- P10 mobil bottom nav (deferred)
- P11 legacy cleanup
- Öğrenci portalı: belge görüntüleme (model genişletmesi ayrı faz), duyuru okundu state (veri yok)
- Secretary tablo → mobil kart
- AppBuilder boş durum
- Tam `flutter test` + `flutter analyze` final

Detay: **`docs/actions/faz_13.md` §16–§17**.
