Connect-Entra -Scopes "Application.Read.All"

$expirationThreshold = (Get-Date)
$applicationList = Get-EntraApplication -All
$clientSecretApps = $applicationList | Where-Object {$_.passwordCredentials}
$applicationsWithNoOwners = 0
$applicationsWithExpiredCredentials = 0

foreach ($application in $applicationList) {

    $owners = Get-MgApplicationOwner -ApplicationId $application.Id
    if ($owners.Count -eq 0) {
        $applicationsWithNoOwners = $applicationsWithNoOwners + 1
    }
}

foreach ($application in $clientSecretApps) {

    $credentialsExpired = $application.PasswordCredentials | Where-Object { $_.EndDate -le $expirationThreshold }
    if ($credentialsExpired.Count -gt 0) {
        $applicationsWithExpiredCredentials = $applicationsWithExpiredCredentials + 1
    }
}

[PSCustomObject][ordered]@{
    "TotalApplications" = $applicationList.Count
    "ApplicationsWithNoOweners" = $applicationsWithNoOwners
    "ApplicationsWithExpiredCredentials" = $applicationsWithExpiredCredentials
}
