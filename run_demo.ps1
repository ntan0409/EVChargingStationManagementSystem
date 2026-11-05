$ErrorActionPreference = 'Stop'
$mobile = Join-Path $PSScriptRoot 'EVChargingStationManagementSystemMobile'
$cache = Join-Path $PSScriptRoot '.artifacts/demo-launcher'
New-Item -ItemType Directory -Force -Path $cache | Out-Null
Push-Location $PSScriptRoot
try {
    if (!(Test-Path -LiteralPath 'appsettings.Local.json')) {
        throw 'Place appsettings.Local.json next to RUN_DEMO.cmd first.'
    }

    function Test-Backend {
        try {
            $response = Invoke-WebRequest 'http://localhost:5058/' -UseBasicParsing -TimeoutSec 2
            return $response.StatusCode -eq 200 -and $response.Content -eq 'EVCSMS API is running...'
        } catch { return $false }
    }

    if (!(Test-Backend)) {
        Write-Host 'Starting backend on port 5058...'
        if (Get-NetTCPConnection -LocalPort 5058 -State Listen -ErrorAction SilentlyContinue) {
            throw 'Port 5058 belongs to another server. Stop that server and try again.'
        }
        & sqllocaldb start MSSQLLocalDB
        if ($LASTEXITCODE) { throw 'Cannot start SQL Server LocalDB.' }
        $backend = Join-Path $PSScriptRoot 'run_backend_local.ps1'
        $process = Start-Process powershell.exe -ArgumentList "-NoProfile -ExecutionPolicy Bypass -File `"$backend`"" -WindowStyle Hidden -PassThru -RedirectStandardOutput (Join-Path $cache 'backend.log') -RedirectStandardError (Join-Path $cache 'backend-error.log')
        $deadline = (Get-Date).AddMinutes(2)
        while (!(Test-Backend)) {
            if ($process.HasExited -or (Get-Date) -gt $deadline) {
                throw "Backend did not start. See $cache/backend-error.log and backend.log."
            }
            Start-Sleep -Seconds 2
        }
    }
    Write-Host 'Backend ready.'

    $sdk = Join-Path $env:LOCALAPPDATA 'Android/sdk'
    $properties = Join-Path $mobile 'android/local.properties'
    if (Test-Path -LiteralPath $properties) {
        $sdkLine = Get-Content -LiteralPath $properties | Where-Object { $_ -like 'sdk.dir=*' } | Select-Object -First 1
        if ($sdkLine) { $sdk = $sdkLine.Substring(8).Replace('\\', '\').Replace('\:', ':') }
    }
    $adb = Join-Path $sdk 'platform-tools/adb.exe'
    $emulator = Join-Path $sdk 'emulator/emulator.exe'
    if (!(Test-Path -LiteralPath $adb)) { throw 'Install the Android SDK and platform-tools first.' }
    function Get-EmulatorSerial {
        $device = & $adb devices | Where-Object { $_ -match '^emulator-\d+\s+device$' } | Select-Object -First 1
        if ($device) { return ($device -split '\s+')[0] }
    }
    $serial = Get-EmulatorSerial
    if (!$serial) {
        $avds = @(& $emulator -list-avds)
        if ($avds -contains 'EVCharging_Debug_API37') { $avd = 'EVCharging_Debug_API37' }
        else { $avd = $avds | Where-Object { $_.Trim() } | Select-Object -First 1 }
        if (!$avd) { throw 'Create an Android Virtual Device with Google Play in Android Studio first.' }
        Write-Host "Opening emulator $avd..."
        Start-Process -FilePath $emulator -ArgumentList "-avd `"$avd`"" -WindowStyle Normal
        $deadline = (Get-Date).AddMinutes(3)
        while (!$serial) {
            if ((Get-Date) -gt $deadline) { throw 'Emulator did not connect. Check Android Studio Device Manager.' }
            Start-Sleep -Seconds 2
            $serial = Get-EmulatorSerial
        }
    }
    $deadline = (Get-Date).AddMinutes(3)
    while ((& $adb -s $serial shell getprop sys.boot_completed 2>$null) -notmatch '1') {
        if ((Get-Date) -gt $deadline) { throw 'Android did not finish booting.' }
        Start-Sleep -Seconds 2
    }

    Push-Location $mobile
    try {
        $files = @(& git ls-files --cached --others --exclude-standard -- lib android pubspec.yaml pubspec.lock)
        if ($LASTEXITCODE -or !$files.Count) { throw 'Cannot inspect Flutter source files.' }
        $fingerprint = ($files | Sort-Object -Unique | ForEach-Object {
            if (Test-Path -LiteralPath $_ -PathType Leaf) {
                "$_ $((Get-FileHash -LiteralPath $_ -Algorithm SHA256).Hash)"
            }
        }) -join "`n"
        $apk = Join-Path $mobile 'build/app/outputs/flutter-apk/app-debug.apk'
        $sourceStamp = Join-Path $cache 'apk-source.txt'
        $apkStamp = Join-Path $cache 'apk-sha256.txt'
        $apkHash = if (Test-Path -LiteralPath $apk) { (Get-FileHash -LiteralPath $apk).Hash } else { '' }
        $needsBuild = !(Test-Path -LiteralPath $sourceStamp) -or !(Test-Path -LiteralPath $apkStamp)
        if (!$needsBuild) {
            $needsBuild = [IO.File]::ReadAllText($sourceStamp) -ne $fingerprint -or [IO.File]::ReadAllText($apkStamp) -ne $apkHash
        }
        if ($needsBuild) {
            Write-Host 'Preparing APK because source changed or no cached APK exists...'
            & flutter build apk --debug --dart-define=API_BASE_URL=http://10.0.2.2:5058/api
            if ($LASTEXITCODE) { throw 'Flutter build failed.' }
            $apkHash = (Get-FileHash -LiteralPath $apk).Hash
            [IO.File]::WriteAllText($sourceStamp, $fingerprint)
            [IO.File]::WriteAllText($apkStamp, $apkHash)
        } else { Write-Host 'Reusing APK. Build skipped.' }

        $package = 'com.fptu.prm.ev_charging_station'
        $installedStamp = Join-Path $cache "$serial-installed.txt"
        $installed = & $adb -s $serial shell pm path $package
        if (!$installed -or !(Test-Path -LiteralPath $installedStamp) -or [IO.File]::ReadAllText($installedStamp) -ne $apkHash) {
            & $adb -s $serial install -r $apk
            if ($LASTEXITCODE) { throw 'APK installation failed.' }
            [IO.File]::WriteAllText($installedStamp, $apkHash)
        }
        & $adb -s $serial shell am force-stop $package
        & $adb -s $serial shell monkey -p $package -c android.intent.category.LAUNCHER 1
        if ($LASTEXITCODE) { throw 'Android could not open the app.' }
        Write-Host 'EV Charging is ready. Backend stays running while you test.'
    } finally { Pop-Location }
} finally { Pop-Location }
