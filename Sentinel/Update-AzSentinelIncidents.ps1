$subscriptionId = ""
$resourceGroupName = ""
$workspaceName = ""
$owner = ""
$AlertTitle = ""

Connect-AzAccount -Subscription $subscriptionId

Get-AzSentinelIncident -ResourceGroupName $resourceGroupName -WorkspaceName $workspaceName | ForEach-Object {
        Update-AzSentinelIncident -Id $_.Name `
                -ResourceGroupName $resourceGroupName `
                -WorkspaceName $workspaceName `
                -SubscriptionId $subscriptionId `
                -Status Closed `
                -Confirm:$false `
                -OwnerAssignedTo $owner `
                -Classification "BenignPositive" `
                -ClassificationReason "SuspiciousButExpected"
}

$filteredIncidents = Get-AzSentinelIncident -ResourceGroupName $resourceGroupName -WorkspaceName $workspaceName | Where-Object {
        $_.Title -eq $AlertTitle -and $_.Status -eq "New"
}

$filteredIncidents
