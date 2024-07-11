#Connet to Microsoft Graph
Connect-MgGraph -Scope "Policy.ReadWrite.AuthenticationMethod, User.Read.All"

#Get all users and select only required properties
$allUsers = Get-MgBetaUser -all -select Id, UserPrincipalName

#initialise array
$allUsersPerUserMFAState = [System.Collections.Generic.List[Object]]::new()

#Loop through each user and add results to array
Foreach ($user in $allusers){
    $pumfa = Invoke-MgGraphRequest -Method GET -Uri "/beta/users/$($user.id)/authentication/requirements" -OutputType PSObject
    $obj = [PSCustomObject][ordered]@{
        "userid" = $user.Id
        "user" = $user.UserPrincipalName
        "mfastate" = $pumfa.PerUserMfaState
    }
    $allUsersPerUserMFAState.Add($obj)
}

#output in grid view
$allUsersPerUserMFAState | ConvertTo-Json -depth 10 | Out-File ".\allUsersPerUserMFAState.json"
