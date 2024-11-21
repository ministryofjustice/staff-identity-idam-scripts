#==========================================================================
#example Remove-EntraIDPIM-Roles.ps1 c:\temp\removeroles1.csv
#CSV comma seperated, first row contains adminUPN,Role
# V1.0  - initial version
# v1.1  - more comments, and output text a little clearer no logical changes
# v1.2  - Add transcript log, Make output text clearer 
# v1.3	- need privilege Role Administrator
#==========================================================================
param ($filename)
write-host "Remove permission input file ($filename)"
Start-Transcript -Path "c:\temp\$($filename)_$(get-date -Format "yyyy-MM-dd_HHmmss").log" -Append

Connect-MgGraph -Scopes "RoleManagement.ReadWrite.Directory", "Directory.ReadWrite.All", "User.Read.All" -NoWelcome
$aadRoles = Get-MgRoleManagementDirectoryRoleDefinition
$csvData = Import-CSV -Path $filename
$count=0
#============loop through perms imported from CSV file
foreach ($line in $csvdata) {
        # Check that the user value is valid
	$count=$count+1
	$goodperm=0 #assume perm is bad

        $user = Get-MgUser -Search "UserPrincipalName:$($line.adminupn)" -ConsistencyLevel eventual 
        write-host "" 
        if ($user.count -eq 1) {
            Write-host -foregroundcolor Green "PERM $count VALID: $($line.adminupn) " -NoNewline
        }
        else {
            write-host "PERM $count **INVALID: $($line.adminupn) " 
            continue  
        }
        
	#===lookup role definition
        $roleDefinition = ($aadroles | Where-Object DisplayName -eq $line.role).Id 

	#===if valid role
        if ($roleDefinition -ne $null) {
            write-host -foregroundcolor green " VALID EntraID ROLE: $($line.role) "

	    #lookup perms for user + role to identify eligible or active roles
            $eligibleAssignments = @(Get-MgRoleManagementDirectoryRoleEligibilityScheduleInstance -Filter "principalId eq '$($user.id)' and roleDefinitionId eq '$($roleDefinition)'")
            $activeAssignments = @(Get-MgRoleManagementDirectoryRoleAssignmentScheduleInstance -Filter "principalId eq '$($user.id)' and roleDefinitionId eq '$($roleDefinition)'")

            if ($eligibleAssignments.count -eq 0 -and $activeAssignments.count -eq 0)  {
                 Write-Host                            "    ***EntraID Role NOT FOUND AGAINST USER***"
            } else {
		 Write-Host -backgroundcolor black  "    FOUND $($eligibleAssignments.count) ELIGIBLE ,  $($activeAssignments.count) ACTIVE "
       	         $goodperm=1 #mark perm as good to remove
            }


        } else {
            write-host " **This is not a EntraID Role" 
        }
    

  #=========valid perms that need to be removed validated earlier
  if ($goodperm=1)  {

    #=========remove eligible assign
    foreach ($assignment in $eligibleAssignments) {
        $roleName = ($aadroles | Where-Object id -eq $assignment.RoleDefinitionId | Select-Object DisplayName).DisplayName
        Write-Host -backgroundcolor black "    Removing eligibility" 
        $params = @{
            "PrincipalId"      = $assignment.principalId
            "RoleDefinitionId" = $assignment.RoleDefinitionId
            "Justification"    = "Atos Tidy Up Acitivity October 2024"
            "DirectoryScopeId" = $assignment.DirectoryScopeId
            "Action"           = "AdminRemove"
         }
         try {
            $obj=New-MgRoleManagementDirectoryRoleEligibilityScheduleRequest -BodyParameter $params  -erroraction 'silentlycontinue'
               if ($null -eq $Obj) {
		        throw
                }
                Write-Host -backgroundcolor black "    Role removed"
            }
            catch {
                Write-Host -foregroundcolor red "    **Error with removing the role"
            }

        } # end for each

    #=========remove active assign
    foreach ($assignment in $activeAssignments) {
        $roleName = ($aadroles | Where-Object id -eq $assignment.RoleDefinitionId | Select-Object DisplayName).DisplayName
#        if (((Get-Date).ToUniversalTime() - $activeAssignments[0].StartDateTime).totalminutes -lt 5) {
#            Write-Host -foregroundcolor red "    **Abort perm as not been active for 5 minutes. Try again" 
#        }
#        else {
            Write-Host -backgroundcolor black "    Removing ACTIVE role"
            $params = @{
                "PrincipalId"      = $assignment.principalId
                "RoleDefinitionId" = $assignment.RoleDefinitionId
                "Justification"    = "MoJ Support Account Disablement"
                "DirectoryScopeId" = $assignment.DirectoryScopeId
                "Action"           = "AdminRemove"
            }
            try {
                $obj=New-MgRoleManagementDirectoryRoleAssignmentScheduleRequest -BodyParameter $params -erroraction 'silentlycontinue'
                if ($null -eq $Obj) {
		        throw
                }
                Write-Host -backgroundcolor black "    Role removed"
            }
            catch {
                Write-Host -foregroundcolor red "    **Error with removing the role"
            }


#        } # endif less than 5 mins
    } #end for
  } # end good perm

} #end loop


Stop-Transcript