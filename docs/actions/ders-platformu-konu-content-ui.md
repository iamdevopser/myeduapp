# ACTION — DERS PLATFORMU KONU / CONTENT ALANI UI DÜZENLEMESİ

project.mdc içindeki tüm kurallar aynen geçerlidir.

Bu action SADECE mevcut Ders Platformu ekranının görsel yerleşimini
ve kullanıcı deneyimini iyileştirmek içindir.

MEVCUT FONKSİYONLAR, VERİ AKIŞI, DATABASE, MODEL, PROVIDER,
REPOSITORY, ROUTING VE İÇERİK EKLEME MANTIĞI BOZULMAMALIDIR.

Yeni özellik veya yeni mimari oluşturma.
Mevcut çalışan sistemi yeniden yazma.
Sadece gerekli UI/layout değişikliklerini yap.

---

# 1. MEVCUT PROBLEM

Ders Platformunda bir ünite açıldığında:

- Konular ayrı bir alanda gösteriliyor.
- Konu seçildiğinde konuya ait dokümanlar ayrıca başka bir alanda/listede gösteriliyor.
- Bu nedenle asıl Content/Doküman görüntüleme alanı gereksiz şekilde daralıyor.

Bu yapı değiştirilmelidir.

---

# 2. YENİ TASARIM

Ders Platformunda:

SOL:
"Konu Seç" alanı

SAĞ:
"Content" alanı

olacak şekilde iki ana bölümlü bir yapı kullanılmalı.

Konuya ait dokümanlar için ayrıca kalıcı bir doküman listesi/paneli oluşturulmayacak.

Yeni akış:

Ünite
↓
Konu seç
↓
Seçilen konunun mevcut dokümanı/içeriği
↓
Doğrudan Content alanında açılır.

---

# 3. KONU PANELİ HOVER DAVRANIŞI

"Konu Seç" bölümü Ana Sayfadaki sidebar yapısına benzer şekilde
hover ile açılıp kapanabilmelidir.

Amaç Content alanına mümkün olduğunca fazla genişlik bırakmaktır.

Konu paneli:

- Normal durumda daraltılmış olabilir.
- Kullanıcı üzerine geldiğinde genişleyerek konuları göstermeli.
- Kullanıcı konu seçtiğinde tekrar daralabilir.
- Seçili konu görsel olarak anlaşılmalıdır.
- Hover/open/close sırasında mevcut Content alanı bozulmamalıdır.
- Responsive davranış korunmalıdır.

Ana Sayfadaki mevcut sidebar hover/collapse implementasyonu varsa
aynı yaklaşım/component/mantık mümkün olduğunca yeniden kullanılmalıdır.

Yeni bir sidebar sistemi oluşturma.

---

# 4. KONUYA TIKLANDIĞINDA

Kullanıcı bir konuya tıkladığında:

1. Konu seçilmeli.
2. O konuya bağlı mevcut içerik/dokümanlar bulunmalı.
3. İçerik doğrudan ana Content alanında açılmalı.
4. Ayrı bir "Dokümanlar" paneli açılmamalı.
5. Doküman isimlerinin listelendiği ikinci bir kalıcı alan oluşturulmamalı.

Örneğin:

Konu:
"Açılış Dersi"

Bu konuya bağlı:

"7.SINIF - GİRİŞ.pdf"

varsa kullanıcı konuya tıkladığında bu doküman doğrudan
Content alanında görüntülenmelidir.

Kullanıcının önce:

Konu → Doküman adı → Doküman

şeklinde ikinci bir seçim yapması gerekmemelidir.

Yeni akış:

Konu → Content

olmalıdır.

---

# 5. BİRDEN FAZLA DOKÜMAN DURUMU

Bir konuya mevcut sistemde birden fazla doküman bağlı olabiliyorsa
mevcut veri yapısı korunmalıdır.

Bu durumda:

