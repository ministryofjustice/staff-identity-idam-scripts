<#
    .SYNOPSIS
    Get all policies assigned to Application
    
    .DESCRIPTION
    Get any policies that are assigned to an Application. If returns no results then it is using the default policy.
#>

Import-Module Microsoft.Graph.Identity.SignIns

#Connet to Microsoft Graph
Connect-MgGraph -Scope "Policy.Read.All"

$applicationId = "applicationid_guid"

Get-MgApplicationTokenLifetimePolicy -ApplicationId $applicationId
