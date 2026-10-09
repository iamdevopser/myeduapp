# ACTION — DERS PLATFORMU HİYERARŞİ VE VERİ KAPSAMI DÜZELTMESİ

project.mdc içindeki tüm kurallar geçerlidir.

## TEMEL AMAÇ

Ders Platformunda mevcut UI tasarımını ve çalışan Ders → Kurs yapısını KORU.

Bu action'ın amacı yeni bir UI tasarlamak değildir.

Asıl problem:
Üniteler ve Konular ekranlarında kayıtların doğru parent nesneye
bağlanmadan GLOBAL olarak listelenmesidir.

Veri hiyerarşisi kesin olarak şu şekilde çalışmalıdır:

Ders
  ↓
Kurs
  ↓
Ünite
  ↓
Konu
  ↓
Doküman / İçerik

Her alt seviye yalnızca seçilmiş üst seviyeye ait kayıtları göstermelidir.

---

# 1. ÖNCE MEVCUT SİSTEMİ ANALİZ ET

Kod değiştirmeden önce yalnızca gerekli dosyaları incele.

Özellikle:

- Ders Platformu ekranları
- Kurs listesi
- Ünite listesi
- Konu listesi
- ilgili modeller
- database tabloları
- repository/service sorguları
- provider/state management
- navigation/routing
- seçili course/unit state'i
- mevcut içerik/doküman ilişkileri

Mevcut veri modelinde Ders → Kurs → Ünite → Konu ilişkisi
nasıl tutuluyorsa onu tespit et.

YENİ bir model, repository veya database yapısı oluşturma.

---

# 2. KURS KAPSAMI

Kullanıcı bir Ders seçtiğinde yalnızca o derse ait Kurslar gösterilmeli.

Örneğin:

Türkçe
→ Türkçe 7. Sınıf / 2026-27
→ Türkçe 8. Sınıf / 2026-27
→ Türkçe 9. Sınıf / 2026-27

başka derslerin kursları bu listede görünmemeli.

MEVCUT KURS LİSTESİ ZATEN DOĞRU ÇALIŞIYORSA
bu kısmı yeniden yazma.

---

# 3. ÜNİTE KAPSAMI — KRİTİK

Bir Kurs açıldığında Üniteler ekranı yalnızca
SEÇİLEN KURSA ait üniteleri göstermeli.

Örnek:

Türkçe 7. Sınıf / 2026-27

sadece:

0. Açılış Dersi
1. Ünite 1
2. Ünite 2
...
16. Ünite 16

gibi BU KURSA ait kayıtları göstermeli.

Başka kursların üniteleri kesinlikle gösterilmemeli.

ÖNEMLİ:

Ünite sorgusu/listesi global olarak tüm üniteleri çekmemeli.

Her ünite sorgusu mevcut veri modelindeki gerçek kurs ilişkisini
kullanarak filtrelenmeli.

Örneğin mevcut modelde:

courseId
parentId
course_id
curriculumId
veya eşdeğer bir ilişki varsa onu kullan.

Alan adını tahmin etme.
Mevcut kod ve database yapısından tespit et.

---

# 4. KONU KAPSAMI — KRİTİK

Bir Ünite açıldığında yalnızca SEÇİLEN ÜNİTEYE ait Konular gösterilmeli.

Örneğin:

Türkçe 7. Sınıf
→ 1. Ünite
→

Konu 1
Konu 2
Konu 3
Konu 4

gibi yalnızca 1. Üniteye ait konular gösterilmeli.

2. Üniteye ait konular,
başka kursa ait konular veya başka seviyedeki konular
kesinlikle bu listede görünmemeli.

Şu anda görülen:

Açılış Dersi
Konu 1
Açılış Dersi
Tanışma ve Selamlaşma
Açılış Dersi
1.Günlük İşler
...

şeklindeki karışık global listeyi düzelt.

Konu sorgusu mutlaka mevcut veri modelindeki
SEÇİLİ ÜNİTE ilişkisine göre filtrelenmeli.

---

# 5. NAVIGATION CONTEXT KORUNMALI

Navigation sırasında parent context kaybolmamalı.

Örneğin:

Ders
→ Türkçe
→ Kurs
→ Türkçe 7. Sınıf / 2026-27
→ Ünite
→ 1. Ünite
→ Konular

akışında:

selectedCourseId
ve
selectedUnitId

gibi mevcut state/route parametreleri zaten varsa bunları kullan.

Yeni bir state sistemi oluşturma.

Navigation hangi yöntemle mevcut projede yapılıyorsa
aynı yöntemi kullan.

Geri dönüşlerde de doğru parent context korunmalı.

---

# 6. ÜNİTE VE KONU LİSTELERİNDE GLOBAL VERİ KULLANMA

Aşağıdaki yaklaşım YASAK:

- tüm üniteleri çek
- UI tarafında göstermeye çalış
- tüm konuları çek
- UI tarafında filtrelemeye çalış

Öncelik mevcut repository/service/database sorgusunda
doğru parent filtrelemesidir.

Doğru yaklaşım:

selectedCourse
→ sadece bu course'un units

selectedUnit
→ sadece bu unit'in topics

şeklinde olmalıdır.

Mevcut repository metotları yeterliyse onları kullan.

Gerekirse mevcut sorguya minimum filtre ekle.

---

# 7. DOKÜMAN / İÇERİK İLİŞKİSİ

