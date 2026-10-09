ACTION — MENTÖRLÜK PLATFORMU

0. KAPSAM VE TEMEL KURAL

Bu action, MyEduApp Öğretmen Platformuna yeni bir Mentörlük modülü eklenmesini kapsar.

project.mdc içindeki tüm kurallar bu action için aynen geçerlidir.

Özellikle:

Mevcut çalışan özellikleri bozma.

Mevcut database, model, repository, service, provider/state management ve routing yapısını önce analiz et.

Aynı işi yapan yeni yapı oluşturma.

Gereksiz refactor yapma.

Yeni dependency ekleme.

Offline-first yapıyı koru.

Mevcut Design System, renkler, typography, spacing, iconlar, kartlar, butonlar ve sidebar yapısını kullan.

Görev kapsamında olmayan ekranları değiştirme.

Mevcut öğrenci, sınıf ve rapor verilerini silme veya bozma.

Yeni özellikleri mümkün olan en küçük güvenli değişiklikle mevcut sisteme entegre et.

Referans Mentörlük tasarım görselindeki yapıyı ana görsel referans olarak kabul et. Mevcut MyEduApp Design System ile çelişen noktalar varsa mevcut Design System korunarak görsel yapı mümkün olduğunca aynı uygulanmalıdır.

1. SIDEBAR — MENTÖRLÜK

Öğretmen Platformu sidebarında Öğrenci Platformu ile Raporlar arasına:

Mentörlük

adında yeni bir menü ekle.

Sıra:

Ana Sayfa

Ders Platformu

Öğrenci Platformu

Mentörlük

Raporlar

Kullanım Kılavuzu

Ayarlar

Mentörlük aktif olduğunda mevcut active-state tasarımı kullanılmalı. Yeni dependency/icon paketi ekleme.

2. MENTÖRLÜK — SINIF SEÇİMİ

Mentörlük menüsüne ilk girildiğinde Mentörlük — Sınıf Seçimi ekranı açılmalı.

Göster:

Sayfa başlığı: Mentörlük

“Mentörlük yapılacak sınıfı seçin.”

Sınıf seçimi

Mevcut sınıflar

Sınıf adı

Akademik yıl

Şube

Öğrenci sayısı

Devam Et butonu

Mevcut sınıf seçildiğinde doğrudan o sınıfın Mentörlük çalışma alanına geçilebilmeli.

3. SINIF AKTARMA / OLUŞTURMA

Mentörlük sınıfı Öğrenci Platformunda mevcutsa yeniden oluşturulmasın.

İki seçenek destekle:

Mevcut Sınıfı Aktar

Öğrenci Platformundaki mevcut sınıflar listelensin.

Aktarımda:

sınıf bilgileri korunmalı,

öğrenciler korunmalı,

mevcut öğrenci kayıtları korunmalı,

duplicate öğrenci oluşmamalı.

Mümkünse mevcut sınıf/öğrenci kayıtlarına referans ver. Mevcut architecture bunu desteklemiyorsa en küçük güvenli uyarlamayı yap.

Yeni Sınıf Oluştur

Sınıf Öğrenci Platformunda yoksa mevcut sınıf oluşturma mantığını kullanarak:

Eğitim yılı

Sınıf

Şube
ile yeni sınıf oluştur.

4. MENTÖRLÜK ANA EKRANI

Sınıf seçildikten sonra Mentörlük — Takvim ve Etkinlikler ekranı açılmalı.

Üst bölüm:

Seçili sınıf

Öğrenci sayısı

Sınıf değiştirme

+ Yeni Etkinlik

Ana içerik:

Takvim

Önceki/sonraki ay

Bugün

Takvim görünümü

Liste görünümü

Yan/alt bölüm:
Bugünün Etkinlikleri

Alt bölümde:

Yaklaşan etkinlikler

Son davranış raporları

Referans görseldeki dashboard/card yaklaşımını kullan.

5. TAKVİM VE ETKİNLİKLER

Etkinlikler tarih ve saate bağlı olmalı.

Başlangıç etkinlik türleri:

Bireysel Görüşme

Grup Etkinliği

Davranış Raporu

Takvim kaydı:

tarih

saat

tür

öğrenci/grup

başlık

durum

göstermeli.

6. BİREYSEL ETKİNLİK

Yeni etkinlikte Bireysel seçildiğinde:

Öğrenci

Tarih

Saat

Etkinlik başlığı

Açıklama/not

Durum

alanları olmalı.

Durum:

Planlandı

Tamamlandı

Mevcut dialog/form componentlerini kullan.

7. GRUP ETKİNLİĞİ

Grup Etkinliği oluşturulabilmeli.

Alanlar:

Tarih

Saat

Başlık

Açıklama

Öğrenci seçimi

Öğrenci seçimi:

Tüm sınıf

Seçilen öğrenciler

olabilmeli.

Grup etkinliği takvimde tek etkinlik olarak gösterilmeli ve katılan öğrencilerin geçmişinde görünmeli.

8. ÖĞRENCİ DETAYI

Öğrenci seçildiğinde Mentörlük — Öğrenci Detayı açılmalı.

Üst:

Öğrenci adı

Sınıf

Öğrenci bilgisi

+ Etkinlik Ekle

Sekmeler:

Etkinlikler

Tarih, saat, tür, başlık ve durum ile geçmiş/planlanan etkinlikler.

Davranış Raporları

Öğrenciye ait davranış kayıtları.

