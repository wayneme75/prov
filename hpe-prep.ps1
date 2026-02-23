# Simple script to download and install HPE drivers for Azure Stack HCI nodes
# Updates the drivers on the NIC so that they are optimized for Azure Stack HCI
# Creates a Azure Local administrative account for AD Less install

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

# Prepare local Admin for AD Less install
# Variables
$Username = read-Host "Enter new admin name"
$Password = Read-Host "Enter password" -AsSecureString
$Description = "Azure Local administrative account"

# Create local user
New-LocalUser `
    -Name $Username `
    -Password $Password `
    -FullName $Username `
    -Description $Description `
    -PasswordNeverExpires `
    -AccountNeverExpires

# Add user to local Administrators group
Add-LocalGroupMember `
    -Group "Administrators" `
    -Member $Username

Write-Host "Local admin user '$Username' created and added to Administrators group."

Set-Location $driversDir

# Run the downloaded executable with silent install parameters
Start-Process -FilePath ".\cp068800.exe"

# Run pnputil to add drivers to the driver store
pnputil /add-driver .\* /subdirs /install

Write-Host "Driver installation process initiated."

# Get Network Adapters driver provider
$networkAdapters = get-NetAdapter | Select-Object name, driverprovider
Write-Host "Network Adapters and their Driver Providers:"
$networkAdapters | ForEach-Object {
    Write-Host "Adapter: $($_.name) - Driver Provider: $($_.driverprovider)"
}
