using System.Data;
using FireExtinguisherInspection.API.Data;
using FireExtinguisherInspection.API.Models;
using FireExtinguisherInspection.API.Models.DTOs;
using Microsoft.Data.SqlClient;

namespace FireExtinguisherInspection.API.Services;

/// <summary>
/// Service for user management operations
/// </summary>
public class UserService : IUserService
{
    private readonly IDbConnectionFactory _connectionFactory;
    private readonly ILogger<UserService> _logger;
    private readonly IJwtTokenService _jwtTokenService;

    public UserService(
        IDbConnectionFactory connectionFactory,
        ILogger<UserService> logger,
        IJwtTokenService jwtTokenService)
    {
        _connectionFactory = connectionFactory;
        _logger = logger;
        _jwtTokenService = jwtTokenService;
    }

    public async Task<UserListResponse> GetAllUsersAsync(GetUsersRequest request)
    {
        _logger.LogDebug("Fetching users with search: {SearchTerm}, active: {IsActive}, page: {PageNumber}",
            request.SearchTerm, request.IsActive, request.PageNumber);

        using var connection = await _connectionFactory.CreateConnectionAsync();
        using var command = (SqlCommand)connection.CreateCommand();

        command.CommandText = "dbo.usp_User_GetAll";
        command.CommandType = CommandType.StoredProcedure;

        command.Parameters.AddWithValue("@SearchTerm", (object?)request.SearchTerm ?? DBNull.Value);
        command.Parameters.AddWithValue("@IsActive", (object?)request.IsActive ?? DBNull.Value);
        command.Parameters.AddWithValue("@PageNumber", request.PageNumber);
        command.Parameters.AddWithValue("@PageSize", request.PageSize);

        var users = new List<UserDetailDto>();
        int totalCount = 0;

        using var reader = await command.ExecuteReaderAsync();
        while (await reader.ReadAsync())
        {
            var user = MapUserDetailFromReader(reader);
            users.Add(user);

            // Get total count from first row (same for all rows)
            if (totalCount == 0)
            {
                var totalCountOrdinal = reader.GetOrdinal("TotalCount");
                totalCount = reader.GetInt32(totalCountOrdinal);
            }
        }

        _logger.LogInformation("Retrieved {Count} users out of {TotalCount}", users.Count, totalCount);

        return new UserListResponse
        {
            Users = users,
            TotalCount = totalCount,
            PageNumber = request.PageNumber,
            PageSize = request.PageSize
        };
    }

    public async Task<UserDetailDto?> GetUserByIdAsync(Guid userId)
    {
        _logger.LogDebug("Fetching user {UserId}", userId);

        using var connection = await _connectionFactory.CreateConnectionAsync();
        using var command = (SqlCommand)connection.CreateCommand();

        command.CommandText = "dbo.usp_User_GetById";
        command.CommandType = CommandType.StoredProcedure;
        command.Parameters.AddWithValue("@UserId", userId);

        UserDetailDto? user = null;

        using var reader = await command.ExecuteReaderAsync();
        if (await reader.ReadAsync())
        {
            user = new UserDetailDto
            {
                UserId = reader.GetGuid(reader.GetOrdinal("UserId")),
                Email = reader.GetString(reader.GetOrdinal("Email")),
                FirstName = reader.GetString(reader.GetOrdinal("FirstName")),
                LastName = reader.GetString(reader.GetOrdinal("LastName")),
                PhoneNumber = reader.IsDBNull(reader.GetOrdinal("PhoneNumber")) ? null : reader.GetString(reader.GetOrdinal("PhoneNumber")),
                EmailConfirmed = reader.GetBoolean(reader.GetOrdinal("EmailConfirmed")),
                MfaEnabled = reader.GetBoolean(reader.GetOrdinal("MfaEnabled")),
                LastLoginDate = reader.IsDBNull(reader.GetOrdinal("LastLoginDate")) ? null : reader.GetDateTime(reader.GetOrdinal("LastLoginDate")),
                IsActive = reader.GetBoolean(reader.GetOrdinal("IsActive")),
                CreatedDate = reader.GetDateTime(reader.GetOrdinal("CreatedDate")),
                ModifiedDate = reader.GetDateTime(reader.GetOrdinal("ModifiedDate"))
            };
        }

        if (user != null)
        {
            // Fetch system roles
            user.SystemRoles = (await GetUserSystemRolesAsync(userId)).ToList();
            user.SystemRoleCount = user.SystemRoles.Count;

            // Fetch tenant roles
            user.TenantRoles = (await GetUserTenantRolesAsync(userId)).ToList();
            user.TenantRoleCount = user.TenantRoles.Count;
        }

        return user;
    }

