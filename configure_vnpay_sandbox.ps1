param(
    [Parameter(Mandatory = $true)][string]$TerminalCode,
    [Parameter(Mandatory = $true)][uri]$CallbackOrigin
)

$ErrorActionPreference = 'Stop'
if (!$CallbackOrigin.IsAbsoluteUri -or $CallbackOrigin.Scheme -ne 'https' -or
    $CallbackOrigin.IsLoopback -or $CallbackOrigin.HostNameType -ne 'Dns' -or
    !$CallbackOrigin.Host.Contains('.') -or $CallbackOrigin.AbsolutePath -ne '/' -or
    $CallbackOrigin.UserInfo -or $CallbackOrigin.Query -or $CallbackOrigin.Fragment) {
    throw 'Provide the public HTTPS origin of your Sandbox callback host.'
}
if ($TerminalCode -notmatch '^[A-Za-z0-9]{8}$') {
    throw 'Provide the eight-character Sandbox terminal code.'
}

$secret = Read-Host 'VNPAY Sandbox HashSecret' -AsSecureString
if ($secret.Length -eq 0) { throw 'HashSecret is required.' }
$hashSecret = [System.Net.NetworkCredential]::new('', $secret).Password
$ipn = [uri]::new($CallbackOrigin, '/api/Payment/vnpay/ipn').AbsoluteUri
$return = [uri]::new($CallbackOrigin, '/api/Payment/vnpay/return').AbsoluteUri
$config = @{
    'VnPay:Mode' = 'Sandbox'
    'VnPay:Enabled' = 'true'
    'VnPay:TmnCode' = $TerminalCode
    'VnPay:HashSecret' = $hashSecret
    'VnPay:PaymentUrl' = 'https://sandbox.vnpayment.vn/paymentv2/vpcpay.html'
    'VnPay:IpnUrl' = $ipn
    'VnPay:ReturnUrl' = $return
}
try {
    $project = Join-Path $PSScriptRoot 'EVChargingStationManagementSystemBE/APIs/APIs.csproj'
    $config | ConvertTo-Json -Compress | dotnet user-secrets set --project $project
    if ($LASTEXITCODE) { throw 'Could not save VNPAY Sandbox settings.' }
    Write-Host "IPN to register in VNPAY SIT: $ipn"
    Write-Host "Return URL: $return"
    Write-Host 'Restart the isolated Sandbox backend after registering IPN.'
} finally {
    $config.Clear()
    $hashSecret = $null
    $secret.Dispose()
}
