<#
.SYNOPSIS
    Enable Auditing on SQL Servers in a subscription and send audit logs to a Log Analytics workspace.    
    
.DESCRIPTION
    This script enables auditing on all Azure SQL Servers (excluding analytics) in a user-specified Azure subscription.
    It configures the auditing settings to send audit logs to a specified Log Analytics workspace.
    The script retrieves all SQL Servers, enables auditing with LogAnalyticsTargetState, and applies the settings.
    Configuration is loaded from Config.json file which contains Log Analytics workspace details and default settings.
    The user can choose which subscription to process at runtime.

.PARAMETER SubscriptionId
    The Azure subscription ID containing the SQL Servers to configure.

.EXAMPLE
    .\Enable-AuditingOnSQLServers.ps1 -SubscriptionId "12345678-1234-1234-1234-123456789012"
    
    Enables auditing on all SQL Servers in the specified subscription.

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
    # .\Enable-AuditingOnSQLServers.ps1 -SubscriptionId "target-subscription-id"

.NOTES
    Author: Christian Frohn
    https://www.linkedin.com/in/frohn/
    Version: 1.0
    
    Prerequisites:
    - Azure PowerShell module installed (Az.Sql, Az.Accounts, Az.OperationalInsights)
    - Config.json file configured with Log Analytics workspace subscription and details 
    - Log Analytics workspace details
    - Minimum required Azure RBAC permissions:
      - Reader role on subscription (to list SQL Servers)
      - SQL Server Contributor role on subscription (to configure auditing)
      - Or alternatively: Contributor role on subscription

    SQL Server Auditing Details:
    - Enables Log Analytics destination for audit logs
    - Uses default audit action groups (SUCCESSFUL_DATABASE_AUTHENTICATION_GROUP, FAILED_DATABASE_AUTHENTICATION_GROUP, BATCH_COMPLETED_GROUP)
    - Applies to all databases on each SQL Server
    - Excludes analytics (Synapse) servers as per policy definition

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

# Connect to Azure
Connect-AzAccount

# Set the subscription context for processing SQL Servers
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

Write-Host "Starting SQL Server auditing configuration..." -ForegroundColor Green
Write-Host "Processing Subscription: $SubscriptionId" -ForegroundColor Cyan
Write-Host "Log Analytics Workspace: $LogAnalyticsWorkspaceName" -ForegroundColor Cyan
Write-Host "Workspace Resource ID: $LogAnalyticsWorkspaceId" -ForegroundColor Gray

try {
    # Get all SQL Servers in the subscription (excluding analytics servers as per policy)
    Write-Host "`nGetting all SQL Servers in subscription..." -ForegroundColor Yellow
    $SqlServers = Get-AzSqlServer | Where-Object { $_.Kind -notlike "*analytics*" }
    
    if ($SqlServers.Count -eq 0) {
        Write-Host "No SQL Servers found in subscription (excluding analytics servers)" -ForegroundColor Red
        exit
    }
    
    Write-Host "Found $($SqlServers.Count) SQL Server(s)" -ForegroundColor Green
    
    # Process each SQL Server
    foreach ($SqlServer in $SqlServers) {
        Write-Host "`nProcessing SQL Server: $($SqlServer.ServerName) (Resource Group: $($SqlServer.ResourceGroupName))" -ForegroundColor Cyan
        
        try {
            # Enable auditing on SQL Server with Log Analytics destination
            Set-AzSqlServerAudit `
                -ResourceGroupName $SqlServer.ResourceGroupName `
                -ServerName $SqlServer.ServerName `
                -LogAnalyticsTargetState Enabled `
                -WorkspaceResourceId $LogAnalyticsWorkspaceId
                
            Write-Host "Auditing enabled for SQL Server '$($SqlServer.ServerName)' with Log Analytics destination" -ForegroundColor Green
        }
        catch {
            Write-Host "Failed to enable auditing for SQL Server '$($SqlServer.ServerName)': $($_.Exception.Message)" -ForegroundColor Red
        }
    }
    
    Write-Host "`nSQL Server auditing configuration completed!" -ForegroundColor Green
    Write-Host "All SQL Servers now send audit logs to Log Analytics workspace" -ForegroundColor Green
}
catch {
    Write-Host "Error: $($_.Exception.Message)" -ForegroundColor Red
}