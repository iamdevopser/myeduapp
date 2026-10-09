MyEduApp projesinde sadece **Report → Export PDF** çıktısındaki localization/translation sorununu düzelt ve raporun en üstüne aşağıdaki bilgilendirme cümlesini ekle.

Önce mevcut PDF export kodunu ve kullanılan localization/translation yapısını analiz et. **Yeni bir sistem oluşturma, mevcut veri akışını veya rapor hesaplamalarını değiştirme.**

### 1. PDF English localization düzeltmeleri

PDF English olarak export edildiğinde aşağıdaki Türkçe metinler kesinlikle İngilizce görünmeli:

* Özet → Summary
* Günlük Ortalama → Daily Average
* Aylık Performans → Monthly Performance
* Aylık Kategori Ortalamaları → Monthly Category Averages
* Aktiviteler → Activities
* Materyaller → Materials
* Eylül → September

PDF içerisinde tarih/ay/kategori gibi alanlarda Türkçe kalan başka sistem tarafından üretilen sabit metinler varsa, mevcut localization sistemini kullanarak English karşılıklarını kullan.

### 2. Raporun en üstüne bilgilendirme cümlesi ekle

PDF raporunun en başında bulunan:

**MyEduApp**

başlığının hemen altına bir bilgilendirme cümlesi ekle.

Bu cümle, raporun seçilen diline göre localization sisteminden gelmeli.

**English PDF:**
"The average grade shown under Monthly Performance will be added as the Activity grade to the MyEducare and Sice electronic catalogs."

**Türkçe PDF:**
"Aylık Performans bölümünde gösterilen ortalama not, MyEducare ve Sice elektronik kataloglarına Aktivite notu olarak eklenecektir."

Bu cümle:

* `MyEduApp` başlığının hemen altında bulunmalı.
* Raporun geri kalan içeriğinden görsel olarak ayrılmalı.
* Mevcut PDF layout'unu bozmayacak şekilde uygun font size/spacing kullanılmalı.
* Sayfanın en üstünde görünmeli.
* Raporun diğer bölümlerinden önce gelmeli.
* Cümle PDF'nin seçilen diline göre otomatik değişmeli.
* Hard-coded olarak yalnızca tek bir dile bağlı kalmamalı; mevcut localization yapısı kullanılmalı.

### 3. Kullanıcı verileri ile sistem metinlerini ayır

ÖNEMLİ:

* Kullanıcı tarafından girilmiş öğrenci adı, aktivite adı, materyal adı, not vb. verileri otomatik olarak çevirmeye çalışma.
* Örneğin `Bu kim?`, `Kelimeler`, `Materyal` gibi kullanıcı verileri aynen kalmalı.
* `Aktiviteler` ve `Materyaller` gibi uygulamanın kendi kategori adları localization kapsamında çevrilmeli.
* `Eylül` gibi ay isimleri locale üzerinden üretilmeli; hard-coded Türkçe ay isimleri kullanılmamalı.

### 4. Mevcut sistemi koru

* PDF'nin Türkçe export davranışını bozma.
* English export seçildiğinde tüm sistem başlıkları ve sabit metinler English olmalı.
* Mevcut PDF layout, fontlar, tablo yapısı, hesaplamalar, puanlar, tarih aralığı ve rapor içeriği değişmemeli.
* Mevcut database/data flow/migration yapısına dokunma.
* Gereksiz refactor yapma.
* Yeni package ekleme.
* Mevcut localization mimarisini kullan.

### 5. Kontrol

Önce ilgili dosyaları bul ve hangi kodun PDF başlıklarını/metinlerini oluşturduğunu tespit et. Sonra yalnızca gerekli dosyalarda minimal değişiklik yap.

Kontrol et:

1. Report → Export PDF → English
2. `MyEduApp` başlığının hemen altında English bilgilendirme cümlesinin bulunduğunu doğrula.
3. Yukarıdaki tüm başlıkların English olduğunu doğrula.
4. `September`, `Activities`, `Materials` gibi sistem metinlerinin English olduğunu doğrula.
5. Kullanıcı tarafından girilen içeriklerin değiştirilmediğini doğrula.
6. Report → Export PDF → Turkish
7. Türkçe bilgilendirme cümlesinin doğru göründüğünü doğrula.
8. Türkçe başlıkların ve ay isimlerinin Türkçe kaldığını doğrula.
9. `flutter analyze` çalıştır.
10. İlgili mevcut testler varsa çalıştır.

İşlem sonunda:

* Değiştirilen dosyaları listele.
* Sorunun kaynağını 1-2 cümleyle açıkla.
* Yapılan düzeltmeleri listele.
* Analyze/test sonucunu belirt.
* APK oluşturma işlemi yapma; önce kod doğrulamasını tamamla.
