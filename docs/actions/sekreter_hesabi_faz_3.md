# MYEDUAPP — FAZ 3
# Veli Yönetimi ve Öğrenci–Veli İlişkisi

## 1. FAZIN AMACI

MyEduApp'te Sekreter hesabı için veli yönetimi ve öğrenci–veli ilişkisinin kurulması.

Bu fazda amaç:

- Veli kayıtlarının yönetilmesi
- Öğrenci ile veli arasındaki ilişkinin kurulması
- Sekreterin veli bilgilerini görüntüleyebilmesi
- Veli bilgilerinin eklenebilmesi ve düzenlenebilmesi
- Öğrenci profilinden bağlı velilerin görülebilmesi
- Veli profilinden bağlı öğrencilerin görülebilmesi

Bu faz, mevcut Faz 1 + Faz 2 + Faz 2.5 mimarisinin üzerine kurulmalıdır.

ÖNEMLİ:

Faz 2.5'te tespit edilen ancak şu anda düzeltilmesine karar verilmeyen öğrenci login eksiklerine bu fazda geri dönme.

Özellikle:
- global öğrenci şifresi,
- aynı öğrenci numarası,
- öğrenci login akışındaki diğer bilinen küçük eksikler

bu fazın konusu değildir.

---

# 2. ÖNCE ANALİZ — KODLAMAYA HEMEN BAŞLAMA

Kodlamaya başlamadan önce mevcut veli/öğrenci veri yapısını kapsamlı şekilde incele.

Özellikle aşağıdakileri bul:

- `ogrenciler` tablosu
- `anne_email`
- `baba_email`
- anne/baba ile ilgili diğer alanlar
- öğrenci modelleri
- öğrenci servisleri
- `SecretaryStudentService`
- `AppDatabase`
- mevcut öğrenci profil ekranları
- mevcut öğrenci düzenleme dialogu
- mevcut öğrenci detay ekranları
- `AuthorizationService`
- `AppRole`
- `AppState`
- Secretary sidebar/navigation
- localization sistemi
- migration/schema version
- database sync/backup yapısı

Ayrıca kod tabanında şu kelimeleri ara:

- veli
- parent
- anne
- baba
- guardian
- parent_email
- anne_email
- baba_email
- telefon
- veli_telefon
- parent_id

Amaç mevcut sistemde zaten kullanılmakta olan bir veli altyapısı olup olmadığını tespit etmektir.

---

# 3. ÇOK ÖNEMLİ — MEVCUT VERİYİ KORU

Mevcut `ogrenciler` tablosunda anne/baba bilgileri bulunuyorsa bunları doğrudan silme veya anlamsızlaştırma.

Örneğin:

`anne_email`
`baba_email`

gibi mevcut alanların ne amaçla kullanıldığını analiz et.

Eğer mevcut alanlar veli yönetimi için yetersizse yeni bir veri modeli oluşturulabilir.

Ancak:

> Mevcut alanları kontrol etmeden doğrudan yeni bir `veliler` tablosu oluşturma.

Önce analiz sonucunda neden yeni tablo/model gerektiğini raporla.

---

# 4. HEDEF VERİ MODELİ

İdeal yapı aşağıdaki mantığı desteklemelidir:

```text
Veli
 ├── id
 ├── ad_soyad
 ├── telefon
 ├── email
 ├── adres / gerekli iletişim bilgileri
 └── not / açıklama gerekiyorsa

Öğrenci
 └── Veli ilişkisi

İlişki
 ├── öğrenci_id
 ├── veli_id
 ├── yakınlık türü
 └── gerekiyorsa birincil veli bilgisi
```

Ancak bu yapıyı birebir uygulamak zorunda değilsin.

Mevcut database mimarisine en uygun çözümü kullan.

Özellikle bir velinin birden fazla öğrencisi olabileceğini destekle.

Örneğin:

```text
Anne Ayşe
   ├── Öğrenci A
   └── Öğrenci B
```

ve:

```text
Öğrenci A
   ├── Anne
   └── Baba
```

gibi ilişkiler mümkün olmalıdır.

---

# 5. VERİ MODELİ TASARIMI

Aşağıdaki sorulara analiz sonucunda cevap ver:

1. Bir öğrenci kaç veliye sahip olabilir?
2. Bir veli kaç öğrenciye bağlanabilir?
3. Anne/baba ilişkisi ayrı tutulmalı mı?
4. "Veli" bir kişi olarak mı modellenmeli?
5. Aynı kişinin iki öğrencinin velisi olması nasıl tutulmalı?
6. Birincil iletişim kişisi nasıl belirlenmeli?
7. E-posta ve telefon benzersiz olmak zorunda mı?
8. Mevcut `anne_email` / `baba_email` alanları yeni modele nasıl aktarılacak?

