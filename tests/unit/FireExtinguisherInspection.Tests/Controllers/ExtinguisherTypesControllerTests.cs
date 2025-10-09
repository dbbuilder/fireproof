using FireExtinguisherInspection.API.Controllers;
using FireExtinguisherInspection.API.Models;
using FireExtinguisherInspection.API.Models.DTOs;
using FireExtinguisherInspection.API.Services;
using FluentAssertions;
using Microsoft.AspNetCore.Mvc;
using Microsoft.Extensions.Logging;
using Moq;

namespace FireExtinguisherInspection.Tests.Controllers;

public class ExtinguisherTypesControllerTests
{
    private readonly Mock<IExtinguisherTypeService> _mockService;
    private readonly Mock<ILogger<ExtinguisherTypesController>> _mockLogger;
    private readonly TenantContext _tenantContext;
    private readonly ExtinguisherTypesController _controller;
    private readonly Guid _testTenantId;

    public ExtinguisherTypesControllerTests()
    {
        _mockService = new Mock<IExtinguisherTypeService>();
        _mockLogger = new Mock<ILogger<ExtinguisherTypesController>>();
        _testTenantId = Guid.NewGuid();
        _tenantContext = new TenantContext
        {
            TenantId = _testTenantId,
            TenantCode = "TEST001",
            DatabaseSchema = $"tenant_{_testTenantId}"
        };
        _controller = new ExtinguisherTypesController(_mockService.Object, _tenantContext, _mockLogger.Object);
    }

    #region CreateExtinguisherType Tests

    [Fact]
    public async Task CreateExtinguisherType_WithValidRequest_ReturnsCreatedResult()
    {
        // Arrange
        var request = new CreateExtinguisherTypeRequest
        {
            TypeCode = "ABC-10",
            TypeName = "10lb ABC Dry Chemical",
            Description = "Standard 10lb multi-purpose extinguisher",
            AgentType = "Dry Chemical",
            Capacity = 10,
            CapacityUnit = "lbs",
            FireClassRating = "A:B:C",
            ServiceLifeYears = 12,
            HydroTestIntervalYears = 12
        };

        var expectedType = new ExtinguisherTypeDto
        {
            ExtinguisherTypeId = Guid.NewGuid(),
            TenantId = _testTenantId,
            TypeCode = request.TypeCode,
            TypeName = request.TypeName,
            Description = request.Description,
            AgentType = request.AgentType,
            Capacity = request.Capacity,
            CapacityUnit = request.CapacityUnit,
            FireClassRating = request.FireClassRating,
            ServiceLifeYears = request.ServiceLifeYears,
            HydroTestIntervalYears = request.HydroTestIntervalYears,
            IsActive = true,
            CreatedDate = DateTime.UtcNow,
            ModifiedDate = DateTime.UtcNow
        };

        _mockService.Setup(x => x.CreateExtinguisherTypeAsync(_testTenantId, request))
            .ReturnsAsync(expectedType);

        // Act
        var result = await _controller.CreateExtinguisherType(request);

        // Assert
        result.Result.Should().BeOfType<CreatedAtActionResult>();
        var createdResult = result.Result as CreatedAtActionResult;
        createdResult!.Value.Should().BeEquivalentTo(expectedType);
    }

    [Fact]
    public async Task CreateExtinguisherType_WithEmptyTenantId_ReturnsUnauthorized()
    {
        // Arrange
        var emptyTenantContext = new TenantContext { TenantId = Guid.Empty };
        var controller = new ExtinguisherTypesController(_mockService.Object, emptyTenantContext, _mockLogger.Object);

        var request = new CreateExtinguisherTypeRequest
        {
            TypeCode = "ABC-10",
            TypeName = "10lb ABC Dry Chemical"
        };

        // Act
        var result = await controller.CreateExtinguisherType(request);

        // Assert
        result.Result.Should().BeOfType<UnauthorizedObjectResult>();
    }

    #endregion

    #region GetAllExtinguisherTypes Tests

