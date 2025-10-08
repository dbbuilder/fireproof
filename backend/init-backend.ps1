# FireProof Backend Initialization Script
# Run this script to create the .NET solution and project structure

Write-Host "FireProof Backend Project Initialization" -ForegroundColor Green
Write-Host "=========================================" -ForegroundColor Green
Write-Host ""

# Check if .NET SDK is installed
try {
    $dotnetVersion = dotnet --version
    Write-Host "✓ .NET SDK detected: $dotnetVersion" -ForegroundColor Green
} catch {
    Write-Host "✗ .NET SDK not found. Please install .NET 8.0 SDK" -ForegroundColor Red
    Write-Host "  Download from: https://dotnet.microsoft.com/download" -ForegroundColor Yellow
    exit 1
}

Write-Host ""

# Navigate to backend directory
$backendPath = "D:\dev2\fireproof\backend"
Set-Location $backendPath

Write-Host "Creating .NET Solution..." -ForegroundColor Cyan

# Create solution
dotnet new sln -n FireExtinguisherInspection

Write-Host "Creating API Project..." -ForegroundColor Cyan

# Create Web API project
dotnet new webapi -n FireExtinguisherInspection.API --framework net8.0 --no-https false

# Add project to solution
dotnet sln add FireExtinguisherInspection.API/FireExtinguisherInspection.API.csproj

Write-Host ""
Write-Host "Installing NuGet Packages..." -ForegroundColor Cyan
Write-Host "This may take a few minutes..." -ForegroundColor Yellow
Write-Host ""

Set-Location FireExtinguisherInspection.API

# Core packages
Write-Host "Installing Entity Framework Core..." -ForegroundColor Gray
dotnet add package Microsoft.EntityFrameworkCore.SqlServer --version 8.0.0
dotnet add package Microsoft.Data.SqlClient --version 5.1.0

# Authentication
Write-Host "Installing Authentication packages..." -ForegroundColor Gray
dotnet add package Microsoft.Identity.Web --version 2.15.0

# Logging
Write-Host "Installing Serilog..." -ForegroundColor Gray
dotnet add package Serilog.AspNetCore --version 8.0.0
dotnet add package Serilog.Sinks.ApplicationInsights --version 4.0.0

# Resilience
Write-Host "Installing Polly..." -ForegroundColor Gray
dotnet add package Polly --version 8.0.0

# Background Jobs
Write-Host "Installing Hangfire..." -ForegroundColor Gray
dotnet add package Hangfire.AspNetCore --version 1.8.0
dotnet add package Hangfire.SqlServer --version 1.8.0

# Azure SDKs
Write-Host "Installing Azure SDKs..." -ForegroundColor Gray
dotnet add package Azure.Storage.Blobs --version 12.19.0
dotnet add package Azure.Identity --version 1.10.0
dotnet add package Azure.Security.KeyVault.Secrets --version 4.5.0

# Utilities
Write-Host "Installing Swagger..." -ForegroundColor Gray
dotnet add package Swashbuckle.AspNetCore --version 6.5.0

Write-Host ""
Write-Host "Restoring packages..." -ForegroundColor Cyan
dotnet restore

Write-Host ""
Write-Host "Building project..." -ForegroundColor Cyan
dotnet build

Write-Host ""
Write-Host "=========================================" -ForegroundColor Green
Write-Host "✓ Backend initialization complete!" -ForegroundColor Green
Write-Host ""
Write-Host "Next steps:" -ForegroundColor Yellow
Write-Host "1. Configure appsettings.json with your Azure connection strings" -ForegroundColor White
Write-Host "2. Run database scripts (001, 002, 003, 004) in order" -ForegroundColor White
Write-Host "3. Start the API: dotnet run --project FireExtinguisherInspection.API" -ForegroundColor White
Write-Host ""
Write-Host "API will be available at: https://localhost:7001" -ForegroundColor Cyan
Write-Host "Swagger UI: https://localhost:7001/swagger" -ForegroundColor Cyan
Write-Host ""
