# FireProof Firewall Configuration

This guide helps configure Windows Firewall and Azure NSG to allow Azure App Service to access SQL Server on TESTVM.

## Azure App Service Outbound IPs

These IPs need firewall access to `sqltest.schoolvision.net:14333`:

```
135.224.222.197, 135.237.226.77, 9.169.150.50, 135.237.226.221,
135.18.140.226, 132.196.212.176, 132.196.184.207, 135.237.203.153,
4.152.150.18, 132.196.184.42, 52.254.111.153, 135.222.182.103, 20.119.128.27
```

## Step 1: Windows Firewall (on TESTVM)

**Run this on TESTVM via RDP:**

```powershell
# Run as Administrator
cd D:\dev2\fireproof\scripts
.\Add-FireProofAzureIPs.ps1
```

This will:
- Create 13 Windows Firewall inbound rules
- Allow each Azure IP to connect to port 14333
- Enable TCP connections from Azure App Service

**Verify rules:**
```powershell
Get-NetFirewallRule -DisplayName "FireProof-Azure-SQL-*" | Format-Table DisplayName, Enabled, Action
```

---

## Step 2: Azure NSG (Network Security Group)

**Find your VM and Resource Group first:**

### Option A: Using Azure CLI (Bash)

```bash
# Switch to correct subscription
az account set --subscription "Microsoft Partner Network"
# OR
az account set --subscription "SchoolVision"

# Find TESTVM
az vm list --query "[?contains(name, 'TEST')].{name:name, resourceGroup:resourceGroup}" -o table

# Edit the script with correct resource group
nano Add-AzureNSG-FireProofIPs.sh
# Update: RESOURCE_GROUP="rg-schoolvision-test"  # <-- Your actual RG name

# Run the script
chmod +x Add-AzureNSG-FireProofIPs.sh
./Add-AzureNSG-FireProofIPs.sh
```

### Option B: Using PowerShell

```powershell
# Switch to correct subscription
Set-AzContext -Subscription "Microsoft Partner Network"
# OR
Set-AzContext -Subscription "SchoolVision"

# Find TESTVM
Get-AzVM | Where-Object { $_.Name -like '*TEST*' } | Select-Object Name, ResourceGroupName

# Edit the script with correct resource group
notepad Add-AzureNSG-FireProofIPs.ps1
# Update: $ResourceGroup = "rg-schoolvision-test"  # <-- Your actual RG name

# Run the script
.\Add-AzureNSG-FireProofIPs.ps1
```

---

## Step 3: Test Connectivity

After applying firewall rules, wait 2-3 minutes for propagation, then test:

```bash
# Test login (should work)
curl -X POST https://fireproof-api-test-2025.azurewebsites.net/api/authentication/login \
  -H "Content-Type: application/json" \
  -d '{"email": "chris@servicevision.net", "password": "Gv51076"}'

# Test locations endpoint (should return 200 OK with empty array)
TOKEN="<access_token_from_above>"
curl -i https://fireproof-api-test-2025.azurewebsites.net/api/locations \
  -H "Authorization: Bearer $TOKEN"
```

**Expected response:**
```
HTTP/2 200
[]
```

---

## Troubleshooting

### Still getting timeouts?

1. **Verify NSG rules are active:**
   ```powershell
   Get-AzNetworkSecurityGroup -Name <NSG_NAME> -ResourceGroupName <RG_NAME> |
     Get-AzNetworkSecurityRuleConfig |
     Where-Object { $_.Name -like 'Allow-FireProof-*' }
   ```

2. **Check SQL Server is listening:**
   ```powershell
   # On TESTVM
   netstat -ano | findstr :14333
   ```

3. **Test from Azure portal:**
   - Go to TESTVM in Azure Portal
   - Click "Networking" → "Network Watcher" → "Connection Troubleshoot"
   - Test connection from App Service to TESTVM:14333

4. **Check App Service logs:**
   ```bash
   az webapp log tail --name fireproof-api-test-2025 --resource-group rg-fireproof
   ```

### NSG script fails?

If auto-detection fails, manually specify the NSG:

**Bash:**
```bash
NSG_NAME="TESTVM-nsg"  # Update this line in the script
```

**PowerShell:**
```powershell
$NSGName = "TESTVM-nsg"  # Update this line in the script
```

---

## Manual NSG Rule Creation (Alternative)

If scripts don't work, add rules manually in Azure Portal:

1. Go to **TESTVM** → **Networking** → **Network Security Group**
2. Click **Inbound security rules** → **Add**
3. For each IP, create a rule:
   - **Source:** IP Address
   - **Source IP:** `135.224.222.197` (etc.)
   - **Destination port:** `14333`
   - **Protocol:** TCP
   - **Action:** Allow
   - **Priority:** 1000, 1010, 1020... (increment by 10)
   - **Name:** `Allow-FireProof-SQL-1`, etc.

---

## Connection String

Current connection string in Azure App Service:

```
Server=sqltest.schoolvision.net,14333;
Database=FireProofDB;
User Id=sv;
Password=Gv51076!;
TrustServerCertificate=True;
Encrypt=True;
MultipleActiveResultSets=true;
ConnectTimeout=30
```

Already configured in Azure App Service environment variable:
`ConnectionStrings__DefaultConnection`
