# MyEduApp - Eski Kurulum Temizleme Script'i
# Bu script eski MyEduApp kurulumunu TAMAMEN kaldırır

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "MyEduApp - Eski Kurulum Temizleme" -ForegroundColor Red
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "UYARI: Bu script tum MyEduApp kurulumlarini kaldirir!" -ForegroundColor Yellow
Write-Host "Devam etmek istiyor musunuz? (E/H)" -ForegroundColor Yellow
$confirm = Read-Host

if ($confirm -ne "E" -and $confirm -ne "e" -and $confirm -ne "Y" -and $confirm -ne "y") {
    Write-Host "Iptal edildi." -ForegroundColor Yellow
    exit 0
}

Write-Host ""
Write-Host "Eski kurulumlar temizleniyor..." -ForegroundColor Yellow

# 1. Provisioned paketleri kaldır (tüm kullanıcılar için)
Write-Host "[1/3] Tum kullanicilar icin paketler kaldiriliyor..." -ForegroundColor Cyan
try {
    $provisionedPackages = Get-AppxProvisionedPackage -Online | Where-Object { 
        $_.DisplayName -like "*myeduapp*" -or $_.PackageName -like "*myeduapp*" -or $_.PackageName -like "*com.myeduapp*"
    }
    
    if ($provisionedPackages) {
        foreach ($provisioned in $provisionedPackages) {
            Write-Host "  Kaldiriliyor: $($provisioned.DisplayName) ($($provisioned.PackageName))" -ForegroundColor Yellow
            try {
                Remove-AppxProvisionedPackage -Online -PackageName $provisioned.PackageName -ErrorAction Stop
                Write-Host "  ✓ Kaldirildi: $($provisioned.DisplayName)" -ForegroundColor Green
            } catch {
                Write-Host "  ✗ Kaldirilamadi: $_" -ForegroundColor Red
            }
        }
    } else {
        Write-Host "  Provisioned paket bulunamadi." -ForegroundColor Green
    }
} catch {
    Write-Host "  UYARI: Provisioned paket kontrolu basarisiz: $_" -ForegroundColor Yellow
}

Start-Sleep -Seconds 2

# 2. Mevcut kullanıcı için kurulu paketleri kaldır
Write-Host "[2/3] Mevcut kullanici icin paketler kaldiriliyor..." -ForegroundColor Cyan
try {
    $installedPackages = Get-AppxPackage | Where-Object { 
        $_.Name -like "*myeduapp*" -or 
        $_.PackageFamilyName -like "*myeduapp*" -or
        $_.PackageFamilyName -like "*com.myeduapp*"
    }
    
    if ($installedPackages) {
        foreach ($pkg in $installedPackages) {
            Write-Host "  Kaldiriliyor: $($pkg.Name) ($($pkg.PackageFullName))" -ForegroundColor Yellow
            try {
                Remove-AppxPackage -Package $pkg.PackageFullName -ErrorAction Stop
                Write-Host "  ✓ Kaldirildi: $($pkg.Name)" -ForegroundColor Green
            } catch {
                Write-Host "  ✗ Kaldirilamadi: $_" -ForegroundColor Red
                Write-Host "  Zorla kaldirma deneniyor..." -ForegroundColor Yellow
                try {
                    Remove-AppxPackage -Package $pkg.PackageFullName -AllUsers -ErrorAction Stop
                    Write-Host "  ✓ Zorla kaldirma basarili!" -ForegroundColor Green
                } catch {
                    Write-Host "  ✗ Zorla kaldirma da basarisiz: $_" -ForegroundColor Red
                }
            }
        }
    } else {
        Write-Host "  Kurulu paket bulunamadi." -ForegroundColor Green
    }
} catch {
    Write-Host "  UYARI: Paket kontrolu basarisiz: $_" -ForegroundColor Yellow
}

Start-Sleep -Seconds 3

# 3. Son kontrol
Write-Host "[3/3] Son kontrol yapiliyor..." -ForegroundColor Cyan
$remainingProvisioned = Get-AppxProvisionedPackage -Online | Where-Object { 
    $_.DisplayName -like "*myeduapp*" -or $_.PackageName -like "*myeduapp*" -or $_.PackageName -like "*com.myeduapp*"
}
$remainingInstalled = Get-AppxPackage | Where-Object { 
    $_.Name -like "*myeduapp*" -or 
    $_.PackageFamilyName -like "*myeduapp*" -or
    $_.PackageFamilyName -like "*com.myeduapp*"
}

if ($remainingProvisioned -or $remainingInstalled) {
    Write-Host "  UYARI: Hala kalan paketler var!" -ForegroundColor Red
    if ($remainingProvisioned) {
        foreach ($rem in $remainingProvisioned) {
            Write-Host "    Kalan provisioned: $($rem.PackageName)" -ForegroundColor Yellow
        }
    }
    if ($remainingInstalled) {
        foreach ($rem in $remainingInstalled) {
            Write-Host "    Kalan installed: $($rem.PackageFullName)" -ForegroundColor Yellow
        }
    }
    Write-Host ""
    Write-Host "  COZUM: Bilgisayari yeniden baslatin ve tekrar deneyin." -ForegroundColor Cyan
} else {
    Write-Host "  ✓ Tum eski kurulumlar temizlendi!" -ForegroundColor Green
}

Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Temizleme tamamlandi!" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "Simdi yeni MSIX paketini kurabilirsiniz." -ForegroundColor Cyan
Write-Host ""
Write-Host "Kapatmak icin bir tusa basin..." -ForegroundColor Yellow
$null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
