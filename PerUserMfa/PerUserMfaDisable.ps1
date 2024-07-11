Connect-MgGraph -Scopes "Policy.ReadWrite.AuthenticationMethod, UserAuthenticationMethod.ReadWrite.All" -NoWelcome

$json = @{
	perUserMfaState = "disable"
}

# Read JSON File
$allUsers = Get-Content -Path ".\allUsersPerUserMFAState.json" | ConvertFrom-Json

# Loop and find per-user mfa enabled
Foreach ($user in $allusers)
{
	if ($user.mfastate = "enabled") {
		$userId = $user.id

		# Update MFA State
		Invoke-MgGraphRequest -Method PATCH -Uri "/beta/users/$userId/authentication/requirements" -OutputType PSObject -Body $json -ContentType "application/json"
	}
}
