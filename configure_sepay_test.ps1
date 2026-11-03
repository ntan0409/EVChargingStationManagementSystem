param([Parameter(Mandatory = $true)][ValidatePattern('^(?:ba_[A-Za-z0-9]+|[0-9A-Fa-f-]{36})$')][string]$TestBankAccountId)

$ErrorActionPreference = 'Stop'
$secret = Read-Host 'SePay Test Mode API token' -AsSecureString
try {
    $token = [System.Net.NetworkCredential]::new('', $secret).Password.Trim()
    if (!$token) { throw 'A Test Mode token is required.' }
    $headers = @{ Authorization = "Bearer $token" }
    $account = Invoke-RestMethod -Method Get -Uri "https://userapi-sandbox.sepay.vn/v2/bank-accounts/$TestBankAccountId" -Headers $headers -MaximumRedirection 0
    if ($account.status -ne 'success') { throw 'SePay did not confirm the Test Mode account.' }
    @{
        'SePay:Enabled' = 'true'
        'SePay:TestToken' = $token
        'SePay:TestBankAccountId' = $TestBankAccountId.ToString()
    } | ConvertTo-Json -Compress | dotnet user-secrets set --project (Join-Path $PSScriptRoot 'EVChargingStationManagementSystemBE/APIs/APIs.csproj')
    if ($LASTEXITCODE) { throw 'Could not save SePay settings.' }
    Write-Host 'SePay Test Mode configured. Restart the TeamDemo backend.'
} finally {
    $secret.Dispose()
}
