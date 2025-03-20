<# 
    .SYNOPSIS
    Script to get list of active and inactive users from a supplied CSV file containing private prison users.

    .DESCRIPTION
    The script gets a CSV file containing a column named UserPrincipalName and queries the user account for sign-in activity.
    User accounts that are enabled and show sign-in activity in the last 90 days are saved to the ActivePath CSV file.
    Disabled accounts or accounts showing greater that 90 days sign-in activity are put in the InactivePath CSV file.
    Checks whether users are in one of four groups, which should identify them as a private prison user.
    If they are not present in any group they are more likely to be MoJ staff.

    .PARAMETER Path
    Path to CSV file containing at least one column with the UserPrincipalName.

    .PARAMETER ActivePath
    Path to CSV file that receives all the active users identitied by the script.

    .PARAMETER InactivePath
    Path to CSV file that receives all the inactive users identitied by the script.

    .EXAMPLE
    PS> GetActiveInactivePrisonUsers.ps1 -Path Users.csv -ActivePath ActiveUsers.csv -InactivePath InactiveUsers.csv
#>

param(
    [Parameter(Mandatory=$true)]
    [string]$Path,
    [Parameter(Mandatory=$true)]
    [string]$ActivePath,
    [Parameter(Mandatory=$true)]
    [string]$InactivePath
)    

$lastSignInDateTime = (Get-Date).AddDays(-90)

try {
    Connect-MgGraph -Scopes "User.Read.All","AuditLog.Read.All" -NoWelcome -ErrorAction Stop
} catch {
    "Failed to login. $($_.Exception.Message)"
    exit
}

$users = @()
$activeUsers = @()
$inactiveUsers = @()
$groupNames = "MoJO-G-Users-AVD-Hostpool01","MoJO-G-Users-AVD-Hostpool02","MoJO-G-Users-AVD-Hostpool03","DELG-MoJO-G-FiveWells-AVD-Access"
$groupMembers = @()
$count = 1

try {
    $users += Import-Csv $Path -ErrorAction Stop
} catch {
    "Failed to import in users. $($_.Exception.Message)"
    exit
}

try {
    foreach ($groupName in $groupNames) {
        $group = Get-MgGroup -Filter "displayName eq '$groupName'" -Property Id,DisplayName -ErrorAction Stop
        $groupMembers += Get-MgGroupMember -GroupId $group.Id -All -ErrorAction Stop | ForEach-Object { $_.Id }
    }
} catch {
    "Failed to get groups and members. $($_.Exception.Message)"
    exit
}

foreach ($user in $users) {
    $privatePrisonUser = $false

    try {
        Write-Host "Currently on user [$count/$($users.Count)]"
        $count++
        $account = Get-MgUser -Filter "userPrincipalName eq '$($user.UserPrincipalName -replace "'","''")'" -Property Id,DisplayName,GivenName,Surname,UserPrincipalName,SignInActivity,AccountEnabled -ErrorAction Stop
    } catch {
        "Failed to get $($user.UserPrincipalName). $($_.Exception.Message)"
        continue
    }

    if ($groupMembers -contains $account.Id) {
        $privatePrisonUser = $true
    }

    if ($account.AccountEnabled -eq $true -and ($account.SignInActivity.LastNonInteractiveSignInDateTime -gt $lastSignInDateTime -or
        $account.SignInActivity.LastSignInDateTime -gt $lastSignInDateTime -or
        $account.SignInActivity.LastSuccessfulSignInDateTime -gt $lastSignInDateTime)) {
        $activeUsers += $account | Select-Object Id,DisplayName,GivenName,Surname,UserPrincipalName,AccountEnabled,@{Name="PrivatePrisonUser"; Expression={$privatePrisonUser}},@{Name="LastNonInteractiveSignInDateTime"; Expression={$_.SignInActivity.LastNonInteractiveSignInDateTime}},@{Name="LastSignInDateTime"; Expression={$_.SignInActivity.LastSignInDateTime}},@{Name="LastSuccessfulSignInDateTime"; Expression={$_.SignInActivity.LastSuccessfulSignInDateTime}}
    } else {
        $inactiveUsers += $account | Select-Object Id,DisplayName,GivenName,Surname,UserPrincipalName,AccountEnabled,@{Name="PrivatePrisonUser"; Expression={$privatePrisonUser}},@{Name="LastNonInteractiveSignInDateTime"; Expression={$_.SignInActivity.LastNonInteractiveSignInDateTime}},@{Name="LastSignInDateTime"; Expression={$_.SignInActivity.LastSignInDateTime}},@{Name="LastSuccessfulSignInDateTime"; Expression={$_.SignInActivity.LastSuccessfulSignInDateTime}}
    }
}

try {
    $activeUsers | Export-Csv $ActivePath -NoTypeInformation -ErrorAction Stop
} catch {
    "Failed to export active users to $ActivePath. $($_.Exception.Message)"
}

try {
    $inactiveUsers | Export-Csv $InactivePath -NoTypeInformation -ErrorAction Stop
} catch {
    "Failed to export inactive users to $InactivePath. $($_.Exception.Message)"
}
