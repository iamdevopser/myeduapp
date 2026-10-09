# MYEDUAPP — FAZ 2.5
# Öğrenci Giriş ve Oturum Akışının Düzeltilmesi

## 1. FAZIN AMACI

MyEduApp'te mevcut öğrenci giriş akışı incelenecek ve düzeltilerek gerçek bir öğrenci hesabı mantığı oluşturulacaktır.

Mevcut durumda öğrenci hesabıyla giriş yapıldığında:
- Öğrenci giriş ekranında varsayılan öğrenci şifresi giriliyor.
- Ardından "Öğrenci profili seçin" ekranı açılıyor.
- Sistemde kayıtlı tüm öğrenciler listeleniyor.
- Kullanıcı buradan bir öğrenci seçebiliyor.
- Ekranın geri kalanında siyah arka plan görülüyor.

Bu yapı gerçek bir kullanıcı hesabı mantığı değildir ve güvenlik açısından kabul edilemez.

HEDEF:
> Öğrenci, kendisine ait giriş bilgileriyle sisteme giriş yapmalı ve giriş yaptıktan sonra yalnızca kendi öğrenci hesabına erişebilmelidir.

Öğrencinin sistemdeki diğer öğrencileri seçmesi veya görmesi kesinlikle mümkün olmamalıdır.

---

## 2. ÇOK ÖNEMLİ — ÖNCE ANALİZ

Kodlamaya başlamadan önce mevcut sistemi mutlaka analiz et.

Özellikle aşağıdaki yapıların tamamını bul ve mevcut ilişkilerini çıkar:
- `AppState`
- `AppRole`
- `setUnlocked`
- `clearSession`
- `sessionStudentId`
- `sessionClassId`
- `verifyStudentPassword`
- `student_password_hash`
- `openStudentPortal`
- `StudentTabWorkspace`
- `StudentPlatformScreen`
- öğrenci login ekranı
- "Öğrenci profili seçin" ekranını oluşturan widget/screen
- `AppShell`
- `AppViewerScreen`
- öğrenci listesi ve öğrenci oluşturma servisleri
- `SecretaryStudentService`
- `AppDatabase`
- `ogrenciler`
- öğrenci şifre alanları
- öğrenci ID alanları
- mevcut öğrenci portalı ekranları

Ayrıca şu soruların cevaplarını kod üzerinden tespit et:
1. Öğrenci şifresi hangi DB alanında tutuluyor?
2. Şifre hangi öğrenciye ait?
3. `verifyStudentPassword` yalnızca şifre mi doğruluyor, yoksa öğrenci kimliği de doğrulanıyor mu?
4. Öğrenci profil seçim ekranı neden ve nereden açılıyor?
5. `sessionStudentId` hangi noktada atanıyor?
6. Öğrenci portalına girildiğinde hangi ID kullanılıyor?
7. Öğrenci portalındaki sorgular gerçekten `sessionStudentId` ile sınırlandırılmış mı?
8. Varsayılan `ogrenci` şifresi mevcut öğrenci kayıtlarıyla nasıl ilişkilendiriliyor?
9. Sekreter tarafından oluşturulan yeni öğrencinin giriş bilgileri şu anda nasıl belirleniyor?
10. Mevcut öğrenci kayıtlarında şifre bulunmuyorsa mevcut veri yapısı nasıl davranıyor?

ÖNCE bu analizi yap. Analiz sonucuna göre en küçük ve güvenli değişiklik setini belirle.

---

## 3. MEVCUT MANTIĞI GEREKSİZ YERE YENİDEN YAZMA

Aşağıdaki mevcut altyapıları mümkün olduğunca koru:
- `AppRole`
- `AppState.currentRole`
- `setUnlocked`
- `clearSession()`
- `sessionStudentId`
- `sessionClassId`
- `StudentTabWorkspace`
- mevcut öğrenci veri modeli
- mevcut `student_password_hash`
- mevcut SQLite yapısı
- mevcut login/session mimarisi

