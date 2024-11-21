#==========================================================================
# Check-User-Logins.ps1 , list last login date
#      PIM require: Global Reader
#
# V1.0  - initial version
#==========================================================================
#
Connect-MgGraph -Scopes "AuditLog.Read.All", "Directory.Read.All"  -NoWelcome
$filename="c:\temp\check-user-logins.csv"
$csvData = Import-CSV -Path $filename
$x=@()

#============loop through users imported from CSV file
write-host -foregroundcolor yellow "Checking adminUPN....."
foreach ($line in $csvdata) {
	$userfound=0 #assume ID is badly spelt

        $user=Get-MgUser -Search "UserPrincipalName:$($line.adminupn)" -all -ConsistencyLevel eventual -Property Id,displayname,userPrincipalName,signInActivity,createdDateTime | select  `
           id,userPrincipalName, displayname, createdDateTime, `
          @{n="LastSuccLogin"  ;e={$_.SignInActivity.LastSuccessfulSignInDateTime}}, `
          @{n="LastNonIntLogin";e={$_.SignInActivity.LastNonInteractiveSignInDateTime}}, `
          @{n="LastLogin"      ;e={$_.SignInActivity.LastSignInDateTime}}



        Write-host  "$($line.adminupn)" -noNewline

        if ($user -ne $null) 
            { Write-host -foregroundcolor Green "  OK" 
            #identify the most recent Login from the 3 types of counters, for null use -
            #if you want to only track succcessful logins just review LastSuccessfulSignInDateTime, the others contain failed logins
            #
            if ($user.LastSuccLogin -gt $user.LastNonIntLogin) {$lld=$user.LastSuccLogin} else {$lld=$user.LastNonIntLogin}
            if ($user.LastLogin -gt $lld) {$lld=$user.LastLogin} 
            if ($lld -eq $null) {$lld="-"} 

            #write as a object to allow export to CSV from array $x
            $obj=new-object psobject
            $obj|add-member -MemberType "NoteProperty" -Name UPN                       -value $user.userPrincipalName 
            $obj|add-member -MemberType "NoteProperty" -Name displayName               -value $user.displayName 
            $obj|add-member -MemberType "NoteProperty" -Name LastLoginCombine-All3      -value $lld
            $obj|add-member -MemberType "NoteProperty" -Name LSuccessfulSignIn         -value $user.LastSuccLogin
            $obj|add-member -MemberType "NoteProperty" -Name LNonInteractiveSignIn     -value $user.LastNonIntLogin
            $obj|add-member -MemberType "NoteProperty" -Name LSignIn                   -value $user.LastLogin
            $obj|add-member -MemberType "NoteProperty" -Name userCreated               -value $user.createdDateTime  
            $x+=$obj
        } else { write-host -foregroundcolor RED "  **INVALID" }

} #end loop

$x | export-csv .\checked-user-logins.csv -NoTypeInformation
