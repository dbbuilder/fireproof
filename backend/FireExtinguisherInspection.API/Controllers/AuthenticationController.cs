using System;
using System.Threading.Tasks;
using FireExtinguisherInspection.API.Models.DTOs;
using FireExtinguisherInspection.API.Services;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace FireExtinguisherInspection.API.Controllers
{
    [ApiController]
    [Route("api/[controller]")]
    public class AuthenticationController : ControllerBase
    {
        private readonly IAuthenticationService _authenticationService;
        private readonly IConfiguration _configuration;
        private readonly ILogger<AuthenticationController> _logger;

        public AuthenticationController(
            IAuthenticationService authenticationService,
            IConfiguration configuration,
            ILogger<AuthenticationController> logger)
        {
            _authenticationService = authenticationService;
            _configuration = configuration;
            _logger = logger;
        }

        /// <summary>
        /// Register a new user
        /// </summary>
        /// <param name="request">Registration request</param>
        /// <returns>Authentication response with JWT tokens</returns>
        [HttpPost("register")]
        [AllowAnonymous]
        [ProducesResponseType(typeof(AuthenticationResponse), 200)]
        [ProducesResponseType(400)]
        public async Task<ActionResult<AuthenticationResponse>> Register([FromBody] RegisterRequest request)
        {
            try
            {
                var response = await _authenticationService.RegisterAsync(request);
                return Ok(response);
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Registration failed for {Email}", request.Email);
                return BadRequest(new { message = ex.Message });
            }
        }

        /// <summary>
        /// Login with email and password
        /// </summary>
        /// <param name="request">Login request</param>
        /// <returns>Authentication response with JWT tokens</returns>
        [HttpPost("login")]
        [AllowAnonymous]
        [ProducesResponseType(typeof(AuthenticationResponse), 200)]
        [ProducesResponseType(401)]
        public async Task<ActionResult<AuthenticationResponse>> Login([FromBody] LoginRequest request)
        {
            try
            {
                var response = await _authenticationService.LoginAsync(request);
                return Ok(response);
            }
            catch (UnauthorizedAccessException ex)
            {
                _logger.LogWarning("Login failed for {Email}: {Message}", request.Email, ex.Message);
                return Unauthorized(new { message = "Invalid email or password" });
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Login error for {Email}", request.Email);
                return StatusCode(500, new { message = "An error occurred during login" });
            }
        }

        /// <summary>
        /// Development login (NO PASSWORD CHECK)
        /// WARNING: This endpoint should be disabled in production!
        /// </summary>
        /// <param name="request">Dev login request</param>
        /// <returns>Authentication response with JWT tokens</returns>
        [HttpPost("dev-login")]
        [AllowAnonymous]
        [ProducesResponseType(typeof(AuthenticationResponse), 200)]
        [ProducesResponseType(401)]
        [ProducesResponseType(403)]
        public async Task<ActionResult<AuthenticationResponse>> DevLogin([FromBody] DevLoginRequest request)
        {
            // Check if dev mode is enabled
            var devModeEnabled = _configuration.GetValue<bool>("Authentication:DevModeEnabled", false);

            if (!devModeEnabled)
            {
                _logger.LogWarning("Dev login attempt while dev mode is disabled");
                return Forbid();
            }

            try
            {
                var response = await _authenticationService.DevLoginAsync(request);
                return Ok(response);
            }
            catch (UnauthorizedAccessException ex)
            {
                _logger.LogWarning("Dev login failed for {Email}: {Message}", request.Email, ex.Message);
                return Unauthorized(new { message = "User not found" });
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Dev login error for {Email}", request.Email);
                return StatusCode(500, new { message = "An error occurred during dev login" });
            }
        }

        /// <summary>
        /// Refresh access token using refresh token
        /// </summary>
        /// <param name="request">Refresh token request</param>
        /// <returns>New authentication response with JWT tokens</returns>
        [HttpPost("refresh")]
        [AllowAnonymous]
        [ProducesResponseType(typeof(AuthenticationResponse), 200)]
        [ProducesResponseType(401)]
        public async Task<ActionResult<AuthenticationResponse>> RefreshToken([FromBody] RefreshTokenRequest request)
        {
            try
            {
                var response = await _authenticationService.RefreshTokenAsync(request);
                return Ok(response);
            }
            catch (UnauthorizedAccessException ex)
            {
                _logger.LogWarning("Token refresh failed: {Message}", ex.Message);
                return Unauthorized(new { message = "Invalid or expired refresh token" });
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Token refresh error");
                return StatusCode(500, new { message = "An error occurred during token refresh" });
            }
        }

        /// <summary>
        /// Reset user password
        /// </summary>
        /// <param name="request">Password reset request</param>
        /// <returns>Success status</returns>
        [HttpPost("reset-password")]
        [Authorize]
        [ProducesResponseType(200)]
        [ProducesResponseType(400)]
        [ProducesResponseType(401)]
        public async Task<ActionResult> ResetPassword([FromBody] ResetPasswordRequest request)
        {
            try
            {
                var success = await _authenticationService.ResetPasswordAsync(request);
                if (success)
                    return Ok(new { message = "Password reset successfully" });

                return BadRequest(new { message = "Failed to reset password" });
            }
            catch (UnauthorizedAccessException ex)
            {
                return Unauthorized(new { message = ex.Message });
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Password reset error for user {UserId}", request.UserId);
                return StatusCode(500, new { message = "An error occurred during password reset" });
            }
        }

        /// <summary>
        /// Confirm user email
        /// </summary>
        /// <param name="request">Email confirmation request</param>
        /// <returns>Success status</returns>
        [HttpPost("confirm-email")]
        [AllowAnonymous]
        [ProducesResponseType(200)]
        [ProducesResponseType(400)]
        public async Task<ActionResult> ConfirmEmail([FromBody] ConfirmEmailRequest request)
        {
            try
            {
                var success = await _authenticationService.ConfirmEmailAsync(request);
                if (success)
                    return Ok(new { message = "Email confirmed successfully" });

                return BadRequest(new { message = "Failed to confirm email" });
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Email confirmation error for user {UserId}", request.UserId);
                return StatusCode(500, new { message = "An error occurred during email confirmation" });
            }
        }

        /// <summary>
        /// Get current user profile
        /// </summary>
        /// <returns>User DTO</returns>
        [HttpGet("me")]
        [Authorize]
        [ProducesResponseType(typeof(UserDto), 200)]
        [ProducesResponseType(401)]
        public async Task<ActionResult<UserDto>> GetCurrentUser()
        {
            try
            {
                var userIdClaim = User.FindFirst(System.Security.Claims.ClaimTypes.NameIdentifier)?.Value;
                if (string.IsNullOrEmpty(userIdClaim) || !Guid.TryParse(userIdClaim, out var userId))
                    return Unauthorized();

                var user = await _authenticationService.GetUserByIdAsync(userId);
                if (user == null)
                    return NotFound();

                return Ok(user);
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error getting current user");
                return StatusCode(500, new { message = "An error occurred while fetching user profile" });
            }
        }

        /// <summary>
        /// Get user roles
        /// </summary>
        /// <returns>List of roles</returns>
        [HttpGet("me/roles")]
        [Authorize]
        [ProducesResponseType(typeof(List<RoleDto>), 200)]
        [ProducesResponseType(401)]
        public async Task<ActionResult<List<RoleDto>>> GetCurrentUserRoles()
        {
            try
            {
                var userIdClaim = User.FindFirst(System.Security.Claims.ClaimTypes.NameIdentifier)?.Value;
                if (string.IsNullOrEmpty(userIdClaim) || !Guid.TryParse(userIdClaim, out var userId))
                    return Unauthorized();

                var roles = await _authenticationService.GetUserRolesAsync(userId);
                return Ok(roles);
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error getting current user roles");
                return StatusCode(500, new { message = "An error occurred while fetching user roles" });
            }
        }

        /// <summary>
        /// Assign user to tenant (admin only)
        /// </summary>
        /// <param name="request">Assignment request</param>
        /// <returns>Success status</returns>
        [HttpPost("assign-tenant")]
        [Authorize(Roles = "SystemAdmin,TenantAdmin")]
        [ProducesResponseType(200)]
        [ProducesResponseType(400)]
        [ProducesResponseType(401)]
        [ProducesResponseType(403)]
        public async Task<ActionResult> AssignUserToTenant([FromBody] AssignUserToTenantRequest request)
        {
            try
            {
                var success = await _authenticationService.AssignUserToTenantAsync(request);
                if (success)
                    return Ok(new { message = "User assigned to tenant successfully" });

                return BadRequest(new { message = "Failed to assign user to tenant" });
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error assigning user {UserId} to tenant {TenantId}",
                    request.UserId, request.TenantId);
                return StatusCode(500, new { message = "An error occurred during tenant assignment" });
            }
        }

        /// <summary>
        /// Test database connection (diagnostic endpoint)
        /// </summary>
        /// <returns>Connection test result</returns>
        [HttpGet("test-db")]
        [AllowAnonymous]
        [ProducesResponseType(typeof(object), 200)]
        [ProducesResponseType(500)]
        public async Task<ActionResult> TestDatabase()
        {
            try
            {
                var connString = _configuration.GetConnectionString("DefaultConnection");
                using var connection = new Microsoft.Data.SqlClient.SqlConnection(connString);
                await connection.OpenAsync();

                using var command = connection.CreateCommand();
                command.CommandText = "SELECT DB_NAME() AS [Database], SUSER_NAME() AS [User], @@VERSION AS [Version]";
                using var reader = await command.ExecuteReaderAsync();

                if (await reader.ReadAsync())
                {
                    return Ok(new
                    {
                        success = true,
                        database = reader["Database"].ToString(),
                        user = reader["User"].ToString(),
                        version = reader["Version"].ToString(),
                        connectionString = connString?.Replace(_configuration["ConnectionStrings:DefaultConnection"]?.Split("Password=")[1]?.Split(";")[0] ?? "", "***")
                    });
                }

                return Ok(new { success = true, message = "Connected but no data returned" });
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Database connection test failed");
                return StatusCode(500, new
                {
                    success = false,
                    error = ex.Message,
                    innerError = ex.InnerException?.Message,
                    stackTrace = ex.StackTrace
                });
            }
        }
    }
}
