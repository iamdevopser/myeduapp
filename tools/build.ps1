# MyEduApp Windows Build Script
# CMake uyarisini otomatik duzeltir, sonra derler.
$ErrorActionPreference = "Continue"
$root = Split-Path -Parent $PSScriptRoot
Set-Location $root

# CMake dosyalarini otomatik duzelt
& "$PSScriptRoot\patch_cmake.ps1"

# Flutter build - cmd ile calistir (PowerShell stderr uyarisini atlar)
cmd /c "flutter clean && flutter pub get && flutter build windows"
exit $LASTEXITCODE