- Yeni database yapısı oluşturma.
- Mevcut doküman ilişkilerini değiştirme.
- Mevcut içerikleri silme veya taşıma.

Birden fazla içerik varsa mevcut sistemin desteklediği şekilde
Content alanı içerisinde içerikler arasında geçiş yapılabilecek
en minimal UI kullanılabilir.

Ancak doküman listesi Content alanının dışında ayrı ve kalıcı
bir sol/orta panel olarak gösterilmemelidir.

---

# 6. CONTENT ALANI

Content alanı mümkün olduğunca geniş tutulmalıdır.

Mevcut:

- PDF görüntüleme
- Word
- Görsel
- Video
- Ses
- Web Link
- diğer mevcut içerik türleri

hangi mekanizma ile açılıyorsa aynen kullanılmalıdır.

Content viewer yeniden yazılmamalıdır.

Sadece mevcut viewer'ın yeni layout içerisindeki kullanılabilir
alanı genişletilmelidir.

---

# 7. ÜNİTE → KONU İLİŞKİSİ

Çok önemli:

Bir ünite açıldığında sadece o üniteye ait konular gösterilmelidir.

Başka ünitelerin konuları kesinlikle gösterilmemelidir.

Örneğin:

Ünite 1 seçildiğinde:

Konu 1
Konu 2
Konu 3

sadece Ünite 1'e aitse gösterilmeli.

Ünite 2 seçildiğinde:

Konu 4
Konu 5
Konu 6

sadece Ünite 2'ye aitse gösterilmeli.

Mevcut database ilişkisi ve repository/provider yapısı korunmalıdır.

---

# 8. MEVCUT FONKSİYONLAR KORUNACAK

Aşağıdaki özelliklerin hiçbirinin çalışma mantığı değiştirilmemelidir:

- Ders seçimi
- Kurs seçimi
- Akademik yıl
- Ünite seçimi
- Konu seçimi
- Konu ekleme
- Konu düzenleme
- Konu silme
- Doküman ekleme
- Doküman düzenleme
- Doküman silme
- İçerik görüntüleme
- Favoriler
- Mevcut navigation
- Database kayıtları
- Offline-first çalışma

Bu action yalnızca UI/layout/interaction düzenlemesidir.

---

# 9. TASARIM KURALLARI

Mevcut MyEduApp Design System kullanılmalıdır.

Korunacaklar:

- Renkler
- Typography
- Icon sistemi
- Border radius
- Spacing
- Button yapıları
- Mevcut sidebar tasarımı
- Mevcut responsive davranış

Yeni renk sistemi veya yeni design system oluşturma.

Ana Sayfadaki mevcut sidebar hover/collapse davranışı
uygunsa doğrudan yeniden kullanılmalıdır.

---

# 10. KABUL KRİTERLERİ

- [ ] Konu paneli hover ile açılıp kapanıyor.
- [ ] Konu paneli Content alanını gereksiz yere daraltmıyor.
- [ ] Konuya tıklandığında doküman doğrudan Content alanında açılıyor.
- [ ] Ayrı kalıcı doküman listesi paneli bulunmuyor.
- [ ] Content alanı mümkün olduğunca geniş kullanılıyor.
- [ ] Bir konuya ait mevcut içerikler korunuyor.
- [ ] Birden fazla doküman varsa mevcut veri ilişkisi korunuyor.
- [ ] Sadece seçilen üniteye ait konular gösteriliyor.
- [ ] Diğer ünitelerin konuları gösterilmiyor.
- [ ] Mevcut PDF/content viewer bozulmuyor.
- [ ] Database değişikliği yapılmıyor veya zorunlu olmadıkça mevcut veri yapısına dokunulmuyor.
- [ ] Yeni dependency eklenmiyor.
- [ ] Mevcut fonksiyonlar bozulmuyor.
- [ ] Sadece gerekli UI dosyaları değiştiriliyor.
- [ ] İlgili analyzer/test kontrolleri çalıştırılıyor.