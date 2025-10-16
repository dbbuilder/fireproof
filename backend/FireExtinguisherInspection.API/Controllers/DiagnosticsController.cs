using FireExtinguisherInspection.API.Models;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.Data.SqlClient;
using System.Data;

namespace FireExtinguisherInspection.API.Controllers;

/// <summary>
/// Diagnostic endpoints for troubleshooting backend issues
/// IMPORTANT: These endpoints expose system information and should be restricted or removed in production
/// </summary>
[ApiController]
[Route("api/[controller]")]
[AllowAnonymous] // Allow anonymous access for diagnostic purposes
public class DiagnosticsController : ControllerBase
{
    private readonly TenantContext _tenantContext;
    private readonly IConfiguration _configuration;
    private readonly ILogger<DiagnosticsController> _logger;

    public DiagnosticsController(
        TenantContext tenantContext,
        IConfiguration configuration,
        ILogger<DiagnosticsController> logger)
    {
        _tenantContext = tenantContext;
        _configuration = configuration;
        _logger = logger;
    }

    /// <summary>
    /// Test database connectivity and return detailed connection information
    /// </summary>
    [HttpGet("test-db")]
    public async Task<ActionResult> TestDatabase([FromQuery] Guid? tenantId = null)
    {
        try
        {
            var effectiveTenantId = tenantId ?? _tenantContext.TenantId;
            var connString = _configuration["DatabaseConnectionString"]
                ?? _configuration.GetConnectionString("DefaultConnection");

            // Mask password in connection string for safe output
            var safeConnString = MaskPassword(connString);

            using var connection = new SqlConnection(connString);
            await connection.OpenAsync();

            // Test basic connectivity
            var serverVersion = connection.ServerVersion;
            var database = connection.Database;

            // Check if tenant exists in dbo.Tenants
            bool tenantExists = false;
            string? tenantName = null;
            string? databaseSchema = null;

            if (effectiveTenantId != Guid.Empty)
            {
                using var cmd = new SqlCommand(
                    "SELECT CompanyName, DatabaseSchema FROM dbo.Tenants WHERE TenantId = @TenantId AND IsActive = 1",
                    connection);
                cmd.Parameters.AddWithValue("@TenantId", effectiveTenantId);

                using var reader = await cmd.ExecuteReaderAsync();
                if (await reader.ReadAsync())
                {
                    tenantExists = true;
                    tenantName = reader.GetString(0);
                    databaseSchema = reader.IsDBNull(1) ? null : reader.GetString(1);
                }
            }

            // Check if tenant schema exists
            bool schemaExists = false;

            if (!string.IsNullOrEmpty(databaseSchema))
            {
                using var cmd = new SqlCommand(
                    "SELECT COUNT(*) FROM sys.schemas WHERE name = @SchemaName",
                    connection);
                cmd.Parameters.AddWithValue("@SchemaName", databaseSchema);

                var count = (int)(await cmd.ExecuteScalarAsync() ?? 0);
                schemaExists = count > 0;
            }

            // Check if usp_Extinguisher_GetAll exists for tenant
            bool spExists = false;

            if (schemaExists && !string.IsNullOrEmpty(databaseSchema))
            {
                using var cmd = new SqlCommand(@"
                    SELECT COUNT(*)
                    FROM sys.procedures p
                    JOIN sys.schemas s ON p.schema_id = s.schema_id
                    WHERE s.name = @SchemaName AND p.name = 'usp_Extinguisher_GetAll'",
                    connection);
                cmd.Parameters.AddWithValue("@SchemaName", databaseSchema);

                var count = (int)(await cmd.ExecuteScalarAsync() ?? 0);
                spExists = count > 0;
            }

            // Try to call the stored procedure if it exists
            string? spTestResult = null;
            string? spTestError = null;

            if (spExists && !string.IsNullOrEmpty(databaseSchema))
            {
                try
                {
                    using var cmd = new SqlCommand($"{databaseSchema}.usp_Extinguisher_GetAll", connection);
                    cmd.CommandType = CommandType.StoredProcedure;
                    cmd.Parameters.AddWithValue("@TenantId", effectiveTenantId);

                    using var reader = await cmd.ExecuteReaderAsync();
                    int rowCount = 0;
                    while (await reader.ReadAsync())
                    {
                        rowCount++;
                    }
                    spTestResult = $"Stored procedure executed successfully, returned {rowCount} rows";
                }
                catch (Exception spEx)
                {
                    spTestError = $"{spEx.Message}\n{spEx.StackTrace}";
                }
            }

            return Ok(new
            {
                success = true,
                serverVersion,
                database,
                connectionString = safeConnString,
                tenantCheck = new
                {
                    requestedTenantId = effectiveTenantId,
                    tenantExists,
                    tenantName,
                    databaseSchema,
                    schemaExists,
                    storedProcedureExists = spExists,
                    storedProcedureTest = spTestResult,
                    storedProcedureError = spTestError
                },
                message = tenantExists
                    ? (schemaExists
                        ? (spExists
                            ? (spTestError == null
                                ? "Tenant schema and stored procedures are working correctly"
                                : "Tenant schema and stored procedures exist but execution failed")
                            : "Tenant schema exists but stored procedures are missing")
                        : "Tenant exists but schema not created in database")
                    : (effectiveTenantId != Guid.Empty
                        ? $"Tenant {effectiveTenantId} not found in database"
                        : "No tenant ID provided")
            });
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Database diagnostic test failed");
            return StatusCode(500, new
            {
                success = false,
                error = ex.Message,
                stackTrace = ex.StackTrace,
                innerError = ex.InnerException?.Message
            });
        }
    }

