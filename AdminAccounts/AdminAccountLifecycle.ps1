<#
    .SYNOPSIS
    A script to manage the lifecycle of Entra Id admin accounts.

    .DESCRIPTION
    The script will:
    Disable admin accounts not signed in for the 365 days for live or 730 days for NLE and DEVL.
    Delete accounts that have been disabled by the script for 60 days.
    Accounts created within 14 days of the script running will not be disabled or deleted, if no sign-in activity has been found on the account.
    Using the Undo parameter will allow the script to reverse the last set of changes provided by the Path parameter.

    .PARAMETER Disable
    Disables admin accounts that have not signed in for the last 365 days.

    .PARAMETER Delete
    Removes admin accounts that have been disabled by the script for over 60 days.

    .PARAMETER Undo
    Re-enables and undeletes admin accounts listed in the CSV file provided by the Path parameter.

    .PARAMETER Path
    Path to the actions log CSV file generated by the script to reverse the previous changes.

    .PARAMETER Tenant
    Must be set to PROD, NLE or DEVL to indicate the tenant the script is running on.

    .INPUTS
    None, the script does not take any input from a pipe.

    .OUTPUTS
    All results are exported to CSV and log files and compressed into a zip file at the end.

    .EXAMPLE
    Disables DEVL accounts that haven't signed in for the last 365 days.

    PS> .\AdminAccountLifecycle.ps1 -Disable -Tenant DEVL

    .EXAMPLE
    Deletes all DEVL accounts that have been disabled by the script over 60 days ago.

    PS> .\AdminAccountLifecycle.ps1 -Delete -Tenant DEVL

    .EXAMPLE
    Disables DEVL accounts that haven't signed in for the last 365 days for live or 730 days for NLE and DEVL and deletes all accounts that have been disabled by the script over 60 days ago.

    PS> .\AdminAccountLifecycle.ps1 -Disable -Delete -Tenant DEVL

    .EXAMPLE
    Undo all DEVL changes captured in the action CSV file provided by the Path parameter.

    PS> .\AdminAccountLifecycle.ps1 -Undo -Path .\AdminAccountLifecycleActions-202502211446.csv -Tenant DEVL
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory=$true, ParameterSetName="DisableAccounts")]
    [Parameter(Mandatory=$true, ParameterSetName="DisableAndDelete")]
    [switch]$Disable,
    [Parameter(Mandatory=$true, ParameterSetName="DeleteAccounts")]
    [Parameter(Mandatory=$true, ParameterSetName="DisableAndDelete")]
    [switch]$Delete,
    [Parameter(Mandatory=$true, ParameterSetName="UndoChanges")]
    [switch]$Undo,
    [Parameter(Mandatory=$true, ParameterSetName="UndoChanges")]
    [string]$Path,
    [Parameter(Mandatory=$true, ParameterSetName="DisableAccounts")]
    [Parameter(Mandatory=$true, ParameterSetName="DeleteAccounts")]
    [Parameter(Mandatory=$true, ParameterSetName="DisableAndDelete")]
    [Parameter(Mandatory=$true, ParameterSetName="UndoChanges")]
    [ValidateSet("PROD", "NLE", "DEVL")]
    [string]$Tenant,
    [Parameter(ParameterSetName="DisableAccounts")]
    [Parameter(ParameterSetName="DeleteAccounts")]
    [Parameter(ParameterSetName="DisableAndDelete")]
    [Parameter(ParameterSetName="UndoChanges")]
    [switch]$WhatIf
)

$workingDir = $MyInvocation.MyCommand.Path
$directorySeparator = '\'
$index = $workingDir.LastIndexOf($directorySeparator)
if ($index -eq -1) {
    $directorySeparator = '/'
}

$index = $workingDir.LastIndexOf($directorySeparator)

$workingDir = $workingDir.Substring(0, $index)
$dateTime = (Get-Date -Format s) -replace "[\-T\:]",""
$logPath = "$workingDir$($directorySeparator)AdminAccountLifecycle-$dateTime.log"
$actionsLogPath = "$workingDir$($directorySeparator)AdminAccountLifecycleActions-$dateTime.csv"
$disabledUserPath = "$workingDir$($directorySeparator)AdminAccountLifecycleDisabledUsers.csv"
$workingSetPath = "$workingDir$($directorySeparator)AdminAccountLifecycleWorkingSet-$dateTime.csv"
$archivePath = "$workingDir$($directorySeparator)AdminAccountLifecycle-$dateTime.zip"

