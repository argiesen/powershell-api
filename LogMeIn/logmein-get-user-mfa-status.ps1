# LogMeIn API
# Created by: CompuNet Inc
# Authors: Andy Giesen <agiesen@compunet.biz>
# Last Modified October 1, 2024
#
#

[cmdletbinding()]
param(
    [Parameter(Mandatory)]
    [string]$CompanyId,
    [Parameter(Mandatory)]
    [string]$ApiPsk
)

# Useful API documentation: https://developer.goto.com/pdf/Central_Developer_Guide.pdf
# https://developer.goto.com/admin/

# Validate authentication with CompanyID and API PSK
$authString = $CompanyId + ":" + $ApiPsk
$authBase64 = [Convert]::ToBase64String([char[]]$authString)

$url = "https://secure.logmein.com/public-api/v1/authentication"
$authResponse = Invoke-WebRequest -Uri $url -Method Get -UseBasicParsing -Headers @{Authorization="Basic $authBase64"}
$authResponse

try {
    $error.Clear()
    $authResponse = Invoke-WebRequest -Uri $url -Method Get -UseBasicParsing -Headers @{Authorization="Basic $authBase64"}
    $authResponseJson = ($authResponse).Content | ConvertFrom-Json

    if ($authResponseJson.success -ne "true"){
        Write-Host "Authentication failed" -ForegroundColor Red
        return;
    }
}catch{
    Write-Host "Error making authentication request (URL: $url): $($Error.Exception.Message)" -ForegroundColor Red
    return;
}

# Get users list
$url = "https://secure.logmein.com/public-api/v3/users"
try {
    $error.Clear()
    $usersResponse = Invoke-WebRequest -Uri $url -Method Get -ContentType "application/json" -UseBasicParsing -Headers @{Authorization="Basic $authBase64"}
    $usersResponse.Content
    $usersResponseJson = ($usersResponse).Content | ConvertFrom-Json
}catch{
    Write-Host "Error making request (URL: $url): $($Error.Exception.Message)" -ForegroundColor Red
    return;
}

$usersResponseJson.usersData | Format-Table id,isPending,isEnabled,email,firstName,lastName,lastLoginDate