    /// <summary>
    /// List all tenants in the database
    /// </summary>
    [HttpGet("list-tenants")]
    public async Task<ActionResult> ListTenants()
    {
        try
        {
            var connString = _configuration["DatabaseConnectionString"]
                ?? _configuration.GetConnectionString("DefaultConnection");

            using var connection = new SqlConnection(connString);
            await connection.OpenAsync();

            using var cmd = new SqlCommand(@"
                SELECT TenantId, CompanyName, DatabaseSchema, IsActive, CreatedDate
                FROM dbo.Tenants
                ORDER BY CreatedDate DESC",
                connection);

            var tenants = new List<object>();
            using var reader = await cmd.ExecuteReaderAsync();

            while (await reader.ReadAsync())
            {
                tenants.Add(new
                {
                    tenantId = reader.GetGuid(0),
                    companyName = reader.GetString(1),
                    databaseSchema = reader.IsDBNull(2) ? null : reader.GetString(2),
                    isActive = reader.GetBoolean(3),
                    createdDate = reader.GetDateTime(4)
                });
            }

            return Ok(new
            {
                success = true,
                count = tenants.Count,
                tenants
            });
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Failed to list tenants");
            return StatusCode(500, new
            {
                success = false,
                error = ex.Message
            });
        }
    }

    /// <summary>
    /// Check if tenant schemas exist for all active tenants
    /// </summary>
    [HttpGet("check-schemas")]
    public async Task<ActionResult> CheckSchemas()
    {
        try
        {
            var connString = _configuration["DatabaseConnectionString"]
                ?? _configuration.GetConnectionString("DefaultConnection");

            using var connection = new SqlConnection(connString);
            await connection.OpenAsync();

            // Get all active tenants
            var tenants = new List<(Guid tenantId, string companyName, string? databaseSchema)>();
            using (var cmd = new SqlCommand(
                "SELECT TenantId, CompanyName, DatabaseSchema FROM dbo.Tenants WHERE IsActive = 1",
                connection))
            {
                using var reader = await cmd.ExecuteReaderAsync();

                while (await reader.ReadAsync())
                {
                    tenants.Add((
                        reader.GetGuid(0),
                        reader.GetString(1),
                        reader.IsDBNull(2) ? null : reader.GetString(2)
                    ));
                }
            }

            // Check if schemas exist for each tenant
            var results = new List<object>();
            foreach (var (tenantId, companyName, databaseSchema) in tenants)
            {
                if (string.IsNullOrEmpty(databaseSchema))
                {
                    results.Add(new
                    {
                        tenantId,
                        companyName,
                        databaseSchema = "NOT SET",
                        schemaExists = false,
                        message = "DatabaseSchema not set in Tenants table"
                    });
                    continue;
                }

                using var cmd = new SqlCommand(
                    "SELECT COUNT(*) FROM sys.schemas WHERE name = @SchemaName",
                    connection);
                cmd.Parameters.AddWithValue("@SchemaName", databaseSchema);

                var exists = (int)(await cmd.ExecuteScalarAsync() ?? 0) > 0;

                results.Add(new
                {
                    tenantId,
                    companyName,
                    databaseSchema,
                    schemaExists = exists
                });
            }

            return Ok(new
            {
                success = true,
                totalTenants = tenants.Count,
                results
            });
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Failed to check schemas");
            return StatusCode(500, new
            {
                success = false,
                error = ex.Message
            });
        }
    }

