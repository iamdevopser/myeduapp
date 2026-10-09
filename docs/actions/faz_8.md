# FAZ 8 — Bildirim Merkezi / In-App Notifications

## 1. Amaç

MyEduApp içerisinde tüm kullanıcı rollerinin kendi yetkileri ve hedefleri doğrultusunda görebileceği bir **uygulama içi Bildirim Merkezi** oluşturulacaktır.

Bu fazda öncelik:

* Bildirimlerin veritabanında güvenli şekilde tutulması
* Okunmamış bildirim sayısının gösterilmesi
* Bildirim listesinin oluşturulması
* Bildirimin okundu olarak işaretlenmesi
* Tüm bildirimlerin okundu olarak işaretlenmesi
* İlgili ekranlara yönlendirme
* Rol ve kullanıcı izolasyonu
* Responsive desktop/mobile görünüm
* TR/EN localization
* JSON sync
* Testler

**Push notification, SMS ve e-posta bildirimi bu fazın kapsamı dışındadır.**

---

# 2. Uygulama Öncesi ZORUNLU AUDIT

Kodlamaya başlamadan önce mevcut proje mutlaka incelenmelidir.

Özellikle aşağıdakiler araştırılmalıdır:

### 2.1 Notification altyapısı

* `bildirim`
* `notification`
* `notifications`
* notification service
* notification model
* notification badge
* bell icon
* unread count
* snackbar/toast notification altyapısı

Mevcut bir sistem varsa kesinlikle yeniden oluşturulmayacak, mevcut altyapı genişletilecektir.

### 2.2 Kullanıcı / rol yapısı

Mevcut:

* `AppRole`
* `AppState.currentRole`
* teacher session
* student session
* secretary session
* parent session
* kullanıcı/student ID bilgileri
* `AuthorizationService`

incelenmelidir.

Bildirim hedefleme sistemi mevcut kullanıcı kimliğine güvenli şekilde bağlanmalıdır.

### 2.3 Mevcut event kaynakları

Aşağıdaki işlemlerin mevcut kodda nerelerde gerçekleştiği bulunmalıdır:

* duyuru yayınlama
* belge oluşturma/yayınlama
* belge hedefleme
* devam/attendance işlemleri
* öğrenci işlemleri
* veli işlemleri

Bunların her biri için gereksiz bildirim üretmekten kaçınılmalıdır.

### 2.4 Database / Sync

Mevcut:

* `AppDatabase`
* schema version
* `DatabaseSyncService`
* JSON export/import

yapısı incelenmelidir.

---

# 3. Bildirim Veri Modeli

Audit sonucunda mevcut notification tablosu yoksa, minimal ve genişletilebilir bir notification yapısı oluşturulmalıdır.

Önerilen yapı:

`bildirimler`

Alanlar minimum olarak:

* `id`
* `user_type` / `role`
* `user_id`
* `title`
* `body`
* `type`
* `reference_type`
* `reference_id`
* `created_at`
* `read_at`
* `status`

Ancak mevcut proje mimarisi farklı bir model gerektiriyorsa bu alanlar audit sonucuna göre uyarlanmalıdır.

## Önemli

Yeni tablo oluşturulması ancak mevcut sistemde kullanılabilir bir notification yapısı olmadığı doğrulandıktan sonra yapılmalıdır.

Gereksiz migration veya duplicate model oluşturulmamalıdır.

---

# 4. Bildirim Tipleri

İlk fazda minimum olarak aşağıdaki bildirim tipleri desteklenmelidir:

### 4.1 Announcement

Duyuru yayınlandığında ilgili hedef kullanıcılar bildirim alabilir.

Örnek:

> Yeni duyuru yayınlandı: Sınav Takvimi

Bildirim ilgili duyuruya yönlendirebilmelidir.

### 4.2 Document

Kullanıcının erişebileceği yeni bir belge yayınlandığında bildirim oluşturulabilir.

Örnek:

> Yeni belge yayınlandı: Okul Etkinlik Takvimi

Bildirim ilgili belgeye yönlendirebilmelidir.

