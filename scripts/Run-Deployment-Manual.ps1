<#
.SYNOPSIS
    Manual step-by-step deployment guide for FireProof API

.DESCRIPTION
    This script provides commands to run manually for production deployment.
    Use this if automated scripts have authentication issues.

.NOTES
    Run each section in order, verifying success before proceeding.
#>

Write-Host @"
========================================
FireProof API - Manual Deployment Guide
========================================

Environment: Production (Test Environment Subscription)
Subscription: Test Environment (7b2beff3-b38a-4516-a75f-3216725cc4e9)
Tenant: DBBuilder (2ee5658f-a9c4-49f3-9df9-998399e3a73e)

Follow these steps in order:

========================================
STEP 1: Authenticate to Azure
========================================

Run this command in PowerShell:

"@ -ForegroundColor Cyan

Write-Host 'az login' -ForegroundColor Yellow
Write-Host ''
Write-Host 'Then verify your subscription:' -ForegroundColor White
Write-Host 'az account show' -ForegroundColor Yellow
Write-Host ''
Write-Host 'Press ENTER when authenticated...' -ForegroundColor Green
Read-Host

Write-Host @"

========================================
STEP 2: Set Variables
========================================

Run these commands to set your deployment variables:

"@ -ForegroundColor Cyan

$script = @'
# Edit these values as needed
$ResourceGroup = "rg-fireproof"
$Location = "eastus"
$AppName = "fireproof-api-test"  # Must be globally unique
$SqlServer = "sqltest"
$SqlDatabase = "FireProofDB"
$Environment = "Production"

# Verify values
Write-Host "Resource Group: $ResourceGroup" -ForegroundColor Green
Write-Host "App Name: $AppName" -ForegroundColor Green
Write-Host "SQL Server: $SqlServer" -ForegroundColor Green
Write-Host "Database: $SqlDatabase" -ForegroundColor Green
'@

Write-Host $script -ForegroundColor Yellow
Write-Host ''
Write-Host 'Copy and run the above commands, then press ENTER...' -ForegroundColor Green
Read-Host

Write-Host @"

========================================
STEP 3: Create Resource Group
========================================

"@ -ForegroundColor Cyan

Write-Host 'az group create --name $ResourceGroup --location $Location' -ForegroundColor Yellow
Write-Host ''
Write-Host 'Press ENTER when complete...' -ForegroundColor Green
Read-Host

Write-Host @"

========================================
STEP 4: Run Key Vault Setup
========================================

This will create the Key Vault and generate secure secrets.

"@ -ForegroundColor Cyan

Write-Host 'cd /mnt/d/dev2/fireproof' -ForegroundColor Yellow
Write-Host './scripts/Setup-AzureKeyVault.ps1 -Environment $Environment -ResourceGroup $ResourceGroup -Location $Location' -ForegroundColor Yellow
Write-Host ''
Write-Host 'IMPORTANT: Note the Key Vault URI from the output!' -ForegroundColor Red
Write-Host ''
Write-Host 'Enter the Key Vault URI (e.g., https://kv-fireproof-prod.vault.azure.net/):' -ForegroundColor Green
$KeyVaultUri = Read-Host

Write-Host @"

========================================
STEP 5: Update appsettings.Production.json
========================================

"@ -ForegroundColor Cyan

Write-Host @"
Edit this file: backend/FireExtinguisherInspection.API/appsettings.Production.json

Update the KeyVault section:
{
  "KeyVault": {
    "VaultUri": "$KeyVaultUri"
  }
}

"@ -ForegroundColor Yellow

Write-Host 'Press ENTER when file is updated...' -ForegroundColor Green
Read-Host

Write-Host @"

========================================
STEP 6: Create App Service Plan
========================================

"@ -ForegroundColor Cyan

Write-Host '$AppServicePlan = "asp-fireproof-prod"' -ForegroundColor Yellow
Write-Host 'az appservice plan create --name $AppServicePlan --resource-group $ResourceGroup --location $Location --sku B1 --is-linux' -ForegroundColor Yellow
Write-Host ''
Write-Host 'Press ENTER when complete...' -ForegroundColor Green
Read-Host

Write-Host @"

========================================
STEP 7: Create App Service
========================================

"@ -ForegroundColor Cyan

