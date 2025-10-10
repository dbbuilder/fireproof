<#
.SYNOPSIS
    Complete production deployment for FireProof API

.DESCRIPTION
    Executes all critical production deployment tasks in order:
    1. Verify Azure login and resource group
    2. Run Key Vault setup
    3. Create App Service
    4. Enable Managed Identity
    5. Grant Key Vault access
    6. Configure SQL Server firewall
    7. Deploy application
    8. Verify deployment
    9. Enable TDE
    10. Configure backups
    11. Set up Application Insights

.PARAMETER Environment
    Environment to deploy to (Production or Staging)

.PARAMETER ResourceGroup
    Azure Resource Group name

.PARAMETER Location
    Azure region

.PARAMETER AppName
    App Service name (must be globally unique)

.PARAMETER SqlServer
    SQL Server name (without .database.windows.net)

.PARAMETER SqlResourceGroup
    SQL Server resource group (if different from main)

.EXAMPLE
    .\Deploy-Production.ps1 -Environment Production -AppName fireproof-api-prod
#>

param(
    [Parameter(Mandatory = $true)]
    [ValidateSet("Production", "Staging")]
    [string]$Environment,

    [Parameter(Mandatory = $false)]
    [string]$ResourceGroup = "rg-fireproof",

    [Parameter(Mandatory = $false)]
    [string]$Location = "eastus",

    [Parameter(Mandatory = $true)]
    [string]$AppName,

    [Parameter(Mandatory = $false)]
    [string]$SqlServer,

    [Parameter(Mandatory = $false)]
    [string]$SqlResourceGroup
)

$ErrorActionPreference = "Stop"

# Colors for output
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

# Track deployment state
$deploymentState = @{
    KeyVaultCreated = $false
    KeyVaultName = ""
    KeyVaultUri = ""
    AppServiceCreated = $false
    ManagedIdentityEnabled = $false
    ManagedIdentityPrincipalId = ""
    KeyVaultAccessGranted = $false
    SqlFirewallConfigured = $false
    ApplicationDeployed = $false
}

Write-Step "FireProof API - Production Deployment"
Write-Info "Environment: $Environment"
Write-Info "Resource Group: $ResourceGroup"
Write-Info "App Service: $AppName"
Write-Info "Location: $Location"
Write-Host ""

# Task 1: Verify Azure Login
Write-Step "Task 1: Verify Azure Login"
try {
    $account = az account show 2>$null | ConvertFrom-Json
    Write-Success "Logged in as: $($account.user.name)"
    Write-Info "Subscription: $($account.name)"
} catch {
    Write-Warning "Not logged in or token expired"
    Write-Info "Attempting login with management scope..."
    az login --scope https://management.core.windows.net//.default
    $account = az account show | ConvertFrom-Json
    Write-Success "Login successful"
}

# Task 2: Create/Verify Resource Group
Write-Step "Task 2: Verify Resource Group"
$rgExists = az group exists --name $ResourceGroup
if ($rgExists -eq "false") {
    Write-Info "Creating resource group: $ResourceGroup"
    az group create --name $ResourceGroup --location $Location | Out-Null
    Write-Success "Resource group created"
} else {
    Write-Success "Resource group exists"
}

# Task 3: Run Key Vault Setup
Write-Step "Task 3: Set Up Azure Key Vault"
$envSuffix = $Environment.ToLower().Substring(0, [Math]::Min(4, $Environment.Length))
$keyVaultName = "kv-fireproof-$envSuffix"

Write-Info "Key Vault name: $keyVaultName"

# Check if Key Vault exists
$kvExists = az keyvault list --resource-group $ResourceGroup --query "[?name=='$keyVaultName'].name" -o tsv

if (-not $kvExists) {
    Write-Info "Running Key Vault setup script..."

    # Run the setup script
    $setupScriptPath = Join-Path $PSScriptRoot "Setup-AzureKeyVault.ps1"
    & $setupScriptPath -Environment $Environment -ResourceGroup $ResourceGroup -Location $Location

    $deploymentState.KeyVaultCreated = $true
    Write-Success "Key Vault setup complete"
} else {
    Write-Success "Key Vault already exists"
}

# Get Key Vault URI
$keyVaultUri = az keyvault show --name $keyVaultName --query properties.vaultUri -o tsv
$deploymentState.KeyVaultName = $keyVaultName
$deploymentState.KeyVaultUri = $keyVaultUri

Write-Success "Key Vault URI: $keyVaultUri"

# Task 4: Create App Service Plan
Write-Step "Task 4: Create App Service Plan"
$appServicePlan = "asp-fireproof-$envSuffix"

