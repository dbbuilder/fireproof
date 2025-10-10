using QRCoder;
using BarcodeStandard;
using SkiaSharp;

namespace FireExtinguisherInspection.API.Services;

/// <summary>
/// Implementation of barcode and QR code generation
/// Uses BarcodeLib for Code 128 barcodes and QRCoder for QR codes
/// </summary>
public class BarcodeGeneratorService : IBarcodeGeneratorService
{
    private readonly ILogger<BarcodeGeneratorService> _logger;

    public BarcodeGeneratorService(ILogger<BarcodeGeneratorService> logger)
    {
        _logger = logger;
    }

    /// <summary>
    /// Generate a Code 128 barcode as base64-encoded PNG
    /// </summary>
    public string GenerateBarcode(string data)
    {
        try
        {
            if (string.IsNullOrWhiteSpace(data))
                throw new ArgumentException("Barcode data cannot be empty", nameof(data));

            var barcode = new Barcode();
            barcode.IncludeLabel = true;

            // Generate barcode image (Code 128 format)
            using var image = barcode.Encode(
                BarcodeStandard.Type.Code128,
                data,
                SKColors.Black,
                SKColors.White,
                400,
                150
            );

            return ConvertSkImageToBase64(image);
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error generating barcode for data: {Data}", data);
            throw;
        }
    }

    /// <summary>
    /// Generate a QR code as base64-encoded PNG
    /// </summary>
    public string GenerateQrCode(string data)
    {
        try
        {
            if (string.IsNullOrWhiteSpace(data))
                throw new ArgumentException("QR code data cannot be empty", nameof(data));

            using var qrGenerator = new QRCodeGenerator();
            using var qrCodeData = qrGenerator.CreateQrCode(data, QRCodeGenerator.ECCLevel.Q);
            using var qrCode = new PngByteQRCode(qrCodeData);

            var pngBytes = qrCode.GetGraphic(20);
            return $"data:image/png;base64,{Convert.ToBase64String(pngBytes)}";
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error generating QR code for data: {Data}", data);
            throw;
        }
    }

    /// <summary>
    /// Generate both barcode and QR code
    /// </summary>
    public (string Barcode, string QrCode) GenerateBoth(string data)
    {
        var barcode = GenerateBarcode(data);
        var qrCode = GenerateQrCode(data);
        return (barcode, qrCode);
    }

    /// <summary>
    /// Validate barcode data format
    /// Code 128 supports ASCII characters 0-127
    /// </summary>
    public bool IsValidBarcodeData(string data)
    {
        if (string.IsNullOrWhiteSpace(data))
            return false;

        // Code 128 supports ASCII 0-127
        // Check max length (typically 80 characters)
        if (data.Length > 80)
            return false;

        // Ensure all characters are valid ASCII
        return data.All(c => c >= 0 && c <= 127);
    }

    /// <summary>
    /// Convert SKImage to base64 data URI
    /// </summary>
    private string ConvertSkImageToBase64(SKImage image)
    {
        using var data = image.Encode(SKEncodedImageFormat.Png, 100);
        var bytes = data.ToArray();
        var base64 = Convert.ToBase64String(bytes);
        return $"data:image/png;base64,{base64}";
    }
}
