[CmdletBinding()]
param (
    [Parameter(Mandatory = $false)]
    [ValidateNotNullOrEmpty()]
    [String]$Path
)

Write-Host "Staring Script" -ForegroundColor Green

Write-Host "Installing Modules" -ForegroundColor Blue

# Check if the Microsoft.Entra Module is installed
if (-not (Get-Module -ListAvailable -Name "Microsoft.Entra" )) {
    # Module is not installed
    Install-Module -Name "Microsoft.Entra" -Force -Scope CurrentUser
    Write-Host "Microsoft.Entra Module has been installed."
} else {
    Write-Host "Microsoft.Entra Module is already installed." -ForegroundColor Cyan
}

Write-Host "Import Modules" -ForegroundColor Yellow
Import-Module -Name "Microsoft.Entra" -Force
Import-Module "..\PSHelperFunctions"
Write-Host "All Modules Have Been Installed" -ForegroundColor Yellow

# Enter your app reg details here
$clientId = ""
$clientSecret = ""
$tenantId = ""

# Get an access token to loging to connect-entra
Write-Host "Generating access token" -ForegroundColor Blue
try {
    $body = @{
        Grant_Type    = "client_credentials"
        Scope         = "https://graph.microsoft.com/.default"
        Client_Id     = $clientId
        Client_Secret = $clientSecret
    }

    $connection = Invoke-RestMethod `
        -Uri https://login.microsoftonline.com/$tenantId/oauth2/v2.0/token `
        -Method POST `
        -Body $body

    $token = $connection.access_token

    Write-Host "Access Token generated..." -ForegroundColor Blue

} catch {
    Write-Error "There was an error getting an access token" -ErrorAction Continue
    throw $_
}

# Log into Entra
Write-host "Logging into entra" -ForegroundColor Green
$secureString = ConvertTo-SecureString -String $token -AsPlainText -Force
Connect-Entra -AccessToken $secureString -NoWelcome
Write-Host "Logged into Entra Continuing..." -ForegroundColor Green

# Get Users from list
$users = [System.Collections.ArrayList]@()

try {
    Write-Host "Importing Users from CSV..." -ForegroundColor Magenta
    $users += Import-Csv $Path -ErrorAction Stop
    Write-Host "Users have been imported..." -ForegroundColor Magenta
} catch {
    "Failed to import in users. $($_.Exception.Message)"
    exit
}

$count = 1
try {
    foreach ($user in $users) {
        Write-Host "Reseting the users Auth methods for $($user.UPN) [$count/$($Users.Count)]" -ForegroundColor Blue
        Reset-EntraStrongAuthenticationMethodByUpn -UserPrincipalName $user.UPN -ErrorAction Stop
        $count++
    }
} catch {
    Write-Error "There was an error reseting the auth method of the user [$user]" -ErrorAction Continue
    throw $_
}

$count = 1
# Once the auth methods have been reset email the users. This is a seperate loop as we do not want to email
# users until we know each users auth methods have been reset 
foreach ($user in $users) {

    # Construct Displayname from UPN
    $nameParts = ($user.UPN -split "@")[0] -split "\."
    $formattedName = $nameParts | ForEach-Object { $_.Substring(0,1).ToUpper() + $_.Substring(1).ToLower() }
    $formattedName = $formattedName -join " "

$emailBody = @"
Hello $formattedName,

We have received a request to reset your MultiFactor Authentication methods, due to a change in device.

Upon your next login, you will be prompted to reconfigure the Microsoft App for 2FA. 

Any issues should be reported to IDAMTeam@justice.gov.uk

Kind Regards
IdAM Team
"@

    $emailDefaultParams = @{
        'ToRecipient'  = $user.UPN
        'Subject'      = "Request to reset 2FA Methods"
        'ContentBody'  = $emailBody
        'SendFrom'     = "IdamAutomation@justice.gov.uk"
    }
    Write-Host "Sending email to user $($user.UPN) [$count/$($Users.Count)]" -ForegroundColor Green
    Send-MGMail @emailDefaultParams -ErrorAction 'Stop'
    $count++

    Start-Sleep 15
}
