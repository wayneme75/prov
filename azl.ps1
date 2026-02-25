#Define the subscription where you want to register your machine as Arc device
$Subscription = (get-azcontext).subscription.id

#Define the resource group where you want to register your machine as Arc device
do {
    $RG = Read-Host "Enter Resource Group name"
} while ([string]::IsNullOrWhiteSpace($RG))

#Define the region to use to register your server as Arc device
#Do not use spaces or capital letters when defining region
do {
    $EnvironmentSelection = Read-Host "Select Azure environment (1 = Azure Commercial, 2 = Azure Government)"
} while ($EnvironmentSelection -notin @('1', '2'))

switch ($EnvironmentSelection) {
    '1' {
        $AzEnvironment = "AzureCloud"
        $ArcCloud = "AzureCloud"
        $Region = "eastus"
    }
    '2' {
        $AzEnvironment = "AzureUSGovernment"
        $ArcCloud = "AzureUSGovernment"
        $Region = "usgovvirginia"
    }
}

#Define the tenant you will use to register your machine as Arc device
$Tenant = (get-azcontext).tenant.id

#Connect to your Azure account and Subscription
Connect-AzAccount -SubscriptionId $Subscription -TenantId $Tenant -DeviceCode -Environment $AzEnvironment

#Get the Access Token for the registration
$ARMtoken = (Get-AzAccessToken -WarningAction SilentlyContinue).Token

$armTokenType = $ARMtoken.GetType().Name
if ($armTokenType -eq 'SecureString') {
    Write-Host "Token acquired is SecureString. Converting to plain string"
    $ARMtoken = [System.Net.NetworkCredential]::new("", $ARMtoken).Password
}

#Get the Account ID for the registration
$id = (Get-AzContext).Account.Id

#Invoke the registration script. Use a supported region.
Invoke-AzStackHciArcInitialization -SubscriptionID $Subscription -ResourceGroup $RG -TenantID $Tenant -Region $Region -Cloud $ArcCloud -ArmAccessToken $ARMtoken -AccountID $id
 
