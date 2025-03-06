$startTime = get-date -Format "yyyy-MM-dd_HHmmss"
$allResults = [System.Collections.Generic.List[Object]]::new()
$failedResults = [System.Collections.Generic.List[Object]]::new()
$usersProcessedCount = 0
$UserList = Get-Content 'UserList.json' | Out-String | ConvertFrom-Json
$numberOfUsers = $UserList.Length

function AppendEntry() {
    $allResults | Export-Csv ".\upgrade_users_results_$($startTime).csv" -NoTypeInformation
}

function AppendEntryFailed() {
    $allResults | Export-Csv ".\upgrade_users_results_failed_$($startTime).csv" -NoTypeInformation
}

# Connect to Entra
Connect-Entra -Scopes 'Group.ReadWrite.All', "Directory.Read.All", "User.Read.All"

# Get Entra Group by Display Name
$group = Get-EntraGroup -Filter "displayName eq 'GoogleTestGroup'"

# Go through list of user accounts to be added
Foreach ($user in $UserList) {
    
    # Parse Justice email
    $JusticeEmail =  $user.jeprefix + "@" + $user.jesuffix
    
    # Increment user processed
    $usersProcessedCount++

    try {
        # Get User Entra object
        $user = Get-EntraUser -UserId $JusticeEmail
        
        # Add Entra user to Group
        Add-EntraGroupMember -GroupId $group.Id -MemberId $user.Id
        Write-Host("Added " + $JusticeEmail + " to GoogleTestGroup")
    
        #Remove-EntraGroupMember -GroupId $group.Id -MemberId $user.Id
        #Write-Host("Removed " + $JusticeEmail + " to GoogleTestGroup")

        # Record record added
        $result = [PSCustomObject][ordered]@{
            "time" = get-date -Format "yyyy-MM-dd HH:mm:ss"
            "upn" = $JusticeEmail
            "id" = $user.Id
        }        
        $allResults.Add($result)

        # Write record to audit log
        AppendEntry
    } catch {
        Write-Host("Failed " + $JusticeEmail + " to GoogleTestGroup")

        # Record record added
        $result = [PSCustomObject][ordered]@{
            "time" = get-date -Format "yyyy-MM-dd HH:mm:ss"
            "upn" = $JusticeEmail
        }
        $failedResults.Add($result)

        # Write record to audit log
        AppendEntryFailed
    }
    
    Write-Host("Processed $($usersProcessedCount) of $($numberOfUsers) users.")
}
