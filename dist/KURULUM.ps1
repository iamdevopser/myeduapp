# MyEduApp - Otomatik Kurulum Script'i
# Bu script runtime'lari kontrol eder, sertifikayi yukler, uygulamayi kurar ve acar
# Tek EXE kurulum (Inno) veya KURULUMU_BASLAT.bat ile calistirilir.

[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
$OutputEncoding = [System.Text.Encoding]::UTF8
chcp 65001 | Out-Null

# Yonetici kontrolu (sertifika + MSIX kurulumu icin gerekli)
$isAdmin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
if (-not $isAdmin) {
    Write-Host "HATA: Bu script YONETICI yetkisiyle calistirilmalidir." -ForegroundColor Red
    Write-Host "KURULUMU_BASLAT.bat kullanin veya PowerShell'i sag tik -> Yonetici olarak calistir." -ForegroundColor Yellow
    $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
    exit 1
}

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "MyEduApp - Otomatik Kurulum" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# Mevcut dizini al (script ile ayni klasorde .cer ve .msix olmali)
$scriptPath = $MyInvocation.MyCommand.Path
$scriptDir = Split-Path -Parent $scriptPath

# 0. Runtime kontrolü ve yükleme
Write-Host "[0/5] Runtime gereksinimleri kontrol ediliyor..." -ForegroundColor Yellow

# Visual C++ Redistributable kontrolü
$vcRedistInstalled = $false
$vcRedistKeys = @(
    "HKLM:\SOFTWARE\Microsoft\VisualStudio\14.0\VC\Runtimes\x64",
    "HKLM:\SOFTWARE\WOW6432Node\Microsoft\VisualStudio\14.0\VC\Runtimes\x64",
    "HKLM:\SOFTWARE\Microsoft\VisualStudio\15.0\VC\Runtimes\x64",
    "HKLM:\SOFTWARE\WOW6432Node\Microsoft\VisualStudio\15.0\VC\Runtimes\x64"
)

foreach ($key in $vcRedistKeys) {
    if (Test-Path $key) {
        $vcRedistInstalled = $true
        break
    }
}

if (-not $vcRedistInstalled) {
    Write-Host "       Visual C++ Redistributable bulunamadi!" -ForegroundColor Red
    Write-Host "       Indiriliyor ve yukleniyor..." -ForegroundColor Yellow
    
    $vcRedistUrl = "https://aka.ms/vs/17/release/vc_redist.x64.exe"
    $vcRedistPath = Join-Path $env:TEMP "vc_redist.x64.exe"
    
    try {
        Write-Host "       Indirme baslatiliyor..." -ForegroundColor Cyan
        Invoke-WebRequest -Uri $vcRedistUrl -OutFile $vcRedistPath -UseBasicParsing -ErrorAction Stop
        Write-Host "       Kurulum baslatiliyor (sessiz mod)..." -ForegroundColor Cyan
        $process = Start-Process -FilePath $vcRedistPath -ArgumentList "/quiet /norestart" -Wait -PassThru
        if ($process.ExitCode -eq 0 -or $process.ExitCode -eq 3010) {
            Write-Host "       Visual C++ Redistributable yuklendi!" -ForegroundColor Green
        } else {
            Write-Host "       UYARI: Kurulum kodu: $($process.ExitCode)" -ForegroundColor Yellow
        }
    } catch {
        Write-Host "       HATA: Indirme/kurulum basarisiz: $_" -ForegroundColor Red
        Write-Host "       Lutfen manuel olarak yukleyin:" -ForegroundColor Yellow
        Write-Host "       https://aka.ms/vs/17/release/vc_redist.x64.exe" -ForegroundColor Cyan
    }
} else {
    Write-Host "       Visual C++ Redistributable yuklu!" -ForegroundColor Green
}

# Dosya yazma izinleri testi
Write-Host "       Dosya yazma izinleri test ediliyor..." -ForegroundColor Yellow
try {
    $testPath = [Environment]::GetFolderPath("MyDocuments")
    $testFile = Join-Path $testPath "MyEduAppData\test_write.txt"
    $testDir = Split-Path $testFile -Parent
    
    if (-not (Test-Path $testDir)) {
        New-Item -ItemType Directory -Path $testDir -Force | Out-Null
    }
    
    "test" | Out-File -FilePath $testFile -Encoding UTF8 -ErrorAction Stop
    Remove-Item $testFile -Force -ErrorAction SilentlyContinue
    Write-Host "       Dosya yazma izinleri OK!" -ForegroundColor Green
} catch {
    Write-Host "       UYARI: Dosya yazma testi basarisiz: $_" -ForegroundColor Yellow
    Write-Host "       Uygulama veri klasoru olusturamayabilir!" -ForegroundColor Yellow
}

Write-Host ""

# Dosya yolları
$certPath = Join-Path $scriptDir "MyEduApp.cer"
$msixPath = Join-Path $scriptDir "my_edu_app.msix"

# 1. Sertifika kontrolü ve yükleme
Write-Host "[1/6] Sertifika yukleniyor..." -ForegroundColor Yellow
if (Test-Path $certPath) {
    try {
        $cert = New-Object System.Security.Cryptography.X509Certificates.X509Certificate2($certPath)
        $store = New-Object System.Security.Cryptography.X509Certificates.X509Store([System.Security.Cryptography.X509Certificates.StoreName]::Root, [System.Security.Cryptography.X509Certificates.StoreLocation]::LocalMachine)
        $store.Open([System.Security.Cryptography.X509Certificates.OpenFlags]::ReadWrite)
        $store.Add($cert)
        $store.Close()
        Write-Host "       Sertifika basariyla yuklendi!" -ForegroundColor Green
    } catch {
        Write-Host "       HATA: Sertifika yuklenemedi: $_" -ForegroundColor Red
        Write-Host "       Lutfen PowerShell'i YONETICI OLARAK calistirin!" -ForegroundColor Yellow
        Write-Host ""
        Write-Host "Devam etmek icin bir tusa basin..." -ForegroundColor Yellow
        $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
        exit 1
    }
} else {
    Write-Host "       HATA: Sertifika dosyasi bulunamadi!" -ForegroundColor Red
    exit 1
}

# 2. Eski veritabanı dosyasını temizle (eski şema sorunlarını önlemek için)
Write-Host "[1.5/6] Eski veritabani kontrol ediliyor..." -ForegroundColor Yellow
$dbPath = Join-Path ([Environment]::GetFolderPath("MyDocuments")) "MyEduAppData\myeduapp.sqlite"
if (Test-Path $dbPath) {
    Write-Host "       Eski veritabani bulundu, temizleniyor..." -ForegroundColor Yellow
    try {
        # Yedek al
        $backupPath = "$dbPath.backup_$(Get-Date -Format 'yyyyMMdd_HHmmss')"
        Copy-Item $dbPath $backupPath -ErrorAction SilentlyContinue
        if (Test-Path $backupPath) {
            Write-Host "       Yedek olusturuldu: $backupPath" -ForegroundColor Cyan
        }
        # Veritabanını sil
        Remove-Item $dbPath -Force -ErrorAction Stop
        Write-Host "       ✓ Eski veritabani temizlendi (yeni veritabani otomatik olusturulacak)" -ForegroundColor Green
    } catch {
        Write-Host "       UYARI: Veritabani temizlenemedi (uygulama acik olabilir): $_" -ForegroundColor Yellow
        Write-Host "       Normal - yeni veritabani olusturulacak" -ForegroundColor Cyan
    }
} else {
    Write-Host "       Eski veritabani bulunamadi (normal)." -ForegroundColor Green
}

# 3. Eski kurulumu kaldır (varsa) - ÖNCE BUNU YAP - TÜM KULLANICILAR İÇİN
Write-Host "[2/6] Eski kurulumlar kontrol ediliyor..." -ForegroundColor Yellow
try {
    # Önce tüm kullanıcılar için provisioned paketi kaldır
    Write-Host "       Tum kullanicilar icin eski kurulum kontrol ediliyor..." -ForegroundColor Cyan
    try {
        $provisionedPackages = Get-AppxProvisionedPackage -Online | Where-Object { 
            $_.DisplayName -like "*myeduapp*" -or $_.PackageName -like "*myeduapp*"
        }
        
        foreach ($provisioned in $provisionedPackages) {
            Write-Host "       Provisioned paket bulundu: $($provisioned.DisplayName)" -ForegroundColor Yellow
            try {
                Remove-AppxProvisionedPackage -Online -PackageName $provisioned.PackageName -ErrorAction Stop
                Write-Host "       Provisioned paket kaldirildi: $($provisioned.DisplayName)" -ForegroundColor Green
            } catch {
                Write-Host "       UYARI: Provisioned paket kaldirilamadi: $_" -ForegroundColor Yellow
            }
        }
    } catch {
        Write-Host "       UYARI: Provisioned paket kontrolu basarisiz (normal olabilir): $_" -ForegroundColor Yellow
    }
    
    # Şimdi mevcut kullanıcı için kurulu paketleri kaldır
    $oldPackage = Get-AppxPackage | Where-Object { $_.Name -like "*myeduapp*" -or $_.PackageFamilyName -like "*myeduapp*" }
    if ($oldPackage) {
        Write-Host "       Mevcut kullanici icin eski kurulum bulundu, kaldiriliyor..." -ForegroundColor Yellow
        foreach ($pkg in $oldPackage) {
            try {
                Write-Host "       Kaldiriliyor: $($pkg.Name) ($($pkg.PackageFullName))" -ForegroundColor Cyan
                Remove-AppxPackage -Package $pkg.PackageFullName -ErrorAction Stop
                Write-Host "       Eski kurulum kaldirildi: $($pkg.Name)" -ForegroundColor Green
            } catch {
                Write-Host "       UYARI: Eski kurulum kaldirilamadi: $($pkg.Name) - $_" -ForegroundColor Yellow
                # Zorla kaldırma dene
                try {
                    Write-Host "       Zorla kaldirma deneniyor..." -ForegroundColor Cyan
                    Remove-AppxPackage -Package $pkg.PackageFullName -AllUsers -ErrorAction Stop
                    Write-Host "       Zorla kaldirma basarili!" -ForegroundColor Green
                } catch {
                    Write-Host "       Zorla kaldirma da basarisiz: $_" -ForegroundColor Red
                }
            }
        }
        Write-Host "       Eski kurulumlar temizleniyor, bekleniyor..." -ForegroundColor Cyan
        Start-Sleep -Seconds 5
        
        # Tekrar kontrol et
        $remainingPackages = Get-AppxPackage | Where-Object { $_.Name -like "*myeduapp*" -or $_.PackageFamilyName -like "*myeduapp*" }
        if ($remainingPackages) {
            Write-Host "       UYARI: Hala eski paket bulunuyor, manuel kaldirma gerekebilir" -ForegroundColor Yellow
            foreach ($rem in $remainingPackages) {
                Write-Host "         Kalan paket: $($rem.PackageFullName)" -ForegroundColor Yellow
            }
        } else {
            Write-Host "       Tum eski kurulumlar temizlendi!" -ForegroundColor Green
        }
    } else {
        Write-Host "       Eski kurulum bulunamadi." -ForegroundColor Green
    }
} catch {
    Write-Host "       UYARI: Eski kurulum kontrolu basarisiz: $_" -ForegroundColor Yellow
}

# 3. MSIX kurulumu
Write-Host "[3/5] Uygulama kuruluyor..." -ForegroundColor Yellow
if (Test-Path $msixPath) {
    try {
        Write-Host "       MSIX dosyasi bulundu: $msixPath" -ForegroundColor Cyan
        Write-Host "       Kurulum baslatiliyor..." -ForegroundColor Cyan
        
        # MSIX kurulumunu çalıştır
        $result = Add-AppxPackage -Path $msixPath -ErrorAction Stop
        
        # Kurulum sonrası doğrulama - daha uzun bekle ve tekrar kontrol et
        Write-Host "       Kurulum tamamlandi, dogrulanıyor..." -ForegroundColor Cyan
        Start-Sleep -Seconds 5
        
        # Tüm kullanıcılar için kontrol et
        $installedPackage = $null
        $maxRetries = 5
        $retryCount = 0
        
        while ($retryCount -lt $maxRetries -and -not $installedPackage) {
            $installedPackage = Get-AppxPackage | Where-Object { 
                $_.Name -like "*myeduapp*" -or 
                $_.PackageFamilyName -like "*myeduapp*" -or
                $_.Name -like "*MyEduApp*"
            } | Select-Object -First 1
            
            if (-not $installedPackage) {
                $retryCount++
                Write-Host "       Paket kontrolu ($retryCount/$maxRetries)..." -ForegroundColor Yellow
                Start-Sleep -Seconds 2
            }
        }
        
        if ($installedPackage) {
            Write-Host "       ✓ Uygulama basariyla kuruldu!" -ForegroundColor Green
            Write-Host "       Paket adi: $($installedPackage.Name)" -ForegroundColor Cyan
            Write-Host "       Paket ailesi: $($installedPackage.PackageFamilyName)" -ForegroundColor Cyan
            Write-Host "       Versiyon: $($installedPackage.Version)" -ForegroundColor Cyan
            Write-Host "       Kurulum yolu: $($installedPackage.InstallLocation)" -ForegroundColor Cyan
        } else {
            Write-Host "       ✗ HATA: Kurulum tamamlandi ama paket bulunamadi!" -ForegroundColor Red
            Write-Host "       Detayli kontrol yapiliyor..." -ForegroundColor Yellow
            
            # Tüm paketleri listele (debug için)
            $allPackages = Get-AppxPackage | Where-Object { 
                $_.Name -like "*edu*" -or $_.Name -like "*app*" 
            } | Select-Object Name, PackageFamilyName | Format-Table -AutoSize
            Write-Host "       Ilgili paketler:" -ForegroundColor Cyan
            $allPackages | Out-String | Write-Host
            
            Write-Host ""
            Write-Host "       COZUM DENEMELERI:" -ForegroundColor Yellow
            Write-Host "       1. Bilgisayari yeniden baslatin" -ForegroundColor Cyan
            Write-Host "       2. Event Viewer'da hatalari kontrol edin" -ForegroundColor Cyan
            Write-Host "       3. PowerShell'i YONETICI olarak acip su komutu calistirin:" -ForegroundColor Cyan
            Write-Host "          Add-AppxPackage -Path `"$msixPath`"" -ForegroundColor White
            Write-Host ""
            Write-Host "Devam etmek icin bir tusa basin..." -ForegroundColor Yellow
            $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
            exit 1
        }
    } catch {
        Write-Host "       ✗ HATA: Kurulum basarisiz!" -ForegroundColor Red
        Write-Host "       Hata detayi: $_" -ForegroundColor Red
        Write-Host "       Hata tipi: $($_.Exception.GetType().FullName)" -ForegroundColor Red
        
        # Daha detaylı hata analizi
        $errorMsg = $_.Exception.Message
        if ($errorMsg -like "*0x800B0100*" -or $errorMsg -like "*signature*" -or $errorMsg -like "*certificate*") {
            Write-Host ""
            Write-Host "       COZUM: Sertifika sorunu tespit edildi." -ForegroundColor Yellow
            Write-Host "       1. Sertifikanin yuklu oldugundan emin olun:" -ForegroundColor Cyan
            Write-Host "          Get-ChildItem Cert:\LocalMachine\Root | Where-Object { `$_.Subject -like '*MyEduApp*' }" -ForegroundColor White
            Write-Host "       2. Sertifikayi tekrar yukleyin:" -ForegroundColor Cyan
            Write-Host "          Import-Certificate -FilePath `"$certPath`" -CertStoreLocation Cert:\LocalMachine\Root" -ForegroundColor White
            Write-Host "       3. Bilgisayari yeniden baslatin" -ForegroundColor Cyan
        } elseif ($errorMsg -like "*0x80073CF3*" -or $errorMsg -like "*already installed*" -or $errorMsg -like "*conflict*") {
            Write-Host ""
            Write-Host "       COZUM: Uygulama zaten kurulu veya cakisma var." -ForegroundColor Yellow
            Write-Host "       Eski kurulumu kaldirip tekrar deneyin:" -ForegroundColor Cyan
            Write-Host "       Get-AppxPackage | Where-Object { `$_.Name -like '*myeduapp*' } | Remove-AppxPackage" -ForegroundColor White
        } elseif ($errorMsg -like "*0x80070005*" -or $errorMsg -like "*access denied*") {
            Write-Host ""
            Write-Host "       COZUM: Yetki sorunu. PowerShell'i YONETICI OLARAK calistirin!" -ForegroundColor Yellow
        } else {
            Write-Host ""
            Write-Host "       Genel cozum:" -ForegroundColor Yellow
            Write-Host "       1. Event Viewer'da Application loglarini kontrol edin" -ForegroundColor Cyan
            Write-Host "       2. MSIX dosyasini manuel olarak calistirmayi deneyin" -ForegroundColor Cyan
        }
        
        Write-Host ""
        Write-Host "Devam etmek icin bir tusa basin..." -ForegroundColor Yellow
        $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
        exit 1
    }
} else {
    Write-Host "       ✗ HATA: MSIX dosyasi bulunamadi: $msixPath" -ForegroundColor Red
    Write-Host "       Lutfen dist klasorunde my_edu_app.msix dosyasinin oldugundan emin olun." -ForegroundColor Yellow
    exit 1
}

