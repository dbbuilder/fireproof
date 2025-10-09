namespace FireExtinguisherInspection.API.Models;

/// <summary>
/// Contains the current tenant context information
/// </summary>
public class TenantContext
{
    /// <summary>
    /// The current tenant ID
    /// </summary>
    public Guid TenantId { get; set; }

    /// <summary>
    /// The tenant code
    /// </summary>
    public string TenantCode { get; set; } = string.Empty;

    /// <summary>
    /// The tenant's database schema name
    /// </summary>
    public string DatabaseSchema { get; set; } = string.Empty;

    /// <summary>
    /// The current user ID
    /// </summary>
    public Guid? UserId { get; set; }

    /// <summary>
    /// The user's role in this tenant
    /// </summary>
    public string? Role { get; set; }
}
