using FireExtinguisherInspection.API.Authorization;
using FireExtinguisherInspection.API.Helpers;
using FireExtinguisherInspection.API.Models;
using FireExtinguisherInspection.API.Models.DTOs;
using FireExtinguisherInspection.API.Services;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace FireExtinguisherInspection.API.Controllers;

/// <summary>
/// API controller for location management
/// Requires tenant-level authorization (Manager or above)
/// </summary>
[ApiController]
[Route("api/[controller]")]
[Authorize] // Require authentication for all endpoints
public class LocationsController : ControllerBase
{
    private readonly ILocationService _locationService;
    private readonly TenantContext _tenantContext;
    private readonly ILogger<LocationsController> _logger;

    public LocationsController(
        ILocationService locationService,
        TenantContext tenantContext,
        ILogger<LocationsController> logger)
    {
        _locationService = locationService;
        _tenantContext = tenantContext;
        _logger = logger;
    }

    /// <summary>
    /// Creates a new location
    /// </summary>
    /// <param name="request">Location creation request</param>
    /// <returns>Created location</returns>
    [HttpPost]
    [Authorize(Policy = AuthorizationPolicies.ManagerOrAbove)]
    [ProducesResponseType(typeof(LocationDto), StatusCodes.Status201Created)]
    [ProducesResponseType(StatusCodes.Status400BadRequest)]
    [ProducesResponseType(StatusCodes.Status401Unauthorized)]
    [ProducesResponseType(StatusCodes.Status403Forbidden)]
    public async Task<ActionResult<LocationDto>> CreateLocation([FromBody] CreateLocationRequest request)
    {
        if (_tenantContext.TenantId == Guid.Empty)
        {
            return Unauthorized(new { message = "Tenant context not found" });
        }

        _logger.LogInformation("Creating location for tenant {TenantId}", _tenantContext.TenantId);

        var location = await _locationService.CreateLocationAsync(_tenantContext.TenantId, request);

        return CreatedAtAction(
            nameof(GetLocationById),
            new { id = location.LocationId },
            location);
    }

    /// <summary>
    /// Retrieves all locations for the current tenant
    /// SystemAdmin users can optionally specify a tenantId parameter to query a specific tenant
    /// </summary>
    /// <param name="isActive">Filter by active status (optional)</param>
    /// <param name="tenantId">Tenant ID (SystemAdmin only)</param>
    /// <returns>List of locations</returns>
    [HttpGet]
    [Authorize(Policy = AuthorizationPolicies.InspectorOrAbove)]
    [ProducesResponseType(typeof(IEnumerable<LocationDto>), StatusCodes.Status200OK)]
    [ProducesResponseType(StatusCodes.Status401Unauthorized)]
    [ProducesResponseType(StatusCodes.Status403Forbidden)]
    public async Task<ActionResult<IEnumerable<LocationDto>>> GetAllLocations(
        [FromQuery] bool? isActive = null,
        [FromQuery] Guid? tenantId = null)
    {
        if (!TenantResolver.TryResolveTenantId(User, _tenantContext, tenantId, out var effectiveTenantId, out var errorMessage))
        {
            if (TenantResolver.IsSystemAdmin(User) && !tenantId.HasValue)
            {
                _logger.LogDebug("SystemAdmin without tenantId - returning empty result");
                return Ok(Array.Empty<LocationDto>());
            }
            return Unauthorized(new { message = errorMessage });
        }

        _logger.LogDebug("Fetching locations for tenant {TenantId}", effectiveTenantId);
        var locations = await _locationService.GetAllLocationsAsync(effectiveTenantId, isActive);
        return Ok(locations);
    }

    /// <summary>
    /// Retrieves a specific location by ID
    /// </summary>
    /// <param name="id">Location ID</param>
    /// <returns>Location details</returns>
    [HttpGet("{id}")]
    [Authorize(Policy = AuthorizationPolicies.InspectorOrAbove)]
    [ProducesResponseType(typeof(LocationDto), StatusCodes.Status200OK)]
    [ProducesResponseType(StatusCodes.Status404NotFound)]
    [ProducesResponseType(StatusCodes.Status401Unauthorized)]
    [ProducesResponseType(StatusCodes.Status403Forbidden)]
    public async Task<ActionResult<LocationDto>> GetLocationById(Guid id, [FromQuery] Guid? tenantId = null)
    {
        if (!TenantResolver.TryResolveTenantId(User, _tenantContext, tenantId, out var effectiveTenantId, out var errorMessage))
        {
            if (TenantResolver.IsSystemAdmin(User) && !tenantId.HasValue)
            {
                _logger.LogDebug("SystemAdmin without tenantId - returning empty result");
                return Ok(Array.Empty<LocationDto>());
            }
            return Unauthorized(new { message = errorMessage });
        }

        _logger.LogDebug("Fetching location {LocationId} for tenant {TenantId}", id, effectiveTenantId);

        var location = await _locationService.GetLocationByIdAsync(effectiveTenantId, id);

        if (location == null)
        {
            return NotFound(new { message = $"Location {id} not found" });
        }

        return Ok(location);
    }

    /// <summary>
    /// Updates an existing location
    /// </summary>
    /// <param name="id">Location ID</param>
    /// <param name="request">Location update request</param>
    /// <returns>Updated location</returns>
    [HttpPut("{id}")]
    [Authorize(Policy = AuthorizationPolicies.ManagerOrAbove)]
    [ProducesResponseType(typeof(LocationDto), StatusCodes.Status200OK)]
    [ProducesResponseType(StatusCodes.Status404NotFound)]
    [ProducesResponseType(StatusCodes.Status400BadRequest)]
    [ProducesResponseType(StatusCodes.Status401Unauthorized)]
    [ProducesResponseType(StatusCodes.Status403Forbidden)]
    public async Task<ActionResult<LocationDto>> UpdateLocation(Guid id, [FromBody] UpdateLocationRequest request)
    {
        if (_tenantContext.TenantId == Guid.Empty)
        {
            return Unauthorized(new { message = "Tenant context not found" });
        }

        _logger.LogInformation("Updating location {LocationId} for tenant {TenantId}", id, _tenantContext.TenantId);

        try
        {
            var location = await _locationService.UpdateLocationAsync(_tenantContext.TenantId, id, request);
            return Ok(location);
        }
        catch (KeyNotFoundException ex)
        {
            return NotFound(new { message = ex.Message });
        }
    }

    /// <summary>
    /// Deletes (soft delete) a location
    /// </summary>
    /// <param name="id">Location ID</param>
    /// <returns>No content on success</returns>
    [HttpDelete("{id}")]
    [Authorize(Policy = AuthorizationPolicies.AdminOrTenantAdmin)]
    [ProducesResponseType(StatusCodes.Status204NoContent)]
    [ProducesResponseType(StatusCodes.Status404NotFound)]
    [ProducesResponseType(StatusCodes.Status401Unauthorized)]
    [ProducesResponseType(StatusCodes.Status403Forbidden)]
    public async Task<IActionResult> DeleteLocation(Guid id)
    {
        if (_tenantContext.TenantId == Guid.Empty)
        {
            return Unauthorized(new { message = "Tenant context not found" });
        }

        _logger.LogInformation("Deleting location {LocationId} for tenant {TenantId}", id, _tenantContext.TenantId);

        var success = await _locationService.DeleteLocationAsync(_tenantContext.TenantId, id);

        if (!success)
        {
            return NotFound(new { message = $"Location {id} not found" });
        }

        return NoContent();
    }
}
