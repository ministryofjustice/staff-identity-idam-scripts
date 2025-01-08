#Connet to Microsoft Graph
Connect-MgGraph -Scope "User.Read.All, Application.Read.All,  User.ReadWrite.All, Directory.Read.All, Application.ReadWrite.All, Policy.ReadWrite.AuthenticationMethod, AuditLog.Read.All"

#Get all users and select only required properties
#$allUsers = Get-MgUser -Top 2000 -Property UserPrincipalName, GivenName, Surname, Mail, OfficeLocation, AccountEnabled, SignInActivity | Select-Object UserPrincipalName, GivenName, Surname, Mail, OfficeLocation, AccountEnabled, SignInActivity
$allUsers = Get-MgUser -All -Property UserPrincipalName, GivenName, Surname, Mail, OfficeLocation, AccountEnabled, SignInActivity | Select-Object UserPrincipalName, GivenName, Surname, Mail, OfficeLocation, AccountEnabled, SignInActivity

$InputArray = @(
    "HMP Altcourse",
    "HMP Ashfield",
    "HMP Bronzefield",
    "HMP Doncaster",
    "HMP Dovegate",
    "HMP Five Wells",
    "HMP Forest Bank",
    "HMP Fosse Way",
    "HMP Northumberland",
    "HMP Oakwood",
    "HMP Parc",
    "HMP Peterborough",
    "HMP Rye Hill",
    "HMP Thameside"
)

$AllUsersPrisonIdentities = [System.Collections.Generic.List[Object]]::new()

Foreach ($user in $allusers) {
    if ($InputArray -contains $user.OfficeLocation) {

        $LastLoginDate = $user.SignInActivity.LastSignInDateTime
        $user | Add-Member -MemberType NoteProperty -Name LastLoginDate -Value $LastLoginDate -Force
        $user.PSObject.Properties.Remove('SignInActivity')
        
        $LicenceList = ""
        $LicensesData = Get-MgUserLicenseDetail -userid $user.UserPrincipalName
        foreach ($x in $LicensesData) {
            $Licenses = $x.SkuPartNumber
            
            foreach ($License in $Licenses) {
                if ($License -eq "M365_E5_SUITE_COMPONENTS") {
                    $LicenceList = $License
                }
            }
        }

        $user | Add-Member -Name Licences -Value $LicenceList -MemberType NoteProperty
        
        $AllUsersPrisonIdentities.Add($user)
    }
}

$AllUsersPrisonIdentities | ConvertTo-Json -depth 10 | Out-File ".\PrisonIdentities.json"
$AllUsersPrisonIdentities | ConvertTo-Csv | Out-File ".\PrisonIdentities.csv" 
