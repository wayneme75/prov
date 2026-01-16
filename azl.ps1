#Define the subscription where you want to register your machine as Arc device
$Subscription = "d62632fb-a5fe-4357-bb36-d5210e2194b9"

#Define the resource group where you want to register your machine as Arc device
$RG = "ciu-rg"

#Define the region to use to register your server as Arc device
#Do not use spaces or capital letters when defining region
$Region = "usgovvirginia"

#Define the tenant you will use to register your machine as Arc device
$Tenant = "1407d530-e6b2-4712-a1fc-a484b3636faa"

#Connect to your Azure account and Subscription
Connect-AzAccount -SubscriptionId $Subscription -TenantId $Tenant -DeviceCode -environment "AzureUSGovernment"

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
Invoke-AzStackHciArcInitialization -SubscriptionID $Subscription -ResourceGroup $RG -TenantID $Tenant -Region $Region -Cloud "AzureUSGovernment" -ArmAccessToken $ARMtoken -AccountID $id
 