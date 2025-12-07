<#
.SYNOPSIS
    Enable Diagnostic Logs for App Services in a subscription and send them to a Log Analytics workspace.    
    
.DESCRIPTION
    This script enables diagnostic logs for all App Service apps (excluding function apps) in a user-selected Azure subscription.
    It configures the diagnostic settings to send logs and metrics to a specified Log Analytics workspace.
    The script retrieves all App Service apps, creates the necessary log, audit log, and metric settings, and applies the diagnostic settings.
    Configuration is loaded from Config.json file which contains Log Analytics workspace details and default settings.
    The user can choose which subscription to process at runtime.

.PARAMETER SubscriptionId
    The Azure subscription ID containing the App Services to configure.

.EXAMPLE
    .\Enable-DiagnosticLogsInAppService.ps1 -SubscriptionId "12345678-1234-1234-1234-123456789012"
    
    Enables diagnostic settings for all App Service apps in the specified subscription.

.EXAMPLE
    # First, configure Config.json with your Log Analytics workspace settings:
    # {
    #   "azure": {
    #     "logAnalyticsSubscriptionId": "subscription-id-where-workspace-is-located",
    #     "logAnalytics": {
    #       "workspaceName": "your-workspace-name",
    #       "resourceGroup": "your-workspace-resource-group"
    #     },
    #     "defaults": {
    #       "diagnosticSettingName": "AzureDiagnosticSettings"
    #     }
    #   }
    # }
    # Then run the script with the target subscription ID:
    # .\Enable-DiagnosticLogsInAppService.ps1 -SubscriptionId "target-subscription-id"

.NOTES
    Author: Christian Frohn
    https://www.linkedin.com/in/frohn/
    Version: 1.0
    
    Prerequisites:
    - Azure PowerShell module installed
    - Config.json file configured with Log Analytics workspace subscription and details 
    - Log Analytics workspace details
    - Minimum required Azure RBAC permissions:
      - Reader role on subscription (to list App Services)
      - Monitoring Contributor role on subscription (to create diagnostic settings)
      - Or alternatively: Contributor role on subscription

.LINK
    https://github.com/ChrFrohn/Azure/Defender-for-Cloud
    https://www.christianfrohn.dk
#>

param(
    [Parameter(Mandatory = $true)]
    [string]$SubscriptionId
)

# Load configuration from JSON
$config = Get-Content "$PSScriptRoot\Config.json" | ConvertFrom-Json
$LogAnalyticsSubscriptionId = $config.azure.logAnalyticsSubscriptionId
$LogAnalyticsWorkspaceName = $config.azure.logAnalytics.workspaceName
$LogAnalyticsResourceGroup = $config.azure.logAnalytics.resourceGroup
$DiagnosticSettingName = $config.azure.defaults.diagnosticSettingName

# Connect to Azure
Connect-AzAccount

# Set the subscription context for processing App Services
Set-AzContext -SubscriptionId $SubscriptionId

# Get the Log Analytics workspace resource ID
Write-Host "Getting Log Analytics workspace..." -ForegroundColor Yellow
# Switch temporarily to workspace subscription if different
if ($SubscriptionId -ne $LogAnalyticsSubscriptionId) {
    Set-AzContext -SubscriptionId $LogAnalyticsSubscriptionId | Out-Null
}

$LogAnalyticsWorkspace = Get-AzOperationalInsightsWorkspace -ResourceGroupName $LogAnalyticsResourceGroup -Name $LogAnalyticsWorkspaceName
if (-not $LogAnalyticsWorkspace) {
    Write-Host "Error: Log Analytics workspace '$LogAnalyticsWorkspaceName' not found in resource group '$LogAnalyticsResourceGroup'" -ForegroundColor Red
    exit
}
$LogAnalyticsWorkspaceId = $LogAnalyticsWorkspace.ResourceId

# Switch back to processing subscription if different
if ($SubscriptionId -ne $LogAnalyticsSubscriptionId) {
    Set-AzContext -SubscriptionId $SubscriptionId | Out-Null
}

Write-Host "Starting App Service diagnostic configuration..." -ForegroundColor Green
Write-Host "Processing Subscription: $SubscriptionId" -ForegroundColor Cyan
Write-Host "Log Analytics Workspace: $LogAnalyticsWorkspaceName" -ForegroundColor Cyan
Write-Host "Workspace Resource ID: $LogAnalyticsWorkspaceId" -ForegroundColor Gray

try {
    # Get all App Service apps in the subscription (excluding function apps)
    Write-Host "`nGetting all App Service apps in subscription..." -ForegroundColor Yellow
    $AppServices = Get-AzWebApp | Where-Object { $_.Kind -notlike "*functionapp*" }
    
    if ($AppServices.Count -eq 0) {
        Write-Host "No App Service apps found in subscription" -ForegroundColor Red
        exit
    }
    
    Write-Host "Found $($AppServices.Count) App Service app(s)" -ForegroundColor Green
    
    # Process each App Service app
    foreach ($AppService in $AppServices) {
        Write-Host "`nProcessing App Service: $($AppService.Name) (Resource Group: $($AppService.ResourceGroup))" -ForegroundColor Cyan
        
        try {
            # Create log settings objects for all logs and audit logs
            $logSettings = @()
            $logSettings += New-AzDiagnosticSettingLogSettingsObject -Enabled $true -CategoryGroup "allLogs"
            $logSettings += New-AzDiagnosticSettingLogSettingsObject -Enabled $true -CategoryGroup "audit"
            
            # Create metric settings object for AllMetrics
            $metricSettings = New-AzDiagnosticSettingMetricSettingsObject -Enabled $true -Category "AllMetrics"
            
            # Create diagnostic setting
            New-AzDiagnosticSetting `
                -Name $DiagnosticSettingName `
                -ResourceId $AppService.Id `
                -WorkspaceId $LogAnalyticsWorkspaceId `
                -Log $logSettings `
                -Metric $metricSettings
                
            Write-Host "Diagnostic setting '$DiagnosticSettingName' enabled for $($AppService.Name)" -ForegroundColor Green
        }
        catch {
            Write-Host "Failed to enable diagnostics for $($AppService.Name): $($_.Exception.Message)" -ForegroundColor Red
        }
    }
    
    Write-Host "`nDiagnostic configuration completed!" -ForegroundColor Green
    Write-Host "All App Service apps now send logs to Log Analytics workspace" -ForegroundColor Green
}
catch {
    Write-Host "Error: $($_.Exception.Message)" -ForegroundColor Red
}
