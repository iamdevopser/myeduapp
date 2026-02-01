# MyEduApp - Tek EXE kurulum paketi olusturma
# Calistir: .\tools\build_full_installer.ps1
# Cikti: dist\MyEduApp-Setup.exe (kullanici bunu indirir, calistirir; gerisi otomatik)

param(
    [switch]$SkipFlutter,
    [switch]$SkipInno,
    [string]$OutputDir = "dist"
)

$ErrorActionPreference = "Stop"
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8

$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$rootDir = Split-Path -Parent $scriptDir
$distDir = Join-Path $rootDir $OutputDir

Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host " MyEduApp - Tek Tikla Kurulum Olusturucu" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# 1. Sertifika (build\msix\MyEduApp.cer + .pfx)
$certDir = Join-Path $rootDir "build\msix"
$cerPath = Join-Path $certDir "MyEduApp.cer"
$pfxPath = Join-Path $certDir "MyEduApp.pfx"

if (-not (Test-Path $cerPath) -or -not (Test-Path $pfxPath)) {
    Write-Host "[1/5] Sertifika olusturuluyor..." -ForegroundColor Yellow
    & (Join-Path $scriptDir "create_msix_cert.ps1") -CertName "MyEduApp" -OutDir "build\msix" -Password "MyEduApp123!"
    if (-not (Test-Path $cerPath)) { throw "Sertifika olusturulamadi." }
    Write-Host "      Sertifika hazir." -ForegroundColor Green
} else {
    Write-Host "[1/5] Sertifika zaten mevcut." -ForegroundColor Green
}

# 2. Flutter build + MSIX
if (-not $SkipFlutter) {
    Write-Host "[2/5] Flutter build (Windows + MSIX)..." -ForegroundColor Yellow
    Push-Location $rootDir
    try {
        flutter pub get
        flutter build windows --release
        dart run msix:create --certificate-path "build\msix\MyEduApp.pfx" --certificate-password "MyEduApp123!"
    } finally {
        Pop-Location
    }
    $msixPath = Join-Path $rootDir "build\windows\x64\runner\Release\my_edu_app.msix"
    if (-not (Test-Path $msixPath)) { throw "MSIX olusturulamadi: $msixPath" }
    Write-Host "      MSIX hazir." -ForegroundColor Green
} else {
    Write-Host "[2/5] Flutter atlandi (mevcut build kullaniliyor)." -ForegroundColor Gray
}

# 3. Dist hazirla (msix + cer + KURULUM.ps1)
Write-Host "[3/5] Dist klasoru hazirlaniyor..." -ForegroundColor Yellow
New-Item -ItemType Directory -Force -Path $distDir | Out-Null

$msixSrc = Join-Path $rootDir "build\windows\x64\runner\Release\my_edu_app.msix"
$msixDst = Join-Path $distDir "my_edu_app.msix"
Copy-Item $msixSrc $msixDst -Force

Copy-Item $cerPath (Join-Path $distDir "MyEduApp.cer") -Force

# KURULUM.ps1 dist'ta kalir (degistirme)
foreach ($f in @("my_edu_app.msix", "MyEduApp.cer", "KURULUM.ps1")) {
    $p = Join-Path $distDir $f
    if (-not (Test-Path $p)) { throw "Dist'ta eksik: $f" }
}
Write-Host "      Dist hazir (msix, cer, KURULUM.ps1)." -ForegroundColor Green

# 4. Inno Setup ile tek EXE
if (-not $SkipInno) {
    Write-Host "[4/5] Inno Setup ile MyEduApp-Setup.exe olusturuluyor..." -ForegroundColor Yellow
    $iscc = $null
    foreach ($path in @(
        "C:\Program Files (x86)\Inno Setup 6\ISCC.exe",
        "C:\Program Files\Inno Setup 6\ISCC.exe",
        (Join-Path $env:LOCALAPPDATA "Programs\Inno Setup 6\ISCC.exe"),
        "iscc"
    )) {
        if ($path -eq "iscc") {
            $exe = Get-Command iscc -ErrorAction SilentlyContinue
            if ($exe) { $iscc = $exe.Source; break }
        } elseif (Test-Path $path) {
            $iscc = $path
            break
        }
    }
    if (-not $iscc) {
        Write-Host "      Inno Setup bulunamadi." -ForegroundColor Red
        Write-Host "      Indir: https://jrsoftware.org/isdl.php" -ForegroundColor Yellow
        Write-Host "      Veya: winget install JRSoftware.InnoSetup" -ForegroundColor Yellow
        Write-Host ""
        Write-Host "      Devam etmek icin dist icindeki dosyalari ZIP yapip dagitabilirsiniz." -ForegroundColor Cyan
        Write-Host "      Kullanici: ZIP'i ac -> KURULUMU_BASLAT.bat cift tikla." -ForegroundColor Cyan
        exit 1
    }
    $issPath = Join-Path $rootDir "installer\MyEduApp.iss"
    & $iscc $issPath
    if ($LASTEXITCODE -ne 0) { throw "Inno Setup derleme hatasi." }
    $setupExe = Join-Path $distDir "MyEduApp-Setup.exe"
    if (-not (Test-Path $setupExe)) { throw "MyEduApp-Setup.exe olusmadi." }
    Write-Host "      Olusturuldu: $setupExe" -ForegroundColor Green
} else {
    Write-Host "[4/5] Inno Setup atlandi." -ForegroundColor Gray
}

# 5. ZIP (opsiyonel)
Write-Host "[5/5] ZIP olusturuluyor (alternatif dagitim)..." -ForegroundColor Yellow
$zipPath = Join-Path $distDir "MyEduApp-Kurulum.zip"
$zipFiles = @("KURULUMU_BASLAT.bat", "KURULUM.ps1", "my_edu_app.msix", "KURULUM_TALIMATLARI.txt", "VERITABANI_TEMIZLE.ps1")
$cerInDist = Join-Path $distDir "MyEduApp.cer"
if (Test-Path $cerInDist) { $zipFiles += "MyEduApp.cer" }
$tmpZipDir = Join-Path $env:TEMP "MyEduAppZip"
if (Test-Path $tmpZipDir) { Remove-Item $tmpZipDir -Recurse -Force }
New-Item -ItemType Directory -Force -Path $tmpZipDir | Out-Null
foreach ($f in $zipFiles) {
    $src = Join-Path $distDir $f
    if (Test-Path $src) { Copy-Item $src (Join-Path $tmpZipDir $f) -Force }
}
Compress-Archive -Path (Join-Path $tmpZipDir "*") -DestinationPath $zipPath -Force
Remove-Item $tmpZipDir -Recurse -Force -ErrorAction SilentlyContinue
Write-Host "      MyEduApp-Kurulum.zip olusturuldu." -ForegroundColor Green

Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host " Hazir!" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "Dagitim:" -ForegroundColor White
Write-Host "  * Tek tikla: dist\MyEduApp-Setup.exe" -ForegroundColor Cyan
Write-Host "    -> Kullanici indirir, calistirir; UAC 'Evet' -> kurulum otomatik." -ForegroundColor Gray
Write-Host ""
Write-Host "  * ZIP: dist\MyEduApp-Kurulum.zip" -ForegroundColor Cyan
Write-Host "    -> Kullanici ZIP'i acar, KURULUMU_BASLAT.bat'a cift tiklar." -ForegroundColor Gray
Write-Host ""
Write-Host "Kullanici ek bir sey yapmaz; kurulum %100 otomatik." -ForegroundColor Green
Write-Host ""
