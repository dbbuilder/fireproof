using System;
using System.Security.Cryptography;
using System.Text;

namespace FireExtinguisherInspection.API.Services
{
    /// <summary>
    /// BCrypt-based password hashing service
    /// Uses BCrypt.Net-Next for industry-standard password hashing
    /// </summary>
    public class PasswordHasher : IPasswordHasher
    {
        private const int WorkFactor = 12; // BCrypt work factor (higher = more secure but slower)

        /// <summary>
        /// Hash a password using BCrypt
        /// </summary>
        public string HashPassword(string password, out string salt)
        {
            if (string.IsNullOrEmpty(password))
                throw new ArgumentException("Password cannot be null or empty", nameof(password));

            // Generate salt
            salt = BCrypt.Net.BCrypt.GenerateSalt(WorkFactor);

            // Hash password with salt
            var hash = BCrypt.Net.BCrypt.HashPassword(password, salt);

            return hash;
        }

        /// <summary>
        /// Verify a password against its BCrypt hash
        /// </summary>
        public bool VerifyPassword(string password, string hash, string salt)
        {
            if (string.IsNullOrEmpty(password))
                return false;

            if (string.IsNullOrEmpty(hash))
                return false;

            try
            {
                // BCrypt.Verify handles the salt internally
                return BCrypt.Net.BCrypt.Verify(password, hash);
            }
            catch
            {
                return false;
            }
        }
    }
}
