# CMake deprecation uyarisini otomatik duzeltir.
# Flutter CMake sablonlari VERSION 3.14 kullandiginda uyari verir.
# Bu script projedeki CMake dosyalarini otomatik gunceller.
$files = @(
    "windows\CMakeLists.txt",
    "windows\flutter\CMakeLists.txt",
    "windows\runner\CMakeLists.txt"
)
$oldPattern = 'cmake_minimum_required\(VERSION 3\.14\)'
$newText = 'cmake_minimum_required(VERSION 3.14...3.28)'
$count = 0
$projRoot = Split-Path -Parent $PSScriptRoot
foreach ($f in $files) {
    $path = Join-Path $projRoot $f
    if (Test-Path $path) {
        $content = Get-Content $path -Raw -Encoding UTF8
        if ($content -match $oldPattern) {
            $content = $content -replace $oldPattern, $newText
            [System.IO.File]::WriteAllText($path, $content)
            $count++
        }
    }
}
if ($count -gt 0) { Write-Host "CMake $count dosya guncellendi." }
