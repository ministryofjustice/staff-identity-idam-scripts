#Connet to Microsoft Graph
Connect-MgGraph -Scope "User.Read.All, Application.Read.All,  User.ReadWrite.All, Directory.Read.All, Application.ReadWrite.All, Policy.ReadWrite.AuthenticationMethod"

#Get all users and select only required properties
$allUsers = Get-MgUser -All -Property UserPrincipalName, GivenName, Surname, Mail, OfficeLocation, AccountEnabled | Select-Object UserPrincipalName, GivenName, Surname, Mail, OfficeLocation, AccountEnabled

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

#initialise array
$AllUsersPrisonIdentities = [System.Collections.Generic.List[Object]]::new()

#Loop through each user and add results to array
Foreach ($user in $allusers){
    if ($InputArray -contains $user.OfficeLocation) {
        $AllUsersPrisonIdentities.Add($user)
    }
}

$AllUsersPrisonIdentities | ConvertTo-Json -depth 10 | Out-File ".\PrisonIdentities.json"
$AllUsersPrisonIdentities | ConvertTo-Csv | Out-File ".\PrisonIdentities.csv" 
