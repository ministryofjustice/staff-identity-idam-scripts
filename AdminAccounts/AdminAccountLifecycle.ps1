param(
    [switch]$Disable,
    [switch]$Delete
)

$workingDir = $MyInvocation.MyCommand.Path
$index = $workingDir.LastIndexOf('\')
$workingDir = $workingDir.Substring(0, $index)
$dateTime = (Get-Date -Format s) -replace "[\-T\:]",""
$logPath = "$workingDir\AdminAccountLifecycle-$dateTime.log"
$disabledUserPath = "$workingDir\AdminAccountLifecycleDisabledUsers.csv"

function Write-LogFile {
    param(
        [Parameter(Mandatory=$true)]
        [string]$Path,

        [Parameter(Mandatory=$true)]
        [ValidateSet("Information","Warning","Error")]
        [string]$Type,

        [Parameter(Mandatory=$true)]
        [string]$Message
    )

    $dateTime = Get-Date -Format s
    $line = "$dateTime`t$Type`t$UserPrincipalName`t$Message"
    try {
        $line | Out-File $Path -Append -ErrorAction Stop
    } catch {
        "$line [$($_.Exception.Message)]"
    }
}
function Get-EntraIdAdminAccount {
    $roles = @()
    $adminUsers = @{}
    $roleCount = 0

    try {
        $roles += Get-MgRoleManagementDirectoryRoleDefinition -All -ErrorAction Stop
    } catch {
        Write-LogFile -Path $logPath -Type Error -Message "Failed to get role definitions. $($_.Exception.Message)"
        exit
    }

    foreach ($role in $roles) {
        $roleCount++

        Write-Progress -Activity "Entra ID Roles" -Status "Role $roleCount of $($roles.Count)" -PercentComplete (($roleCount / $roles.Count) * 100) -CurrentOperation $role.DisplayName -Id 0

        if ($role.DisplayName -eq "Guest User" -or $role.DisplayName -eq "User") {
            continue
        }

        $assignments = @()
        $assignmentCount = 0

        try {
            $assignments += Get-MgRoleManagementDirectoryRoleAssignment -Filter "roleDefinitionId eq '$($role.Id)'" -ErrorAction Stop
        } catch {
            Write-LogFile -Path $logPath -Type Error -Message "Failed to get role assignments for $($role.DisplayName). $($_.Exception.Message)"
            continue
        }

        foreach ($assignment in $assignments) {
            $assignmentCount++

            Write-Progress -Activity "Role assignments" -Status "Assignment $assignmentCount of $($assignments.Count)" -PercentComplete (($assignmentCount / $assignments.Count) * 100) -Id 1 -ParentId 0

            $user = $null
            $group = $null

            if ($adminUsers.ContainsKey($assignment.PrincipalId) -eq $false) {
                $user = Get-MgUser -UserId $assignment.PrincipalId -Property DisplayName,UserPrincipalName,Id,SignInActivity,AccountEnabled -ErrorAction SilentlyContinue | Select-Object Id,DisplayName,AccountEnabled,UserPrincipalName,@{Name="LastSignInDateTime"; Expression={ $_.SignInActivity.LastSignInDateTime }},@{Name="LastSuccessfulSignInDateTime"; Expression={ $_.SignInActivity.LastSuccessfulSignInDateTime }},@{Name="LastNonInteractiveSignInDateTime"; Expression={ $_.SignInActivity.LastNonInteractiveSignInDateTime }}

                if ($null -eq $user) {
                    $group = Get-MgGroup -GroupId $assignment.PrincipalId -ErrorAction SilentlyContinue
                }

                if ($null -ne $group) {
                    $members = @()
                    $memberCount = 0

                    
                    try {
                        $members += Get-MgGroupMember -GroupId $assignment.PrincipalId -ErrorAction Stop
                    } catch {
                        Write-LogFile -Path $logPath -Type Error -Message "Failed to get group members for $($group.DisplayName) - $($assignment.PrincipalId). $($_.Exception.Message)"
                    }
                    
                    foreach ($member in $members) {
                        $memberCount++
                        
                        Write-Progress -Activity "Group $($group.DisplayName)" -Status "Group member $memberCount of $($members.Count)" -PercentComplete (($memberCount / $members.Count) * 100) -Id 2 -ParentId 1
        
                        if ($adminUsers.ContainsKey($member.Id) -eq $false) {
                            $user = $null

                            try {
                                $user = Get-MgUser -UserId $member.Id -Property DisplayName,UserPrincipalName,Id,SignInActivity,AccountEnabled -ErrorAction Stop | Select-Object Id,DisplayName,AccountEnabled,UserPrincipalName,@{Name="LastSignInDateTime"; Expression={ $_.SignInActivity.LastSignInDateTime }},@{Name="LastSuccessfulSignInDateTime"; Expression={ $_.SignInActivity.LastSuccessfulSignInDateTime }},@{Name="LastNonInteractiveSignInDateTime"; Expression={ $_.SignInActivity.LastNonInteractiveSignInDateTime }}
                            } catch {
                                Write-LogFile -Path $logPath -Type Error -Message "Failed to get user $($member.Id) in group $($group.DisplayName). $($_.Exception.Message)"
                            }

                            if ($null -ne $user) {
                                $adminUsers.Add($member.Id, $user)
                            }
                        }
                    }
                } elseif ($null -ne $user) {
                    $adminUsers.Add($assignment.PrincipalId, $user)
                }
            }
        }
    }

    $userList = @()

    foreach ($principalId in $adminUsers.Keys) {
        $userList += $adminUsers[$principalId]
    }

    return $userList
}

try {
    Connect-MgGraph -Scopes "User.ReadWrite.All","AuditLog.Read.All" -NoWelcome -ErrorAction Stop
} catch {
    Write-LogFile -Path $logPath -Type Error -Message "Failed to login to Microsoft Graph. $($_.Exception.Message)"
    exit
}

$disabledUsers = @{}
$users = @()
$users += Get-EntraIdAdminAccount
$lastSignInDate = (Get-Date).AddDays(-365)

try {
    $importedUsers = Import-Csv $disabledUserPath -ErrorAction Stop
    $importedUsers | ForEach-Object {
        if ($disabledUsers.ContainsKey($_.UserPrincipalName) -eq $false) {
            $disabledUsers.Add($_.UserPrincipalName, $_)
        }
    }
} catch {
    Write-LogFile -Path $logPath -Type Error -Message "Failed to import disabled users from '$disabledUserPath'. $($_.Exception.Message)"
}

foreach ($user in $users) {
    try {
        if ($user.SignInActivity.LastNonInteractiveSignInDateTime -ge $lastSignInDate -or
            $user.SignInActivity.LastSignInDateTime -ge $lastSignInDate -or
            $user.SignInActivity.LastSuccessfulSignInDateTime -ge $lastSignInDate) {
            Write-LogFile -Path $logPath -Type Information -Message "Skipping $($user.UserPrincipalName) as last signin is after $lastSignInDate"
            continue
        }
    } catch {
        Write-LogFile -Path $logPath -Type Error -Message "Unable to find user $($user.UserPrincipalName). $($_.Exception.Message)"
        continue
    }

    if ($Disable.IsPresent) {
        try {
            if ($user.AccountEnabled -eq $true) {
                if ($user.OnPremisesSyncEnabled -eq $false) {
                    Update-MgUser -UserId $user.Id -AccountEnabled $false -ErrorAction Stop

                    $disabledUsers[$user.UserPrincipalName].DateDisabled = Get-Date
                    $disabledUsers[$user.UserPrincipalName].UserPrincipalName = $user.UserPrincipalName

                    Write-LogFile -Path $logPath -Type Information -Message "User account $($user.UserPrincipalName) has been disabled"
                } else {
                    Write-LogFile -Path $logPath -Type Warning -Message "User account $($user.UserPrincipalName) is synced with Active Directory, unable to disable it via Graph"
                }
            } else {
                Write-LogFile -Path $logPath -Type Information -Message "User account $($user.UserPrincipalName) is already disabled"
                if ($user.OnPremisesSyncEnabled -eq $false) {
                    if ($disabledUsers.ContainsKey($user.UserPrincipalName) -eq $false) {
                        $disabledUsers[$user.UserPrincipalName].DateDisabled = Get-Date
                        $disabledUsers[$user.UserPrincipalName].UserPrincipalName = $user.UserPrincipalName
                    }
                }
            }
        } catch {
            Write-LogFile -Path $logPath -Type Error -Message "Failed to disable user account $($user.UserPrincipalName). $($_.Exception.Message)"
        }
    }

    if ($Delete.IsPresent) {

    }
}