    public async Task<UserDto> UpdateUserAsync(UpdateUserRequest request)
    {
        _logger.LogInformation("Updating user {UserId}", request.UserId);

        using var connection = await _connectionFactory.CreateConnectionAsync();
        using var command = (SqlCommand)connection.CreateCommand();

        command.CommandText = "dbo.usp_User_Update";
        command.CommandType = CommandType.StoredProcedure;

        command.Parameters.AddWithValue("@UserId", request.UserId);
        command.Parameters.AddWithValue("@FirstName", request.FirstName);
        command.Parameters.AddWithValue("@LastName", request.LastName);
        command.Parameters.AddWithValue("@PhoneNumber", (object?)request.PhoneNumber ?? DBNull.Value);
        command.Parameters.AddWithValue("@EmailConfirmed", request.EmailConfirmed);
        command.Parameters.AddWithValue("@MfaEnabled", request.MfaEnabled);
        command.Parameters.AddWithValue("@IsActive", request.IsActive);

        using var reader = await command.ExecuteReaderAsync();
        if (await reader.ReadAsync())
        {
            var user = MapUserFromReader(reader);
            _logger.LogInformation("User {UserId} updated successfully", request.UserId);
            return user;
        }

        throw new InvalidOperationException($"Failed to update user {request.UserId}");
    }

    public async Task DeleteUserAsync(Guid userId)
    {
        _logger.LogInformation("Deleting user {UserId}", userId);

        using var connection = await _connectionFactory.CreateConnectionAsync();
        using var command = (SqlCommand)connection.CreateCommand();

        command.CommandText = "dbo.usp_User_Delete";
        command.CommandType = CommandType.StoredProcedure;
        command.Parameters.AddWithValue("@UserId", userId);

        await command.ExecuteNonQueryAsync();
        _logger.LogInformation("User {UserId} deleted successfully", userId);
    }

    public async Task<IEnumerable<SystemRoleDto>> AssignSystemRoleAsync(AssignSystemRoleRequest request)
    {
        _logger.LogInformation("Assigning system role {SystemRoleId} to user {UserId}",
            request.SystemRoleId, request.UserId);

        using var connection = await _connectionFactory.CreateConnectionAsync();
        using var command = (SqlCommand)connection.CreateCommand();

        command.CommandText = "dbo.usp_User_AssignSystemRole";
        command.CommandType = CommandType.StoredProcedure;

        command.Parameters.AddWithValue("@UserId", request.UserId);
        command.Parameters.AddWithValue("@SystemRoleId", request.SystemRoleId);

        var roles = new List<SystemRoleDto>();

        using var reader = await command.ExecuteReaderAsync();
        while (await reader.ReadAsync())
        {
            roles.Add(MapSystemRoleFromReader(reader));
        }

        _logger.LogInformation("System role assigned successfully to user {UserId}", request.UserId);
        return roles;
    }

    public async Task RemoveSystemRoleAsync(RemoveSystemRoleRequest request)
    {
        _logger.LogInformation("Removing system role {SystemRoleId} from user {UserId}",
            request.SystemRoleId, request.UserId);

        using var connection = await _connectionFactory.CreateConnectionAsync();
        using var command = (SqlCommand)connection.CreateCommand();

        command.CommandText = "dbo.usp_User_RemoveSystemRole";
        command.CommandType = CommandType.StoredProcedure;

        command.Parameters.AddWithValue("@UserId", request.UserId);
        command.Parameters.AddWithValue("@SystemRoleId", request.SystemRoleId);

        await command.ExecuteNonQueryAsync();
        _logger.LogInformation("System role removed successfully from user {UserId}", request.UserId);
    }