En uygun tasarımı seç.

Gereksiz karmaşık bir CRM sistemi oluşturma.

---

# 6. DATABASE / MIGRATION

Yeni tablo veya alan gerekiyorsa kontrollü migration yap.

Mevcut schema version'ı tespit et.

Yeni migration gerekiyorsa:

1. Mevcut schema version'ı artır.
2. Migration kodunu ekle.
3. Mevcut öğrenci verilerini koru.
4. Mevcut anne/baba email verilerini mümkünse kaybetmeden yeni yapıya aktar.
5. Migration sonrası eski öğrenci özelliklerinin çalıştığını doğrula.
6. Test DB üzerinde migration test et.

Önemli:

Mevcut veriler migration sırasında silinmemeli.

---

# 7. SEKRETER SIDEBAR

Faz 2'deki Secretary sidebar yapısını kullan.

Mevcut:

```text
Ana Sayfa

Öğrenciler
  ├── Öğrenci Listesi
  └── Öğrenci Ekle

Sınıflar ve Şubeler
  ├── Sınıflar
  └── Şubeler

Profilim
```

yapısına:

```text
Veliler
  ├── Veli Listesi
  └── Veli Ekle
```

ekle.

Mevcut navigation/state yapısını yeniden yazma.

---

# 8. VELİ LİSTESİ

Yeni bir Secretary Veli Listesi ekranı oluştur.

Liste en az şunları göstermeli:

- Veli adı soyadı
- Telefon
- E-posta
- Bağlı öğrenci sayısı

Mümkünse bağlı öğrencilerin adları da detay görünümünde gösterilebilir.

Arama:

- veli adı
- e-posta
- telefon

üzerinden yapılabilmeli.

Filtre gerekiyorsa mevcut öğrenci/sınıf ilişkisine uygun şekilde eklenebilir.

Liste:

- Desktop'ta tablo
- Mobile'da kart/list item

olarak responsive çalışmalı.

---

# 9. VELİ EKLE

Sekreter:

`Veliler → Veli Ekle`

ekranından yeni veli oluşturabilmeli.

Minimum alanlar:

- Ad Soyad
- Telefon
- E-posta

Gerekiyorsa:

- yakınlık türü
- adres
- açıklama

alanları eklenebilir.

Form:

- validation
- boş alan kontrolü
- e-posta formatı
- telefon formatı
- kullanıcı dostu hata mesajları

içermeli.

Gereksiz alan ekleme.

---

# 10. VELİ DÜZENLE

Sekreter mevcut veli kaydını düzenleyebilmeli.

Örneğin:

- ad soyad
- telefon
- e-posta
- iletişim bilgileri

güncellenebilmeli.

Mevcut öğrenci düzenleme dialogunda Faz 2'de yapılan ortaklaştırma yaklaşımını dikkate al.

Ancak veli düzenleme için gereksiz yere karmaşık dialog sistemi oluşturma.

---

# 11. VELİ SİLME

Bu fazda veli silme işlemi konusunda dikkatli davran.

Önce bağlı öğrencileri kontrol et.

Bağlı öğrencisi olan bir veli doğrudan silinmemeli.

Minimum güvenli yaklaşım:

- bağlı veli için silme işlemini engelle,
- kullanıcıya bağlı öğrencileri göster,
- ilişki kaldırılmadan silmeye izin verme.

Eğer mevcut sistemde güvenli bir soft-delete yaklaşımı zaten varsa onu kullan.

Öğrenci silme approval sistemi bu fazda yapılmayacaktır.

---

# 12. ÖĞRENCİ ↔ VELİ EŞLEŞTİRME

Bu fazın en önemli özelliğidir.

Sekreter bir öğrenci için veli ilişkilendirebilmeli.

Örneğin:

```text
Öğrenci:
Sofia Albu

Veliler:
[ + Veli Ekle ]

Anne:
Ayşe Albu

Baba:
Mehmet Albu
```

veya veri modeli daha uygunsa:

```text
Veliler
- Ayşe Albu — Anne
- Mehmet Albu — Baba
```

İlişki ekleme:

1. Mevcut veli seç
2. Yakınlık türü seç
3. Kaydet

Yeni veli gerekiyorsa aynı akış içinde veli oluşturma seçeneği olabilir.

