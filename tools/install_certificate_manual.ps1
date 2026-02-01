# Bu script sertifikayı Windows Sertifika Yöneticisi üzerinden yükler
param(
  [string]$CertPath = "build\msix\MyEduApp.cer"
)

if (-not (Test-Path $CertPath)) {
    Write-Host "HATA: Sertifika dosyası bulunamadı: $CertPath" -ForegroundColor Red
    exit 1
}

Write-Host "Windows Sertifika Yöneticisi açılıyor..." -ForegroundColor Green
Write-Host "Lütfen şu adımları takip edin:" -ForegroundColor Yellow
Write-Host "1. 'Trusted Root Certification Authorities' > 'Certificates' klasörüne gidin" -ForegroundColor White
Write-Host "2. Sağ tıklayın > 'All Tasks' > 'Import...'" -ForegroundColor White
Write-Host "3. '$CertPath' dosyasını seçin" -ForegroundColor White
Write-Host "4. 'Next' > 'Finish' butonlarına tıklayın" -ForegroundColor White
Write-Host ""

# Sertifika Yöneticisi'ni aç
Start-Process certlm.msc

# Dosyayı da aç
Start-Process $CertPath

