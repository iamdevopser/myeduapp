# MyEduApp — SEKRETER HESABI

# FAZ 1 — Rol ve Oturum Altyapısı

## Amaç

MyEduApp'e Sekreter hesabının eklenmesi için mevcut `isTeacher` tabanlı rol yaklaşımını kontrollü biçimde genişlet.

Bu faz yalnızca **rol ve oturum altyapısını** hazırlayacaktır.

Sekreter için henüz gerçek öğrenci, veli, devamsızlık, rapor, belge veya diğer yönetim ekranlarını geliştirme.

Amaç, sonraki fazlarda Sekreter modüllerinin güvenli ve düzenli şekilde eklenebileceği temel mimariyi oluşturmaktır.

---

# 1. Önce mevcut kodu tekrar incele

Özellikle şu dosyaları mevcut durumlarıyla kontrol et:

* `lib/providers/app_state.dart`
* `lib/screens/home_screen.dart`
* `lib/screens/home_role_grid.dart`
* `lib/widgets/app_shell.dart`
* `lib/screens/.../student_tab_workspace.dart`
* `lib/screens/.../teacher_tab_workspace.dart`
* `lib/app.dart`
* `lib/main.dart`

Ayrıca audit sırasında tespit edilen `isTeacher`, `setUnlocked`, `verifyTeacherPassword`, `verifyStudentPassword`, `verifySecretaryPassword` kullanımlarının tamamını bul.

**Kod değişikliğine başlamadan önce mevcut rol akışını tam olarak anla.**

---

# 2. AppRole oluştur

Mevcut sistemde olmayan merkezi rol enum'u oluştur.

Önerilen yapı:

```dart
enum AppRole {
  teacher,
  student,
  secretary,
}
```

Dosya konumu mevcut proje mimarisine uygun seçilmeli.

Örneğin:

```text
lib/models/app_role.dart
```

veya projede roller için mevcut uygun bir klasör varsa orası kullanılmalı.

Gereksiz yeni klasör oluşturma.

---

# 3. AppState'i rol tabanlı hale getir

Mevcut:

```dart
bool isTeacher
```

yaklaşımını doğrudan kaldırıp sistemi kırma.

Öncelikle geriye uyumlu bir geçiş yap.

Tercih edilen yapı:

```dart
AppRole? currentRole
```

ve:

```dart
bool get isTeacher => currentRole == AppRole.teacher;
bool get isStudent => currentRole == AppRole.student;
bool get isSecretary => currentRole == AppRole.secretary;
```

gibi compatibility getter'ları kullan.

Mevcut kodun tamamını aynı anda değiştirmek zorunda kalma.

---

# 4. setUnlocked yapısını genişlet

Mevcut:

```dart
setUnlocked(...)
```

metodunu Sekreter rolünü destekleyecek şekilde genişlet.

Örneğin:

```dart
setUnlocked(
  true,
  role: AppRole.secretary,
);
```

veya mevcut proje stiline daha uygun eşdeğer bir API kullan.

Önemli:

### Öğretmen

Mevcut öğretmen giriş davranışı değişmemeli.

### Öğrenci

Mevcut öğrenci giriş davranışı değişmemeli.

### Sekreter

Sekreter doğrulaması başarılı olduğunda:

```text
currentRole = AppRole.secretary
isUnlocked = true
```

olmalı.

---

# 5. Logout davranışını kontrol et

Logout veya session reset sırasında:

```text
currentRole = null
isUnlocked = false
sessionClassId = null
sessionStudentId = null
```

gibi mevcut session state'leri uygun şekilde temizlenmeli.

Özellikle:

```text
Teacher → Logout → Secretary
Secretary → Logout → Student
Student → Logout → Teacher
```

gibi rol geçişlerinde eski rol state'inin taşınmamasını sağla.

---

# 6. Sekreter giriş akışını düzelt

Mevcut davranış:

```text
Sekreter şifresi doğru
        ↓
Snackbar
        ↓
Panel yok
```

şeklinde.

Bunu:

```text
Sekreter şifresi doğru
        ↓
AppRole.secretary
        ↓
SecretaryTabWorkspace
```

haline getir.

Mevcut:

```text
homeRoleSecretaryNotAvailable
```

gibi snackbar / "kullanılamıyor" mesajını kaldır.

Sekreter şifresi yanlışsa mevcut hata davranışı korunmalı.

---

# 7. SecretaryTabWorkspace oluştur

Henüz gerçek Sekreter modüllerini oluşturma.

Sadece minimal bir workspace oluştur.

Örneğin:

```text
SecretaryTabWorkspace
    └── AppShell
          └── Sekreter Ana Sayfa / Placeholder
```

Ekranda geçici olarak:

```text
Sekreter Paneli

Sekreter hesabı başarıyla oluşturuldu.
```

gibi basit bir içerik olabilir.

Ancak placeholder'ın ileride gerçek dashboard ile kolayca değiştirilebileceği bir yapı kur.

---

# 8. AppShell'i üç role hazırla

Mevcut:

```text
isTeacher
   ├── teacher sidebar
   └── student sidebar
```

mantığını:

```text
currentRole
   ├── teacher
   ├── student
   └── secretary
```

mantığına hazırla.

Bu fazda Sekreter sidebar'ı tamamen geliştirme.

Geçici olarak:

```text
Ana Sayfa
```

tek menü öğesi yeterlidir.

Ancak mimari:

```text
if teacher
else if student
else if secretary
```

şeklinde dağınık hale gelmemeli.

Mümkün olduğunca mevcut sidebar mimarisini tekrar kullan.

---

# 9. SecretaryNavSection için altyapı oluştur

Sekreter menüsü bu fazda yalnızca:

```text
Ana Sayfa
```

içerebilir.

Ancak ileride şu yapıya genişleyebilecek şekilde tasarla:

```text
SecretaryNavSection
    home
    students
    parents
    teachers
    classes
    schedules
    attendance
    announcements
    documents
    reports
    notifications
    profile
```

Henüz bu ekranların hiçbirini implement etme.

---

# 10. Teacher ve Student davranışını koru

Bu fazın en önemli kuralıdır.

Aşağıdakiler mevcut davranışlarıyla çalışmaya devam etmeli:

### Teacher

* Teacher login
* Teacher workspace
* Teacher sidebar
* Teacher tabs
* Academic Plans
* Lesson Platform
* Student Platform
* mevcut teacher navigation

### Student

* Student login
* Student workspace
* Student sidebar
* Student session
* mevcut öğrenci ekranları

Sekreter eklenirken bu iki rolün davranışını gereksiz yere değiştirme.

---

# 11. AuthorizationService konusunda

Audit raporunda `AuthorizationService` gerekli görülmüştür.

Bu fazda tam permission sistemi geliştirme.

Ancak ileride kullanılabilecek basit bir iskelet gerekiyorsa oluşturabilirsin.

Örneğin:

```text
AuthorizationService
```

içinde rol kontrolü yapılabilecek temel yapı hazırlanabilir.

Fakat:

* kapsamlı permission enum'u
* tüm ekranlara capability sistemi
* database wrapper
* approval workflow

bu fazın dışında.

Bunlar ilerleyen fazlarda yapılacak.

---

# 12. Routing

Mevcut uygulamada Teacher/Student geçişinin `pushReplacement` + workspace yaklaşımı nasıl çalışıyorsa onu koru.

Sekreter için aynı mimariyi kullan.

Örneğin:

```text
HomeScreen
    ↓
Secretary authentication
    ↓
SecretaryTabWorkspace
```

Sekreter için ayrı ve gereksiz bir routing sistemi oluşturma.

Mevcut routing mimarisini bozma.

---

# 13. Web / Mobile

Mevcut `AppShell` responsive yapısını kullan.