Yeni bir authentication sistemi oluşturma.

Firebase, OAuth, JWT, REST authentication veya cloud authentication ekleme.

Ama mevcut yapı öğrenci bazlı kimlik doğrulamayı gerçekten desteklemiyorsa, gerekli minimum DB/model değişikliğini kontrollü şekilde yap.

---

## 4. HEDEF ÖĞRENCİ GİRİŞ AKIŞI

İstenen temel akış:

Ana Sayfa
→ Öğrenci
→ Öğrenci Giriş Ekranı
→ Öğrenci Kimliği / Öğrenci No + Şifre
→ Kimlik + Şifre doğrulaması
→ `sessionStudentId` atanır
→ `StudentTabWorkspace`

Öğrenci girişinden sonra:
`sessionStudentId = giriş yapan öğrencinin ID'si`

olmalıdır.

Öğrencinin başka bir öğrenci seçmesini sağlayan herhangi bir ekran olmamalıdır.

---

## 5. "ÖĞRENCİ PROFİLİ SEÇİN" EKRANININ DÜZELTİLMESİ

Mevcut "Öğrenci profili seçin" ekranını tespit et.

Bu ekran gerçek öğrenci login akışında kullanılıyorsa kaldır.

Özellikle:
- ALBU Sofia
- BORS Laura
- BOT Nicolae
- vb.

gibi tüm öğrencilerin listelendiği ekran öğrenci hesabı girişinden erişilebilir olmamalıdır.

Öğrenci login akışında:
- öğrenci listesi gösterme
- öğrenci seçtirme
- başka öğrencinin adına tıklayarak giriş yapma

kesinlikle yapılmayacak.

Eğer bu ekran uygulamanın başka bir yönetim/test akışında gerçekten gerekli ise, tamamen silmek yerine yalnızca uygun yönetim/test bağlamında bırakılabilir.

Ancak normal öğrenci login akışından erişilemez olmalıdır.

---

## 6. ÖĞRENCİ KİMLİĞİ

Mevcut DB yapısını incele.

Öğrenciyi belirlemek için zaten kullanılan güvenilir bir alan varsa onu kullan:
- öğrenci ID
- öğrenci numarası
- benzersiz kullanıcı kodu

Mevcut alanlardan uygun olanı tercih et.

Gereksiz yere yeni bir kullanıcı sistemi oluşturma.

Eğer mevcut öğrenci numarası benzersiz değilse veya giriş için güvenli şekilde kullanılamıyorsa bunu analiz raporunda belirt ve minimum gerekli düzeltmeyi yap.

---

## 7. ŞİFRE MANTIĞI

Mevcut `student_password_hash` yapısını incele.

Şifre doğrulaması mümkün olduğunca mevcut hash altyapısı üzerinden yapılmalıdır.

SADECE şifre doğrulamak yeterli değildir.

Hedef:
Öğrenci kimliği + öğrenciye ait şifre = başarılı login

Yanlış öğrenci + başka öğrencinin şifresi ile giriş yapılmasına izin verilmemelidir.

---

## 8. SEKRETER TARAFINDAN OLUŞTURULAN ÖĞRENCİ

Faz 2'de oluşturduğumuz `SecretaryStudentService` yapısını incele.

Sekreter yeni öğrenci oluşturduğunda öğrencinin login bilgilerinin nasıl oluştuğunu tespit et.

Hedef:
Sekreter → Öğrenci oluşturur → giriş kimliği oluşturulur → öğrenci şifresi atanır → öğrenci bu bilgilerle login olur.

Mevcut sistemde öğrenci şifresi için uygun bir alan zaten varsa onu kullan.

Yeni şifre alanı/migration ancak gerçekten gerekli ise eklenebilir.

---

## 9. ŞİFRE BELİRLEME POLİTİKASI