# 4. Uygulamayı aç (sadece kurulum başarılıysa)
Write-Host "[4/5] Uygulama aciliyor..." -ForegroundColor Yellow

$package = Get-AppxPackage | Where-Object { 
    $_.Name -like "*myeduapp*" -or 
    $_.PackageFamilyName -like "*myeduapp*" -or
    $_.Name -like "*MyEduApp*"
} | Select-Object -First 1

if ($package) {
    Write-Host "       Uygulama paketi bulundu: $($package.Name)" -ForegroundColor Cyan
    
    try {
        $manifest = [xml](Get-AppxPackageManifest $package)
        $appId = $manifest.Package.Applications.Application.Id
        $appPath = "shell:AppsFolder\$($package.PackageFamilyName)!$appId"
        
        Write-Host "       Uygulama baslatiliyor: $appPath" -ForegroundColor Cyan
        Start-Process $appPath -ErrorAction Stop
        Start-Sleep -Seconds 2
        Write-Host "       ✓ Uygulama acildi!" -ForegroundColor Green
    } catch {
        Write-Host "       UYARI: Uygulama otomatik acilamadi: $_" -ForegroundColor Yellow
        Write-Host "       Alternatif yontem deneniyor..." -ForegroundColor Cyan
        
        # Alternatif yöntemler
        $packageFamilyName = $package.PackageFamilyName
        $alternatives = @(
            "shell:AppsFolder\$packageFamilyName!App",
            "shell:AppsFolder\$($package.PackageFamilyName)!$($package.Name)"
        )
        
        $opened = $false
        foreach ($altPath in $alternatives) {
            try {
                Start-Process $altPath -ErrorAction Stop
                Start-Sleep -Seconds 2
                Write-Host "       ✓ Uygulama alternatif yontemle acildi!" -ForegroundColor Green
                $opened = $true
                break
            } catch {
                # Devam et
            }
        }
        
        if (-not $opened) {
            Write-Host "       ! Uygulama otomatik acilamadi." -ForegroundColor Yellow
            Write-Host "       Lutfen Baslat menusunden 'MyEduApp' uygulamasini manuel olarak acin." -ForegroundColor Yellow
        }
    }
} else {
    Write-Host "       ✗ HATA: Uygulama paketi bulunamadi!" -ForegroundColor Red
    Write-Host "       Kurulum basarisiz olmus olabilir." -ForegroundColor Yellow
    Write-Host "       Lutfen kurulum loglarini kontrol edin." -ForegroundColor Yellow
}

