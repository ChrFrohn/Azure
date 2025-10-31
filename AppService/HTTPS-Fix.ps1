<#
.SYNOPSIS
    Simple script to enable HTTPS Only on Azure Web Apps

.EXAMPLE
    .\Simple-HTTPS-Fix.ps1 -ResourceGroupName "MyRG" -WebAppName "MyApp"
#>

param(
    [Parameter(Mandatory=$true)]
    [string]$ResourceGroupName,
    
    [Parameter(Mandatory=$true)]
    [string]$WebAppName
)

# Enable HTTPS Only
Set-AzWebApp -ResourceGroupName $ResourceGroupName -Name $WebAppName -HttpsOnly $true | Out-Null

# Confirm the setting
$webapp = Get-AzWebApp -ResourceGroupName $ResourceGroupName -Name $WebAppName
Write-Host "HTTPS Only enabled for $WebAppName - Status: $($webapp.HttpsOnly)" -ForegroundColor Green