    /// <summary>
    /// Create missing InspectionTypes table for DEMO001 tenant
    /// </summary>
    [HttpPost("create-inspection-types-table")]
    public async Task<ActionResult> CreateInspectionTypesTable()
    {
        try
        {
            var connString = _configuration["DatabaseConnectionString"]
                ?? _configuration.GetConnectionString("DefaultConnection");

            using var connection = new SqlConnection(connString);
            await connection.OpenAsync();

            // Get DEMO001 tenant schema
            string? schemaName = null;
            Guid tenantId = Guid.Empty;

            using (var cmd = new SqlCommand(
                "SELECT TenantId, DatabaseSchema FROM dbo.Tenants WHERE TenantCode = 'DEMO001'",
                connection))
            {
                using var reader = await cmd.ExecuteReaderAsync();
                if (await reader.ReadAsync())
                {
                    tenantId = reader.GetGuid(0);
                    schemaName = reader.IsDBNull(1) ? null : reader.GetString(1);
                }
            }

            if (string.IsNullOrEmpty(schemaName))
            {
                return BadRequest(new { success = false, message = "DEMO001 tenant not found or schema not set" });
            }

            // Check if table exists
            bool tableExists = false;
            using (var cmd = new SqlCommand(
                $"SELECT COUNT(*) FROM sys.tables t INNER JOIN sys.schemas s ON t.schema_id = s.schema_id WHERE s.name = @SchemaName AND t.name = 'InspectionTypes'",
                connection))
            {
                cmd.Parameters.AddWithValue("@SchemaName", schemaName);
                var count = (int)(await cmd.ExecuteScalarAsync() ?? 0);
                tableExists = count > 0;
            }

            if (tableExists)
            {
                return Ok(new { success = true, message = "InspectionTypes table already exists", schemaName, tableExists = true });
            }

            // Create the table
            var createTableSql = $@"
                CREATE TABLE [{schemaName}].InspectionTypes (
                    InspectionTypeId UNIQUEIDENTIFIER NOT NULL DEFAULT NEWID(),
                    TenantId UNIQUEIDENTIFIER NOT NULL,
                    TypeName NVARCHAR(100) NOT NULL,
                    Description NVARCHAR(1000) NULL,
                    RequiresServiceTechnician BIT NOT NULL DEFAULT 0,
                    FrequencyDays INT NOT NULL,
                    IsActive BIT NOT NULL DEFAULT 1,
                    CreatedDate DATETIME2 NOT NULL DEFAULT GETUTCDATE(),
                    CONSTRAINT PK_{schemaName.Replace("-", "_")}_InspectionTypes PRIMARY KEY CLUSTERED (InspectionTypeId)
                )";

            using (var cmd = new SqlCommand(createTableSql, connection))
            {
                await cmd.ExecuteNonQueryAsync();
            }

            // Verify creation
            using (var cmd = new SqlCommand(
                $"SELECT COUNT(*) FROM sys.tables t INNER JOIN sys.schemas s ON t.schema_id = s.schema_id WHERE s.name = @SchemaName AND t.name = 'InspectionTypes'",
                connection))
            {
                cmd.Parameters.AddWithValue("@SchemaName", schemaName);
                var count = (int)(await cmd.ExecuteScalarAsync() ?? 0);
                tableExists = count > 0;
            }

            return Ok(new
            {
                success = true,
                message = "InspectionTypes table created successfully",
                schemaName,
                tenantId,
                tableExists
            });
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Failed to create InspectionTypes table");
            return StatusCode(500, new
            {
                success = false,
                error = ex.Message,
                stackTrace = ex.StackTrace
            });
        }
    }

    private static string MaskPassword(string? connectionString)
    {
        if (string.IsNullOrEmpty(connectionString))
            return "No connection string configured";

        // Mask password in connection string
        var parts = connectionString.Split(';');
        for (int i = 0; i < parts.Length; i++)
        {
            if (parts[i].Trim().StartsWith("Password=", StringComparison.OrdinalIgnoreCase) ||
                parts[i].Trim().StartsWith("Pwd=", StringComparison.OrdinalIgnoreCase))
            {
                parts[i] = "Password=***MASKED***";
            }
        }

        return string.Join(";", parts);
    }
}