    [Fact]
    public async Task GetAllExtinguisherTypes_WithValidTenant_ReturnsOkWithTypes()
    {
        // Arrange
        var types = new List<ExtinguisherTypeDto>
        {
            new ExtinguisherTypeDto
            {
                ExtinguisherTypeId = Guid.NewGuid(),
                TenantId = _testTenantId,
                TypeCode = "ABC-10",
                TypeName = "10lb ABC",
                AgentType = "Dry Chemical",
                IsActive = true,
                CreatedDate = DateTime.UtcNow,
                ModifiedDate = DateTime.UtcNow
            },
            new ExtinguisherTypeDto
            {
                ExtinguisherTypeId = Guid.NewGuid(),
                TenantId = _testTenantId,
                TypeCode = "CO2-15",
                TypeName = "15lb CO2",
                AgentType = "CO2",
                IsActive = true,
                CreatedDate = DateTime.UtcNow,
                ModifiedDate = DateTime.UtcNow
            }
        };

        _mockService.Setup(x => x.GetAllExtinguisherTypesAsync(_testTenantId, null))
            .ReturnsAsync(types);

        // Act
        var result = await _controller.GetAllExtinguisherTypes();

        // Assert
        result.Result.Should().BeOfType<OkObjectResult>();
        var okResult = result.Result as OkObjectResult;
        okResult!.Value.Should().BeEquivalentTo(types);
    }

    [Fact]
    public async Task GetAllExtinguisherTypes_WithActiveFilter_PassesFilterToService()
    {
        // Arrange
        var activeTypes = new List<ExtinguisherTypeDto>
        {
            new ExtinguisherTypeDto
            {
                ExtinguisherTypeId = Guid.NewGuid(),
                TenantId = _testTenantId,
                TypeCode = "ABC-10",
                TypeName = "10lb ABC",
                IsActive = true,
                CreatedDate = DateTime.UtcNow,
                ModifiedDate = DateTime.UtcNow
            }
        };

        _mockService.Setup(x => x.GetAllExtinguisherTypesAsync(_testTenantId, true))
            .ReturnsAsync(activeTypes);

        // Act
        var result = await _controller.GetAllExtinguisherTypes(isActive: true);

        // Assert
        _mockService.Verify(x => x.GetAllExtinguisherTypesAsync(_testTenantId, true), Times.Once);
        result.Result.Should().BeOfType<OkObjectResult>();
    }

    #endregion

    #region GetExtinguisherTypeById Tests

    [Fact]
    public async Task GetExtinguisherTypeById_WithExistingType_ReturnsOkWithType()
    {
        // Arrange
        var typeId = Guid.NewGuid();
        var type = new ExtinguisherTypeDto
        {
            ExtinguisherTypeId = typeId,
            TenantId = _testTenantId,
            TypeCode = "ABC-10",
            TypeName = "10lb ABC",
            IsActive = true,
            CreatedDate = DateTime.UtcNow,
            ModifiedDate = DateTime.UtcNow
        };

        _mockService.Setup(x => x.GetExtinguisherTypeByIdAsync(_testTenantId, typeId))
            .ReturnsAsync(type);

        // Act
        var result = await _controller.GetExtinguisherTypeById(typeId);

        // Assert
        result.Result.Should().BeOfType<OkObjectResult>();
        var okResult = result.Result as OkObjectResult;
        okResult!.Value.Should().BeEquivalentTo(type);
    }

    [Fact]
    public async Task GetExtinguisherTypeById_WithNonExistentType_ReturnsNotFound()
    {
        // Arrange
        var typeId = Guid.NewGuid();

        _mockService.Setup(x => x.GetExtinguisherTypeByIdAsync(_testTenantId, typeId))
            .ReturnsAsync((ExtinguisherTypeDto?)null);

        // Act
        var result = await _controller.GetExtinguisherTypeById(typeId);

        // Assert
        result.Result.Should().BeOfType<NotFoundObjectResult>();
    }

    #endregion

    #region UpdateExtinguisherType Tests

