namespace FireExtinguisherInspection.API.Services;

/// <summary>
/// Service for creating tamper-proof inspection records using cryptographic hashing
/// </summary>
public interface ITamperProofingService
{
    /// <summary>
    /// Compute a SHA-256 hash of inspection data
    /// </summary>
    /// <param name="inspectionData">Inspection data object</param>
    /// <returns>Hexadecimal hash string</returns>
    string ComputeInspectionHash(object inspectionData);

    /// <summary>
    /// Verify that an inspection record has not been tampered with
    /// </summary>
    /// <param name="inspectionData">Inspection data object</param>
    /// <param name="storedHash">The hash stored with the inspection</param>
    /// <returns>True if hashes match (not tampered), false otherwise</returns>
    bool VerifyInspectionIntegrity(object inspectionData, string storedHash);

    /// <summary>
    /// Create a digital signature for an inspection
    /// </summary>
    /// <param name="inspectorUserId">Inspector's user ID</param>
    /// <param name="inspectionHash">Hash of the inspection data</param>
    /// <param name="timestamp">Signature timestamp</param>
    /// <returns>Digital signature string</returns>
    string CreateInspectorSignature(Guid inspectorUserId, string inspectionHash, DateTime timestamp);

    /// <summary>
    /// Verify an inspector's digital signature
    /// </summary>
    /// <param name="signature">The signature to verify</param>
    /// <param name="inspectorUserId">Inspector's user ID</param>
    /// <param name="inspectionHash">Hash of the inspection data</param>
    /// <param name="timestamp">Signature timestamp</param>
    /// <returns>True if signature is valid</returns>
    bool VerifyInspectorSignature(string signature, Guid inspectorUserId, string inspectionHash, DateTime timestamp);
}
