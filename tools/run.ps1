# MyEduApp - Uygulamayi calistir (Release modu - debug kernel hatasini atlar)
$ErrorActionPreference = "Continue"
$root = Split-Path -Parent $PSScriptRoot
Set-Location $root
if (Test-Path "$PSScriptRoot\patch_cmake.ps1") { & "$PSScriptRoot\patch_cmake.ps1" }
cmd /c "flutter run -d windows --release"
