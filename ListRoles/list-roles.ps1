#==========================================================================
#List-Roles.ps1 , list roles and users. PIM Doesnt require any special rights
#
# V1.0  - initial version
# V1.1  - Updated to show group names and get members of those groups
#==========================================================================

param(
    [Parameter(Mandatory=$true, Position=0)]
    [string]$Path
)

try {
  Connect-MgGraph -Scopes "RoleManagement.Read.Directory", "Directory.Read.All", "User.Read.All" -NoWelcome -ErrorAction Stop
} catch {
  "Failed to login in to Microsoft Graph. $($_.Exception.Message)"
  exit
}

$aadRoles = @()

try {
  $aadRoles += Get-MgRoleManagementDirectoryRoleDefinition -All -ErrorAction Stop
} catch {
  "Failed to get Entra Id Roles. $($_.Exception.Message)"
  exit
}

$x = @()

foreach ($role in $aadRoles) {
  if ($role.displayname -ne "Guest User" -and $role.displayname -ne "User") { 

   write-host -backgroundcolor red $role.displayname
   $eligibleAssignments = Get-MgRoleManagementDirectoryRoleEligibilityScheduleInstance -Filter "roleDefinitionId eq '$($role.id)'" -All
   $activeAssignments = Get-MgRoleManagementDirectoryRoleAssignmentScheduleInstance  -Filter "roleDefinitionId eq '$($role.id)'" -All
   $eligibleAssignments | ForEach-Object {  $_ | Add-Member -NotePropertyName "AssType" -NotePropertyValue "Eligible"}
   $activeAssignments | ForEach-Object {  $_ | Add-Member -NotePropertyName "AssType" -NotePropertyValue "Active"}

   $allassignments=@()
   if ($null -ne $activeAssignments)   { $allassignments+=$activeAssignments}
   if ($null -ne $eligibleAssignments) { $allassignments+=$eligibleAssignments }

   foreach ($usr in $allAssignments) {
     $user = $null
     $user = Get-MgUser -userid $usr.principalid -erroraction 'silentlycontinue'
     if ($null -ne $user) {
       $username=$user.displayname
       $userprin=$user.UserPrincipalName
       write-host $role.displayname   $usr.asstype  $username      $userprin   $usr.MemberType      $usr.StartDateTime     $usr.EndDateTime 

       #write as a object to allow export to CSV from array $x
       $obj=new-object psobject
       $obj|add-member -MemberType "NoteProperty" -Name Role -value $role.displayname 
       $obj|add-member -MemberType "NoteProperty" -Name Alloc -value $usr.asstype 
       $obj|add-member -MemberType "NoteProperty" -Name Name -value $username      
       $obj|add-member -MemberType "NoteProperty" -Name Type -value "User"
       $obj|add-member -MemberType "NoteProperty" -Name UserPrincipal -value $userprin    
       $obj|add-member -MemberType "NoteProperty" -Name MemberType -value $usr.MemberType
       $obj|Add-Member -MemberType "NoteProperty" -Name AssignmentType -Value $usr.AssignmentType
       $obj|add-member -MemberType "NoteProperty" -Name StartDate -value $usr.StartDateTime
       $obj|add-member -MemberType "NoteProperty" -Name EndDate -value $usr.EndDateTime
       $obj|Add-Member -MemberType "NoteProperty" -Name ProvidedBy -Value "Assignment"
       $obj|Add-Member -MemberType "NoteProperty" -Name GroupName -Value ""

       if ($null -ne $usr.EndDateTime -and $null -ne $usr.StartDateTime -and $usr.EndDateTime -le $usr.StartDateTime.AddHours(8)) {
        $obj.ProvidedBy = "Activation"
       }
       $x+=$obj

     } else {
        $group = $null
        $group = Get-MgGroup -GroupId $usr.PrincipalId -ErrorAction SilentlyContinue
        if ($null -ne $group) {
           $username=$group.displayname
           $userprin=""
           write-host $role.displayname   $usr.asstype  $username      $userprin   $usr.MemberType      $usr.StartDateTime     $usr.EndDateTime 

           #write as a object to allow export to CSV from array $x
           $obj=new-object psobject
           $obj|add-member -MemberType "NoteProperty" -Name Role -value $role.displayname 
           $obj|add-member -MemberType "NoteProperty" -Name Alloc -value $usr.asstype 
           $obj|add-member -MemberType "NoteProperty" -Name Name -value $username      
           $obj|add-member -MemberType "NoteProperty" -Name Type -value "Group"
           $obj|add-member -MemberType "NoteProperty" -Name UserPrincipal -value $userprin    
           $obj|add-member -MemberType "NoteProperty" -Name MemberType -value $usr.MemberType
           $obj|Add-Member -MemberType "NoteProperty" -Name AssignmentType -Value $usr.AssignmentType
           $obj|add-member -MemberType "NoteProperty" -Name StartDate -value $usr.StartDateTime
           $obj|add-member -MemberType "NoteProperty" -Name EndDate -value $usr.EndDateTime 
           $obj|Add-Member -MemberType "NoteProperty" -Name ProvidedBy -Value "Group Assignment"
           $obj|Add-Member -MemberType "NoteProperty" -Name GroupName -Value $group.DisplayName
           $x+=$obj

           $members = @()
           $members += Get-MgGroupMember -GroupId $group.Id -ErrorAction SilentlyContinue
           foreach ($member in $members) {
               $user = $null
               $user = Get-MgUser -UserId $member.Id -ErrorAction SilentlyContinue
               if ($null -ne $user) {
                   $username=$user.displayname
                   $userprin=$user.UserPrincipalName
                   write-host $role.displayname   $usr.asstype  $username      $userprin   $usr.MemberType      $usr.StartDateTime     $usr.EndDateTime 

                   #write as a object to allow export to CSV from array $x
                   $obj=new-object psobject
                   $obj|add-member -MemberType "NoteProperty" -Name Role -value $role.displayname 
                   $obj|add-member -MemberType "NoteProperty" -Name Alloc -value $usr.asstype 
                   $obj|add-member -MemberType "NoteProperty" -Name Name -value $username      
                   $obj|add-member -MemberType "NoteProperty" -Name Type -value "User"
                   $obj|add-member -MemberType "NoteProperty" -Name UserPrincipal -value $userprin    
                   $obj|add-member -MemberType "NoteProperty" -Name MemberType -value $usr.MemberType
                   $obj|Add-Member -MemberType "NoteProperty" -Name AssignmentType -Value $usr.AssignmentType
                   $obj|add-member -MemberType "NoteProperty" -Name StartDate -value $usr.StartDateTime
                   $obj|add-member -MemberType "NoteProperty" -Name EndDate -value $usr.EndDateTime 
                   $obj|Add-Member -MemberType "NoteProperty" -Name ProvidedBy -Value "Group Assignment"
                   $obj|Add-Member -MemberType "NoteProperty" -Name GroupName -Value $group.DisplayName
                   $x+=$obj
               }
           }
        }
     } #end if
   } #end usr




  } #endif exlude role
}

try {
  $x | export-csv $Path -NoTypeInformation -ErrorAction Stop
} catch {
  "Failed to export admin accounts to $Path. $($_.Exception.Message)"
}
