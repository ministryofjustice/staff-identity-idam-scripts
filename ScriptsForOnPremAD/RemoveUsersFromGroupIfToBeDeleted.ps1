<#
    .SYNOPSIS
    A script to remove users from a group.
     
    .DESCRIPTION
    This script removes users who are in the TO_BE_DELETED OU from a group that you specify.
#>
[CmdletBinding()]
param (
    [Parameter(Mandatory = $true)]
    [String]$ExportPath
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
[Array]$usersToBeRemoved = @()

# Get properties of all Visor group members
Write-Host "Getting the members of the Visor group. This will take some time..." -ForegroundColor Yellow
[Array]$visorGroupMembers = Get-ADGroup $groupName -Properties Member | Select-Object -ExpandProperty Member | Get-ADObject -Properties *

function Get-UsersToBeRemoved {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true)]
        [Array]$GroupMembers
    )
    [Array]$usersToBeRemovedFromVisorGroup = @()
    [Array]$usersExcluded = @()
    [Int]$count = 1

    foreach ($member in $GroupMembers) {
    Write-Host "Checking user [$count/$($GroupMembers.Count)]"
    $count++
    $userInfo = $member.DistinguishedName -split ","

        foreach ($item in $userInfo) {
            if ($item -eq "OU=Inactive" -or $item -eq "OU=Quarantine") {
                $usersExcluded += $member
                break
            }

            if ($item -eq "OU=TO_BE_DELETED") {
                Write-Host "User [$($member.CN)/$($member.Mail)] is a member of [$item]" -ForegroundColor Yellow
                $usersToBeRemovedFromVisorGroup += $member
            }
        }
    }
    Write-Host "There are [$($usersExcluded.Count)] that are exluded" -ForegroundColor Red
    Write-Host "There are [$($usersToBeRemovedFromVisorGroup.Count)] users to be removed from $groupName" -ForegroundColor Green
    return $usersToBeRemovedFromVisorGroup
}

Write-Host "Getting Visor Group members in TO_BE_DELETED_OU..." -ForegroundColor Magenta
$usersToBeRemoved = Get-UsersToBeRemoved -GroupMembers $visorGroupMembers

Write-Host "Sending Visor Group Members to be deleted to CSV at $ExportPath" -ForegroundColor Yellow
$userDetails = $usersToBeRemoved | Select-Object CN, Mail
$userDetails | Export-Csv -Path $ExportPath -NoTypeInformation

function Remove-UsersFromGroup {
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
            Remove-ADGroupMember -Identity $groupName -Members $user.sAMAccountName
        } catch {
            Write-Error "Could not remove user: $user from group: $GroupName" -ErrorAction Continue
            throw $_
        }
    }
}

Write-Host "Starting Remove Users From Group Function" -ForegroundColor Yellow
Remove-UsersFromGroup -GroupName $groupName -GroupMembers $usersToBeRemoved
Write-Host "Successfully removed [$($usersToBeRemoved.Count)] from group: $groupName" -ForegroundColor Green
