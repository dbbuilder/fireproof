using FireExtinguisherInspection.API.Models.DTOs;

namespace FireExtinguisherInspection.API.Services;

/// <summary>
/// Service interface for inspection type management
/// </summary>
public interface IInspectionTypeService
{
    Task<InspectionTypeDto> CreateInspectionTypeAsync(Guid tenantId, CreateInspectionTypeRequest request);
    Task<IEnumerable<InspectionTypeDto>> GetAllInspectionTypesAsync(Guid tenantId, bool? isActive = null);
    Task<InspectionTypeDto?> GetInspectionTypeByIdAsync(Guid tenantId, Guid inspectionTypeId);
    Task<InspectionTypeDto> UpdateInspectionTypeAsync(Guid tenantId, Guid inspectionTypeId, UpdateInspectionTypeRequest request);
    Task<bool> DeleteInspectionTypeAsync(Guid tenantId, Guid inspectionTypeId);
}
