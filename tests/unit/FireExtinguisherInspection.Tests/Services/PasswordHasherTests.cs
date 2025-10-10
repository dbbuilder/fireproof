using FireExtinguisherInspection.API.Services;
using FluentAssertions;
using Xunit;

namespace FireExtinguisherInspection.Tests.Services
{
    public class PasswordHasherTests
    {
        private readonly IPasswordHasher _passwordHasher;

        public PasswordHasherTests()
        {
            _passwordHasher = new PasswordHasher();
        }

        [Fact]
        public void HashPassword_WithValidPassword_ReturnsHashAndSalt()
        {
            // Arrange
            var password = "SecurePassword123!";

            // Act
            var hash = _passwordHasher.HashPassword(password, out var salt);

            // Assert
            hash.Should().NotBeNullOrEmpty();
            salt.Should().NotBeNullOrEmpty();
            hash.Should().NotBe(password);
            salt.Should().NotBe(password);
        }

        [Fact]
        public void HashPassword_WithSamePassword_GeneratesDifferentHashesWithDifferentSalts()
        {
            // Arrange
            var password = "SamePassword123!";

            // Act
            var hash1 = _passwordHasher.HashPassword(password, out var salt1);
            var hash2 = _passwordHasher.HashPassword(password, out var salt2);

            // Assert
            salt1.Should().NotBe(salt2);
            hash1.Should().NotBe(hash2);
        }

        [Fact]
        public void VerifyPassword_WithCorrectPassword_ReturnsTrue()
        {
            // Arrange
            var password = "CorrectPassword123!";
            var hash = _passwordHasher.HashPassword(password, out var salt);

            // Act
            var result = _passwordHasher.VerifyPassword(password, hash, salt);

            // Assert
            result.Should().BeTrue();
        }

        [Fact]
        public void VerifyPassword_WithIncorrectPassword_ReturnsFalse()
        {
            // Arrange
            var correctPassword = "CorrectPassword123!";
            var incorrectPassword = "WrongPassword123!";
            var hash = _passwordHasher.HashPassword(correctPassword, out var salt);

            // Act
            var result = _passwordHasher.VerifyPassword(incorrectPassword, hash, salt);

            // Assert
            result.Should().BeFalse();
        }

        [Fact]
        public void VerifyPassword_WithNullPassword_ReturnsFalse()
        {
            // Arrange
            var password = "ValidPassword123!";
            var hash = _passwordHasher.HashPassword(password, out var salt);

            // Act
            var result = _passwordHasher.VerifyPassword(null!, hash, salt);

            // Assert
            result.Should().BeFalse();
        }

        [Fact]
        public void VerifyPassword_WithEmptyPassword_ReturnsFalse()
        {
            // Arrange
            var password = "ValidPassword123!";
            var hash = _passwordHasher.HashPassword(password, out var salt);

            // Act
            var result = _passwordHasher.VerifyPassword("", hash, salt);

            // Assert
            result.Should().BeFalse();
        }

        [Fact]
        public void VerifyPassword_WithNullHash_ReturnsFalse()
        {
            // Arrange
            var password = "ValidPassword123!";
            _passwordHasher.HashPassword(password, out var salt);

            // Act
            var result = _passwordHasher.VerifyPassword(password, null!, salt);

            // Assert
            result.Should().BeFalse();
        }

        [Fact]
        public void HashPassword_WithNullPassword_ThrowsArgumentException()
        {
            // Act
            Action act = () => _passwordHasher.HashPassword(null!, out _);

            // Assert
            act.Should().Throw<ArgumentException>()
                .WithMessage("Password cannot be null or empty*");
        }

        [Fact]
        public void HashPassword_WithEmptyPassword_ThrowsArgumentException()
        {
            // Act
            Action act = () => _passwordHasher.HashPassword("", out _);

            // Assert
            act.Should().Throw<ArgumentException>()
                .WithMessage("Password cannot be null or empty*");
        }
    }
}
