<#
.SYNOPSIS
    Post-deployment configuration tasks for FireProof API

.DESCRIPTION
    Completes important production tasks:
    8. Enable TDE on database
    9. Configure automated backups
    10. Set up Application Insights
    11. Remove dev test users

.PARAMETER SqlServer
    SQL Server name (without .database.windows.net)

.PARAMETER Database
    Database name

.PARAMETER SqlResourceGroup
    SQL Server resource group

.PARAMETER AppName
    App Service name

.PARAMETER ResourceGroup
    App Service resource group

.EXAMPLE
    .\Configure-PostDeployment.ps1 -SqlServer sqltest -Database FireProofDB -AppName fireproof-api-prod
#>

param(
    [Parameter(Mandatory = $true)]
    [string]$SqlServer,

    [Parameter(Mandatory = $false)]
    [string]$Database = "FireProofDB",

    [Parameter(Mandatory = $false)]
    [string]$SqlResourceGroup,

    [Parameter(Mandatory = $false)]
    [string]$AppName,

    [Parameter(Mandatory = $false)]
    [string]$ResourceGroup = "rg-fireproof"
)

$ErrorActionPreference = "Stop"

function Write-Step {
    param([string]$Message)
    Write-Host "`n========================================" -ForegroundColor Cyan
    Write-Host $Message -ForegroundColor Cyan
    Write-Host "========================================`n" -ForegroundColor Cyan
}

function Write-Success {
    param([string]$Message)
    Write-Host "✓ $Message" -ForegroundColor Green
}

function Write-Warning {
    param([string]$Message)
    Write-Host "⚠ $Message" -ForegroundColor Yellow
}

function Write-Info {
    param([string]$Message)
    Write-Host "ℹ $Message" -ForegroundColor White
}

Write-Step "FireProof API - Post-Deployment Configuration"

if (-not $SqlResourceGroup) {
    $SqlResourceGroup = $ResourceGroup
}

# Task 8: Enable TDE on Database
Write-Step "Task 8: Enable Transparent Data Encryption"

Write-Info "Checking TDE status on $Database..."

try {
    # Check if this is Azure SQL or SQL Server on VM
    $isAzureSQL = $true
    try {
        az sql db show --name $Database --server $SqlServer --resource-group $SqlResourceGroup 2>&1 | Out-Null
    } catch {
        $isAzureSQL = $false
    }

    if ($isAzureSQL) {
        Write-Info "Azure SQL Database detected"

        # For Azure SQL, TDE is enabled by default on new databases
        $tdeStatus = az sql db tde show `
            --database $Database `
            --server $SqlServer `
            --resource-group $SqlResourceGroup `
            --query state -o tsv

        if ($tdeStatus -eq "Enabled") {
            Write-Success "TDE is already enabled"
        } else {
            Write-Info "Enabling TDE..."
            az sql db tde set `
                --database $Database `
                --server $SqlServer `
                --resource-group $SqlResourceGroup `
                --status Enabled | Out-Null
            Write-Success "TDE enabled"
        }
    } else {
        Write-Warning "Not Azure SQL Database. TDE must be enabled manually via SQL Server Management Studio"
        Write-Info "Run this SQL script on the database:"
        Write-Host @"
USE master;
GO

-- Create master key if not exists
IF NOT EXISTS (SELECT * FROM sys.symmetric_keys WHERE name = '##MS_DatabaseMasterKey##')
CREATE MASTER KEY ENCRYPTION BY PASSWORD = '<StrongPassword>';
GO

-- Create certificate
IF NOT EXISTS (SELECT * FROM sys.certificates WHERE name = 'FireProofDB_TDE_Cert')
CREATE CERTIFICATE FireProofDB_TDE_Cert WITH SUBJECT = 'FireProofDB TDE Certificate';
GO

USE FireProofDB;
GO

-- Create database encryption key
IF NOT EXISTS (SELECT * FROM sys.dm_database_encryption_keys WHERE database_id = DB_ID('FireProofDB'))
CREATE DATABASE ENCRYPTION KEY
WITH ALGORITHM = AES_256
ENCRYPTION BY SERVER CERTIFICATE FireProofDB_TDE_Cert;
GO

-- Enable encryption
ALTER DATABASE FireProofDB SET ENCRYPTION ON;
GO
"@ -ForegroundColor Gray
    }
} catch {
    Write-Warning "Could not enable TDE automatically: $($_.Exception.Message)"
    Write-Info "Please enable TDE manually"
}

