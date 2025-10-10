using System.Security.Cryptography;
using System.Text;
using System.Text.Json;

namespace FireExtinguisherInspection.API.Services;

/// <summary>
/// Implementation of tamper-proofing service using SHA-256 hashing and HMAC signatures
/// Ensures inspection records cannot be modified after creation
/// </summary>
public class TamperProofingService : ITamperProofingService
{
    private readonly IConfiguration _configuration;
    private readonly ILogger<TamperProofingService> _logger;
    private readonly byte[] _signatureKey;

    public TamperProofingService(IConfiguration configuration, ILogger<TamperProofingService> logger)
    {
        _configuration = configuration;
        _logger = logger;

        // Try Key Vault first, fallback to appsettings
        var keyString = _configuration["TamperProofingSignatureKey"]
            ?? _configuration["TamperProofing:SignatureKey"]
            ?? throw new InvalidOperationException("TamperProofing signature key not configured");
        _signatureKey = Encoding.UTF8.GetBytes(keyString);

        _logger.LogInformation("TamperProofing service initialized with signature key from {Source}",
            _configuration["TamperProofingSignatureKey"] != null ? "Key Vault" : "appsettings");
    }

    /// <summary>
    /// Compute SHA-256 hash of inspection data
    /// Creates a deterministic hash by serializing the object to JSON
    /// </summary>
    public string ComputeInspectionHash(object inspectionData)
    {
        try
        {
            // Serialize to JSON with consistent formatting
            var jsonOptions = new JsonSerializerOptions
            {
                WriteIndented = false,
                PropertyNamingPolicy = JsonNamingPolicy.CamelCase,
                DefaultIgnoreCondition = System.Text.Json.Serialization.JsonIgnoreCondition.Never
            };

            var jsonString = JsonSerializer.Serialize(inspectionData, jsonOptions);
            var bytes = Encoding.UTF8.GetBytes(jsonString);

            using var sha256 = SHA256.Create();
            var hashBytes = sha256.ComputeHash(bytes);

            // Convert to hexadecimal string
            return BitConverter.ToString(hashBytes).Replace("-", "").ToLowerInvariant();
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error computing inspection hash");
            throw;
        }
    }

    /// <summary>
    /// Verify inspection data has not been tampered with
    /// </summary>
    public bool VerifyInspectionIntegrity(object inspectionData, string storedHash)
    {
        try
        {
            var computedHash = ComputeInspectionHash(inspectionData);
            var isValid = string.Equals(computedHash, storedHash, StringComparison.OrdinalIgnoreCase);

            if (!isValid)
            {
                _logger.LogWarning(
                    "Inspection integrity check failed. Stored hash: {StoredHash}, Computed hash: {ComputedHash}",
                    storedHash,
                    computedHash);
            }

            return isValid;
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error verifying inspection integrity");
            return false;
        }
    }

    /// <summary>
    /// Create HMAC-based digital signature for inspector
    /// Combines inspector ID, inspection hash, and timestamp
    /// </summary>
    public string CreateInspectorSignature(Guid inspectorUserId, string inspectionHash, DateTime timestamp)
    {
        try
        {
            // Create signature payload
            var payload = $"{inspectorUserId:N}|{inspectionHash}|{timestamp:O}";
            var payloadBytes = Encoding.UTF8.GetBytes(payload);

            // Compute HMAC-SHA256
            using var hmac = new HMACSHA256(_signatureKey);
            var signatureBytes = hmac.ComputeHash(payloadBytes);

            // Return as base64 string
            return Convert.ToBase64String(signatureBytes);
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error creating inspector signature");
            throw;
        }
    }

    /// <summary>
    /// Verify inspector's digital signature
    /// </summary>
    public bool VerifyInspectorSignature(string signature, Guid inspectorUserId, string inspectionHash, DateTime timestamp)
    {
        try
        {
            var expectedSignature = CreateInspectorSignature(inspectorUserId, inspectionHash, timestamp);
            var isValid = string.Equals(signature, expectedSignature, StringComparison.Ordinal);

            if (!isValid)
            {
                _logger.LogWarning(
                    "Inspector signature verification failed for inspector {InspectorId}",
                    inspectorUserId);
            }

            return isValid;
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error verifying inspector signature");
            return false;
        }
    }
}

/// <summary>
/// Helper class to create a hashable inspection data object
/// Excludes fields that shouldn't be part of the hash (IDs, timestamps, hash itself)
/// </summary>
public class InspectionHashData
{
    public Guid ExtinguisherId { get; set; }
    public Guid InspectorUserId { get; set; }
    public DateTime InspectionDate { get; set; }
    public string InspectionType { get; set; } = string.Empty;

    public decimal? GpsLatitude { get; set; }
    public decimal? GpsLongitude { get; set; }
    public int? GpsAccuracyMeters { get; set; }

    public bool IsAccessible { get; set; }
    public bool HasObstructions { get; set; }
    public bool SignageVisible { get; set; }
    public bool SealIntact { get; set; }
    public bool PinInPlace { get; set; }
    public bool NozzleClear { get; set; }
    public bool HoseConditionGood { get; set; }
    public bool GaugeInGreenZone { get; set; }
    public decimal? GaugePressurePsi { get; set; }
    public bool PhysicalDamagePresent { get; set; }
    public string? DamageDescription { get; set; }

    public decimal? WeightPounds { get; set; }

    public bool InspectionTagAttached { get; set; }
    public string? PreviousInspectionDate { get; set; }
    public string? Notes { get; set; }

    public bool RequiresService { get; set; }
    public bool RequiresReplacement { get; set; }
    public string? FailureReason { get; set; }
    public string? CorrectiveAction { get; set; }

    public List<string>? PhotoUrls { get; set; }
}
