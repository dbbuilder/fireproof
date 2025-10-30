using FireExtinguisherInspection.API.Authorization;
using FireExtinguisherInspection.API.Models.DTOs;
using FireExtinguisherInspection.API.Services;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace FireExtinguisherInspection.API.Controllers;

/// <summary>
/// API controller for user management (SystemAdmin only)
/// </summary>
[ApiController]
[Route("api/[controller]")]
[Authorize(Policy = AuthorizationPolicies.SystemAdminOnly)] // All endpoints require SystemAdmin
public class UsersController : ControllerBase
{
    private readonly IUserService _userService;
    private readonly ILogger<UsersController> _logger;

    public UsersController(
        IUserService userService,
        ILogger<UsersController> logger)
    {
        _userService = userService;
        _logger = logger;
    }

    /// <summary>
    /// Retrieves all users with optional filtering and pagination
    /// </summary>
    /// <param name="searchTerm">Optional search term for email, first name, or last name</param>
    /// <param name="isActive">Optional filter by active status</param>
    /// <param name="pageNumber">Page number (1-based)</param>
    /// <param name="pageSize">Number of records per page (max 100)</param>
    /// <returns>Paginated list of users</returns>
    [HttpGet]
    [ProducesResponseType(typeof(UserListResponse), StatusCodes.Status200OK)]
    [ProducesResponseType(StatusCodes.Status401Unauthorized)]
    [ProducesResponseType(StatusCodes.Status403Forbidden)]
    public async Task<ActionResult<UserListResponse>> GetAllUsers(
        [FromQuery] string? searchTerm = null,
        [FromQuery] bool? isActive = null,
        [FromQuery] int pageNumber = 1,
        [FromQuery] int pageSize = 50)
    {
        _logger.LogDebug("GetAllUsers called with search: {SearchTerm}, active: {IsActive}, page: {PageNumber}",
            searchTerm, isActive, pageNumber);

        var request = new GetUsersRequest
        {
            SearchTerm = searchTerm,
            IsActive = isActive,
            PageNumber = pageNumber,
            PageSize = pageSize
        };

        var result = await _userService.GetAllUsersAsync(request);
        return Ok(result);
    }

    /// <summary>
    /// Retrieves a specific user by ID with full role information
    /// </summary>
    /// <param name="id">User ID</param>
    /// <returns>User details with roles</returns>
    [HttpGet("{id}")]
    [ProducesResponseType(typeof(UserDetailDto), StatusCodes.Status200OK)]
    [ProducesResponseType(StatusCodes.Status404NotFound)]
    [ProducesResponseType(StatusCodes.Status401Unauthorized)]
    [ProducesResponseType(StatusCodes.Status403Forbidden)]
    public async Task<ActionResult<UserDetailDto>> GetUserById(Guid id)
    {
        _logger.LogDebug("GetUserById called for user {UserId}", id);

        var user = await _userService.GetUserByIdAsync(id);

        if (user == null)
        {
            return NotFound(new { message = $"User {id} not found" });
        }

        return Ok(user);
    }

    /// <summary>
    /// Updates user profile information
    /// </summary>
    /// <param name="id">User ID</param>
    /// <param name="request">Update user request</param>
    /// <returns>Updated user</returns>
    [HttpPut("{id}")]
    [ProducesResponseType(typeof(UserDto), StatusCodes.Status200OK)]
    [ProducesResponseType(StatusCodes.Status400BadRequest)]
    [ProducesResponseType(StatusCodes.Status404NotFound)]
    [ProducesResponseType(StatusCodes.Status401Unauthorized)]
    [ProducesResponseType(StatusCodes.Status403Forbidden)]
    public async Task<ActionResult<UserDto>> UpdateUser(Guid id, [FromBody] UpdateUserRequest request)
    {
        _logger.LogInformation("UpdateUser called for user {UserId}", id);

        if (id != request.UserId)
        {
            return BadRequest(new { message = "User ID in URL does not match request body" });
        }

        try
        {
            var user = await _userService.UpdateUserAsync(request);
            return Ok(user);
        }
        catch (InvalidOperationException ex)
        {
            _logger.LogWarning(ex, "Failed to update user {UserId}", id);
            return NotFound(new { message = ex.Message });
        }
    }

