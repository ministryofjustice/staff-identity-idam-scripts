<#
    .SYNOPSIS
    A script to check MFA status for user accounts
     
    .DESCRIPTION
    Utilises an input file which should contain a list of targeted UPNs, these users will then be queried to identify authentication methods.
#>

# User list of UPNs withthe  heading UserPrincipalName
$list = import-csv '.\userlist.csv'

# Connect to Microsoft Graph with the required scopes
Connect-MgGraph -Scopes "User.Read.All", "UserAuthenticationMethod.Read.All"

# Build user list, without the user ID, later section can encounter issues
$users = foreach ($item in $list) {
    get-mguser -UserId $item.UserPrincipalName
}

$results = $null
$count = 0

# Check MFA for each user account
foreach ($user in $users) {
    $count++
    Write-Host "Inspecting user $($user.DisplayName) [$count/$($users.Count)]" -ForegroundColor Cyan
    $obj = [PSCustomObject]@{
        user               = "-"
        MFAstatus          = "-"
        email              = "-"
        fido2              = "-"
        app                = "-"
        password           = "-"
        phone              = "-"
        softwareoath       = "-"
        tempaccess         = "-"
        hellobusiness      = "-"
    }

    $MFAData = Get-MgUserAuthenticationMethod -UserId $user.Id

    $obj.user = $user.UserPrincipalName
    
    # Check authentication methods for each user
    ForEach ($method in $MFAData) {
    
            Switch ($method.AdditionalProperties["@odata.type"]) {
              "#microsoft.graph.emailAuthenticationMethod"  {
                 $obj.email = $true
                 $obj.MFAstatus = "Enabled"
              }
              "#microsoft.graph.fido2AuthenticationMethod"                   {
                $obj.fido2 = $true
                $obj.MFAstatus = "Enabled"
              }
              "#microsoft.graph.microsoftAuthenticatorAuthenticationMethod"  {
                $obj.app = $true
                $obj.MFAstatus = "Enabled"
              }
              "#microsoft.graph.passwordAuthenticationMethod"                {
                    $obj.password = $true
                    # When only the password is set, then MFA is disabled.
                    if($obj.MFAstatus -ne "Enabled")
                    {
                        $obj.MFAstatus = "Disabled"
                    }
               }
               "#microsoft.graph.phoneAuthenticationMethod"  {
                $obj.phone = $true
                $obj.MFAstatus = "Enabled"
              }
                "#microsoft.graph.softwareOathAuthenticationMethod"  {
                $obj.softwareoath = $true
                $obj.MFAstatus = "Enabled"
              }
                "#microsoft.graph.temporaryAccessPassAuthenticationMethod"  {
                $obj.tempaccess = $true
                $obj.MFAstatus = "Enabled"
              }           
                "#microsoft.graph.windowsHelloForBusinessAuthenticationMethod"  {
                $obj.hellobusiness = $true 
                $obj.MFAstatus = "Enabled"
              }                   
            }
        }

    # Collecting objects
    [array]$results += $obj
}

# Display the results
$results | Format-Table

# Example export options
$results | Export-Csv -Path "$exportPath-AllResults.csv" -NoTypeInformation
$results | Where-Object {$_.MFAstatus -EQ "Disabled"} | Export-Csv -Path "$exportPath-MFANotConfigured.csv" -NoTypeInformation