Ancak duplicate veli kayıtlarının oluşmasına dikkat et.

---

# 13. VELİ → ÖĞRENCİLER

Veli detay ekranında:

```text
Veli:
Ayşe Albu

Bağlı öğrenciler:
- Sofia Albu — 7A
- Mihai Albu — 5B
```

gibi bilgiler gösterilebilmeli.

Bu ekranın amacı yalnızca ilişkiyi görüntülemek ve yönetmektir.

Bu fazda veli hesabı/login sistemi oluşturma.

---

# 14. ÖĞRENCİ → VELİLER

Öğrenci detayında veya öğrenci düzenleme/detay ekranında:

```text
Veliler

Ayşe Albu
Anne
telefon
email

Mehmet Albu
Baba
telefon
email
```

görülebilmeli.

Sekreter için düzenleme yetkisi olabilir.

Öğrenci hesabının bu fazda veli bilgilerine erişim yetkisini değiştirme.

Öğrenci portalına yeni veli özellikleri ekleme.

---

# 15. AUTHORIZATION

`AuthorizationService` genişletilebilir.

Gerekli minimum yetkiler:

- `canViewParents`
- `canCreateParent`
- `canEditParent`
- `canDeleteParent`
- `canManageStudentParentRelation`

Ancak mevcut authorization mimarisine uygun isimleri tercih et.

Sekreter:

- veli görüntüleme: ALLOWED
- veli oluşturma: ALLOWED
- veli düzenleme: ALLOWED
- veli–öğrenci ilişkilendirme: ALLOWED
- bağlı veli silme: DENIED
- sistem/rol değişiklikleri: DENIED

Teacher ve Student rollerinin mevcut davranışlarını gereksiz yere değiştirme.

---

# 16. DUPLICATE KONTROLÜ

Aynı kişinin tekrar tekrar veli olarak oluşturulmasını mümkün olduğunca engelle.

Ancak:

- e-posta zorunlu olmayabilir,
- telefon zorunlu olmayabilir,
- aynı telefon numarasını aile içinde paylaşmak mümkün olabilir.

Bu nedenle yalnızca email/telefon üzerinden agresif unique constraint koyma.

Gerekirse:

- ad + telefon
- ad + email

gibi soft duplicate uyarısı kullanılabilir.

Ama kullanıcıyı gereksiz yere kilitleme.

---

# 17. RESPONSIVE

Desktop/Web:

- sidebar sabit çalışmalı,
- veli listesi tablo olarak kullanılabilir,
- detay alanları yeterli genişlikte olmalı.

Mobile:

- kart/list görünümü,
- form alanları ekran genişliğine uyumlu,
- yatay taşma olmamalı,
- ilişki yönetimi kullanılabilir olmalı.

Faz 2'deki `AppSpacing.phoneBreakpoint` yaklaşımını kullan.

---

# 18. LOCALIZATION

Yeni kullanıcıya görünen metinleri mevcut localization sistemine ekle.

Örneğin:

- Veliler
- Veli Listesi
- Veli Ekle
- Veli Düzenle
- Bağlı Öğrenciler
- Veli Ekle
- Anne
- Baba
- Diğer
- Veli bulunamadı
- Bu velinin bağlı öğrencileri var

Hard-coded kullanıcı metinlerini mümkün olduğunca bırakma.

---

# 19. TESTLER

En az aşağıdaki testleri ekle:

### Veri

1. Veli oluşturma
2. Veli güncelleme
3. Veli listeleme
4. Öğrenci–veli ilişkisi oluşturma
5. Öğrenci–veli ilişkisi kaldırma
6. Veli → öğrenciler sorgusu
7. Öğrenci → veliler sorgusu
8. Bağlı veli silme engeli

### Authorization

9. Secretary veli görebilir.
10. Secretary veli oluşturabilir.
11. Secretary veli düzenleyebilir.
12. Secretary öğrenci–veli ilişkisi yönetebilir.
13. Bağlı veli silinemez.

### Regression

14. Teacher login çalışıyor.
15. Student login çalışıyor.
16. Secretary login çalışıyor.
17. Faz 2 Secretary student işlemleri çalışıyor.
18. Faz 2.5 student session/login testleri çalışıyor.

---

# 20. DATABASE TESTLERİ

Migration eklenmişse migration testi oluştur.

Özellikle:

- mevcut öğrenciler kaybolmamalı,
- mevcut `anne_email` / `baba_email` bilgileri korunmalı,
- mevcut öğrenci login sistemi çalışmalı,
- Faz 2 öğrenci CRUD çalışmalı.

