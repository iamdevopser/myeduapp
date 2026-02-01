param(
  [string]$CertPath = "build\msix\MyEduApp.cer"
)

if (-not (Test-Path $CertPath)) {
    Write-Host "HATA: Sertifika dosyası bulunamadı: $CertPath" -ForegroundColor Red
    Write-Host "Lütfen önce sertifikayı oluşturun:" -ForegroundColor Yellow
    Write-Host "  powershell -ExecutionPolicy Bypass -File tools\create_msix_cert.ps1" -ForegroundColor Cyan
    exit 1
}

Write-Host "Sertifika yükleniyor..." -ForegroundColor Green

# Sertifikayı Trusted Root Certification Authorities içine yükle
try {
    $cert = New-Object System.Security.Cryptography.X509Certificates.X509Certificate2($CertPath)
    $store = New-Object System.Security.Cryptography.X509Certificates.X509Store([System.Security.Cryptography.X509Certificates.StoreName]::Root, [System.Security.Cryptography.X509Certificates.StoreLocation]::LocalMachine)
    
    $store.Open([System.Security.Cryptography.X509Certificates.OpenFlags]::ReadWrite)
    $store.Add($cert)
    $store.Close()
    
    Write-Host "`n✓ Sertifika başarıyla yüklendi!" -ForegroundColor Green
    Write-Host "Artık MSIX paketini kurabilirsiniz:" -ForegroundColor Cyan
    Write-Host "  Add-AppxPackage `"D:\MyEduApp\build\windows\x64\runner\Release\my_edu_app.msix`"" -ForegroundColor White
} catch {
    Write-Host "`n✗ Otomatik yükleme başarısız oldu. Manuel yükleme deneyin:" -ForegroundColor Yellow
    Write-Host "`nYÖNTEM 1 - PowerShell ile (Yönetici olarak):" -ForegroundColor Cyan
    Write-Host "  Import-Certificate -FilePath `"$((Get-Item $CertPath).FullName)`" -CertStoreLocation Cert:\LocalMachine\Root" -ForegroundColor White
    Write-Host "`nYÖNTEM 2 - Windows Sertifika Yöneticisi ile:" -ForegroundColor Cyan
    Write-Host "  1. Windows tuşu + R > 'certlm.msc' yazın" -ForegroundColor White
    Write-Host "  2. 'Trusted Root Certification Authorities' > 'Certificates' klasörüne gidin" -ForegroundColor White
    Write-Host "  3. Sağ tıklayın > 'All Tasks' > 'Import...'" -ForegroundColor White
    Write-Host "  4. '$CertPath' dosyasını seçin ve 'Next' > 'Finish' yapın" -ForegroundColor White
    Write-Host "`nYÖNTEM 3 - Dosyaya sağ tıklayın:" -ForegroundColor Cyan
    Write-Host "  '$CertPath' dosyasına sağ tıklayın > 'Install Certificate' > 'Local Machine' > 'Trusted Root Certification Authorities'" -ForegroundColor White
    Write-Host "`nHata detayı: $_" -ForegroundColor Red
    exit 1
}

