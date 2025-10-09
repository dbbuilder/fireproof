using FireExtinguisherInspection.API.Models;
using FireExtinguisherInspection.API.Models.DTOs;
using FireExtinguisherInspection.API.Services;
using Microsoft.AspNetCore.Mvc;

namespace FireExtinguisherInspection.API.Controllers;

[ApiController]
[Route("api/[controller]")]
public class InspectionsController : ControllerBase
{
    private readonly IInspectionService _inspectionService;
    private readonly TenantContext _tenantContext;
    private readonly ILogger<InspectionsController> _logger;

    public InspectionsController(
        IInspectionService inspectionService,
        TenantContext tenantContext,
        ILogger<InspectionsController> logger)
    {
        _inspectionService = inspectionService;
        _tenantContext = tenantContext;
        _logger = logger;
    }

    /// <summary>
    /// Create a new tamper-proof inspection
    /// </summary>
    [HttpPost]
    public async Task<ActionResult<InspectionDto>> CreateInspection([FromBody] CreateInspectionRequest request)
    {
        if (_tenantContext.TenantId == Guid.Empty)
            return Unauthorized(new { message = "Tenant context not found" });

        try
        {
            var inspection = await _inspectionService.CreateInspectionAsync(_tenantContext.TenantId, request);
            return CreatedAtAction(nameof(GetInspectionById), new { id = inspection.InspectionId }, inspection);
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error creating inspection for tenant {TenantId}", _tenantContext.TenantId);
            return StatusCode(500, new { message = "Failed to create inspection", error = ex.Message });
        }
    }

    /// <summary>
    /// Get all inspections with optional filtering
    /// </summary>
    [HttpGet]
    public async Task<ActionResult<IEnumerable<InspectionDto>>> GetAllInspections(
        [FromQuery] Guid? extinguisherId = null,
        [FromQuery] Guid? inspectorUserId = null,
        [FromQuery] DateTime? startDate = null,
        [FromQuery] DateTime? endDate = null,
        [FromQuery] string? inspectionType = null,
        [FromQuery] bool? passed = null)
    {
        if (_tenantContext.TenantId == Guid.Empty)
            return Unauthorized(new { message = "Tenant context not found" });

        try
        {
            var inspections = await _inspectionService.GetAllInspectionsAsync(
                _tenantContext.TenantId,
                extinguisherId,
                inspectorUserId,
                startDate,
                endDate,
                inspectionType,
                passed);

            return Ok(inspections);
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error retrieving inspections for tenant {TenantId}", _tenantContext.TenantId);
            return StatusCode(500, new { message = "Failed to retrieve inspections", error = ex.Message });
        }
    }

    /// <summary>
    /// Get inspection by ID
    /// </summary>
    [HttpGet("{id:guid}")]
    public async Task<ActionResult<InspectionDto>> GetInspectionById(Guid id)
    {
        if (_tenantContext.TenantId == Guid.Empty)
            return Unauthorized(new { message = "Tenant context not found" });

        try
        {
            var inspection = await _inspectionService.GetInspectionByIdAsync(_tenantContext.TenantId, id);

            if (inspection == null)
                return NotFound(new { message = $"Inspection {id} not found" });

            return Ok(inspection);
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error retrieving inspection {InspectionId} for tenant {TenantId}",
                id, _tenantContext.TenantId);
            return StatusCode(500, new { message = "Failed to retrieve inspection", error = ex.Message });
        }
    }

    /// <summary>
    /// Get inspection history for a specific extinguisher
    /// </summary>
    [HttpGet("extinguisher/{extinguisherId:guid}")]
    public async Task<ActionResult<IEnumerable<InspectionDto>>> GetExtinguisherInspectionHistory(Guid extinguisherId)
    {
        if (_tenantContext.TenantId == Guid.Empty)
            return Unauthorized(new { message = "Tenant context not found" });

        try
        {
            var inspections = await _inspectionService.GetExtinguisherInspectionHistoryAsync(_tenantContext.TenantId, extinguisherId);
            return Ok(inspections);
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error retrieving inspection history for extinguisher {ExtinguisherId} for tenant {TenantId}",
                extinguisherId, _tenantContext.TenantId);
            return StatusCode(500, new { message = "Failed to retrieve inspection history", error = ex.Message });
        }
    }

    /// <summary>
    /// Get inspections performed by a specific inspector
    /// </summary>
    [HttpGet("inspector/{inspectorUserId:guid}")]
    public async Task<ActionResult<IEnumerable<InspectionDto>>> GetInspectorInspections(
        Guid inspectorUserId,
        [FromQuery] DateTime? startDate = null,
        [FromQuery] DateTime? endDate = null)
    {
        if (_tenantContext.TenantId == Guid.Empty)
            return Unauthorized(new { message = "Tenant context not found" });

        try
        {
            var inspections = await _inspectionService.GetInspectorInspectionsAsync(
                _tenantContext.TenantId,
                inspectorUserId,
                startDate,
                endDate);

            return Ok(inspections);
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error retrieving inspections for inspector {InspectorUserId} for tenant {TenantId}",
                inspectorUserId, _tenantContext.TenantId);
            return StatusCode(500, new { message = "Failed to retrieve inspector inspections", error = ex.Message });
        }
    }

    /// <summary>
    /// Verify the tamper-proof integrity of an inspection
    /// </summary>
    [HttpPost("{id:guid}/verify")]
    public async Task<ActionResult<InspectionVerificationResponse>> VerifyInspectionIntegrity(Guid id)
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
            _logger.LogError(ex, "Error verifying inspection {InspectionId} for tenant {TenantId}",
                id, _tenantContext.TenantId);
            return StatusCode(500, new { message = "Failed to verify inspection integrity", error = ex.Message });
        }
    }

    /// <summary>
    /// Get inspection statistics
    /// </summary>
    [HttpGet("stats")]
    public async Task<ActionResult<InspectionStatsDto>> GetInspectionStats(
        [FromQuery] DateTime? startDate = null,
        [FromQuery] DateTime? endDate = null)
    {
        if (_tenantContext.TenantId == Guid.Empty)
            return Unauthorized(new { message = "Tenant context not found" });

        try
        {
            var stats = await _inspectionService.GetInspectionStatsAsync(_tenantContext.TenantId, startDate, endDate);
            return Ok(stats);
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error retrieving inspection stats for tenant {TenantId}", _tenantContext.TenantId);
            return StatusCode(500, new { message = "Failed to retrieve inspection statistics", error = ex.Message });
        }
    }

    /// <summary>
    /// Get overdue inspections
    /// </summary>
    [HttpGet("overdue")]
    public async Task<ActionResult<IEnumerable<InspectionDto>>> GetOverdueInspections(
        [FromQuery] string inspectionType = "Monthly")
    {
        if (_tenantContext.TenantId == Guid.Empty)
            return Unauthorized(new { message = "Tenant context not found" });

        try
        {
            var inspections = await _inspectionService.GetOverdueInspectionsAsync(_tenantContext.TenantId, inspectionType);
            return Ok(inspections);
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error retrieving overdue inspections for tenant {TenantId}", _tenantContext.TenantId);
            return StatusCode(500, new { message = "Failed to retrieve overdue inspections", error = ex.Message });
        }
    }

    /// <summary>
    /// Delete an inspection
    /// </summary>
    [HttpDelete("{id:guid}")]
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
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error deleting inspection {InspectionId} for tenant {TenantId}",
                id, _tenantContext.TenantId);
            return StatusCode(500, new { message = "Failed to delete inspection", error = ex.Message });
        }
    }
}
