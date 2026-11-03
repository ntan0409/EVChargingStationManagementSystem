param([switch]$InitializeDatabase, [switch]$SetupOnly, [ValidateRange(1, 65535)][int]$Port = 5058)
$ErrorActionPreference = 'Stop'
$previousEnvironment = $env:ASPNETCORE_ENVIRONMENT
$previousVnpay = $env:VnPay__Enabled
$previousChargingDemo = $env:ChargingDemo__Enabled
$sePayKeys = 'Enabled', 'TestToken', 'TestBankAccountId'
$previousSePay = @{}
foreach ($name in $sePayKeys) {
    $previousSePay[$name] = [Environment]::GetEnvironmentVariable("SePay__$name", 'Process')
}
$previousConnection = $env:ConnectionStrings__DefaultConnection
Push-Location (Join-Path $PSScriptRoot 'EVChargingStationManagementSystemBE')
try {
    $env:ASPNETCORE_ENVIRONMENT = 'Development'
    $env:VnPay__Enabled = 'false'
    $env:ChargingDemo__Enabled = 'true'
    $project = 'APIs/APIs.csproj'
    $teamSettings = Join-Path $PSScriptRoot 'appsettings.Local.json'
    if (Test-Path -LiteralPath $teamSettings) {
        $sePay = (Get-Content -LiteralPath $teamSettings -Raw | ConvertFrom-Json).SePay
        foreach ($name in $sePayKeys) {
            [Environment]::SetEnvironmentVariable("SePay__$name", [string]$sePay.$name, 'Process')
        }
    }
    $env:ConnectionStrings__DefaultConnection = 'Server=(localdb)\MSSQLLocalDB;Database=EVCSMS_TeamDemo;Integrated Security=True;TrustServerCertificate=True;MultipleActiveResultSets=True'
    $settings = Join-Path $env:APPDATA 'Microsoft/UserSecrets/evcharging-local-development/secrets.json'
    $key = $env:Jwt__Key
    if (!$key -and (Test-Path $settings)) {
        $key = (Get-Content $settings -Raw | ConvertFrom-Json).'Jwt:Key'
    }
    if ([Text.Encoding]::UTF8.GetByteCount([string]$key) -lt 32) {
        $bytes = New-Object byte[] 48
        $rng = [Security.Cryptography.RandomNumberGenerator]::Create()
        try { $rng.GetBytes($bytes) } finally { $rng.Dispose() }
        $key = [Convert]::ToBase64String($bytes)
        @{ 'Jwt:Key' = $key } | ConvertTo-Json -Compress | dotnet user-secrets set --project $project
        if ($LASTEXITCODE) { throw 'Cannot initialize local JWT key.' }
    }
    sqllocaldb start MSSQLLocalDB
    if ($LASTEXITCODE) { throw 'Cannot start SQL Server LocalDB.' }
    if ($InitializeDatabase -or $SetupOnly) {
        dotnet restore $project
        if ($LASTEXITCODE) { throw 'Cannot restore backend dependencies.' }
        dotnet ef database update --project Infrastructure --startup-project APIs --configuration Release --connection $env:ConnectionStrings__DefaultConnection
        if ($LASTEXITCODE) { throw 'Cannot initialize EVCSMS_TeamDemo. Check dotnet ef and LocalDB.' }
    }
    if ($InitializeDatabase -or $SetupOnly) {
        $seed = Join-Path $PSScriptRoot 'EVChargingStationManagementSystemMobile/audit/demo_classroom_seed.sql'
        sqlcmd -S '(localdb)\MSSQLLocalDB' -E -d EVCSMS_TeamDemo -b -f 65001 -i $seed
        if ($LASTEXITCODE) { throw 'Cannot seed EVCSMS_TeamDemo.' }
    }
    if ($InitializeDatabase -or $SetupOnly) {
        # Derive a repeatable, local-only demo password from the machine's private key.
        $hmac = [Security.Cryptography.HMACSHA256]::new([Text.Encoding]::UTF8.GetBytes($key))
        try {
            $demoPassword = 'Demo!a1' + [Convert]::ToBase64String($hmac.ComputeHash([Text.Encoding]::UTF8.GetBytes('EVCSMS_TeamDemo/accounts'))).Substring(0, 16)
        } finally { $hmac.Dispose() }
        $salt = New-Object byte[] 16
        $rng = [Security.Cryptography.RandomNumberGenerator]::Create()
        try { $rng.GetBytes($salt) } finally { $rng.Dispose() }
        $pbkdf = [Security.Cryptography.Rfc2898DeriveBytes]::new($demoPassword, $salt, 100000, [Security.Cryptography.HashAlgorithmName]::SHA512)
        try { $subkey = $pbkdf.GetBytes(32) } finally { $pbkdf.Dispose() }
        [byte[]]$header = 1,0,0,0,2,0,1,134,160,0,0,0,16
        $hash = [Convert]::ToBase64String([byte[]]($header + $salt + $subkey))
        $sql = "SET QUOTED_IDENTIFIER ON; IF DB_NAME() <> 'EVCSMS_TeamDemo' THROW 50001, 'Wrong database.', 1; UPDATE dbo.AspNetUsers SET Name=CONCAT('Legacy demo ',LEFT(CONVERT(varchar(36),Id),1)), Email=CONCAT('legacy',LEFT(CONVERT(varchar(36),Id),1),'@evcsms-demo.invalid'), UserName=CONCAT('legacy',LEFT(CONVERT(varchar(36),Id),1),'@evcsms-demo.invalid'), NormalizedEmail=UPPER(CONCAT('legacy',LEFT(CONVERT(varchar(36),Id),1),'@evcsms-demo.invalid')), NormalizedUserName=UPPER(CONCAT('legacy',LEFT(CONVERT(varchar(36),Id),1),'@evcsms-demo.invalid')), PhoneNumber=NULL, Address=NULL, DateOfBirth=NULL, ProfilePictureUrl=NULL, ProviderUserId=NULL, PasswordHash=NULL WHERE CONVERT(varchar(36),Id) IN ('11111111-1111-1111-1111-111111111111','22222222-2222-2222-2222-222222222222','33333333-3333-3333-3333-333333333333','44444444-4444-4444-4444-444444444444','77777777-7777-7777-7777-777777777777') AND ISNULL(Email,'') NOT LIKE '%@evcsms-demo.invalid'; UPDATE dbo.AspNetUsers SET PasswordHash='$hash' WHERE PasswordHash IS NULL AND Email LIKE '%@evcsms-demo.invalid' AND CONVERT(varchar(36),Id) LIKE '6de60000-8a51-4319-a00[12]-%';"
        sqlcmd -S '(localdb)\MSSQLLocalDB' -E -d EVCSMS_TeamDemo -b -Q $sql
        if ($LASTEXITCODE) { throw 'Cannot initialize demo logins.' }
        Write-Host "Demo accounts: driver1@evcsms-demo.invalid and staff1@evcsms-demo.invalid"
        Write-Host "Local demo password: $demoPassword"
    }
    if ($SetupOnly) { return }
    dotnet run --project $project --configuration Release --no-launch-profile --urls "http://localhost:$Port"
    if ($LASTEXITCODE) { throw 'Cannot start backend.' }
} finally {
    $env:ASPNETCORE_ENVIRONMENT = $previousEnvironment
    $env:VnPay__Enabled = $previousVnpay
    $env:ChargingDemo__Enabled = $previousChargingDemo
    foreach ($name in $sePayKeys) {
        [Environment]::SetEnvironmentVariable("SePay__$name", $previousSePay[$name], 'Process')
    }
    $env:ConnectionStrings__DefaultConnection = $previousConnection
    Pop-Location
}
