# MyEduApp — Sekreter Hesabı Audit ve Uygulama Planı

## Amaç

MyEduApp uygulamasına yeni bir **Sekreter (Secretary)** kullanıcı rolü eklenmesi planlanmaktadır.

Bu aşamada doğrudan kodlama yapma.

Önce mevcut MyEduApp kod tabanını kapsamlı şekilde analiz et ve Sekreter hesabının mevcut mimariye en doğru şekilde nasıl entegre edileceğini belirle.

Uygulama Flutter altyapısı kullanmaktadır.

---

# 1. Önce mevcut sistemi analiz et

Aşağıdaki alanları tek tek incele:

### Kullanıcı ve rol sistemi

* Kullanıcı modeli
* User / Account yapısı
* Role enum veya role tanımları
* Permission sistemi
* Authentication
* Authorization
* Role-based route/page kontrolü
* Kullanıcının rolüne göre gösterilen sidebar
* Kullanıcının rolüne göre gösterilen navbar
* Backend/API/Firebase erişim kontrolleri
* Firestore/Database security rules varsa bunlar

Mevcut rollerin tamamını tespit et.

Özellikle:

* Admin
* Yönetici
* Teacher / Öğretmen
* Student / Öğrenci
* Parent / Veli

gibi mevcut rollerin nasıl uygulandığını belirle.

---

# 2. Mevcut Sidebar mimarisini analiz et

MyEduApp'teki sidebar yapısını incele.

Şunları belirle:

* Sidebar hangi dosyalarda oluşturuluyor?
* Role göre menüler nasıl filtreleniyor?
* Ortak menüler nasıl tanımlanıyor?
* Submenu sistemi nasıl çalışıyor?
* Responsive/mobile sidebar nasıl çalışıyor?
* Navbar ile sidebar arasındaki ilişki nedir?
* Sayfa değişimlerinde sidebar/navbar sabit kalıyor mu?
* Mobil uygulamada sidebar yerine kullanılan navigation yapısı nedir?

Sekreter hesabının bu mimariye mevcut sistemi bozmadan nasıl eklenebileceğini tespit et.

---

# 3. Sekreter rolü için önerilen menü yapısını mevcut sistemle karşılaştır

Önerilen Sekreter menüsü:

```text
Ana Sayfa

Öğrenciler
    Öğrenci Listesi
    Öğrenci Ekle
    Öğrenci Belgeleri

Veliler
    Veli Listesi
    Veli-Öğrenci Eşleştirme

Öğretmenler
    Öğretmen Listesi
    Öğretmen Programları

Sınıflar ve Şubeler
    Sınıflar
    Şubeler
    Sınıf Mevcutları

Ders Programları
    Sınıf Programları
    Öğretmen Programları
    Günlük Program

Devamsızlık
    Günlük Devamsızlık
    Öğrenci Devamsızlıkları
    Raporlar

Duyurular
    Duyurular
    Yeni Duyuru

Belgeler
    Öğrenci Belgeleri
    Okul Belgeleri
    Evraklar

Raporlar
    Öğrenci Raporları
    Devamsızlık Raporları
    Personel Raporları

Bildirimler

Profilim
```

Bu menüleri körü körüne uygulama.

Önce mevcut uygulamada bunların karşılıklarını bul.

Her menü için:

* Mevcut sayfa var mı?
* Mevcut component var mı?
* Mevcut service/provider/repository var mı?
* Backend desteği var mı?
* Yeni sayfa gerekiyor mu?
* Mevcut sayfa yeniden kullanılabilir mi?
* Mevcut sayfanın yetkileri Sekreter için uygun mu?

tespit et.

---

# 4. Permission matrisi oluştur

Sekreter için aşağıdaki yetkileri mevcut sistemle karşılaştır:

