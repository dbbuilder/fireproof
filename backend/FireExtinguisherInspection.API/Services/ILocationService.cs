using FireExtinguisherInspection.API.Models.DTOs;

namespace FireExtinguisherInspection.API.Services;

/// <summary>
/// Service interface for location management operations
/// </summary>
public interface ILocationService
{
    /// <summary>
    /// Creates a new location for a tenant
    /// </summary>
    Task<LocationDto> CreateLocationAsync(Guid tenantId, CreateLocationRequest request);

    /// <summary>
    /// Retrieves all locations for a tenant
    /// </summary>
    Task<IEnumerable<LocationDto>> GetAllLocationsAsync(Guid tenantId, bool? isActive = null);

    /// <summary>
    /// Retrieves a specific location by ID
    /// </summary>
    Task<LocationDto?> GetLocationByIdAsync(Guid tenantId, Guid locationId);

    /// <summary>
    /// Updates an existing location
    /// </summary>
    Task<LocationDto> UpdateLocationAsync(Guid tenantId, Guid locationId, UpdateLocationRequest request);

    /// <summary>
    /// Deletes (soft delete) a location
    /// </summary>
    Task<bool> DeleteLocationAsync(Guid tenantId, Guid locationId);
}
