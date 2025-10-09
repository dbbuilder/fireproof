using FireExtinguisherInspection.API.Controllers;
using FireExtinguisherInspection.API.Models;
using FireExtinguisherInspection.API.Models.DTOs;
using FireExtinguisherInspection.API.Services;
using FluentAssertions;
using Microsoft.AspNetCore.Mvc;
using Microsoft.Extensions.Logging;
using Moq;

namespace FireExtinguisherInspection.Tests.Controllers;

public class LocationsControllerTests
{
    private readonly Mock<ILocationService> _mockLocationService;
    private readonly Mock<ILogger<LocationsController>> _mockLogger;
    private readonly TenantContext _tenantContext;
    private readonly LocationsController _controller;
    private readonly Guid _testTenantId;

    public LocationsControllerTests()
    {
        _mockLocationService = new Mock<ILocationService>();
        _mockLogger = new Mock<ILogger<LocationsController>>();
        _testTenantId = Guid.NewGuid();
        _tenantContext = new TenantContext
        {
            TenantId = _testTenantId,
            TenantCode = "TEST001",
            DatabaseSchema = $"tenant_{_testTenantId}"
        };
        _controller = new LocationsController(_mockLocationService.Object, _tenantContext, _mockLogger.Object);
    }

    #region CreateLocation Tests

    [Fact]
    public async Task CreateLocation_WithValidRequest_ReturnsCreatedResult()
    {
        // Arrange
        var request = new CreateLocationRequest
        {
            LocationCode = "LOC001",
            LocationName = "Test Location",
            AddressLine1 = "123 Main St",
            City = "Seattle",
            StateProvince = "WA",
            PostalCode = "98101",
            Country = "USA"
        };

        var expectedLocation = new LocationDto
        {
            LocationId = Guid.NewGuid(),
            TenantId = _testTenantId,
            LocationCode = request.LocationCode,
            LocationName = request.LocationName,
            AddressLine1 = request.AddressLine1,
            City = request.City,
            StateProvince = request.StateProvince,
            PostalCode = request.PostalCode,
            Country = request.Country,
            IsActive = true,
            CreatedDate = DateTime.UtcNow,
            ModifiedDate = DateTime.UtcNow
        };

        _mockLocationService.Setup(x => x.CreateLocationAsync(_testTenantId, request))
            .ReturnsAsync(expectedLocation);

        // Act
        var result = await _controller.CreateLocation(request);

        // Assert
        result.Result.Should().BeOfType<CreatedAtActionResult>();
        var createdResult = result.Result as CreatedAtActionResult;
        createdResult!.Value.Should().BeEquivalentTo(expectedLocation);
    }

    [Fact]
    public async Task CreateLocation_WithEmptyTenantId_ReturnsUnauthorized()
    {
        // Arrange
        var emptyTenantContext = new TenantContext { TenantId = Guid.Empty };
        var controller = new LocationsController(_mockLocationService.Object, emptyTenantContext, _mockLogger.Object);

        var request = new CreateLocationRequest
        {
            LocationCode = "LOC001",
            LocationName = "Test Location"
        };

        // Act
        var result = await controller.CreateLocation(request);

        // Assert
        result.Result.Should().BeOfType<UnauthorizedObjectResult>();
    }

    [Fact]
    public async Task CreateLocation_LogsInformation()
    {
        // Arrange
        var request = new CreateLocationRequest
        {
            LocationCode = "LOC001",
            LocationName = "Test Location"
        };

        var location = new LocationDto
        {
            LocationId = Guid.NewGuid(),
            TenantId = _testTenantId,
            LocationCode = request.LocationCode,
            LocationName = request.LocationName,
            IsActive = true,
            CreatedDate = DateTime.UtcNow,
            ModifiedDate = DateTime.UtcNow
        };

        _mockLocationService.Setup(x => x.CreateLocationAsync(_testTenantId, request))
            .ReturnsAsync(location);

        // Act
        await _controller.CreateLocation(request);

        // Assert
        _mockLogger.Verify(
            x => x.Log(
                LogLevel.Information,
                It.IsAny<EventId>(),
                It.Is<It.IsAnyType>((v, t) => v.ToString()!.Contains("Creating location")),
                It.IsAny<Exception>(),
                It.IsAny<Func<It.IsAnyType, Exception?, string>>()),
            Times.Once);
    }

    #endregion

    #region GetAllLocations Tests

