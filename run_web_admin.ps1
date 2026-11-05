$ErrorActionPreference = 'Stop'
$settingsFile = Join-Path $PSScriptRoot 'appsettings.Local.json'
if (!(Test-Path -LiteralPath $settingsFile)) { throw 'Receive appsettings.Local.json from the project owner first.' }
$settings = Get-Content -LiteralPath $settingsFile -Raw | ConvertFrom-Json
$oldApi = $env:VITE_API_URL
$oldGoogle = $env:VITE_GOOGLE_CLIENT_ID
Push-Location (Join-Path $PSScriptRoot 'EVChargingStationManagementSystemFE')
try {
    # Only public client settings go to Vite. Backend secrets never enter its bundle.
    $env:VITE_API_URL = 'http://localhost:5058/api'
    $env:VITE_GOOGLE_CLIENT_ID = $settings.Authentication.Google.ClientId
    if (!(Test-Path -LiteralPath 'node_modules')) {
        & npm.cmd ci
        if ($LASTEXITCODE) { throw 'Frontend dependency installation failed.' }
    }
    & npm.cmd run dev
    if ($LASTEXITCODE) { throw 'Frontend dev server failed.' }
} finally {
    $env:VITE_API_URL = $oldApi
    $env:VITE_GOOGLE_CLIENT_ID = $oldGoogle
    Pop-Location
}
