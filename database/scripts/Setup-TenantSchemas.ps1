#!/usr/bin/env pwsh
<#
.SYNOPSIS
    Sets up tenant schemas and seed data for FireProof database

.DESCRIPTION
    This script connects to the FireProof database and:
    1. Checks which tenants exist in dbo.Tenants
    2. For each tenant, checks if the tenant schema exists
    3. Creates missing schemas
    4. Creates tenant-specific tables and stored procedures
    5. Runs seed data scripts

.PARAMETER Server
    SQL Server instance (default: sqltest.schoolvision.net,14333)

.PARAMETER Database
    Database name (default: FireProofDB)

.PARAMETER Username
    SQL Server username (default: sv)

.PARAMETER Password
    SQL Server password

.EXAMPLE
    ./Setup-TenantSchemas.ps1 -Password "Gv51076!"
#>

param(
    [string]$Server = "sqltest.schoolvision.net,14333",
    [string]$Database = "FireProofDB",
    [string]$Username = "sv",
    [string]$Password = "Gv51076!"
)

$ErrorActionPreference = "Stop"

# Color output functions
function Write-Info { param($Message) Write-Host $Message -ForegroundColor Cyan }
function Write-Success { param($Message) Write-Host "✓ $Message" -ForegroundColor Green }
function Write-Warning { param($Message) Write-Host "⚠ $Message" -ForegroundColor Yellow }
function Write-Error { param($Message) Write-Host "✗ $Message" -ForegroundColor Red }

Write-Info "========================================="
Write-Info "FireProof Tenant Schema Setup"
Write-Info "========================================="
Write-Info "Server: $Server"
Write-Info "Database: $Database"
Write-Info ""

# Test database connectivity
Write-Info "Testing database connectivity..."
try {
    $testQuery = "SELECT @@VERSION AS Version"
    $result = sqlcmd -S $Server -d $Database -U $Username -P $Password -C -Q $testQuery -h -1 -W
    if ($LASTEXITCODE -eq 0) {
        Write-Success "Database connection successful"
    } else {
        Write-Error "Database connection failed"
        exit 1
    }
} catch {
    Write-Error "Failed to connect to database: $_"
    exit 1
}

# Get all tenants
Write-Info ""
Write-Info "Retrieving tenants from database..."
$getTenants = @"
SET NOCOUNT ON;
SELECT
    CAST(TenantId AS NVARCHAR(36)) AS TenantId,
    CompanyName,
    DatabaseSchema,
    IsActive
FROM dbo.Tenants
ORDER BY CreatedDate
"@

$tenants = sqlcmd -S $Server -d $Database -U $Username -P $Password -C -Q $getTenants -h -1 -s "," -W

if ($LASTEXITCODE -ne 0 -or -not $tenants) {
    Write-Error "Failed to retrieve tenants or no tenants found"
    exit 1
}

Write-Success "Found $($tenants.Count) tenant(s)"

