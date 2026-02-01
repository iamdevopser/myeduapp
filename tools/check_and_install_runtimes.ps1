# Bu script gerekli runtime'ları kontrol eder ve yükler
param([string]$DistDir = "dist")

Write-Host "Runtime gereksinimleri kontrol ediliyor..." -ForegroundColor Green

$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$rootDir = Split-Path -Parent $scriptDir
$distPath = Join-Path $rootDir $DistDir

# Runtime kontrol ve yükleme script'i oluştur
$runtimeScriptPath = Join-Path $distPath "RUNTIME_KONTROL.ps1"
$runtimeScript = @'
# MyEduApp - Runtime Gereksinimleri Kontrol ve Yükleme Script'i
# Bu script gerekli Windows runtime'larını kontrol eder ve eksik olanları yükler

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "MyEduApp - Runtime Kontrolü" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

$needsRestart = $false

# 1. Visual C++ Redistributable kontrolü
Write-Host "[1/4] Visual C++ Redistributable kontrol ediliyor..." -ForegroundColor Yellow
$vcRedistInstalled = $false

# VC++ 2015-2022 x64 kontrolü
$vcRedistKeys = @(
    "HKLM:\SOFTWARE\Microsoft\VisualStudio\14.0\VC\Runtimes\x64",
    "HKLM:\SOFTWARE\WOW6432Node\Microsoft\VisualStudio\14.0\VC\Runtimes\x64",
    "HKLM:\SOFTWARE\Classes\Installer\Dependencies\Microsoft.VS.VC_RuntimeMinimumVSU_amd64,v14"
)

foreach ($key in $vcRedistKeys) {
    if (Test-Path $key) {
        $vcRedistInstalled = $true
        break
    }
}

if (-not $vcRedistInstalled) {
    Write-Host "       Visual C++ Redistributable bulunamadı!" -ForegroundColor Red
    Write-Host "       Lütfen şu adresten indirip yükleyin:" -ForegroundColor Yellow
    Write-Host "       https://aka.ms/vs/17/release/vc_redist.x64.exe" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "       İndirme başlatılıyor..." -ForegroundColor Yellow
    
    $vcRedistUrl = "https://aka.ms/vs/17/release/vc_redist.x64.exe"
    $vcRedistPath = Join-Path $env:TEMP "vc_redist.x64.exe"
    
    try {
        Invoke-WebRequest -Uri $vcRedistUrl -OutFile $vcRedistPath -UseBasicParsing
        Write-Host "       İndirme tamamlandı. Kurulum başlatılıyor..." -ForegroundColor Green
        Start-Process -FilePath $vcRedistPath -ArgumentList "/quiet /norestart" -Wait
        Write-Host "       Visual C++ Redistributable yüklendi!" -ForegroundColor Green
        $needsRestart = $true
    } catch {
        Write-Host "       HATA: İndirme/kurulum başarısız: $_" -ForegroundColor Red
        Write-Host "       Lütfen manuel olarak yükleyin." -ForegroundColor Yellow
    }
} else {
    Write-Host "       Visual C++ Redistributable yüklü!" -ForegroundColor Green
}

# 2. .NET Runtime kontrolü (Flutter için gerekli olabilir)
Write-Host "[2/4] .NET Runtime kontrol ediliyor..." -ForegroundColor Yellow
$dotNetInstalled = $false

$dotNetKeys = @(
    "HKLM:\SOFTWARE\Microsoft\NET Framework Setup\NDP\v4\Full",
    "HKLM:\SOFTWARE\WOW6432Node\Microsoft\NET Framework Setup\NDP\v4\Full"
)

foreach ($key in $dotNetKeys) {
    if (Test-Path $key) {
        $release = (Get-ItemProperty $key -ErrorAction SilentlyContinue).Release
        if ($release -and $release -ge 461808) {
            $dotNetInstalled = $true
            break
        }
    }
}

