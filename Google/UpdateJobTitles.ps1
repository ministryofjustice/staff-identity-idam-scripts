# --- Test logging path
$testpath = Test-Path $env:userprofile\scripts\
    if ($testpath -ne $true) {
        new-item -Path $env:userprofile -Name scripts -ItemType Directory
        $testpath = Test-Path $env:userprofile\scripts\
        if ($testpath -ne $true) {
            write-host "failed to create log path, investigate before proceeding" -ForegroundColor Red
            pause
            exit
            }
        }

# --- Start variables
$Users = Import-Csv -Path \path\to\file.csv
# Change these next two as required
$companyName = "Service Transformation Group"
$officeLocation = "Justice Digital|Digital"
$date = get-date -Format dd-MM-yyyy-HHmm
$outputPre = "$env:userprofile\scripts\AdjustUsersPre$date.csv"
$outputPost = "$env:userprofile\scripts\AdjustUsersPost$date.csv"

# --- Start script execution

# --- Collect pre changes data
$preResults = foreach ($user in $users) {
    $upn = $user.UserPrincipalName
    Get-ADUser -Filter 'UserPrincipalName -eq $upn' -Property Name,SamAccountName,UserPrincipalName,Title,Department,physicalDeliveryOfficeName,Company | select Name,SamAccountName,UserPrincipalName,Title,Department,physicalDeliveryOfficeName,Company
}
$preResults | Export-Csv -path $outputPre -NoTypeInformation

# --- Make changes
foreach ($user in $Users) {
    $upn = $user.UserPrincipalName
    $jobTitle = $user.CSVJobTitle

    $adUser = Get-ADUser -Filter 'UserPrincipalName -eq $upn' -Property Name,SamAccountName,UserPrincipalName,Title,Department,physicalDeliveryOfficeName,Company | select Name,SamAccountName,UserPrincipalName,Title,Department,physicalDeliveryOfficeName,Company
    Write-Host "Inspecting $upn ..." -ForegroundColor Green
    
    if ($jobTitle -eq "") {
        Write-Host "No csv source job title, no action to take on this"
    }
    else {
        if ($adUser.Title -eq $null) {
            Write-Host "Job title is Null, will change to $jobTitle from csv source" -ForegroundColor Cyan
            Set-adUser $aduser.SamAccountName -Title "$jobTitle"
        }
        else {
            Write-Host "Job title is populated already, will ignore"
        }
    }

    Write-Host "Setting Company and Office to $companyName and $officeLocation" -ForegroundColor Cyan
    Set-ADUser $adUser.SamAccountName -Company $companyName -Office $officeLocation
}

# --- Collect post changes data
$postResults = foreach ($user in $users) {
    $upn = $user.UserPrincipalName
    Get-ADUser -Filter 'UserPrincipalName -eq $upn' -Property Name,SamAccountName,UserPrincipalName,Title,Department,physicalDeliveryOfficeName,Company | select Name,SamAccountName,UserPrincipalName,Title,Department,physicalDeliveryOfficeName,Company
}
$postResults | Export-Csv -path $outputPost -NoTypeInformation