    [Fact]
    public async Task GetAllLocations_WithValidTenant_ReturnsOkWithLocations()
    {
        // Arrange
        var locations = new List<LocationDto>
        {
            new LocationDto
            {
                LocationId = Guid.NewGuid(),
                TenantId = _testTenantId,
                LocationCode = "LOC001",
                LocationName = "Location 1",
                IsActive = true,
                CreatedDate = DateTime.UtcNow,
                ModifiedDate = DateTime.UtcNow
            },
            new LocationDto
            {
                LocationId = Guid.NewGuid(),
                TenantId = _testTenantId,
                LocationCode = "LOC002",
                LocationName = "Location 2",
                IsActive = true,
                CreatedDate = DateTime.UtcNow,
                ModifiedDate = DateTime.UtcNow
            }
        };

        _mockLocationService.Setup(x => x.GetAllLocationsAsync(_testTenantId, null))
            .ReturnsAsync(locations);

        // Act
        var result = await _controller.GetAllLocations();

        // Assert
        result.Result.Should().BeOfType<OkObjectResult>();
        var okResult = result.Result as OkObjectResult;
        okResult!.Value.Should().BeEquivalentTo(locations);
    }

    [Fact]
    public async Task GetAllLocations_WithActiveFilter_PassesFilterToService()
    {
        // Arrange
        var activeLocations = new List<LocationDto>
        {
            new LocationDto
            {
                LocationId = Guid.NewGuid(),
                TenantId = _testTenantId,
                LocationCode = "LOC001",
                LocationName = "Active Location",
                IsActive = true,
                CreatedDate = DateTime.UtcNow,
                ModifiedDate = DateTime.UtcNow
            }
        };

        _mockLocationService.Setup(x => x.GetAllLocationsAsync(_testTenantId, true))
            .ReturnsAsync(activeLocations);

        // Act
        var result = await _controller.GetAllLocations(isActive: true);

        // Assert
        _mockLocationService.Verify(x => x.GetAllLocationsAsync(_testTenantId, true), Times.Once);
        result.Result.Should().BeOfType<OkObjectResult>();
    }

    [Fact]
    public async Task GetAllLocations_WithEmptyTenantId_ReturnsUnauthorized()
    {
        // Arrange
        var emptyTenantContext = new TenantContext { TenantId = Guid.Empty };
        var controller = new LocationsController(_mockLocationService.Object, emptyTenantContext, _mockLogger.Object);

        // Act
        var result = await controller.GetAllLocations();

        // Assert
        result.Result.Should().BeOfType<UnauthorizedObjectResult>();
    }

    #endregion

    #region GetLocationById Tests

    [Fact]
    public async Task GetLocationById_WithExistingLocation_ReturnsOkWithLocation()
    {
        // Arrange
        var locationId = Guid.NewGuid();
        var location = new LocationDto
        {
            LocationId = locationId,
            TenantId = _testTenantId,
            LocationCode = "LOC001",
            LocationName = "Test Location",
            IsActive = true,
            CreatedDate = DateTime.UtcNow,
            ModifiedDate = DateTime.UtcNow
        };

        _mockLocationService.Setup(x => x.GetLocationByIdAsync(_testTenantId, locationId))
            .ReturnsAsync(location);

        // Act
        var result = await _controller.GetLocationById(locationId);

        // Assert
        result.Result.Should().BeOfType<OkObjectResult>();
        var okResult = result.Result as OkObjectResult;
        okResult!.Value.Should().BeEquivalentTo(location);
    }

    [Fact]
    public async Task GetLocationById_WithNonExistentLocation_ReturnsNotFound()
    {
        // Arrange
        var locationId = Guid.NewGuid();

        _mockLocationService.Setup(x => x.GetLocationByIdAsync(_testTenantId, locationId))
            .ReturnsAsync((LocationDto?)null);

        // Act
        var result = await _controller.GetLocationById(locationId);

        // Assert
        result.Result.Should().BeOfType<NotFoundObjectResult>();
    }

    [Fact]
    public async Task GetLocationById_WithEmptyTenantId_ReturnsUnauthorized()
    {
        // Arrange
        var emptyTenantContext = new TenantContext { TenantId = Guid.Empty };
        var controller = new LocationsController(_mockLocationService.Object, emptyTenantContext, _mockLogger.Object);
        var locationId = Guid.NewGuid();

        // Act
        var result = await controller.GetLocationById(locationId);

        // Assert
        result.Result.Should().BeOfType<UnauthorizedObjectResult>();
    }

    #endregion

    #region UpdateLocation Tests