    /// <summary>
    /// Soft deletes a user (sets IsActive = 0)
    /// </summary>
    /// <param name="id">User ID</param>
    /// <returns>No content</returns>
    [HttpDelete("{id}")]
    [ProducesResponseType(StatusCodes.Status204NoContent)]
    [ProducesResponseType(StatusCodes.Status404NotFound)]
    [ProducesResponseType(StatusCodes.Status401Unauthorized)]
    [ProducesResponseType(StatusCodes.Status403Forbidden)]
    public async Task<IActionResult> DeleteUser(Guid id)
    {
        _logger.LogInformation("DeleteUser called for user {UserId}", id);

        try
        {
            await _userService.DeleteUserAsync(id);
            return NoContent();
        }
        catch (Exception ex)
        {
            _logger.LogWarning(ex, "Failed to delete user {UserId}", id);
            return NotFound(new { message = $"User {id} not found" });
        }
    }

    /// <summary>
    /// Gets all system roles assigned to a user
    /// </summary>
    /// <param name="id">User ID</param>
    /// <returns>List of system roles</returns>
    [HttpGet("{id}/system-roles")]
    [ProducesResponseType(typeof(IEnumerable<SystemRoleDto>), StatusCodes.Status200OK)]
    [ProducesResponseType(StatusCodes.Status404NotFound)]
    [ProducesResponseType(StatusCodes.Status401Unauthorized)]
    [ProducesResponseType(StatusCodes.Status403Forbidden)]
    public async Task<ActionResult<IEnumerable<SystemRoleDto>>> GetUserSystemRoles(Guid id)
    {
        _logger.LogDebug("GetUserSystemRoles called for user {UserId}", id);

        var roles = await _userService.GetUserSystemRolesAsync(id);
        return Ok(roles);
    }

    /// <summary>
    /// Assigns a system role to a user
    /// </summary>
    /// <param name="id">User ID</param>
    /// <param name="request">Assign system role request</param>
    /// <returns>Updated list of system roles</returns>
    [HttpPost("{id}/system-roles")]
    [ProducesResponseType(typeof(IEnumerable<SystemRoleDto>), StatusCodes.Status200OK)]
    [ProducesResponseType(StatusCodes.Status400BadRequest)]
    [ProducesResponseType(StatusCodes.Status404NotFound)]
    [ProducesResponseType(StatusCodes.Status401Unauthorized)]
    [ProducesResponseType(StatusCodes.Status403Forbidden)]
    public async Task<ActionResult<IEnumerable<SystemRoleDto>>> AssignSystemRole(
        Guid id,
        [FromBody] AssignSystemRoleRequest request)
    {
        _logger.LogInformation("AssignSystemRole called for user {UserId}", id);

        if (id != request.UserId)
        {
            return BadRequest(new { message = "User ID in URL does not match request body" });
        }

        try
        {
            var roles = await _userService.AssignSystemRoleAsync(request);
            return Ok(roles);
        }
        catch (Exception ex)
        {
            _logger.LogWarning(ex, "Failed to assign system role to user {UserId}", id);
            return BadRequest(new { message = ex.Message });
        }
    }

    /// <summary>
    /// Removes a system role from a user
    /// </summary>
    /// <param name="id">User ID</param>
    /// <param name="roleId">System role ID</param>
    /// <returns>No content</returns>
    [HttpDelete("{id}/system-roles/{roleId}")]
    [ProducesResponseType(StatusCodes.Status204NoContent)]
    [ProducesResponseType(StatusCodes.Status404NotFound)]
    [ProducesResponseType(StatusCodes.Status401Unauthorized)]
    [ProducesResponseType(StatusCodes.Status403Forbidden)]
    public async Task<IActionResult> RemoveSystemRole(Guid id, Guid roleId)
    {
        _logger.LogInformation("RemoveSystemRole called for user {UserId}, role {RoleId}", id, roleId);

        try
        {
            await _userService.RemoveSystemRoleAsync(new RemoveSystemRoleRequest
            {
                UserId = id,
                SystemRoleId = roleId
            });
            return NoContent();
        }
        catch (Exception ex)
        {
            _logger.LogWarning(ex, "Failed to remove system role from user {UserId}", id);
            return NotFound(new { message = ex.Message });
        }
    }

