using FireExtinguisherInspection.API.Models.DTOs;

namespace FireExtinguisherInspection.API.Services;

/// <summary>
/// Service interface for user management operations
/// </summary>
public interface IUserService
{
    /// <summary>
    /// Retrieves all users with optional filtering and pagination
    /// </summary>
    Task<UserListResponse> GetAllUsersAsync(GetUsersRequest request);

    /// <summary>
    /// Retrieves a specific user by ID with role information
    /// </summary>
    Task<UserDetailDto?> GetUserByIdAsync(Guid userId);

    /// <summary>
    /// Updates user profile information
    /// </summary>
    Task<UserDto> UpdateUserAsync(UpdateUserRequest request);

    /// <summary>
    /// Soft deletes a user (sets IsActive = 0)
    /// </summary>
    Task DeleteUserAsync(Guid userId);

    /// <summary>
    /// Assigns a system role to a user
    /// </summary>
    Task<IEnumerable<SystemRoleDto>> AssignSystemRoleAsync(AssignSystemRoleRequest request);

    /// <summary>
    /// Removes a system role from a user
    /// </summary>
    Task RemoveSystemRoleAsync(RemoveSystemRoleRequest request);

    /// <summary>
    /// Gets all system roles assigned to a user
    /// </summary>
    Task<IEnumerable<SystemRoleDto>> GetUserSystemRolesAsync(Guid userId);

    /// <summary>
    /// Gets all tenant roles assigned to a user
    /// </summary>
    Task<IEnumerable<UserTenantRoleDto>> GetUserTenantRolesAsync(Guid userId);

    /// <summary>
    /// Assigns a tenant role to a user
    /// </summary>
    Task<IEnumerable<UserTenantRoleDto>> AssignTenantRoleAsync(AssignTenantRoleRequest request);

    /// <summary>
    /// Removes a tenant role from a user
    /// </summary>
    Task RemoveTenantRoleAsync(RemoveTenantRoleRequest request);

    /// <summary>
    /// Gets all available system roles
    /// </summary>
    Task<IEnumerable<SystemRoleDto>> GetAllSystemRolesAsync();
}
