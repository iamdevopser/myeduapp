# MyEduApp - Veritabani Temizleme Script'i
# Eski veritabani dosyasini siler, uygulama yeni veritabani olusturur

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "MyEduApp - Veritabani Temizleme" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "UYARI: Bu islem veritabani dosyasini siler!" -ForegroundColor Yellow
Write-Host "Tum veriler (siniflar, dersler, icerikler) silinecek." -ForegroundColor Yellow
Write-Host "Dosyalar (PDF, resim vb.) silinmez, sadece veritabani kayitlari silinir." -ForegroundColor Cyan
Write-Host ""
Write-Host "Devam etmek istiyor musunuz? (E/H)" -ForegroundColor Yellow
$response = Read-Host

if ($response -ne "E" -and $response -ne "e") {
    Write-Host "Islem iptal edildi." -ForegroundColor Gray
    exit 0
}

Write-Host ""
Write-Host "Veritabani dosyasi araniyor..." -ForegroundColor Yellow

# Kullanici Documents klasorunde ara
$dbPath = Join-Path ([Environment]::GetFolderPath("MyDocuments")) "MyEduAppData\myeduapp.sqlite"
$dbDir = Split-Path $dbPath -Parent

if (Test-Path $dbPath) {
    Write-Host "       Veritabani bulundu: $dbPath" -ForegroundColor Cyan
    
    # Yedek al (opsiyonel)
    $backupPath = "$dbPath.backup_$(Get-Date -Format 'yyyyMMdd_HHmmss')"
    try {
        Copy-Item $dbPath $backupPath -ErrorAction Stop
        Write-Host "       Yedek olusturuldu: $backupPath" -ForegroundColor Green
    } catch {
        Write-Host "       UYARI: Yedek olusturulamadi: $_" -ForegroundColor Yellow
    }
    
    # Veritabani dosyasini sil
    try {
        Remove-Item $dbPath -Force -ErrorAction Stop
        Write-Host "       ✓ Veritabani dosyasi silindi!" -ForegroundColor Green
        Write-Host ""
        Write-Host "Uygulamayi acin, yeni veritabani otomatik olusturulacak." -ForegroundColor Cyan
    } catch {
        Write-Host "       ✗ HATA: Veritabani silinemedi: $_" -ForegroundColor Red
        Write-Host "       Uygulama acik olabilir, once kapatip tekrar deneyin." -ForegroundColor Yellow
        exit 1
    }
} else {
    Write-Host "       Veritabani dosyasi bulunamadi: $dbPath" -ForegroundColor Yellow
    Write-Host "       Uygulama henuz calistirilmamis olabilir." -ForegroundColor Cyan
    Write-Host "       Normal - uygulama ilk acilista otomatik olusturur." -ForegroundColor Cyan
}

Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Tamamlandi!" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "Kapatmak icin bir tusa basin..." -ForegroundColor Yellow
$null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
