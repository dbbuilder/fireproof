using FireExtinguisherInspection.API.Controllers;
using FireExtinguisherInspection.API.Models.DTOs;
using FireExtinguisherInspection.API.Services;
using FluentAssertions;
using Microsoft.AspNetCore.Mvc;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.Logging;
using Moq;
using Xunit;

namespace FireExtinguisherInspection.Tests.Controllers
{
    public class AuthenticationControllerTests
    {
        private readonly Mock<IAuthenticationService> _mockAuthService;
        private readonly Mock<IConfiguration> _mockConfiguration;
        private readonly Mock<ILogger<AuthenticationController>> _mockLogger;
        private readonly AuthenticationController _controller;

        public AuthenticationControllerTests()
        {
            _mockAuthService = new Mock<IAuthenticationService>();
            _mockConfiguration = new Mock<IConfiguration>();
            _mockLogger = new Mock<ILogger<AuthenticationController>>();

            _controller = new AuthenticationController(
                _mockAuthService.Object,
                _mockConfiguration.Object,
                _mockLogger.Object
            );
        }

        [Fact]
        public async Task Register_WithValidRequest_ReturnsOkWithTokens()
        {
            // Arrange
            var request = new RegisterRequest
            {
                Email = "newuser@example.com",
                Password = "SecurePassword123!",
                FirstName = "New",
                LastName = "User"
            };

            var expectedResponse = new AuthenticationResponse
            {
                AccessToken = "valid.access.token",
                RefreshToken = "valid.refresh.token",
                ExpiresAt = DateTime.UtcNow.AddHours(1),
                User = new UserDto
                {
                    UserId = Guid.NewGuid(),
                    Email = request.Email,
                    FirstName = request.FirstName,
                    LastName = request.LastName,
                    EmailConfirmed = false,
                    MfaEnabled = false,
                    IsActive = true,
                    CreatedDate = DateTime.UtcNow,
                    ModifiedDate = DateTime.UtcNow
                },
                Roles = new List<RoleDto>()
            };

            _mockAuthService
                .Setup(x => x.RegisterAsync(request))
                .ReturnsAsync(expectedResponse);

            // Act
            var result = await _controller.Register(request);

            // Assert
            result.Result.Should().BeOfType<OkObjectResult>();
            var okResult = result.Result as OkObjectResult;
            okResult!.Value.Should().BeEquivalentTo(expectedResponse);
        }

        [Fact]
        public async Task Register_WhenServiceThrowsException_ReturnsBadRequest()
        {
            // Arrange
            var request = new RegisterRequest
            {
                Email = "existing@example.com",
                Password = "Password123!",
                FirstName = "Test",
                LastName = "User"
            };

            _mockAuthService
                .Setup(x => x.RegisterAsync(request))
                .ThrowsAsync(new Exception("User already exists"));

            // Act
            var result = await _controller.Register(request);

            // Assert
            result.Result.Should().BeOfType<BadRequestObjectResult>();
        }

        [Fact]
        public async Task Login_WithValidCredentials_ReturnsOkWithTokens()
        {
            // Arrange
            var request = new LoginRequest
            {
                Email = "user@example.com",
                Password = "CorrectPassword123!"
            };

            var expectedResponse = new AuthenticationResponse
            {
                AccessToken = "valid.access.token",
                RefreshToken = "valid.refresh.token",
                ExpiresAt = DateTime.UtcNow.AddHours(1),
                User = new UserDto
                {
                    UserId = Guid.NewGuid(),
                    Email = request.Email,
                    FirstName = "Test",
                    LastName = "User",
                    EmailConfirmed = true,
                    MfaEnabled = false,
                    IsActive = true,
                    CreatedDate = DateTime.UtcNow,
                    ModifiedDate = DateTime.UtcNow
                },
                Roles = new List<RoleDto>()
            };

            _mockAuthService
                .Setup(x => x.LoginAsync(request))
                .ReturnsAsync(expectedResponse);

            // Act
            var result = await _controller.Login(request);

            // Assert
            result.Result.Should().BeOfType<OkObjectResult>();
            var okResult = result.Result as OkObjectResult;
            okResult!.Value.Should().BeEquivalentTo(expectedResponse);
        }

        [Fact]
        public async Task Login_WithInvalidCredentials_ReturnsUnauthorized()
        {
            // Arrange
            var request = new LoginRequest
            {
                Email = "user@example.com",
                Password = "WrongPassword123!"
            };

            _mockAuthService
                .Setup(x => x.LoginAsync(request))
                .ThrowsAsync(new UnauthorizedAccessException("Invalid credentials"));

            // Act
            var result = await _controller.Login(request);

            // Assert
            result.Result.Should().BeOfType<UnauthorizedObjectResult>();
        }

