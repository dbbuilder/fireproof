using System;
using System.Collections.Generic;

namespace FireExtinguisherInspection.API.Models.DTOs
{
    /// <summary>
    /// User detail DTO with role information
    /// </summary>
    public class UserDetailDto : UserDto
    {
        public int SystemRoleCount { get; set; }
        public int TenantRoleCount { get; set; }
        public List<SystemRoleDto> SystemRoles { get; set; } = new();
        public List<UserTenantRoleDto> TenantRoles { get; set; } = new();
    }

    /// <summary>
    /// System role DTO
    /// </summary>
    public class SystemRoleDto
    {
        public Guid SystemRoleId { get; set; }
        public required string RoleName { get; set; }
        public string? Description { get; set; }
        public bool IsActive { get; set; }
        public DateTime CreatedDate { get; set; }
    }

    /// <summary>
    /// User tenant role DTO
    /// </summary>
    public class UserTenantRoleDto
    {
        public Guid UserTenantRoleId { get; set; }
        public Guid TenantId { get; set; }
        public required string TenantName { get; set; }
        public required string TenantCode { get; set; }
        public required string RoleName { get; set; }
        public bool IsActive { get; set; }
        public DateTime CreatedDate { get; set; }
    }

    /// <summary>
    /// Update user request
    /// </summary>
    public class UpdateUserRequest
    {
        public Guid UserId { get; set; }
        public required string FirstName { get; set; }
        public required string LastName { get; set; }
        public string? PhoneNumber { get; set; }
        public bool EmailConfirmed { get; set; }
        public bool MfaEnabled { get; set; }
        public bool IsActive { get; set; }
    }

    /// <summary>
    /// Assign system role request
    /// </summary>
    public class AssignSystemRoleRequest
    {
        public Guid UserId { get; set; }
        public Guid SystemRoleId { get; set; }
    }

    /// <summary>
    /// Remove system role request
    /// </summary>
    public class RemoveSystemRoleRequest
    {
        public Guid UserId { get; set; }
        public Guid SystemRoleId { get; set; }
    }

    /// <summary>
    /// Assign tenant role request (enhanced version of AssignUserToTenantRequest)
    /// </summary>
    public class AssignTenantRoleRequest
    {
        public Guid UserId { get; set; }
        public Guid TenantId { get; set; }
        public required string RoleName { get; set; } // TenantAdmin, LocationManager, Inspector, Viewer
    }

    /// <summary>
    /// Remove tenant role request
    /// </summary>
    public class RemoveTenantRoleRequest
    {
        public Guid UserId { get; set; }
        public Guid UserTenantRoleId { get; set; }
    }

    /// <summary>
    /// User list response with pagination
    /// </summary>
    public class UserListResponse
    {
        public List<UserDetailDto> Users { get; set; } = new();
        public int TotalCount { get; set; }
        public int PageNumber { get; set; }
        public int PageSize { get; set; }
        public int TotalPages => (int)Math.Ceiling((double)TotalCount / PageSize);
    }

    /// <summary>
    /// Get users request with filtering and pagination
    /// </summary>
    public class GetUsersRequest
    {
        public string? SearchTerm { get; set; }
        public bool? IsActive { get; set; }
        public int PageNumber { get; set; } = 1;
        public int PageSize { get; set; } = 50;
    }
}
