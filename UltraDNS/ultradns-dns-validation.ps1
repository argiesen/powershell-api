# Created by: CompuNet Inc
# Authors: Andy Giesen <agiesen@compunet.biz>
# Last Modified October 1, 2024
#
#

[cmdletbinding()]
param(
    [Parameter(Mandatory)]
    [String]$Username,
    [Parameter(Mandatory)]
    [SecureString]$Password,
    [Parameter(Mandatory)]
    [array]$Records
)

# https://github.com/ili101/PowerShell/blob/master/Get-Domain.ps1
function Get-Domain {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory, Position=0)]
        [String]$Fqdn
    )
    
    # Create TLDs List as save it to "script" for faster next run.
    if (!$TldsList){
        $TldsListRow = Invoke-RestMethod -Uri https://publicsuffix.org/list/public_suffix_list.dat
        $script:TldsList = ($TldsListRow -split "`n" | Where-Object {$_ -notlike '//*' -and $_})
        [array]::Reverse($TldsList)
    }

    $Ok = $false
    foreach ($Tld in $TldsList){
        if ($Fqdn -Like "*.$Tld"){
            $Ok = $true
            break
        }
    }

    if ($Ok){
        ($Fqdn -replace "\.$Tld" -split '\.')[-1] + ".$Tld"
    }else{
        throw 'Not a valid TLD'
    }
}

# UltraDNS API documentation: https://ultra-portalstatic.ultradns.com/static/docs/REST-API_User_Guide.pdf
# https://docs.ultradns.com/Default.htm

# Authentication URL
$url = "https://api.ultradns.com/authorization/token"

# Hashtable to create x-www-form-urlencoded body
$body = @{
    grant_type="password";
    username="$Username";
    password="$(ConvertFrom-SecureString -SecureString $Password -AsPlainText)"
}

# Get authenticaton token
try {
    $error.Clear()
    $authResponse = Invoke-WebRequest -Uri $url -Method Post -ContentType "application/x-www-form-urlencoded" -Body $body -UseBasicParsing
    $authResponseJson = ($authResponse).Content | ConvertFrom-Json

    if (!$authResponseJson.accessToken){
        Write-Host "Authentication failed" -ForegroundColor Red
        return
    }else{
        $authToken = $authResponseJson.accessToken
    }
}catch{
    Write-Host "Error making request (URL: $url): $($Error.Exception.Message)" -ForegroundColor Red
    return
}

# Proceed if authentication is successful
if ($authToken){
    # Get provided records
    foreach ($record in $records){
        $zoneName = Get-Domain $record
        $url = "https://api.ultradns.com/zones/$zoneName/rrsets/TXT/$record"

        # GET TXT record and convert response to JSON
        try {
            $getResponse = Invoke-WebRequest -Uri $url -Method Get -ContentType "application/json" -Headers @{Authorization="Bearer $authToken"} -UseBasicParsing
            $getResponseJson = ($getResponse).Content | ConvertFrom-Json
            $getResponseJson | Select-Object zoneName,rrSets
        }catch{
            Write-Host "Error retrieving record (URL: $url): $($Error.Exception.Message)" -ForegroundColor Red
            
            #switch ($getResponse.StatusCode){
            #    400 {Write-Host "Error retrieving record - Bad request(400) (URL: $url): $($Error.Exception.Message)" -ForegroundColor Red; continue}
            #    401 {Write-Host "Error retrieving record - Unauthorized (401) (URL: $url): $($Error.Exception.Message)" -ForegroundColor Red; continue}
            #    404 {Write-Host "Error retrieving record - Record not found (404) (URL: $url): $($Error.Exception.Message)" -ForegroundColor Yellow; continue}
            #    500 {Write-Host "Error retrieving record - Server error (500) (URL: $url): $($Error.Exception.Message)" -ForegroundColor Red; continue}
            #    503 {Write-Host "Error retrieving record - Server error (503) (URL: $url): $($Error.Exception.Message)" -ForegroundColor Red; continue}
            #}
            continue
        }
    }
}