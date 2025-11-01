# Simple Azure App Service Deployment Script using Az PowerShell Module
# Deploy Access Package Policy Tool to Azure App Service

param(
    [string]$ZipFilePath = "",
    [string]$ResourceGroupName = "", 
    [string]$AppServiceName = ""
)

# Check if Az module is installed
if (-not (Get-Module -ListAvailable -Name Az.Websites)) {
    Write-Host "Installing Az.Websites module..." -ForegroundColor Yellow
    Install-Module -Name Az.Websites -Force -AllowClobber
}

# Connect to Azure (if not already connected)
try {
    $context = Get-AzContext
    if (-not $context) {
        Write-Host "Connecting to Azure..." -ForegroundColor Yellow
        Connect-AzAccount
    }
}
catch {
    Write-Host "Connecting to Azure..." -ForegroundColor Yellow
    Connect-AzAccount
}

# Check if zip file exists
if (-not (Test-Path $ZipFilePath)) {
    Write-Host "Error: Zip file not found: $ZipFilePath" -ForegroundColor Red
    exit 1
}

Write-Host "Found zip file: $ZipFilePath" -ForegroundColor Green

# Deploy the zip file to App Service
try {
    Write-Host "Deploying to App Service: $AppServiceName..." -ForegroundColor Yellow
    
    Publish-AzWebApp -ResourceGroupName $ResourceGroupName `
                     -Name $AppServiceName `
                     -ArchivePath $ZipFilePath `
                     -Force
    
    Write-Host "✓ Deployment completed successfully!" -ForegroundColor Green
    
    # Get the app URL
    $webapp = Get-AzWebApp -ResourceGroupName $ResourceGroupName -Name $AppServiceName
    $appUrl = "https://$($webapp.DefaultHostName)"
    
    Write-Host ""
    Write-Host "Deployment Summary:" -ForegroundColor Cyan
    Write-Host "  App Service: $AppServiceName" -ForegroundColor White
    Write-Host "  Resource Group: $ResourceGroupName" -ForegroundColor White  
    Write-Host "  App URL: $appUrl" -ForegroundColor White
    
}
catch {
    Write-Host "❌ Deployment failed: $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}
