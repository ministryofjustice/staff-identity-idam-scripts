<#
.SYNOPSIS
This function creates a new service account.

.DESCRIPTION
This creates a new user via Microsoft Graph

Permission Type                         Permission
Application	                            User.ReadWrite.All

You will need to install the MS Graph module 'Install-Module -Name Microsoft.Graph' in your script calling this function.
You will also need to import the following module 'Import-Module -Name Microsoft.Graph.Users.Actions'.
You MUST be logged in to Azure MG Graph (With Connect-MgGraph) before running this function

.PARAMETER SendFrom
This is the email addres in which you want to send the email from.

.PARAMETER Subject
This is the subject of the email that you are sending.

.PARAMETER ContentBody
This is the content of the body of the email that you wish to send.

.PARAMETER ToRecipient
This is the recipients address, who you want to send the email to.

.OUTPUTS
Sends an email to a recipient.

.NOTES
Authored by Jason Gillett 29/06/2023
#>

function New-ServiceAccount {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $false)]
        [array]$Licenses,

        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$CompanyName,

        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$Department,

        [Parameter(Mandatory = $true)]
        [ValidatePattern("^svc_[A-Za-z]{2,}_[A-Z]{2,}_[A-Za-z0-9-]+$")]
        [string]$DisplayName,

        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$Tenant
    )

    # Global Vars
    [string]$jobTitle = "Service Account"
    [string]$employeeType = "Service Account"
    [string]$usageLocation = "GB"
    
    try {

        switch ($Tenant) {
            'DEVL' { [string]$domain = "devl.justice.gov.uk" }
            'NLE' { [string]$domain = "testjusticeuk.onmicrosoft.com" }
            'LIVE' { [string]$domain = "justiceuk.onmicrosoft.com" }
        }
        
        $userPrincipalName = "$($DisplayName)@$($domain)"

        $password = New-SecurePassword

        $passwordProfile = @{
            Password = $password
            ForceChangePasswordNextSignIn = $true
        }

        $param = @{
            DisplayName       = $DisplayName
            CompanyName       = $CompanyName
            Department        = $Department
            EmployeeType      = $employeeType
            JobTitle          = $jobTitle
            PasswordProfile   = $passwordProfile
            UsageLocation     = $usageLocation
            UserPrincipalName = $userPrincipalName
            MailNickname      = $DisplayName
        }
        $user = New-MgUser @param -AccountEnabled -ErrorAction Stop 
        
        return [PSCustomObject]@{
            User     = $user
            Password = $password
        }

    } catch {
        Write-Error "This was a problem creating the service account" -ErrorAction Continue
        throw $_ 
    }
}
