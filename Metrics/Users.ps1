Connect-Entra -Scopes "User.Read.All"

$usersList = Get-EntraUser -All -Property UserPrincipalName, AccountEnabled, Id, UserType | Select-Object UserPrincipalName, AccountEnabled, Id, UserType
$disabledUsers = $usersList | Where-Object { $_.accountEnabled -eq $false }
$guestUsers = $usersList | Where-Object { $_.userType -eq 'Guest' }
$serviceAccountUsers = $usersList | Where-Object { $_.userPrincipalName -like "svc_*" }

$serviceAccounts = $serviceAccountUsers.Count
$guestAccounts = $guestUsers.Count
$enabledAccounts = ($usersList.Count - $disabledUsers.Count)
$disabledAccounts = $disabledUsers.Count

[PSCustomObject][ordered]@{
    "TotalAccounts" = $usersList.Count
    "TotalServiceAccounts" = $serviceAccounts
    "TotalGuests" = $guestAccounts
    "TotalEnabledAccounts" = $enabledAccounts
    "TotalDisabledAccounts" = $disabledAccounts
}
