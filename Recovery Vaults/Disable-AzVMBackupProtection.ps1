$resourceGroupName = ""
$vaultName = ""
$vmFriendlyName = ""

$vault = Get-AzRecoveryServicesVault -ResourceGroupName $resourceGroupName -Name $vaultName

$container = Get-AzRecoveryServicesBackupContainer -ContainerType AzureVM -FriendlyName $vmFriendlyName -VaultId $vault.Id

$backupItem = Get-AzRecoveryServicesBackupItem -Container $container -WorkloadType AzureVM -VaultId $vault.Id

Disable-AzRecoveryServicesBackupProtection -Item $backupItem -VaultId $vault.Id -RemoveRecoveryPoints
