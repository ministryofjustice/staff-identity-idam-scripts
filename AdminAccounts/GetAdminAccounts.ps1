<#
    .SYNOPSIS
    Gets all user accounts assigned one or more Entra Id admin roles

    .DESCRIPTION
    Enumerates through all the Entra Id admin roles gathering a list of users, groups and the group members and export them out to a CSV file.
    Make sure to activate the Global Reader role to gather the LastSigninActivity property from the user accounts.

    .PARAMETER Path
    CSV file to export the user and groups assigned one or more Entra Id roles.

    .INPUTS
    None, you cannot pipe objects to this script.

    .OUTPUTS
    Results are exported to CSV file specified by the Path parameter.

    .EXAMPLE
    PS> .\GetAdminAccounts.ps1 -Path .\AdminAccounts.csv
#>

param(
    [Parameter(Mandatory=$true, Position=0)]
    [string]$Path
)

try {
    Connect-MgGraph -Scopes "User.Read.All","AuditLog.Read.all" -NoWelcome -ErrorAction Stop
} catch {
    "Failed to login to Microsoft Graph PowerShell. $($_.Exception.Message)"
    exit
}

$roles = @()
$adminUsers = @{}
$roleCount = 0

try {
    $roles += Get-MgRoleManagementDirectoryRoleDefinition -All -ErrorAction Stop
} catch {
    "Failed to get role definitions. $($_.Exception.Message)"
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
        "Failed to get role assignments for $($role.DisplayName). $($_.Exception.Message)"
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
                    "Failed to get group members for $($group.DisplayName) - $($assignment.PrincipalId). $($_.Exception.Message)"
                }
                
                foreach ($member in $members) {
                    $memberCount++
                    
                    Write-Progress -Activity "Group $($group.DisplayName)" -Status "Group member $memberCount of $($members.Count)" -PercentComplete (($memberCount / $members.Count) * 100) -Id 2 -ParentId 1
    
                    if ($adminUsers.ContainsKey($member.Id) -eq $false) {
                        $user = $null

                        try {
                            $user = Get-MgUser -UserId $member.Id -Property DisplayName,UserPrincipalName,Id,SignInActivity,AccountEnabled -ErrorAction Stop | Select-Object Id,DisplayName,AccountEnabled,UserPrincipalName,@{Name="LastSignInDateTime"; Expression={ $_.SignInActivity.LastSignInDateTime }},@{Name="LastSuccessfulSignInDateTime"; Expression={ $_.SignInActivity.LastSuccessfulSignInDateTime }},@{Name="LastNonInteractiveSignInDateTime"; Expression={ $_.SignInActivity.LastNonInteractiveSignInDateTime }}
                        } catch {
                            "Failed to get user $($member.Id) in group $($group.DisplayName). $($_.Exception.Message)"
                        }

                        if ($null -ne $user) {
                            $adminUsers.Add($member.Id, $user)
                        }
                    }
                }

                Write-Progress -Activity "Group $($group.DisplayName)" -Id 2 -Completed
            } elseif ($null -ne $user) {
                $adminUsers.Add($assignment.PrincipalId, $user)
            }
        }
    }

    Write-Progress -Activity "Role assignments" -Id 1 -Completed
}

Write-Progress -Activity "Entra ID Roles" -Id 0 -Completed

$userList = @()

foreach ($principalId in $adminUsers.Keys) {
    $userList += $adminUsers[$principalId]
}

try {
    $userList | Export-Csv $Path -NoTypeInformation -ErrorAction Stop
} catch {
    "Failed to export results to file $Path. $($_.Exception.Message)"
}
