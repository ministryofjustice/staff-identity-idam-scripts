<#
.SYNOPSIS
Connects to Microsoft Graph (MG) using application registration with client credentials.

.DESCRIPTION
The `Connect-MgGraphViaAppReg` function connects to Microsoft Graph (MG) by obtaining an access token
using application registration with client credentials flow. This function is typically used in scenarios
where you want to automate tasks that require accessing Microsoft Graph resources without user interaction.

.PARAMETER ClientId
Specifies the client ID (Application ID) of the registered application in Entra ID.
This parameter is mandatory and requires a valid client ID.

.PARAMETER ClientSecret
Specifies the client secret (Application secret) of the registered application in Entra ID.
This parameter is mandatory and requires a valid client secret.

.PARAMETER TenantId
Specifies the directory (tenant) ID of the Azure Entra ID tenant where the registered application is located.
This parameter is mandatory and requires a valid tenant ID.

.EXAMPLE
Connect-MgGraphViaAppReg -ClientId "12345678-abcd-1234-abcd-1234567890ab" -ClientSecret "myClientSecret" -TenantId "abcdefgh-abcd-abcd-abcd-abcdefghijkl"

Connects to Microsoft Graph using the specified application registration credentials.

.NOTES
This function requires the "Connect-MgGraph" function to be available, which is not provided in this script.
Please ensure that the "Connect-MgGraph" function is available in your PowerShell session before using this function.
This can be found by installing and importing v2.0+ of the Microsoft.Graph PowerShell module

.LINK
https://docs.microsoft.com/en-us/graph/overview
#>
function Connect-MgGraphViaAppReg {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [String]$ClientId,

        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [String]$ClientSecret,

        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [String]$TenantId
    )

    try {
        # Connection details for MS Graph
        $body = @{
            Grant_Type    = "client_credentials"
            Scope         = "https://graph.microsoft.com/.default"
            Client_Id     = $ClientId
            Client_Secret = $ClientSecret
        }

        $connection = Invoke-RestMethod `
            -Uri https://login.microsoftonline.com/$TenantId/oauth2/v2.0/token `
            -Method POST `
            -Body $body

        $token = $connection.access_token | Out-Null

        Write-Verbose "Connecting to Microsoft Graph using the provided Client ID and Secret"
        Connect-MgGraph -AccessToken (ConvertTo-SecureString -String $token -AsPlainText) -ErrorAction 'Stop'
    } catch {
        Write-Error "Couldn't connect to MG Graph" -ErrorAction 'Continue'
        throw
    }
}
