Connect-MgGraph -Scopes "Policy.ReadWrite.AuthenticationMethod" -NoWelcome

$userId = "b745babf-c6f1-4ea1-9dc2-a71b45c0ef91"
Invoke-MgGraphRequest -Method GET -Uri "/beta/users/$userId/authentication/requirements" -OutputType PSObject | Select-Object PerUserMFAState
