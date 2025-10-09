using System;
using System.Collections.Generic;
using System.Data;
using System.Threading.Tasks;
using Dapper;
using FireExtinguisherInspection.API.Data;
using FireExtinguisherInspection.API.Models.DTOs;
using Microsoft.Data.SqlClient;

namespace FireExtinguisherInspection.API.Services
{
    /// <summary>
    /// Authentication service implementation
    /// </summary>
    public class AuthenticationService : IAuthenticationService
    {
        private readonly IDbConnectionFactory _connectionFactory;
        private readonly IPasswordHasher _passwordHasher;
        private readonly IJwtTokenService _jwtTokenService;
        private readonly ILogger<AuthenticationService> _logger;

        public AuthenticationService(
            IDbConnectionFactory connectionFactory,
            IPasswordHasher passwordHasher,
            IJwtTokenService jwtTokenService,
            ILogger<AuthenticationService> logger)
        {
            _connectionFactory = connectionFactory;
            _passwordHasher = passwordHasher;
            _jwtTokenService = jwtTokenService;
            _logger = logger;
        }

        /// <summary>
        /// Register new user
        /// </summary>
        public async Task<AuthenticationResponse> RegisterAsync(RegisterRequest request)
        {
            // Hash password
            var passwordHash = _passwordHasher.HashPassword(request.Password, out var salt);

            // Create user in database
            using var connection = _connectionFactory.CreateCommonConnection();
            var parameters = new DynamicParameters();
            parameters.Add("@Email", request.Email);
            parameters.Add("@FirstName", request.FirstName);
            parameters.Add("@LastName", request.LastName);
            parameters.Add("@PasswordHash", passwordHash);
            parameters.Add("@PasswordSalt", salt);
            parameters.Add("@PhoneNumber", request.PhoneNumber);
            parameters.Add("@UserId", dbType: DbType.Guid, direction: ParameterDirection.Output);

            var userResult = await connection.QueryAsync<UserDto>(
                "dbo.usp_User_Register",
                parameters,
                commandType: CommandType.StoredProcedure
            );

            var user = userResult.FirstOrDefault()
                ?? throw new InvalidOperationException("Failed to create user");

            // Assign to tenant if provided
            if (request.TenantId.HasValue)
            {
                await AssignUserToTenantAsync(new AssignUserToTenantRequest
                {
                    UserId = user.UserId,
                    TenantId = request.TenantId.Value,
                    RoleName = request.TenantRole ?? "Viewer"
                });
            }

            // Get roles and generate tokens
            var roles = await GetUserRolesAsync(user.UserId);
            var accessToken = _jwtTokenService.GenerateAccessToken(user, roles);
            var refreshToken = _jwtTokenService.GenerateRefreshToken();

            // Store refresh token
            await UpdateRefreshTokenAsync(user.UserId, refreshToken);

            _logger.LogInformation("User registered successfully: {Email}", user.Email);

            return new AuthenticationResponse
            {
                AccessToken = accessToken,
                RefreshToken = refreshToken,
                ExpiresAt = _jwtTokenService.GetTokenExpiry(),
                User = user,
                Roles = roles
            };
        }

        /// <summary>
        /// Login with email and password
        /// </summary>
        public async Task<AuthenticationResponse> LoginAsync(LoginRequest request)
        {
            using var connection = _connectionFactory.CreateCommonConnection();

            // Get user by email
            var userWithPassword = await connection.QueryFirstOrDefaultAsync<UserWithPasswordDto>(
                "dbo.usp_User_GetByEmail",
                new { Email = request.Email },
                commandType: CommandType.StoredProcedure
            );

            if (userWithPassword == null)
                throw new UnauthorizedAccessException("Invalid email or password");

            // Verify password
            if (!_passwordHasher.VerifyPassword(request.Password, userWithPassword.PasswordHash!, userWithPassword.PasswordSalt!))
                throw new UnauthorizedAccessException("Invalid email or password");

            // Update last login
            await UpdateLastLoginAsync(userWithPassword.UserId);

            // Get roles and generate tokens
            var roles = await GetUserRolesAsync(userWithPassword.UserId);
            var accessToken = _jwtTokenService.GenerateAccessToken(userWithPassword, roles);
            var refreshToken = _jwtTokenService.GenerateRefreshToken();

            // Store refresh token
            await UpdateRefreshTokenAsync(userWithPassword.UserId, refreshToken);

            _logger.LogInformation("User logged in: {Email}", request.Email);

            // Map to UserDto (exclude password fields)
            var user = MapToUserDto(userWithPassword);

            return new AuthenticationResponse
            {
                AccessToken = accessToken,
                RefreshToken = refreshToken,
                ExpiresAt = _jwtTokenService.GetTokenExpiry(),
                User = user,
                Roles = roles
            };
        }

