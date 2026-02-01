# Bu script daÄŸÄ±tÄ±m iÃ§in gerekli dosyalarÄ± hazÄ±rlar
param([string]$OutputDir = "dist")

Write-Host "DaÄŸÄ±tÄ±m paketi hazÄ±rlanÄ±yor..." -ForegroundColor Green

$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$rootDir = Split-Path -Parent $scriptDir
$distDir = Join-Path $rootDir $OutputDir
New-Item -ItemType Directory -Force -Path $distDir | Out-Null

$msixSource = Join-Path $rootDir "build\windows\x64\runner\Release\my_edu_app.msix"
$msixDest = Join-Path $distDir "my_edu_app.msix"

if (Test-Path $msixSource) {
    Copy-Item $msixSource $msixDest -Force
    Write-Host "MSIX dosyasÄ± kopyalandÄ±" -ForegroundColor Green
} else {
    Write-Host "MSIX dosyasÄ± bulunamadÄ±" -ForegroundColor Red
    exit 1
}

$certSource = Join-Path $rootDir "build\msix\MyEduApp.cer"
$certDest = Join-Path $distDir "MyEduApp.cer"

if (Test-Path $certSource) {
    Copy-Item $certSource $certDest -Force
    Write-Host "Sertifika dosyasÄ± kopyalandÄ±" -ForegroundColor Green
} else {
    Write-Host "Sertifika dosyasÄ± bulunamadÄ±" -ForegroundColor Red
    exit 1
}

# TEST_UYGULAMA.ps1'i kopyala
$testScriptSource = Join-Path $rootDir "dist\TEST_UYGULAMA.ps1"
$testScriptDest = Join-Path $distDir "TEST_UYGULAMA.ps1"

if (Test-Path $testScriptSource) {
    Copy-Item $testScriptSource $testScriptDest -Force
    Write-Host "Test script'i kopyalandÄ±" -ForegroundColor Green
}

$readmePath = Join-Path $distDir "KURULUM_TALIMATLARI.txt"
$content = @"
========================================
MyEduApp - Kurulum TalimatlarÄ±
========================================

1. SERTÄ°FÄ°KAYI YÃœKLEYÄ°N (Ã–NEMLÄ°!)
   PowerShell'i YÃ–NETÄ°CÄ° OLARAK aÃ§Ä±n ve ÅŸu komutu Ã§alÄ±ÅŸtÄ±rÄ±n:
   Import-Certificate -FilePath "MyEduApp.cer" -CertStoreLocation Cert:\LocalMachine\Root

2. MSIX PAKETÄ°NÄ° KURUN
   my_edu_app.msix dosyasÄ±na Ã§ift tÄ±klayÄ±n veya PowerShell'de:
   Add-AppxPackage "my_edu_app.msix"

3. UYGULAMAYI Ã‡ALIÅžTIRIN
   BaÅŸlat menÃ¼sÃ¼nden MyEduApp uygulamasÄ±nÄ± aÃ§Ä±n.
"@

Set-Content -Path $readmePath -Value $content -Encoding UTF8
Write-Host "Kurulum talimatlarÄ± oluÅŸturuldu" -ForegroundColor Green

Write-Host ""
Write-Host "DaÄŸÄ±tÄ±m paketi hazÄ±r: $distDir" -ForegroundColor Cyan
