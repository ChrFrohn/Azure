#SQL authentication
$ClientID = ""
$TenantID = ""
$ClientSecret = ""

#SQL server info (Server name, DB, Table)
$SQLServer = ""
$DBName = ""
$DBTableName1 = ""

$RequestToken = Invoke-RestMethod -Method POST `
    -Uri "https://login.microsoftonline.com/$TenantID/oauth2/token"`
    -Body @{ resource = "https://database.windows.net/"; grant_type = "client_credentials"; client_id = $ClientID; client_secret = $ClientSecret }`
    -ContentType "application/x-www-form-urlencoded"
$AccessToken = $RequestToken.access_token

Invoke-Sqlcmd -Query "SELECT * FROM $DBTableName1" `
    -ServerInstance $SQLServer `
    -Database $DBName `
    -Authentication ActiveDirectoryAccessToken `
    -AccessToken $AccessToken