        /// <summary>
        /// Development login (NO PASSWORD CHECK)
        /// </summary>
        public async Task<AuthenticationResponse> DevLoginAsync(DevLoginRequest request)
        {
            _logger.LogWarning("DEV LOGIN USED - This should NEVER happen in production! Email: {Email}", request.Email);

            using var connection = _connectionFactory.CreateCommonConnection();

            // Get user WITHOUT password verification
            var user = await connection.QueryFirstOrDefaultAsync<UserDto>(
                "dbo.usp_User_DevLogin",
                new { Email = request.Email },
                commandType: CommandType.StoredProcedure
            );

            if (user == null)
                throw new UnauthorizedAccessException("User not found");

            // Get roles and generate tokens
            var roles = await GetUserRolesAsync(user.UserId);
            var accessToken = _jwtTokenService.GenerateAccessToken(user, roles);
            var refreshToken = _jwtTokenService.GenerateRefreshToken();

            // Store refresh token
            await UpdateRefreshTokenAsync(user.UserId, refreshToken);

            return new AuthenticationResponse
            {
                AccessToken = accessToken,
                RefreshToken = refreshToken,
                ExpiresAt = _jwtTokenService.GetTokenExpiry(),
                User = user,
                Roles = roles
            };
        }

        /// <summary>
        /// Refresh access token
        /// </summary>
        public async Task<AuthenticationResponse> RefreshTokenAsync(RefreshTokenRequest request)
        {
            using var connection = _connectionFactory.CreateCommonConnection();

            // Get user by refresh token
            var user = await connection.QueryFirstOrDefaultAsync<UserDto>(
                "dbo.usp_User_GetByRefreshToken",
                new { RefreshToken = request.RefreshToken },
                commandType: CommandType.StoredProcedure
            );

            if (user == null)
                throw new UnauthorizedAccessException("Invalid or expired refresh token");

            // Generate new tokens
            var roles = await GetUserRolesAsync(user.UserId);
            var accessToken = _jwtTokenService.GenerateAccessToken(user, roles);
            var refreshToken = _jwtTokenService.GenerateRefreshToken();

            // Store new refresh token
            await UpdateRefreshTokenAsync(user.UserId, refreshToken);

            _logger.LogInformation("Token refreshed for user: {Email}", user.Email);

            return new AuthenticationResponse
            {
                AccessToken = accessToken,
                RefreshToken = refreshToken,
                ExpiresAt = _jwtTokenService.GetTokenExpiry(),
                User = user,
                Roles = roles
            };
        }

        /// <summary>
        /// Reset password
        /// </summary>
        public async Task<bool> ResetPasswordAsync(ResetPasswordRequest request)
        {
            using var connection = _connectionFactory.CreateCommonConnection();

            // Get user
            var userWithPassword = await connection.QueryFirstOrDefaultAsync<UserWithPasswordDto>(
                "dbo.usp_User_GetById",
                new { UserId = request.UserId },
                commandType: CommandType.StoredProcedure
            );

            if (userWithPassword == null)
                return false;

            // Verify current password
            if (!_passwordHasher.VerifyPassword(request.CurrentPassword, userWithPassword.PasswordHash!, userWithPassword.PasswordSalt!))
                throw new UnauthorizedAccessException("Current password is incorrect");

            // Hash new password
            var newPasswordHash = _passwordHasher.HashPassword(request.NewPassword, out var newSalt);

            // Update password
            await connection.ExecuteAsync(
                "dbo.usp_User_UpdatePassword",
                new
                {
                    UserId = request.UserId,
                    PasswordHash = newPasswordHash,
                    PasswordSalt = newSalt
                },
                commandType: CommandType.StoredProcedure
            );

            _logger.LogInformation("Password reset for user: {UserId}", request.UserId);
            return true;
        }