        [Fact]
        public async Task DevLogin_WhenDevModeEnabled_ReturnsOkWithTokens()
        {
            // Arrange
            var request = new DevLoginRequest
            {
                Email = "dev@fireproof.local"
            };

            var expectedResponse = new AuthenticationResponse
            {
                AccessToken = "dev.access.token",
                RefreshToken = "dev.refresh.token",
                ExpiresAt = DateTime.UtcNow.AddHours(1),
                User = new UserDto
                {
                    UserId = Guid.NewGuid(),
                    Email = request.Email,
                    FirstName = "Dev",
                    LastName = "User",
                    EmailConfirmed = true,
                    MfaEnabled = false,
                    IsActive = true,
                    CreatedDate = DateTime.UtcNow,
                    ModifiedDate = DateTime.UtcNow
                },
                Roles = new List<RoleDto>()
            };

            // Mock configuration section for GetValue extension method
            var mockSection = new Mock<IConfigurationSection>();
            mockSection.Setup(x => x.Value).Returns("true");
            _mockConfiguration
                .Setup(x => x.GetSection("Authentication:DevModeEnabled"))
                .Returns(mockSection.Object);

            _mockAuthService
                .Setup(x => x.DevLoginAsync(request))
                .ReturnsAsync(expectedResponse);

            // Act
            var result = await _controller.DevLogin(request);

            // Assert
            result.Result.Should().BeOfType<OkObjectResult>();
            var okResult = result.Result as OkObjectResult;
            okResult!.Value.Should().BeEquivalentTo(expectedResponse);
        }

        [Fact]
        public async Task DevLogin_WhenDevModeDisabled_ReturnsForbidden()
        {
            // Arrange
            var request = new DevLoginRequest
            {
                Email = "dev@fireproof.local"
            };

            // Mock configuration section for GetValue extension method
            var mockSection = new Mock<IConfigurationSection>();
            mockSection.Setup(x => x.Value).Returns("false");
            _mockConfiguration
                .Setup(x => x.GetSection("Authentication:DevModeEnabled"))
                .Returns(mockSection.Object);

            // Act
            var result = await _controller.DevLogin(request);

            // Assert
            result.Result.Should().BeOfType<ForbidResult>();
        }

        [Fact]
        public async Task RefreshToken_WithValidToken_ReturnsOkWithNewTokens()
        {
            // Arrange
            var request = new RefreshTokenRequest
            {
                RefreshToken = "valid.refresh.token"
            };

            var expectedResponse = new AuthenticationResponse
            {
                AccessToken = "new.access.token",
                RefreshToken = "new.refresh.token",
                ExpiresAt = DateTime.UtcNow.AddHours(1),
                User = new UserDto
                {
                    UserId = Guid.NewGuid(),
                    Email = "user@example.com",
                    FirstName = "Test",
                    LastName = "User",
                    EmailConfirmed = true,
                    MfaEnabled = false,
                    IsActive = true,
                    CreatedDate = DateTime.UtcNow,
                    ModifiedDate = DateTime.UtcNow
                },
                Roles = new List<RoleDto>()
            };

            _mockAuthService
                .Setup(x => x.RefreshTokenAsync(request))
                .ReturnsAsync(expectedResponse);

            // Act
            var result = await _controller.RefreshToken(request);

            // Assert
            result.Result.Should().BeOfType<OkObjectResult>();
            var okResult = result.Result as OkObjectResult;
            okResult!.Value.Should().BeEquivalentTo(expectedResponse);
        }

        [Fact]
        public async Task RefreshToken_WithInvalidToken_ReturnsUnauthorized()
        {
            // Arrange
            var request = new RefreshTokenRequest
            {
                RefreshToken = "invalid.refresh.token"
            };

            _mockAuthService
                .Setup(x => x.RefreshTokenAsync(request))
                .ThrowsAsync(new UnauthorizedAccessException("Invalid refresh token"));

            // Act
            var result = await _controller.RefreshToken(request);

            // Assert
            result.Result.Should().BeOfType<UnauthorizedObjectResult>();
        }

        [Fact]
        public async Task ResetPassword_WithValidRequest_ReturnsOk()
        {
            // Arrange
            var request = new ResetPasswordRequest
            {
                UserId = Guid.NewGuid(),
                CurrentPassword = "OldPassword123!",
                NewPassword = "NewPassword123!"
            };

            _mockAuthService
                .Setup(x => x.ResetPasswordAsync(request))
                .ReturnsAsync(true);

            // Act
            var result = await _controller.ResetPassword(request);

            // Assert
            result.Should().BeOfType<OkObjectResult>();
        }

        [Fact]
        public async Task ResetPassword_WithIncorrectCurrentPassword_ReturnsUnauthorized()
        {
            // Arrange
            var request = new ResetPasswordRequest
            {
                UserId = Guid.NewGuid(),
                CurrentPassword = "WrongPassword123!",
                NewPassword = "NewPassword123!"
            };

            _mockAuthService
                .Setup(x => x.ResetPasswordAsync(request))
                .ThrowsAsync(new UnauthorizedAccessException("Current password is incorrect"));

            // Act
            var result = await _controller.ResetPassword(request);

            // Assert
            result.Should().BeOfType<UnauthorizedObjectResult>();
        }
    }
}
