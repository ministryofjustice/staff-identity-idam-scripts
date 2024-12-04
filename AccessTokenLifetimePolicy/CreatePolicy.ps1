<#
    .SYNOPSIS
    Create Policy
    
    .DESCRIPTION
    Creates a new Policy to be used with Application Registrations. Ensure you check for existing policies before creating a new one to reduce technical debt.
#>

Import-Module Microsoft.Graph.Identity.SignIns

#Connet to Microsoft Graph
Connect-MgGraph -Scope "Policy.Read.All"

# Create a token lifetime policy
$params = @{
    Definition = @('{"TokenLifetimePolicy":{"Version":1,"AccessTokenLifetime":"8:00:00"}}')
    DisplayName = "WebPolicyScenario8Hours"
    IsOrganizationDefault = $false
}
$tokenLifetimePolicyId = (New-MgPolicyTokenLifetimePolicy -BodyParameter $params).Id

$tokenLifetimePolicyId
