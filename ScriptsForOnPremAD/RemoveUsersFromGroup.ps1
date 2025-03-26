[CmdletBinding()]
param (
    [Parameter(Mandatory = $true)]
    [ValidateNotNullOrEmpty()]
    [String]$GroupName,

    [Parameter(Mandatory = $true)]
    [ValidateNotNullOrEmpty()]
    [String]$PathToInputCSV,

    [Parameter(Mandatory = $true)]
    [ValidateNotNullOrEmpty()]
    [String]$PathToOutputCSV
)

Write-Host "Staring Script" -ForegroundColor Green

Write-Host "Installing Modules" -ForegroundColor Blue

# Check if the Microsoft.Entra Module is installed
if (-not (Get-Module -ListAvailable -Name "ActiveDirectory" )) {
    # Module is not installed
    Install-Module -Name "ActiveDirectory" -Force -Scope CurrentUser
    Write-Host "ActiveDirectory Module has been installed." -ForegroundColor Cyan
} else {
    Write-Host "ActiveDirectory Module is already installed." -ForegroundColor Cyan
}

Write-Host "Importing Modules..." -ForegroundColor Yellow
Import-Module -Name "ActiveDirectory"
Write-Host "All Modules Have Been Installed" -ForegroundColor Yellow

# Get all group members and thier properties
try { 
    Write-Host "Getting all members of $GroupName..." -ForegroundColor Green
    $groupMembers = Get-ADGroup $GroupName -Properties Member -ErrorAction Stop | Select-Object -ExpandProperty Member -ErrorAction Stop | Get-ADObject -Properties * -ErrorAction Stop
} catch {
    Write-Error "Could not get all users from group $GroupName" -ErrorAction Continue
    throw $_
}


# Path to CSV containing list of users to remove
try {
    Write-Host "Importing users from CSV..." -ForegroundColor Yellow
    $userList = Import-Csv -Path $PathToInputCSV -ErrorAction Stop
} catch {
    Write-Error "There was an issue importing CSV..." -ErrorAction Continue
    throw $_
}

# Get the email for each user and add it to an array
Write-Host "Getting email address of users in $GroupName..." -ForegroundColor Yellow
$usersToBeRemovedFromGroup = @()
foreach ($user in $userList) {
    $usersToBeRemovedFromGroup += $user.email
}

# Get all users from the group that are in the CSV list
$matchingUsers = @()
foreach ($groupMember in $groupMembers) {
    if ($usersToBeRemovedFromGroup -contains $groupMember.mail) {
        $matchingUsers += $groupMember
    }
}

# Output matching users to the CSV. These are users that were in the CSV input list and in the group
Write-Host "Writing matching users to output CSV in $PathtoOutputCSV..." -ForegroundColor Green
$matchingUsers | Export-Csv -FilePath $PathToOutputCSV