    /// <summary>
    /// Gets all tenant roles assigned to a user
    /// </summary>
    /// <param name="id">User ID</param>
    /// <returns>List of tenant roles</returns>
    [HttpGet("{id}/tenant-roles")]
    [ProducesResponseType(typeof(IEnumerable<UserTenantRoleDto>), StatusCodes.Status200OK)]
    [ProducesResponseType(StatusCodes.Status404NotFound)]
    [ProducesResponseType(StatusCodes.Status401Unauthorized)]
    [ProducesResponseType(StatusCodes.Status403Forbidden)]
    public async Task<ActionResult<IEnumerable<UserTenantRoleDto>>> GetUserTenantRoles(Guid id)
    {
        _logger.LogDebug("GetUserTenantRoles called for user {UserId}", id);

        var roles = await _userService.GetUserTenantRolesAsync(id);
        return Ok(roles);
    }

    /// <summary>
    /// Assigns a tenant role to a user
    /// </summary>
    /// <param name="id">User ID</param>
    /// <param name="request">Assign tenant role request</param>
    /// <returns>Updated list of tenant roles</returns>
    [HttpPost("{id}/tenant-roles")]
    [ProducesResponseType(typeof(IEnumerable<UserTenantRoleDto>), StatusCodes.Status200OK)]
    [ProducesResponseType(StatusCodes.Status400BadRequest)]
    [ProducesResponseType(StatusCodes.Status404NotFound)]
    [ProducesResponseType(StatusCodes.Status401Unauthorized)]
    [ProducesResponseType(StatusCodes.Status403Forbidden)]
    public async Task<ActionResult<IEnumerable<UserTenantRoleDto>>> AssignTenantRole(
        Guid id,
        [FromBody] AssignTenantRoleRequest request)
    {
        _logger.LogInformation("AssignTenantRole called for user {UserId}", id);

        if (id != request.UserId)
        {
            return BadRequest(new { message = "User ID in URL does not match request body" });
        }

        try
        {
            var roles = await _userService.AssignTenantRoleAsync(request);
            return Ok(roles);
        }
        catch (Exception ex)
        {
            _logger.LogWarning(ex, "Failed to assign tenant role to user {UserId}", id);
            return BadRequest(new { message = ex.Message });
        }
    }

    /// <summary>
    /// Removes a tenant role from a user
    /// </summary>
    /// <param name="id">User ID</param>
    /// <param name="tenantRoleId">User tenant role ID</param>
    /// <returns>No content</returns>
    [HttpDelete("{id}/tenant-roles/{tenantRoleId}")]
    [ProducesResponseType(StatusCodes.Status204NoContent)]
    [ProducesResponseType(StatusCodes.Status404NotFound)]
    [ProducesResponseType(StatusCodes.Status401Unauthorized)]
    [ProducesResponseType(StatusCodes.Status403Forbidden)]
    public async Task<IActionResult> RemoveTenantRole(Guid id, Guid tenantRoleId)
    {
        _logger.LogInformation("RemoveTenantRole called for user {UserId}, tenant role {TenantRoleId}", id, tenantRoleId);

        try
        {
            await _userService.RemoveTenantRoleAsync(new RemoveTenantRoleRequest
            {
                UserId = id,
                UserTenantRoleId = tenantRoleId
            });
            return NoContent();
        }
        catch (Exception ex)
        {
            _logger.LogWarning(ex, "Failed to remove tenant role from user {UserId}", id);
            return NotFound(new { message = ex.Message });
        }
    }

    /// <summary>
    /// Gets all available system roles (for dropdown selection)
    /// </summary>
    /// <returns>List of system roles</returns>
    [HttpGet("system-roles")]
    [ProducesResponseType(typeof(IEnumerable<SystemRoleDto>), StatusCodes.Status200OK)]
    [ProducesResponseType(StatusCodes.Status401Unauthorized)]
    [ProducesResponseType(StatusCodes.Status403Forbidden)]
    public async Task<ActionResult<IEnumerable<SystemRoleDto>>> GetAllSystemRoles()
    {
        _logger.LogDebug("GetAllSystemRoles called");

        var roles = await _userService.GetAllSystemRolesAsync();
        return Ok(roles);
    }
}
