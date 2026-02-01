# MyEduApp - Setup Dosyasi Kontrol
# Setup EXE'nin varligini ve detaylarini kontrol eder

$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$setupExe = Join-Path $scriptDir "MyEduApp-Setup.exe"

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "MyEduApp - Setup Dosyasi Kontrol" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "Aranan konum: $setupExe" -ForegroundColor Cyan
Write-Host ""

if (Test-Path $setupExe) {
    $exe = Get-Item $setupExe
    Write-Host "✓ MyEduApp-Setup.exe BULUNDU!" -ForegroundColor Green
    Write-Host ""
    Write-Host "Detaylar:" -ForegroundColor Yellow
    Write-Host "  Konum: $($exe.FullName)" -ForegroundColor White
    Write-Host "  Olusturulma: $($exe.LastWriteTime)" -ForegroundColor White
    Write-Host "  Boyut: $([math]::Round($exe.Length/1MB, 2)) MB" -ForegroundColor White
    Write-Host ""
    Write-Host "✓ Setup dosyasi hazir ve kullanima hazir!" -ForegroundColor Green
} else {
    Write-Host "✗ MyEduApp-Setup.exe BULUNAMADI!" -ForegroundColor Red
    Write-Host ""
    Write-Host "Cozum:" -ForegroundColor Yellow
    Write-Host "  1. Build script'ini calistirin:" -ForegroundColor Cyan
    Write-Host "     .\tools\build_full_installer.ps1" -ForegroundColor White
    Write-Host ""
    Write-Host "  2. Veya sadece Inno Setup adimini calistirin:" -ForegroundColor Cyan
    Write-Host "     .\tools\build_full_installer.ps1 -SkipFlutter" -ForegroundColor White
}

Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "Kapatmak icin bir tusa basin..." -ForegroundColor Yellow
$null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
