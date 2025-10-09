using FireExtinguisherInspection.API.Controllers;
using FluentAssertions;
using Microsoft.AspNetCore.Mvc;
using Microsoft.Extensions.Logging;
using Moq;

namespace FireExtinguisherInspection.Tests.Controllers;

public class HealthControllerTests
{
    private readonly Mock<ILogger<HealthController>> _mockLogger;
    private readonly HealthController _controller;

    public HealthControllerTests()
    {
        _mockLogger = new Mock<ILogger<HealthController>>();
        _controller = new HealthController(_mockLogger.Object);
    }

    [Fact]
    public void Get_ReturnsOkResult()
    {
        // Act
        var result = _controller.Get();

        // Assert
        result.Should().BeOfType<OkObjectResult>();
    }

    [Fact]
    public void Get_ReturnsHealthStatus()
    {
        // Act
        var result = _controller.Get() as OkObjectResult;

        // Assert
        result.Should().NotBeNull();
        var value = result!.Value;
        value.Should().NotBeNull();

        // Check for expected properties using reflection
        var statusProperty = value.GetType().GetProperty("status");
        var timestampProperty = value.GetType().GetProperty("timestamp");
        var versionProperty = value.GetType().GetProperty("version");
        var serviceProperty = value.GetType().GetProperty("service");

        statusProperty.Should().NotBeNull();
        timestampProperty.Should().NotBeNull();
        versionProperty.Should().NotBeNull();
        serviceProperty.Should().NotBeNull();

        statusProperty!.GetValue(value).Should().Be("healthy");
        versionProperty!.GetValue(value).Should().Be("1.0.0");
        serviceProperty!.GetValue(value).Should().Be("FireProof API");
    }

    [Fact]
    public void Get_ReturnsCurrentTimestamp()
    {
        // Arrange
        var beforeCall = DateTime.UtcNow;

        // Act
        var result = _controller.Get() as OkObjectResult;

        // Assert
        var afterCall = DateTime.UtcNow;
        result.Should().NotBeNull();

        var value = result!.Value;
        var timestampProperty = value!.GetType().GetProperty("timestamp");
        var timestamp = (DateTime)timestampProperty!.GetValue(value)!;

        timestamp.Should().BeOnOrAfter(beforeCall).And.BeOnOrBefore(afterCall);
    }

    [Fact]
    public void Get_LogsDebugMessage()
    {
        // Act
        _controller.Get();

        // Assert
        _mockLogger.Verify(
            x => x.Log(
                LogLevel.Debug,
                It.IsAny<EventId>(),
                It.Is<It.IsAnyType>((v, t) => v.ToString()!.Contains("Health check requested")),
                It.IsAny<Exception>(),
                It.IsAny<Func<It.IsAnyType, Exception?, string>>()),
            Times.Once);
    }

    [Fact]
    public void Ping_ReturnsOkResult()
    {
        // Act
        var result = _controller.Ping();

        // Assert
        result.Should().BeOfType<OkObjectResult>();
    }

    [Fact]
    public void Ping_ReturnsPongMessage()
    {
        // Act
        var result = _controller.Ping() as OkObjectResult;

        // Assert
        result.Should().NotBeNull();
        var value = result!.Value;
        value.Should().NotBeNull();

        var messageProperty = value!.GetType().GetProperty("message");
        var timestampProperty = value.GetType().GetProperty("timestamp");

        messageProperty.Should().NotBeNull();
        timestampProperty.Should().NotBeNull();

        messageProperty!.GetValue(value).Should().Be("pong");
    }

    [Fact]
    public void Ping_ReturnsCurrentTimestamp()
    {
        // Arrange
        var beforeCall = DateTime.UtcNow;

        // Act
        var result = _controller.Ping() as OkObjectResult;

        // Assert
        var afterCall = DateTime.UtcNow;
        result.Should().NotBeNull();

        var value = result!.Value;
        var timestampProperty = value!.GetType().GetProperty("timestamp");
        var timestamp = (DateTime)timestampProperty!.GetValue(value)!;

        timestamp.Should().BeOnOrAfter(beforeCall).And.BeOnOrBefore(afterCall);
    }
}
