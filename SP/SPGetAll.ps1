Connect-MgGraph -Scopes "User.Read.All, Application.Read.All, Directory.Read.All" -NoWelcome
Import-Module Microsoft.Graph.Beta.Applications

# Get all application with less than 2 owners
Get-MgBetaServicePrincipal -Filter "owners/`$count eq 0 or owners/`$count eq 1" -CountVariable CountVar -ConsistencyLevel eventual -All | ConvertTo-Json -Depth 20 | Out-File ".\OWNERS.json"

# Create CSV with required details for looking at less than 2 owners
$certificateDetails = Get-Content './OWNERS.json' | Out-String | ConvertFrom-Json

$certificateDetails | Select-Object -Property "id", "appDisplayName", "description", "createdDateTime", "preferredSingleSignOnMode", "accountEnabled", @{Name="owners"; Expression={$_.owners -join ","}} | ConvertTo-Csv | Out-File ".\SPOwnersLessThanTwo.csv"  #>


# Get all SAML applications with notification people
$allPages = @()

$aadUsers = (Invoke-MgGraphRequest -Method GET -Uri "/beta/servicePrincipals?`$filter=preferredSingleSignOnMode eq 'saml'")
$allPages += $aadUsers.value

if ($aadUsers.'@odata.nextLink') {

        do {

            $aadUsers = (Invoke-MgGraphRequest -Uri $aadUsers.'@odata.nextLink')
            $allPages += $aadUsers.value

        } until (
            !$aadUsers.'@odata.nextLink'
        )
        
}

$aadUsers = $allPages
$aadUsers | ConvertTo-Json -Depth 20 | Out-File ".\SAML.json"
$aadUsers.Count 

# Create CSV with required details for looking at notifications
$certificateDetails = Get-Content './SAML.json' | Out-String | ConvertFrom-Json

$certificateDetails | Select-Object -Property "id", "appDisplayName", "description", "createdDateTime", "preferredSingleSignOnMode", "accountEnabled", @{Name="notificationEmailAddresses"; Expression={$_.notificationEmailAddresses -join ","}} | ConvertTo-Csv | Out-File ".\SAMLNotifications.csv" 
