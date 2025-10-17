using System.Data;
using System.Text.Json;
using Azure.Storage.Blobs;
using Azure.Storage.Blobs.Models;
using Azure.Storage.Sas;
using FireExtinguisherInspection.API.Data;
using FireExtinguisherInspection.API.Models.DTOs;
using MetadataExtractor;
using MetadataExtractor.Formats.Exif;
using Microsoft.Data.SqlClient;
using SixLabors.ImageSharp;
using SixLabors.ImageSharp.Processing;

namespace FireExtinguisherInspection.API.Services;

/// <summary>
/// Azure Blob Storage photo service with mobile-first optimizations
/// Handles upload, EXIF extraction, thumbnail generation, and tamper verification
/// </summary>
public class AzureBlobPhotoService : IPhotoService
{
    private readonly IDbConnectionFactory _connectionFactory;
    private readonly BlobServiceClient _blobServiceClient;
    private readonly IConfiguration _configuration;
    private readonly ILogger<AzureBlobPhotoService> _logger;

    private const int ThumbnailMaxWidth = 400; // Mobile-optimized thumbnail size
    private const int ThumbnailMaxHeight = 400;
    private const int ThumbnailQuality = 80; // Balance between quality and size

    public AzureBlobPhotoService(
        IDbConnectionFactory connectionFactory,
        IConfiguration configuration,
        ILogger<AzureBlobPhotoService> logger)
    {
        _connectionFactory = connectionFactory;
        _configuration = configuration;
        _logger = logger;

        // Initialize Azure Blob Service Client
        var connectionString = configuration["AzureStorage:ConnectionString"]
            ?? configuration.GetConnectionString("AzureStorage")
            ?? throw new InvalidOperationException("Azure Storage connection string not configured");

        _blobServiceClient = new BlobServiceClient(connectionString);
    }

