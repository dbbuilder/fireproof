using System.Data;
using Microsoft.Data.SqlClient;

namespace FireExtinguisherInspection.API.Data;

/// <summary>
/// Factory for creating SQL Server database connections
/// Standard multi-tenant architecture with TenantId-based row-level security
/// </summary>
public class DbConnectionFactory : IDbConnectionFactory
{
    private readonly string _connectionString;
    private readonly ILogger<DbConnectionFactory> _logger;

    public DbConnectionFactory(
        IConfiguration configuration,
        ILogger<DbConnectionFactory> logger)
    {
        // Try Key Vault first, fallback to appsettings
        _connectionString = configuration["DatabaseConnectionString"]
            ?? configuration.GetConnectionString("DefaultConnection")
            ?? throw new InvalidOperationException("Connection string 'DefaultConnection' not found");
        _logger = logger;
    }

    /// <inheritdoc />
    public async Task<IDbConnection> CreateConnectionAsync()
    {
        var connection = new SqlConnection(_connectionString);
        await connection.OpenAsync();

        _logger.LogDebug("Created database connection");

        return connection;
    }

    /// <inheritdoc />
    public async Task<IDbConnection> CreateTenantConnectionAsync(Guid tenantId)
    {
        // Standard schema - no tenant-specific schemas
        // Tenant isolation is handled by TenantId parameters in stored procedures
        var connection = new SqlConnection(_connectionString);
        await connection.OpenAsync();

        _logger.LogDebug("Created database connection for tenant: {TenantId}", tenantId);

        return connection;
    }

    /// <inheritdoc />
    public Task<string> GetTenantSchemaAsync(Guid tenantId)
    {
        // All tables are in dbo schema
        // This method is kept for interface compatibility but always returns "dbo"
        return Task.FromResult("dbo");
    }
}
