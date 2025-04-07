<#
    .SYNOPSIS
    A script to remove users from a group.
     
    .DESCRIPTION
    This script removes users from the Visor group, which have been imported from a CSV
#>
[CmdletBinding()]
param (
    [Parameter(Mandatory = $false)]
    [String]$ImportPath = "",

    [Parameter(Mandatory = $false)]
    [String]$ExportPath = ""
)

# Module Imports
if (-not (Get-Module -ListAvailable -Name "ActiveDirectory" )) {
    # Active Directory Module is not installed
    Install-Module -Name "ActiveDirectory" -Force -Scope CurrentUser
    Write-Host "ActiveDirectory Module has been installed." -ForegroundColor Green
} else {
    Write-Host "ActiveDirectory Module is already installed." -ForegroundColor Yellow
}

try {
    Write-Host "Importing ActiveDirectory Module..." -ForegroundColor Yellow
    Import-Module -Name "ActiveDirectory" -ErrorAction Stop
    Write-Host "ActiveDirectory module imported" -ForegroundColor Green
} catch {
    Write-Error "Failed to install ActiveDirectory Module" -ErrorAction Continue
    throw $_
}

# Global Vars
[String]$groupName = "appl-xdc-g-visor"
[Array]$userList = Import-Csv -Path $ImportPath

# Get properties of all Visor group members
try {
    Write-Host "Getting the members of the Visor group. This will take some time..." -ForegroundColor Yellow
    [Array]$visorGroupMembers = Get-ADGroup $groupName -Properties Member | Select-Object -ExpandProperty Member | Get-ADObject -Properties *
    Write-Host "Successfully got members of group: $groupName. Continuing..." -ForegroundColor Green
} catch {
    Write-Error "Could not get memebers of group: $groupName" -ErrorAction Continue
    throw $_
}


function Get-UsersToBeRemoved {
    <#
        .SYNOPSIS
        Gets users to be removed from the specified VISOR group.

        .DESCRIPTION
        Takes users obtained from a CSV import and compares them to the users from the VISOR group.
        If there is a match

        .PARAMETER UserList
        List of users imported from the CSV.

        .PARAMETER VisorGroupMembers
        List of users from the VISOR group specified.

        .OUTPUTS
        System.Array Get-UsersToBeRemoved returns an array of users.
    #>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true)]
        [Array]$UserList,

        [Parameter(Mandatory=$true)]
        [Array]$VisorGroupMembers
    )

    [Array]$matchingUsers = @()
    [Int]$count = 1

    foreach ($user in $VisorGroupMembers) {
        Write-Host "Checking user [$count/$($VisorGroupMembers.Count)]" -ForegroundColor Yellow
        if ($UserList.Email -Contains $user.Mail) {
            Write-Host "$user.Mail is in group: $groupName" -ForegroundColor Magenta
            $matchingUsers += $user
        }

        $count++
    }
    Write-Host "There are $($matchingUsers.Count) to remove from the group" -ForegroundColor Green
    return $matchingUsers
}

Write-Host "Getting list of users that match the Visor group from the input CSV..." -ForegroundColor Yellow
$usersToRemovedFromGroup = Get-UsersToBeRemoved -UserList $userList -VisorGroupMembers $visorGroupMembers

Write-Host "Exporting list of users that match the Visor group from the input CSV to $ExportPath " -ForegroundColor Yellow
$userDetails = $usersToRemovedFromGroup | ForEach-Object { 
    [PSCustomObject]@{
        CN   = $_.CN
        Mail = $_.Mail
    }
 }

$userDetails | Export-Csv -Path $ExportPath -NoTypeInformation

function Remove-UsersFromGroup {
    <#
        .SYNOPSIS
        Removes specified users from the specified VISOR group.

        .DESCRIPTION
        Takes in a list of group members who need to be removed from the speicified group.

        .PARAMETER GroupName
        The name of the group that the users need to be removed from.

        .PARAMETER GroupMembers
        The users who you want to remove from the group in

        .OUTPUTS
        Remove-UsersFromGroup does not return any data.
    #>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true)]
        [String]$GroupName,

        [Parameter(Mandatory=$true)]
        [Array]$GroupMembers
    )

    [Int]$count = 1

    foreach ($user in $GroupMembers) {
        Write-Host "Removing user [$count/$($GroupMembers.Count)]" -ForegroundColor Yellow
        $count++
        try {
            Write-Host "Removing user: $($user.mail) from $GroupName" -ForegroundColor Green
            Remove-ADGroupMember -Identity $groupName -Members $user.sAMAccountName -WhatIf
        } catch {
            Write-Error "Could not remove user: $user from group: $GroupName" -ErrorAction Continue
            throw $_
        }
    }
}

Write-Host "Starting Remove Users From Group Function" -ForegroundColor Yellow
Remove-UsersFromGroup -GroupName $groupName -GroupMembers $usersToRemovedFromGroup

# Get a count of the users to be removed for reporting
$count = 0

$usersToRemovedFromGroup | ForEach-Object { $count++ }
Write-Host "Successfully removed $count from group: $groupName" -ForegroundColor Green
