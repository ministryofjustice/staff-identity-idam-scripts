#==========================================================================
#List-Roles-compare-standard.ps1
# Based on list-roles.ps1 , this version lists roles and users assigned, then
# comapres to enabled state of standard accounts
# PIM Doesnt require any special rights
#
# V1.0  - initial version
#==========================================================================

$date = get-date -format dd-MM-yyyy-HHmm

Connect-MgGraph -Scopes "RoleManagement.Read.Directory", "Directory.Read.All", "User.Read.All" -NoWelcome
$aadRoles = Get-MgRoleManagementDirectoryRoleDefinition
$count = 0
$x = @()

foreach ($role in $aadRoles) {
    if ($role.displayname -ne "Guest User" -and $role.displayname -ne "User") { 

        write-host -backgroundcolor red $role.displayname
        $eligibleAssignments = Get-MgRoleManagementDirectoryRoleEligibilityScheduleInstance -Filter "roleDefinitionId eq '$($role.id)'"
        $activeAssignments = Get-MgRoleManagementDirectoryRoleAssignmentScheduleInstance  -Filter "roleDefinitionId eq '$($role.id)'"
        $eligibleAssignments | ForEach-Object { $_ | Add-Member -NotePropertyName "AssType" -NotePropertyValue "eligible" }
        $activeAssignments | ForEach-Object { $_ | Add-Member -NotePropertyName "AssType" -NotePropertyValue "active" }

        $allassignments = @()
        if ($activeAssignments -ne $null ) { $allassignments += $allassignments = $activeAssignments }
        if ($eligibleAssignments -ne $null ) { $allassignments += $eligibleAssignments }

        foreach ($usr in $allAssignments) {
            $user = mguser -userid $usr.principalid -Property Id, DisplayName, UserPrincipalName, AccountEnabled | select Id, DisplayName, UserPrincipalName, AccountEnabled -erroraction 'silentlycontinue'
            if ($user -ne $null) {
                $username = $user.displayname
                $userprin = $user.UserPrincipalName
                write-host $role.displayname   $usr.asstype  $username      $userprin   $usr.MemberType      $usr.StartDateTime     $usr.EndDateTime 

                # if onmicrosoft, check standard account
                $standardcheck = if ($user.UserPrincipalName -like "*onmicrosoft.com") {
                    $standarduser = $user.UserPrincipalName -replace ('JusticeUK.onmicrosoft.com', 'justice.gov.uk') # maybe check other domains too?
                    get-mguser -userid $standarduser -Property Id, DisplayName, UserPrincipalName, AccountEnabled | select Id, DisplayName, UserPrincipalName, AccountEnabled -erroraction 'silentlycontinue'
                }

                # if standard disabled but onmicrosoft enabled, add "concern" column
                $concern = $null
                if ($user.AccountEnabled -eq $True -and $standardcheck.AccountEnabled -eq $False) {
                    $concern = "True"
                }
                else { $concern = "False" }

                #write as a object to allow export to CSV from array $x
                $obj = new-object psobject
                $obj | add-member -MemberType "NoteProperty" -Name Role -value $role.displayname 
                $obj | add-member -MemberType "NoteProperty" -Name Alloc -value $usr.asstype 
                $obj | add-member -MemberType "NoteProperty" -Name UserName -value $username      
                $obj | add-member -MemberType "NoteProperty" -Name UserPrincipal -value $userprin    
                $obj | add-member -MemberType "NoteProperty" -Name MemberType -value $usr.MemberType
                $obj | add-member -MemberType "NoteProperty" -Name StartDate -value $usr.StartDateTime
                $obj | add-member -MemberType "NoteProperty" -Name EndDate -value $usr.EndDateTime 
                # add active state for both onmicrosft and standard accounts here
                $obj | add-member -MemberType "NoteProperty" -Name AccountEnabled -value $user.AccountEnabled
                $obj | add-member -MemberType "NoteProperty" -Name StandardAccount -value $standardcheck.UserPrincipalName
                $obj | add-member -MemberType "NoteProperty" -Name StandardAccountEnabled -value $standardcheck.AccountEnabled
                # if standard disabled but onmicrosoft enabled, add "concern" column
                $obj | add-member -MemberType "NoteProperty" -Name Concern -value $concern
       
                $x += $obj

            } #end if
        } #end usr
    } #endif exlude role
}

$x | export-csv .\roles-extract-with-concern$date.csv -NoTypeInformation