Eğer mevcut sistemde sekreter tarafından oluşturulan öğrenciler için şifre belirleme mekanizması yoksa:
- bunu tespit et,
- mevcut yapıya en uygun minimum çözümü uygula,
- sekreter öğrenci ekleme ekranında şifre belirlenmesi gerekiyorsa bunu ekle.

Gerekiyorsa öğrenci oluşturma ekranında:
- Öğrenci No
- Ad Soyad
- E-posta
- Sınıf
- Şifre
- Şifre Tekrar

alanları kullanılabilir.

Ancak mevcut veri modelinde daha uygun bir yapı varsa onu tercih et.

Şifreleri plaintext olarak DB'de tutma. Mevcut hash mekanizmasını kullan.

---

## 10. VARSAYILAN "ogrenci" ŞİFRESİ

Mevcut sistemde `ogrenci` gibi varsayılan bir öğrenci şifresi olup olmadığını tespit et.

Bu mekanizmanın tüm öğrenciler için ortak bir şifre oluşturup oluşturmadığını özellikle kontrol et.

Eğer bütün öğrencilerin aynı varsayılan şifre ile giriş yapabildiği bir yapı varsa bu güvenlik açısından düzeltilmelidir.

Ancak mevcut kullanıcıların girişini gereksiz yere bozma.

Migration gerekiyorsa kontrollü yap.

Sonuç raporunda açıkça belirt:
`Default student password: mevcut / kaldırıldı / geçiş amaçlı korunuyor`

---

## 11. SESSION YAPISI

Başarılı öğrenci login sonrasında:
`AppState.currentRole = AppRole.student`
ve
`sessionStudentId = ilgili öğrencinin ID'si`
olmalıdır.

Ayrıca gerekiyorsa `sessionClassId`, ilgili öğrencinin sınıfından belirlenmelidir.

`clearSession()` çağrıldığında:
- currentRole
- sessionStudentId
- sessionClassId
- ilgili öğrenci session bilgileri

temizlenmelidir.

Secretary veya Teacher hesabına geçerken öğrenci session bilgileri kalmamalıdır.

---

## 12. STUDENT PORTAL VERİ GÜVENLİĞİ

`StudentTabWorkspace` ve öğrenciye ait ekranları incele.

Özellikle:
- notlar
- devamsızlık
- dersler
- duyurular
- belgeler
- profil
- öğrenci bilgileri

gibi alanlarda öğrenci ID'sinin nereden geldiğini kontrol et.

Mümkün olduğunca `sessionStudentId` üzerinden veri çekilmesini sağla.

Öğrenci portalında tüm öğrencileri getirip UI'da seçim yaptıran bir yapı kesinlikle olmamalıdır.

Bunun yerine öğrenci portalında yalnızca oturum sahibinin verileri kullanılmalıdır.

---

## 13. BAŞKA ÖĞRENCİYE ERİŞİM TESTİ

Aşağıdaki senaryoları test et:

### Test 1
Öğrenci A ile login:
`sessionStudentId = A`

Öğrenci A yalnızca A'nın bilgilerini görmeli.

### Test 2
Öğrenci A'nın portalında öğrenci B'nin ID'sini manuel olarak kullanmaya çalışan bir akış varsa engellenmeli.

### Test 3
Öğrenci B ile logout/login:
`sessionStudentId = B`

olmalı ve A'nın bilgileri görünmemeli.

### Test 4
Öğrenci logout yaptıktan sonra:
`sessionStudentId == null`

olmalı.

### Test 5
Secretary login yaptıktan sonra:
`isStudent == false`
`isSecretary == true`

olmalı.

### Test 6
Teacher login yaptıktan sonra öğrenci session bilgileri taşınmamalı.

---

## 14. SİYAH EKRAN PROBLEMİ

Ekran görüntüsündeki mevcut durumda:
- pencerenin büyük bölümü siyah,
- ortada beyaz bir kutu,
- "Öğrenci profili seçin" listesi bulunuyor.

Bu görüntünün neden oluştuğunu kod üzerinden tespit et.

