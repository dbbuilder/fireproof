# Add-AzureNSG-FireProofIPs.ps1
# Adds Azure App Service outbound IPs to TESTVM NSG for SQL Server access

# Azure App Service Outbound IPs for fireproof-api-test-2025
$AzureIPs = @(
    "135.224.222.197",
    "135.237.226.77",
    "9.169.150.50",
    "135.237.226.221",
    "135.18.140.226",
    "132.196.212.176",
    "132.196.184.207",
    "135.237.203.153",
    "4.152.150.18",
    "132.196.184.42",
    "52.254.111.153",
    "135.222.182.103",
    "20.119.128.27"
)

# Configuration - UPDATE THESE VALUES
$VMName = "TESTVM"
$ResourceGroup = "<RESOURCE_GROUP_NAME>"  # e.g., rg-schoolvision-test
$NSGName = ""  # Will be auto-detected if empty
$SQLPort = 14333

Write-Host "================================================" -ForegroundColor Cyan
Write-Host "FireProof Azure NSG Configuration Script" -ForegroundColor Cyan
Write-Host "================================================" -ForegroundColor Cyan
Write-Host ""

# Check if resource group is set
if ($ResourceGroup -eq "<RESOURCE_GROUP_NAME>") {
    Write-Host "ERROR: Please update `$ResourceGroup in the script" -ForegroundColor Red
    Write-Host ""
    Write-Host "To find your VM and resource group, run:" -ForegroundColor Yellow
    Write-Host "  az vm list --query `"[?contains(name, 'TEST')].{name:name, resourceGroup:resourceGroup}`" -o table" -ForegroundColor Gray
    Write-Host ""
    Write-Host "Or in PowerShell:" -ForegroundColor Yellow
    Write-Host "  Get-AzVM | Where-Object { `$_.Name -like '*TEST*' } | Select-Object Name, ResourceGroupName" -ForegroundColor Gray
    exit 1
}

# Find NSG if not specified
if ([string]::IsNullOrEmpty($NSGName)) {
    Write-Host "Finding NSG for VM $VMName..." -ForegroundColor Cyan

    # Get VM
    $VM = Get-AzVM -Name $VMName -ResourceGroupName $ResourceGroup -ErrorAction SilentlyContinue

    if (-not $VM) {
        Write-Host "ERROR: Could not find VM $VMName in resource group $ResourceGroup" -ForegroundColor Red
        exit 1
    }

    # Get NIC
    $NICId = $VM.NetworkProfile.NetworkInterfaces[0].Id
    $NIC = Get-AzNetworkInterface -ResourceId $NICId

    if ($NIC.NetworkSecurityGroup) {
        $NSGName = (Get-AzResource -ResourceId $NIC.NetworkSecurityGroup.Id).Name
        Write-Host "Found NSG: $NSGName" -ForegroundColor Green
    } else {
        Write-Host "ERROR: No NSG attached to VM $VMName" -ForegroundColor Red
        Write-Host "You may need to attach an NSG first or check subnet-level NSG" -ForegroundColor Yellow
        exit 1
    }
}

Write-Host ""
Write-Host "Configuration:" -ForegroundColor Cyan
Write-Host "  VM: $VMName"
Write-Host "  Resource Group: $ResourceGroup"
Write-Host "  NSG: $NSGName"
Write-Host "  SQL Port: $SQLPort"
Write-Host "  IPs to add: $($AzureIPs.Count)"
Write-Host ""

# Get NSG
$NSG = Get-AzNetworkSecurityGroup -Name $NSGName -ResourceGroupName $ResourceGroup

# Find next available priority
Write-Host "Finding next available priority..." -ForegroundColor Cyan
$ExistingRules = $NSG.SecurityRules | Where-Object { $_.Direction -eq "Inbound" }
if ($ExistingRules) {
    $MaxPriority = ($ExistingRules | Measure-Object -Property Priority -Maximum).Maximum
    $NextPriority = $MaxPriority + 10
} else {
    $NextPriority = 1000
}

Write-Host "Starting priority: $NextPriority" -ForegroundColor Green
Write-Host ""

# Add NSG rules for each IP
$Priority = $NextPriority
$Counter = 1

foreach ($IP in $AzureIPs) {
    $RuleName = "Allow-FireProof-SQL-$Counter"

    Write-Host "[$Counter/$($AzureIPs.Count)] Creating rule: $RuleName for $IP (Priority: $Priority)" -ForegroundColor Cyan

    # Remove existing rule if it exists
    $ExistingRule = $NSG.SecurityRules | Where-Object { $_.Name -eq $RuleName }
    if ($ExistingRule) {
        Write-Host "  Removing existing rule..." -ForegroundColor Yellow
        Remove-AzNetworkSecurityRuleConfig -Name $RuleName -NetworkSecurityGroup $NSG | Out-Null
    }

    # Add new rule
    Add-AzNetworkSecurityRuleConfig `
        -Name $RuleName `
        -NetworkSecurityGroup $NSG `
        -Priority $Priority `
        -SourceAddressPrefix $IP `
        -SourcePortRange "*" `
        -DestinationAddressPrefix "*" `
        -DestinationPortRange $SQLPort `
        -Access Allow `
        -Protocol Tcp `
        -Direction Inbound `
        -Description "Allow Azure App Service (fireproof-api-test-2025) to access SQL Server" | Out-Null

    Write-Host "  Added rule to NSG configuration" -ForegroundColor Green

    $Priority += 10
    $Counter++
}

# Apply all changes at once
Write-Host ""
Write-Host "Applying NSG configuration changes..." -ForegroundColor Cyan
Set-AzNetworkSecurityGroup -NetworkSecurityGroup $NSG | Out-Null

Write-Host ""
Write-Host "================================================" -ForegroundColor Green
Write-Host "NSG Rules Created Successfully!" -ForegroundColor Green
Write-Host "================================================" -ForegroundColor Green
Write-Host ""
Write-Host "To view the rules, run:" -ForegroundColor Cyan
Write-Host "  Get-AzNetworkSecurityGroup -Name $NSGName -ResourceGroupName $ResourceGroup | Get-AzNetworkSecurityRuleConfig | Where-Object { `$_.Name -like 'Allow-FireProof-*' } | Format-Table Name, Priority, SourceAddressPrefix, DestinationPortRange, Access" -ForegroundColor Gray
Write-Host ""
Write-Host "To test connectivity from Azure:" -ForegroundColor Cyan
Write-Host "  Wait 2-3 minutes for rules to propagate" -ForegroundColor Yellow
Write-Host "  Then test from: https://fireproof-api-test-2025.azurewebsites.net/api/locations" -ForegroundColor Gray
