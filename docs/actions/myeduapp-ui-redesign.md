# ACTION — MYEDUAPP GLOBAL UI/UX REDESIGN

Bu action'ın amacı MyEduApp'ın mevcut fonksiyonlarını değiştirmeden,
uygulamanın tamamına modern, özgün, tutarlı ve profesyonel bir görsel tasarım uygulamaktır.

project.mdc içindeki TÜM kurallar bu action için aynen geçerlidir.

# 1. EN ÖNEMLİ KURAL — FONKSİYONLARA DOKUNMA

Bu görev öncelikle VISUAL/UI REDESIGN görevidir.

Mevcut uygulamanın:

- business logic
- database
- SQLite yapısı
- modeller
- repository
- service
- provider/state management
- CRUD işlemleri
- autosave
- veri kayıt sistemi
- hesaplama mantıkları
- raporlama mantığı
- PDF/Excel export
- routing
- navigation davranışları
- authentication
- mevcut kullanıcı işlemleri

BOZULMAMALI ve gereksiz yere değiştirilmemelidir.

Mevcut çalışan bir fonksiyon yalnızca görsel tasarıma uyum sağlamak için
gerekliyse minimum seviyede yeniden bağlanabilir.

Yeni business logic oluşturma.
Yeni database yapısı oluşturma.
Mevcut fonksiyonları yeniden yazma.
Mevcut çalışan özellikleri yeniden tasarlama.

ÖNCELİK:

Mevcut fonksiyonellik
>
Mevcut veri yapısı
>
Mevcut architecture
>
Mevcut componentler
>
Yeni görsel tasarım

# 2. TASARIM HEDEFİ

MyEduApp mevcut haliyle işlevsel bir eğitim uygulamasıdır.

Yeni tasarım:

- modern
- profesyonel
- sade
- ferah
- eğitim platformu hissi veren
- özgün
- görsel olarak zengin fakat karmaşık olmayan
- masaüstü kullanımına uygun
- tablet kullanımına uyumlu
- responsive
- bütün ekranlarda aynı tasarım dilini kullanan

bir yapıya dönüştürülmelidir.

Tasarım, sıradan bir CRUD uygulaması gibi görünmemelidir.

Modern bir eğitim yönetim platformu / teacher workspace hissi vermelidir.

# 3. GLOBAL APP SHELL

Uygulamanın bütün ana ekranlarında ortak bir App Shell oluştur.

Sol tarafta sabit veya responsive bir navigation paneli bulunmalıdır.

Navigation:

- MyEduApp logosu / markası
- Ana Sayfa
- Ders Platformu
- Öğrenci Platformu
- Raporlar
- Kullanım Kılavuzu
- Ayarlar

alanlarını içermelidir.

Kullanıcının hangi bölümde olduğunu açıkça gösteren active navigation state bulunmalıdır.

Navigation görsel olarak:

- koyu lacivert / mavi taban
- açık ve okunabilir ikonlar
- aktif menü için belirgin mavi vurgu
- yumuşak radius
- sade hover/selected durumları

kullanmalıdır.

Alt bölümde mevcut kullanıcı bilgisi gösterilebilir.

Mevcut navigation route'larını değiştirme.
Sadece mevcut route'ları ortak görsel navigation üzerinden erişilebilir hale getir.

# 4. ÜST HEADER

Ana çalışma alanının üstünde ortak bir header kullan.

Header:

- mevcut sayfa başlığı
- kısa açıklama/breadcrumb gerektiğinde
- arama alanı
- bildirim ikonu mevcutsa
- kullanıcı/avatar alanı
- gerekli action butonları

içerebilir.

Her sayfanın kendi header'ını tekrar tekrar oluşturma.

Mevcut işlevsel butonları koru ve uygun yerlere taşı.

# 5. TASARIM DİLİ

Mevcut MyEduApp Design System varsa onu genişlet ve yeniden kullan.

Yeni tasarım dili:

## Renk

Ana renk:
- koyu lacivert
- eğitim platformu hissi veren mavi

Vurgu:
- canlı mavi
- gerektiğinde mor
- yeşil
- turuncu
- kırmızı

Kategori renkleri birbirinden ayırt edilebilir olmalı.

Ancak ekranlar renk karmaşasına dönüşmemeli.

## Kartlar

Kartlar:

- rounded corners
- hafif border
- çok hafif shadow
- temiz white/light background
- yeterli padding

kullanmalıdır.

