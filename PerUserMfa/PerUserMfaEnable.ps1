Connect-MgGraph -Scopes "Policy.ReadWrite.AuthenticationMethod, UserAuthenticationMethod.ReadWrite.All" -NoWelcome

$userId = "UUID"
$json = @{
	perUserMfaState = "enabled"
}

# Check existing status
Invoke-MgGraphRequest -Method GET -Uri "/beta/users/$userId/authentication/requirements" -OutputType PSObject | Select-Object PerUserMFAState

# Update MFA State
Invoke-MgGraphRequest -Method PATCH -Uri "/beta/users/$userId/authentication/requirements" -OutputType PSObject -Body $json -ContentType "application/json" | Select-Object PerUserMFAState

# Check new status
Invoke-MgGraphRequest -Method GET -Uri "/beta/users/$userId/authentication/requirements" -OutputType PSObject | Select-Object PerUserMFAState
