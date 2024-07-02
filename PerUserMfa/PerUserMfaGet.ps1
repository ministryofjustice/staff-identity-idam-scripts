Connect-MgGraph -Scopes "Policy.ReadWrite.AuthenticationMethod" -NoWelcome

$userId = "UUID"
Invoke-MgGraphRequest -Method GET -Uri "/beta/users/$userId/authentication/requirements" -OutputType PSObject | Select-Object PerUserMFAState