Write-Host 'az webapp create --name $AppName --resource-group $ResourceGroup --plan $AppServicePlan --runtime "DOTNETCORE:8.0"' -ForegroundColor Yellow
Write-Host ''
Write-Host 'Press ENTER when complete...' -ForegroundColor Green
Read-Host

Write-Host @"

========================================
STEP 8: Enable Managed Identity
========================================

"@ -ForegroundColor Cyan

Write-Host 'az webapp identity assign --name $AppName --resource-group $ResourceGroup' -ForegroundColor Yellow
Write-Host ''
Write-Host '$PrincipalId = az webapp identity show --name $AppName --resource-group $ResourceGroup --query principalId -o tsv' -ForegroundColor Yellow
Write-Host 'Write-Host "Principal ID: $PrincipalId"' -ForegroundColor Yellow
Write-Host ''
Write-Host 'Press ENTER when you have the Principal ID...' -ForegroundColor Green
Read-Host

Write-Host @"

========================================
STEP 9: Grant Key Vault Access
========================================

"@ -ForegroundColor Cyan

Write-Host '$KeyVaultName = "kv-fireproof-prod"' -ForegroundColor Yellow
Write-Host 'az keyvault set-policy --name $KeyVaultName --object-id $PrincipalId --secret-permissions get list' -ForegroundColor Yellow
Write-Host ''
Write-Host 'Press ENTER when complete...' -ForegroundColor Green
Read-Host

Write-Host @"

========================================
STEP 10: Configure App Settings
========================================

"@ -ForegroundColor Cyan

Write-Host 'az webapp config appsettings set --name $AppName --resource-group $ResourceGroup --settings ASPNETCORE_ENVIRONMENT=Production' -ForegroundColor Yellow
Write-Host 'az webapp log config --name $AppName --resource-group $ResourceGroup --application-logging filesystem --level information' -ForegroundColor Yellow
Write-Host ''
Write-Host 'Press ENTER when complete...' -ForegroundColor Green
Read-Host

Write-Host @"

========================================
STEP 11: Configure SQL Server Firewall
========================================

"@ -ForegroundColor Cyan

Write-Host 'az sql server firewall-rule create --resource-group $ResourceGroup --server $SqlServer --name "AllowAllAzureIPs" --start-ip-address 0.0.0.0 --end-ip-address 0.0.0.0' -ForegroundColor Yellow
Write-Host ''
Write-Host 'Press ENTER when complete...' -ForegroundColor Green
Read-Host

Write-Host @"

========================================
STEP 12: Build and Deploy Application
========================================

"@ -ForegroundColor Cyan

Write-Host @'
cd /mnt/d/dev2/fireproof
dotnet publish backend/FireExtinguisherInspection.API -c Release -o ./publish
Compress-Archive -Path ./publish/* -DestinationPath ./deploy.zip -Force
az webapp deployment source config-zip --name $AppName --resource-group $ResourceGroup --src ./deploy.zip
Remove-Item ./publish -Recurse -Force
Remove-Item ./deploy.zip -Force
'@ -ForegroundColor Yellow

Write-Host ''
Write-Host 'Press ENTER when deployment is complete...' -ForegroundColor Green
Read-Host

Write-Host @"

========================================
STEP 13: Verify Deployment
========================================

"@ -ForegroundColor Cyan

Write-Host 'Start-Sleep -Seconds 30' -ForegroundColor Yellow
Write-Host 'Invoke-WebRequest -Uri "https://$AppName.azurewebsites.net/health"' -ForegroundColor Yellow
Write-Host ''
Write-Host 'Or use curl:' -ForegroundColor White
Write-Host 'curl https://$AppName.azurewebsites.net/health' -ForegroundColor Yellow
Write-Host ''
Write-Host 'View logs:' -ForegroundColor White
Write-Host 'az webapp log tail --name $AppName --resource-group $ResourceGroup' -ForegroundColor Yellow
Write-Host ''

Write-Host @"

========================================
DEPLOYMENT COMPLETE!
========================================

Your application should now be running at:
https://$AppName.azurewebsites.net

Next steps:
1. Run post-deployment configuration:
   ./scripts/Configure-PostDeployment.ps1 -SqlServer $SqlServer -Database $SqlDatabase -AppName $AppName -ResourceGroup $ResourceGroup

2. Test the API endpoints
3. Set up monitoring and alerts

"@ -ForegroundColor Green

Write-Host 'Deployment guide complete!' -ForegroundColor Cyan
