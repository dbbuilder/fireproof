using FireExtinguisherInspection.API.Models.DTOs;

namespace FireExtinguisherInspection.API.Services;

/// <summary>
/// Service interface for tenant management operations
/// </summary>
public interface ITenantService
{
    /// <summary>
    /// Retrieves all tenants (SystemAdmin only)
    /// </summary>
    Task<IEnumerable<TenantDto>> GetAllTenantsAsync();

    /// <summary>
    /// Retrieves tenants available to a specific user based on their roles
    /// </summary>
    Task<IEnumerable<TenantDto>> GetAvailableTenantsForUserAsync(Guid userId);

    /// <summary>
    /// Retrieves a specific tenant by ID
    /// </summary>
    Task<TenantDto?> GetTenantByIdAsync(Guid tenantId);

    /// <summary>
    /// Creates a new tenant
    /// </summary>
    Task<TenantDto> CreateTenantAsync(CreateTenantRequest request);

    /// <summary>
    /// Updates an existing tenant
    /// </summary>
    Task<TenantDto> UpdateTenantAsync(Guid tenantId, UpdateTenantRequest request);
}