Write-Host ""
Write-Host "[5/6] Kurulum sonrasi kontrol..." -ForegroundColor Yellow
Start-Sleep -Seconds 3

# Kurulum doğrulama
$installedPackage = Get-AppxPackage | Where-Object { $_.Name -like "*myeduapp*" -or $_.PackageFamilyName -like "*myeduapp*" }

if ($installedPackage) {
    Write-Host "       ✓ Uygulama paketi kurulu: $($installedPackage.Name)" -ForegroundColor Green
    
    # Process kontrolü
    Start-Sleep -Seconds 2
    $processes = Get-Process | Where-Object { 
        $_.ProcessName -like "*myeduapp*" -or 
        $_.ProcessName -like "*flutter*" -or
        $_.MainWindowTitle -like "*MyEduApp*"
    }
    
    if ($processes) {
        Write-Host "       ✓ Uygulama calisiyor!" -ForegroundColor Green
        foreach ($proc in $processes) {
            Write-Host "         Process: $($proc.ProcessName) (PID: $($proc.Id))" -ForegroundColor Cyan
        }
    } else {
        Write-Host "       ! Uygulama process'i henuz baslamadi." -ForegroundColor Yellow
        Write-Host "         Uygulama arka planda yukleniyor olabilir." -ForegroundColor Cyan
    }
} else {
    Write-Host "       ✗ Uygulama paketi bulunamadi!" -ForegroundColor Red
    Write-Host "       Kurulum basarisiz olmus olabilir." -ForegroundColor Yellow
}

Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "✓ Kurulum tamamlandi!" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "[6/6] Uygulama otomatik aciliyor..." -ForegroundColor Yellow
Start-Sleep -Seconds 2

# Uygulamayı aç
$finalPackage = Get-AppxPackage | Where-Object { 
    $_.Name -like "*myeduapp*" -or 
    $_.PackageFamilyName -like "*myeduapp*" -or
    $_.Name -like "*MyEduApp*"
} | Select-Object -First 1

if ($finalPackage) {
    try {
        $manifest = [xml](Get-AppxPackageManifest $finalPackage)
        $appId = $manifest.Package.Applications.Application.Id
        $appPath = "shell:AppsFolder\$($finalPackage.PackageFamilyName)!$appId"
        Start-Process $appPath -ErrorAction Stop
        Write-Host "       ✓ Uygulama acildi!" -ForegroundColor Green
    } catch {
        Write-Host "       ! Uygulama otomatik acilamadi, Finish sayfasindaki butonu kullanin." -ForegroundColor Yellow
    }
} else {
    Write-Host "       ! Uygulama paketi bulunamadi." -ForegroundColor Yellow
}

Write-Host ""
Write-Host "Kurulum sihirbazina donmek icin bir tusa basin..." -ForegroundColor Yellow
$null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