if (-not $dotNetInstalled) {
    Write-Host "       .NET Framework 4.7.2 veya üzeri bulunamadı!" -ForegroundColor Yellow
    Write-Host "       (Çoğu Windows 10/11'de zaten yüklüdür)" -ForegroundColor Gray
} else {
    Write-Host "       .NET Framework yüklü!" -ForegroundColor Green
}

# 3. Windows App Runtime kontrolü (MSIX için)
Write-Host "[3/4] Windows App Runtime kontrol ediliyor..." -ForegroundColor Yellow
$appRuntimeInstalled = Get-AppxPackage -Name "Microsoft.WindowsAppRuntime" -ErrorAction SilentlyContinue

if (-not $appRuntimeInstalled) {
    Write-Host "       Windows App Runtime bulunamadı!" -ForegroundColor Yellow
    Write-Host "       Windows Store'dan yükleniyor..." -ForegroundColor Yellow
    
    try {
        Start-Process "ms-windows-store://pdp/?ProductId=9N5Q1JPMB4MP" -ErrorAction SilentlyContinue
        Write-Host "       Windows Store açıldı. Lütfen 'Al' butonuna tıklayın." -ForegroundColor Cyan
    } catch {
        Write-Host "       Windows Store açılamadı. Manuel olarak yükleyin." -ForegroundColor Yellow
    }
} else {
    Write-Host "       Windows App Runtime yüklü!" -ForegroundColor Green
}

# 4. Flutter Engine dosyaları kontrolü
Write-Host "[4/4] Flutter Engine dosyaları kontrol ediliyor..." -ForegroundColor Yellow
$flutterEnginePath = Join-Path $PSScriptRoot "flutter_windows.dll"
if (Test-Path $flutterEnginePath) {
    Write-Host "       Flutter Engine dosyaları mevcut!" -ForegroundColor Green
} else {
    Write-Host "       UYARI: Flutter Engine dosyaları bulunamadı!" -ForegroundColor Red
    Write-Host "       Uygulama çalışmayabilir!" -ForegroundColor Red
}

Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
if ($needsRestart) {
    Write-Host "Bazı runtime'lar yüklendi. Sistem yeniden başlatılmalı." -ForegroundColor Yellow
    Write-Host "Yeniden başlatmak ister misiniz? (E/H)" -ForegroundColor Yellow
    $response = Read-Host
    if ($response -eq "E" -or $response -eq "e") {
        Restart-Computer -Force
    }
} else {
    Write-Host "Runtime kontrolü tamamlandı!" -ForegroundColor Green
}
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "Devam etmek için bir tuşa basın..." -ForegroundColor Yellow
$null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
'@

Set-Content -Path $runtimeScriptPath -Value $runtimeScript -Encoding UTF8
Write-Host "✓ Runtime kontrol script'i oluşturuldu" -ForegroundColor Green