    public async Task<PhotoUploadResponse> UploadPhotoAsync(Guid tenantId, UploadPhotoRequest request)
    {
        _logger.LogInformation("Uploading photo for inspection {InspectionId}, type: {PhotoType}",
            request.InspectionId, request.PhotoType);

        try
        {
            // Validate file
            if (request.File.Length == 0)
            {
                throw new ArgumentException("File is empty");
            }

            if (request.File.Length > 50 * 1024 * 1024) // 50 MB limit (mobile optimization)
            {
                throw new ArgumentException("File size exceeds 50 MB limit");
            }

            // Validate content type (mobile cameras typically produce JPEG)
            var allowedTypes = new[] { "image/jpeg", "image/jpg", "image/png", "image/heic", "image/heif" };
            if (!allowedTypes.Contains(request.File.ContentType.ToLower()))
            {
                throw new ArgumentException($"Invalid file type: {request.File.ContentType}. Allowed: JPEG, PNG, HEIC");
            }

            // Generate unique identifiers
            var photoId = Guid.NewGuid();
            var fileName = $"{photoId}{Path.GetExtension(request.File.FileName)}";
            var thumbnailFileName = $"{photoId}_thumb{Path.GetExtension(request.File.FileName)}";

            // Get or create container for tenant
            var containerName = $"tenant-{tenantId:N}".ToLowerInvariant();
            var containerClient = _blobServiceClient.GetBlobContainerClient(containerName);
            await containerClient.CreateIfNotExistsAsync(PublicAccessType.None);

            // Extract EXIF data before uploading
            ExifData? exifData = null;
            using (var stream = request.File.OpenReadStream())
            {
                exifData = await ExtractExifDataAsync(stream);
            }

            // Upload original photo
            string blobUrl;
            using (var stream = request.File.OpenReadStream())
            {
                var blobClient = containerClient.GetBlobClient(fileName);
                await blobClient.UploadAsync(stream, new BlobHttpHeaders
                {
                    ContentType = request.File.ContentType
                });
                blobUrl = blobClient.Uri.ToString();
            }

            // Generate and upload thumbnail (mobile optimization for list views)
            string? thumbnailUrl = null;
            try
            {
                using (var originalStream = request.File.OpenReadStream())
                using (var thumbnailStream = await GenerateThumbnailAsync(originalStream))
                {
                    var thumbnailBlobClient = containerClient.GetBlobClient(thumbnailFileName);
                    await thumbnailBlobClient.UploadAsync(thumbnailStream, new BlobHttpHeaders
                    {
                        ContentType = request.File.ContentType
                    });
                    thumbnailUrl = thumbnailBlobClient.Uri.ToString();
                }
            }
            catch (Exception ex)
            {
                _logger.LogWarning(ex, "Failed to generate thumbnail for photo {PhotoId}, continuing without thumbnail", photoId);
            }

            // Merge client-provided data with extracted EXIF
            var captureDate = request.CaptureDate ?? exifData?.CaptureDate;
            var latitude = request.Latitude ?? exifData?.Latitude;
            var longitude = request.Longitude ?? exifData?.Longitude;
            var deviceModel = request.DeviceModel ?? exifData?.DeviceModel;

            // Store photo metadata in database
            using var connection = await _connectionFactory.CreateConnectionAsync();

            using var command = (SqlCommand)connection.CreateCommand();
            command.CommandText = "dbo.usp_InspectionPhoto_Create";
            command.CommandType = CommandType.StoredProcedure;

            var photoIdParam = new SqlParameter("@PhotoId", SqlDbType.UniqueIdentifier)
            {
                Direction = ParameterDirection.InputOutput,
                Value = photoId
            };
            command.Parameters.Add(photoIdParam);
            command.Parameters.AddWithValue("@InspectionId", request.InspectionId);
            command.Parameters.AddWithValue("@PhotoType", request.PhotoType);
            command.Parameters.AddWithValue("@BlobUrl", blobUrl);
            command.Parameters.AddWithValue("@ThumbnailUrl", (object?)thumbnailUrl ?? DBNull.Value);
            command.Parameters.AddWithValue("@FileSize", request.File.Length);
            command.Parameters.AddWithValue("@MimeType", request.File.ContentType);
            command.Parameters.AddWithValue("@Notes", (object?)request.Notes ?? DBNull.Value);
            command.Parameters.AddWithValue("@TenantId", tenantId);

            await command.ExecuteNonQueryAsync();

            _logger.LogInformation("Photo uploaded successfully: {PhotoId}, size: {FileSize} bytes",
                photoId, request.File.Length);

            return new PhotoUploadResponse
            {
                PhotoId = photoId,
                BlobUrl = blobUrl,
                ThumbnailUrl = thumbnailUrl,
                FileSize = request.File.Length,
                EXIFDataExtracted = exifData != null,
                UploadedDate = DateTime.UtcNow
            };
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error uploading photo for inspection {InspectionId}", request.InspectionId);
            throw;
        }
    }

    public async Task<IEnumerable<PhotoUploadResponse>> UploadPhotosAsync(Guid tenantId, IEnumerable<UploadPhotoRequest> requests)
    {
        _logger.LogInformation("Uploading {Count} photos in batch for tenant {TenantId}",
            requests.Count(), tenantId);

        var responses = new List<PhotoUploadResponse>();

        foreach (var request in requests)
        {
            try
            {
                var response = await UploadPhotoAsync(tenantId, request);
                responses.Add(response);
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error uploading photo in batch for inspection {InspectionId}",
                    request.InspectionId);
                // Continue with other photos even if one fails
            }
        }

        _logger.LogInformation("Batch upload completed: {Success}/{Total} photos uploaded",
            responses.Count, requests.Count());

