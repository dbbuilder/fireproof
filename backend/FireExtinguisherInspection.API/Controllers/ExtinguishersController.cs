using FireExtinguisherInspection.API.Authorization;
using FireExtinguisherInspection.API.Helpers;
using FireExtinguisherInspection.API.Models;
using FireExtinguisherInspection.API.Models.DTOs;
using FireExtinguisherInspection.API.Services;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace FireExtinguisherInspection.API.Controllers;

/// <summary>
/// API controller for fire extinguisher inventory management
/// Requires tenant-level authorization
/// </summary>
[ApiController]
[Route("api/[controller]")]
[Authorize] // Require authentication for all endpoints
public class ExtinguishersController : ControllerBase
{
    private readonly IExtinguisherService _extinguisherService;
    private readonly TenantContext _tenantContext;
    private readonly ILogger<ExtinguishersController> _logger;

    public ExtinguishersController(
        IExtinguisherService extinguisherService,
        TenantContext tenantContext,
        ILogger<ExtinguishersController> logger)
    {
        _extinguisherService = extinguisherService;
        _tenantContext = tenantContext;
        _logger = logger;
    }

    /// <summary>
    /// Create a new fire extinguisher
    /// </summary>
    [HttpPost]
    [Authorize(Policy = AuthorizationPolicies.ManagerOrAbove)]
    [ProducesResponseType(typeof(ExtinguisherDto), StatusCodes.Status201Created)]
    [ProducesResponseType(StatusCodes.Status400BadRequest)]
    [ProducesResponseType(StatusCodes.Status401Unauthorized)]
    [ProducesResponseType(StatusCodes.Status403Forbidden)]
    public async Task<ActionResult<ExtinguisherDto>> CreateExtinguisher([FromBody] CreateExtinguisherRequest request)
    {
        if (_tenantContext.TenantId == Guid.Empty)
            return Unauthorized(new { message = "Tenant context not found" });

        try
        {
            var extinguisher = await _extinguisherService.CreateExtinguisherAsync(_tenantContext.TenantId, request);
            return CreatedAtAction(nameof(GetExtinguisherById), new { id = extinguisher.ExtinguisherId }, extinguisher);
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error creating extinguisher for tenant {TenantId}", _tenantContext.TenantId);
            return StatusCode(500, new { message = "Failed to create extinguisher", error = ex.Message });
        }
    }

    /// <summary>
    /// Get all fire extinguishers with optional filtering
    /// </summary>
    [HttpGet]
    [Authorize(Policy = AuthorizationPolicies.InspectorOrAbove)]
    [ProducesResponseType(typeof(IEnumerable<ExtinguisherDto>), StatusCodes.Status200OK)]
    [ProducesResponseType(StatusCodes.Status401Unauthorized)]
    [ProducesResponseType(StatusCodes.Status403Forbidden)]
    public async Task<ActionResult<IEnumerable<ExtinguisherDto>>> GetAllExtinguishers(
        [FromQuery] Guid? locationId = null,
        [FromQuery] Guid? typeId = null,
        [FromQuery] bool? isActive = null,
        [FromQuery] bool? isOutOfService = null,
        [FromQuery] Guid? tenantId = null)
    {
        if (!TenantResolver.TryResolveTenantId(User, _tenantContext, tenantId, out var effectiveTenantId, out var errorMessage))
        {
            if (TenantResolver.IsSystemAdmin(User) && !tenantId.HasValue)
            {
                _logger.LogDebug("SystemAdmin without tenantId - returning empty result");
                return Ok(Array.Empty<ExtinguisherDto>());
            }
            return Unauthorized(new { message = errorMessage });
        }

        try
        {
            var extinguishers = await _extinguisherService.GetAllExtinguishersAsync(
                effectiveTenantId,
                locationId,
                typeId,
                isActive,
                isOutOfService);

            return Ok(extinguishers);
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error retrieving extinguishers for tenant {TenantId}", effectiveTenantId);
            return StatusCode(500, new { message = "Failed to retrieve extinguishers", error = ex.Message });
        }
    }

