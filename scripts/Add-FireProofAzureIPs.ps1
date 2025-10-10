# Add-FireProofAzureIPs.ps1
# Adds Azure App Service outbound IPs to Windows Firewall for SQL Server access

# Azure App Service Outbound IPs for fireproof-api-test-2025
$AzureIPs = @(
    "135.224.222.197",
    "135.237.226.77",
    "9.169.150.50",
    "135.237.226.221",
    "135.18.140.226",
    "132.196.212.176",
    "132.196.184.207",
    "135.237.203.153",
    "4.152.150.18",
    "132.196.184.42",
    "52.254.111.153",
    "135.222.182.103",
    "20.119.128.27"
)

Write-Host "Adding Azure App Service IPs to Windows Firewall..." -ForegroundColor Cyan

# SQL Server default port
$SQLPort = 14333

# Create firewall rule for each IP
foreach ($IP in $AzureIPs) {
    $RuleName = "FireProof-Azure-SQL-$($IP.Replace('.', '-'))"

    # Check if rule already exists
    $ExistingRule = Get-NetFirewallRule -DisplayName $RuleName -ErrorAction SilentlyContinue

    if ($ExistingRule) {
        Write-Host "Rule already exists: $RuleName" -ForegroundColor Yellow
        Remove-NetFirewallRule -DisplayName $RuleName
        Write-Host "Removed existing rule: $RuleName" -ForegroundColor Yellow
    }

    # Create new firewall rule
    New-NetFirewallRule `
        -DisplayName $RuleName `
        -Direction Inbound `
        -Protocol TCP `
        -LocalPort $SQLPort `
        -RemoteAddress $IP `
        -Action Allow `
        -Profile Any `
        -Description "Allow Azure App Service (fireproof-api-test-2025) to access SQL Server on port $SQLPort" | Out-Null

    Write-Host "Created rule: $RuleName" -ForegroundColor Green
}

Write-Host "`nWindows Firewall rules created successfully!" -ForegroundColor Green
Write-Host "`nTo view all rules, run:" -ForegroundColor Cyan
Write-Host "Get-NetFirewallRule -DisplayName 'FireProof-Azure-SQL-*' | Format-Table DisplayName, Enabled, Direction, Action" -ForegroundColor Gray

# Test connectivity info
Write-Host "`nTo test SQL connectivity from one of these IPs:" -ForegroundColor Cyan
Write-Host "Test-NetConnection -ComputerName sqltest.schoolvision.net -Port 14333" -ForegroundColor Gray