    public async Task<IEnumerable<SystemRoleDto>> GetUserSystemRolesAsync(Guid userId)
    {
        _logger.LogDebug("Fetching system roles for user {UserId}", userId);

        using var connection = await _connectionFactory.CreateConnectionAsync();
        using var command = (SqlCommand)connection.CreateCommand();

        command.CommandText = "dbo.usp_User_GetSystemRoles";
        command.CommandType = CommandType.StoredProcedure;
        command.Parameters.AddWithValue("@UserId", userId);

        var roles = new List<SystemRoleDto>();

        using var reader = await command.ExecuteReaderAsync();
        while (await reader.ReadAsync())
        {
            roles.Add(MapSystemRoleFromReader(reader));
        }

        return roles;
    }

    public async Task<IEnumerable<UserTenantRoleDto>> GetUserTenantRolesAsync(Guid userId)
    {
        _logger.LogDebug("Fetching tenant roles for user {UserId}", userId);

        using var connection = await _connectionFactory.CreateConnectionAsync();
        using var command = (SqlCommand)connection.CreateCommand();

        command.CommandText = "dbo.usp_User_GetTenantRoles";
        command.CommandType = CommandType.StoredProcedure;
        command.Parameters.AddWithValue("@UserId", userId);

        var roles = new List<UserTenantRoleDto>();

        using var reader = await command.ExecuteReaderAsync();
        while (await reader.ReadAsync())
        {
            roles.Add(MapUserTenantRoleFromReader(reader));
        }

        return roles;
    }

    public async Task<IEnumerable<UserTenantRoleDto>> AssignTenantRoleAsync(AssignTenantRoleRequest request)
    {
        _logger.LogInformation("Assigning tenant role {RoleName} to user {UserId} for tenant {TenantId}",
            request.RoleName, request.UserId, request.TenantId);

        using var connection = await _connectionFactory.CreateConnectionAsync();
        using var command = (SqlCommand)connection.CreateCommand();

        command.CommandText = "dbo.usp_User_AssignToTenant";
        command.CommandType = CommandType.StoredProcedure;

        command.Parameters.AddWithValue("@UserId", request.UserId);
        command.Parameters.AddWithValue("@TenantId", request.TenantId);
        command.Parameters.AddWithValue("@RoleName", request.RoleName);

        await command.ExecuteNonQueryAsync();
        _logger.LogInformation("Tenant role assigned successfully to user {UserId}", request.UserId);

        // Return updated tenant roles
        return await GetUserTenantRolesAsync(request.UserId);
    }

    public async Task RemoveTenantRoleAsync(RemoveTenantRoleRequest request)
    {
        _logger.LogInformation("Removing tenant role {UserTenantRoleId} from user {UserId}",
            request.UserTenantRoleId, request.UserId);

        using var connection = await _connectionFactory.CreateConnectionAsync();
        using var command = (SqlCommand)connection.CreateCommand();

        command.CommandText = @"
            UPDATE dbo.UserTenantRoles
            SET IsActive = 0
            WHERE UserTenantRoleId = @UserTenantRoleId AND UserId = @UserId";
        command.CommandType = CommandType.Text;

        command.Parameters.AddWithValue("@UserTenantRoleId", request.UserTenantRoleId);
        command.Parameters.AddWithValue("@UserId", request.UserId);

        await command.ExecuteNonQueryAsync();
        _logger.LogInformation("Tenant role removed successfully from user {UserId}", request.UserId);
    }

    public async Task<IEnumerable<SystemRoleDto>> GetAllSystemRolesAsync()
    {
        _logger.LogDebug("Fetching all system roles");

        using var connection = await _connectionFactory.CreateConnectionAsync();
        using var command = (SqlCommand)connection.CreateCommand();

        command.CommandText = "SELECT SystemRoleId, RoleName, Description, IsActive, CreatedDate FROM dbo.SystemRoles WHERE IsActive = 1 ORDER BY RoleName";
        command.CommandType = CommandType.Text;

        var roles = new List<SystemRoleDto>();

        using var reader = await command.ExecuteReaderAsync();
        while (await reader.ReadAsync())
        {
            roles.Add(MapSystemRoleFromReader(reader));
        }

        return roles;
    }

