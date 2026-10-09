# MyEduApp - Once derle, sonra Release exe'yi dogrudan calistir
$ErrorActionPreference = "Continue"
$root = Split-Path -Parent $PSScriptRoot
Set-Location $root
if (Test-Path "$PSScriptRoot\patch_cmake.ps1") { & "$PSScriptRoot\patch_cmake.ps1" }
cmd /c "flutter build windows"
if ($LASTEXITCODE -eq 0) {
    $exe = Join-Path $root "build\windows\x64\runner\Release\my_edu_app.exe"
    if (Test-Path $exe) {
        Start-Process $exe
    } else {
        $exe = Join-Path $root "build\windows\x64\runner\Debug\my_edu_app.exe"
        if (Test-Path $exe) { Start-Process $exe } else { Write-Host "Exe bulunamadi." }
    }
}