Özellikle şunları araştır:
- ayrı bir eski screen
- yanlış route
- `showDialog`
- `MaterialApp` dışında render edilen widget
- eski öğrenci seçim akışı
- tema/background problemi
- `StudentTabWorkspace`'in yanlış çağrılması
- desktop/mobile layout problemi

Sebebi tespit etmeden sadece arka planı beyaza çevirme.

HEDEF:
Öğrenci login sonrasında uygulamanın mevcut tasarım sistemi kullanılmalı.

Mevcut:
- AppShell
- Sidebar
- Navbar
- Theme
- responsive layout

yapılarıyla uyumlu olmalıdır.

Öğrenci için mevcut `StudentTabWorkspace` kullanılabiliyorsa onu kullan.

Yeni ve bağımsız bir öğrenci uygulaması oluşturma.

---

## 15. RESPONSIVE TASARIM

Web/Desktop:
- login kartı düzgün merkezlenmeli,
- makul genişlikte olmalı,
- gereksiz siyah alan olmamalı.

Mobile:
- ekran genişliğine uyumlu,
- keyboard açıldığında taşma olmamalı,
- login alanları kullanılabilir olmalı.

Öğrenci portalı da mevcut responsive yapıyı korumalı.

---

## 16. AUTHORIZATION

`AuthorizationService` mevcut yapısını incele.

Gerekli minimum öğrenci yetkilerini ekle.

Gerekliyse:
- `canAccessStudentWorkspace`
- `canViewOwnStudentData`

gibi capability'ler kullanılabilir.

Ancak gereksiz bir permission sistemi oluşturma.

Öğrencinin kendi verisi ile başka öğrencinin verisi arasındaki ayrımı öncelikle session üzerinden sağlamlaştır.

---

## 17. TESTLER

Yeni veya mevcut test yapısına uygun testler ekle.

En az şu senaryolar test edilmelidir:
1. `AppRole.student` doğru çalışıyor.
2. Başarılı öğrenci login `sessionStudentId` oluşturuyor.
3. Yanlış öğrenci kimliği + şifre reddediliyor.
4. Yanlış şifre reddediliyor.
5. Başarılı login doğru öğrenci ID'sini taşıyor.
6. `clearSession()` öğrenci session bilgisini temizliyor.
7. Öğrenci portalı `sessionStudentId` olmadan açılmıyor veya güvenli şekilde login'e dönüyor.
8. Secretary login student portalına düşmüyor.
9. Teacher login student portalına düşmüyor.
10. Öğrenci A'nın session'ı öğrenci B'nin verisine erişim sağlamıyor.

Widget testlerde SQLite/FutureBuilder kaynaklı flaky durum varsa Faz 2'deki state/service test yaklaşımını dikkate al.

Gerekirse service/state seviyesinde deterministic testler kullan.

---

## 18. REGRESSION

Aşağıdaki mevcut akışları bozma:

### Teacher
Teacher Login → Teacher Workspace

### Secretary
Secretary Login → SecretaryTabWorkspace

### Student
Student Login → StudentTabWorkspace

Teacher'ın:
- öğrenci düzenleme dialogu
- not
- sınav
- mevcut öğrenci yönetimi

mantığını değiştirme.

Secretary'nin Faz 1 ve Faz 2 özelliklerini bozma:
- Dashboard
- Öğrenci listesi
- Öğrenci ekleme
- Öğrenci düzenleme
- Sınıflar
- Şubeler
- Profilim
- Sidebar

---

## 19. BU FAZDA YAPILMAYACAKLAR

KESİNLİKLE aşağıdaki çalışmaları bu faza dahil etme:
- Veli sistemi
- Öğretmen yönetimi
- Devamsızlık modülü
- Duyurular
- Belgeler
- Raporlar
- Bildirimler
- Academic Plans
- Weekly Schedule değişiklikleri
- Öğrenci silme approval sistemi
- Firebase
- REST API
- JWT
- OAuth
- Cloud authentication
- Büyük çaplı UI redesign
- Database encryption
- Yeni rol sistemi

