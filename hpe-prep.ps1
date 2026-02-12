# Base directories
$baseDir = "software"
$driversDir = Join-Path $baseDir "drivers"

# Create directories if they do not exist
New-Item -ItemType Directory -Path $driversDir -Force | Out-Null

# Download details
$url = "https://downloads.hpe.com/pub/softlib2/software1/sc-windows/p176556484/v274622/cp068800.exe"
$outFile = Join-Path $driversDir "cp068800.exe"

# Expected SHA256 checksum for the driver
# IMPORTANT: This MUST be obtained from HPE's official website before production use
# Get the official checksum from: https://support.hpe.com/
# To calculate locally after download: (Get-FileHash -Path <file> -Algorithm SHA256).Hash
$expectedHash = ""  # MUST be filled in before enabling verification

Write-Host "Downloading driver from HPE..."
Write-Host "URL: $url"

# Download the file with error handling
try {
    # Use TLS 1.2 for secure download
    [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
    
    Invoke-WebRequest -Uri $url -OutFile $outFile -ErrorAction Stop
    
    Write-Host "Download complete: $outFile"
    
    # Verify file was downloaded and has content
    if (-not (Test-Path $outFile)) {
        throw "Downloaded file not found at expected location"
    }
    
    $fileInfo = Get-Item $outFile
    if ($fileInfo.Length -eq 0) {
        throw "Downloaded file is empty"
    }
    
    Write-Host "File size: $($fileInfo.Length) bytes"
    
    # Calculate and verify checksum
    Write-Host "Calculating SHA256 checksum..."
    $actualHash = (Get-FileHash -Path $outFile -Algorithm SHA256).Hash
    Write-Host "Calculated hash: $actualHash"
    
    # Verify checksum if expected hash is provided
    if (-not [string]::IsNullOrWhiteSpace($expectedHash)) {
        if ($actualHash -ne $expectedHash) {
            Write-Error "❌ CHECKSUM VERIFICATION FAILED!"
            Write-Error "Expected: $expectedHash"
            Write-Error "Got: $actualHash"
            Write-Error "File may be corrupted or compromised. Deleting downloaded file."
            Remove-Item $outFile -Force
            exit 1
        }
        Write-Host "✅ Checksum verification passed"
    } else {
        Write-Warning "⚠️  SECURITY WARNING: Checksum verification is DISABLED"
        Write-Warning "    For production use, obtain the official SHA256 hash from HPE at:"
        Write-Warning "    https://support.hpe.com/"
        Write-Warning "    Current file hash: $actualHash"
        Write-Warning "    Add this hash to `$expectedHash variable to enable verification"
    }
    
} catch {
    Write-Error "Failed to download or verify driver: $_"
    if (Test-Path $outFile) {
        Remove-Item $outFile -Force -ErrorAction SilentlyContinue
    }
    exit 1
}

Write-Host "Driver ready at: $outFile"
Write-Warning "Please verify the file integrity before installation!"