Her bilgi ayrı bir kart olmak zorunda değildir.

Gereksiz kart kullanımından kaçın.

## Typography

Mevcut typography sistemini koru.

Başlıklar belirgin,
alt başlıklar daha küçük,
yardımcı bilgiler daha düşük görsel ağırlıkta olmalıdır.

Türkçe karakterler düzgün desteklenmelidir.

## Icons

Mevcut icon sistemini kullan.

Aynı işlev için farklı icon stilleri kullanma.

# 6. ANA SAYFA

Ana Sayfa artık yalnızca ortada birkaç buton bulunan boş bir ekran gibi görünmemelidir.

Modern dashboard yaklaşımı kullan.

Üst bölüm:

- hoş geldiniz alanı
- kullanıcı adı
- kısa açıklama
- hızlı işlem butonları

Örneğin:

Ders Oluştur
Sınıf Ekle
Öğrenci Ekle
Rapor Oluştur

Mevcut fonksiyonlar korunmalıdır.

Sonrasında:

## Sınıflarım

Mevcut sınıfları modern kartlar halinde göster.

Her sınıf kartında mümkün olduğunca:

- sınıf adı
- akademik yıl
- şube
- öğrenci sayısı
- varsa mevcut performans özeti
- hızlı erişim

gösterilebilir.

Sınıf kartına tıklama mevcut davranışı bozmayacak şekilde çalışmalıdır.

## Hızlı Çalışma Alanları

Mevcut ana modüller:

- Ders Platformu
- Öğrenci Platformu
- Öğrenci Listesi
- Materyaller
- Aktiviteler
- Ödevler
- Sınavlar
- Raporlar

gibi işlevlere modern quick-access kartları oluştur.

Bu kartlar yeni fonksiyon oluşturmaz.
Mevcut ekranlara erişim sağlar.

## Bugünkü Akış / Son Aktiviteler

Mevcut verilerden yararlanarak mevcut aktiviteleri görsel olarak düzenle.

Yeni veri modeli oluşturma.

# 7. TEK SAYFADAN ERİŞİM FELSEFESİ

Kullanıcı mümkün olduğunca her ana işleve tek bir ana çalışma alanından ulaşabilmelidir.

Kullanıcı:

Ana Sayfa
→ Ders Platformu
→ Öğrenci Platformu
→ Raporlar

arasında sürekli geri tuşuna basmak zorunda kalmamalıdır.

Sol navigation her zaman ana bölümlere erişim sağlamalıdır.

Alt ekranlarda geri butonu kullanılabilir fakat ana navigation kaybolmamalıdır.

# 8. DERS PLATFORMU

Ders Platformu mevcut işlevlerini koruyarak modern bir içerik yönetim alanına dönüştürülmelidir.

Hiyerarşi görsel olarak açıkça anlaşılmalıdır:

Ders
↓
Kurs
↓
Ünite
↓
Konu
↓
Doküman / İçerik

## Dersler

Dersler modern kart/grid yapısında gösterilebilir.

Kart:

- ders görseli
- ders adı
- içerik sayısı varsa içerik sayısı
- ilgili kurs sayısı varsa kurs sayısı

içerebilir.

## Kurslar

Kurs kartlarında:

- kurs adı
- akademik yıl
- görsel
- ünite sayısı

gösterilebilir.

## Üniteler

Üniteler numara + başlık ile görsel olarak ayrıştırılmalıdır.

## Konu / İçerik

Ünite açıldığında:

SOL:
Konu listesi

SAĞ:
Seçilen konuya ait içerik/doküman alanı

kullanılmalıdır.

Mevcut içerik oluşturma, düzenleme, silme ve önizleme fonksiyonları aynen korunmalıdır.

# 9. DERS OLUŞTURUCU

Ders Oluşturucu ekranını mevcut fonksiyonlarını koruyarak profesyonel bir çalışma alanına dönüştür.

Mevcut:

- Blok Türleri
- Ders Yapısı
- Ders/Kurs/Ünite/Konu ayarları

korunmalıdır.

Üç kolonlu çalışma alanı kullanılabilir:

SOL:
İçerik blokları

ORTA:
Ders yapısı / çalışma alanı

SAĞ:
Ayarlar / özellikler

Bu ekran bir admin panelinden çok modern bir "lesson builder" hissi vermelidir.

Mevcut drag/drop ve içerik oluşturma fonksiyonlarına dokunma.

