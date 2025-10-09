using FireExtinguisherInspection.API.Models.DTOs;

namespace FireExtinguisherInspection.API.Services;

/// <summary>
/// Service interface for fire extinguisher type management
/// </summary>
public interface IExtinguisherTypeService
{
    Task<ExtinguisherTypeDto> CreateExtinguisherTypeAsync(Guid tenantId, CreateExtinguisherTypeRequest request);
    Task<IEnumerable<ExtinguisherTypeDto>> GetAllExtinguisherTypesAsync(Guid tenantId, bool? isActive = null);
    Task<ExtinguisherTypeDto?> GetExtinguisherTypeByIdAsync(Guid tenantId, Guid extinguisherTypeId);
    Task<ExtinguisherTypeDto> UpdateExtinguisherTypeAsync(Guid tenantId, Guid extinguisherTypeId, UpdateExtinguisherTypeRequest request);
    Task<bool> DeleteExtinguisherTypeAsync(Guid tenantId, Guid extinguisherTypeId);
}
