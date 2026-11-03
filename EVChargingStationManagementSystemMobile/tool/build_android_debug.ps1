$ErrorActionPreference = 'Stop'
$previousWindowsFlag = $env:FLUTTER_WINDOWS
Push-Location (Split-Path -Parent $PSScriptRoot)
try {
    # Limit platform preparation to this process. Android/Web still work;
    # Windows desktop plugin symlinks are not needed for this APK.
    $env:FLUTTER_WINDOWS = 'false'
    flutter pub get --enforce-lockfile
    if ($LASTEXITCODE -ne 0) { throw 'Dependency/plugin preparation failed.' }
    if (!(Test-Path 'android/app/src/main/java/io/flutter/plugins/GeneratedPluginRegistrant.java')) {
        throw 'Android plugin registrant was not generated. Do not build a plugin-free APK.'
    }
    flutter build apk --debug --no-pub
    if ($LASTEXITCODE -ne 0) { throw 'Android debug build failed.' }
}
finally {
    if ($null -eq $previousWindowsFlag) {
        Remove-Item Env:FLUTTER_WINDOWS -ErrorAction SilentlyContinue
    } else {
        $env:FLUTTER_WINDOWS = $previousWindowsFlag
    }
    Pop-Location
}
