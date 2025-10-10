<#
.SYNOPSIS
    Sets up Azure Key Vault for FireProof API secrets management

.DESCRIPTION
    Creates Azure Key Vault and stores all sensitive configuration values
    Supports Development, Staging, and Production environments

.PARAMETER Environment
    Target environment: Development, Staging, or Production

.PARAMETER ResourceGroup
    Azure Resource Group name (default: rg-fireproof)

.PARAMETER Location
    Azure region (default: eastus)

.EXAMPLE
    .\Setup-AzureKeyVault.ps1 -Environment Production -ResourceGroup rg-fireproof-prod
#>

param(
    [Parameter(Mandatory = $true)]
    [ValidateSet("Development", "Staging", "Production")]
    [string]$Environment,

    [Parameter(Mandatory = $false)]
    [string]$ResourceGroup = "rg-fireproof",

    [Parameter(Mandatory = $false)]
    [string]$Location = "eastus"
)

# Set error action preference
$ErrorActionPreference = "Stop"

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "FireProof Azure Key Vault Setup" -ForegroundColor Cyan
Write-Host "Environment: $Environment" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# Check if Azure CLI is installed
try {
    $azVersion = az version --output json | ConvertFrom-Json
    Write-Host "Azure CLI Version: $($azVersion.'azure-cli')" -ForegroundColor Green
} catch {
    Write-Error "Azure CLI is not installed. Please install from https://aka.ms/installazurecli"
    exit 1
}

# Check if logged in
Write-Host "Checking Azure login status..." -ForegroundColor Yellow
$account = az account show 2>$null
if (-not $account) {
    Write-Host "Not logged in to Azure. Please login..." -ForegroundColor Yellow
    az login
}

$accountInfo = az account show | ConvertFrom-Json
Write-Host "Logged in as: $($accountInfo.user.name)" -ForegroundColor Green
Write-Host "Subscription: $($accountInfo.name) ($($accountInfo.id))" -ForegroundColor Green
Write-Host ""

# Set Key Vault name based on environment
$envSuffix = $Environment.ToLower().Substring(0, [Math]::Min(4, $Environment.Length))
$keyVaultName = "kv-fireproof-$envSuffix"

Write-Host "Key Vault Name: $keyVaultName" -ForegroundColor Cyan
Write-Host ""

# Create Resource Group if it doesn't exist
Write-Host "Checking Resource Group: $ResourceGroup" -ForegroundColor Yellow
$rgExists = az group exists --name $ResourceGroup
if ($rgExists -eq "false") {
    Write-Host "Creating Resource Group: $ResourceGroup" -ForegroundColor Yellow
    az group create --name $ResourceGroup --location $Location
    Write-Host "Resource Group created successfully" -ForegroundColor Green
} else {
    Write-Host "Resource Group already exists" -ForegroundColor Green
}
Write-Host ""

# Create Key Vault if it doesn't exist
Write-Host "Checking Key Vault: $keyVaultName" -ForegroundColor Yellow
$kvExists = az keyvault list --resource-group $ResourceGroup --query "[?name=='$keyVaultName'].name" -o tsv
if (-not $kvExists) {
    Write-Host "Creating Key Vault: $keyVaultName" -ForegroundColor Yellow
    az keyvault create `
        --name $keyVaultName `
        --resource-group $ResourceGroup `
        --location $Location `
        --enable-rbac-authorization false `
        --enabled-for-deployment true `
        --enabled-for-template-deployment true

    Write-Host "Key Vault created successfully" -ForegroundColor Green
} else {
    Write-Host "Key Vault already exists" -ForegroundColor Green
}
Write-Host ""

# Grant current user access to Key Vault secrets
Write-Host "Granting access to current user..." -ForegroundColor Yellow
$currentUserId = az ad signed-in-user show --query id -o tsv
az keyvault set-policy `
    --name $keyVaultName `
    --object-id $currentUserId `
    --secret-permissions get list set delete purge recover backup restore

Write-Host "Access granted successfully" -ForegroundColor Green
Write-Host ""

# Generate secure secrets
Write-Host "Generating secure secrets..." -ForegroundColor Yellow

# Generate JWT Secret (64 characters, alphanumeric + special chars)
$jwtSecretBytes = [System.Security.Cryptography.RandomNumberGenerator]::GetBytes(48)
$jwtSecret = [Convert]::ToBase64String($jwtSecretBytes)

# Generate TamperProofing Signature Key (64 characters)
$tamperKeyBytes = [System.Security.Cryptography.RandomNumberGenerator]::GetBytes(48)
$tamperKey = [Convert]::ToBase64String($tamperKeyBytes)

Write-Host "Secrets generated successfully" -ForegroundColor Green
Write-Host ""

# Store secrets in Key Vault
Write-Host "Storing secrets in Key Vault..." -ForegroundColor Yellow

# JWT Secret
az keyvault secret set `
    --vault-name $keyVaultName `
    --name "JwtSecretKey" `
    --value $jwtSecret `
    --description "JWT token signing secret for $Environment environment"

# TamperProofing Signature Key
az keyvault secret set `
    --vault-name $keyVaultName `
    --name "TamperProofingSignatureKey" `
    --value $tamperKey `
    --description "Tamper-proofing signature key for $Environment environment"

# Database Connection String (prompt user)
Write-Host ""
Write-Host "Please enter the database connection string for ${Environment}:" -ForegroundColor Yellow
Write-Host "Example: Server=sqltest.schoolvision.net,14333;Database=FireProofDB;User Id=sv;Password=***;TrustServerCertificate=True;Encrypt=True" -ForegroundColor Gray
$dbConnectionString = Read-Host "Connection String"

if ($dbConnectionString) {
    az keyvault secret set `
        --vault-name $keyVaultName `
        --name "DatabaseConnectionString" `
        --value $dbConnectionString `
        --description "SQL Server connection string for $Environment environment"
    Write-Host "Database connection string stored" -ForegroundColor Green
}

Write-Host ""
Write-Host "All secrets stored successfully" -ForegroundColor Green
Write-Host ""

# Display Key Vault URI
$keyVaultUri = az keyvault show --name $keyVaultName --query properties.vaultUri -o tsv
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Key Vault Setup Complete!" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "Key Vault Name: $keyVaultName" -ForegroundColor White
Write-Host "Key Vault URI: $keyVaultUri" -ForegroundColor White
Write-Host ""
Write-Host "Secrets stored:" -ForegroundColor White
Write-Host "  - JwtSecretKey" -ForegroundColor Gray
Write-Host "  - TamperProofingSignatureKey" -ForegroundColor Gray
Write-Host "  - DatabaseConnectionString" -ForegroundColor Gray
Write-Host ""
Write-Host "Next Steps:" -ForegroundColor Yellow
Write-Host "1. Update appsettings.$Environment.json with:" -ForegroundColor White
Write-Host "   ""KeyVault"": {" -ForegroundColor Gray
Write-Host "     ""VaultUri"": ""$keyVaultUri""" -ForegroundColor Gray
Write-Host "   }" -ForegroundColor Gray
Write-Host ""
Write-Host "2. Configure Managed Identity or Service Principal for production" -ForegroundColor White
Write-Host "3. Test the configuration" -ForegroundColor White
Write-Host ""
Write-Host "For local development, ensure you're logged in with 'az login'" -ForegroundColor Yellow
Write-Host ""