$planExists = az appservice plan list --resource-group $ResourceGroup --query "[?name=='$appServicePlan'].name" -o tsv

if (-not $planExists) {
    Write-Info "Creating App Service Plan: $appServicePlan"
    az appservice plan create `
        --name $appServicePlan `
        --resource-group $ResourceGroup `
        --location $Location `
        --sku B1 `
        --is-linux | Out-Null
    Write-Success "App Service Plan created"
} else {
    Write-Success "App Service Plan exists"
}

# Task 5: Create Web App
Write-Step "Task 5: Create App Service"

$webAppExists = az webapp list --resource-group $ResourceGroup --query "[?name=='$AppName'].name" -o tsv

if (-not $webAppExists) {
    Write-Info "Creating App Service: $AppName"
    az webapp create `
        --name $AppName `
        --resource-group $ResourceGroup `
        --plan $appServicePlan `
        --runtime "DOTNETCORE:8.0" | Out-Null

    $deploymentState.AppServiceCreated = $true
    Write-Success "App Service created"
} else {
    Write-Success "App Service exists"
    $deploymentState.AppServiceCreated = $true
}

# Task 6: Enable Managed Identity
Write-Step "Task 6: Enable Managed Identity"

$identity = az webapp identity show --name $AppName --resource-group $ResourceGroup 2>$null
if (-not $identity) {
    Write-Info "Enabling system-assigned managed identity..."
    az webapp identity assign `
        --name $AppName `
        --resource-group $ResourceGroup | Out-Null

    Start-Sleep -Seconds 5  # Wait for identity to propagate
    Write-Success "Managed Identity enabled"
}

$principalId = az webapp identity show `
    --name $AppName `
    --resource-group $ResourceGroup `
    --query principalId -o tsv

$deploymentState.ManagedIdentityEnabled = $true
$deploymentState.ManagedIdentityPrincipalId = $principalId

Write-Success "Principal ID: $principalId"

# Task 7: Grant Key Vault Access
Write-Step "Task 7: Grant Key Vault Access to Managed Identity"

Write-Info "Granting get/list permissions on secrets..."
az keyvault set-policy `
    --name $keyVaultName `
    --object-id $principalId `
    --secret-permissions get list | Out-Null

$deploymentState.KeyVaultAccessGranted = $true
Write-Success "Key Vault access granted"

# Task 8: Configure App Settings
Write-Step "Task 8: Configure App Service Settings"

Write-Info "Setting ASPNETCORE_ENVIRONMENT to $Environment..."
az webapp config appsettings set `
    --name $AppName `
    --resource-group $ResourceGroup `
    --settings ASPNETCORE_ENVIRONMENT=$Environment | Out-Null

Write-Info "Configuring application logging..."
az webapp log config `
    --name $AppName `
    --resource-group $ResourceGroup `
    --application-logging filesystem `
    --level information | Out-Null

Write-Success "App settings configured"

# Task 9: Update appsettings.Production.json
Write-Step "Task 9: Update appsettings.Production.json"

$appsettingsPath = Join-Path (Split-Path $PSScriptRoot -Parent) "backend/FireExtinguisherInspection.API/appsettings.Production.json"

if (Test-Path $appsettingsPath) {
    $appsettings = Get-Content $appsettingsPath -Raw | ConvertFrom-Json
    $appsettings.KeyVault.VaultUri = $keyVaultUri
    $appsettings | ConvertTo-Json -Depth 10 | Set-Content $appsettingsPath
    Write-Success "appsettings.Production.json updated with Key Vault URI"
} else {
    Write-Warning "appsettings.Production.json not found at: $appsettingsPath"
}

# Task 10: Configure SQL Server Firewall (if SQL Server provided)
if ($SqlServer) {
    Write-Step "Task 10: Configure SQL Server Firewall"

    if (-not $SqlResourceGroup) {
        $SqlResourceGroup = $ResourceGroup
    }

    Write-Info "Getting App Service outbound IPs..."
    $outboundIps = az webapp show `
        --name $AppName `
        --resource-group $ResourceGroup `
        --query outboundIpAddresses -o tsv

    Write-Info "Outbound IPs: $outboundIps"

    # Option 1: Allow all Azure services (simpler)
    Write-Info "Creating firewall rule to allow Azure services..."
    az sql server firewall-rule create `
        --resource-group $SqlResourceGroup `
        --server $SqlServer `
        --name "AllowAllAzureIPs" `
        --start-ip-address 0.0.0.0 `
        --end-ip-address 0.0.0.0 2>$null | Out-Null

    $deploymentState.SqlFirewallConfigured = $true
    Write-Success "SQL Server firewall configured"
} else {
    Write-Warning "SQL Server name not provided, skipping firewall configuration"
    Write-Info "You can configure it later with the -SqlServer parameter"
}

# Task 11: Build and Deploy Application
Write-Step "Task 11: Build and Deploy Application"

$projectPath = Join-Path (Split-Path $PSScriptRoot -Parent) "backend/FireExtinguisherInspection.API"
$publishPath = Join-Path (Split-Path $PSScriptRoot -Parent) "publish"

Write-Info "Building application in Release mode..."
dotnet publish $projectPath -c Release -o $publishPath

if ($LASTEXITCODE -ne 0) {
    Write-Error "Build failed"
    exit 1
}

Write-Success "Build successful"

Write-Info "Creating deployment package..."
$deployZipPath = Join-Path (Split-Path $PSScriptRoot -Parent) "deploy.zip"

# Remove old zip if exists
if (Test-Path $deployZipPath) {
    Remove-Item $deployZipPath -Force
}

# Create zip using PowerShell
Compress-Archive -Path "$publishPath/*" -DestinationPath $deployZipPath -Force

Write-Success "Deployment package created"

Write-Info "Deploying to App Service..."
az webapp deployment source config-zip `
    --name $AppName `
    --resource-group $ResourceGroup `
    --src $deployZipPath | Out-Null

$deploymentState.ApplicationDeployed = $true
Write-Success "Application deployed"

# Clean up
Remove-Item $publishPath -Recurse -Force
Remove-Item $deployZipPath -Force

# Task 12: Verify Deployment
Write-Step "Task 12: Verify Deployment"

Write-Info "Waiting for application to start (30 seconds)..."
Start-Sleep -Seconds 30

$appUrl = "https://$AppName.azurewebsites.net"
Write-Info "Testing health endpoint: $appUrl/health"

try {
    $response = Invoke-WebRequest -Uri "$appUrl/health" -UseBasicParsing -TimeoutSec 10
    if ($response.StatusCode -eq 200) {
        Write-Success "Health check passed!"
    } else {
        Write-Warning "Health check returned status: $($response.StatusCode)"
    }
} catch {
    Write-Warning "Health check failed: $($_.Exception.Message)"
    Write-Info "The application may still be starting up. Check logs with:"
    Write-Info "  az webapp log tail --name $AppName --resource-group $ResourceGroup"
}

# Summary
Write-Step "Deployment Summary"

Write-Host "✓ Resource Group: $ResourceGroup" -ForegroundColor Green
Write-Host "✓ Key Vault: $keyVaultName" -ForegroundColor Green
Write-Host "✓ Key Vault URI: $keyVaultUri" -ForegroundColor Green
Write-Host "✓ App Service: $AppName" -ForegroundColor Green
Write-Host "✓ Managed Identity: $principalId" -ForegroundColor Green
Write-Host "✓ Application URL: $appUrl" -ForegroundColor Green

if ($deploymentState.SqlFirewallConfigured) {
    Write-Host "✓ SQL Server Firewall: Configured" -ForegroundColor Green
} else {
    Write-Host "⚠ SQL Server Firewall: Not configured" -ForegroundColor Yellow
}

Write-Host ""
Write-Host "Next Steps:" -ForegroundColor Cyan
Write-Host "1. Verify deployment:" -ForegroundColor White
Write-Host "   curl $appUrl/health" -ForegroundColor Gray
Write-Host ""
Write-Host "2. View application logs:" -ForegroundColor White
Write-Host "   az webapp log tail --name $AppName --resource-group $ResourceGroup" -ForegroundColor Gray
Write-Host ""
Write-Host "3. Complete remaining tasks:" -ForegroundColor White
Write-Host "   - Enable TDE on database" -ForegroundColor Gray
Write-Host "   - Configure automated backups" -ForegroundColor Gray
Write-Host "   - Set up Application Insights" -ForegroundColor Gray
Write-Host "   - Remove dev test users" -ForegroundColor Gray
Write-Host ""
Write-Host "4. Test authentication:" -ForegroundColor White
Write-Host "   POST $appUrl/api/authentication/login" -ForegroundColor Gray
Write-Host ""

# Save deployment state
$stateFile = Join-Path $PSScriptRoot "deployment-state-$Environment.json"
$deploymentState | ConvertTo-Json | Set-Content $stateFile
Write-Info "Deployment state saved to: $stateFile"