    [Fact]
    public async Task UpdateLocation_WithValidRequest_ReturnsOkWithUpdatedLocation()
    {
        // Arrange
        var locationId = Guid.NewGuid();
        var request = new UpdateLocationRequest
        {
            LocationName = "Updated Location",
            AddressLine1 = "456 Oak St",
            City = "Portland",
            StateProvince = "OR",
            PostalCode = "97201",
            Country = "USA",
            IsActive = true
        };

        var updatedLocation = new LocationDto
        {
            LocationId = locationId,
            TenantId = _testTenantId,
            LocationCode = "LOC001",
            LocationName = request.LocationName,
            AddressLine1 = request.AddressLine1,
            City = request.City,
            StateProvince = request.StateProvince,
            PostalCode = request.PostalCode,
            Country = request.Country,
            IsActive = request.IsActive,
            CreatedDate = DateTime.UtcNow.AddDays(-1),
            ModifiedDate = DateTime.UtcNow
        };

        _mockLocationService.Setup(x => x.UpdateLocationAsync(_testTenantId, locationId, request))
            .ReturnsAsync(updatedLocation);

        // Act
        var result = await _controller.UpdateLocation(locationId, request);

        // Assert
        result.Result.Should().BeOfType<OkObjectResult>();
        var okResult = result.Result as OkObjectResult;
        okResult!.Value.Should().BeEquivalentTo(updatedLocation);
    }

    [Fact]
    public async Task UpdateLocation_WithNonExistentLocation_ReturnsNotFound()
    {
        // Arrange
        var locationId = Guid.NewGuid();
        var request = new UpdateLocationRequest
        {
            LocationName = "Updated Location",
            IsActive = true
        };

        _mockLocationService.Setup(x => x.UpdateLocationAsync(_testTenantId, locationId, request))
            .ThrowsAsync(new KeyNotFoundException($"Location {locationId} not found"));

        // Act
        var result = await _controller.UpdateLocation(locationId, request);

        // Assert
        result.Result.Should().BeOfType<NotFoundObjectResult>();
    }

    [Fact]
    public async Task UpdateLocation_WithEmptyTenantId_ReturnsUnauthorized()
    {
        // Arrange
        var emptyTenantContext = new TenantContext { TenantId = Guid.Empty };
        var controller = new LocationsController(_mockLocationService.Object, emptyTenantContext, _mockLogger.Object);
        var locationId = Guid.NewGuid();
        var request = new UpdateLocationRequest
        {
            LocationName = "Updated Location",
            IsActive = true
        };

        // Act
        var result = await controller.UpdateLocation(locationId, request);

        // Assert
        result.Result.Should().BeOfType<UnauthorizedObjectResult>();
    }

    #endregion

    #region DeleteLocation Tests

    [Fact]
    public async Task DeleteLocation_WithExistingLocation_ReturnsNoContent()
    {
        // Arrange
        var locationId = Guid.NewGuid();

        _mockLocationService.Setup(x => x.DeleteLocationAsync(_testTenantId, locationId))
            .ReturnsAsync(true);

        // Act
        var result = await _controller.DeleteLocation(locationId);

        // Assert
        result.Should().BeOfType<NoContentResult>();
    }

    [Fact]
    public async Task DeleteLocation_WithNonExistentLocation_ReturnsNotFound()
    {
        // Arrange
        var locationId = Guid.NewGuid();

        _mockLocationService.Setup(x => x.DeleteLocationAsync(_testTenantId, locationId))
            .ReturnsAsync(false);

        // Act
        var result = await _controller.DeleteLocation(locationId);

        // Assert
        result.Should().BeOfType<NotFoundObjectResult>();
    }

    [Fact]
    public async Task DeleteLocation_WithEmptyTenantId_ReturnsUnauthorized()
    {
        // Arrange
        var emptyTenantContext = new TenantContext { TenantId = Guid.Empty };
        var controller = new LocationsController(_mockLocationService.Object, emptyTenantContext, _mockLogger.Object);
        var locationId = Guid.NewGuid();

        // Act
        var result = await controller.DeleteLocation(locationId);

        // Assert
        result.Should().BeOfType<UnauthorizedObjectResult>();
    }

    [Fact]
    public async Task DeleteLocation_LogsInformation()
    {
        // Arrange
        var locationId = Guid.NewGuid();

        _mockLocationService.Setup(x => x.DeleteLocationAsync(_testTenantId, locationId))
            .ReturnsAsync(true);

        // Act
        await _controller.DeleteLocation(locationId);

        // Assert
        _mockLogger.Verify(
            x => x.Log(
                LogLevel.Information,
                It.IsAny<EventId>(),
                It.Is<It.IsAnyType>((v, t) => v.ToString()!.Contains("Deleting location")),
                It.IsAny<Exception>(),
                It.IsAny<Func<It.IsAnyType, Exception?, string>>()),
            Times.Once);
    }

    #endregion
}
