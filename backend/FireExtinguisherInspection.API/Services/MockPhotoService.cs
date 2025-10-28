using FireExtinguisherInspection.API.Models.DTOs;

namespace FireExtinguisherInspection.API.Services;

/// <summary>
/// Mock photo service for development mode - bypasses Azure Blob Storage
/// </summary>
public class MockPhotoService : IPhotoService
{
    public Task<PhotoUploadResponse> UploadPhotoAsync(Guid tenantId, UploadPhotoRequest request)
    {
        return Task.FromResult(new PhotoUploadResponse
        {
            PhotoId = Guid.NewGuid(),
            BlobUrl = $"mock://photos/{Guid.NewGuid()}.jpg",
            ThumbnailUrl = $"mock://thumbnails/{Guid.NewGuid()}.jpg",
            FileSize = 1024,
            EXIFDataExtracted = false,
            UploadedDate = DateTime.UtcNow
        });
    }

    public Task<IEnumerable<PhotoUploadResponse>> UploadPhotosAsync(Guid tenantId, IEnumerable<UploadPhotoRequest> requests)
    {
        var responses = requests.Select(r => new PhotoUploadResponse
        {
            PhotoId = Guid.NewGuid(),
            BlobUrl = $"mock://photos/{Guid.NewGuid()}.jpg",
            ThumbnailUrl = $"mock://thumbnails/{Guid.NewGuid()}.jpg",
            FileSize = 1024,
            EXIFDataExtracted = false,
            UploadedDate = DateTime.UtcNow
        });
        return Task.FromResult(responses);
    }

    public Task<InspectionPhotoDto?> GetPhotoByIdAsync(Guid tenantId, Guid photoId)
    {
        return Task.FromResult<InspectionPhotoDto?>(null);
    }

    public Task<IEnumerable<InspectionPhotoDto>> GetPhotosByInspectionAsync(Guid tenantId, Guid inspectionId)
    {
        return Task.FromResult(Enumerable.Empty<InspectionPhotoDto>());
    }

    public Task<IEnumerable<InspectionPhotoDto>> GetPhotosByTypeAsync(Guid tenantId, Guid inspectionId, string photoType)
    {
        return Task.FromResult(Enumerable.Empty<InspectionPhotoDto>());
    }

    public Task<string> GetPhotoUrlAsync(Guid tenantId, Guid photoId, int expirationMinutes = 60)
    {
        return Task.FromResult($"mock://photos/{photoId}.jpg");
    }

    public Task<string> GetThumbnailUrlAsync(Guid tenantId, Guid photoId, int expirationMinutes = 60)
    {
        return Task.FromResult($"mock://thumbnails/{photoId}.jpg");
    }

    public Task<bool> DeletePhotoAsync(Guid tenantId, Guid photoId)
    {
        return Task.FromResult(true);
    }

    public Task<ExifData?> ExtractExifDataAsync(Stream photoStream)
    {
        return Task.FromResult<ExifData?>(new ExifData
        {
            CaptureDate = DateTime.UtcNow,
            DeviceModel = "Mock Device",
            ImageWidth = 1920,
            ImageHeight = 1080
        });
    }
}