Sekreter için:

* Desktop sidebar
* Mobile drawer
* PageHeader

mevcut sistemle uyumlu çalışmalı.

Ayrı bir mobile Sekreter UI oluşturma.

---

# 14. Database

Bu fazda yeni database tablosu oluşturma.

Yeni:

* Parent table
* Teacher table
* Approval table
* Notification table
* Secretary profile table

oluşturma.

Bunlar sonraki fazlarda ele alınacak.

Mevcut `ayarlar.secretary_password_hash` yapısı kullanılmaya devam edebilir.

---

# 15. Yapılmaması gerekenler

Bu faz kapsamında aşağıdakileri yapma:

* Veli modülü
* Öğretmen yönetimi
* Öğrenci CRUD refactor
* Devamsızlık modülü
* Rapor modülü
* Belge modülü
* Duyuru modülü
* Academic Plans değişikliği
* Weekly Schedule değişikliği
* Permission sisteminin tamamı
* Database migration
* Audit log
* Bildirim sistemi
* Şifreleme
* Cloud backend
* Yeni authentication provider

---

# 16. Test

Kod değişikliklerinden sonra aşağıdaki senaryoları test et.

### Test 1 — Teacher

```text
Home
→ Teacher
→ doğru şifre
→ Teacher workspace
```

Teacher davranışı değişmemeli.

### Test 2 — Student

```text
Home
→ Student
→ doğru şifre
→ Student workspace
```

Student davranışı değişmemeli.

### Test 3 — Secretary

```text
Home
→ Secretary
→ doğru şifre
→ Secretary workspace
```

Snackbar yerine Sekreter workspace açılmalı.

### Test 4 — Wrong secretary password

```text
Home
→ Secretary
→ yanlış şifre
```

Workspace açılmamalı.

### Test 5 — Teacher → Logout → Secretary

Eski teacher state'i Sekreter'e taşınmamalı.

### Test 6 — Secretary → Logout → Student

Sekreter state'i öğrenciye taşınmamalı.

### Test 7 — Student → Logout → Teacher

Öğrenci session bilgileri öğretmen oturumuna taşınmamalı.

### Test 8 — Responsive

Sekreter workspace:

* desktop
* dar ekran
* mobile/drawer

üzerinde crash olmadan açılmalı.

---

# 17. Test ve analiz sırasında hata çıkarsa

Bir test mevcut sistemde önceden var olan bir problem nedeniyle başarısız oluyorsa bunu raporla.

Sırf Faz 1'i tamamlamak için ilgisiz bir refactor yapma.

---

# 18. Kod kalitesi

* Mevcut naming convention'ı koru.
* Mevcut architecture pattern'ini takip et.
* Duplicate kod oluşturma.
* Gereksiz abstraction oluşturma.
* Mevcut çalışan ekranları yeniden yazma.
* Null-safety kurallarını koru.
* Linter hatalarını artırma.

---

# 19. Faz sonunda rapor

Kodlama tamamlandıktan sonra şu formatta kısa final raporu oluştur:

## FAZ 1 STATUS

```text
PASS / PARTIAL / BLOCKED
```

### Yapılanlar

* AppRole
* AppState role handling
* Secretary authentication flow
* SecretaryTabWorkspace
* AppShell secretary branch
* Logout/session cleanup
* Tests

### Değiştirilen dosyalar

Listele.

### Test sonucu

Her test için:

```text
PASS / FAIL
```

### Risk / Not

Varsa belirt.

### Sonraki Faz

Faz 2'nin kapsamını bir paragrafla belirt.

---

## Kritik kural

**Önce mevcut kodu oku, sonra değiştir.**

Kod tabanında audit raporunda önerilen yapıdan farklı ama daha uygun bir mevcut pattern varsa onu tercih et.

Amaç mevcut MyEduApp mimarisini bozmak değil, Sekreter rolünü bu mimariye kontrollü şekilde eklemektir.
