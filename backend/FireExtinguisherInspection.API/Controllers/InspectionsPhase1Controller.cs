using FireExtinguisherInspection.API.Authorization;
using FireExtinguisherInspection.API.Helpers;
using FireExtinguisherInspection.API.Models;
using FireExtinguisherInspection.API.Models.DTOs;
using FireExtinguisherInspection.API.Services;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace FireExtinguisherInspection.API.Controllers;

/// <summary>
/// Phase 1 API controller for checklist-based inspection management
/// Supports multi-step workflow: Create (InProgress) -> Add Responses -> Add Photos -> Complete
/// </summary>
[ApiController]
[Route("api/v2/inspections")]
[Authorize] // Require authentication for all endpoints
public class InspectionsPhase1Controller : ControllerBase
{
    private readonly IInspectionPhase1Service _inspectionService;
    private readonly TenantContext _tenantContext;
    private readonly ILogger<InspectionsPhase1Controller> _logger;

    public InspectionsPhase1Controller(
        IInspectionPhase1Service inspectionService,
        TenantContext tenantContext,
        ILogger<InspectionsPhase1Controller> logger)
    {
        _inspectionService = inspectionService;
        _tenantContext = tenantContext;
        _logger = logger;
    }

    // ==================== CORE CRUD OPERATIONS ====================

    /// <summary>
    /// Creates a new inspection in "InProgress" status with a checklist template
    /// Inspector can then add responses, photos, and deficiencies before completing
    /// </summary>
    [HttpPost]
    [Authorize(Policy = AuthorizationPolicies.InspectorOrAbove)]
    [ProducesResponseType(typeof(InspectionPhase1Dto), StatusCodes.Status201Created)]
    [ProducesResponseType(StatusCodes.Status400BadRequest)]
    [ProducesResponseType(StatusCodes.Status401Unauthorized)]
    [ProducesResponseType(StatusCodes.Status403Forbidden)]
    public async Task<ActionResult<InspectionPhase1Dto>> CreateInspection([FromBody] CreateInspectionPhase1Request request)
    {
        if (_tenantContext.TenantId == Guid.Empty)
            return Unauthorized(new { message = "Tenant context not found" });

        try
        {
            _logger.LogInformation("Creating Phase 1 inspection for extinguisher {ExtinguisherId}, template {TemplateId}",
                request.ExtinguisherId, request.TemplateId);

            var inspection = await _inspectionService.CreateInspectionAsync(_tenantContext.TenantId, request);

            return CreatedAtAction(
                nameof(GetInspectionById),
                new { id = inspection.InspectionId },
                inspection);
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error creating Phase 1 inspection for tenant {TenantId}", _tenantContext.TenantId);
            return StatusCode(500, new { message = "Failed to create inspection", error = ex.Message });
        }
    }

    /// <summary>
    /// Gets all inspections with optional filtering
    /// Supports filters: extinguisherId, inspectorUserId, dateRange, inspectionType, status
    /// </summary>
    [HttpGet]
    [Authorize(Policy = AuthorizationPolicies.InspectorOrAbove)]
    [ProducesResponseType(typeof(IEnumerable<InspectionPhase1Dto>), StatusCodes.Status200OK)]
    [ProducesResponseType(StatusCodes.Status401Unauthorized)]
    [ProducesResponseType(StatusCodes.Status403Forbidden)]
    public async Task<ActionResult<IEnumerable<InspectionPhase1Dto>>> GetAllInspections(
        [FromQuery] Guid? extinguisherId = null,
        [FromQuery] Guid? inspectorUserId = null,
        [FromQuery] DateTime? startDate = null,
        [FromQuery] DateTime? endDate = null,
        [FromQuery] string? inspectionType = null,
        [FromQuery] string? status = null,
        [FromQuery] Guid? tenantId = null)
    {
        if (!TenantResolver.TryResolveTenantId(User, _tenantContext, tenantId, out var effectiveTenantId, out var errorMessage))
        {
            if (TenantResolver.IsSystemAdmin(User) && !tenantId.HasValue)
            {
                _logger.LogDebug("SystemAdmin without tenantId - returning empty result");
                return Ok(Array.Empty<InspectionPhase1Dto>());
            }
            return Unauthorized(new { message = errorMessage });
        }

        try
        {
            var inspections = await _inspectionService.GetAllInspectionsAsync(
                effectiveTenantId,
                extinguisherId,
                inspectorUserId,
                startDate,
                endDate,
                inspectionType,
                status);

            return Ok(inspections);
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error retrieving Phase 1 inspections for tenant {TenantId}", effectiveTenantId);
            return StatusCode(500, new { message = "Failed to retrieve inspections", error = ex.Message });
        }
    }