# 10. ÖĞRENCİ PLATFORMU

Öğrenci Platformu uygulamanın en önemli ekranlarından biri olduğundan daha güçlü bir dashboard görünümüne sahip olmalıdır.

Sol tarafta sınıflar:

7. Sınıf / 2026-27 / A
7. Sınıf / 2026-27 / B
8. Sınıf / 2026-27 / A
...

şeklinde düzenli gösterilebilir.

Sınıflar expandable/collapsible olmalıdır.

Sınıf başlığı her zaman görünür kalmalıdır.

Sınıf açıldığında:

- Öğrenci Listesi
- Materyaller
- Aktiviteler
- Ödevler
- Sınavlar
- kullanıcı kategorileri

gösterilebilir.

Sağdaki ana çalışma alanında seçilen bölüm açılmalıdır.

Kullanıcı sınıf → kategori → kayıt işlemlerini mümkün olduğunca aynı çalışma alanında gerçekleştirebilmelidir.

# 11. KATEGORİLER

Sistem kategorileri görsel olarak birbirinden ayırt edilebilir.

Sabit sistem kategorileri:

1. Öğrenci Listesi
2. Materyaller
3. Aktiviteler
4. Ödevler
5. Sınavlar

olmalıdır.

Kullanıcı kategorileri bunların altında gösterilebilir.

Her kategori için:

- icon
- kategori adı
- kısa açıklama
- kayıt sayısı varsa kayıt sayısı

gösterilebilir.

Mevcut kategori yönetimi fonksiyonları korunmalıdır.

# 12. KATEGORİ DETAY EKRANI

Kategori detay ekranı modern bir veri çalışma alanı şeklinde tasarlanmalıdır.

Üst bölüm:

- kategori iconu
- kategori adı
- kategori açıklaması
- tarih seçici
- önceki/sonraki gün

Orta bölüm:

öğrenci tablosu / liste görünümü.

Öğrenciler:

- öğrenci adı
- puan/değer
- mevcut ilgili bilgiler

şeklinde gösterilmelidir.

Mevcut autosave davranışı aynen korunmalıdır.

Per-student açıklama alanı mevcut gereksinime göre kullanılmamalıdır.

# 13. ÖĞRENCİ PERFORMANSI

Öğrenci performans ekranı modern bir analytics dashboard şeklinde tasarlanmalıdır.

Üst bölüm:

- öğrenci avatarı
- öğrenci adı
- sınıf
- akademik yıl
- tarih/dönem seçimi

Ana bölüm:

- Genel Ortalama
- kategori ortalamaları
- aylık genel ortalama
- performans trendi

görsel olarak gösterilebilir.

Grafikler mevcut verilerden üretilmelidir.

Yeni hesaplama sistemi oluşturma.

Mevcut hesaplama mantığını aynen kullan.

# 14. RAPORLAR

Rapor ekranı modern bir report workspace görünümünde olmalıdır.

Üst bölüm:

Bireysel | Toplu

seçimi.

Filtreler:

- öğrenci
- sınıf
- başlangıç tarihi
- bitiş tarihi
- kategori

Mevcut PDF ve Excel export fonksiyonları korunmalıdır.

Rapor oluşturma butonu görsel olarak öne çıkarılabilir.

# 15. ÖĞRENCİ PANELİ

Öğrenci paneli de öğretmen paneli ile aynı App Shell'i kullanmalıdır.

Öğrenci tarafında:

- Ana Sayfa / Öğrenme Paneli
- Ders Platformu
- ilgili mevcut öğrenci özellikleri

aynı navigation sistemi üzerinden erişilebilir olmalıdır.

Öğrenci Paneli / Öğrenme Paneli:

- Derslerim
- Ödevlerim
- Sınavlarım
- Performansım
- Son aktiviteler

gibi mevcut özellikleri modern dashboard kartlarıyla göstermelidir.

Mevcut öğrenci fonksiyonlarını değiştirme.

# 16. KULLANIM KILAVUZU

Kullanım Kılavuzu ekranını FAQ / Help Center görünümüne dönüştür.

Üst bölüm:

- başlık
- kısa açıklama
- arama alanı

FAQ maddeleri:

- temiz kartlar
- accordion yapısı
- iconlar

kullanabilir.

Mevcut soru/cevap içeriklerini değiştirme.

# 17. AYARLAR

Ayarlar ekranını modern settings workspace haline getir.

Bölümler:

- Dil
- Tema
- Güvenlik
- Otomatik yedekleme
- Etiketler
- Soru Bankası
- Arama
- Yedek Alma

mevcut yapıya göre gruplandırılabilir.

Her ayarı görsel olarak anlaşılır bir setting row/card şeklinde göster.

Mevcut ayar fonksiyonlarını değiştirme.

# 18. MODAL VE DIALOG TASARIMI

Mevcut dialoglar da yeni tasarım diline uymalıdır.

Dialoglar:

- yeterli genişlik
- rounded corners
- net başlık
- kısa açıklama
- düzenli form alanları
- belirgin primary action
- ikincil cancel action

kullanmalıdır.

Mevcut form alanlarının işlevlerini değiştirme.

# 19. FORM TASARIMI

Dropdown, text field, date picker ve diğer inputlar aynı tasarım sistemine sahip olmalıdır.

Formlarda:

- label
- input
- yardımcı açıklama
- validation mesajı

arasındaki spacing tutarlı olmalıdır.

# 20. TABLO TASARIMI

Öğrenci listeleri ve veri giriş tabloları modern dashboard table görünümüne sahip olmalıdır.

Ancak mevcut veri giriş fonksiyonları korunmalıdır.

Özellikle:

- 26+ öğrencinin tamamı görüntülenebilmeli
- vertical scrolling düzgün çalışmalı
- header okunabilir olmalı
- satırlar kolay ayırt edilebilmeli
- puan alanları kolay düzenlenebilmeli

# 21. RESPONSIVE TASARIM

Masaüstü ana kullanım senaryosudur.

Ancak tasarım:

- desktop
- tablet

ekranlarında düzgün çalışmalıdır.

Dar ekranlarda sidebar gerektiğinde responsive davranabilir.

Üç kolonlu ekranlar dar genişliklerde kontrollü şekilde iki kolon / tek kolon düzenine geçebilir.

Mevcut işlevlerin kaybolmasına izin verme.

# 22. EMPTY STATE

Boş ekranlar yalnızca ortada düz metin göstermek yerine modern empty state tasarımına sahip olmalıdır.

Örneğin:

- icon/illustration
- kısa açıklama
- primary action

kullanılabilir.

Yeni fonksiyon ekleme; mevcut action varsa ona bağla.

# 23. LOADING / ERROR / SUCCESS STATE

Mevcut loading, error ve success durumlarını yeni tasarım sistemine uyarla.

Fonksiyonel davranışı değiştirme.

# 24. TASARIMDA KAÇINILACAKLAR

Şunları yapma:

- mevcut business logic'i yeniden yazma
- yeni database oluşturma
- yeni repository oluşturma
- yeni provider oluşturma
- yeni dependency ekleme
- route sistemini değiştirme
- çalışan fonksiyonları kaldırma
- gereksiz refactor
- tüm uygulamayı yeniden yazma
- mevcut verileri değiştirme
- mevcut kayıtları silme
- sırf görsel amaçlı veri modeli değiştirme

Ayrıca:

Her alanı karta dönüştürme.
Her yere gradient ekleme.
Aşırı renk kullanma.
Aşırı animasyon kullanma.
Gereksiz büyük boşluklar oluşturma.
Kullanıcıyı gereksiz popup/dialog ile yorma.

# 25. COMPONENT STRATEJİSİ

Mevcut reusable componentler varsa onları kullan.

Aynı görsel yapı birçok yerde kullanılıyorsa mevcut design system üzerinden ortak component oluşturulabilir.

Ancak aynı işlevi yapan duplicate component oluşturma.

Özellikle ortaklaştırılabilecek yapılar:

- App Shell
- Sidebar
- Header
- Page Header
- Card
- Stat Card
- Category Card
- Class Card
- Section Header
- Primary Button
- Secondary Button
- Form Field
- Dropdown
- Date Selector
- Empty State
- Dialog

olabilir.

Mevcut component mimarisi yeterliyse yeni component oluşturma.

# 26. TASARIM REFERANSI

Tasarımın genel görsel yönü:

Modern eğitim SaaS platformu
+
Teacher Workspace
+
Student Learning Dashboard

kombinasyonunda olmalıdır.

Ana görsel karakter:

- navy sidebar
- açık arka plan
- beyaz içerik alanları
- mavi primary action
- pastel kategori renkleri
- rounded cards
- subtle shadows
- clean typography
- modern icons
- güçlü spacing sistemi

