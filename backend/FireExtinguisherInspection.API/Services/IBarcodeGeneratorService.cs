namespace FireExtinguisherInspection.API.Services;

/// <summary>
/// Service for generating barcodes and QR codes
/// </summary>
public interface IBarcodeGeneratorService
{
    /// <summary>
    /// Generate a Code 128 barcode as base64-encoded PNG
    /// </summary>
    /// <param name="data">Data to encode</param>
    /// <returns>Base64-encoded PNG image</returns>
    string GenerateBarcode(string data);

    /// <summary>
    /// Generate a QR code as base64-encoded PNG
    /// </summary>
    /// <param name="data">Data to encode</param>
    /// <returns>Base64-encoded PNG image</returns>
    string GenerateQrCode(string data);

    /// <summary>
    /// Generate both barcode and QR code
    /// </summary>
    /// <param name="data">Data to encode</param>
    /// <returns>Tuple of (barcode, qrcode) as base64-encoded PNGs</returns>
    (string Barcode, string QrCode) GenerateBoth(string data);

    /// <summary>
    /// Validate barcode data format
    /// </summary>
    bool IsValidBarcodeData(string data);
}
