# MyEduApp - Build Durumu Kontrol Script'i
# Build'in devam edip etmedigini kontrol eder

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "MyEduApp - Build Durumu Kontrol" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# 1. Calisan build process'leri
Write-Host "[1/3] Calisan build process'leri kontrol ediliyor..." -ForegroundColor Yellow
$buildProcesses = Get-Process | Where-Object { 
    $_.ProcessName -like "*flutter*" -or 
    $_.ProcessName -like "*dart*" -or 
    $_.ProcessName -like "*iscc*" -or
    ($_.ProcessName -like "*powershell*" -and $_.CommandLine -like "*build_full_installer*")
} -ErrorAction SilentlyContinue

if ($buildProcesses) {
    Write-Host "       ✓ Build devam ediyor!" -ForegroundColor Green
    foreach ($proc in $buildProcesses) {
        Write-Host "       - $($proc.ProcessName) (PID: $($proc.Id), Baslangic: $($proc.StartTime))" -ForegroundColor Cyan
    }
} else {
    Write-Host "       Build process bulunamadi (tamamlanmis olabilir)" -ForegroundColor Gray
}

Write-Host ""

# 2. Setup EXE kontrolu
Write-Host "[2/3] Setup EXE kontrol ediliyor..." -ForegroundColor Yellow
$setupExe = Join-Path $PSScriptRoot "MyEduApp-Setup.exe"
if (Test-Path $setupExe) {
    $exe = Get-Item $setupExe
    Write-Host "       ✓ MyEduApp-Setup.exe mevcut!" -ForegroundColor Green
    Write-Host "       Olusturulma: $($exe.LastWriteTime)" -ForegroundColor Cyan
    Write-Host "       Boyut: $([math]::Round($exe.Length/1MB, 2)) MB" -ForegroundColor Cyan
} else {
    Write-Host "       ✗ MyEduApp-Setup.exe bulunamadi" -ForegroundColor Red
    Write-Host "       Build henuz tamamlanmamis olabilir" -ForegroundColor Yellow
}

Write-Host ""

# 3. MSIX kontrolu
Write-Host "[3/3] MSIX paketi kontrol ediliyor..." -ForegroundColor Yellow
$msix = Join-Path $PSScriptRoot "my_edu_app.msix"
if (Test-Path $msix) {
    $msixFile = Get-Item $msix
    Write-Host "       ✓ my_edu_app.msix mevcut!" -ForegroundColor Green
    Write-Host "       Olusturulma: $($msixFile.LastWriteTime)" -ForegroundColor Cyan
    Write-Host "       Boyut: $([math]::Round($msixFile.Length/1MB, 2)) MB" -ForegroundColor Cyan
} else {
    Write-Host "       ✗ my_edu_app.msix bulunamadi" -ForegroundColor Red
}

Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Kontrol tamamlandi!" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "Build log dosyalari:" -ForegroundColor Yellow
Write-Host "  C:\Users\$env:USERNAME\.cursor\projects\d-MyEduApp\terminals\*.txt" -ForegroundColor Cyan
Write-Host ""
Write-Host "Kapatmak icin bir tusa basin..." -ForegroundColor Yellow
$null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