olmalıdır.

Tasarım mevcut ekranların basit bir makyajı olmamalıdır.

Ancak mevcut işlevsel yapı korunarak görsel hiyerarşi ve kullanım deneyimi ciddi şekilde iyileştirilmelidir.

# 27. UYGULAMA STRATEJİSİ

ÖNCE:

Mevcut uygulamayı analiz et.

Özellikle:

- mevcut App Shell
- navigation
- theme
- reusable components
- page layouts
- providers
- routes

tespit edilmelidir.

SONRA:

1. Global Theme / Design System
2. App Shell
3. Sidebar
4. Header
5. Ana Sayfa
6. Ders Platformu
7. Ders Oluşturucu
8. Öğrenci Platformu
9. Kategori Yönetimi
10. Kategori Detayları
11. Öğrenci Performansı
12. Raporlar
13. Öğrenci Paneli
14. Kullanım Kılavuzu
15. Ayarlar
16. Dialog/Form/Table/Empty State

sırasıyla görsel olarak uyarlanmalıdır.

Her aşamada mevcut fonksiyonların çalışmaya devam ettiğini kontrol et.

# 28. DOSYA KAPSAMI

Sadece UI için gerekli dosyaları değiştir.

Mümkün olduğunca:

- screens/pages
- widgets/components
- theme/design system

dosyalarıyla sınırlı kal.

Provider, repository, model, database veya service dosyalarına
görsel görev nedeniyle dokunmak zorunda kalırsan önce mevcut yapıyı analiz et
ve yalnızca minimum gerekli değişikliği yap.

# 29. VALIDATION

Değişikliklerden sonra:

- flutter analyze
- ilgili widget/screen testleri
- mevcut route kontrolleri

çalıştır.

Özellikle şu fonksiyonların bozulmadığını kontrol et:

- sınıf ekleme
- öğrenci ekleme
- öğrenci düzenleme
- öğrenci silme
- kategori ekleme
- kategori düzenleme
- kategori silme
- puan girişi
- autosave
- tarih değiştirme
- ders oluşturma
- kurs ekleme
- ünite ekleme
- konu ekleme
- içerik ekleme
- içerik görüntüleme
- PDF export
- Excel export
- rapor oluşturma
- ayarlar

# 30. SON KONTROL

Uygulamanın bütün ana ekranlarında:

- aynı sidebar
- aynı header
- aynı typography
- aynı button sistemi
- aynı card dili
- aynı spacing
- aynı icon dili
- aynı renk mantığı

kullanıldığını kontrol et.

Kullanıcı uygulamanın bir ekranından diğerine geçtiğinde
başka bir uygulamaya geçmiş hissine kapılmamalıdır.

MyEduApp tek ve bütünleşik bir eğitim platformu gibi görünmelidir.

# KABUL KRİTERLERİ

- [ ] Mevcut fonksiyonlar çalışıyor.
- [ ] Mevcut database korunuyor.
- [ ] Mevcut veriler korunuyor.
- [ ] Mevcut routes korunuyor.
- [ ] Mevcut providers korunuyor.
- [ ] Mevcut CRUD işlemleri çalışıyor.
- [ ] Autosave çalışıyor.
- [ ] PDF export çalışıyor.
- [ ] Excel export çalışıyor.
- [ ] Ortak App Shell uygulanmış.
- [ ] Ortak Sidebar uygulanmış.
- [ ] Ortak Header uygulanmış.
- [ ] Ana Sayfa modern dashboard görünümünde.
- [ ] Ders Platformu modern içerik platformu görünümünde.
- [ ] Ders Oluşturucu modern workspace görünümünde.
- [ ] Öğrenci Platformu modern dashboard görünümünde.
- [ ] Kategori ekranları modern tablo/workspace görünümünde.
- [ ] Öğrenci Performansı analytics dashboard görünümünde.
- [ ] Raporlar modern report workspace görünümünde.
- [ ] Öğrenci Paneli aynı tasarım sistemini kullanıyor.
- [ ] Kullanım Kılavuzu modern help center görünümünde.
- [ ] Ayarlar modern settings görünümünde.
- [ ] Dialog/form/table tasarımları ortak tasarım dilinde.
- [ ] Responsive davranış korunuyor.
- [ ] Gereksiz dependency eklenmedi.
- [ ] Gereksiz refactor yapılmadı.
- [ ] UI dışında business logic değiştirilmedi.