    // Helper methods to map from SqlDataReader to DTOs
    private UserDto MapUserFromReader(SqlDataReader reader)
    {
        return new UserDto
        {
            UserId = reader.GetGuid(reader.GetOrdinal("UserId")),
            Email = reader.GetString(reader.GetOrdinal("Email")),
            FirstName = reader.GetString(reader.GetOrdinal("FirstName")),
            LastName = reader.GetString(reader.GetOrdinal("LastName")),
            PhoneNumber = reader.IsDBNull(reader.GetOrdinal("PhoneNumber")) ? null : reader.GetString(reader.GetOrdinal("PhoneNumber")),
            EmailConfirmed = reader.GetBoolean(reader.GetOrdinal("EmailConfirmed")),
            MfaEnabled = reader.GetBoolean(reader.GetOrdinal("MfaEnabled")),
            LastLoginDate = reader.IsDBNull(reader.GetOrdinal("LastLoginDate")) ? null : reader.GetDateTime(reader.GetOrdinal("LastLoginDate")),
            IsActive = reader.GetBoolean(reader.GetOrdinal("IsActive")),
            CreatedDate = reader.GetDateTime(reader.GetOrdinal("CreatedDate")),
            ModifiedDate = reader.GetDateTime(reader.GetOrdinal("ModifiedDate"))
        };
    }

    private UserDetailDto MapUserDetailFromReader(SqlDataReader reader)
    {
        var user = MapUserFromReader(reader);
        return new UserDetailDto
        {
            UserId = user.UserId,
            Email = user.Email,
            FirstName = user.FirstName,
            LastName = user.LastName,
            PhoneNumber = user.PhoneNumber,
            EmailConfirmed = user.EmailConfirmed,
            MfaEnabled = user.MfaEnabled,
            LastLoginDate = user.LastLoginDate,
            IsActive = user.IsActive,
            CreatedDate = user.CreatedDate,
            ModifiedDate = user.ModifiedDate,
            SystemRoleCount = reader.GetInt32(reader.GetOrdinal("SystemRoleCount")),
            TenantRoleCount = reader.GetInt32(reader.GetOrdinal("TenantRoleCount"))
        };
    }

    private SystemRoleDto MapSystemRoleFromReader(SqlDataReader reader)
    {
        return new SystemRoleDto
        {
            SystemRoleId = reader.GetGuid(reader.GetOrdinal("SystemRoleId")),
            RoleName = reader.GetString(reader.GetOrdinal("RoleName")),
            Description = reader.IsDBNull(reader.GetOrdinal("Description")) ? null : reader.GetString(reader.GetOrdinal("Description")),
            IsActive = reader.GetBoolean(reader.GetOrdinal("IsActive")),
            CreatedDate = reader.GetDateTime(reader.GetOrdinal("CreatedDate"))
        };
    }

    private UserTenantRoleDto MapUserTenantRoleFromReader(SqlDataReader reader)
    {
        return new UserTenantRoleDto
        {
            UserTenantRoleId = reader.GetGuid(reader.GetOrdinal("UserTenantRoleId")),
            TenantId = reader.GetGuid(reader.GetOrdinal("TenantId")),
            TenantName = reader.GetString(reader.GetOrdinal("TenantName")),
            TenantCode = reader.GetString(reader.GetOrdinal("TenantCode")),
            RoleName = reader.GetString(reader.GetOrdinal("RoleName")),
            IsActive = reader.GetBoolean(reader.GetOrdinal("IsActive")),
            CreatedDate = reader.GetDateTime(reader.GetOrdinal("CreatedDate"))
        };
    }