    /// <summary>
    /// Get extinguisher by ID
    /// </summary>
    [HttpGet("{id:guid}")]
    [Authorize(Policy = AuthorizationPolicies.InspectorOrAbove)]
    [ProducesResponseType(typeof(ExtinguisherDto), StatusCodes.Status200OK)]
    [ProducesResponseType(StatusCodes.Status404NotFound)]
    [ProducesResponseType(StatusCodes.Status401Unauthorized)]
    [ProducesResponseType(StatusCodes.Status403Forbidden)]
    public async Task<ActionResult<ExtinguisherDto>> GetExtinguisherById(Guid id, [FromQuery] Guid? tenantId = null)
    {
        if (!TenantResolver.TryResolveTenantId(User, _tenantContext, tenantId, out var effectiveTenantId, out var errorMessage))
        {
            if (TenantResolver.IsSystemAdmin(User) && !tenantId.HasValue)
            {
                _logger.LogDebug("SystemAdmin without tenantId - returning empty result");
                return Ok(Array.Empty<ExtinguisherDto>());
            }
            return Unauthorized(new { message = errorMessage });
        }

        try
        {
            var extinguisher = await _extinguisherService.GetExtinguisherByIdAsync(effectiveTenantId, id);

            if (extinguisher == null)
                return NotFound(new { message = $"Extinguisher {id} not found" });

            return Ok(extinguisher);
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error retrieving extinguisher {ExtinguisherId} for tenant {TenantId}",
                id, effectiveTenantId);
            return StatusCode(500, new { message = "Failed to retrieve extinguisher", error = ex.Message });
        }
    }

    /// <summary>
    /// Get extinguisher by barcode
    /// </summary>
    [HttpGet("barcode/{barcodeData}")]
    [Authorize(Policy = AuthorizationPolicies.InspectorOrAbove)]
    [ProducesResponseType(typeof(ExtinguisherDto), StatusCodes.Status200OK)]
    [ProducesResponseType(StatusCodes.Status404NotFound)]
    [ProducesResponseType(StatusCodes.Status401Unauthorized)]
    [ProducesResponseType(StatusCodes.Status403Forbidden)]
    public async Task<ActionResult<ExtinguisherDto>> GetExtinguisherByBarcode(string barcodeData, [FromQuery] Guid? tenantId = null)
    {
        if (!TenantResolver.TryResolveTenantId(User, _tenantContext, tenantId, out var effectiveTenantId, out var errorMessage))
        {
            if (TenantResolver.IsSystemAdmin(User) && !tenantId.HasValue)
            {
                _logger.LogDebug("SystemAdmin without tenantId - returning empty result");
                return Ok(Array.Empty<ExtinguisherDto>());
            }
            return Unauthorized(new { message = errorMessage });
        }

        try
        {
            var extinguisher = await _extinguisherService.GetExtinguisherByBarcodeAsync(effectiveTenantId, barcodeData);

            if (extinguisher == null)
                return NotFound(new { message = $"Extinguisher with barcode {barcodeData} not found" });

            return Ok(extinguisher);
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error retrieving extinguisher by barcode {BarcodeData} for tenant {TenantId}",
                barcodeData, effectiveTenantId);
            return StatusCode(500, new { message = "Failed to retrieve extinguisher", error = ex.Message });
        }
    }

    /// <summary>
    /// Update an extinguisher
    /// </summary>
    [HttpPut("{id:guid}")]
    [Authorize(Policy = AuthorizationPolicies.ManagerOrAbove)]
    [ProducesResponseType(typeof(ExtinguisherDto), StatusCodes.Status200OK)]
    [ProducesResponseType(StatusCodes.Status404NotFound)]
    [ProducesResponseType(StatusCodes.Status400BadRequest)]
    [ProducesResponseType(StatusCodes.Status401Unauthorized)]
    [ProducesResponseType(StatusCodes.Status403Forbidden)]
    public async Task<ActionResult<ExtinguisherDto>> UpdateExtinguisher(Guid id, [FromBody] UpdateExtinguisherRequest request)
    {
        if (_tenantContext.TenantId == Guid.Empty)
            return Unauthorized(new { message = "Tenant context not found" });

        try
        {
            var extinguisher = await _extinguisherService.UpdateExtinguisherAsync(_tenantContext.TenantId, id, request);
            return Ok(extinguisher);
        }
        catch (KeyNotFoundException)
        {
            return NotFound(new { message = $"Extinguisher {id} not found" });
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error updating extinguisher {ExtinguisherId} for tenant {TenantId}",
                id, _tenantContext.TenantId);
            return StatusCode(500, new { message = "Failed to update extinguisher", error = ex.Message });
        }
    }

    /// <summary>
    /// Delete an extinguisher
    /// </summary>
    [HttpDelete("{id:guid}")]
    [Authorize(Policy = AuthorizationPolicies.AdminOrTenantAdmin)]
    [ProducesResponseType(StatusCodes.Status204NoContent)]
    [ProducesResponseType(StatusCodes.Status404NotFound)]
    [ProducesResponseType(StatusCodes.Status401Unauthorized)]
    [ProducesResponseType(StatusCodes.Status403Forbidden)]
    public async Task<IActionResult> DeleteExtinguisher(Guid id)
    {
        if (_tenantContext.TenantId == Guid.Empty)
            return Unauthorized(new { message = "Tenant context not found" });

        try
        {
            var success = await _extinguisherService.DeleteExtinguisherAsync(_tenantContext.TenantId, id);

            if (!success)
                return NotFound(new { message = $"Extinguisher {id} not found" });

            return NoContent();
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error deleting extinguisher {ExtinguisherId} for tenant {TenantId}",
                id, _tenantContext.TenantId);
            return StatusCode(500, new { message = "Failed to delete extinguisher", error = ex.Message });
        }
    }

    /// <summary>
    /// Generate or regenerate barcode for an extinguisher
    /// </summary>
    [HttpPost("{id:guid}/barcode")]
    [Authorize(Policy = AuthorizationPolicies.ManagerOrAbove)]
    [ProducesResponseType(typeof(BarcodeResponse), StatusCodes.Status200OK)]
    [ProducesResponseType(StatusCodes.Status404NotFound)]
    [ProducesResponseType(StatusCodes.Status401Unauthorized)]
    [ProducesResponseType(StatusCodes.Status403Forbidden)]
    public async Task<ActionResult<BarcodeResponse>> GenerateBarcode(Guid id)
    {
        if (_tenantContext.TenantId == Guid.Empty)
            return Unauthorized(new { message = "Tenant context not found" });

        try
        {
            var barcodeResponse = await _extinguisherService.GenerateBarcodeAsync(_tenantContext.TenantId, id);
            return Ok(barcodeResponse);
        }
        catch (KeyNotFoundException)
        {
            return NotFound(new { message = $"Extinguisher {id} not found" });
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error generating barcode for extinguisher {ExtinguisherId} for tenant {TenantId}",
                id, _tenantContext.TenantId);
            return StatusCode(500, new { message = "Failed to generate barcode", error = ex.Message });
        }
    }

    /// <summary>
    /// Mark extinguisher as out of service
    /// </summary>
    [HttpPost("{id:guid}/outofservice")]
    [Authorize(Policy = AuthorizationPolicies.InspectorOrAbove)]
    [ProducesResponseType(typeof(ExtinguisherDto), StatusCodes.Status200OK)]
    [ProducesResponseType(StatusCodes.Status404NotFound)]
    [ProducesResponseType(StatusCodes.Status401Unauthorized)]
    [ProducesResponseType(StatusCodes.Status403Forbidden)]
    public async Task<ActionResult<ExtinguisherDto>> MarkOutOfService(Guid id, [FromBody] OutOfServiceRequest request)
    {
        if (_tenantContext.TenantId == Guid.Empty)
            return Unauthorized(new { message = "Tenant context not found" });

        try
        {
            var extinguisher = await _extinguisherService.MarkOutOfServiceAsync(_tenantContext.TenantId, id, request.Reason);
            return Ok(extinguisher);
        }
        catch (KeyNotFoundException)
        {
            return NotFound(new { message = $"Extinguisher {id} not found" });
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error marking extinguisher {ExtinguisherId} out of service for tenant {TenantId}",
                id, _tenantContext.TenantId);
            return StatusCode(500, new { message = "Failed to mark extinguisher out of service", error = ex.Message });
        }
    }

    /// <summary>
    /// Return extinguisher to service
    /// </summary>
    [HttpPost("{id:guid}/returntoservice")]
    [Authorize(Policy = AuthorizationPolicies.InspectorOrAbove)]
    [ProducesResponseType(typeof(ExtinguisherDto), StatusCodes.Status200OK)]
    [ProducesResponseType(StatusCodes.Status404NotFound)]
    [ProducesResponseType(StatusCodes.Status401Unauthorized)]
    [ProducesResponseType(StatusCodes.Status403Forbidden)]
    public async Task<ActionResult<ExtinguisherDto>> ReturnToService(Guid id)
    {
        if (_tenantContext.TenantId == Guid.Empty)
            return Unauthorized(new { message = "Tenant context not found" });

        try
        {
            var extinguisher = await _extinguisherService.ReturnToServiceAsync(_tenantContext.TenantId, id);
            return Ok(extinguisher);
        }
        catch (KeyNotFoundException)
        {
            return NotFound(new { message = $"Extinguisher {id} not found" });
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error returning extinguisher {ExtinguisherId} to service for tenant {TenantId}",
                id, _tenantContext.TenantId);
            return StatusCode(500, new { message = "Failed to return extinguisher to service", error = ex.Message });
        }
    }

    /// <summary>
    /// Get extinguishers needing service soon
    /// </summary>
    [HttpGet("needingservice")]
    [Authorize(Policy = AuthorizationPolicies.InspectorOrAbove)]
    [ProducesResponseType(typeof(IEnumerable<ExtinguisherDto>), StatusCodes.Status200OK)]
    [ProducesResponseType(StatusCodes.Status401Unauthorized)]
    [ProducesResponseType(StatusCodes.Status403Forbidden)]
    public async Task<ActionResult<IEnumerable<ExtinguisherDto>>> GetExtinguishersNeedingService([FromQuery] int daysAhead = 30, [FromQuery] Guid? tenantId = null)
    {
        if (!TenantResolver.TryResolveTenantId(User, _tenantContext, tenantId, out var effectiveTenantId, out var errorMessage))
        {
            if (TenantResolver.IsSystemAdmin(User) && !tenantId.HasValue)
            {
                _logger.LogDebug("SystemAdmin without tenantId - returning empty result");
                return Ok(Array.Empty<ExtinguisherDto>());
            }
            return Unauthorized(new { message = errorMessage });
        }

        try
        {
            var extinguishers = await _extinguisherService.GetExtinguishersNeedingServiceAsync(effectiveTenantId, daysAhead);
            return Ok(extinguishers);
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error retrieving extinguishers needing service for tenant {TenantId}", effectiveTenantId);
            return StatusCode(500, new { message = "Failed to retrieve extinguishers needing service", error = ex.Message });
        }
    }

    /// <summary>
    /// Get extinguishers needing hydro test soon
    /// </summary>
    [HttpGet("needinghydrotest")]
    [Authorize(Policy = AuthorizationPolicies.InspectorOrAbove)]
    [ProducesResponseType(typeof(IEnumerable<ExtinguisherDto>), StatusCodes.Status200OK)]
    [ProducesResponseType(StatusCodes.Status401Unauthorized)]
    [ProducesResponseType(StatusCodes.Status403Forbidden)]
    public async Task<ActionResult<IEnumerable<ExtinguisherDto>>> GetExtinguishersNeedingHydroTest([FromQuery] int daysAhead = 30, [FromQuery] Guid? tenantId = null)
    {
        if (!TenantResolver.TryResolveTenantId(User, _tenantContext, tenantId, out var effectiveTenantId, out var errorMessage))
        {
            if (TenantResolver.IsSystemAdmin(User) && !tenantId.HasValue)
            {
                _logger.LogDebug("SystemAdmin without tenantId - returning empty result");
                return Ok(Array.Empty<ExtinguisherDto>());
            }
            return Unauthorized(new { message = errorMessage });
        }

        try
        {
            var extinguishers = await _extinguisherService.GetExtinguishersNeedingHydroTestAsync(effectiveTenantId, daysAhead);
            return Ok(extinguishers);
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error retrieving extinguishers needing hydro test for tenant {TenantId}", effectiveTenantId);
            return StatusCode(500, new { message = "Failed to retrieve extinguishers needing hydro test", error = ex.Message });
        }
    }
}

/// <summary>
/// Request to mark extinguisher out of service
/// </summary>
public class OutOfServiceRequest
{
    public string Reason { get; set; } = string.Empty;
}