### 4.3 Parent / Child

Veli hesabı için çocuğuyla doğrudan ilişkili bir işlem bildirim gerektiriyorsa notification sistemi bunu desteklemelidir.

Ancak bu fazda gereksiz veya anlamsız parent notification üretimi yapılmamalıdır.

### 4.4 Operational

Sekreter gibi kullanıcıların işlemleri açısından gerçekten gerekli olan operasyonel bildirimler desteklenebilir.

Bunun için mevcut iş akışları incelenmelidir.

---

# 5. NotificationService

Bildirim işlemleri merkezi bir servis üzerinden yönetilmelidir.

Örneğin:

`NotificationService`

veya mevcut projede buna karşılık gelen servis kullanılmalıdır.

Servis en azından şu işlemleri desteklemelidir:

* createNotification
* getNotificationsForCurrentUser
* getUnreadCount
* markAsRead
* markAllAsRead
* delete/archive gerekiyorsa mevcut mimariye göre yönetmek

Notification oluşturma işlemleri ekranlara dağınık şekilde yazılmamalıdır.

---

# 6. Hedef Kullanıcı Güvenliği

Bu bölüm kritik önem taşır.

Bir kullanıcı başka bir kullanıcının notification kayıtlarını görememelidir.

Özellikle:

### Öğrenci

Sadece kendi bildirimlerini görebilir.

### Veli

Sadece kendi veli hesabına ait bildirimleri görebilir.

Veli birden fazla çocuğa bağlı olsa bile başka veli hesabının notification kayıtlarına erişemez.

### Sekreter

Sadece kendi hesabına ait notification kayıtlarını görebilir.

### Öğretmen

Sadece kendi hesabına ait bildirimleri görebilir.

### Diğer roller

Mevcut `AppRole` ve `AuthorizationService` yapısına göre kontrol edilmelidir.

---

# 7. IDOR / Security

Notification ekranına `userId` veya başka bir ID parametresi verilerek başka kullanıcının bildirimlerine erişilememelidir.

Örneğin:

```text
NotificationScreen(userId: 25)
```

gibi bir kullanım varsa bu ID güvenilir kabul edilmemelidir.

Servis katmanı mevcut session kullanıcı kimliğini doğrulamalıdır.

UI'dan gelen kullanıcı ID'si ile başka hesabın notification kayıtlarına erişim engellenmelidir.

---

# 8. Bildirim Merkezi UI

Bildirim Merkezi tüm uygun kullanıcı workspace'lerinde erişilebilir olmalıdır.

Tercihen:

* Navbar üzerinde bell icon
* okunmamış badge
* Bildirim Merkezi ekranı

kullanılmalıdır.

Mevcut navbar/sidebar yapısı varsa onun tasarım dili kullanılmalıdır.

Yeni ve bağımsız bir navigation sistemi oluşturulmamalıdır.

---

# 9. Notification List

Liste aşağıdaki bilgileri gösterebilir:

* notification icon/type
* başlık
* kısa açıklama
* tarih/saat
* okunmamış durumu

Okunmamış bildirimler görsel olarak ayırt edilmelidir.

Örneğin:

* farklı background
* küçük unread indicator
* bold title

kullanılabilir.

Ancak mevcut UI tasarım sistemiyle uyumlu olmalıdır.

---

# 10. Bildirim Detayı

Bir notification tıklandığında:

1. notification `read` durumuna geçirilir.
2. Eğer `reference_type` + `reference_id` varsa ilgili ekrana yönlendirilir.
3. Referans artık mevcut değilse uygulama crash olmamalıdır.
4. Kullanıcı uygun olmayan bir hedefe yönlendirilmemelidir.

Örneğin:

```text
announcement → AnnouncementDetail
document → DocumentDetail
```

gibi navigation mapping oluşturulabilir.

---

# 11. Okundu / Okunmadı

Desteklenecek işlemler:

### Tek bildirim

* Açıldığında otomatik olarak read olabilir.
* Kullanıcı tekrar unread yapabiliyorsa mevcut tasarıma göre desteklenebilir.

