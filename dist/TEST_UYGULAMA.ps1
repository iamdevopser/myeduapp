# MyEduApp - Uygulama Test Script'i
# Bu script uygulamanın çalışması için gerekli ortamı test eder

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "MyEduApp - Ortam Testi" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

$errors = @()

# 1. Dosya yazma izinleri testi
Write-Host "[1/5] Dosya yazma izinleri test ediliyor..." -ForegroundColor Yellow
try {
    $testPath = [Environment]::GetFolderPath("MyDocuments")
    $testFile = Join-Path $testPath "MyEduAppData\test_write.txt"
    $testDir = Split-Path $testFile -Parent
    
    if (-not (Test-Path $testDir)) {
        New-Item -ItemType Directory -Path $testDir -Force | Out-Null
    }
    
    "test" | Out-File -FilePath $testFile -Encoding UTF8 -ErrorAction Stop
    Remove-Item $testFile -Force -ErrorAction SilentlyContinue
    Write-Host "       Dosya yazma izinleri OK!" -ForegroundColor Green
} catch {
    $errors += "Dosya yazma hatası: $_"
    Write-Host "       HATA: Dosya yazma izinleri yok!" -ForegroundColor Red
}

# 2. SQLite DLL kontrolü
Write-Host "[2/5] SQLite DLL kontrol ediliyor..." -ForegroundColor Yellow
$sqliteDllPaths = @(
    "$env:ProgramFiles\WindowsApps\*\my_edu_app*\sqlite3.dll",
    "$env:LOCALAPPDATA\Packages\*\my_edu_app*\sqlite3.dll"
)

$sqliteFound = $false
foreach ($path in $sqliteDllPaths) {
    $found = Get-ChildItem -Path $path -ErrorAction SilentlyContinue
    if ($found) {
        Write-Host "       SQLite DLL bulundu: $($found.FullName)" -ForegroundColor Green
        $sqliteFound = $true
        break
    }
}

if (-not $sqliteFound) {
    Write-Host "       UYARI: SQLite DLL bulunamadi (normal olabilir)" -ForegroundColor Yellow
}

# 3. Uygulama paketi kontrolü
Write-Host "[3/5] Uygulama paketi kontrol ediliyor..." -ForegroundColor Yellow
$package = Get-AppxPackage | Where-Object { $_.Name -like "*myeduapp*" -or $_.PackageFamilyName -like "*myeduapp*" }
if ($package) {
    Write-Host "       Uygulama kurulu: $($package.Name)" -ForegroundColor Green
    Write-Host "       Versiyon: $($package.Version)" -ForegroundColor Cyan
    Write-Host "       Konum: $($package.InstallLocation)" -ForegroundColor Cyan
} else {
    $errors += "Uygulama paketi bulunamadi"
    Write-Host "       HATA: Uygulama kurulu degil!" -ForegroundColor Red
}

# 4. Event Viewer'da uygulama hatalarını kontrol et
Write-Host "[4/5] Event Viewer'da hatalar kontrol ediliyor..." -ForegroundColor Yellow
try {
    $appEvents = Get-WinEvent -LogName Application -MaxEvents 50 -ErrorAction SilentlyContinue | 
        Where-Object { 
            $_.Message -like "*myeduapp*" -or 
            $_.Message -like "*MyEduApp*" -or
            $_.ProviderName -like "*myeduapp*" -or
            $_.ProviderName -like "*flutter*"
        }
    
    if ($appEvents) {
        Write-Host "       Son 50 olayda uygulama ile ilgili kayitlar bulundu:" -ForegroundColor Yellow
        foreach ($event in $appEvents | Select-Object -First 5) {
            Write-Host "       - [$($event.TimeCreated)] $($event.LevelDisplayName): $($event.Message.Substring(0, [Math]::Min(100, $event.Message.Length)))" -ForegroundColor Cyan
        }
    } else {
        Write-Host "       Uygulama ile ilgili kayit bulunamadi" -ForegroundColor Yellow
    }
} catch {
    Write-Host "       Event Viewer erisim hatasi: $_" -ForegroundColor Yellow
}

# 5. Çalışan process kontrolü
Write-Host "[5/5] Çalışan process'ler kontrol ediliyor..." -ForegroundColor Yellow
$processes = Get-Process | Where-Object { 
    $_.ProcessName -like "*myeduapp*" -or 
    $_.ProcessName -like "*flutter*" -or
    $_.MainWindowTitle -like "*MyEduApp*"
}

if ($processes) {
    Write-Host "       Çalışan process'ler bulundu:" -ForegroundColor Yellow
    foreach ($proc in $processes) {
        Write-Host "       - $($proc.ProcessName) (PID: $($proc.Id))" -ForegroundColor Cyan
    }
} else {
    Write-Host "       Çalışan process bulunamadi" -ForegroundColor Yellow
}

Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
if ($errors.Count -eq 0) {
    Write-Host "Test tamamlandi - Kritik hata bulunamadi" -ForegroundColor Green
} else {
    Write-Host "Test tamamlandi - $($errors.Count) hata bulundu:" -ForegroundColor Red
    foreach ($error in $errors) {
        Write-Host "  - $error" -ForegroundColor Red
    }
}
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "Event Viewer'da daha detayli kontrol icin:" -ForegroundColor Yellow
Write-Host "  1. Event Viewer'i acin (Win+R -> eventvwr)" -ForegroundColor Cyan
Write-Host "  2. Windows Logs -> Application'a gidin" -ForegroundColor Cyan
Write-Host "  3. Sag tiklayip 'Filter Current Log' secin" -ForegroundColor Cyan
Write-Host "  4. Event sources: 'Application Error' ve 'Windows Error Reporting' secin" -ForegroundColor Cyan
Write-Host "  5. 'myeduapp' veya 'flutter' kelimelerini arayin" -ForegroundColor Cyan
Write-Host ""
Write-Host "Kapatmak icin bir tusa basin..." -ForegroundColor Yellow
$null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
