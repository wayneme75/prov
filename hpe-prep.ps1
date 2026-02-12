# Base directories
$baseDir = "software"
$driversDir = Join-Path $baseDir "drivers"

# Create directories if they do not exist
New-Item -ItemType Directory -Path $driversDir -Force | Out-Null

# Download details
$url = "https://downloads.hpe.com/pub/softlib2/software1/sc-windows/p176556484/v274622/cp068800.exe"
$outFile = Join-Path $driversDir "cp068800.exe"

# Expected SHA256 checksum for the driver
# TODO: Update this with the actual checksum from HPE's website
# You can find it at: https://support.hpe.com/
$expectedHash = "REPLACE_WITH_ACTUAL_SHA256_HASH_FROM_HPE"

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
    
    # Note: Uncomment the following lines once you have the actual checksum from HPE
    # if ($actualHash -ne $expectedHash) {
    #     Write-Error "❌ CHECKSUM VERIFICATION FAILED!"
    #     Write-Error "Expected: $expectedHash"
    #     Write-Error "Got: $actualHash"
    #     Write-Error "File may be corrupted or compromised. Deleting downloaded file."
    #     Remove-Item $outFile -Force
    #     exit 1
    # }
    
    # Write-Host "✅ Checksum verification passed"
    Write-Warning "SECURITY WARNING: Checksum verification is currently disabled."
    Write-Warning "Please obtain the official SHA256 hash from HPE and update the script."
    Write-Warning "Current hash: $actualHash"
    
} catch {
    Write-Error "Failed to download or verify driver: $_"
    if (Test-Path $outFile) {
        Remove-Item $outFile -Force -ErrorAction SilentlyContinue
    }
    exit 1
}

Write-Host "Driver ready at: $outFile"
Write-Warning "Please verify the file integrity before installation!"

