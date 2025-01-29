param(
    [switch]$Disable,
    [switch]$Delete
)

$workingDir = $MyInvocation.MyCommand.Path
$index = $workingDir.LastIndexOf('\')
$workingDir = $workingDir.Substring(0, $index)
$dateTime = (Get-Date -Format s) -replace "[\-T\:]",""
$logPath = "$workingDir\AdminAccountLifecycle-$dateTime.log"
$actionsLogPath = "$workingDir\AdminAccountLifecycleActions-$dateTime.csv"
$disabledUserPath = "$workingDir\AdminAccountLifecycleDisabledUsers.csv"
$workingSetPath = "$workingDir\AdminAccountLifecycleWorkingSet-$dateTime.csv"
$archivePath = "$workingDir\AdminAccountLifecycle-$dateTime.zip"
$lastSignInDate = (Get-Date).AddDays(-365)
$disabledDateTime = (Get-Date).AddDays(-60)

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

function Write-ActionLog {
    param(
        [Parameter(Mandatory=$true)]
        [ValidateSet(Disabled, Deleted)]
        [string]$Action,
        [Parameter(Mandatory=$true)]
        [string]$Id,
        [Parameter(Mandatory=$true)]
        [string]$UserPrincipalName
    )

    $entry = New-Object -TypeName PSCustomObject -Property @{
        DateTime = Get-Date -Format s;
        Action = $Action;
        Id = $Id;
        UserPrincipalName = $UserPrincipalName;
    }

    try {
        $entry | Select-Object DateTime,Action,Id,UserPrincipalName | Export-Csv $actionsLogPath -Append -NoTypeInformation -ErrorAction Stop
    } catch {
        Write-LogFile -Path $logPath -Type Warning -Message "Failed to write to actions log '$actionsLogPath' '$($entry.DateTime),$($entry.Action),$($entry.Id),$($entry.UserPrincipalName)'. $($_.Exception.Message)"
    }
}

function Get-EntraIdAdminAccount {
    $roles = @()
    $adminUsers = @{}
    $adminGroups = @{}
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
                try {
                    $user = Get-MgUser -UserId $assignment.PrincipalId -Property DisplayName,UserPrincipalName,Id,SignInActivity,AccountEnabled -ErrorAction Stop | Select-Object Id,DisplayName,AccountEnabled,UserPrincipalName,@{Name="LastSignInDateTime"; Expression={ $_.SignInActivity.LastSignInDateTime }},@{Name="LastSuccessfulSignInDateTime"; Expression={ $_.SignInActivity.LastSuccessfulSignInDateTime }},@{Name="LastNonInteractiveSignInDateTime"; Expression={ $_.SignInActivity.LastNonInteractiveSignInDateTime }}
                } catch {
                    Write-LogFile -Path $logPath -Type Warning -Message "Failed to get user $($assignment.PrincipalId), could it be a group? $($_.Exception.Message)"
                }

                if ($null -eq $user -and $adminGroups.ContainsKey($assignment.PrincipalId) -eq $false) {
                    try {
                        $group = Get-MgGroup -GroupId $assignment.PrincipalId -ErrorAction Stop
                    } catch {
                        Write-LogFile -Path $logPath -Type Warning -Message "Failed to get group $($assignment.PrincipalId), maybe it is not a user or group? $($_.Exception.Message)"
                    }
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

                        if ($memberCount -eq $members.Count) {
                            Write-Progress -Activity "Group $($group.DisplayName)" -Id 2 -Completed
                        }
                    }

                    $adminGroups.Add($assignment.PrincipalId, $group)
                } elseif ($null -ne $user) {
                    $adminUsers.Add($assignment.PrincipalId, $user)
                }
            }

            if ($assignmentCount -eq $assignments.Count) {
                Write-Progress -Activity "Role assignments" -Id 1 -Completed
            }
        }
    }
    
    Write-Progress -Activity "Entra ID Roles" -Id 0 -Completed

    $userList = @()

    foreach ($principalId in $adminUsers.Keys) {
        $userList += $adminUsers[$principalId]
    }

    return $userList
}

try {
    $scopes = "User.Read.All","AuditLog.Read.All"
    if ($Disable.IsPresent -or $Delete.IsPresent) {
        $scopes = "User.ReadWrite.All","AuditLog.Read.All"
    }

    Connect-MgGraph -Scopes $scopes -NoWelcome -ErrorAction Stop
} catch {
    Write-LogFile -Path $logPath -Type Error -Message "Failed to login to Microsoft Graph. $($_.Exception.Message)"
    exit
}

$disabledUsers = @{}
$users = @()
$users += Get-EntraIdAdminAccount

try {
    if ((Test-Path $disabledUserPath) -eq $true) {
        $importedUsers = Import-Csv $disabledUserPath -ErrorAction Stop
        $importedUsers | ForEach-Object {
            if ($disabledUsers.ContainsKey($_.Id) -eq $false) {
                $disabledUsers.Add($_.Id, $_)
            }
        }
    }
} catch {
    Write-LogFile -Path $logPath -Type Error -Message "Failed to import disabled users from '$disabledUserPath'. $($_.Exception.Message)"
}

