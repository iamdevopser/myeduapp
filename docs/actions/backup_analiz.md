MyEduApp projesindeki mevcut Backup/Restore sistemini kapsamlı şekilde analiz et.

Şimdilik HİÇBİR KODU DEĞİŞTİRME.

Amaç:
Windows'ta oluşturulan bir backup dosyasının Android APK üzerinde sorunsuz şekilde Restore edilebilmesini sağlamak.

Özellikle aşağıdakileri incele:

1. Backup işleminin hangi dosyaları/verileri yedeklediğini tespit et.
2. SQLite database dosyasının konumunu ve oluşturulma yöntemini tespit et.
3. Öğrenci fotoğrafları, sınıf/ders görselleri, materyaller, PDF, Word, audio, video, weblink ve diğer attachment dosyalarının nerede tutulduğunu tespit et.
4. Backup sırasında yalnızca database mi yoksa dosya sistemi verileri de mi yedekleniyor belirle.
5. Restore işleminin mevcut çalışma şeklini analiz et.
6. Windows ve Android arasında kullanılan dosya yollarının platform bağımlı olup olmadığını kontrol et.
7. Mutlak Windows path'lerinin backup içine kaydedilip kaydedilmediğini kontrol et.
8. Android sandbox/path yapısına uygun olmayan herhangi bir restore işlemi olup olmadığını belirle.
9. Restore sırasında SQLite bağlantısının kapatılıp kapatılmadığını kontrol et.
10. Restore sonrasında database bağlantısının yeniden açılıp açılmadığını kontrol et.
11. Flutter uygulama state'inin restore sonrası yenilenip yenilenmediğini kontrol et.
12. Database schema/version/migration uyumluluğunu kontrol et.
13. Android APK ile Windows arasında backup formatı açısından herhangi bir uyumsuzluk olup olmadığını belirle.
14. Kullanıcının seçtiği backup dosyasının Android'de erişilebilir bir temporary/app-controlled alana kopyalanıp kopyalanmadığını kontrol et.
15. Restore sırasında dosya izinleri ve Android storage restrictions açısından sorun olup olmadığını kontrol et.
16. Backup dosyasının bütünlüğünün doğrulanıp doğrulanmadığını kontrol et.
17. Bozuk/eksik backup durumunda güvenli rollback mekanizması olup olmadığını kontrol et.

Özellikle şu dosyaları ve servisleri bul ve incele:

* database_helper.dart
* backup service
* restore service
* file/storage service
* attachment/file management
* ilgili repository/service sınıfları
* pubspec.yaml'daki ilgili paketler

Analizin sonunda şu başlıklarla rapor oluştur:

A. Mevcut Backup Sistemi
B. Mevcut Restore Sistemi
C. Windows → Android Uyumluluk Sorunları
D. Eksik veya Riskli Noktalar
E. Önerilen Backup Formatı
F. Önerilen Restore Akışı
G. Değiştirilmesi gereken dosyalar
H. Gerekli yeni paketler varsa neden gerekli oldukları
I. Veri kaybını önlemek için alınması gereken önlemler
J. Test edilmesi gereken senaryolar

ÖNEMLİ:

* Kod değiştirme.
* Yeni dosya oluşturma.
* Yeni paket ekleme.
* Mevcut mimariyi değiştirme.
* Sadece mevcut sistemi analiz et ve uygulanabilir bir düzeltme planı hazırla.
* Mevcut çalışan özellikleri bozacak gereksiz değişiklik önermemeye dikkat et.
* Sonuçta önce mevcut durum ile hedef durum arasındaki farkı açıkça göster.
