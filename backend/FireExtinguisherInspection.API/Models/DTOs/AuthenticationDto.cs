using System;

namespace FireExtinguisherInspection.API.Models.DTOs
{
    /// <summary>
    /// User registration request
    /// </summary>
    public class RegisterRequest
    {
        public required string Email { get; set; }
        public required string Password { get; set; }
        public required string FirstName { get; set; }
        public required string LastName { get; set; }
        public string? PhoneNumber { get; set; }
        public Guid? TenantId { get; set; } // Optional: auto-assign to tenant during registration
        public string? TenantRole { get; set; } = "Viewer"; // Default role: Viewer
    }

    /// <summary>
    /// User login request
    /// </summary>
    public class LoginRequest
    {
        public required string Email { get; set; }
        public required string Password { get; set; }
    }

    /// <summary>
    /// Development login request (NO PASSWORD)
    /// </summary>
    public class DevLoginRequest
    {
        public required string Email { get; set; }
    }

    /// <summary>
    /// JWT token refresh request
    /// </summary>
    public class RefreshTokenRequest
    {
        public required string RefreshToken { get; set; }
    }

    /// <summary>
    /// Authentication response with JWT tokens
    /// </summary>
    public class AuthenticationResponse
    {
        public required string AccessToken { get; set; }
        public required string RefreshToken { get; set; }
        public DateTime ExpiresAt { get; set; }
        public required UserDto User { get; set; }
        public List<RoleDto> Roles { get; set; } = new();
    }

    /// <summary>
    /// User DTO (without sensitive data)
    /// </summary>
    public class UserDto
    {
        public Guid UserId { get; set; }
        public required string Email { get; set; }
        public required string FirstName { get; set; }
        public required string LastName { get; set; }
        public string? PhoneNumber { get; set; }
        public bool EmailConfirmed { get; set; }
        public bool MfaEnabled { get; set; }
        public DateTime? LastLoginDate { get; set; }
        public bool IsActive { get; set; }
        public DateTime CreatedDate { get; set; }
        public DateTime ModifiedDate { get; set; }
    }

    /// <summary>
    /// User with password fields (internal use only)
    /// </summary>
    public class UserWithPasswordDto : UserDto
    {
        public string? PasswordHash { get; set; }
        public string? PasswordSalt { get; set; }
        public string? RefreshToken { get; set; }
        public DateTime? RefreshTokenExpiryDate { get; set; }
    }

    /// <summary>
    /// Role DTO (system or tenant role)
    /// </summary>
    public class RoleDto
    {
        public required string RoleType { get; set; } // "System" or "Tenant"
        public Guid? TenantId { get; set; }
        public required string RoleName { get; set; }
        public string? Description { get; set; }
        public bool IsActive { get; set; }
    }

    /// <summary>
    /// Password reset request
    /// </summary>
    public class ResetPasswordRequest
    {
        public Guid UserId { get; set; }
        public required string CurrentPassword { get; set; }
        public required string NewPassword { get; set; }
    }

    /// <summary>
    /// Email confirmation request
    /// </summary>
    public class ConfirmEmailRequest
    {
        public Guid UserId { get; set; }
        public required string ConfirmationToken { get; set; }
    }

    /// <summary>
    /// Assign user to tenant request
    /// </summary>
    public class AssignUserToTenantRequest
    {
        public Guid UserId { get; set; }
        public Guid TenantId { get; set; }
        public required string RoleName { get; set; } // TenantAdmin, LocationManager, Inspector, Viewer
    }

    /// <summary>
    /// JWT token claims
    /// </summary>
    public class TokenClaims
    {
        public Guid UserId { get; set; }
        public required string Email { get; set; }
        public required string FirstName { get; set; }
        public required string LastName { get; set; }
        public List<string> SystemRoles { get; set; } = new();
        public Dictionary<Guid, List<string>> TenantRoles { get; set; } = new(); // TenantId -> Roles[]
    }
}