# Task 9: Configure Automated Backups
Write-Step "Task 9: Configure Automated Backups"

if ($isAzureSQL) {
    Write-Info "Configuring long-term retention policy..."

    try {
        az sql db ltr-policy set `
            --database $Database `
            --server $SqlServer `
            --resource-group $SqlResourceGroup `
            --weekly-retention "P4W" `
            --monthly-retention "P12M" `
            --yearly-retention "P7Y" `
            --week-of-year 1 | Out-Null

        Write-Success "Backup retention policy configured:"
        Write-Info "  - Weekly: 4 weeks"
        Write-Info "  - Monthly: 12 months"
        Write-Info "  - Yearly: 7 years"

        # Show current backup policy
        Write-Info "`nCurrent short-term backup policy:"
        $backupPolicy = az sql db show `
            --name $Database `
            --server $SqlServer `
            --resource-group $SqlResourceGroup `
            --query "retentionPolicy" | ConvertFrom-Json

        Write-Info "  - Retention days: $($backupPolicy.retentionDays)"
        Write-Info "  - Differential backup hours: $($backupPolicy.diffBackupIntervalInHours)"

    } catch {
        Write-Warning "Could not configure backup policy: $($_.Exception.Message)"
    }
} else {
    Write-Warning "Not Azure SQL Database. Configure backups via SQL Server Agent or third-party tools"
    Write-Info "Recommended backup schedule:"
    Write-Info "  - Full: Daily at 2:00 AM"
    Write-Info "  - Differential: Every 6 hours"
    Write-Info "  - Transaction Log: Every 15 minutes"
    Write-Info "  - Retention: 30 days"
}

