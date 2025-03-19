if (-not (Get-Module -ListAvailable -Name Microsoft.Graph)) {
    # Module is not installed, install version 2.26.1
    Install-Module -Name Microsoft.Graph -Force -Scope CurrentUser
    Write-Host "Microsoft.Graph has been installed." -ForegroundColor Blue
} else {
    Write-Host "Microsoft.Graph module is already installed." -ForegroundColor Blue
}

Import-Module -Name Microsoft.Graph

# Login with corresponding scope. Should the tenant admin or anyone else have the permission.
Connect-MgGraph -Scopes "Application.ReadWrite.All,Directory.ReadWrite.All" 

# Set an app client ID
$appClientId = ""
# Set a friendly display name for the credential
$displayName = ""

# Get principal id by AppId
$appPrincipal = Get-MgServicePrincipal -Filter "AppId eq '$appClientId'" 
$params = @{
    PasswordCredential = @{
        DisplayName = $displayName
    }
}
$result = Add-MgServicePrincipalPassword -ServicePrincipalId $appPrincipal.Id -BodyParameter $params    # Update the secret
$base64Secret = [System.Convert]::ToBase64String([System.Text.Encoding]::UTF8.GetBytes($result.SecretText)) # Convert to base64 string.
$app = Get-MgServicePrincipal -ServicePrincipalId $appPrincipal.Id # get existing app information
$existingKeyCredentials = $app.KeyCredentials # read existing credentials
$dtStart = [System.DateTime]::Now # Start date
$dtEnd = $dtStart.AddYears(2) # End date (equals to secret end date)
$keyCredentials = @( # construct keys
    @{
        Type = "Symmetric"
        Usage = "Verify"
        Key = [System.Text.Encoding]::ASCII.GetBytes($result.SecretText)
        StartDateTime = $dtStart
        EndDateTIme = $dtEnd
    },
    @{
        type = "Symmetric"
        usage = "Sign"
        key = [System.Text.Encoding]::ASCII.GetBytes($result.SecretText)
        StartDateTime = $dtStart
        EndDateTIme = $dtEnd
    }
) + $existingKeyCredentials # combine with existing
Update-MgServicePrincipal -ServicePrincipalId $appPrincipal.Id -KeyCredentials $keyCredentials # Update keys

# Print base64 secret and end date
Write-Host "The secret is: $base64Secret" -ForegroundColor Green
Write-Host "The end date is: $($result.EndDateTime)" -ForegroundColor Yellow
