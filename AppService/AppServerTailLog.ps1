# Get web tail log output from Azure App service

$AppName = ""
$RGGroup = ""
az webapp log tail --name $AppName --resource-group $RGGroup
