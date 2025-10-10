# FireProof SQL Server Connectivity Status

## ✅ Working: Local Connection

Successfully connected from local machine to SQL Server:

```bash
# Password stored in file to avoid escaping issues
export SQLCMDPASSWORD=$(cat ~/.sqlpass)
sqlcmd -S sqltest.schoolvision.net,14333 -U sv -d FireProofDB -C

# Connection confirmed:
- Database: FireProofDB
- User: sv
- Server: SQL Server 2019 (RTM-GDR) Developer Edition
- Tables: AuditLog, SystemRoles, Tenants, Users, UserSystemRoles, UserTenantRoles
```

Test script: `scripts/test-sql-connection.sh`

---

## ✅ Firewall Configuration Complete

### Azure NSG Rules (TESTVM)
- **Subscription**: Microsoft Partner Network
- **Resource Group**: network
- **NSG**: TestVM-nsg
- **Rules Created**: 13 (priorities 100-220)
- **Status**: Active ✓

All Azure App Service outbound IPs allowed:
```
135.224.222.197, 135.237.226.77, 9.169.150.50, 135.237.226.221,
135.18.140.226, 132.196.212.176, 132.196.184.207, 135.237.203.153,
4.152.150.18, 132.196.184.42, 52.254.111.153, 135.222.182.103,
20.119.128.27
```

Verify rules:
```bash
az account set --subscription "Microsoft Partner Network"
az network nsg rule list --nsg-name TestVM-nsg --resource-group network \
  --query "[?contains(name, 'FireProof')]" -o table
```

### Windows Firewall (TESTVM)
- **Rules Created**: 13 (executed remotely)
- **Port**: 14333 (TCP)
- **Status**: Active ✓

Verify rules:
```powershell
# RDP to TESTVM, then:
Get-NetFirewallRule -DisplayName "FireProof-Azure-SQL-*" | Format-Table
```

---

## ❌ Not Working: Azure App Service Connection

**App Service**: fireproof-api-test-2025
**Resource Group**: rg-fireproof
**Subscription**: Test Environment

### Current Status
- Health endpoint: Returns "Error"
- Login endpoint: Connection timeout or failure
- Database connectivity: **FAILED**

### Connection String Configured
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

Set in Azure as: `ConnectionStrings__DefaultConnection`

---

## 🔍 Troubleshooting Steps Completed

1. ✓ Verified SQL Server listening on port 14333
2. ✓ Confirmed DNS resolution (sqltest.schoolvision.net → 52.241.6.49)
3. ✓ Added all App Service IPs to NSG
4. ✓ Added all App Service IPs to Windows Firewall
5. ✓ Verified 'sv' user exists in SQL Server
6. ✓ Tested password from file (works locally)
7. ✓ Connection string configured in Azure
8. ✗ App Service still cannot connect

---

## ✅ SQL Server Browser Service Configured

### Firewall Rules Added:
- **Azure NSG**: UDP port 1434 (Priority 240) ✓
- **Windows Firewall**: UDP port 1434 rule created ✓
- **Service Status**: SQL Browser running (Automatic) ✓

### Local Connection Working:
- Connection string: `Server=sqltest.schoolvision.net,14333;...;Encrypt=Optional`
- Microsoft.Data.SqlClient 5.2.2
- Tested successfully with login endpoint ✓

## 🚧 Remaining Issues

### Azure App Service Still Failing

**Status**: App responds but returns "Unhealthy" on health check

**Tests Performed**:
1. ✓ Set connection string as SQLAzure type
2. ✓ Set connection string as app setting (ConnectionStrings__DefaultConnection)
3. ✓ Tried `Encrypt=Optional` (works locally)
4. ✓ Tried `Encrypt=False` (traditional setting)
5. ✗ All attempts result in "Unhealthy" status

### Possible Causes:

1. **Azure App Service Outbound UDP Restrictions**
   - App Service may block outbound UDP traffic to port 1434
   - SQL Server Browser service cannot respond to instance queries
   - Even though we specify port 14333, SqlClient may still try UDP 1434

2. **Network Path Differences**
   - Local (WSL): Direct connection works perfectly
   - Azure (East US 2): Cannot establish connection
   - MobileID-demo (West US 3): Successfully connects to same server
   - Suggests regional or network path issue

3. **Azure SQL Connection Proxy**
   - Azure may intercept or modify SQL connections
   - Connection string type "SQLAzure" may trigger special handling
   - App setting override may not be taking effect

4. **SqlClient Version Compatibility**
   - Microsoft.Data.SqlClient 5.2.2 has strict SSL/TLS requirements
   - May behave differently when running in Azure vs local
   - MobileID-demo may use older SqlClient version

---

## 📋 Recommended Next Steps

### Option A: Check SQL Server Authentication Mode
```powershell
# RDP to TESTVM
$regPath = "HKLM:\SOFTWARE\Microsoft\Microsoft SQL Server\MSSQL**.MSSQLSERVER\MSSQLServer"
(Get-ItemProperty -Path $regPath).LoginMode
# 1 = Windows Auth only, 2 = Mixed Mode
```

### Option B: Verify Actual Connection Attempts
Check SQL Server error logs for connection attempts from Azure IPs:
```sql
EXEC xp_readerrorlog 0, 1, N'Login failed'
```

### Option C: Use Azure SQL Database
Migrate to Azure SQL Database for native Azure networking:
- No public IP/firewall management needed
- Built-in VNet integration
- Better performance and reliability

### Option D: VNet Integration
Configure Azure App Service VNet integration:
```bash
az webapp vnet-integration add \
  --name fireproof-api-test-2025 \
  --resource-group rg-fireproof \
  --vnet <vnet-name> \
  --subnet <subnet-name>
```

---

## 📝 Test Commands

### Test from Local Machine
```bash
cd /mnt/d/dev2/fireproof
./scripts/test-sql-connection.sh
```

### Check Azure App Service Logs
```bash
az account set --subscription "Test Environment"
az webapp log tail --name fireproof-api-test-2025 --resource-group rg-fireproof
```

### Verify NSG Rules
```bash
az account set --subscription "Microsoft Partner Network"
az network nsg rule list --nsg-name TestVM-nsg --resource-group network \
  --query "[?contains(name, 'FireProof')].{Name:name, Priority:priority, SourceIP:sourceAddressPrefixes[0]}" -o table
```

---

**Last Updated**: 2025-10-10
**Status**: Local connection ✓ | Firewall configured ✓ | Azure App Service ✗