| İşlem                                 | Sekreter           |
| ------------------------------------- | ------------------ |
| Öğrenci görüntüleme                   | ALLOWED            |
| Öğrenci ekleme                        | ALLOWED            |
| Öğrenci düzenleme                     | ALLOWED            |
| Öğrenci silme                         | ADMIN/ONAY GEREKLİ |
| Veli görüntüleme                      | ALLOWED            |
| Veli ekleme/düzenleme                 | ALLOWED            |
| Veli-öğrenci eşleştirme               | ALLOWED            |
| Öğretmen görüntüleme                  | ALLOWED            |
| Öğretmen düzenleme                    | SINIRLI            |
| Öğretmen akademik işlemleri           | DENIED             |
| Not değiştirme                        | DENIED             |
| Sınav yönetimi                        | DENIED             |
| Günlük/haftalık/yıllık öğretmen planı | DENIED             |
| Öğrenci devamsızlığı görüntüleme      | ALLOWED            |
| Devamsızlık yönetimi                  | ALLOWED            |
| Duyuru oluşturma                      | ALLOWED            |
| Belgeleri görüntüleme                 | ALLOWED            |
| Belgeleri yükleme                     | ALLOWED            |
| Kritik belgeleri silme                | ADMIN              |
| Rapor görüntüleme                     | ALLOWED            |
| Kullanıcı rolü değiştirme             | DENIED             |
| Sistem ayarları                       | DENIED             |
| Yönetici işlemleri                    | DENIED             |

Ancak mevcut permission mimarisini inceledikten sonra gerekirse bu matrisi mevcut sistemin terminolojisine uygun şekilde yeniden düzenle.

---

# 5. Veri erişim güvenliğini kontrol et

Önemli:

Sadece Flutter tarafında:

```dart
if (user.role == secretary)
```

kontrolü yapmak yeterli kabul edilmemeli.

Backend/API/Firestore/Database tarafında da Sekreter rolünün erişimleri kontrol edilmeli.

Şunları özellikle incele:

* Student collection/table erişimi
* Parent erişimi
* Teacher erişimi
* Attendance erişimi
* Announcement erişimi
* Documents erişimi
* Reports erişimi
* Admin-only işlemler

Sekreterin yetkisi olmayan bir veriye doğrudan API/backend üzerinden ulaşabilmesi mümkünse bunu raporda **CRITICAL** olarak belirt.

---

# 6. Web + Mobile yapısını birlikte analiz et

MyEduApp Flutter tabanlı olduğu için Sekreter hesabı yalnızca web ekranı olarak düşünülmemeli.

Mevcut:

* Desktop/Web
* Tablet
* Mobile

responsive davranışını incele.

Sekreter sidebar'ının:

* geniş ekran
* tablet
* telefon

üzerindeki davranışını belirle.

Yeni ekranlar mevcut responsive mimariyi kullanmalı.

Ayrı ayrı ve gereksiz duplicate ekranlar oluşturma.

---

# 7. Academic Plans ile ilişkisini kontrol et

MyEduApp'te mevcut:

```text
Academic Plans
    Weekly Schedule
    Daily Plans
    Annual Plans
    Documents
```

yapısını ayrıca kontrol et.

Sekreter hesabına bu menülerin hangilerinin:

* hiç gösterilmemesi,
* yalnızca görüntülenmesi,
* yönetilmesi

gerektiğini belirle.

Özellikle **Weekly Schedule** öğretmenin akademik planlama ekranı ile okulun genel ders programının birbirine karıştırılmamasına dikkat et.

---

# 8. Sonuç olarak bir AUDIT RAPORU oluştur

Analiz sonunda aşağıdaki formatta rapor oluştur:

## A. Mevcut Mimari

* Authentication
* Roles
* Permissions
* Sidebar
* Navbar
* Routing
* Backend authorization
* Database/security rules

## B. Mevcut Özellikler

Sekreter menüsündeki her özellik için:

| Özellik | Mevcut mu? | Yeniden kullanılabilir mi? | Eksik | Öneri |
| ------- | ---------- | -------------------------- | ----- | ----- |

## C. Sekreter Permission Matrisi