$lastSignInDate = (Get-Date).AddDays(-730)
if ($Tenant -eq "PROD") {
    $lastSignInDate = (Get-Date).AddDays(-365)
}

$disabledDateTime = (Get-Date).AddDays(-60)
$createdDateTime = (Get-Date).AddDays(-14)
$disabledUsers = @{}
$globalAdmins = @{}

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
        Write-Host "$line [$($_.Exception.Message)]"
    }
}

function Write-ActionLog {
    param(
        [Parameter(Mandatory=$true)]
        [ValidateSet("Disabled", "Deleted", "Restored", "Enabled")]
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

function Undo-Change {
    param(
        [Parameter(Mandatory=$true)]
        [string]$Path
    )
    
    $users = @()

    try {
        $users += Import-Csv $Path -ErrorAction Stop
    } catch {
        Write-LogFile -Path $logPath -Type Error -Message "Failed to import $Path. $($_.Exception.Message)"
        exit
    }
    
    foreach ($user in $users) {
        if ($user.Action -eq "Disabled") {
            try {
                if ($WhatIf.IsPresent) {
                    Update-MgUser -UserId $user.Id -AccountEnabled:$true -ErrorAction Stop -WhatIf
                    Write-LogFile -Path $logPath -Type Information -Message "Would have enabled account $($user.UserPrincipalName), but the WhatIf parameter was specified and the account is still disabled"
                } else {
                    Update-MgUser -UserId $user.Id -AccountEnabled:$true -ErrorAction Stop
                    $disabledUsers.Remove($user.Id)
                    Write-ActionLog -Action Enabled -Id $user.Id -UserPrincipalName $user.UserPrincipalName
                    Write-LogFile -Path $logPath -Type Information -Message "Enabled account $($user.UserPrincipalName)"
                }
            } catch {
                Write-LogFile -Path $logPath -Type Error -Message "Failed to enable account $($user.UserPrincipalName). $($_.Exception.Message)"
            }
        } elseif ($user.Action -eq "Deleted") {
            try {
                if ($WhatIf.IsPresent) {
                    Restore-MgDirectoryDeletedItem -DirectoryObjectId $user.Id -ErrorAction Stop -WhatIf
                    Write-LogFile -Path $logPath -Type Information -Message "Would have restored deleted account $($user.UserPrincipalName), but the WhatIf parameter was specified"
                } else {
                    Restore-MgDirectoryDeletedItem -DirectoryObjectId $user.Id -ErrorAction Stop | Out-Null
                    Write-ActionLog -Action Restored -Id $user.Id -UserPrincipalName $user.UserPrincipalName
                    Write-LogFile -Path $logPath -Type Information -Message "Restored deleted account $($user.UserPrincipalName)"
                }
            } catch {
                Write-LogFile -Path $logPath -Type Error -Message "Failed to restore deleted user $($user.UserPrincipalName). $($_.Exception.Message)"
            }
        }
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

        if ($role.DisplayName -eq "Guest User" -or $role.DisplayName -eq "User" -or $role.DisplayName -eq "Directory Synchronization Accounts") {
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
            $servicePrincipal = $null

            if ($adminUsers.ContainsKey($assignment.PrincipalId) -eq $false) {
                try {
                    $user = Get-MgUser -UserId $assignment.PrincipalId -Property DisplayName,UserPrincipalName,Id,SignInActivity,CreatedDateTime,AccountEnabled,OnPremisesSyncEnabled -ErrorAction Stop | Select-Object Id,DisplayName,AccountEnabled,UserPrincipalName,OnPremisesSyncEnabled,@{Name="LastSignInDateTime"; Expression={ $_.SignInActivity.LastSignInDateTime }},@{Name="LastSuccessfulSignInDateTime"; Expression={ $_.SignInActivity.LastSuccessfulSignInDateTime }},@{Name="LastNonInteractiveSignInDateTime"; Expression={ $_.SignInActivity.LastNonInteractiveSignInDateTime }},CreatedDateTime
                    if ($role.DisplayName -eq "Global Administrator") {
                        $globalAdmins[$assignment.PrincipalId] = $user
                    }
                } catch {
                    Write-LogFile -Path $logPath -Type Warning -Message "Failed to get user $($assignment.PrincipalId), could it be a group? $($_.Exception.Message)"
                }

                if ($null -eq $user -and $adminGroups.ContainsKey($assignment.PrincipalId) -eq $false) {
                    try {
                        $group = Get-MgGroup -GroupId $assignment.PrincipalId -ErrorAction Stop
                        Write-LogFile -Path $logPath -Type Information -Message "Principal Id $($assignment.PrincipalId) is group $($group.DisplayName)"
                    } catch {
                        Write-LogFile -Path $logPath -Type Warning -Message "Failed to get group $($assignment.PrincipalId), maybe it is not a user or group? $($_.Exception.Message)"
                    }
                }

                if ($null -eq $user -and $null -eq $group) {
                    try {
                        $servicePrincipal = Get-MgServicePrincipal -ServicePrincipalId $assignment.PrincipalId -Property Id,DisplayName -ErrorAction Stop
                        Write-LogFile -Path $logPath -Type Warning -Message "Principal Id $($assignment.PrincipalId) has been identified as service principal, $($servicePrincipal.DisplayName)"
                    } catch {
                        Write-LogFile -Path $logPath -Type Warning -Message "Doesn't appear to be a service principal. $($_.Exception.Message)"
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
                                $user = Get-MgUser -UserId $member.Id -Property DisplayName,UserPrincipalName,Id,SignInActivity,CreatedDateTime,AccountEnabled,OnPremisesSyncEnabled -ErrorAction Stop | Select-Object Id,DisplayName,AccountEnabled,UserPrincipalName,OnPremisesSyncEnabled,@{Name="LastSignInDateTime"; Expression={ $_.SignInActivity.LastSignInDateTime }},@{Name="LastSuccessfulSignInDateTime"; Expression={ $_.SignInActivity.LastSuccessfulSignInDateTime }},@{Name="LastNonInteractiveSignInDateTime"; Expression={ $_.SignInActivity.LastNonInteractiveSignInDateTime }},CreatedDateTime
                                if ($role.DisplayName -eq "Global Administrator") {
                                    $globalAdmins[$assignment.PrincipalId] = $user
                                }
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
    if ($Disable.IsPresent -and $Delete.IsPresent) {
        $scopes = "User.ReadWrite.All","User.EnableDisableAccount.All","AuditLog.Read.All","Directory.AccessAsUser.All"
    } elseif ($Disable.IsPresent -and $Delete.IsPresent -eq $false) {
        $scopes = "User.ReadWrite.All","User.EnableDisableAccount.All","AuditLog.Read.All"
    } elseif ($Delete.IsPresent -and $Disable.IsPresent -eq $false) {
        $scopes = "User.ReadWrite.All","AuditLog.Read.All","Directory.AccessAsUser.All"
    } elseif ($Undo.IsPresent) {
        $scopes = "User.ReadWrite.All","User.EnableDisableAccount.All","Directory.AccessAsUser.All"
    }

    $context = Get-MgContext -ErrorAction Stop
    if ($null -ne $context) {
        if ($Tenant -eq "PROD") {
            if ($context.Account -notmatch "^.+@justiceuk\.onmicrosoft\.com$") {
                Disconnect-MgGraph -ErrorAction Stop | Out-Null
            }
        } elseif ($Tenant -eq "NLE") {
            if ($context.Account -notmatch "^.+@testjusticeuk\.onmicrosoft\.com$") {
                Disconnect-MgGraph -ErrorAction Stop | Out-Null
            }
        } elseif ($Tenant -eq "DEVL") {
            if ($context.Account -notmatch "^.+@(mojodevl\.onmicrosoft\.com|devl\.justice\.gov\.uk)$") {
                Disconnect-MgGraph -ErrorAction Stop | Out-Null
            }
        }
    }

    Connect-MgGraph -Scopes $scopes -NoWelcome -ErrorAction Stop
} catch {
    Write-LogFile -Path $logPath -Type Error -Message "Failed to login to Microsoft Graph. $($_.Exception.Message)"
    exit
}

$users = @()

if ((Test-Path $disabledUserPath) -eq $true) {
    try {
        $importedUsers = Import-Csv $disabledUserPath -ErrorAction Stop
    } catch {
        Write-LogFile -Path $logPath -Type Error -Message "Failed to import disabled users from '$disabledUserPath'. $($_.Exception.Message)"
    }
    
    $importedUsers | ForEach-Object {
        try {
            $removeUserFromList = $false
            $user = Get-MgUser -UserId $_.Id -Property Id,AccountEnabled -ErrorAction Stop
        } catch {
            if ($_.Exception.Message -like "[Request_ResourceNotFound]*") {
                $removeUserFromList = $true
                Write-LogFile -Path $logPath -Type Warning -Message "User not found removing it from the disabled user list. $($_.Exception.Message)"
            } else {
                Write-LogFile -Path $logPath -Type Error -Message "Issues encountered while getting the user from Entra Id. $($_.Exception.Message)"
                continue
            }
        }
        
        if ($disabledUsers.ContainsKey($user.Id) -eq $false -and $removeUserFromList -eq $false -and $user.AccountEnabled -ne $true) {
            $disabledUser = New-Object -TypeName PSCustomObject -Property @{ DateDisabled = [DateTime]$_.DateDisabled; Id = $_.Id; UserPrincipalName = $_.UserPrincipalName; }
            $disabledUsers.Add($user.Id, $disabledUser)
        }
    }
}

if ($Undo.IsPresent) {
    Undo-Change -Path $Path
} else {
    $users += Get-EntraIdAdminAccount
    $userCount = 0

    foreach ($user in $users) {
        $userCount++
        
        Write-Progress -Activity "Processing admin accounts" -Status "User $userCount of $($users.Count)" -PercentComplete (($userCount / $users.Count) * 100) -CurrentOperation $user.DisplayName -Id 0

        if ($globalAdmins.ContainsKey($user.Id) -eq $true) {
            Write-LogFile -Path $logPath -Type Information -Message "Skipping $($user.UserPrincipalName) as account is a Global Admin account"
            continue
        }

        if ($user.CreatedDateTime -gt $createdDateTime) {
            Write-LogFile -Path $logPath -Type Information -Message "Skipping $($user.UserPrincipalName) as account has been created after $createdDateTime"
            continue
        }

        if ($user.LastNonInteractiveSignInDateTime -ge $lastSignInDate -or
            $user.LastSignInDateTime -ge $lastSignInDate -or
            $user.LastSuccessfulSignInDateTime -ge $lastSignInDate) {
            $loginTime = $user.LastNonInteractiveSignInDateTime
            if ($loginTime -lt $user.LastSignInDateTime) {
                $loginTime = $user.LastSignInDateTime
            }

            if ($loginTime -lt $user.LastSuccessfulSignInDateTime) {
                $loginTime = $user.LastSuccessfulSignInDateTime
            }

            Write-LogFile -Path $logPath -Type Information -Message "Skipping $($user.UserPrincipalName) as last sign-in $loginTime is after $lastSignInDate"

            if ($disabledUsers.ContainsKey($user.Id)) {
                $disabledUsers.Remove($user.Id)
            }

            continue
        }

        try {
            $user | Select-Object DisplayName,UserPrincipalName,AccountEnabled,Id,OnPremisesSyncEnabled,LastNonInteractiveSignInDateTime,LastSignInDateTime,LastSuccessfulSignInDateTime,CreatedDateTime | Export-Csv $workingSetPath -NoTypeInformation -Append -ErrorAction Stop
        } catch {
            Write-LogFile -Path $logPath -Type Warning -Message "Failed to export admin account $($user.UserPrincipalName) to '$workingSetPath'. $($_.Exception.Message)"
        }

        try {
            if ($user.AccountEnabled -eq $true) {
                if ($null -eq $user.OnPremisesSyncEnabled -or $user.OnPremisesSyncEnabled -eq $false) {
                    if ($Disable.IsPresent) {
                        if ($WhatIf.IsPresent) {
                            Update-MgUser -UserId $user.Id -AccountEnabled:$false -ErrorAction Stop -WhatIf
                            Write-LogFile -Path $logPath -Type Information -Message "User account $($user.UserPrincipalName) would have been disabled, but WhatIf parameter was specified"
                        } else {
                            Update-MgUser -UserId $user.Id -AccountEnabled:$false -ErrorAction Stop
                            $updatedUser = $null
                            $updatedUser = Get-MgUser -UserId $user.Id -Property Id,UserPrincipalName,AccountEnabled -ErrorAction SilentlyContinue
                            if ($null -ne $updatedUser) {
                                if ($updatedUser.AccountEnabled -eq $false) {
                                    $disabledUsers[$user.Id] = New-Object -TypeName PSCustomObject -Property @{ DateDisabled = Get-Date; Id = $user.Id; UserPrincipalName = $user.UserPrincipalName; } -ErrorAction Stop
                                    Write-ActionLog -Action Disabled -Id $user.Id -UserPrincipalName $user.UserPrincipalName
                                    Write-LogFile -Path $logPath -Type Information -Message "User account $($user.UserPrincipalName) has been disabled"
                                } else {
                                    Write-LogFile -Path $logPath -Type Error -Message "User account $($user.UserPrincipalName) is still enabled"
                                }
                            } else {
                                Write-LogFile -Path $logPath -Type Error -Message "Failed to check user account $($user.UserPrincipalName) has been disabled"
                            }
                        }
                    } else {
                        Write-LogFile -Path $logPath -Type Information -Message "User account $($user.UserPrincipalName) would have been disabled, but disable switch has not been used"
                    }
                } else {
                    Write-LogFile -Path $logPath -Type Warning -Message "User account $($user.UserPrincipalName) is synced with Active Directory, cannot disable it via Graph"
                }
            } else {
                Write-LogFile -Path $logPath -Type Information -Message "User account $($user.UserPrincipalName) is already disabled"
                if (($null -eq $user.OnPremisesSyncEnabled -or $user.OnPremisesSyncEnabled -eq $false) -and $Disable.IsPresent) {
                    if ($disabledUsers.ContainsKey($user.Id) -eq $false) {
                        $disabledUsers[$user.Id] = New-Object -TypeName PSCustomObject -Property @{ DateDisabled = Get-Date; Id = $user.Id; UserPrincipalName = $user.UserPrincipalName; } -ErrorAction Stop
                    }
                }
            }
        } catch {
            Write-LogFile -Path $logPath -Type Error -Message "Failed to disable user account $($user.UserPrincipalName). $($_.Exception.Message)"
        }

        if ($disabledUsers.ContainsKey($user.Id)) {
            if ($disabledUsers[$user.Id].DateDisabled -lt $disabledDateTime) {
                try {
                    if ($Delete.IsPresent) {
                        if ($WhatIf.IsPresent) {
                            Remove-MgUser -UserId $user.Id -ErrorAction Stop -WhatIf
                            Write-LogFile -Path $logPath -Type Information -Message "User $($user.UserPrincipalName) would have been deleted, but WhatIf parameter was specified"
                        } else {
                            Remove-MgUser -UserId $user.Id -ErrorAction Stop
                            $disabledUsers.Remove($user.Id)
                            Write-ActionLog -Action Deleted -Id $user.Id -UserPrincipalName $user.UserPrincipalName
                            Write-LogFile -Path $logPath -Type Information -Message "User $($user.UserPrincipalName) has been deleted"
                        }
                    } else {
                        Write-LogFile -Path $logPath -Type Information -Message "User $($user.UserPrincipalName) would have been deleted, if the delete switch had been used"
                    }
                } catch {
                    Write-LogFile -Path $logPath -Type Error -Message "Failed to delete user $($user.UserPrincipalName). $($_.Exception.Message)"
                }
            }
        }
    }

    Write-Progress -Activity "Processing admin accounts" -Id 0 -Completed
}

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

    foreach ($fileName in $files) {
        if ($fileName -ne $disabledUserPath) {
            Remove-Item -Path $fileName -Force -Confirm:$false -ErrorAction SilentlyContinue
        }
    }
} catch {
    Write-LogFile -Path $logPath -Type Error -Message "Failed to create zip file '$archivePath'. $($_.Exception.Message)"
}
