# MyEduApp - MSIX Paketi Doğrulama Script'i
# Bu script MSIX paketinin imzalanmış olup olmadığını kontrol eder

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "MyEduApp - MSIX Paketi Doğrulama" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

$scriptPath = $MyInvocation.MyCommand.Path
$scriptDir = Split-Path -Parent $scriptPath
$msixPath = Join-Path $scriptDir "my_edu_app.msix"

if (-not (Test-Path $msixPath)) {
    Write-Host "HATA: MSIX dosyasi bulunamadi: $msixPath" -ForegroundColor Red
    exit 1
}

Write-Host "MSIX dosyasi bulundu: $msixPath" -ForegroundColor Green
Write-Host "Dosya boyutu: $((Get-Item $msixPath).Length / 1MB) MB" -ForegroundColor Cyan
Write-Host ""

# MSIX paketini doğrula
Write-Host "MSIX paketi dogrulanıyor..." -ForegroundColor Yellow

try {
    # Get-AppxPackageManifest ile paketi test et
    $tempPackage = Add-AppxPackage -Path $msixPath -ErrorAction Stop -WhatIf 2>&1
    
    # SignTool ile imza kontrolü (eğer varsa)
    $signtoolPath = "${env:ProgramFiles(x86)}\Windows Kits\10\bin\*\x64\signtool.exe"
    $signtool = Get-ChildItem -Path $signtoolPath -ErrorAction SilentlyContinue | Select-Object -First 1
    
    if ($signtool) {
        Write-Host "SignTool ile imza kontrol ediliyor..." -ForegroundColor Cyan
        $verifyResult = & $signtool.FullName verify /pa $msixPath 2>&1
        
        if ($LASTEXITCODE -eq 0) {
            Write-Host "✓ MSIX paketi imzalanmis!" -ForegroundColor Green
            Write-Host $verifyResult -ForegroundColor Cyan
        } else {
            Write-Host "✗ MSIX paketi imzalanmamis veya imza gecersiz!" -ForegroundColor Red
            Write-Host $verifyResult -ForegroundColor Red
        }
    } else {
        Write-Host "SignTool bulunamadi, alternatif yontem kullaniliyor..." -ForegroundColor Yellow
        
        # PowerShell ile sertifika kontrolü
        try {
            $cert = [System.Security.Cryptography.X509Certificates.X509Certificate2]::CreateFromSignedFile($msixPath)
            Write-Host "✓ MSIX paketi imzalanmis!" -ForegroundColor Green
            Write-Host "  Imzalayan: $($cert.Subject)" -ForegroundColor Cyan
            Write-Host "  Gecerlilik: $($cert.NotBefore) - $($cert.NotAfter)" -ForegroundColor Cyan
        } catch {
            Write-Host "✗ MSIX paketi imzalanmamis!" -ForegroundColor Red
            Write-Host "  Hata: $_" -ForegroundColor Red
        }
    }
    
    Write-Host ""
    Write-Host "MSIX paketi hazir!" -ForegroundColor Green
    
} catch {
    Write-Host "✗ MSIX paketi dogrulanamadi!" -ForegroundColor Red
    Write-Host "  Hata: $_" -ForegroundColor Red
    exit 1
}

Write-Host ""
Write-Host "Kapatmak icin bir tusa basin..." -ForegroundColor Yellow
$null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