Açık şekilde:

* ALLOWED
* DENIED
* ADMIN ONLY
* APPROVAL REQUIRED

olarak belirt.

## D. Eksik Dosyalar / Modüller

Yeni oluşturulması gereken:

* Dart dosyaları
* Models
* Services
* Providers
* Repositories
* Screens
* Widgets
* Routes
* Permissions
* Backend functions
* Security rules

varsa listele.

## E. Riskler

Özellikle:

* Yetki açığı
* Veri sızıntısı
* Client-side-only authorization
* Yanlış role erişimi
* Mobile/Web uyumsuzluğu
* Duplicate code
* Mevcut öğretmen/yönetici ekranlarının bozulma riski

gibi konuları belirt.

Her risk için:

```text
Risk
Severity
Neden
Önerilen çözüm
```

formatını kullan.

---

# 9. Uygulama planı oluştur

Audit tamamlandıktan sonra Sekreter hesabını uygulamak için aşamalı plan çıkar.

Örneğin:

### Faz 1

Role ve permission altyapısı

### Faz 2

Sekreter authentication/authorization

### Faz 3

Sidebar/Navbar

### Faz 4

Öğrenci yönetimi

### Faz 5

Veli yönetimi

### Faz 6

Öğretmen ve sınıf yönetimi

### Faz 7

Ders programları

### Faz 8

Devamsızlık

### Faz 9

Duyurular ve belgeler

### Faz 10

Raporlar

### Faz 11

Responsive Web/Mobile

### Faz 12

Security ve test

Bu fazları mevcut kod tabanındaki gerçek durumlara göre değiştir.

Gereksiz faz oluşturma.

---

# 10. Bu aşamada kod yazma

Bu görev bir **AUDIT + IMPLEMENTATION PLAN** görevidir.

Henüz:

* Yeni screen oluşturma
* Yeni model oluşturma
* Sidebar kodunu değiştirme
* Database migration
* Permission kodu ekleme
* Backend kodu değiştirme

yapma.

Önce mevcut sistemi tamamen anla.

---

# 11. Çıktının sonunda kesin karar ver

Raporun sonunda şu bölümü oluştur:

## SEKRETER HESABI — UYGULAMA KARARI

Burada net olarak belirt:

1. Mevcut sistemde hangi yapılar kullanılabilir?
2. Hangi yapılar değiştirilmelidir?
3. Hangi yapılar yeni oluşturulmalıdır?
4. En düşük riskli uygulama sırası nedir?
5. Web ve mobile için hangi ortak mimari kullanılmalıdır?
6. Backend/security tarafında hangi değişiklikler zorunludur?
7. İlk kodlama fazı tam olarak ne olmalıdır?

Sonunda sonraki Cursor promptunun hazırlanabilmesi için **önerilen ilk fazın kapsamını net şekilde tanımla.**

## Önemli kurallar

* Mevcut çalışan özellikleri gereksiz yere yeniden yazma.
* Önce mevcut kodu keşfet.
* Duplicate yapı oluşturma.
* Mevcut role/permission mimarisi varsa onu mümkün olduğunca kullan.
* Sekreter rolünü öğretmen rolünün kopyası olarak oluşturma.
* UI yetkilendirmesini backend yetkilendirmesinin yerine koyma.
* Web ve mobile için mümkün olduğunca ortak business logic kullan.
* Mevcut Academic Plans yapısını bozma.
* Mevcut Öğretmen, Öğrenci ve Veli rollerinin davranışlarını değiştirme.
* Kodlamaya başlamadan önce audit raporunu tamamla.

# Nihai çıktı

Bana yalnızca:

1. **AUDIT RAPORU**
2. **SEKRETER PERMISSION MATRİSİ**
3. **EKSİKLER / RİSKLER**
4. **UYGULAMA FAZLARI**
5. **İLK KODLAMA FAZININ ÖNERİLEN KAPSAMI**

başlıkları altında sonuçları ver.

Kod değişikliği yapma.
