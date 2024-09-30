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

# Useful API documentation: https://developer.goto.com/pdf/Central_Developer_Guide.pdf

# Validate authentication with CompanyID and API PSK
$authString = [System.Text.Encoding]::Unicode.GetBytes($CompanyId + ":" + $ApiPsk)
$authBase64 = [Convert]::ToBase64String($authString)

$url = "https://secure.logmein.com/public-api/v1/authentication"
try {
    $error.Clear()
    $authResponse = Invoke-WebRequest -Uri $url -Method Get -ContentType "application/json" -UseBasicParsing -Headers @{Authorization="Basic $authBase64"}
    $authResponseJson = ($authResponse).Content | ConvertFrom-Json

    if ($authResponseJson.success -ne "true"){
        Write-Host "Authentication failed" -ForegroundColor Red
        return;
    }
}catch{
    Write-Host "Error making request (URL: $url): $($Error.Exception.Message)" -ForegroundColor Red
    return;
}

# Get users list
$url = "https://secure.logmein.com/public-api/v3/users"
try {
    $error.Clear()
    $usersResponse = Invoke-WebRequest -Uri $url -Method Get -ContentType "application/json" -UseBasicParsing -Headers @{Authorization="Basic $authBase64"}
    $usersResponseJson = ($usersResponse).Content | ConvertFrom-Json
}catch{
    Write-Host "Error making request (URL: $url): $($Error.Exception.Message)" -ForegroundColor Red
    return;
}

$usersResponseJson | Format-Table id,email,firstName,lastName,lastLoginDate