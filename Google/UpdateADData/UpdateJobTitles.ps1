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
$COMPANY_NAME = "Service Transformation Group"
$OFFICE_LOCATION = "Justice Digital|Digital"
$DATE = get-date -Format dd-MM-yyyy-HHmm
$OUTPUT_PRE = "$env:userprofile\scripts\AdjustUsersPre$DATE.csv"
$OUTPUT_POST = "$env:userprofile\scripts\AdjustUsersPost$DATE.csv"

# --- Start script execution

# --- Collect pre changes data
$preResults = foreach ($user in $users) {
    $upn = $user.UserPrincipalName
    Get-ADUser -Filter 'UserPrincipalName -eq $upn' -Property Name,SamAccountName,UserPrincipalName,Title,Department,physicalDeliveryOfficeName,Company | select Name,SamAccountName,UserPrincipalName,Title,Department,physicalDeliveryOfficeName,Company
}
$preResults | Export-Csv -path $OUTPUT_PRE -NoTypeInformation

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

    Write-Host "Setting Company and Office to $COMPANY_NAME and $OFFICE_LOCATION" -ForegroundColor Cyan
    Set-ADUser $adUser.SamAccountName -Company $COMPANY_NAME -Office $OFFICE_LOCATION
}

# --- Collect post changes data
$postResults = foreach ($user in $users) {
    $upn = $user.UserPrincipalName
    Get-ADUser -Filter 'UserPrincipalName -eq $upn' -Property Name,SamAccountName,UserPrincipalName,Title,Department,physicalDeliveryOfficeName,Company | select Name,SamAccountName,UserPrincipalName,Title,Department,physicalDeliveryOfficeName,Company
}
$postResults | Export-Csv -path $OUTPUT_POST -NoTypeInformation
