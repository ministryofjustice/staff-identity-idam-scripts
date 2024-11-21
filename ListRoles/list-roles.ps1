#==========================================================================
#List-Roles.ps1 , list roles and users. PIM Doesnt require any special rights
#
# V1.0  - initial version
#==========================================================================

Connect-MgGraph -Scopes "RoleManagement.Read.Directory", "Directory.Read.All", "User.Read.All" -NoWelcome
$aadRoles = Get-MgRoleManagementDirectoryRoleDefinition
$count=0
$x=@()

foreach ($role in $aadRoles) {
  if ($role.displayname -ne "Guest User" -and $role.displayname -ne "User") { 

   write-host -backgroundcolor red $role.displayname
   $eligibleAssignments=Get-MgRoleManagementDirectoryRoleEligibilityScheduleInstance -Filter "roleDefinitionId eq '$($role.id)'"
   $activeAssignments = Get-MgRoleManagementDirectoryRoleAssignmentScheduleInstance  -Filter "roleDefinitionId eq '$($role.id)'"
   $eligibleAssignments | ForEach-Object {  $_ | Add-Member -NotePropertyName "AssType" -NotePropertyValue "eligible"}
   $activeAssignments | ForEach-Object {  $_ | Add-Member -NotePropertyName "AssType" -NotePropertyValue "active"}

   $allassignments=@()
   if ($activeAssignments -ne $null )   { $allassignments+=$allassignments=$activeAssignments}
   if ($eligibleAssignments -ne $null ) { $allassignments+=$eligibleAssignments }

   foreach ($usr in $allAssignments) {
     $user=mguser -userid $usr.principalid -erroraction 'silentlycontinue'
     if ($user -ne $null) {
       $username=$user.displayname
       $userprin=$user.UserPrincipalName
       write-host $role.displayname   $usr.asstype  $username      $userprin   $usr.MemberType      $usr.StartDateTime     $usr.EndDateTime 

       #write as a object to allow export to CSV from array $x
       $obj=new-object psobject
       $obj|add-member -MemberType "NoteProperty" -Name Role -value $role.displayname 
       $obj|add-member -MemberType "NoteProperty" -Name Alloc -value $usr.asstype 
       $obj|add-member -MemberType "NoteProperty" -Name UserName -value $username      
       $obj|add-member -MemberType "NoteProperty" -Name UserPrincipal -value $userprin    
       $obj|add-member -MemberType "NoteProperty" -Name MemberType -value $usr.MemberType
       $obj|add-member -MemberType "NoteProperty" -Name StartDate -value $usr.StartDateTime
       $obj|add-member -MemberType "NoteProperty" -Name EndDate -value $usr.EndDateTime 
       $x+=$obj

     } #end if
   } #end usr




  } #endif exlude role
}

$x | export-csv .\roles-extract.csv -NoTypeInformation

