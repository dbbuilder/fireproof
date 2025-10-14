using FireExtinguisherInspection.API.Models.DTOs;

namespace FireExtinguisherInspection.API.Services;

/// <summary>
/// Service interface for inspection photo management
/// Handles photo upload, EXIF extraction, thumbnail generation, and Azure Blob Storage
/// Designed for mobile-first experience with future native app support
/// </summary>
public interface IPhotoService
{
    /// <summary>
    /// Uploads a photo to Azure Blob Storage with EXIF extraction and thumbnail generation
    /// Optimized for mobile uploads (handles large files, slow connections)
    /// </summary>
    Task<PhotoUploadResponse> UploadPhotoAsync(Guid tenantId, UploadPhotoRequest request);

    /// <summary>
    /// Uploads multiple photos in batch (mobile optimization for offline queue sync)
    /// </summary>
    Task<IEnumerable<PhotoUploadResponse>> UploadPhotosAsync(Guid tenantId, IEnumerable<UploadPhotoRequest> requests);

    /// <summary>
    /// Gets a specific photo by ID with full EXIF data
    /// </summary>
    Task<InspectionPhotoDto?> GetPhotoByIdAsync(Guid tenantId, Guid photoId);

    /// <summary>
    /// Gets all photos for a specific inspection
    /// </summary>
    Task<IEnumerable<InspectionPhotoDto>> GetPhotosByInspectionAsync(Guid tenantId, Guid inspectionId);

    /// <summary>
    /// Gets photos by type (Location, PhysicalCondition, Pressure, Label, Seal, Hose, Deficiency, Other)
    /// </summary>
    Task<IEnumerable<InspectionPhotoDto>> GetPhotosByTypeAsync(Guid tenantId, Guid inspectionId, string photoType);

    /// <summary>
    /// Gets a signed URL for secure photo access (mobile apps, temporary links)
    /// </summary>
    Task<string> GetPhotoUrlAsync(Guid tenantId, Guid photoId, int expirationMinutes = 60);

    /// <summary>
    /// Gets a signed URL for thumbnail (mobile optimization for list views)
    /// </summary>
    Task<string> GetThumbnailUrlAsync(Guid tenantId, Guid photoId, int expirationMinutes = 60);

    /// <summary>
    /// Deletes a photo from Azure Blob Storage and database (soft delete)
    /// </summary>
    Task<bool> DeletePhotoAsync(Guid tenantId, Guid photoId);

    /// <summary>
    /// Extracts EXIF data from an uploaded photo (lat/lng, capture date, device model)
    /// Used for tamper verification
    /// </summary>
    Task<ExifData?> ExtractExifDataAsync(Stream photoStream);
}

/// <summary>
/// EXIF metadata extracted from photos for tamper verification
/// </summary>
public class ExifData
{
    public DateTime? CaptureDate { get; set; }
    public decimal? Latitude { get; set; }
    public decimal? Longitude { get; set; }
    public string? DeviceModel { get; set; }
    public string? DeviceMake { get; set; }
    public int? ImageWidth { get; set; }
    public int? ImageHeight { get; set; }
    public string? Orientation { get; set; }
    public string? FullExifJson { get; set; } // Complete EXIF data as JSON
}