    public async Task<IEnumerable<TenantSummaryDto>> GetAccessibleTenantsAsync(Guid userId)
    {
        _logger.LogDebug("Fetching accessible tenants for user: {UserId}", userId);

        using var connection = await _connectionFactory.CreateConnectionAsync();
        using var command = (SqlCommand)connection.CreateCommand();

        command.CommandText = "dbo.usp_User_GetAccessibleTenants";
        command.CommandType = CommandType.StoredProcedure;

        command.Parameters.AddWithValue("@UserId", userId);

        var tenants = new List<TenantSummaryDto>();

        using var reader = await command.ExecuteReaderAsync();
        while (await reader.ReadAsync())
        {
            tenants.Add(new TenantSummaryDto
            {
                TenantId = reader.GetGuid(reader.GetOrdinal("TenantId")),
                TenantName = reader.GetString(reader.GetOrdinal("TenantName")),
                TenantCode = reader.GetString(reader.GetOrdinal("TenantCode")),
                UserRole = reader.GetString(reader.GetOrdinal("UserRole")),
                IsActive = reader.GetBoolean(reader.GetOrdinal("IsActive")),
                LastAccessedDate = reader.IsDBNull(reader.GetOrdinal("LastAccessedDate"))
                    ? null
                    : reader.GetDateTime(reader.GetOrdinal("LastAccessedDate")),
                LocationCount = reader.GetInt32(reader.GetOrdinal("LocationCount")),
                ExtinguisherCount = reader.GetInt32(reader.GetOrdinal("ExtinguisherCount"))
            });
        }

        _logger.LogInformation("Found {Count} accessible tenants for user {UserId}", tenants.Count, userId);

        return tenants;
    }

    public async Task<SwitchTenantResponse> SwitchTenantAsync(Guid userId, Guid tenantId)
    {
        _logger.LogDebug("Switching tenant for user {UserId} to tenant {TenantId}", userId, tenantId);

        using var connection = await _connectionFactory.CreateConnectionAsync();
        using var command = (SqlCommand)connection.CreateCommand();

        command.CommandText = "dbo.usp_User_UpdateLastAccessedTenant";
        command.CommandType = CommandType.StoredProcedure;

        command.Parameters.AddWithValue("@UserId", userId);
        command.Parameters.AddWithValue("@TenantId", tenantId);

        using var reader = await command.ExecuteReaderAsync();

        if (!await reader.ReadAsync())
        {
            _logger.LogWarning("User {UserId} does not have access to tenant {TenantId}", userId, tenantId);
            throw new UnauthorizedAccessException("User does not have access to this tenant");
        }

        var tenantInfo = new
        {
            TenantId = reader.GetGuid(reader.GetOrdinal("TenantId")),
            TenantName = reader.GetString(reader.GetOrdinal("TenantName")),
            TenantCode = reader.GetString(reader.GetOrdinal("TenantCode")),
            UserRole = reader.GetString(reader.GetOrdinal("UserRole"))
        };

        // Get user info for token generation
        var user = await GetUserByIdAsync(userId);
        if (user == null)
        {
            _logger.LogError("User {UserId} not found", userId);
            throw new KeyNotFoundException($"User {userId} not found");
        }

        // Create user DTO for token generation
        var userDto = new UserDto
        {
            UserId = user.UserId,
            Email = user.Email,
            FirstName = user.FirstName,
            LastName = user.LastName,
            IsActive = user.IsActive
        };

        // Create role DTOs for token with updated tenant context
        var roles = new List<RoleDto>
        {
            new RoleDto
            {
                RoleName = tenantInfo.UserRole,
                RoleType = "Tenant",
                TenantId = tenantInfo.TenantId,
                IsActive = true
            }
        };

        // Add system roles
        var systemRoles = await GetUserSystemRolesAsync(userId);
        foreach (var systemRole in systemRoles)
        {
            roles.Add(new RoleDto
            {
                RoleName = systemRole.RoleName,
                RoleType = "System",
                IsActive = true
            });
        }

        // Generate new JWT token with updated TenantId claim
        var token = _jwtTokenService.GenerateAccessToken(userDto, roles);
        var tokenExpiry = _jwtTokenService.GetTokenExpiry();

        _logger.LogInformation("User {UserId} switched to tenant {TenantName} ({TenantId})",
            userId, tenantInfo.TenantName, tenantInfo.TenantId);

        return new SwitchTenantResponse
        {
            TenantId = tenantInfo.TenantId,
            TenantName = tenantInfo.TenantName,
            Token = token,
            TokenExpiration = tokenExpiry
        };
    }
}
