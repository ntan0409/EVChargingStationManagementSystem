param([switch]$InitializeDatabase, [switch]$SetupOnly, [ValidateRange(1, 65535)][int]$Port = 5058)

$previousEnvironment = $env:ASPNETCORE_ENVIRONMENT
try {
    $env:ASPNETCORE_ENVIRONMENT = 'Development'
    $project = Join-Path $PSScriptRoot 'EVChargingStationManagementSystemBE/APIs'
    $options = @('--TeamDemo:Run=true', "--urls=http://localhost:$Port")
    if ($SetupOnly) { $options += '--TeamDemo:SetupOnly=true' }

    # Startup always applies pending migrations and seeds the demo database.
    dotnet run --project $project --configuration Release --no-launch-profile -- @options
    if ($LASTEXITCODE) { throw 'Cannot initialize or start the demo backend.' }
} finally {
    $env:ASPNETCORE_ENVIRONMENT = $previousEnvironment
}
