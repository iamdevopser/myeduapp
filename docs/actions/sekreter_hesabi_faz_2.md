# MyEduApp — SEKRETER HESABI

# FAZ 2 — Navigasyon + Öğrenci/Sınıf Yönetimi

## Amaç

Faz 1'de oluşturulan:

* `AppRole`
* `AppState.currentRole`
* `SecretaryTabWorkspace`
* `SecretaryHomeScreen`
* Sekreter `AppShell` branch'i
* `SecretaryNavSection`
* `AuthorizationService` iskeleti

üzerine gerçek Sekreter panelinin ilk kullanılabilir modüllerini ekle.

Bu fazın kapsamı:

1. Sekreter sidebar'ının gerçek yapısının oluşturulması
2. Sekreter ana dashboard'unun oluşturulması
3. Öğrenci yönetimi
4. Sınıf / şube yönetimi
5. Bu modüllerin Sekreter rolüne güvenli şekilde bağlanması

Bu fazda diğer Sekreter modüllerini geliştirme.

---

# 1. Önce mevcut kodu incele

Kodlamaya başlamadan önce özellikle şunları tekrar incele:

* `AppState`
* `AppRole`
* `SecretaryTabWorkspace`
* `SecretaryNavSection`
* `SecretaryNavigation`
* `AppShell`
* `StudentPlatformScreen`
* `StudentReportScreen`
* `AppDatabase`
* öğrenci ile ilgili model/helper/service sınıfları
* `ogrenciler` tablosu
* `ogrenci_siniflar` tablosu
* mevcut öğrenci ekleme/düzenleme/silme işlemleri

Özellikle `StudentPlatformScreen` içindeki öğrenci CRUD mantığını tespit et.

Mevcut çalışan öğrenci ekranını kopyalayıp ikinci bir büyük ekran oluşturma.

---

# 2. Sekreter Sidebar

Sekreter sidebar'ını aşağıdaki yapıya getir:

```text
Ana Sayfa

Öğrenciler
    Öğrenci Listesi
    Öğrenci Ekle

Sınıflar ve Şubeler
    Sınıflar
    Şubeler

Profilim
```

Şimdilik sidebar'a aşağıdakileri ekleme:

* Veliler
* Öğretmenler
* Ders Programları
* Devamsızlık
* Duyurular
* Belgeler
* Raporlar
* Bildirimler

Bunlar sonraki fazlarda eklenecek.

### Önemli

Sidebar:

* Desktop
* Tablet
* Mobile drawer

üzerinde mevcut `AppShell` mimarisini kullanmalı.

Teacher ve Student sidebar'larına zarar verme.

---

# 3. Secretary Dashboard

Mevcut `SecretaryHomeScreen` placeholder'ını gerçek dashboard'a dönüştür.

Dashboard'da mümkün olduğunca mevcut database sorgularını kullanarak:

### Özet kartları

* Toplam öğrenci
* Toplam sınıf/şube
* Bugünkü tarih

İleride eklenecek modüller için boş/uydurma veri oluşturma.

Örneğin henüz veli sistemi yoksa:

```text
Veli sayısı: 0
```

gibi sahte istatistik gösterme.

---

# 4. Öğrenci Listesi

Sekreter:

```text
Öğrenciler
    → Öğrenci Listesi
```

ekranına gidebilmeli.

Mevcut `StudentPlatformScreen` içindeki veri erişim mantığını yeniden kullan.

Ancak öğretmen ekranının tamamını Sekreter'e açma.

Sekreter ekranında öncelikle:

* Öğrenci adı
* Öğrenci numarası varsa
* Sınıf
* Şube
* Durum

gibi temel bilgiler gösterilsin.

### Arama

Öğrenci adı üzerinden arama yapılabilmeli.

### Filtre

En az:

* Sınıf
* Şube

filtreleri mevcut veriye göre çalışmalı.

---

# 5. Öğrenci Ekle

Sekreter:

```text
Öğrenciler
    → Öğrenci Ekle
```

ile öğrenci oluşturabilmeli.

Mevcut öğrenci ekleme formu varsa onu yeniden kullan.

Yeni bir duplicate form oluşturma.

Form mevcut öğrenci modelinin gerektirdiği alanlarla uyumlu olmalı.

Başarılı kayıt sonrasında:

* database güncellenmeli
* liste yenilenmeli
* kullanıcıya başarı mesajı gösterilmeli

---

# 6. Öğrenci Düzenle

Sekreter mevcut öğrencinin temel bilgilerini düzenleyebilmeli.

Mevcut edit formu varsa yeniden kullan.

Özellikle:

* isim
* öğrenci numarası
* sınıf
* şube
* mevcut öğrenci alanları

gibi alanların mevcut modeldeki karşılığını kullan.

---

# 7. Öğrenci Silme

Bu fazda doğrudan öğrenci silme işlemini otomatik olarak aktif etme.

Audit'teki karar:

```text
Öğrenci silme = APPROVAL REQUIRED
```

olduğu için:

* Eğer mevcut sistemde gerçek approval mekanizması yoksa
* Sekreter için "Sil" işlemini göstermeme veya disabled bırakma.

Sahte approval sistemi oluşturma.

Sonraki fazda gerçek onay mekanizması ayrıca ele alınacak.

---

# 8. Sınıflar ve Şubeler

Mevcut:

```text
ogrenci_siniflar
```

yapısını incele.

Sekreter için:

### Sınıflar

Örneğin:

```text
5. Sınıf
6. Sınıf
7. Sınıf
8. Sınıf
```

