[CmdletBinding()]
param (
    [Parameter(Mandatory = $false)]
    [ValidateNotNullOrEmpty()]
    [String]$CompanyName,

    [Parameter(Mandatory = $false)]
    [ValidateNotNullOrEmpty()]
    [String]$DemandNumber,

    [Parameter(Mandatory = $false)]
    [ValidateNotNullOrEmpty()]
    [String]$Department,

    [Parameter(Mandatory = $false)]
    [ValidatePattern("^svc_[A-Za-z]{2,}_[A-Z]{2,}_[A-Za-z0-9-]+$")]
    [String]$SvcAccountDisplayName,

    [Parameter(Mandatory = $false)]
    [ValidateNotNullOrEmpty()]
    [String]$Tenant,

    [Parameter(Mandatory = $false)]
    [ValidateNotNullOrEmpty()]
    [String]$ToRecipient
)

try {
    Write-Output "`e[32mStarting Script`e[0m"

    Write-Output "`e[33mInstalling Modules`e[0m"
    # Check if the Microsoft.Graph module is installed and install version 2.26.1 if not
    if (-not (Get-Module -ListAvailable -Name Microsoft.Graph)) {
        # Module is not installed, install version 2.26.1
        Install-Module -Name Microsoft.Graph -RequiredVersion 2.26.1 -Force -Scope CurrentUser
        Write-Output "`e[32mMicrosoft.Graph version 2.26.1 has been installed.`e[0m"
    } else {
        Write-Output "`e[31mMicrosoft.Graph module is already installed.`e[0m"
    }

    # Import the Microsoft.Graph module
    Import-Module -Name Microsoft.Graph -RequiredVersion 2.26.1 -Force
    Write-Output "`e[32mMicrosoft.Graph module version 2.26.1 has been imported.`e[0m"

    Import-Module ".\PSHelperFunctions" -Force
    Write-Output "`e[32mPSHelperFunctions has been installed`e[0m"

    
    $param = @{
        ClientId = $clientId
        ClientSecret = $clientSecret
        TenantId = $tenantId
    }

    $token = Connect-MgGraphViaAppReg @param

    Write-Output "`e[34mConnecting to Azure via Graph`e[0m"
    Connect-MgGraphViaAppReg @param

    $serviceAccountParams = @{
        DisplayName = $SvcAccountDisplayName
        Department  = $Department
        CompanyName = $CompanyName
        Tenant      = $Tenant
    }

    Write-Verbose "`e[33mEntering Service account creation function`e[0m"
    $serviceAccount = New-ServiceAccount @serviceAccountParams


    $sendCredentialsParam = @{
        DemandNumber      = $DemandNumber
        ToRecipient       = $ToRecipient
        UserPrincipalName = $serviceAccount.User.UserPrincipalName
        UserPW            = $serviceAccount.Password
    }

    Write-Verbose "`e[33mEntering Send-ServiceAccountCredentials function`e[0m"
    Write-Output "`e[34mSending email to customers with their credentials`e[0m"
    Send-ServiceAccountCredentials @sendCredentialsParam

} catch {
    throw $_
}