Bu faz yalnızca:
> Öğrenci Login + Student Session + Own Data Access + mevcut öğrenci portalının doğru açılması

içindir.

---

## 20. VERİTABANI DEĞİŞİKLİKLERİ

Migration gerekiyorsa:
1. Mevcut schema version'ı tespit et.
2. Migration'ın neden gerekli olduğunu belirt.
3. Mevcut verileri koru.
4. Eski kayıtların migration sonrasında çalışmasını sağla.
5. Test DB ile migration test et.

Gereksiz migration oluşturma.

---

## 21. KOD KALİTESİ

- Mevcut architecture patternlerini takip et.
- Duplicate login logic oluşturma.
- Duplicate student model oluşturma.
- Duplicate database helper oluşturma.
- Mevcut service/repository yapısını kullan.
- Magic string kullanımını azalt.
- Null safety'yi koru.
- Mevcut localization sistemini kullan.
- UI içine doğrudan SQL koyma.
- Öğrenci session mantığını tek merkezden yönet.

---

## 22. TAMAMLAMA KRİTERLERİ

Faz ancak aşağıdakilerin tamamı sağlandığında PASS kabul edilecektir:

### Login
- [ ] Öğrenci kimliği ile login yapılabiliyor.
- [ ] Öğrenci şifresi doğrulanıyor.
- [ ] Başarılı login doğru öğrenci ID'sini oluşturuyor.
- [ ] Öğrenci profil seçim ekranı normal login akışından kaldırıldı.
- [ ] Diğer öğrencilerin isimleri öğrenci login ekranında görünmüyor.

### Session
- [ ] `sessionStudentId` doğru.
- [ ] Logout session'ı temizliyor.
- [ ] Role geçişlerinde öğrenci session'ı temizleniyor.

### Security
- [ ] Öğrenci başka öğrenciyi seçerek giriş yapamıyor.
- [ ] Öğrenci yalnızca kendi verilerine erişiyor.
- [ ] Başka öğrenci ID'si ile erişim güvenli şekilde engelleniyor.

### UI
- [ ] Siyah ekran problemi çözüldü.
- [ ] Öğrenci login ekranı mevcut tema ile uyumlu.
- [ ] Öğrenci portalı mevcut uygulama shell/layout sistemiyle uyumlu.
- [ ] Desktop çalışıyor.
- [ ] Mobile çalışıyor.

### Regression
- [ ] Teacher login çalışıyor.
- [ ] Secretary login çalışıyor.
- [ ] Student login çalışıyor.
- [ ] Faz 2 Secretary özellikleri çalışıyor.

### Tests
`flutter test` çalıştırılmalı ve sonuç açıkça raporlanmalıdır.

---

## 23. SON RAPOR FORMATI

Çalışma sonunda aşağıdaki formatı kullan:

## FAZ 2.5 STATUS

PASS / FAIL / PARTIAL

### Analiz
- Öğrenci seçim ekranının kaynağı:
- Eski login akışının nedeni:
- Student password yapısı:
- sessionStudentId akışı:

### Yapılanlar
- ...

### Değiştirilen / eklenen dosyalar
- ...

### Database / Migration
- ...

### Student Login
- ...

### Session
- ...

### Security
- ...

### UI
- ...

### Test sonucu
flutter test
X passed
Y failed

### Manuel test gerektirenler
- ...

### Riskler
- ...

### Faz 3'e kalanlar
- ...

Özellikle "Öğrenci profili seçin" ekranının neden oluştuğunu raporda açıkça belirt.

Sadece ekranı değiştirip geçme; mevcut akışın teknik nedenini tespit et.

---

# SON TALİMAT

Önce analiz et.

Sonra minimum güvenli değişiklikleri uygula.

Sonra testleri çalıştır.

Mevcut Teacher, Secretary ve Student özelliklerini koru.

Faz kapsamı dışına çıkma.
