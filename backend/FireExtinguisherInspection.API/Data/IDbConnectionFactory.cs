using System.Data;

namespace FireExtinguisherInspection.API.Data;

/// <summary>
/// Factory interface for creating database connections
/// </summary>
public interface IDbConnectionFactory
{
    /// <summary>
    /// Creates a database connection for the core schema
    /// </summary>
    /// <returns>Database connection instance</returns>
    Task<IDbConnection> CreateConnectionAsync();

    /// <summary>
    /// Creates a database connection for a specific tenant schema
    /// </summary>
    /// <param name="tenantId">The tenant identifier</param>
    /// <returns>Database connection instance</returns>
    Task<IDbConnection> CreateTenantConnectionAsync(Guid tenantId);

    /// <summary>
    /// Gets the schema name for a specific tenant
    /// </summary>
    /// <param name="tenantId">The tenant identifier</param>
    /// <returns>The tenant schema name</returns>
    Task<string> GetTenantSchemaAsync(Guid tenantId);
}
