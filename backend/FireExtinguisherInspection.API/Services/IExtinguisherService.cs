using FireExtinguisherInspection.API.Models.DTOs;

namespace FireExtinguisherInspection.API.Services;

/// <summary>
/// Service for managing fire extinguisher inventory
/// </summary>
public interface IExtinguisherService
{
    /// <summary>
    /// Create a new extinguisher with automatic barcode generation
    /// </summary>
    Task<ExtinguisherDto> CreateExtinguisherAsync(Guid tenantId, CreateExtinguisherRequest request);

    /// <summary>
    /// Get all extinguishers with optional filtering
    /// </summary>
    Task<IEnumerable<ExtinguisherDto>> GetAllExtinguishersAsync(
        Guid tenantId,
        Guid? locationId = null,
        Guid? typeId = null,
        bool? isActive = null,
        bool? isOutOfService = null);

    /// <summary>
    /// Get extinguisher by ID
    /// </summary>
    Task<ExtinguisherDto?> GetExtinguisherByIdAsync(Guid tenantId, Guid extinguisherId);

    /// <summary>
    /// Get extinguisher by barcode
    /// </summary>
    Task<ExtinguisherDto?> GetExtinguisherByBarcodeAsync(Guid tenantId, string barcodeData);

    /// <summary>
    /// Update extinguisher details
    /// </summary>
    Task<ExtinguisherDto> UpdateExtinguisherAsync(Guid tenantId, Guid extinguisherId, UpdateExtinguisherRequest request);

    /// <summary>
    /// Delete extinguisher (soft delete)
    /// </summary>
    Task<bool> DeleteExtinguisherAsync(Guid tenantId, Guid extinguisherId);

    /// <summary>
    /// Generate or regenerate barcode for an extinguisher
    /// </summary>
    Task<BarcodeResponse> GenerateBarcodeAsync(Guid tenantId, Guid extinguisherId);

    /// <summary>
    /// Mark extinguisher as out of service
    /// </summary>
    Task<ExtinguisherDto> MarkOutOfServiceAsync(Guid tenantId, Guid extinguisherId, string reason);

    /// <summary>
    /// Return extinguisher to service
    /// </summary>
    Task<ExtinguisherDto> ReturnToServiceAsync(Guid tenantId, Guid extinguisherId);

    /// <summary>
    /// Get extinguishers with upcoming service dates
    /// </summary>
    Task<IEnumerable<ExtinguisherDto>> GetExtinguishersNeedingServiceAsync(Guid tenantId, int daysAhead = 30);

    /// <summary>
    /// Get extinguishers with upcoming hydro test dates
    /// </summary>
    Task<IEnumerable<ExtinguisherDto>> GetExtinguishersNeedingHydroTestAsync(Guid tenantId, int daysAhead = 30);
}