    [Fact]
    public async Task UpdateExtinguisherType_WithValidRequest_ReturnsOkWithUpdatedType()
    {
        // Arrange
        var typeId = Guid.NewGuid();
        var request = new UpdateExtinguisherTypeRequest
        {
            TypeName = "Updated 10lb ABC",
            Description = "Updated description",
            IsActive = true
        };

        var updatedType = new ExtinguisherTypeDto
        {
            ExtinguisherTypeId = typeId,
            TenantId = _testTenantId,
            TypeCode = "ABC-10",
            TypeName = request.TypeName,
            Description = request.Description,
            IsActive = request.IsActive,
            CreatedDate = DateTime.UtcNow.AddDays(-1),
            ModifiedDate = DateTime.UtcNow
        };

        _mockService.Setup(x => x.UpdateExtinguisherTypeAsync(_testTenantId, typeId, request))
            .ReturnsAsync(updatedType);

        // Act
        var result = await _controller.UpdateExtinguisherType(typeId, request);

        // Assert
        result.Result.Should().BeOfType<OkObjectResult>();
        var okResult = result.Result as OkObjectResult;
        okResult!.Value.Should().BeEquivalentTo(updatedType);
    }

    [Fact]
    public async Task UpdateExtinguisherType_WithNonExistentType_ReturnsNotFound()
    {
        // Arrange
        var typeId = Guid.NewGuid();
        var request = new UpdateExtinguisherTypeRequest
        {
            TypeName = "Updated Type",
            IsActive = true
        };

        _mockService.Setup(x => x.UpdateExtinguisherTypeAsync(_testTenantId, typeId, request))
            .ThrowsAsync(new KeyNotFoundException($"Extinguisher type {typeId} not found"));

        // Act
        var result = await _controller.UpdateExtinguisherType(typeId, request);

        // Assert
        result.Result.Should().BeOfType<NotFoundObjectResult>();
    }

    #endregion

    #region DeleteExtinguisherType Tests

    [Fact]
    public async Task DeleteExtinguisherType_WithExistingType_ReturnsNoContent()
    {
        // Arrange
        var typeId = Guid.NewGuid();

        _mockService.Setup(x => x.DeleteExtinguisherTypeAsync(_testTenantId, typeId))
            .ReturnsAsync(true);

        // Act
        var result = await _controller.DeleteExtinguisherType(typeId);

        // Assert
        result.Should().BeOfType<NoContentResult>();
    }

    [Fact]
    public async Task DeleteExtinguisherType_WithNonExistentType_ReturnsNotFound()
    {
        // Arrange
        var typeId = Guid.NewGuid();

        _mockService.Setup(x => x.DeleteExtinguisherTypeAsync(_testTenantId, typeId))
            .ReturnsAsync(false);

        // Act
        var result = await _controller.DeleteExtinguisherType(typeId);

        // Assert
        result.Should().BeOfType<NotFoundObjectResult>();
    }

    #endregion

    #region DTO Validation Tests

    [Fact]
    public void CreateExtinguisherTypeRequest_RequiredFields_AreNotNullOrEmpty()
    {
        // Arrange & Act
        var request = new CreateExtinguisherTypeRequest
        {
            TypeCode = "ABC-10",
            TypeName = "10lb ABC Dry Chemical"
        };

        // Assert
        request.TypeCode.Should().NotBeNullOrEmpty();
        request.TypeName.Should().NotBeNullOrEmpty();
    }

    [Fact]
    public void ExtinguisherTypeDto_FireClassRating_CanBeNull()
    {
        // Arrange & Act
        var dto = new ExtinguisherTypeDto
        {
            ExtinguisherTypeId = Guid.NewGuid(),
            TenantId = Guid.NewGuid(),
            TypeCode = "TEST",
            TypeName = "Test Type",
            FireClassRating = null,
            IsActive = true,
            CreatedDate = DateTime.UtcNow,
            ModifiedDate = DateTime.UtcNow
        };

        // Assert
        dto.FireClassRating.Should().BeNull();
    }

    #endregion
}
