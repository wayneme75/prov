#Define the subscription where you want to register your machine as Arc device
$Subscription = (get-azcontext).subscription.id

#Define the resource group where you want to register your machine as Arc device
do {
    $RG = Read-Host "Enter Resource Group name"
} while ([string]::IsNullOrWhiteSpace($RG))

#Define the region to use to register your server as Arc device
#Do not use spaces or capital letters when defining region
$Region = "usgovvirginia"

#Define the tenant you will use to register your machine as Arc device
$Tenant = (get-azcontext).tenant.id

#Connect to your Azure account and Subscription
try {
    Connect-AzAccount -SubscriptionId $Subscription -TenantId $Tenant -DeviceCode -environment "AzureUSGovernment" -ErrorAction Stop
} catch {
    Write-Error "Failed to connect to Azure account: $_"
    exit 1
}

#Get the Access Token for the registration
try {
    $ARMtoken = (Get-AzAccessToken -WarningAction SilentlyContinue -ErrorAction Stop).Token
} catch {
    Write-Error "Failed to get Azure Access Token: $_"
    exit 1
}

$armTokenType = $ARMtoken.GetType().Name
if ($armTokenType -eq 'SecureString') {
    Write-Warning "Token acquired is SecureString. Converting to plain string. WARNING: Token will be in memory as plain text."
    $ARMtoken = [System.Net.NetworkCredential]::new("", $ARMtoken).Password
} else {
    Write-Warning "Token is in plain text. Ensure this script is run in a secure environment and logs are protected."
}

#Get the Account ID for the registration
$id = (Get-AzContext).Account.Id

if ([string]::IsNullOrWhiteSpace($id)) {
    Write-Error "Failed to get Account ID from Azure context"
    exit 1
}

#Invoke the registration script. Use a supported region.
try {
    Invoke-AzStackHciArcInitialization -SubscriptionID $Subscription -ResourceGroup $RG -TenantID $Tenant -Region $Region -Cloud "AzureUSGovernment" -ArmAccessToken $ARMtoken -AccountID $id -ErrorAction Stop
} catch {
    Write-Error "Failed to initialize Arc registration: $_"
    exit 1
} finally {
    # Clear sensitive token from memory
    if ($ARMtoken) {
        Clear-Variable -Name ARMtoken -ErrorAction SilentlyContinue
    }
}

Write-Host "Arc initialization completed successfully"
 
