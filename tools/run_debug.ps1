# MyEduApp - Debug modunda calistir (kernel hatasi olursa run.ps1 veya build+Release exe kullanin)
$ErrorActionPreference = "Continue"
$root = Split-Path -Parent $PSScriptRoot
Set-Location $root
if (Test-Path "$PSScriptRoot\patch_cmake.ps1") { & "$PSScriptRoot\patch_cmake.ps1" }
# Debug hatasi icin once temiz build dene
cmd /c "flutter clean && flutter pub get && flutter run -d windows"
