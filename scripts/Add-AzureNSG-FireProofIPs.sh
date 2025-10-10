#!/bin/bash
# Add-AzureNSG-FireProofIPs.sh
# Adds Azure App Service outbound IPs to TESTVM NSG for SQL Server access

# Azure App Service Outbound IPs for fireproof-api-test-2025
AZURE_IPS=(
    "135.224.222.197"
    "135.237.226.77"
    "9.169.150.50"
    "135.237.226.221"
    "135.18.140.226"
    "132.196.212.176"
    "132.196.184.207"
    "135.237.203.153"
    "4.152.150.18"
    "132.196.184.42"
    "52.254.111.153"
    "135.222.182.103"
    "20.119.128.27"
)

# Configuration - UPDATE THESE VALUES
VM_NAME="TESTVM"
RESOURCE_GROUP="<RESOURCE_GROUP_NAME>"  # e.g., rg-schoolvision-test
NSG_NAME=""  # Will be auto-detected if empty
SQL_PORT="14333"

echo "================================================"
echo "FireProof Azure NSG Configuration Script"
echo "================================================"
echo ""

# Check if resource group is set
if [[ "$RESOURCE_GROUP" == "<RESOURCE_GROUP_NAME>" ]]; then
    echo "ERROR: Please update RESOURCE_GROUP in the script"
    echo ""
    echo "To find your VM and resource group, run:"
    echo "  az vm list --query \"[?contains(name, 'TEST')].{name:name, resourceGroup:resourceGroup}\" -o table"
    exit 1
fi

# Find NSG if not specified
if [[ -z "$NSG_NAME" ]]; then
    echo "Finding NSG for VM $VM_NAME..."

    # Get NIC for the VM
    NIC_ID=$(az vm show --name $VM_NAME --resource-group $RESOURCE_GROUP --query "networkProfile.networkInterfaces[0].id" -o tsv)

    if [[ -z "$NIC_ID" ]]; then
        echo "ERROR: Could not find network interface for VM $VM_NAME"
        exit 1
    fi

    # Get NSG from NIC
    NSG_ID=$(az network nic show --ids $NIC_ID --query "networkSecurityGroup.id" -o tsv)

    if [[ -z "$NSG_ID" ]]; then
        echo "ERROR: No NSG attached to VM $VM_NAME"
        echo "You may need to attach an NSG first or check subnet-level NSG"
        exit 1
    fi

    NSG_NAME=$(basename $NSG_ID)
    echo "Found NSG: $NSG_NAME"
fi

echo ""
echo "Configuration:"
echo "  VM: $VM_NAME"
echo "  Resource Group: $RESOURCE_GROUP"
echo "  NSG: $NSG_NAME"
echo "  SQL Port: $SQL_PORT"
echo "  IPs to add: ${#AZURE_IPS[@]}"
echo ""

# Get next available priority
echo "Finding next available priority..."
MAX_PRIORITY=$(az network nsg rule list --nsg-name $NSG_NAME --resource-group $RESOURCE_GROUP \
    --query "max([?direction=='Inbound'].priority)" -o tsv)

if [[ -z "$MAX_PRIORITY" || "$MAX_PRIORITY" == "null" ]]; then
    NEXT_PRIORITY=1000
else
    NEXT_PRIORITY=$((MAX_PRIORITY + 10))
fi

echo "Starting priority: $NEXT_PRIORITY"
echo ""

# Add NSG rules for each IP
PRIORITY=$NEXT_PRIORITY
COUNTER=1

for IP in "${AZURE_IPS[@]}"; do
    RULE_NAME="Allow-FireProof-SQL-${COUNTER}"

    echo "[$COUNTER/${#AZURE_IPS[@]}] Creating rule: $RULE_NAME for $IP (Priority: $PRIORITY)"

    az network nsg rule create \
        --name $RULE_NAME \
        --nsg-name $NSG_NAME \
        --resource-group $RESOURCE_GROUP \
        --priority $PRIORITY \
        --source-address-prefixes $IP \
        --destination-port-ranges $SQL_PORT \
        --access Allow \
        --protocol Tcp \
        --direction Inbound \
        --description "Allow Azure App Service (fireproof-api-test-2025) to access SQL Server" \
        --output none

    if [[ $? -eq 0 ]]; then
        echo "  ✓ Created successfully"
    else
        echo "  ✗ Failed to create rule"
    fi

    PRIORITY=$((PRIORITY + 10))
    COUNTER=$((COUNTER + 1))
done

echo ""
echo "================================================"
echo "NSG Rules Created Successfully!"
echo "================================================"
echo ""
echo "To view the rules, run:"
echo "  az network nsg rule list --nsg-name $NSG_NAME --resource-group $RESOURCE_GROUP --query \"[?contains(name, 'FireProof')].{Name:name, Priority:priority, SourceIP:sourceAddressPrefix, Port:destinationPortRange, Access:access}\" -o table"
echo ""
echo "To test connectivity from Azure:"
echo "  Wait 2-3 minutes for rules to propagate"
echo "  Then test from: https://fireproof-api-test-2025.azurewebsites.net/api/locations"
