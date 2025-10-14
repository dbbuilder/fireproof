namespace FireExtinguisherInspection.API.Models.DTOs;

/// <summary>
/// Photo attached to an inspection with EXIF data for tamper verification
/// </summary>
public class InspectionPhotoDto
{
    public Guid PhotoId { get; set; }
    public Guid InspectionId { get; set; }
    public required string PhotoType { get; set; } // Location, PhysicalCondition, Pressure, Label, Seal, Hose, Deficiency, Other
    public required string BlobUrl { get; set; }
    public string? ThumbnailUrl { get; set; }
    public long? FileSize { get; set; }
    public string? MimeType { get; set; }

    // EXIF Data for tamper verification
    public DateTime? CaptureDate { get; set; }
    public decimal? Latitude { get; set; }
    public decimal? Longitude { get; set; }
    public string? DeviceModel { get; set; }
    public string? EXIFData { get; set; } // Full EXIF JSON

    public string? Notes { get; set; }
    public DateTime CreatedDate { get; set; }
}

/// <summary>
/// Request to upload a photo
/// </summary>
public class UploadPhotoRequest
{
    public Guid InspectionId { get; set; }
    public required string PhotoType { get; set; }
    public required IFormFile File { get; set; }
    public DateTime? CaptureDate { get; set; }
    public decimal? Latitude { get; set; }
    public decimal? Longitude { get; set; }
    public string? DeviceModel { get; set; }
    public string? Notes { get; set; }
}

/// <summary>
/// Response for photo upload
/// </summary>
public class PhotoUploadResponse
{
    public Guid PhotoId { get; set; }
    public required string BlobUrl { get; set; }
    public string? ThumbnailUrl { get; set; }
    public long FileSize { get; set; }
    public bool EXIFDataExtracted { get; set; }
    public DateTime UploadedDate { get; set; }
}