Konu seçildiğinde gösterilen doküman/içerikler de
aynı hiyerarşik kapsamı korumalı.

Akış:

Kurs
→ Ünite
→ Konu
→ Doküman/İçerik

Bir konunun içeriği başka bir konudan gelmemeli.

Özellikle mevcut PDF/doküman gösterim sistemini bozma.

PDF viewer, içerik viewer veya mevcut document navigation
çalışıyorsa yeniden oluşturma.

---

# 8. UI'Yİ BOZMA

Şu anda Dersler ve Kurslar ekranında çalışan:

- kart yapısı
- grid yapısı
- responsive yapı
- breadcrumb
- sidebar
- Ders Platformu alt menüleri
- mevcut tasarım
- mevcut spacing
- mevcut typography
- mevcut renkler
- mevcut ikonlar

KORUNMALI.

Bu action kapsamında yeni bir tasarım yapılmayacak.

Ama Üniteler ve Konular ekranında mevcut tasarım
doğru veriyi gösterecek şekilde çalışmalıdır.

---

# 9. VERİLERİ SİLME / DEĞİŞTİRME

Mevcut SQLite verilerini değiştirme.

Migration yapma.

Seed data değiştirme.

Mevcut ünite veya konu kayıtlarını silme.

Mevcut ilişkileri yeniden oluşturma.

Öncelikle problemin yalnızca yanlış sorgu/filter/state
nedeniyle oluşup oluşmadığını tespit et.

Amaç mevcut verileri DOĞRU KAPSAMDA GÖSTERMEKTİR.

---

# 10. AYNI İSİMLİ KAYITLAR

Aynı isimde:

- Ünite 1
- Konu 1
- Açılış Dersi

gibi kayıtlar farklı kurslarda veya farklı ünitelerde bulunabilir.

Bu kayıtlar isimlerine göre birbirinden ayırt edilmemeli.

Kimlik/ID ve parent ilişkisi kullanılmalı.

Örneğin:

Kurs A → Ünite 1 → Konu 1

Kurs B → Ünite 1 → Konu 1

iki farklı kayıt olarak desteklenmelidir.

Sadece name/title ile filtreleme yapma.

---

# 11. BEKLENEN TEST

Aşağıdaki senaryoyu özellikle test et:

### Senaryo 1

Türkçe
→ Türkçe 7. Sınıf / 2026-27
→ Üniteler

SONUÇ:

Yalnızca bu kursa ait üniteler.

### Senaryo 2

Türkçe 7. Sınıf / 2026-27
→ 1. Ünite

SONUÇ:

Yalnızca 1. Üniteye ait konular.

### Senaryo 3

1. Ünite
→ Konu 1

SONUÇ:

Yalnızca Konu 1'e ait doküman/içerikler.

### Senaryo 4

Geri dön:

Konu
→ Ünite
→ Kurs

SONUÇ:

Doğru parent seviyesine geri dönülmeli.

### Senaryo 5

Başka bir kurs aç:

Türkçe 8. Sınıf / 2026-27

SONUÇ:

7. sınıfın ünite ve konuları burada görünmemeli.

---

# 12. KABUL KRİTERLERİ

- [ ] Ders listesi mevcut haliyle çalışıyor.
- [ ] Kurs listesi mevcut haliyle çalışıyor.
- [ ] Kurslar doğru derse göre filtreleniyor.
- [ ] Üniteler yalnızca seçilen kursa göre filtreleniyor.
- [ ] Konular yalnızca seçilen üniteye göre filtreleniyor.
- [ ] Dokümanlar yalnızca seçilen konuya göre filtreleniyor.
- [ ] Aynı isimli kayıtlar ID/parent ilişkileriyle ayrıştırılıyor.
- [ ] Navigation sırasında course/unit context kaybolmuyor.
- [ ] Geri dönüşlerde doğru context korunuyor.
- [ ] Mevcut kart/grid UI bozulmuyor.
- [ ] Mevcut breadcrumb bozulmuyor.
- [ ] Mevcut sidebar alt menü yapısı bozulmuyor.
- [ ] Mevcut PDF/doküman viewer bozulmuyor.
- [ ] Mevcut SQLite verileri korunuyor.
- [ ] Yeni dependency eklenmiyor.
- [ ] Yeni duplicate model/repository/service oluşturulmuyor.
- [ ] Gereksiz refactor yapılmıyor.

---

# 13. UYGULAMA PRENSİBİ

ÖNCE problemi bul.

Özellikle şu ihtimalleri kontrol et:

1. Ünite repository sorgusu courseId filtresi kullanıyor mu?
2. Konu repository sorgusu unitId filtresi kullanıyor mu?
3. Provider tüm kayıtları mı getiriyor?
4. Navigation selectedCourse/selectedUnit bilgisini kaybediyor mu?
5. UI yanlış provider/state'i mi dinliyor?
6. Aynı isimli kayıtları name üzerinden mi eşleştiriyor?
7. Route parametreleri doğru parent ID'yi taşıyor mu?

Problemin gerçek nedenini tespit ettikten sonra
EN KÜÇÜK gerekli kod değişikliğini yap.

Birden fazla olası çözüm varsa mevcut mimariye en uygun
ve en az değişiklik gerektiren çözümü seç.

İşlem sonunda:

- değiştirilen dosyaları,
- problemin gerçek nedenini,
- yapılan düzeltmeyi,
- test sonuçlarını

kısaca raporla.