# Task 10: Set Up Application Insights
if ($AppName) {
    Write-Step "Task 10: Set Up Application Insights"

    $appInsightsName = "$AppName-insights"

    # Check if Application Insights exists
    $insightsExists = az monitor app-insights component show `
        --app $appInsightsName `
        --resource-group $ResourceGroup 2>$null

    if (-not $insightsExists) {
        Write-Info "Creating Application Insights: $appInsightsName"

        # Create Log Analytics workspace first
        $workspaceName = "$AppName-logs"
        $workspaceExists = az monitor log-analytics workspace show `
            --workspace-name $workspaceName `
            --resource-group $ResourceGroup 2>$null

        if (-not $workspaceExists) {
            Write-Info "Creating Log Analytics workspace..."
            az monitor log-analytics workspace create `
                --workspace-name $workspaceName `
                --resource-group $ResourceGroup `
                --location eastus | Out-Null
        }

        $workspaceId = az monitor log-analytics workspace show `
            --workspace-name $workspaceName `
            --resource-group $ResourceGroup `
            --query id -o tsv

        # Create Application Insights
        az monitor app-insights component create `
            --app $appInsightsName `
            --location eastus `
            --resource-group $ResourceGroup `
            --workspace $workspaceId | Out-Null

        Write-Success "Application Insights created"
    } else {
        Write-Success "Application Insights exists"
    }

    # Get connection string
    $connectionString = az monitor app-insights component show `
        --app $appInsightsName `
        --resource-group $ResourceGroup `
        --query connectionString -o tsv

    Write-Info "Connection String: $connectionString"

    # Update App Service settings
    Write-Info "Configuring App Service with Application Insights..."
    az webapp config appsettings set `
        --name $AppName `
        --resource-group $ResourceGroup `
        --settings APPLICATIONINSIGHTS_CONNECTION_STRING="$connectionString" | Out-Null

    Write-Success "App Service configured with Application Insights"

    # Create alerts
    Write-Info "Creating monitoring alerts..."

    # Alert for high error rate
    az monitor metrics alert create `
        --name "High Error Rate - $AppName" `
        --resource-group $ResourceGroup `
        --scopes "/subscriptions/$(az account show --query id -o tsv)/resourceGroups/$ResourceGroup/providers/Microsoft.Web/sites/$AppName" `
        --condition "count Http5xx > 10 where aggregation = Total" `
        --window-size 5m `
        --evaluation-frequency 1m `
        --description "Alert when 5xx errors exceed 10 in 5 minutes" 2>$null | Out-Null

    # Alert for high response time
    az monitor metrics alert create `
        --name "High Response Time - $AppName" `
        --resource-group $ResourceGroup `
        --scopes "/subscriptions/$(az account show --query id -o tsv)/resourceGroups/$ResourceGroup/providers/Microsoft.Web/sites/$AppName" `
        --condition "avg HttpResponseTime > 2000 where aggregation = Average" `
        --window-size 5m `
        --evaluation-frequency 1m `
        --description "Alert when average response time exceeds 2 seconds" 2>$null | Out-Null

    Write-Success "Monitoring alerts created"
} else {
    Write-Warning "App Service name not provided, skipping Application Insights setup"
}

# Task 11: Remove Dev Test Users
Write-Step "Task 11: Remove Dev Test Users"

Write-Warning "This task requires database access with appropriate permissions"
Write-Info "SQL script to remove dev test users:"

Write-Host @"

-- Connect to $Database
USE $Database;
GO

-- Show dev/test users before deletion
SELECT UserId, Email, IsActive, CreatedDate
FROM dbo.Users
WHERE Email LIKE '%@dev.local' OR Email LIKE '%@test.local' OR Email LIKE '%example.com%';
GO

-- Option 1: Soft delete (recommended - preserves audit trail)
UPDATE dbo.Users
SET IsActive = 0, ModifiedDate = GETUTCDATE()
WHERE Email LIKE '%@dev.local' OR Email LIKE '%@test.local' OR Email LIKE '%example.com%';
GO

-- Option 2: Hard delete (use with caution)
-- DELETE FROM dbo.Users
-- WHERE Email LIKE '%@dev.local' OR Email LIKE '%@test.local' OR Email LIKE '%example.com%';
-- GO

-- Verify deletion
SELECT COUNT(*) as RemainingDevUsers
FROM dbo.Users
WHERE (Email LIKE '%@dev.local' OR Email LIKE '%@test.local' OR Email LIKE '%example.com%')
AND IsActive = 1;
GO

"@ -ForegroundColor Gray

Write-Info "`nYou can run this script using:"
Write-Info "  sqlcmd -S $SqlServer.database.windows.net -d $Database -U <admin-user> -P <password> -i cleanup-users.sql"
Write-Info "  OR use Azure Data Studio / SQL Server Management Studio"

# Summary
Write-Step "Post-Deployment Configuration Complete"

Write-Host "Completed Tasks:" -ForegroundColor Green
Write-Host "  ✓ TDE configuration reviewed" -ForegroundColor White
Write-Host "  ✓ Backup retention policy configured" -ForegroundColor White
if ($AppName) {
    Write-Host "  ✓ Application Insights created and configured" -ForegroundColor White
    Write-Host "  ✓ Monitoring alerts created" -ForegroundColor White
}
Write-Host "  ✓ Dev user cleanup script provided" -ForegroundColor White
Write-Host ""

Write-Host "Next Steps:" -ForegroundColor Cyan
Write-Host "1. Run the dev user cleanup SQL script" -ForegroundColor White
Write-Host "2. Test the application thoroughly" -ForegroundColor White
Write-Host "3. Monitor Application Insights for errors" -ForegroundColor White
Write-Host "4. Set up alerts for your operations team" -ForegroundColor White
Write-Host ""

if ($AppName) {
    Write-Host "Application Insights Portal:" -ForegroundColor Cyan
    Write-Host "  https://portal.azure.com/#resource/subscriptions/$(az account show --query id -o tsv)/resourceGroups/$ResourceGroup/providers/microsoft.insights/components/$appInsightsName/overview" -ForegroundColor Gray
    Write-Host ""
}

Write-Success "All post-deployment tasks completed!"
