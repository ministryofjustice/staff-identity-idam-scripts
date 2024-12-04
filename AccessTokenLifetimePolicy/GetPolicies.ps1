<#
    .SYNOPSIS
    Get all policies
    
    .DESCRIPTION
    Get all policies available in the tenent.
#>

Import-Module Microsoft.Graph.Identity.SignIns

#Connet to Microsoft Graph
Connect-MgGraph -Scope "Policy.Read.All"

Get-MgPolicyTokenLifetimePolicy -All | Select-Object Id, DisplayName, Definition
