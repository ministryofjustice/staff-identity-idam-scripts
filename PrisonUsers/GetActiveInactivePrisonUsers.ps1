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
try {
    $users += Import-Csv $Path -ErrorAction Stop
} catch {
    "Failed to import in users. $($_.Exception.Message)"
    exit
}

foreach ($user in $users) {
    try {
        $account = Get-MgUser -Filter "userPrincipalName eq '$($user.UserPrincipalName)'" -Property Id,DisplayName,UserPrincipalName,SignInActivity,AccountEnabled -ErrorAction Stop
    } catch {
        "Failed to get $($user.UserPrincipalName). $($_.Exception.Message)"
        continue
    }

    if ($account.SignInActivity.LastNonInteractiveSignInDateTime -gt $lastSignInDateTime -or
        $account.SignInActivity.LastSignInDateTime -gt $lastSignInDateTime -or
        $account.SignInActivity.LastSuccessfulSignInDateTime -gt $lastSignInDateTime) {
        try {
            $account | Select-Object Id,DisplayName,UserPrincipalName,AccountEnabled,@{Name="LastNonInteractiveSignInDateTime"; Expression={$_.SignInActivity.LastNonInteractiveSignInDateTime}},@{Name="LastSignInDateTime"; Expression={$_.SignInActivity.LastSignInDateTime}},@{Name="LastSuccessfulSignInDateTime"; Expression={$_.SignInActivity.LastSuccessfulSignInDateTime}} | Export-Csv $ActivePath -NoTypeInformation -Append -ErrorAction Stop
        } catch {
            "Failed to export active user to $ActivePath. $($_.Exception.Message)"
            continue
        }
    } else {
        try {
            $account | Select-Object Id,DisplayName,UserPrincipalName,AccountEnabled,@{Name="LastNonInteractiveSignInDateTime"; Expression={$_.SignInActivity.LastNonInteractiveSignInDateTime}},@{Name="LastSignInDateTime"; Expression={$_.SignInActivity.LastSignInDateTime}},@{Name="LastSuccessfulSignInDateTime"; Expression={$_.SignInActivity.LastSuccessfulSignInDateTime}} | Export-Csv $InactivePath -NoTypeInformation -Append -ErrorAction Stop
        } catch {
            "Failed to export inactive user to $InactivePath. $($_.Exception.Message)"
            continue
        }
    }
}
