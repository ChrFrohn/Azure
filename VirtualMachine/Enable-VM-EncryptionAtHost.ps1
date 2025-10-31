<#
.SYNOPSIS
    Simple script to enable EncryptionAtHost on Azure VMs

.DESCRIPTION
    Enables EncryptionAtHost on specified Azure VM to resolve security recommendation:
    "Windows virtual machines should enable Azure Disk Encryption or EncryptionAtHost"

.NOTES
    Fill in the variables below and run the script
#>

#region === CONFIGURATION VARIABLES - EDIT THESE ===
$VMName = "Valladolid"
$ResourceGroupName = "IAM"
$SubscriptionId = ""  # Leave empty to use current subscription
#endregion

#region === SCRIPT EXECUTION - DO NOT EDIT BELOW ===
$ErrorActionPreference = 'Stop'

# Helper function for colored output
function Write-Step { param([string]$Message, [string]$Status = 'Info')
    $colors = @{ 'Success' = 'Green'; 'Warning' = 'Yellow'; 'Error' = 'Red'; 'Info' = 'Cyan' }
    $icons = @{ 'Success' = '✓'; 'Warning' = '⚠'; 'Error' = '❌'; 'Info' = 'ℹ' }
    Write-Host "$($icons[$Status]) $Message" -ForegroundColor $colors[$Status]
}

try {
    Write-Host "=== Enabling EncryptionAtHost for VM: $VMName ===" -ForegroundColor Blue
    
    # Set subscription if specified
    if ($SubscriptionId) {
        Write-Step "Setting subscription: $SubscriptionId"
        Set-AzContext -SubscriptionId $SubscriptionId | Out-Null
    }
    
    # Check Azure connection
    $context = Get-AzContext
    if (-not $context) {
        Write-Step "Not connected to Azure. Run Connect-AzAccount first." "Error"
        exit 1
    }
    Write-Step "Connected to: $($context.Subscription.Name)"
    
    # Get VM
    Write-Step "Getting VM information..."
    $vm = Get-AzVM -ResourceGroupName $ResourceGroupName -Name $VMName
    Write-Step "Found VM: $($vm.Name) (Size: $($vm.HardwareProfile.VmSize))"
    
    # Check current encryption status
    if ($vm.SecurityProfile.EncryptionAtHost) {
        Write-Step "EncryptionAtHost is already enabled!" "Success"
        exit 0
    }
    
    # Register feature if needed
    Write-Step "Checking EncryptionAtHost feature registration..."
    $feature = Get-AzProviderFeature -FeatureName "EncryptionAtHost" -ProviderNamespace "Microsoft.Compute"
    
    if ($feature.RegistrationState -ne 'Registered') {
        Write-Step "Registering EncryptionAtHost feature..." "Warning"
        Register-AzProviderFeature -FeatureName "EncryptionAtHost" -ProviderNamespace "Microsoft.Compute" | Out-Null
        
        # Wait for registration
        do {
            Start-Sleep 30
            $feature = Get-AzProviderFeature -FeatureName "EncryptionAtHost" -ProviderNamespace "Microsoft.Compute"
            Write-Host "  Waiting for registration... ($($feature.RegistrationState))" -ForegroundColor Gray
        } while ($feature.RegistrationState -eq 'Registering')
        
        if ($feature.RegistrationState -eq 'Registered') {
            Write-Step "Feature registered successfully" "Success"
        } else {
            Write-Step "Feature registration failed: $($feature.RegistrationState)" "Error"
            exit 1
        }
    } else {
        Write-Step "Feature already registered" "Success"
    }
    
    # Check VM status and stop if running
    $vmStatus = Get-AzVM -ResourceGroupName $ResourceGroupName -Name $VMName -Status
    $isRunning = $vmStatus.Statuses | Where-Object {$_.Code -eq 'PowerState/running'}
    
    if ($isRunning) {
        Write-Step "Stopping VM..." "Warning"
        Stop-AzVM -ResourceGroupName $ResourceGroupName -Name $VMName -Force | Out-Null
        Write-Step "VM stopped"
    }
    
    # Enable EncryptionAtHost
    Write-Step "Enabling EncryptionAtHost..."
    $result = Update-AzVM -VM $vm -ResourceGroupName $ResourceGroupName -EncryptionAtHost $true
    
    if ($result.IsSuccessStatusCode) {
        Write-Step "EncryptionAtHost enabled successfully!" "Success"
        
        # Start VM if it was running
        if ($isRunning) {
            Write-Step "Starting VM..."
            Start-AzVM -ResourceGroupName $ResourceGroupName -Name $VMName | Out-Null
            Write-Step "VM started" "Success"
        }
        
        Write-Host "`n=== COMPLETED SUCCESSFULLY ===" -ForegroundColor Green
        Write-Step "Security recommendation will be resolved within 24 hours" "Success"
        
    } else {
        Write-Step "Failed to enable EncryptionAtHost" "Error"
        exit 1
    }
    
} catch {
    Write-Step "Error: $($_.Exception.Message)" "Error"
    exit 1
}
#endregion
