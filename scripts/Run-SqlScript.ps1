param(
    [string]$ScriptPath = "seed-inspections-direct.sql"
)

$connectionString = "Server=sqltest.schoolvision.net,14333;Database=FireProofDB;User Id=sv;Password=Gv51076!;TrustServerCertificate=True;Connection Timeout=30"
$connection = New-Object System.Data.SqlClient.SqlConnection($connectionString)

try {
    Write-Host "Connecting to database..."
    $connection.Open()
    Write-Host "Connected successfully"

    Write-Host "Reading SQL script: $ScriptPath"
    $sqlContent = Get-Content -Path $ScriptPath -Raw

    # Split by GO statements and execute each batch
    $batches = $sqlContent -split '\r?\nGO\r?\n'

    foreach ($batch in $batches) {
        if ($batch.Trim() -ne "") {
            Write-Host "Executing batch..."
            $command = $connection.CreateCommand()
            $command.CommandText = $batch
            $command.CommandTimeout = 60

            try {
                $result = $command.ExecuteNonQuery()
                Write-Host "  Rows affected: $result"
            } catch {
                Write-Host "  Error in batch: $($_.Exception.Message)"
            }
        }
    }

    Write-Host "`nSQL script executed successfully"
} catch {
    Write-Host "Error: $($_.Exception.Message)"
    exit 1
} finally {
    if ($connection.State -eq 'Open') {
        $connection.Close()
        Write-Host "Connection closed"
    }
}
