# Bu script tek tıkla kurulum dosyası oluşturur
param([string]$OutputDir = "dist")

Write-Host "Tek tıkla kurulum dosyası oluşturuluyor..." -ForegroundColor Green

$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$rootDir = Split-Path -Parent $scriptDir
$distDir = Join-Path $rootDir $OutputDir

# Kurulum script'ini oluştur
$installScriptPath = Join-Path $distDir "KURULUM.ps1"
$installScript = @'
# MyEduApp - Otomatik Kurulum Script'i
# Bu script sertifikayı yükler, uygulamayı kurar ve açar

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "MyEduApp - Otomatik Kurulum" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# Mevcut dizini al
$scriptPath = $MyInvocation.MyCommand.Path
$scriptDir = Split-Path -Parent $scriptPath

# Dosya yolları
$certPath = Join-Path $scriptDir "MyEduApp.cer"
$msixPath = Join-Path $scriptDir "my_edu_app.msix"

# 1. Sertifika kontrolü ve yükleme
Write-Host "[1/3] Sertifika yükleniyor..." -ForegroundColor Yellow
if (Test-Path $certPath) {
    try {
        $cert = New-Object System.Security.Cryptography.X509Certificates.X509Certificate2($certPath)
        $store = New-Object System.Security.Cryptography.X509Certificates.X509Store([System.Security.Cryptography.X509Certificates.StoreName]::Root, [System.Security.Cryptography.X509Certificates.StoreLocation]::LocalMachine)
        $store.Open([System.Security.Cryptography.X509Certificates.OpenFlags]::ReadWrite)
        $store.Add($cert)
        $store.Close()
        Write-Host "       Sertifika başarıyla yüklendi!" -ForegroundColor Green
    } catch {
        Write-Host "       HATA: Sertifika yüklenemedi: $_" -ForegroundColor Red
        Write-Host "       Lütfen PowerShell'i YÖNETİCİ OLARAK çalıştırın!" -ForegroundColor Yellow
        Write-Host ""
        Write-Host "Devam etmek için bir tuşa basın..." -ForegroundColor Yellow
        $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
        exit 1
    }
} else {
    Write-Host "       HATA: Sertifika dosyası bulunamadı!" -ForegroundColor Red
    exit 1
}

# 2. MSIX kurulumu
Write-Host "[2/3] Uygulama kuruluyor..." -ForegroundColor Yellow
if (Test-Path $msixPath) {
    try {
        Add-AppxPackage -Path $msixPath -ErrorAction Stop
        Write-Host "       Uygulama başarıyla kuruldu!" -ForegroundColor Green
    } catch {
        Write-Host "       HATA: Kurulum başarısız: $_" -ForegroundColor Red
        Write-Host ""
        Write-Host "Devam etmek için bir tuşa basın..." -ForegroundColor Yellow
        $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
        exit 1
    }
} else {
    Write-Host "       HATA: MSIX dosyası bulunamadı!" -ForegroundColor Red
    exit 1
}

# 3. Uygulamayı aç
Write-Host "[3/3] Uygulama açılıyor..." -ForegroundColor Yellow
try {
    Start-Process "shell:AppsFolder\com.myeduapp.desktop_1.0.0.0_x64__*" -ErrorAction SilentlyContinue
    Write-Host "       Uygulama açıldı!" -ForegroundColor Green
} catch {
    # Alternatif yöntem
    $app = Get-AppxPackage | Where-Object { $_.Name -like "*myeduapp*" -or $_.PackageFamilyName -like "*myeduapp*" }
    if ($app) {
        $appId = (Get-AppxPackageManifest $app).package.applications.application.id
        Start-Process "shell:AppsFolder\$($app.PackageFamilyName)!$appId" -ErrorAction SilentlyContinue
        Write-Host "       Uygulama açıldı!" -ForegroundColor Green
    } else {
        Write-Host "       Uygulama kuruldu ancak otomatik açılamadı." -ForegroundColor Yellow
        Write-Host "       Lütfen Başlat menüsünden 'MyEduApp' uygulamasını açın." -ForegroundColor Yellow
    }
}

Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Kurulum tamamlandı!" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "Kapatmak için bir tuşa basın..." -ForegroundColor Yellow
$null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
'@

Set-Content -Path $installScriptPath -Value $installScript -Encoding UTF8
Write-Host "✓ Kurulum script'i oluşturuldu" -ForegroundColor Green

# Batch dosyası oluştur (kullanıcı buna çift tıklayacak)
$batchPath = Join-Path $distDir "KURULUMU_BASLAT.bat"
$batchContent = @"
@echo off
title MyEduApp - Kurulum
echo.
echo ========================================
echo MyEduApp - Otomatik Kurulum
echo ========================================
echo.
echo Bu kurulum için yonetici yetkisi gereklidir.
echo.
echo PowerShell yonetici olarak aciliyor...
echo.

REM PowerShell'i yönetici olarak aç ve kurulum script'ini çalıştır
powershell -ExecutionPolicy Bypass -NoProfile -Command "Start-Process powershell -ArgumentList '-ExecutionPolicy Bypass -NoProfile -File \"%~dp0KURULUM.ps1\"' -Verb RunAs"

timeout /t 2 >nul
"@

Set-Content -Path $batchPath -Value $batchContent -Encoding ASCII
Write-Host "✓ Batch dosyası oluşturuldu" -ForegroundColor Green

# README güncelle
$readmePath = Join-Path $distDir "KURULUM_TALIMATLARI.txt"
$readmeLines = @(
    "========================================",
    "MyEduApp - Kurulum Talimatlari",
    "========================================",
    "",
    "TEK TIKLA KURULUM (ONERILEN):",
    "------------------------------",
    "1. KURULUMU_BASLAT.bat dosyasina cift tiklayin",
    "2. Evet butonuna tiklayarak yonetici izni verin",
    "3. Kurulum otomatik olarak tamamlanacak ve uygulama acilacak",
    "",
    "NOT: Ilk kurulumda Windows guvenlik uyarisi cikabilir.",
    "     Daha fazla bilgi > Yine de calistir secenegini secin.",
    "",
    "========================================",
    "MANUEL KURULUM (Alternatif)",
    "========================================",
    "",
    "Eger otomatik kurulum calismazsa:",
    "",
    "1. SERTIFIKAYI YUKLEYIN:",
    "   - PowerShell'i YONETICI OLARAK acin",
    "   - Su komutu calistirin:",
    "     Import-Certificate -FilePath `"MyEduApp.cer`" -CertStoreLocation Cert:\LocalMachine\Root",
    "",
    "2. MSIX PAKETINI KURUN:",
    "   - my_edu_app.msix dosyasina cift tiklayin",
    "   - VEYA PowerShell ile:",
    "     Add-AppxPackage \"my_edu_app.msix\"",
    "",
    "3. UYGULAMAYI ACIN:",
    "   - Baslat menusunden MyEduApp uygulamasini acin",
    "",
    "========================================"
)

Set-Content -Path $readmePath -Value $readmeLines -Encoding UTF8
Write-Host "✓ README güncellendi" -ForegroundColor Green

Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Tek tıkla kurulum dosyası hazır!" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "Kullanım:" -ForegroundColor Yellow
Write-Host "  dist\KURULUMU_BASLAT.bat dosyasına çift tıklayın" -ForegroundColor White
Write-Host ""