### Tüm bildirimler

Bir:

> Tümünü okundu olarak işaretle

işlemi bulunmalıdır.

İşlem sadece mevcut kullanıcının notification kayıtlarını etkilemelidir.

---

# 12. Unread Badge

Navbar/sidebar notification icon üzerinde okunmamış bildirim sayısı gösterilmelidir.

Örnek:

```text
🔔 3
```

Sayı:

* session değişiminde
* notification oluşturulduğunda
* notification okunduğunda
* mark all read sonrasında

güncellenmelidir.

Aşırı database query oluşturacak bir yapı kurulmasından kaçınılmalıdır.

---

# 13. Notification Event Integration

Mevcut uygulamadaki gerçek event noktaları bulunarak notification üretimi merkezi şekilde bağlanmalıdır.

Minimum hedef:

### Announcement

Bir duyuru yayınlandığında hedef kullanıcılar için notification üretilebilmesi.

### Document

Bir belge ilgili kullanıcıların erişimine açıldığında notification üretilebilmesi.

### Parent

Çocuğu ilgilendiren gerçekten gerekli bir event varsa parent notification oluşturulabilmesi.

---

# 14. Duplicate Notification Protection

Aynı event tekrar çalıştırıldığında aynı notification'ın tekrar tekrar oluşturulması engellenmelidir.

Özellikle:

* JSON import
* sync
* publish işleminin tekrar çağrılması
* ekranın yeniden açılması

gibi durumlarda duplicate notification oluşmamalıdır.

Mümkünse:

```text
event_type + reference_type + reference_id + user_id
```

benzeri bir idempotency yaklaşımı kullanılmalıdır.

Mevcut database mimarisine uygun daha iyi bir yöntem varsa audit sonucuna göre kullanılmalıdır.

---

# 15. JSON Sync

Notification kayıtları mevcut `DatabaseSyncService` ile uyumlu hale getirilmelidir.

Schema değişirse:

* database version artırılmalı
* migration yazılmalı
* JSON export/import güncellenmeli
* eski veriler korunmalı

Import sırasında duplicate notification oluşturulmamalıdır.

---

# 16. Localization

TR ve EN desteklenmelidir.

Yeni localization key'leri:

* Bildirimler
* Bildirim Merkezi
* Okunmamış
* Tümünü okundu işaretle
* Yeni duyuru
* Yeni belge
* Bildirim bulunamadı
* Tüm bildirimler okundu
* vb.

Mevcut localization mimarisi kullanılmalıdır.

Hardcoded Türkçe/İngilizce metin bırakılmamalıdır.

---

# 17. Responsive Design

Notification Center:

* desktop
* tablet
* mobile

ekranlarda düzgün çalışmalıdır.

Desktop:

* navbar notification icon
* geniş notification list

Mobile:

* dar ekran listesi
* taşma olmaması
* uzun başlıkların düzgün kırılması
* touch-friendly item yüksekliği

kontrol edilmelidir.

---

# 18. Authorization

`AuthorizationService` mevcut yapısı kullanılmalıdır.

Notification için temel kurallar:

```text
Kullanıcı → kendi notification kayıtlarını görebilir
Kullanıcı → kendi notification kayıtlarını read yapabilir
Kullanıcı → başka kullanıcının notification kayıtlarını göremez
```

Notification oluşturma yetkisi ile notification görüntüleme yetkisi birbirinden ayrılmalıdır.

Bir kullanıcının notification görme yetkisine sahip olması, istediği kişiye notification oluşturabileceği anlamına gelmemelidir.

---

# 19. Testler

Yeni test dosyası:

```text
test/notifications_faz8_test.dart
```

veya mevcut test organizasyonuna uygun isim kullanılmalıdır.

Minimum testler:

### Notification creation

* notification oluşturulabiliyor.

### User isolation

* kullanıcı A → kendi notification'ını görebiliyor.
* kullanıcı B → kullanıcı A'nın notification'ını göremiyor.

### Unread

* yeni notification unread.
* unread count doğru.

