$startTime = get-date -Format "yyyy-MM-dd_HHmmss"
$allResults = [System.Collections.Generic.List[Object]]::new()
$UserList = Get-Content 'NewUserList.json' | Out-String | ConvertFrom-Json
$UserGroups = Get-Content 'NewUserGroups.json' | Out-String | ConvertFrom-Json

function AppendEntry() {
    $allResults | Export-Csv ".\upgrade_users_results_$($startTime).csv" -NoTypeInformation
}

# Connect to Entra
Connect-Entra -Scopes 'Group.ReadWrite.All', "Directory.Read.All", "User.ReadWrite.All"

# Go through list of user accounts to be added
Foreach ($user in $UserList) {
    
    # Parse Justice email
    $JusticeEmail = $user.jeprefix + "@" + $user.jesuffix

    $passwordProfile = New-Object -TypeName Microsoft.Open.AzureAD.Model.PasswordProfile
    $passwordProfile.Password = ''
    $UserParams = @{
        DisplayName       = $user.jeprefix
        PasswordProfile   = $passwordProfile
        UserPrincipalName = $JusticeEmail
        AccountEnabled    = $true
        MailNickName      = $user.jeprefix
    }
    New-EntraUser @UserParams

    # Get User Entra object
    $user = Get-EntraUser -UserId $JusticeEmail
    
     Foreach ($group in $UserGroups) {
        # Get Entra Group by Display Name
        $entraGroup = Get-EntraGroup -Filter "displayName eq '$($group.g)'"
        # Add Entra user to Group
        Add-EntraGroupMember -GroupId $entraGroup.Id -MemberId $user.Id
        Write-Host("Added $($JusticeEmail) to $($group.g)")
    }

    # Record record added
    $result = [PSCustomObject][ordered]@{
        "time" = get-date -Format "yyyy-MM-dd HH:mm:ss"
        "upn"  = $JusticeEmail
        #"id" = $user.Id
    }        
    $allResults.Add($result)
    
}
$allResults