        /// <summary>
        /// Confirm email
        /// </summary>
        public async Task<bool> ConfirmEmailAsync(ConfirmEmailRequest request)
        {
            using var connection = _connectionFactory.CreateCommonConnection();

            await connection.ExecuteAsync(
                "dbo.usp_User_ConfirmEmail",
                new { UserId = request.UserId },
                commandType: CommandType.StoredProcedure
            );

            _logger.LogInformation("Email confirmed for user: {UserId}", request.UserId);
            return true;
        }

        /// <summary>
        /// Get user by ID
        /// </summary>
        public async Task<UserDto?> GetUserByIdAsync(Guid userId)
        {
            using var connection = _connectionFactory.CreateCommonConnection();

            return await connection.QueryFirstOrDefaultAsync<UserDto>(
                "dbo.usp_User_GetById",
                new { UserId = userId },
                commandType: CommandType.StoredProcedure
            );
        }

        /// <summary>
        /// Get user roles
        /// </summary>
        public async Task<List<RoleDto>> GetUserRolesAsync(Guid userId)
        {
            using var connection = _connectionFactory.CreateCommonConnection();

            var roles = await connection.QueryAsync<RoleDto>(
                "dbo.usp_User_GetRoles",
                new { UserId = userId },
                commandType: CommandType.StoredProcedure
            );

            return roles.AsList();
        }

        /// <summary>
        /// Assign user to tenant
        /// </summary>
        public async Task<bool> AssignUserToTenantAsync(AssignUserToTenantRequest request)
        {
            using var connection = _connectionFactory.CreateCommonConnection();

            await connection.ExecuteAsync(
                "dbo.usp_User_AssignToTenant",
                new
                {
                    UserId = request.UserId,
                    TenantId = request.TenantId,
                    RoleName = request.RoleName
                },
                commandType: CommandType.StoredProcedure
            );

            _logger.LogInformation("User {UserId} assigned to tenant {TenantId} as {RoleName}",
                request.UserId, request.TenantId, request.RoleName);

            return true;
        }

        /// <summary>
        /// Update refresh token in database
        /// </summary>
        private async Task UpdateRefreshTokenAsync(Guid userId, string refreshToken)
        {
            using var connection = _connectionFactory.CreateCommonConnection();

            var expiryDate = DateTime.UtcNow.AddDays(7); // 7 days

            await connection.ExecuteAsync(
                "dbo.usp_User_UpdateRefreshToken",
                new
                {
                    UserId = userId,
                    RefreshToken = refreshToken,
                    RefreshTokenExpiryDate = expiryDate
                },
                commandType: CommandType.StoredProcedure
            );
        }

        /// <summary>
        /// Update last login date
        /// </summary>
        private async Task UpdateLastLoginAsync(Guid userId)
        {
            using var connection = _connectionFactory.CreateCommonConnection();

            await connection.ExecuteAsync(
                "dbo.usp_User_UpdateLastLogin",
                new { UserId = userId },
                commandType: CommandType.StoredProcedure
            );
        }

        /// <summary>
        /// Map UserWithPasswordDto to UserDto (exclude password fields)
        /// </summary>
        private UserDto MapToUserDto(UserWithPasswordDto userWithPassword)
        {
            return new UserDto
            {
                UserId = userWithPassword.UserId,
                Email = userWithPassword.Email,
                FirstName = userWithPassword.FirstName,
                LastName = userWithPassword.LastName,
                PhoneNumber = userWithPassword.PhoneNumber,
                EmailConfirmed = userWithPassword.EmailConfirmed,
                MfaEnabled = userWithPassword.MfaEnabled,
                LastLoginDate = userWithPassword.LastLoginDate,
                IsActive = userWithPassword.IsActive,
                CreatedDate = userWithPassword.CreatedDate,
                ModifiedDate = userWithPassword.ModifiedDate
            };
        }
    }
}