### Mark read

* tek notification read oluyor.
* unread count azalıyor.

### Mark all read

* sadece mevcut kullanıcının notification'ları read oluyor.

### Reference navigation

* announcement reference doğru.
* document reference doğru.
* silinmiş/geçersiz reference crash oluşturmuyor.

### Duplicate protection

* aynı event tekrar işlendiğinde duplicate notification oluşmuyor.

### Role isolation

En azından:

* student
* parent
* secretary
* teacher

rollerinde notification izolasyonu test edilmelidir.

### Regression

Mevcut Faz 1–7 testleri bozulmamalıdır.

---

# 20. Flutter Test

Uygulama sonunda:

```bash
flutter test
```

çalıştırılmalıdır.

Beklenen:

```text
0 failed
```

Önceki baseline:

```text
145 passed / 0 failed
```

Yeni testler eklendikten sonra toplam test sayısı raporlanmalıdır.

---

# 21. Manuel Test

Aşağıdaki senaryolar manuel olarak kontrol edilmelidir:

### Senaryo 1

Sekreter login olur.

Notification Center açılır.

Kendi bildirimleri görünür.

### Senaryo 2

Öğrenci login olur.

Sadece kendi notification kayıtlarını görür.

### Senaryo 3

Veli login olur.

Sadece kendi hesabına ait notification kayıtlarını görür.

### Senaryo 4

Yeni duyuru yayınlanır.

İlgili kullanıcı için notification oluşur.

### Senaryo 5

Notification açılır.

Read durumuna geçer.

### Senaryo 6

Birden fazla unread notification vardır.

" Tümünü okundu olarak işaretle " çalışır.

### Senaryo 7

Başka kullanıcı ID'si ile notification erişimi denenir.

Erişim engellenir.

### Senaryo 8

Aynı event tekrar tetiklenir.

Duplicate notification oluşmaz.

### Senaryo 9

Desktop ve mobile layout kontrol edilir.

### Senaryo 10

TR/EN dil değişimi kontrol edilir.

### Senaryo 11

Faz 2–7 ana akışları tekrar kontrol edilir.

---

# 22. Kapsam Dışı

Bu fazda aşağıdakiler yapılmayacaktır:

* Firebase Push Notification
* FCM
* SMS
* E-mail notification
* WhatsApp notification
* harici notification provider
* notification preferences sistemi
* karmaşık notification scheduling
* cron/background worker
* notification analytics

Bunlar ileride ayrı bir faz olabilir.

---

# 23. Kod Kalitesi Kuralları

* Mevcut mimari korunacak.
* Duplicate service/model/table oluşturulmayacak.
* Mevcut `AppRole`, `AppState`, `AuthorizationService`, `AppDatabase`, `DatabaseSyncService` kullanılacak.
* Gereksiz refactor yapılmayacak.
* Mevcut Faz 1–7 davranışları bozulmayacak.
* UI'da business logic biriktirilmeyecek.
* Authorization yalnızca UI'a bırakılmayacak.
* User/session isolation service/database seviyesinde korunacak.
* Migration gerekiyorsa schema version doğru artırılacak.
* TR/EN localization eksiksiz yapılacak.
* Responsive tasarım korunacak.

---

# 24. Final Status Raporu

Uygulama sonunda:

```text
FAZ 8 — Final Status
```

başlığı altında aşağıdakiler raporlanmalıdır:

* Summary
* Audit sonucu
* Database
* Notification Model
* Notification Service
* Event Integration
* Navigation
* UI
* Unread Badge
* Authorization
* User Isolation / IDOR
* Duplicate Protection
* Responsive
* Localization
* JSON Sync
* Tests
* Manual Test
* Risks
* Remaining Work
* Next Phase Recommendation

Ayrıca:

```text
flutter test
```

sonucu açıkça belirtilmelidir.

Örneğin:

```text
145 → XXX passed / 0 failed
```

şeklinde gerçek sonuç yazılmalıdır.

**Gerçek test sonucu alınmadan PASS denmemelidir.**