Notlar

Mevcut architecture destekliyorsa mentörlük notları.

9. DAVRANIŞ RAPORU

Davranış raporu oluşturulabilmeli.

Alanlar:

Öğrenci

Tarih

Davranış türü

Davranış açıklaması

Gözlem/not

Gerekirse önem/seviye

Öğretmen notu

Mevcut davranış/kategori yapısı varsa yeniden oluşturma.

Başlangıç türleri, mevcut yapı yoksa:

Olumlu Davranış

Geliştirilmesi Gereken Davranış

Dikkat Gerektiren Durum

10. DAVRANIŞ RAPORLARI GÖRÜNÜMÜ

Mentörlük içinde Davranış Raporları görünümü bulunmalı.

Filtreler:

Sınıf

Öğrenci

Tarih aralığı

Davranış türü

Liste/tablo:
Öğrenci | Tarih | Davranış | Açıklama | Durum

Mevcut Raporlar altyapısı uygunsa yeni bir raporlama sistemi oluşturma; mevcut yapıyı genişlet.

11. RESPONSIVE / TABLET / TELEFON

Mentörlük desktop, tablet ve telefon ekranlarında sorunsuz çalışmalı.

Desktop:

Sidebar

Takvim

Etkinlik paneli

Tablet:

Mevcut sidebar hover/daraltma yapısına uyum

Takvim ve etkinlik panelinin uygun responsive düzeni

Telefon:

Mevcut mobile navigation/drawer

Yatay taşma olmamalı

Formlar ekran genişliğine uymalı

Öğrenci listeleri scroll edilebilir olmalı

Detaylar dikey yerleşebilmeli

Sabit genişliklerle responsive yapıyı bozma.

12. VERİ / OFFLINE-FIRST

Mentörlük offline-first çalışmalı.

Mevcut SQLite/database/repository/service/provider yapısı kullanılmalı.

İlişkiler:

Sınıf

Öğrenci

Etkinlik

Davranış raporu

doğru tutulmalı.

Duplicate kayıt oluşturma.

Yeni backend/API/cloud service ekleme.

13. NAVIGATION

Mentörlük ekranları arasında düzgün geri dönüş olmalı.

Akış:
Sınıf Seçimi
→ Mentörlük Ana Ekranı
→ Öğrenci Detayı
→ Etkinlik / Davranış Raporu

Mevcut navigation yaklaşımını kullan.

14. GÖRSEL TASARIM

Referans görseldeki şu ekranların görsel mantığını mümkün olduğunca aynı uygula:

Mentörlük — Sınıf Seçimi

Mentörlük — Takvim ve Etkinlikler

Mentörlük — Öğrenci Detayı

Mentörlük — Davranış Raporları

Sınıf Aktarımı / Yeni Sınıf Oluşturma

Özellikle:

sidebar

sayfa başlığı

breadcrumb

kartlar

filtre alanları

takvim

etkinlik kartları

öğrenci detay sekmeleri

rapor tablosu

primary/secondary button yapısı

aynı MyEduApp görsel diliyle uygulanmalı.

15. MEVCUT SİSTEMİ KORU

Kesinlikle bozulmaması gerekenler:

Ders Platformu

Öğrenci Platformu

Raporlar

Mevcut sınıflar

Mevcut öğrenciler

Mevcut kategoriler

Performans kayıtları

PDF/Excel export

Autosave

SQLite verileri

Sidebar

Routing

Mentörlük minimum müdahale ile eklenmeli.

16. UYGULAMA SIRASI

Önce yalnızca gerekli dosyaları analiz et:

Öğretmen sidebar/navigation

Sınıf modeli

Öğrenci modeli

Sınıf repository/service/provider

Rapor altyapısı

Mevcut takvim/date yapıları

Form/dialog/card/table componentleri

Responsive/tablet yapısı

Database schema

Sonra minimum değişiklikle uygula:

A. Sidebar + Mentörlük sınıf seçimi
B. Sınıf aktarımı/oluşturma
C. Mentörlük dashboard
D. Takvim
E. Bireysel etkinlik
F. Grup etkinliği
G. Öğrenci detay
H. Davranış raporları
I. Responsive uyarlama

17. KABUL KRİTERLERİ

Mentörlük sidebar menüsü doğru yerde.

Sınıf seçimi çalışıyor.

Mevcut sınıf aktarılabiliyor.

Duplicate öğrenci oluşmuyor.

Yeni sınıf oluşturulabiliyor.

Takvim çalışıyor.

Bireysel etkinlik çalışıyor.

Grup etkinliği çalışıyor.

Etkinlikler öğrenci geçmişinde görünüyor.

Öğrenci detay ekranı çalışıyor.

Davranış raporu oluşturulabiliyor.

Davranış raporları filtrelenebiliyor.

Desktop/tablet/telefon responsive.

SQLite/offline-first korunuyor.

Mevcut Öğrenci Platformu, Ders Platformu ve Raporlar bozulmuyor.

Yeni dependency eklenmiyor.

Gereksiz refactor yapılmıyor.

İlgili analyzer/test kontrolleri başarılı.

18. SON KONTROL

İşlem sonunda:

flutter analyze çalıştır.

Mentörlükle ilgili mevcut testleri çalıştır.

Yalnızca bu action kapsamındaki hataları düzelt.

Regresyon oluşturma.

Değiştirilen dosyaları kısa şekilde raporla.

Test/analyzer sonuçlarını raporla.