---

# 21. BU FAZDA YAPILMAYACAKLAR

Kesinlikle aşağıdakileri bu faza dahil etme:

- Öğretmen yönetimi
- Devamsızlık
- Duyurular
- Belgeler
- Raporlar
- Bildirimler
- Academic Plans
- Weekly Schedule
- Öğrenci silme approval
- Öğretmen şifreleri
- Öğretmen yetki sistemi
- Veli login hesabı
- Veli portalı
- SMS/e-posta gönderimi
- Firebase
- Cloud authentication
- JWT/OAuth
- Büyük UI redesign
- Faz 2.5 öğrenci login sorunlarının yeniden ele alınması

Bu faz yalnızca:

> Veli kayıtları + Öğrenci–Veli ilişkileri

içindir.

---

# 22. KOD KALİTESİ

- Mevcut Flutter architecture'ı takip et.
- Duplicate model oluşturma.
- Duplicate DB helper oluşturma.
- Mevcut service/repository yaklaşımını kullan.
- SQL'i UI içine koyma.
- Migration mantığını `AppDatabase` yapısına uygun uygula.
- Null safety'yi koru.
- Localization kullan.
- Responsive yapıyı koru.
- Teacher/Student davranışlarını gereksiz yere değiştirme.

---

# 23. TAMAMLAMA KRİTERLERİ

Faz ancak aşağıdakiler sağlandığında PASS kabul edilecektir:

### Veli

- [ ] Veli oluşturulabiliyor.
- [ ] Veli listelenebiliyor.
- [ ] Veli aranabiliyor.
- [ ] Veli düzenlenebiliyor.
- [ ] Bağlı veli doğrudan silinemiyor.

### İlişki

- [ ] Öğrenciye veli bağlanabiliyor.
- [ ] Öğrenciye birden fazla veli bağlanabiliyor.
- [ ] Bir veli birden fazla öğrenciye bağlanabiliyor.
- [ ] İlişki kaldırılabiliyor.
- [ ] Öğrenci detayında veliler görülebiliyor.
- [ ] Veli detayında öğrenciler görülebiliyor.

### Secretary

- [ ] Sidebar'a Veliler bölümü eklendi.
- [ ] Veli Listesi çalışıyor.
- [ ] Veli Ekle çalışıyor.
- [ ] Veli düzenleme çalışıyor.
- [ ] Yetkiler uygulanıyor.

### Database

- [ ] Migration gerekiyorsa uygulanmış.
- [ ] Mevcut öğrenci verileri korunmuş.
- [ ] Mevcut anne/baba bilgileri kaybolmamış.

### Responsive

- [ ] Desktop/Web çalışıyor.
- [ ] Mobile çalışıyor.
- [ ] Yatay taşma yok.

### Regression

- [ ] Teacher login çalışıyor.
- [ ] Student login çalışıyor.
- [ ] Secretary login çalışıyor.
- [ ] Faz 2 çalışıyor.
- [ ] Faz 2.5 çalışıyor.

### Tests

`flutter test`

çalıştırılmalı.

---

# 24. SON RAPOR FORMATI

Çalışma sonunda:

## FAZ 3 STATUS

PASS / FAIL / PARTIAL

### Ön Analiz
- Mevcut veli yapısı:
- `anne_email` / `baba_email` kullanımı:
- Mevcut model:
- Yeni model neden gerekli/gereksiz:
- İlişki modeli:

### Yapılanlar
- ...

### Database / Migration
- ...

### Veli Yönetimi
- ...

### Öğrenci–Veli İlişkisi
- ...

### Authorization
- ...

### Responsive
- ...

### Değiştirilen / eklenen dosyalar
- ...

### Test sonucu

flutter test

X passed
Y failed

### Manuel test gerektirenler
- ...

### Riskler
- ...

### Faz 4'e kalanlar
- ...

Özellikle mevcut `anne_email` / `baba_email` alanlarının nasıl ele alındığını açıkça raporla.

---

# SON TALİMAT

Önce mevcut veri modelini ve kodu analiz et.

Mevcut veli/anne/baba yapısını anlamadan yeni tablo oluşturma.

Sonra minimum ve sürdürülebilir veri modelini uygula.

Mevcut öğrenci verilerini koru.

Sonra UI, authorization ve testleri ekle.

En son `flutter test` çalıştır.

Faz kapsamı dışına çıkma.

Teacher, Student, Secretary ve Faz 2.5 öğrenci login/session akışlarını bozma.