gibi mevcut veri yapısını kullanarak listeleme yap.

### Şubeler

Örneğin:

```text
7A
7B
7C
8A
8B
```

gibi mevcut kayıtları göster.

Her şubede:

* Öğrenci sayısı
* Şube adı
* Sınıf bilgisi

görülebilir.

---

# 9. Sınıf/Şube veri modelini değiştirme

Bu fazda mevcut database yapısını mümkün olduğunca kullan.

Yeni tablo oluşturma.

Yeni migration yapma.

Ancak mevcut yapı sınıf/şube işlemini desteklemiyorsa bunu raporla ve gerekli minimum değişikliği gerekçelendir.

Varsayım yaparak yeni database modeli oluşturma.

---

# 10. Öğrenci ve sınıf verilerine erişim

Sekreter ekranlarının doğrudan rastgele `AppDatabase` çağrılarıyla dağılmasını önle.

Mevcut projede repository/service pattern varsa onu kullan.

Yoksa bu fazda tüm database mimarisini yeniden tasarlama.

Ancak en azından Sekreter UI ile database erişimini düzenli tut.

`AuthorizationService` iskeletini kullanmaya uygun bir yapı bırak.

---

# 11. Yetki ayrımı

Sekreter:

### İZİNLİ

* Öğrenci listeleme
* Öğrenci arama
* Öğrenci filtreleme
* Öğrenci ekleme
* Öğrenci düzenleme
* Sınıf görüntüleme
* Şube görüntüleme

### İZİNSİZ

* Not değiştirme
* Sınav işlemleri
* Akademik plan düzenleme
* Soru bankası
* Mentorluk
* Öğretmen ayarları
* Sistem ayarları
* Rol değiştirme
* Öğrenci silme

Özellikle Sekreter kullanıcıyı mevcut Teacher ekranlarına yönlendiren navigation yolları bırakma.

---

# 12. AuthorizationService

Faz 1'de oluşturulan:

```text
AuthorizationService
```

iskeletini bu fazda mümkün olduğunca gerçek kullanım için hazırlayabilirsin.

Örneğin:

```text
canViewStudents
canCreateStudent
canEditStudent
canDeleteStudent
canViewClasses
```

gibi capability mantığı oluşturulabilir.

Ancak bütün uygulamanın permission sistemini bu fazda yeniden yazma.

Sadece bu fazın kapsamındaki yetkiler için temel oluştur.

---

# 13. Teacher / Student regression

Aşağıdaki mevcut davranışları koru:

### Teacher

* Login
* Teacher workspace
* Sidebar
* Academic Plans
* Lesson Platform
* Student Platform

### Student

* Login
* Student workspace
* Student sidebar
* Student portal

Sekreter için yapılan değişiklikler bu rolleri etkilememeli.

---

# 14. Responsive

Sekreter ekranlarının tamamı:

* Desktop
* Tablet
* Mobile

üzerinde mevcut Flutter responsive mimarisine uygun olmalı.

Özellikle öğrenci tablosu mobilde taşma yapmamalı.

Gerekirse:

* responsive card
* horizontal scroll
* compact list

gibi mevcut proje patternlerinden uygun olanı kullan.

---

# 15. Testler

Aşağıdaki testleri ekle/güncelle:

### Role

* Secretary login → Secretary workspace

### Navigation

* Secretary → Öğrenci Listesi
* Secretary → Öğrenci Ekle
* Secretary → Sınıflar
* Secretary → Şubeler

### Authorization

Sekreterin Teacher-only ekranlarına erişemediğini test et.

### Student

* öğrenci listeleme
* öğrenci ekleme
* öğrenci düzenleme

### Regression

* mevcut Teacher testleri
* mevcut Student testleri

çalıştırılmalı.

---

# 16. Test komutu

Sonunda:

```bash
flutter test
```

çalıştır.

Mevcut tüm testlerin geçmesini sağla.

Yeni testleri ayrıca raporla.

---

# 17. Bu fazda yapılmayacaklar

Kesinlikle geliştirme:

* Veli sistemi
* Veli-öğrenci ilişkisi
* Öğretmen yönetimi
* Devamsızlık
* Duyurular
* Belgeler
* Raporlar
* Bildirimler
* Academic Plans değişikliği
* Weekly Schedule değişikliği
* Öğrenci silme approval sistemi
* Tam database authorization katmanı
* Database encryption
* Cloud authentication

---

# 18. Faz sonunda rapor

Şu formatta rapor oluştur:

## FAZ 2 STATUS

```text
PASS / PARTIAL / BLOCKED
```

### Yapılanlar

* Sidebar
* Dashboard
* Student List
* Student Create
* Student Edit
* Classes
* Sections
* Authorization
* Responsive

### Değiştirilen dosyalar

Eklenen ve güncellenen dosyaları listele.

### Test sonucu

```text
flutter test
X passed
Y failed
```

### Manuel test gerektirenler

Varsa açıkça belirt.

### Riskler

Varsa belirt.

### Sonraki Faz

Faz 3 için öneriyi kısa şekilde yaz.

---

## KRİTİK KURAL

Mevcut Teacher ve Student ekranlarını kopyalayarak ayrı bir Sekreter uygulaması oluşturma.

Amaç:

**aynı business logic + farklı role-specific navigation/UI**

oluşturmaktır.

Mevcut çalışan kodu gereksiz yere yeniden yazma.

Önce kodu oku, sonra minimum gerekli değişikliği yap.
