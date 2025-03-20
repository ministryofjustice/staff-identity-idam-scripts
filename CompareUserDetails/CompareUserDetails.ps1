<#
    .SYNOPSIS
    A script to compare job title and department from a csv to that stored in Entra

    .DESCRIPTION
    This script does the following:
    - Imports user data from a CSV file. (This expects the headings: UserPrincipalName,JobTitle,Department)
    - Connects to Microsoft Graph to retrieve user data from Microsoft Entra ID.
    - Compares job titles and departments from the csv to those stored in Entra, then stores the results in a list.
    - Outputs the comparison results in a table format, showing the user principal name, job title and department from the CSV, to the job title and department from Entra ID side by side.

    Make sure to replace "path\to\your\file.csv" with the actual path to your CSV file.
#>

# Import the CSV file
$csvUsers = Import-Csv -Path "path\to\your\file.csv"

# Connect to Microsoft Graph
Connect-MgGraph -Scopes "User.Read.All"

# Get users from Microsoft Entra ID
$entraUsers = Get-MgUser -All -Property UserPrincipalName,JobTitle,Department | select UserPrincipalName,JobTitle,Department

# Create a list to store comparison results
$comparisonResults = @()
$count = 1

# Compare job titles and department
foreach ($csvUser in $csvUsers) {
    Write-Host "Currently on user [$count/$($csvUsers.Count)]"
    $count++

    $entraUser = $null
    $user = $csvUser.UserPrincipalName
    $entraUser = Get-MgUser -filter “userPrincipalName eq '$user'” -Property UserPrincipalName,JobTitle,Department | select UserPrincipalName,JobTitle,Department

    if ($entraUser) {
        $comparisonResults += [PSCustomObject]@{
            UserPrincipalName = $csvUser.UserPrincipalName
            CSVJobTitle = $csvUser.JobTitle
            CSVDepartment = $csvUser.Department
            EntraIDJobTitle = $entraUser.JobTitle
            EntraIDDepartment = $entraUser.Department
        }
    } else {
        $comparisonResults += [PSCustomObject]@{
            UserPrincipalName = $csvUser.UserPrincipalName
            CSVJobTitle = $csvUser.JobTitle
            CSVDepartment = $csvUser.Department
            EntraIDJobTitle = "Not Found"
            EntraIDDepartment = "Not Found"
        }
    }
}

# Output the comparison results (you can output this to a file if desired)
$comparisonResults | Format-Table -AutoSize
