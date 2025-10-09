namespace FireExtinguisherInspection.API.Models.DTOs;

/// <summary>
/// Extinguisher inventory item DTO
/// </summary>
public class ExtinguisherDto
{
    public Guid ExtinguisherId { get; set; }
    public Guid TenantId { get; set; }
    public Guid LocationId { get; set; }
    public Guid ExtinguisherTypeId { get; set; }

    public string ExtinguisherCode { get; set; } = string.Empty;
    public string SerialNumber { get; set; } = string.Empty;
    public string? AssetTag { get; set; }
    public string? Manufacturer { get; set; }
    public DateTime? ManufactureDate { get; set; }
    public DateTime? InstallDate { get; set; }
    public DateTime? LastServiceDate { get; set; }
    public DateTime? NextServiceDueDate { get; set; }
    public DateTime? LastHydroTestDate { get; set; }
    public DateTime? NextHydroTestDueDate { get; set; }

    public string? LocationDescription { get; set; }
    public string? FloorLevel { get; set; }
    public string? Notes { get; set; }

    public string? BarcodeData { get; set; }
    public string? QrCodeData { get; set; }

    public bool IsActive { get; set; }
    public bool IsOutOfService { get; set; }
    public string? OutOfServiceReason { get; set; }

    public DateTime CreatedDate { get; set; }
    public DateTime ModifiedDate { get; set; }

    // Navigation properties (populated from joins)
    public string? LocationName { get; set; }
    public string? TypeName { get; set; }
    public string? TypeCode { get; set; }
}

/// <summary>
/// Request to create a new extinguisher
/// </summary>
public class CreateExtinguisherRequest
{
    public Guid LocationId { get; set; }
    public Guid ExtinguisherTypeId { get; set; }

    public string ExtinguisherCode { get; set; } = string.Empty;
    public string SerialNumber { get; set; } = string.Empty;
    public string? AssetTag { get; set; }
    public string? Manufacturer { get; set; }
    public DateTime? ManufactureDate { get; set; }
    public DateTime? InstallDate { get; set; }

    public string? LocationDescription { get; set; }
    public string? FloorLevel { get; set; }
    public string? Notes { get; set; }
}

/// <summary>
/// Request to update an extinguisher
/// </summary>
public class UpdateExtinguisherRequest
{
    public Guid LocationId { get; set; }
    public Guid ExtinguisherTypeId { get; set; }

    public string SerialNumber { get; set; } = string.Empty;
    public string? AssetTag { get; set; }
    public string? Manufacturer { get; set; }
    public DateTime? ManufactureDate { get; set; }
    public DateTime? InstallDate { get; set; }
    public DateTime? LastServiceDate { get; set; }
    public DateTime? NextServiceDueDate { get; set; }
    public DateTime? LastHydroTestDate { get; set; }
    public DateTime? NextHydroTestDueDate { get; set; }

    public string? LocationDescription { get; set; }
    public string? FloorLevel { get; set; }
    public string? Notes { get; set; }

    public bool IsActive { get; set; }
    public bool IsOutOfService { get; set; }
    public string? OutOfServiceReason { get; set; }
}

/// <summary>
/// Response containing barcode/QR code data
/// </summary>
public class BarcodeResponse
{
    public string BarcodeData { get; set; } = string.Empty;
    public string QrCodeData { get; set; } = string.Empty;
    public string Format { get; set; } = string.Empty;
}