# KURULUM.ps1'i güncelle - önce runtime kontrolü yapsın
$installScriptPath = Join-Path $distPath "KURULUM.ps1"
if (Test-Path $installScriptPath) {
    $installContent = Get-Content $installScriptPath -Raw
    
    # Runtime kontrolünü başa ekle
    $newInstallContent = @"
# MyEduApp - Otomatik Kurulum Script'i
# Bu script önce runtime'ları kontrol eder, sonra sertifikayı yükler, uygulamayı kurar ve açar

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "MyEduApp - Otomatik Kurulum" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# Mevcut dizini al
`$scriptPath = `$MyInvocation.MyCommand.Path
`$scriptDir = Split-Path -Parent `$scriptPath

# Runtime kontrolü
`$runtimeScript = Join-Path `$scriptDir "RUNTIME_KONTROL.ps1"
if (Test-Path `$runtimeScript) {
    Write-Host "[0/4] Runtime gereksinimleri kontrol ediliyor..." -ForegroundColor Yellow
    & `$runtimeScript
    Write-Host ""
}

# Dosya yolları
`$certPath = Join-Path `$scriptDir "MyEduApp.cer"
`$msixPath = Join-Path `$scriptDir "my_edu_app.msix"

# 1. Sertifika kontrolü ve yükleme
Write-Host "[1/4] Sertifika yükleniyor..." -ForegroundColor Yellow
if (Test-Path `$certPath) {
    try {
        `$cert = New-Object System.Security.Cryptography.X509Certificates.X509Certificate2(`$certPath)
        `$store = New-Object System.Security.Cryptography.X509Certificates.X509Store([System.Security.Cryptography.X509Certificates.StoreName]::Root, [System.Security.Cryptography.X509Certificates.StoreLocation]::LocalMachine)
        `$store.Open([System.Security.Cryptography.X509Certificates.OpenFlags]::ReadWrite)
        `$store.Add(`$cert)
        `$store.Close()
        Write-Host "       Sertifika başarıyla yüklendi!" -ForegroundColor Green
    } catch {
        Write-Host "       HATA: Sertifika yüklenemedi: `$_" -ForegroundColor Red
        Write-Host "       Lütfen PowerShell'i YÖNETİCİ OLARAK çalıştırın!" -ForegroundColor Yellow
        Write-Host ""
        Write-Host "Devam etmek için bir tuşa basın..." -ForegroundColor Yellow
        `$null = `$Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
        exit 1
    }
} else {
    Write-Host "       HATA: Sertifika dosyası bulunamadı!" -ForegroundColor Red
    exit 1
}

# 2. MSIX kurulumu
Write-Host "[2/4] Uygulama kuruluyor..." -ForegroundColor Yellow
if (Test-Path `$msixPath) {
    try {
        Add-AppxPackage -Path `$msixPath -ErrorAction Stop
        Write-Host "       Uygulama başarıyla kuruldu!" -ForegroundColor Green
    } catch {
        Write-Host "       HATA: Kurulum başarısız: `$_" -ForegroundColor Red
        Write-Host ""
        Write-Host "Devam etmek için bir tuşa basın..." -ForegroundColor Yellow
        `$null = `$Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
        exit 1
    }
} else {
    Write-Host "       HATA: MSIX dosyası bulunamadı!" -ForegroundColor Red
    exit 1
}

# 3. Uygulamayı aç
Write-Host "[3/4] Uygulama açılıyor..." -ForegroundColor Yellow
Start-Sleep -Seconds 2

try {
    # MSIX uygulamasını aç
    `$package = Get-AppxPackage | Where-Object { `$_.Name -like "*myeduapp*" -or `$_.PackageFamilyName -like "*myeduapp*" }
    if (`$package) {
        `$manifest = [xml](Get-AppxPackageManifest `$package)
        `$appId = `$manifest.Package.Applications.Application.Id
        `$appPath = "shell:AppsFolder\$(`$package.PackageFamilyName)!`$appId"
        Start-Process `$appPath -ErrorAction SilentlyContinue
        Write-Host "       Uygulama açıldı!" -ForegroundColor Green
    } else {
        Write-Host "       UYARI: Uygulama bulunamadı. Başlat menüsünden açın." -ForegroundColor Yellow
    }
} catch {
    Write-Host "       UYARI: Uygulama otomatik açılamadı." -ForegroundColor Yellow
    Write-Host "       Lütfen Başlat menüsünden 'MyEduApp' uygulamasını açın." -ForegroundColor Yellow
}

Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Kurulum tamamlandı!" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "Kapatmak için bir tuşa basın..." -ForegroundColor Yellow
`$null = `$Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
"@

    Set-Content -Path $installScriptPath -Value $newInstallContent -Encoding UTF8
    Write-Host "✓ Kurulum script'i güncellendi" -ForegroundColor Green
}

Write-Host ""
Write-Host "Runtime kontrol script'i hazir!" -ForegroundColor Green

