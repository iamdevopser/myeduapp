param(
  [string]$CertPath = "build\msix\MyEduApp.pfx",
  [string]$Password = "MyEduApp123!"
)

Write-Host "MSIX paketi oluşturuluyor..." -ForegroundColor Green

# Bağımlılıkları yükle
flutter pub get

# Windows release build
Write-Host "Windows release build oluşturuluyor..." -ForegroundColor Yellow
flutter build windows --release

# MSIX paketini oluştur
Write-Host "MSIX paketi oluşturuluyor..." -ForegroundColor Yellow
dart run msix:create `
  --certificate-path "$CertPath" `
  --certificate-password "$Password"

# MSIX dosyasını bul ve göster
$msixFile = Get-ChildItem -Path "." -Filter "*.msix" -Recurse -ErrorAction SilentlyContinue | Select-Object -First 1

if ($msixFile) {
    Write-Host "`nMSIX paketi başarıyla oluşturuldu!" -ForegroundColor Green
    Write-Host "Konum: $($msixFile.FullName)" -ForegroundColor Cyan
    Write-Host "`nKurulum için:" -ForegroundColor Yellow
    Write-Host "1. Önce sertifikayı yükleyin (Yönetici yetkisi gerekir):" -ForegroundColor White
    Write-Host "   powershell -ExecutionPolicy Bypass -File tools\install_certificate.ps1" -ForegroundColor Cyan
    Write-Host "2. Sonra MSIX'i kurun:" -ForegroundColor White
    Write-Host "   Add-AppxPackage `"$($msixFile.FullName)`"" -ForegroundColor Cyan
} else {
    Write-Host "`nUYARI: MSIX dosyası bulunamadı!" -ForegroundColor Red
    Write-Host "Lütfen hata mesajlarını kontrol edin." -ForegroundColor Yellow
}

