namespace FireExtinguisherInspection.API.Services
{
    /// <summary>
    /// Service for hashing and verifying passwords using BCrypt
    /// </summary>
    public interface IPasswordHasher
    {
        /// <summary>
        /// Hash a password with a salt
        /// </summary>
        /// <param name="password">Plain text password</param>
        /// <param name="salt">Output: generated salt</param>
        /// <returns>Password hash</returns>
        string HashPassword(string password, out string salt);

        /// <summary>
        /// Verify a password against a hash
        /// </summary>
        /// <param name="password">Plain text password to verify</param>
        /// <param name="hash">Stored password hash</param>
        /// <param name="salt">Stored salt</param>
        /// <returns>True if password matches</returns>
        bool VerifyPassword(string password, string hash, string salt);
    }
}