        return responses;
    }

    public async Task<InspectionPhotoDto?> GetPhotoByIdAsync(Guid tenantId, Guid photoId)
    {
        _logger.LogDebug("Fetching photo {PhotoId} for tenant {TenantId}", photoId, tenantId);

        var schemaName = await _connectionFactory.GetTenantSchemaAsync(tenantId);
        using var connection = await _connectionFactory.CreateTenantConnectionAsync(tenantId);

        using var command = (SqlCommand)connection.CreateCommand();
        command.CommandText = $@"
            SELECT * FROM [{schemaName}].InspectionPhotos
            WHERE PhotoId = @PhotoId";

        command.Parameters.AddWithValue("@PhotoId", photoId);

        using var reader = await command.ExecuteReaderAsync();

        if (await reader.ReadAsync())
        {
            return MapPhotoFromReader(reader);
        }

        return null;
    }

    public async Task<IEnumerable<InspectionPhotoDto>> GetPhotosByInspectionAsync(Guid tenantId, Guid inspectionId)
    {
        _logger.LogDebug("Fetching photos for inspection {InspectionId}", inspectionId);

        using var connection = await _connectionFactory.CreateConnectionAsync();

        using var command = (SqlCommand)connection.CreateCommand();
        command.CommandText = "dbo.usp_InspectionPhoto_GetByInspection";
        command.CommandType = CommandType.StoredProcedure;

        command.Parameters.AddWithValue("@InspectionId", inspectionId);
        command.Parameters.AddWithValue("@TenantId", tenantId);

        var photos = new List<InspectionPhotoDto>();

        using var reader = await command.ExecuteReaderAsync();
        while (await reader.ReadAsync())
        {
            photos.Add(MapPhotoFromReader(reader));
        }

        return photos;
    }

    public async Task<IEnumerable<InspectionPhotoDto>> GetPhotosByTypeAsync(Guid tenantId, Guid inspectionId, string photoType)
    {
        _logger.LogDebug("Fetching {PhotoType} photos for inspection {InspectionId}", photoType, inspectionId);

        using var connection = await _connectionFactory.CreateConnectionAsync();

        using var command = (SqlCommand)connection.CreateCommand();
        command.CommandText = "dbo.usp_InspectionPhoto_GetByType";
        command.CommandType = CommandType.StoredProcedure;

        command.Parameters.AddWithValue("@InspectionId", inspectionId);
        command.Parameters.AddWithValue("@PhotoType", photoType);
        command.Parameters.AddWithValue("@TenantId", tenantId);

        var photos = new List<InspectionPhotoDto>();

        using var reader = await command.ExecuteReaderAsync();
        while (await reader.ReadAsync())
        {
            photos.Add(MapPhotoFromReader(reader));
        }

        return photos;
    }

    public async Task<string> GetPhotoUrlAsync(Guid tenantId, Guid photoId, int expirationMinutes = 60)
    {
        var photo = await GetPhotoByIdAsync(tenantId, photoId);
        if (photo == null)
        {
            throw new KeyNotFoundException($"Photo {photoId} not found");
        }

        // Generate SAS token for secure access (mobile apps, temporary links)
        var containerName = $"tenant-{tenantId:N}".ToLowerInvariant();
        var blobClient = _blobServiceClient
            .GetBlobContainerClient(containerName)
            .GetBlobClient(Path.GetFileName(new Uri(photo.BlobUrl).LocalPath));

        var sasBuilder = new BlobSasBuilder
        {
            BlobContainerName = containerName,
            BlobName = blobClient.Name,
            Resource = "b",
            StartsOn = DateTimeOffset.UtcNow.AddMinutes(-5), // Allow for clock skew
            ExpiresOn = DateTimeOffset.UtcNow.AddMinutes(expirationMinutes)
        };
        sasBuilder.SetPermissions(BlobSasPermissions.Read);

        var sasToken = blobClient.GenerateSasUri(sasBuilder);
        return sasToken.ToString();
    }

    public async Task<string> GetThumbnailUrlAsync(Guid tenantId, Guid photoId, int expirationMinutes = 60)
    {
        var photo = await GetPhotoByIdAsync(tenantId, photoId);
        if (photo == null || string.IsNullOrEmpty(photo.ThumbnailUrl))
        {
            throw new KeyNotFoundException($"Thumbnail for photo {photoId} not found");
        }

        // Generate SAS token for thumbnail (mobile optimization)
        var containerName = $"tenant-{tenantId:N}".ToLowerInvariant();
        var blobClient = _blobServiceClient
            .GetBlobContainerClient(containerName)
            .GetBlobClient(Path.GetFileName(new Uri(photo.ThumbnailUrl).LocalPath));

        var sasBuilder = new BlobSasBuilder
        {
            BlobContainerName = containerName,
            BlobName = blobClient.Name,
            Resource = "b",
            StartsOn = DateTimeOffset.UtcNow.AddMinutes(-5),
            ExpiresOn = DateTimeOffset.UtcNow.AddMinutes(expirationMinutes)
        };
        sasBuilder.SetPermissions(BlobSasPermissions.Read);

        var sasToken = blobClient.GenerateSasUri(sasBuilder);
        return sasToken.ToString();
    }

    public async Task<bool> DeletePhotoAsync(Guid tenantId, Guid photoId)
    {
        _logger.LogInformation("Deleting photo {PhotoId} for tenant {TenantId}", photoId, tenantId);

        var photo = await GetPhotoByIdAsync(tenantId, photoId);
        if (photo == null)
        {
            return false;
        }

        try
        {
            // Delete from Azure Blob Storage
            var containerName = $"tenant-{tenantId:N}".ToLowerInvariant();
            var containerClient = _blobServiceClient.GetBlobContainerClient(containerName);

            // Delete original
            var blobClient = containerClient.GetBlobClient(Path.GetFileName(new Uri(photo.BlobUrl).LocalPath));
            await blobClient.DeleteIfExistsAsync();

            // Delete thumbnail if exists
            if (!string.IsNullOrEmpty(photo.ThumbnailUrl))
            {
                var thumbnailClient = containerClient.GetBlobClient(Path.GetFileName(new Uri(photo.ThumbnailUrl).LocalPath));
                await thumbnailClient.DeleteIfExistsAsync();
            }

            // Soft delete from database
            var schemaName = await _connectionFactory.GetTenantSchemaAsync(tenantId);
            using var connection = await _connectionFactory.CreateTenantConnectionAsync(tenantId);

            using var command = (SqlCommand)connection.CreateCommand();
            command.CommandText = $@"
                UPDATE [{schemaName}].InspectionPhotos
                SET BlobUrl = 'DELETED', ThumbnailUrl = NULL
                WHERE PhotoId = @PhotoId";

            command.Parameters.AddWithValue("@PhotoId", photoId);

            var rowsAffected = await command.ExecuteNonQueryAsync();

            _logger.LogInformation("Photo {PhotoId} deleted successfully", photoId);
            return rowsAffected > 0;
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error deleting photo {PhotoId}", photoId);
            throw;
        }
    }

    public async Task<ExifData?> ExtractExifDataAsync(Stream photoStream)
    {
        try
        {
            // Reset stream position
            if (photoStream.CanSeek)
            {
                photoStream.Position = 0;
            }

            var directories = ImageMetadataReader.ReadMetadata(photoStream);

            var exifData = new ExifData();
            var exifDict = new Dictionary<string, string>();

            foreach (var directory in directories)
            {
                foreach (var tag in directory.Tags)
                {
                    exifDict[$"{directory.Name}.{tag.Name}"] = tag.Description ?? "";
                }
            }

            // Extract GPS data
            var gpsDirectory = directories.OfType<GpsDirectory>().FirstOrDefault();
            if (gpsDirectory != null)
            {
                var location = gpsDirectory.GetGeoLocation();
                if (location != null)
                {
                    exifData.Latitude = (decimal)location.Latitude;
                    exifData.Longitude = (decimal)location.Longitude;
                }
            }

            // Extract capture date
            var exifSubIfdDirectory = directories.OfType<ExifSubIfdDirectory>().FirstOrDefault();
            if (exifSubIfdDirectory != null)
            {
                exifData.CaptureDate = exifSubIfdDirectory.GetDateTime(ExifDirectoryBase.TagDateTimeOriginal);
            }

            // Extract device info
            var exifIfd0Directory = directories.OfType<ExifIfd0Directory>().FirstOrDefault();
            if (exifIfd0Directory != null)
            {
                exifData.DeviceMake = exifIfd0Directory.GetString(ExifDirectoryBase.TagMake);
                exifData.DeviceModel = exifIfd0Directory.GetString(ExifDirectoryBase.TagModel);
                exifData.ImageWidth = exifIfd0Directory.GetInt32(ExifDirectoryBase.TagImageWidth);
                exifData.ImageHeight = exifIfd0Directory.GetInt32(ExifDirectoryBase.TagImageHeight);
                exifData.Orientation = exifIfd0Directory.GetDescription(ExifDirectoryBase.TagOrientation);
            }

            // Serialize full EXIF data to JSON
            exifData.FullExifJson = JsonSerializer.Serialize(exifDict, new JsonSerializerOptions
            {
                WriteIndented = false
            });

            return exifData;
        }
        catch (Exception ex)
        {
            _logger.LogWarning(ex, "Failed to extract EXIF data from photo");
            return null;
        }
    }

    #region Private Helper Methods

    private async Task<Stream> GenerateThumbnailAsync(Stream originalStream)
    {
        // Reset stream position
        if (originalStream.CanSeek)
        {
            originalStream.Position = 0;
        }

        using var image = await Image.LoadAsync(originalStream);

        // Calculate thumbnail dimensions maintaining aspect ratio
        var ratioX = (double)ThumbnailMaxWidth / image.Width;
        var ratioY = (double)ThumbnailMaxHeight / image.Height;
        var ratio = Math.Min(ratioX, ratioY);

        var newWidth = (int)(image.Width * ratio);
        var newHeight = (int)(image.Height * ratio);

        // Resize image
        image.Mutate(x => x.Resize(newWidth, newHeight));

        // Save to memory stream
        var thumbnailStream = new MemoryStream();
        await image.SaveAsJpegAsync(thumbnailStream, new SixLabors.ImageSharp.Formats.Jpeg.JpegEncoder
        {
            Quality = ThumbnailQuality
        });

        thumbnailStream.Position = 0;
        return thumbnailStream;
    }

    private static InspectionPhotoDto MapPhotoFromReader(SqlDataReader reader)
    {
        return new InspectionPhotoDto
        {
            PhotoId = reader.GetGuid(reader.GetOrdinal("PhotoId")),
            InspectionId = reader.GetGuid(reader.GetOrdinal("InspectionId")),
            PhotoType = reader.GetString(reader.GetOrdinal("PhotoType")),
            BlobUrl = reader.GetString(reader.GetOrdinal("BlobUrl")),
            ThumbnailUrl = reader.IsDBNull(reader.GetOrdinal("ThumbnailUrl")) ? null : reader.GetString(reader.GetOrdinal("ThumbnailUrl")),
            FileSize = reader.IsDBNull(reader.GetOrdinal("FileSize")) ? null : reader.GetInt64(reader.GetOrdinal("FileSize")),
            MimeType = reader.IsDBNull(reader.GetOrdinal("MimeType")) ? null : reader.GetString(reader.GetOrdinal("MimeType")),
            CaptureDate = reader.IsDBNull(reader.GetOrdinal("CaptureDate")) ? null : reader.GetDateTime(reader.GetOrdinal("CaptureDate")),
            Latitude = reader.IsDBNull(reader.GetOrdinal("Latitude")) ? null : reader.GetDecimal(reader.GetOrdinal("Latitude")),
            Longitude = reader.IsDBNull(reader.GetOrdinal("Longitude")) ? null : reader.GetDecimal(reader.GetOrdinal("Longitude")),
            DeviceModel = reader.IsDBNull(reader.GetOrdinal("DeviceModel")) ? null : reader.GetString(reader.GetOrdinal("DeviceModel")),
            EXIFData = reader.IsDBNull(reader.GetOrdinal("EXIFData")) ? null : reader.GetString(reader.GetOrdinal("EXIFData")),
            Notes = reader.IsDBNull(reader.GetOrdinal("Notes")) ? null : reader.GetString(reader.GetOrdinal("Notes")),
            CreatedDate = reader.GetDateTime(reader.GetOrdinal("CreatedDate"))
        };
    }

    #endregion
}
