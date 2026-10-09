# FAZ 14 — P7 Veli Portalı — Audit (2026-10-07)

## Özet

Veli portalı **önceden implemente edilmiş** (FAZ 7 / FAZ 10). P7 kapsamı: mevcut mimariyi koruyarak **shell/UI hizalama** (FAZ 13/P6 pattern), **haftalık program** ekranı, **zengin dashboard**, responsive/accessibility iyileştirmeleri ve dokümantasyon/test güncellemesi. **Yeni tablo/migration gerekmez** (schema v34: `veliler`, `ogrenci_veliler`, `sifre_hash`).

---

## 1. Login / roller

| Bileşen | Durum |
| --- | --- |
| `AppRole.parent` | ✓ `lib/models/app_role.dart` |
| Home veli girişi | ✓ `home_screen.dart` + `parent_login_dialog.dart` |
| `AppState.loginParent` | ✓ e-posta veya portal kullanıcı adı + şifre |
| `setParentSession` / `selectParentStudent` | ✓ DB `isStudentLinkedToParent` doğrulaması |
| Hesap tabanlı veli | ✓ `AccountService.createParentPortalAccount` (FAZ 9/10) |

Harici auth yok; lokal SQLite + hash.

---

## 2. AppState / session

- `sessionParentId`, `parentSelectedStudentId`, `activeParentSection`
- Veli oturumu öğrenci `sessionStudentId` ile karışmaz
- `selectParentStudent` bağlı olmayan ID’yi reddeder (test: `parent_portal_faz7_test.dart`)

---

## 3. AppShell

- `parentSection` + `parentSidebarMenuOrder` → navy sidebar, drawer mobil, `NotificationBellButton`, `AppWorkspaceBackground`
- `ParentTabWorkspace` tüm bölümlerde shell sarıyor

---

## 4. Öğrenci–veli veri modeli

- `veliler` (veli kaydı)
- `ogrenci_veliler` (ogrenci_id, veli_id, yakinlik)
- `AppDatabase.listStudentsForParent`, `isStudentLinkedToParent`
- Backup: mevcut export tabloları (FAZ 7+); yeni migration **gerekmez**

---

## 5. Servis katmanı

| Servis | Rol |
| --- | --- |
| `ParentPortalService` | IDOR korumalı veli API: `requireLinked`, duyuru/belge/devam/akademik |
| `StudentPortalService` | Öğrenci verisi; veli tarafında **enrollment** üzerinden yeniden kullanılacak |
| `SecretaryDocumentService` | Sekreter belgeleri aç/kopyala (veli read-only UI) |
| `AuthorizationService` | `canManage*AsParent` false, `canViewOwnStudents` true |

**Gap (P7):** Dashboard için `loadDashboardSummary` / `loadTodayLessons` delegasyonu `ParentPortalService`’te yok → **eklenecek** (write path yok).

---

## 6. Mevcut veli ekranları (`parent_portal_screens.dart`)

| Ekran | Durum | P7 iyileştirme |
| --- | --- | --- |
| Home | Basit liste | KPI + öğrenci kapsamlı özet |
| Children | ✓ | Korunur |
| Announcements | ListTile | `StudentAnnouncementCard` |
| Documents | ListTile + actions | Responsive aksiyonlar |
| Attendance | ✓ özet + liste | Korunur + UI token |
| Academic | Minimal | Boş state + skor formatı |
| Profile | Düz metin | `StudentProfileHeader` + bağlı öğrenciler |
| Weekly schedule | **Yok** | Yeni bölüm + read-only panel |

---

## 7. Öğrenci seçici

- `ParentStudentPicker` + `_StudentScopedScreen` + `AppState.parentSelectedStudentId`
- Çoklu öğrenci: dropdown; tek öğrenci: metin

---

## 8. Duyurular / belgeler / read-unread

- Duyurular: `StudentPortalService.loadAnnouncements` (yayın + scope)
- Read/unread persistence: **yok** → P7’de eklenmeyecek (faz_14 §11)
- Belgeler: sekreter `belge_kapsam` filtreli; viewer öğrenci içerik `icerikler` ile karışık — veli **sekreter belge** aç/kopyala mevcut

---

## 9. Bildirimler

- `NotificationBellButton` rol bazlı recipient (`AppState`); veli hesabı varsa kullanılır
- Yeni backend **gerekmez**

---

## 10. RBAC / güvenlik

- Servis: `ParentAccessDeniedException`, `requireLinked`
- Test: `parent_portal_faz7_test.dart`, `faz10_integration_test.dart` (foreign student)
- UI-only auth **yeterli değil** — mevcut servis kontrolleri korunacak

---

## 11. Student Portal UI yeniden kullanım

- `ReferenceStatCard`, `student_portal_ui.dart` (Announcement, Profile, Activity cards)
- `WeeklySchedulePanel` read-only + `allowedStudentClassIds`

---

## 12. Test altyapısı

- `parent_portal_faz7_test.dart` — login, IDOR, duyuru, belge, devam, read-only auth
- P7: servis delegasyon + widget smoke (`parent_portal_p7_test.dart`)

---

## 13. P7 kararları (PLAN)

1. Migration **yok**
2. `ParentNavSection.weeklySchedule` + shell menü
3. `ParentPortalService` → student portal read delegasyonları
4. Dashboard ve listeler → P6 UI bileşenleri
5. Dokümantasyon: `faz_14.md` status + `docs/new_updates/faz_14.md`
6. Kapsam dışı: duyuru okundu, öğrenci `icerik` viewer, ödeme, chat

---

*Audit tamamlandı — implementation onayı.*
