using System.Data;
using Microsoft.Data.SqlClient;
using Microsoft.Extensions.Caching.Memory;

namespace FireExtinguisherInspection.API.Data;

/// <summary>
/// Factory for creating SQL Server database connections
/// Supports multi-tenant schema isolation
/// </summary>
public class DbConnectionFactory : IDbConnectionFactory
{
    private readonly string _connectionString;
    private readonly IMemoryCache _cache;
    private readonly ILogger<DbConnectionFactory> _logger;
    private const string TenantSchemaCacheKeyPrefix = "TenantSchema_";

    public DbConnectionFactory(
        IConfiguration configuration,
        IMemoryCache cache,
        ILogger<DbConnectionFactory> logger)
    {
        _connectionString = configuration.GetConnectionString("DefaultConnection")
            ?? throw new InvalidOperationException("Connection string 'DefaultConnection' not found");
        _cache = cache;
        _logger = logger;
    }

    /// <inheritdoc />
    public async Task<IDbConnection> CreateConnectionAsync()
    {
        var connection = new SqlConnection(_connectionString);
        await connection.OpenAsync();

        _logger.LogDebug("Created core database connection");

        return connection;
    }

    /// <inheritdoc />
    public async Task<IDbConnection> CreateTenantConnectionAsync(Guid tenantId)
    {
        // Get tenant schema name (cached)
        var schemaName = await GetTenantSchemaAsync(tenantId);

        var connection = new SqlConnection(_connectionString);
        await connection.OpenAsync();

        _logger.LogDebug("Created tenant database connection for schema: {SchemaName}", schemaName);

        return connection;
    }

    /// <inheritdoc />
    public async Task<string> GetTenantSchemaAsync(Guid tenantId)
    {
        var cacheKey = $"{TenantSchemaCacheKeyPrefix}{tenantId}";

        // Try to get from cache first
        if (_cache.TryGetValue(cacheKey, out string? cachedSchema) && cachedSchema != null)
        {
            return cachedSchema;
        }

        // Query database for schema name
        var schemaName = await QueryTenantSchemaAsync(tenantId);

        if (string.IsNullOrEmpty(schemaName))
        {
            throw new InvalidOperationException($"Tenant schema not found for tenant ID: {tenantId}");
        }

        // Cache for 1 hour
        var cacheOptions = new MemoryCacheEntryOptions
        {
            AbsoluteExpirationRelativeToNow = TimeSpan.FromHours(1),
            SlidingExpiration = TimeSpan.FromMinutes(30)
        };

        _cache.Set(cacheKey, schemaName, cacheOptions);

        _logger.LogInformation("Cached tenant schema: {SchemaName} for tenant: {TenantId}", schemaName, tenantId);

        return schemaName;
    }

    private async Task<string> QueryTenantSchemaAsync(Guid tenantId)
    {
        using var connection = new SqlConnection(_connectionString);
        await connection.OpenAsync();

        using var command = new SqlCommand(
            "SELECT DatabaseSchema FROM dbo.Tenants WHERE TenantId = @TenantId AND IsActive = 1",
            connection);

        command.Parameters.AddWithValue("@TenantId", tenantId);

        var result = await command.ExecuteScalarAsync();

        return result?.ToString() ?? string.Empty;
    }
}
