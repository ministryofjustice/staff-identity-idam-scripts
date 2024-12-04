<#
    .SYNOPSIS
    Assign Policy to Application
    
    .DESCRIPTION
    Assigns a policy to an Application. You will need to provide the Policy ID, obtained from GetPolicies.ps1 and the Application ID from Entra ID.
#>

Import-Module Microsoft.Graph.Identity.SignIns

#Connet to Microsoft Graph
Connect-MgGraph -Scope "Policy.Read.All"

$tokenLifetimePolicyId = "policyid_guid"
$applicationId = "applicationid_guid"

# Assign the policy to an application
$params = @{
    "@odata.id" = "https://graph.microsoft.com/v1.0/policies/tokenLifetimePolicies/$tokenLifetimePolicyId"
}

New-MgApplicationTokenLifetimePolicyByRef -ApplicationId $applicationId -BodyParameter $params
