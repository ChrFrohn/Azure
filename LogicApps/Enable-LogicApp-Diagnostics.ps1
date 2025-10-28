# Enable Diagnostics for Logic Apps in Resource Group

$ResourceGroupName = ""
$SubscriptionId = "" 
$LogAnalyticsWorkspaceName = ""
$LogAnalyticsResourceGroup = ""
$DiagnosticSettingName = ""


# Connect to Azure
Connect-AzAccount

# Set the subscription context
Set-AzContext -SubscriptionId $SubscriptionId

# Get the Log Analytics workspace resource ID
Write-Host "Getting Log Analytics workspace..." -ForegroundColor Yellow
$LogAnalyticsWorkspace = Get-AzOperationalInsightsWorkspace -ResourceGroupName $LogAnalyticsResourceGroup -Name $LogAnalyticsWorkspaceName
if (-not $LogAnalyticsWorkspace) {
    Write-Host "Error: Log Analytics workspace '$LogAnalyticsWorkspaceName' not found in resource group '$LogAnalyticsResourceGroup'" -ForegroundColor Red
    exit
}
$LogAnalyticsWorkspaceId = $LogAnalyticsWorkspace.ResourceId

Write-Host "Starting Logic Apps diagnostic configuration..." -ForegroundColor Green
Write-Host "Resource Group: $ResourceGroupName" -ForegroundColor Cyan
Write-Host "Log Analytics Workspace: $LogAnalyticsWorkspaceName" -ForegroundColor Cyan
Write-Host "Workspace Resource ID: $LogAnalyticsWorkspaceId" -ForegroundColor Gray

try {
    # Get all Logic Apps in the specified resource group
    Write-Host "`nGetting Logic Apps in resource group..." -ForegroundColor Yellow
    $LogicApps = Get-AzLogicApp -ResourceGroupName $ResourceGroupName
    
    if ($LogicApps.Count -eq 0) {
        Write-Host "No Logic Apps found in resource group '$ResourceGroupName'" -ForegroundColor Red
        exit
    }
    
    Write-Host "Found $($LogicApps.Count) Logic App(s)" -ForegroundColor Green
    
    # Process each Logic App
    foreach ($LogicApp in $LogicApps) {
        Write-Host "`nProcessing Logic App: $($LogicApp.Name)" -ForegroundColor Cyan
        
        try {
            # Create log settings object for all log categories
            $logSettings = New-AzDiagnosticSettingLogSettingsObject -Enabled $true -CategoryGroup "allLogs"
            
            # Create metric settings object for AllMetrics
            $metricSettings = New-AzDiagnosticSettingMetricSettingsObject -Enabled $true -Category "AllMetrics"
            
            # Create diagnostic setting
            New-AzDiagnosticSetting `
                -Name $DiagnosticSettingName `
                -ResourceId $LogicApp.Id `
                -WorkspaceId $LogAnalyticsWorkspaceId `
                -Log $logSettings `
                -Metric $metricSettings
                
            Write-Host "Diagnostic setting '$DiagnosticSettingName' enabled for $($LogicApp.Name)" -ForegroundColor Green
        }
        catch {
            Write-Host "Failed to enable diagnostics for $($LogicApp.Name): $($_.Exception.Message)" -ForegroundColor Red
        }
    }
    
    Write-Host "`nDiagnostic configuration completed!" -ForegroundColor Green
    Write-Host "All Logic Apps now send logs to Log Analytics workspace" -ForegroundColor Green
}
catch {
    Write-Host "Error: $($_.Exception.Message)" -ForegroundColor Red
}

Write-Host "`nScript execution finished." -ForegroundColor Yellow
