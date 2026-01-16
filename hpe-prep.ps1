# Base directories
$baseDir = "software"
$driversDir = Join-Path $baseDir "drivers"

# Create directories if they do not exist
New-Item -ItemType Directory -Path $driversDir -Force | Out-Null

# Download details
$url = "https://downloads.hpe.com/pub/softlib2/software1/sc-windows/p176556484/v274622/cp068800.exe"
$outFile = Join-Path $driversDir "cp068800.exe"

# Download the file
Invoke-WebRequest -Uri $url -OutFile $outFile

Write-Host "Download complete: $outFile"
