<#
    .SYNOPSIS
    A script to confirm inactive users.
     
    .DESCRIPTION
    This script comapres inactive users in the Visor group against a list of users from a CSV.
#>
[CmdletBinding()]
param (
    [Parameter(Mandatory = $false)]
    [String]$InactiveUsersCsv,
    
    [Parameter(Mandatory = $false)]
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
[Array]$inactiveUsersFromCSV = Import-Csv -Path $InactiveUsersCsv

try {
    # Get properties of all Visor group members
    Write-Host "Getting the members of the Visor group. This will take some time..." -ForegroundColor Yellow
    [Array]$visorGroupMembers = Get-ADGroup $groupName -Properties Member | Select-Object -ExpandProperty Member | Get-ADObject -Properties *

} catch {
    Write-Error "Could not get group members of group $groupName" -ErrorAction Continue
    throw $_
}


function Get-AllInactiveUsers {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true)]
        [Array]$VisorGroupMembers
    )

    # Replace 'username' with the actual username or SAMAccountName
    $count = 1
    $inactiveVisorUsersFromGroup = foreach ($user in $visorGroupMembers) {
        write-host "Currently on user [$count/$($visorGroupMembers.Count)]" -ForegroundColor Green
        $currentUser = Get-ADUser -Identity $user.sAMAccountName -Properties * -ErrorAction Cont
        if ($currentUser.Enabled -ne $true) {
                $currentUser
        }

        $count++
    }
    
    return $inactiveVisorUsersFromGroup

}

Write-Host "Getting inactive users from $groupName..." -ForegroundColor Yellow
$inactiveVisorUsersFromGroup = Get-AllInactiveUsers -VisorGroupMembers $visorGroupMembers

Function Compare-InactiveUsers {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true)]
        [Array]$InactiveGroupMembers,

        [Parameter(Mandatory=$true)]
        [Array]$InactiveUsersFromCSV
    )
    
    # Create a hash table for faster lookup
    $emailLookup = @{}
    foreach ($csvUser in $InactiveUsersFromCSV) {
        $emailLookup[$csvUser.Email] = $true
    }

    $count = 1
    $matchingUsers = @()
    
    foreach ($user in $InactiveGroupMembers) {
        Write-Host "Comparing user [$count/$($InactiveGroupMembers.Count)]" -ForegroundColor Green
        if ($emailLookup.ContainsKey($user.mail)) {
            $matchingUsers += $user
        }

        $count++
    }

    return $matchingUsers
}

Write-Host "Comparing Inactive Visor group members to the Email addresses from the CSV..." -ForegroundColor Yellow
$matchingInactiveUsers = Compare-InactiveUsers -InactiveGroupMembers $inactiveVisorUsersFromGroup -InactiveUsersFromCSV $inactiveUsersFromCSV

Write-Host "Writing all Matching InactiveUsers to CSV..." -ForegroundColor Magenta
$matchingInactiveUsers | Select-Object -Property EmailAddress | Export-Csv -Path $ExportPath -NoTypeInformation
