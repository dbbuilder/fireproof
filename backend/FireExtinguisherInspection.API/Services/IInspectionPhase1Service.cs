using FireExtinguisherInspection.API.Models.DTOs;

namespace FireExtinguisherInspection.API.Services;

/// <summary>
/// Service interface for Phase 1 inspection management
/// Uses checklist-based approach with separate tables for responses, photos, and deficiencies
/// </summary>
public interface IInspectionPhase1Service
{
    // === Inspection Lifecycle ===

    /// <summary>
    /// Creates a new inspection in "InProgress" status with a checklist template
    /// Inspector can then add responses, photos, and deficiencies before completing
    /// </summary>
    Task<InspectionPhase1Dto> CreateInspectionAsync(Guid tenantId, CreateInspectionPhase1Request request);

    /// <summary>
    /// Updates an in-progress inspection (GPS, notes)
    /// </summary>
    Task<InspectionPhase1Dto> UpdateInspectionAsync(Guid tenantId, Guid inspectionId, UpdateInspectionPhase1Request request);

    /// <summary>
    /// Completes an inspection: computes hash (blockchain-style), creates signature, sets status to "Completed"
    /// </summary>
    Task<InspectionPhase1Dto> CompleteInspectionAsync(Guid tenantId, Guid inspectionId, CompleteInspectionRequest request);

    // === Checklist Responses ===

    /// <summary>
    /// Saves checklist responses for an inspection (batch operation)
    /// </summary>
    Task<IEnumerable<InspectionChecklistResponseDto>> SaveChecklistResponsesAsync(
        Guid tenantId,
        Guid inspectionId,
        SaveChecklistResponsesRequest request);

    /// <summary>
    /// Gets checklist responses for an inspection
    /// </summary>
    Task<IEnumerable<InspectionChecklistResponseDto>> GetChecklistResponsesAsync(Guid tenantId, Guid inspectionId);

    // === Query Operations ===

    /// <summary>
    /// Gets all inspections with optional filtering
    /// </summary>
    Task<IEnumerable<InspectionPhase1Dto>> GetAllInspectionsAsync(
        Guid tenantId,
        Guid? extinguisherId = null,
        Guid? inspectorUserId = null,
        DateTime? startDate = null,
        DateTime? endDate = null,
        string? inspectionType = null,
        string? status = null);

    /// <summary>
    /// Gets a specific inspection by ID with all related data (responses, photos, deficiencies)
    /// </summary>
    Task<InspectionPhase1Dto?> GetInspectionByIdAsync(Guid tenantId, Guid inspectionId, bool includeDetails = true);

    /// <summary>
    /// Gets inspection history for a specific extinguisher
    /// </summary>
    Task<IEnumerable<InspectionPhase1Dto>> GetExtinguisherInspectionHistoryAsync(Guid tenantId, Guid extinguisherId);

    /// <summary>
    /// Gets inspections performed by a specific inspector
    /// </summary>
    Task<IEnumerable<InspectionPhase1Dto>> GetInspectorInspectionsAsync(
        Guid tenantId,
        Guid inspectorUserId,
        DateTime? startDate = null,
        DateTime? endDate = null);

    /// <summary>
    /// Gets inspections due for a specific date range
    /// </summary>
    Task<IEnumerable<InspectionPhase1Dto>> GetDueInspectionsAsync(
        Guid tenantId,
        DateTime? startDate = null,
        DateTime? endDate = null);

    /// <summary>
    /// Gets scheduled inspections
    /// </summary>
    Task<IEnumerable<InspectionPhase1Dto>> GetScheduledInspectionsAsync(
        Guid tenantId,
        DateTime? startDate = null,
        DateTime? endDate = null);

    // === Verification and Integrity ===

    /// <summary>
    /// Verifies the integrity of an inspection record using blockchain-style hash chaining
    /// </summary>
    Task<InspectionPhase1VerificationResponse> VerifyInspectionIntegrityAsync(Guid tenantId, Guid inspectionId);

    // === Statistics and Reporting ===

    /// <summary>
    /// Gets inspection statistics for reporting
    /// </summary>
    Task<InspectionPhase1StatsDto> GetInspectionStatsAsync(Guid tenantId, DateTime? startDate = null, DateTime? endDate = null);

    // === Deletion ===

    /// <summary>
    /// Deletes an inspection (soft delete, preserves audit trail)
    /// Only allows deletion of InProgress inspections
    /// </summary>
    Task<bool> DeleteInspectionAsync(Guid tenantId, Guid inspectionId);
}
