# Connect to Microsoft Graph with the required scopes
Connect-MgGraph -Scopes "User.Read.All", "UserAuthenticationMethod.Read.All"

# Get MFA report
$AllMFA = Get-MgReportAuthenticationMethodUserRegistrationDetail -All
# Trim to non-guests
$users = $AllMFA | Where-Object UserType -EQ "member"


# stats
$total = $users.Count

$enrolled = $users | Where-Object IsMfaRegistered -EQ $True | Measure-Object
$authenticator = $users | Where-Object MethodsRegistered -Like *Authenticator* | Measure-Object # or 'softwareOneTimePasscode' ?
$phone = $users | Where-Object MethodsRegistered -Like *phone* | Measure-Object
$hardware = $users | Where-Object MethodsRegistered -Like *hardwareOneTimePasscode* | Measure-Object
$whfb = $users | Where-Object MethodsRegistered -Like *windowsHelloForBusiness* | Measure-Object

$statsObject = [PSCustomObject]@{
        TotalEnabledNonGuestUsers = $total
        MFAenrolled               = $enrolled.count
        MFAenrolledPercent        = [math]::Round($enrolled.Count/$total*100,2)
        PhoneMFAPercent           = [math]::Round($phone.Count/$total*100,2)
        AuthenticatorMFAPercent   = [math]::Round($authenticator.Count/$total*100,2)
        HardwareMFAPercent        = [math]::Round($hardware.Count/$total*100,2)
        WindowsHelloMFAPercent    = [math]::Round($whfb.Count/$total*100,2)
    }

$statsObject
