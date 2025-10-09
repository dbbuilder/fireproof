using FireExtinguisherInspection.API.Models.DTOs;

namespace FireExtinguisherInspection.API.Services;

/// <summary>
/// Service for managing fire extinguisher inspections with tamper-proof records
/// </summary>
public interface IInspectionService
{
    /// <summary>
    /// Create a new inspection with tamper-proof hash and digital signature
    /// </summary>
    Task<InspectionDto> CreateInspectionAsync(Guid tenantId, CreateInspectionRequest request);

    /// <summary>
    /// Get all inspections with optional filtering
    /// </summary>
    Task<IEnumerable<InspectionDto>> GetAllInspectionsAsync(
        Guid tenantId,
        Guid? extinguisherId = null,
        Guid? inspectorUserId = null,
        DateTime? startDate = null,
        DateTime? endDate = null,
        string? inspectionType = null,
        bool? passed = null);

    /// <summary>
    /// Get inspection by ID
    /// </summary>
    Task<InspectionDto?> GetInspectionByIdAsync(Guid tenantId, Guid inspectionId);

    /// <summary>
    /// Get inspection history for a specific extinguisher
    /// </summary>
    Task<IEnumerable<InspectionDto>> GetExtinguisherInspectionHistoryAsync(Guid tenantId, Guid extinguisherId);

    /// <summary>
    /// Get inspections performed by a specific inspector
    /// </summary>
    Task<IEnumerable<InspectionDto>> GetInspectorInspectionsAsync(Guid tenantId, Guid inspectorUserId, DateTime? startDate = null, DateTime? endDate = null);

    /// <summary>
    /// Verify the integrity of an inspection record
    /// </summary>
    Task<InspectionVerificationResponse> VerifyInspectionIntegrityAsync(Guid tenantId, Guid inspectionId);

    /// <summary>
    /// Get inspection statistics for reporting
    /// </summary>
    Task<InspectionStatsDto> GetInspectionStatsAsync(Guid tenantId, DateTime? startDate = null, DateTime? endDate = null);

    /// <summary>
    /// Get extinguishers that are due for inspection
    /// </summary>
    Task<IEnumerable<InspectionDto>> GetOverdueInspectionsAsync(Guid tenantId, string inspectionType = "Monthly");

    /// <summary>
    /// Delete an inspection (soft delete, preserves audit trail)
    /// </summary>
    Task<bool> DeleteInspectionAsync(Guid tenantId, Guid inspectionId);
}
