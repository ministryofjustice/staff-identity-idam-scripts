#Connet to Microsoft Graph
Connect-MgGraph -Scope "User.Read.All, Directory.Read.All"

#Get all users and select only required properties
$allUsers = Get-MgUser -All -Property UserPrincipalName, GivenName, Surname, Mail, OfficeLocation, AccountEnabled, CompanyName, Country, CreatedDateTime, DeletedDateTime, Department, DisplayName, EmployeeId, EmployeeType, FaxNumber, MobilePhone, BusinessPhone, Id, Identity, JobTitle, LastPasswordChangeDateTime, Mail, MailNickname, Manager, OnPremisesImmutableId, OnPremisesLastSyncDateTime, OnPremisesSyncEnabled, OtherMail, StreetAddress, PostalCode, City, State, TrustType, UserType | Select-Object UserPrincipalName, GivenName, Surname, OfficeLocation, AccountEnabled, CompanyName, Country, CreatedDateTime, DeletedDateTime, Department, DisplayName, EmployeeId, EmployeeType, FaxNumber, MobilePhone, BusinessPhone, Id, Identity, JobTitle, LastPasswordChangeDateTime, MailNickname, Manager, OnPremisesImmutableId, OnPremisesLastSyncDateTime, OnPremisesSyncEnabled, OtherMail, StreetAddress, PostalCode, City, State, TrustType, UserType

#initialise array
$AllUsersPrisonIdentities = [System.Collections.Generic.List[Object]]::new()

#Loop through each user and add results to array
Foreach ($user in $allusers) {
    #if ($user.AccountEnabled) {
        $AllUsersPrisonIdentities.Add($user)
    #}
}

$AllUsersPrisonIdentities | ConvertTo-Json -depth 10 | Out-File ".\UserIdentities.json"
$AllUsersPrisonIdentities | ConvertTo-Csv | Out-File ".\UserIdentities.csv"



