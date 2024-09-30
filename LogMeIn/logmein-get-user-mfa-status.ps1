# LogMeIn API
# Created by: Andy Giesen
# Date: 2024.09.29

[cmdletbinding()]
param(
    [Parameter(Mandatory)]
    [string]$CompanyId,
    [Parameter(Mandatory)]
    [string]$ApiPsk
)

# Update certificate trust policy to allow untrusted certificates
add-type @"
    using System.Net;
    using System.Security.Cryptography.X509Certificates;
    public class TrustAllCertsPolicy : ICertificatePolicy {
        public bool CheckValidationResult(
            ServicePoint srvPoint, X509Certificate certificate,
            WebRequest request, int certificateProblem) {
            return true;
        }
    }
"@
[System.Net.ServicePointManager]::CertificatePolicy = New-Object TrustAllCertsPolicy

# Useful API documentation: https://developer.goto.com/pdf/Central_Developer_Guide.pdf

# Validate authentication with CompanyID and API PSK
$authBase64 = [Convert]::ToBase64String($CompanyId + ":" + $ApiPsk)

$url = "https://secure.logmein.com/public-api/v1/authentication"
try {
    $error.Clear()
    $authResponse = Invoke-WebRequest -Uri $url -Method Get -ContentType "application/json" -UseBasicParsing -Headers @{Authorization="Basic $authBase64"}
    $authResponseJson = ($authResponse).Content | ConvertFrom-Json

    if ($authResponseJson.success -ne "true"){
        Write-Host "Authentication failed" -ForegroundColor Red
        break;
    }
}catch{
    Write-Host "Error making request (URL: $url): $($Error.Exception.Message)" -ForegroundColor Red
    break;
}

# Get users list
$url = "https://secure.logmein.com/public-api/v3/users"
try {
    $error.Clear()
    $usersResponse = Invoke-WebRequest -Uri $url -Method Get -ContentType "application/json" -UseBasicParsing -Headers @{Authorization="Basic $authBase64"}
    $usersResponseJson = ($usersResponse).Content | ConvertFrom-Json
}catch{
    Write-Host "Error making request (URL: $url): $($Error.Exception.Message)" -ForegroundColor Red
    break;
}