# Process each tenant
foreach ($tenantLine in $tenants) {
    if ([string]::IsNullOrWhiteSpace($tenantLine)) { continue }

    $parts = $tenantLine -split ','
    if ($parts.Count -lt 4) { continue }

    $tenantId = $parts[0].Trim()
    $companyName = $parts[1].Trim()
    $databaseSchema = $parts[2].Trim()
    $isActive = $parts[3].Trim()

    Write-Info ""
    Write-Info "========================================="
    Write-Info "Processing Tenant: $companyName"
    Write-Info "  Tenant ID: $tenantId"
    Write-Info "  Schema: $databaseSchema"
    Write-Info "  Active: $isActive"
    Write-Info "========================================="

    if ($isActive -ne "1") {
        Write-Warning "Tenant is not active, skipping..."
        continue
    }

    if ([string]::IsNullOrWhiteSpace($databaseSchema)) {
        Write-Warning "DatabaseSchema is NULL or empty"

        # Generate schema name
        $databaseSchema = "tenant_$($tenantId.ToUpper())"
        Write-Info "Generated schema name: $databaseSchema"

        # Update tenant record with schema name
        $updateTenant = @"
UPDATE dbo.Tenants
SET DatabaseSchema = '$databaseSchema',
    ModifiedDate = GETUTCDATE()
WHERE TenantId = '$tenantId'
"@
        Write-Info "Updating tenant record with schema name..."
        sqlcmd -S $Server -d $Database -U $Username -P $Password -C -Q $updateTenant -h -1

        if ($LASTEXITCODE -eq 0) {
            Write-Success "Updated tenant record"
        } else {
            Write-Error "Failed to update tenant record"
            continue
        }
    }

    # Check if schema exists
    $checkSchema = @"
SET NOCOUNT ON;
SELECT COUNT(*) FROM sys.schemas WHERE name = '$databaseSchema'
"@

    $schemaExists = sqlcmd -S $Server -d $Database -U $Username -P $Password -C -Q $checkSchema -h -1 -W
    $schemaExists = [int]$schemaExists.Trim()

    if ($schemaExists -eq 0) {
        Write-Info "Schema does not exist, creating..."

        # Create schema
        $createSchema = "CREATE SCHEMA [$databaseSchema]"
        sqlcmd -S $Server -d $Database -U $Username -P $Password -C -Q $createSchema -h -1

        if ($LASTEXITCODE -eq 0) {
            Write-Success "Created schema: $databaseSchema"
        } else {
            Write-Error "Failed to create schema"
            continue
        }
    } else {
        Write-Success "Schema already exists"
    }

    # Create tenant tables
    Write-Info "Creating tenant tables..."
    $scriptPath = Join-Path $PSScriptRoot "002_CreateTenantSchema.sql"

    if (Test-Path $scriptPath) {
        # Read the script and replace {tenant_schema} placeholder
        $sqlScript = Get-Content $scriptPath -Raw
        $sqlScript = $sqlScript -replace '\{tenant_schema\}', $databaseSchema

        # Save to temp file
        $tempFile = [System.IO.Path]::GetTempFileName()
        $sqlScript | Out-File -FilePath $tempFile -Encoding UTF8

        # Execute
        sqlcmd -S $Server -d $Database -U $Username -P $Password -C -i $tempFile -h -1

        if ($LASTEXITCODE -eq 0) {
            Write-Success "Created tenant tables"
        } else {
            Write-Warning "Some errors occurred creating tables (may already exist)"
        }

        Remove-Item $tempFile -Force
    } else {
        Write-Warning "Table creation script not found: $scriptPath"
    }

    # Create tenant stored procedures
    Write-Info "Creating tenant stored procedures..."
    $spScriptPath = Join-Path $PSScriptRoot "004_CreateTenantStoredProcedures.sql"

    if (Test-Path $spScriptPath) {
        # Read the script and replace {tenant_schema} placeholder
        $sqlScript = Get-Content $spScriptPath -Raw
        $sqlScript = $sqlScript -replace '\{tenant_schema\}', $databaseSchema

        # Save to temp file
        $tempFile = [System.IO.Path]::GetTempFileName()
        $sqlScript | Out-File -FilePath $tempFile -Encoding UTF8

        # Execute
        sqlcmd -S $Server -d $Database -U $Username -P $Password -C -i $tempFile -h -1

        if ($LASTEXITCODE -eq 0) {
            Write-Success "Created tenant stored procedures"
        } else {
            Write-Warning "Some errors occurred creating stored procedures (may already exist)"
        }

        Remove-Item $tempFile -Force
    } else {
        Write-Warning "Stored procedure script not found: $spScriptPath"
    }

    # Check if tenant has any data
    $checkData = @"
SET NOCOUNT ON;
SELECT COUNT(*) FROM [$databaseSchema].Locations
"@

    $dataCount = sqlcmd -S $Server -d $Database -U $Username -P $Password -C -Q $checkData -h -1 -W 2>$null

    if ($LASTEXITCODE -eq 0) {
        $dataCount = [int]$dataCount.Trim()

        if ($dataCount -eq 0) {
            Write-Info "No data found, creating seed data..."

            # Create seed data script for this tenant
            $seedScript = @"
USE [$Database]
GO

DECLARE @TenantId UNIQUEIDENTIFIER = '$tenantId'
DECLARE @Schema NVARCHAR(128) = '$databaseSchema'

-- Create sample location
DECLARE @LocationId UNIQUEIDENTIFIER = NEWID()
INSERT INTO [$databaseSchema].Locations (LocationId, TenantId, LocationName, Address, City, StateProvince, PostalCode, Country, ContactPerson, ContactPhone, ContactEmail, IsActive)
VALUES (@LocationId, @TenantId, 'Main Office', '123 Main St', 'Springfield', 'IL', '62701', 'USA', 'John Doe', '555-0100', 'john.doe@example.com', 1)

PRINT 'Created location: ' + CAST(@LocationId AS NVARCHAR(36))

-- Create sample extinguisher type
DECLARE @TypeId UNIQUEIDENTIFIER = NEWID()
INSERT INTO [$databaseSchema].ExtinguisherTypes (TypeId, TenantId, TypeName, TypeCode, Description, AgentType, Capacity, InspectionIntervalMonths, HydroTestIntervalYears, IsActive)
VALUES (@TypeId, @TenantId, 'ABC Dry Chemical', 'ABC-10', '10lb ABC Dry Chemical Fire Extinguisher', 'Dry Chemical', '10 lbs', 12, 6, 1)

PRINT 'Created extinguisher type: ' + CAST(@TypeId AS NVARCHAR(36))

-- Create sample checklist template
DECLARE @TemplateId UNIQUEIDENTIFIER = NEWID()
INSERT INTO [$databaseSchema].ChecklistTemplates (TemplateId, TenantId, TemplateName, Description, InspectionType, IsActive)
VALUES (@TemplateId, @TenantId, 'Annual Inspection', 'Comprehensive annual fire extinguisher inspection', 'Annual', 1)

-- Add checklist items
INSERT INTO [$databaseSchema].ChecklistItems (ItemId, TemplateId, ItemOrder, ItemText, RequiresPhoto, RequiresNote, PassFailNA, IsRequired)
VALUES
    (NEWID(), @TemplateId, 1, 'Check pressure gauge - must be in green zone', 1, 1, 'PassFailNA', 1),
    (NEWID(), @TemplateId, 2, 'Verify tamper seal is intact', 1, 1, 'PassFailNA', 1),
    (NEWID(), @TemplateId, 3, 'Check for physical damage or corrosion', 1, 1, 'PassFailNA', 1),
    (NEWID(), @TemplateId, 4, 'Verify inspection tag is legible', 1, 1, 'PassFailNA', 1),
    (NEWID(), @TemplateId, 5, 'Check hose and nozzle for obstructions', 1, 1, 'PassFailNA', 1)

PRINT 'Created checklist template with 5 items'

-- Create sample extinguisher
DECLARE @ExtinguisherId UNIQUEIDENTIFIER = NEWID()
INSERT INTO [$databaseSchema].Extinguishers (
    ExtinguisherId, TenantId, LocationId, TypeId, SerialNumber,
    Manufacturer, ManufactureDate, InstallDate,
    FloorLevel, SpecificLocation, GPSLatitude, GPSLongitude,
    LastInspectionDate, NextInspectionDate,
    LastHydroTestDate, NextHydroTestDate,
    IsActive, IsOutOfService
)
VALUES (
    @ExtinguisherId, @TenantId, @LocationId, @TypeId, 'EXT-001',
    'ACME Fire Safety', '2023-01-15', '2023-02-01',
    '1st Floor', 'Near Main Entrance', 41.8781, -87.6298,
    DATEADD(month, -3, GETUTCDATE()), DATEADD(month, 9, GETUTCDATE()),
    DATEADD(year, -2, GETUTCDATE()), DATEADD(year, 4, GETUTCDATE()),
    1, 0
)

PRINT 'Created sample extinguisher: ' + CAST(@ExtinguisherId AS NVARCHAR(36))
PRINT ''
PRINT '✓ Seed data created successfully for tenant: $companyName'
"@

            # Save to temp file
            $tempFile = [System.IO.Path]::GetTempFileName()
            $seedScript | Out-File -FilePath $tempFile -Encoding UTF8

            # Execute
            sqlcmd -S $Server -d $Database -U $Username -P $Password -C -i $tempFile

            if ($LASTEXITCODE -eq 0) {
                Write-Success "Created seed data"
            } else {
                Write-Warning "Some errors occurred creating seed data"
            }

            Remove-Item $tempFile -Force
        } else {
            Write-Success "Tenant already has $dataCount location(s)"
        }
    } else {
        Write-Warning "Could not check tenant data (Locations table may not exist)"
    }
}

Write-Info ""
Write-Info "========================================="
Write-Success "Tenant schema setup complete!"
Write-Info "========================================="