$userCount = 0

foreach ($user in $users) {
    $userCount++

    if ($user.LastNonInteractiveSignInDateTime -ge $lastSignInDate -or
        $user.LastSignInDateTime -ge $lastSignInDate -or
        $user.LastSuccessfulSignInDateTime -ge $lastSignInDate) {
        Write-LogFile -Path $logPath -Type Information -Message "Skipping $($user.UserPrincipalName) as last sign-in is after $lastSignInDate"

        if ($disabledUsers.ContainsKey($user.Id)) {
            $disabledUsers.Remove($user.Id)
        }
        continue
    }

    Write-Progress -Activity "Processing admin accounts" -Status "User $userCount of $($users.Count)" -PercentComplete (($userCount / $users.Count) * 100) -CurrentOperation $user.DisplayName -Id 0

    try {
        $user | Select-Object DisplayName,UserPrincipalName,AccountEnabled,Id,LastNonInteractiveSignInDateTime,LastSignInDateTime,LastSuccessfulSignInDateTime | Export-Csv $workingSetPath -NoTypeInformation -Append -ErrorAction Stop
    } catch {
        Write-LogFile -Path $logPath -Type Warning -Message "Failed to export admin account $($user.UserPrincipalName) to '$workingSetPath'. $($_.Exception.Message)"
    }

    if ($Disable.IsPresent) {
        try {
            if ($user.AccountEnabled -eq $true) {
                if ($user.OnPremisesSyncEnabled -eq $false) {
                    Update-MgUser -UserId $user.Id -AccountEnabled $false -ErrorAction Stop

                    $disabledUsers[$user.Id] = New-Object -TypeName PSCustomObject -Property @{ DateDisabled = Get-Date; Id = $user.Id; UserPrincipalName = $user.UserPrincipalName; } -ErrorAction Stop

                    Write-ActionLog -Action Disabled -Id $user.Id -UserPrincipalName $user.UserPrincipalName
                    Write-LogFile -Path $logPath -Type Information -Message "User account $($user.UserPrincipalName) has been disabled"
                } else {
                    Write-LogFile -Path $logPath -Type Warning -Message "User account $($user.UserPrincipalName) is synced with Active Directory, unable to disable it via Graph"
                }
            } else {
                Write-LogFile -Path $logPath -Type Information -Message "User account $($user.UserPrincipalName) is already disabled"
                if ($user.OnPremisesSyncEnabled -eq $false) {
                    if ($disabledUsers.ContainsKey($user.Id) -eq $false) {
                        $disabledUsers[$user.Id] = New-Object -TypeName PSCustomObject -Property @{ DateDisabled = Get-Date; Id = $user.Id; UserPrincipalName = $user.UserPrincipalName; } -ErrorAction Stop
                    }
                }
            }
        } catch {
            Write-LogFile -Path $logPath -Type Error -Message "Failed to disable user account $($user.UserPrincipalName). $($_.Exception.Message)"
        }
    }

    if ($Delete.IsPresent) {
        if ($disabledUsers.ContainsKey($user.Id)) {
            if ($disabledUsers[$user.Id].DateDisabled -lt $disabledDateTime) {
                try {
                    Remove-MgUser -UserId $user.Id -ErrorAction Stop
                    $disabledUsers.Remove($user.Id)
                    Write-ActionLog -Action Deleted -Id $user.Id -UserPrincipalName $user.UserPrincipalName
                    Write-LogFile -Path $logPath -Type Information -Message "User $($user.UserPrincipalName) has been deleted"
                } catch {
                    Write-LogFile -Path $logPath -Type Error -Message "Failed to delete user $($user.UserPrincipalName). $($_.Exception.Message)"
                }
            }
        }
    }
}

Write-Progress -Activity "Processing admin accounts" -Id 0 -Completed

try {
    $disabledUsers.Keys | ForEach-Object { $disabledUsers[$_] | Select-Object DateDisabled,Id,UserPrincipalName } | Export-Csv $disabledUserPath -NoTypeInformation -ErrorAction Stop
    Write-LogFile -Path $logPath -Type Information -Message "Written disabled user list to '$disabledUserPath'"
} catch {
    Write-LogFile -Path $logPath -Type Error -Message "Failed to write disabled user list to '$disabledUserPath'. $($_.Exception.Message)"
}

try {
    $files = @()
    if ((Test-Path $logPath) -eq $true) {
        $files += $logPath
    }

    if ((Test-Path $actionsLogPath) -eq $true) {
        $files += $actionsLogPath
    }

    if ((Test-Path $disabledUserPath) -eq $true) {
        $files += $disabledUserPath
    }

    if ((Test-Path $workingSetPath) -eq $true) {
        $files += $workingSetPath
    }

    Compress-Archive -Path $files -DestinationPath $archivePath -CompressionLevel Optimal -ErrorAction Stop
} catch {
    Write-LogFile -Path $logPath -Type Error -Message "Failed to create zip file '$archivePath'. $($_.Exception.Message)"
}