    /// <summary>
    /// Gets a specific inspection by ID with optional details (responses, photos, deficiencies)
    /// </summary>
    [HttpGet("{id:guid}")]
    [Authorize(Policy = AuthorizationPolicies.InspectorOrAbove)]
    [ProducesResponseType(typeof(InspectionPhase1Dto), StatusCodes.Status200OK)]
    [ProducesResponseType(StatusCodes.Status404NotFound)]
    [ProducesResponseType(StatusCodes.Status401Unauthorized)]
    [ProducesResponseType(StatusCodes.Status403Forbidden)]
    public async Task<ActionResult<InspectionPhase1Dto>> GetInspectionById(
        Guid id,
        [FromQuery] bool includeDetails = true,
        [FromQuery] Guid? tenantId = null)
    {
        if (!TenantResolver.TryResolveTenantId(User, _tenantContext, tenantId, out var effectiveTenantId, out var errorMessage))
        {
            if (TenantResolver.IsSystemAdmin(User) && !tenantId.HasValue)
            {
                _logger.LogDebug("SystemAdmin without tenantId - returning not found");
                return NotFound(new { message = $"Inspection {id} not found" });
            }
            return Unauthorized(new { message = errorMessage });
        }

        try
        {
            var inspection = await _inspectionService.GetInspectionByIdAsync(effectiveTenantId, id, includeDetails);

            if (inspection == null)
                return NotFound(new { message = $"Inspection {id} not found" });

            return Ok(inspection);
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error retrieving Phase 1 inspection {InspectionId} for tenant {TenantId}",
                id, effectiveTenantId);
            return StatusCode(500, new { message = "Failed to retrieve inspection", error = ex.Message });
        }
    }

    /// <summary>
    /// Updates an in-progress inspection (GPS coordinates, notes)
    /// Cannot update completed inspections (immutability for audit trail)
    /// </summary>
    [HttpPut("{id:guid}")]
    [Authorize(Policy = AuthorizationPolicies.InspectorOrAbove)]
    [ProducesResponseType(typeof(InspectionPhase1Dto), StatusCodes.Status200OK)]
    [ProducesResponseType(StatusCodes.Status404NotFound)]
    [ProducesResponseType(StatusCodes.Status400BadRequest)]
    [ProducesResponseType(StatusCodes.Status401Unauthorized)]
    [ProducesResponseType(StatusCodes.Status403Forbidden)]
    public async Task<ActionResult<InspectionPhase1Dto>> UpdateInspection(
        Guid id,
        [FromBody] UpdateInspectionPhase1Request request)
    {
        if (_tenantContext.TenantId == Guid.Empty)
            return Unauthorized(new { message = "Tenant context not found" });

        try
        {
            var inspection = await _inspectionService.UpdateInspectionAsync(_tenantContext.TenantId, id, request);
            return Ok(inspection);
        }
        catch (KeyNotFoundException)
        {
            return NotFound(new { message = $"Inspection {id} not found" });
        }
        catch (InvalidOperationException ex)
        {
            return BadRequest(new { message = ex.Message });
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error updating Phase 1 inspection {InspectionId} for tenant {TenantId}",
                id, _tenantContext.TenantId);
            return StatusCode(500, new { message = "Failed to update inspection", error = ex.Message });
        }
    }

    /// <summary>
    /// Deletes an inspection (soft delete, InProgress inspections only)
    /// Completed inspections cannot be deleted (audit trail preservation)
    /// </summary>
    [HttpDelete("{id:guid}")]
    [Authorize(Policy = AuthorizationPolicies.AdminOrTenantAdmin)]
    [ProducesResponseType(StatusCodes.Status204NoContent)]
    [ProducesResponseType(StatusCodes.Status404NotFound)]
    [ProducesResponseType(StatusCodes.Status400BadRequest)]
    [ProducesResponseType(StatusCodes.Status401Unauthorized)]
    [ProducesResponseType(StatusCodes.Status403Forbidden)]
    public async Task<IActionResult> DeleteInspection(Guid id)
    {
        if (_tenantContext.TenantId == Guid.Empty)
            return Unauthorized(new { message = "Tenant context not found" });

        try
        {
            var success = await _inspectionService.DeleteInspectionAsync(_tenantContext.TenantId, id);

            if (!success)
                return NotFound(new { message = $"Inspection {id} not found" });

            return NoContent();
        }
        catch (InvalidOperationException ex)
        {
            return BadRequest(new { message = ex.Message });
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error deleting Phase 1 inspection {InspectionId} for tenant {TenantId}",
                id, _tenantContext.TenantId);
            return StatusCode(500, new { message = "Failed to delete inspection", error = ex.Message });
        }
    }

    // ==================== CHECKLIST RESPONSES ====================

    /// <summary>
    /// Saves checklist responses for an inspection (batch operation)
    /// Inspector fills out Pass/Fail/NA for each checklist item
    /// </summary>
    [HttpPost("{id:guid}/responses")]
    [Authorize(Policy = AuthorizationPolicies.InspectorOrAbove)]
    [ProducesResponseType(typeof(IEnumerable<InspectionChecklistResponseDto>), StatusCodes.Status201Created)]
    [ProducesResponseType(StatusCodes.Status400BadRequest)]
    [ProducesResponseType(StatusCodes.Status401Unauthorized)]
    [ProducesResponseType(StatusCodes.Status403Forbidden)]
    public async Task<ActionResult<IEnumerable<InspectionChecklistResponseDto>>> SaveChecklistResponses(
        Guid id,
        [FromBody] SaveChecklistResponsesRequest request)
    {
        if (_tenantContext.TenantId == Guid.Empty)
            return Unauthorized(new { message = "Tenant context not found" });

        // Ensure InspectionId matches route parameter
        if (request.InspectionId != id)
        {
            return BadRequest(new { message = "InspectionId in body must match route parameter" });
        }

        try
        {
            _logger.LogInformation("Saving {Count} checklist responses for inspection {InspectionId}",
                request.Responses.Count, id);

            var responses = await _inspectionService.SaveChecklistResponsesAsync(_tenantContext.TenantId, id, request);

            return CreatedAtAction(
                nameof(GetChecklistResponses),
                new { id },
                responses);
        }
        catch (KeyNotFoundException)
        {
            return NotFound(new { message = $"Inspection {id} not found" });
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error saving checklist responses for inspection {InspectionId} for tenant {TenantId}",
                id, _tenantContext.TenantId);
            return StatusCode(500, new { message = "Failed to save checklist responses", error = ex.Message });
        }
    }

    /// <summary>
    /// Gets checklist responses for an inspection
    /// </summary>
    [HttpGet("{id:guid}/responses")]
    [Authorize(Policy = AuthorizationPolicies.InspectorOrAbove)]
    [ProducesResponseType(typeof(IEnumerable<InspectionChecklistResponseDto>), StatusCodes.Status200OK)]
    [ProducesResponseType(StatusCodes.Status404NotFound)]
    [ProducesResponseType(StatusCodes.Status401Unauthorized)]
    [ProducesResponseType(StatusCodes.Status403Forbidden)]
    public async Task<ActionResult<IEnumerable<InspectionChecklistResponseDto>>> GetChecklistResponses(Guid id)
    {
        if (_tenantContext.TenantId == Guid.Empty)
            return Unauthorized(new { message = "Tenant context not found" });

        try
        {
            var responses = await _inspectionService.GetChecklistResponsesAsync(_tenantContext.TenantId, id);
            return Ok(responses);
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error retrieving checklist responses for inspection {InspectionId} for tenant {TenantId}",
                id, _tenantContext.TenantId);
            return StatusCode(500, new { message = "Failed to retrieve checklist responses", error = ex.Message });
        }
    }

    // ==================== WORKFLOW OPERATIONS ====================

    /// <summary>
    /// Completes an inspection: computes tamper-proof hash, creates digital signature, sets status to "Completed"
    /// Uses blockchain-style hash chaining (PreviousInspectionHash)
    /// </summary>
    [HttpPut("{id:guid}/complete")]
    [Authorize(Policy = AuthorizationPolicies.InspectorOrAbove)]
    [ProducesResponseType(typeof(InspectionPhase1Dto), StatusCodes.Status200OK)]
    [ProducesResponseType(StatusCodes.Status404NotFound)]
    [ProducesResponseType(StatusCodes.Status400BadRequest)]
    [ProducesResponseType(StatusCodes.Status401Unauthorized)]
    [ProducesResponseType(StatusCodes.Status403Forbidden)]
    public async Task<ActionResult<InspectionPhase1Dto>> CompleteInspection(
        Guid id,
        [FromBody] CompleteInspectionRequest request)
    {
        if (_tenantContext.TenantId == Guid.Empty)
            return Unauthorized(new { message = "Tenant context not found" });

        try
        {
            _logger.LogInformation("Completing Phase 1 inspection {InspectionId} with result: {OverallResult}",
                id, request.OverallResult);

            var inspection = await _inspectionService.CompleteInspectionAsync(_tenantContext.TenantId, id, request);
            return Ok(inspection);
        }
        catch (KeyNotFoundException)
        {
            return NotFound(new { message = $"Inspection {id} not found" });
        }
        catch (InvalidOperationException ex)
        {
            return BadRequest(new { message = ex.Message });
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error completing Phase 1 inspection {InspectionId} for tenant {TenantId}",
                id, _tenantContext.TenantId);
            return StatusCode(500, new { message = "Failed to complete inspection", error = ex.Message });
        }
    }

    // ==================== QUERY OPERATIONS ====================

    /// <summary>
    /// Gets inspection history for a specific extinguisher
    /// </summary>
    [HttpGet("extinguisher/{extinguisherId:guid}")]
    [Authorize(Policy = AuthorizationPolicies.InspectorOrAbove)]
    [ProducesResponseType(typeof(IEnumerable<InspectionPhase1Dto>), StatusCodes.Status200OK)]
    [ProducesResponseType(StatusCodes.Status401Unauthorized)]
    [ProducesResponseType(StatusCodes.Status403Forbidden)]
    public async Task<ActionResult<IEnumerable<InspectionPhase1Dto>>> GetExtinguisherInspectionHistory(
        Guid extinguisherId,
        [FromQuery] Guid? tenantId = null)
    {
        if (!TenantResolver.TryResolveTenantId(User, _tenantContext, tenantId, out var effectiveTenantId, out var errorMessage))
        {
            if (TenantResolver.IsSystemAdmin(User) && !tenantId.HasValue)
            {
                _logger.LogDebug("SystemAdmin without tenantId - returning empty result");
                return Ok(Array.Empty<InspectionPhase1Dto>());
            }
            return Unauthorized(new { message = errorMessage });
        }

        try
        {
            var inspections = await _inspectionService.GetExtinguisherInspectionHistoryAsync(effectiveTenantId, extinguisherId);
            return Ok(inspections);
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error retrieving Phase 1 inspection history for extinguisher {ExtinguisherId} for tenant {TenantId}",
                extinguisherId, effectiveTenantId);
            return StatusCode(500, new { message = "Failed to retrieve inspection history", error = ex.Message });
        }
    }

    /// <summary>
    /// Gets inspections performed by a specific inspector
    /// </summary>
    [HttpGet("inspector/{inspectorUserId:guid}")]
    [Authorize(Policy = AuthorizationPolicies.ManagerOrAbove)]
    [ProducesResponseType(typeof(IEnumerable<InspectionPhase1Dto>), StatusCodes.Status200OK)]
    [ProducesResponseType(StatusCodes.Status401Unauthorized)]
    [ProducesResponseType(StatusCodes.Status403Forbidden)]
    public async Task<ActionResult<IEnumerable<InspectionPhase1Dto>>> GetInspectorInspections(
        Guid inspectorUserId,
        [FromQuery] DateTime? startDate = null,
        [FromQuery] DateTime? endDate = null,
        [FromQuery] Guid? tenantId = null)
    {
        if (!TenantResolver.TryResolveTenantId(User, _tenantContext, tenantId, out var effectiveTenantId, out var errorMessage))
        {
            if (TenantResolver.IsSystemAdmin(User) && !tenantId.HasValue)
            {
                _logger.LogDebug("SystemAdmin without tenantId - returning empty result");
                return Ok(Array.Empty<InspectionPhase1Dto>());
            }
            return Unauthorized(new { message = errorMessage });
        }

        try
        {
            var inspections = await _inspectionService.GetInspectorInspectionsAsync(
                effectiveTenantId,
                inspectorUserId,
                startDate,
                endDate);

            return Ok(inspections);
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error retrieving Phase 1 inspections for inspector {InspectorUserId} for tenant {TenantId}",
                inspectorUserId, effectiveTenantId);
            return StatusCode(500, new { message = "Failed to retrieve inspector inspections", error = ex.Message });
        }
    }

    /// <summary>
    /// Gets inspections that are due (scheduled but not yet completed)
    /// </summary>
    [HttpGet("due")]
    [Authorize(Policy = AuthorizationPolicies.InspectorOrAbove)]
    [ProducesResponseType(typeof(IEnumerable<InspectionPhase1Dto>), StatusCodes.Status200OK)]
    [ProducesResponseType(StatusCodes.Status401Unauthorized)]
    [ProducesResponseType(StatusCodes.Status403Forbidden)]
    public async Task<ActionResult<IEnumerable<InspectionPhase1Dto>>> GetDueInspections(
        [FromQuery] DateTime? startDate = null,
        [FromQuery] DateTime? endDate = null,
        [FromQuery] Guid? tenantId = null)
    {
        if (!TenantResolver.TryResolveTenantId(User, _tenantContext, tenantId, out var effectiveTenantId, out var errorMessage))
        {
            if (TenantResolver.IsSystemAdmin(User) && !tenantId.HasValue)
            {
                _logger.LogDebug("SystemAdmin without tenantId - returning empty result");
                return Ok(Array.Empty<InspectionPhase1Dto>());
            }
            return Unauthorized(new { message = errorMessage });
        }

        try
        {
            var inspections = await _inspectionService.GetDueInspectionsAsync(effectiveTenantId, startDate, endDate);
            return Ok(inspections);
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error retrieving due Phase 1 inspections for tenant {TenantId}", effectiveTenantId);
            return StatusCode(500, new { message = "Failed to retrieve due inspections", error = ex.Message });
        }
    }

    /// <summary>
    /// Gets scheduled inspections
    /// </summary>
    [HttpGet("scheduled")]
    [Authorize(Policy = AuthorizationPolicies.InspectorOrAbove)]
    [ProducesResponseType(typeof(IEnumerable<InspectionPhase1Dto>), StatusCodes.Status200OK)]
    [ProducesResponseType(StatusCodes.Status401Unauthorized)]
    [ProducesResponseType(StatusCodes.Status403Forbidden)]
    public async Task<ActionResult<IEnumerable<InspectionPhase1Dto>>> GetScheduledInspections(
        [FromQuery] DateTime? startDate = null,
        [FromQuery] DateTime? endDate = null,
        [FromQuery] Guid? tenantId = null)
    {
        if (!TenantResolver.TryResolveTenantId(User, _tenantContext, tenantId, out var effectiveTenantId, out var errorMessage))
        {
            if (TenantResolver.IsSystemAdmin(User) && !tenantId.HasValue)
            {
                _logger.LogDebug("SystemAdmin without tenantId - returning empty result");
                return Ok(Array.Empty<InspectionPhase1Dto>());
            }
            return Unauthorized(new { message = errorMessage });
        }

        try
        {
            var inspections = await _inspectionService.GetScheduledInspectionsAsync(effectiveTenantId, startDate, endDate);
            return Ok(inspections);
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error retrieving scheduled Phase 1 inspections for tenant {TenantId}", effectiveTenantId);
            return StatusCode(500, new { message = "Failed to retrieve scheduled inspections", error = ex.Message });
        }
    }

    // ==================== VERIFICATION & STATISTICS ====================

    /// <summary>
    /// Verifies the tamper-proof integrity of an inspection using blockchain-style hash chaining
    /// </summary>
    [HttpPost("{id:guid}/verify")]
    [Authorize(Policy = AuthorizationPolicies.InspectorOrAbove)]
    [ProducesResponseType(typeof(InspectionPhase1VerificationResponse), StatusCodes.Status200OK)]
    [ProducesResponseType(StatusCodes.Status404NotFound)]
    [ProducesResponseType(StatusCodes.Status401Unauthorized)]
    [ProducesResponseType(StatusCodes.Status403Forbidden)]
    public async Task<ActionResult<InspectionPhase1VerificationResponse>> VerifyInspectionIntegrity(Guid id)
    {
        if (_tenantContext.TenantId == Guid.Empty)
            return Unauthorized(new { message = "Tenant context not found" });

        try
        {
            var verificationResult = await _inspectionService.VerifyInspectionIntegrityAsync(_tenantContext.TenantId, id);
            return Ok(verificationResult);
        }
        catch (KeyNotFoundException)
        {
            return NotFound(new { message = $"Inspection {id} not found" });
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error verifying Phase 1 inspection {InspectionId} for tenant {TenantId}",
                id, _tenantContext.TenantId);
            return StatusCode(500, new { message = "Failed to verify inspection integrity", error = ex.Message });
        }
    }

    /// <summary>
    /// Gets inspection statistics with comprehensive metrics
    /// </summary>
    [HttpGet("stats")]
    [Authorize(Policy = AuthorizationPolicies.ManagerOrAbove)]
    [ProducesResponseType(typeof(InspectionPhase1StatsDto), StatusCodes.Status200OK)]
    [ProducesResponseType(StatusCodes.Status401Unauthorized)]
    [ProducesResponseType(StatusCodes.Status403Forbidden)]
    public async Task<ActionResult<InspectionPhase1StatsDto>> GetInspectionStats(
        [FromQuery] DateTime? startDate = null,
        [FromQuery] DateTime? endDate = null,
        [FromQuery] Guid? tenantId = null)
    {
        if (!TenantResolver.TryResolveTenantId(User, _tenantContext, tenantId, out var effectiveTenantId, out var errorMessage))
        {
            if (TenantResolver.IsSystemAdmin(User) && !tenantId.HasValue)
            {
                _logger.LogDebug("SystemAdmin without tenantId - returning empty result");
                return Ok(new InspectionPhase1StatsDto());
            }
            return Unauthorized(new { message = errorMessage });
        }

        try
        {
            var stats = await _inspectionService.GetInspectionStatsAsync(effectiveTenantId, startDate, endDate);
            return Ok(stats);
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error retrieving Phase 1 inspection stats for tenant {TenantId}", effectiveTenantId);
            return StatusCode(500, new { message = "Failed to retrieve inspection statistics", error = ex.Message });
        }
    }
}
