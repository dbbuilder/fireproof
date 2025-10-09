using System;
using System.Threading.Tasks;
using FireExtinguisherInspection.API.Models.DTOs;

namespace FireExtinguisherInspection.API.Services
{
    /// <summary>
    /// Authentication service for user registration, login, and token management
    /// </summary>
    public interface IAuthenticationService
    {
        /// <summary>
        /// Register a new user
        /// </summary>
        /// <param name="request">Registration request</param>
        /// <returns>Authentication response with tokens</returns>
        Task<AuthenticationResponse> RegisterAsync(RegisterRequest request);

        /// <summary>
        /// Authenticate user with email and password
        /// </summary>
        /// <param name="request">Login request</param>
        /// <returns>Authentication response with tokens</returns>
        Task<AuthenticationResponse> LoginAsync(LoginRequest request);

        /// <summary>
        /// Development login (NO PASSWORD CHECK)
        /// WARNING: Only use in development!
        /// </summary>
        /// <param name="request">Dev login request</param>
        /// <returns>Authentication response with tokens</returns>
        Task<AuthenticationResponse> DevLoginAsync(DevLoginRequest request);

        /// <summary>
        /// Refresh access token using refresh token
        /// </summary>
        /// <param name="request">Refresh token request</param>
        /// <returns>New authentication response with tokens</returns>
        Task<AuthenticationResponse> RefreshTokenAsync(RefreshTokenRequest request);

        /// <summary>
        /// Reset user password
        /// </summary>
        /// <param name="request">Password reset request</param>
        /// <returns>True if successful</returns>
        Task<bool> ResetPasswordAsync(ResetPasswordRequest request);

        /// <summary>
        /// Confirm user email
        /// </summary>
        /// <param name="request">Email confirmation request</param>
        /// <returns>True if successful</returns>
        Task<bool> ConfirmEmailAsync(ConfirmEmailRequest request);

        /// <summary>
        /// Get user by ID
        /// </summary>
        /// <param name="userId">User ID</param>
        /// <returns>User DTO or null</returns>
        Task<UserDto?> GetUserByIdAsync(Guid userId);

        /// <summary>
        /// Get user roles
        /// </summary>
        /// <param name="userId">User ID</param>
        /// <returns>List of roles</returns>
        Task<List<RoleDto>> GetUserRolesAsync(Guid userId);

        /// <summary>
        /// Assign user to tenant with role
        /// </summary>
        /// <param name="request">Assignment request</param>
        /// <returns>True if successful</returns>
        Task<bool> AssignUserToTenantAsync(AssignUserToTenantRequest request);
    }
}
