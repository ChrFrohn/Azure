<#
.SYNOPSIS
    Install Guest Configuration extension to fix encryption policy compliance

.DESCRIPTION
    This policy uses Guest Configuration to check encryption status from inside the VM.
    Without this extension, the policy can't detect EncryptionAtHost status.

.EXAMPLE
    .\Install-GuestConfig-Extension.ps1 -ResourceGroupName "MyRG" -VMName "MyVM"
#>

param(
    [Parameter(Mandatory=$true)]
    [string]$ResourceGroupName,
    
    [Parameter(Mandatory=$true)]
    [string]$VMName
)

Write-Host "Installing Guest Configuration extension on $VMName..." -ForegroundColor Yellow

# Install the Guest Configuration extension
Set-AzVMExtension `
    -ResourceGroupName $ResourceGroupName `
    -VMName $VMName `
    -Name "AzurePolicyforWindows" `
    -Publisher "Microsoft.GuestConfiguration" `
    -ExtensionType "ConfigurationforWindows" `
    -TypeHandlerVersion "1.0" `
    -EnableAutomaticUpgrade $true

# Verify the extension installation
$extension = Get-AzVMExtension -ResourceGroupName $ResourceGroupName -VMName $VMName -Name "AzurePolicyforWindows"
Write-Host "Guest Configuration extension installed on $VMName - Status: $($extension.ProvisioningState)" -ForegroundColor Green
