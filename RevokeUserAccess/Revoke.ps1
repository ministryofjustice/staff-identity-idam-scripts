Connect-MgGraph -Scopes "User.ReadWrite.All" -NoWelcome
Import-Module Microsoft.Graph.Beta.Applications

Write-Host "Welcome to the Revoke user access in Microsoft Entra ID PowerShell script.`n" -ForegroundColor Green
Write-Host "For more information on this process, consult the following Microsoft Knowledge Article: https://learn.microsoft.com/en-us/entra/identity/users/users-revoke-access#microsoft-entra-environment.`n" -ForegroundColor Green
Write-Host "Warning: Running this script will disable a users account and device. Please ensure you understand the process fully before going any further.`n" -ForegroundColor Red

$UserUPN = Read-Host -Prompt "Enter users principle name to be revoked"

if (!$UserUPN) {
    Write-Error "UPN empty."
    return
}

$user = Get-MgBetaUser -Search UserPrincipalName:$UserUPN -ConsistencyLevel eventual | Format-List  ID, DisplayName, Mail, UserPrincipalName

if ($user.Count -eq 0) {
    Write-Error "User $UserUPN not found."
    return
}

if ($user.Count -ne 5) {
    Write-Error "Multiple users found for search: $UserUPN."
    return
}

Write-Host "`n$UserUPN details" -ForegroundColor Blue
$user

$ConfirmCorrectUser = Read-Host -Prompt "Are the above details correct? If so, please re-enter the users principle name to continue"

if ($UserUPN -ne $ConfirmCorrectUser) {
    Write-Error "UPN values do not match. Process cancelled."
    return
}

# Step 1
Write-Host "`nStep 1 - Disable users account in Entra." -ForegroundColor Blue

$ConfirmStep = Read-Host -Prompt "Enter Y to continue"

if ($ConfirmStep.ToLower() -ne "y") {
    Write-Error "Process cancelled at Step 1."
    return
}

# Update-MgUser -UserId $user.Id -AccountEnabled:$false

Write-Host "Step 1 Complete. $UserUPN disabled." -ForegroundColor Green

# Step 2
Write-Host "`nStep 2 - Revoke the user's Microsoft Entra ID refresh tokens." -ForegroundColor Blue

$ConfirmStep = Read-Host -Prompt "Enter Y to continue"

if ($ConfirmStep.ToLower() -ne "y") {
    Write-Error "Process cancelled at Step 2."
    return
}

# Revoke-MgUserSignInSession -UserId $user.Id

Write-Host "Step 2 Complete. $UserUPN refresh tokens revoked." -ForegroundColor Green

# Step 3
Write-Host "`nStep 3 - Disable the user's devices." -ForegroundColor Blue

$ConfirmStep = Read-Host -Prompt "Enter Y to continue"

if ($ConfirmStep.ToLower() -ne "y") {
    Write-Error "Process cancelled at Step 3."
    return
}

# $Device = Get-MgUserRegisteredDevice -UserId $User.Id 
# Update-MgDevice -DeviceId $Device.Id -AccountEnabled:$false

Write-Host "Step 3 Complete. $UserUPN devices disabled." -ForegroundColor Green

# Process completed
Write-Host "`nEntra User successfully disabled." -ForegroundColor Green
