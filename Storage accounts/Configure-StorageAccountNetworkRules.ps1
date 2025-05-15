$ResourceGroupName = ""
$StorageAccountName = ""
$VirtualNetworkRG = ""
$VirtualNetworkName = ""
$SubnetName = ""

$subnet = Get-AzVirtualNetwork -ResourceGroupName $VirtualNetworkRG -Name $VirtualNetworkName |
    Get-AzVirtualNetworkSubnetConfig -Name $SubnetName

Add-AzStorageAccountNetworkRule -ResourceGroupName $ResourceGroupName `
    -Name $StorageAccountName `
    -VirtualNetworkResourceId $subnet.Id

Set-AzStorageAccount -ResourceGroupName $ResourceGroupName `
    -AccountName $StorageAccountName `
    -AllowSharedKeyAccess $false
