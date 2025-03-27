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
$Users = Import-Csv -Path \path\to\file.csv #this should be the OUTPUT_PRE file from the run you wish to backout
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
    $jobTitle = $user.Title
    $company_name = $user.Company
    $office_location = $user.physicalDeliveryOfficeName

    $adUser = Get-ADUser -Filter 'UserPrincipalName -eq $upn' -Property Name,SamAccountName,UserPrincipalName,Title,Department,physicalDeliveryOfficeName,Company | select Name,SamAccountName,UserPrincipalName,Title,Department,physicalDeliveryOfficeName,Company
    Write-Host "Inspecting $upn ..." -ForegroundColor Green
    Write-Host "Reverting job title, will change to $jobTitle from csv source" -ForegroundColor Cyan
    Set-adUser $user.SamAccountName -Title "$jobTitle"
    Write-Host "Setting Company and Office to $company_name and $office_location" -ForegroundColor Cyan
    Set-ADUser $user.SamAccountName -Company $company_name -Office $office_location
}

# --- Collect post changes data
$postResults = foreach ($user in $users) {
    $upn = $user.UserPrincipalName
    Get-ADUser -Filter 'UserPrincipalName -eq $upn' -Property Name,SamAccountName,UserPrincipalName,Title,Department,physicalDeliveryOfficeName,Company | select Name,SamAccountName,UserPrincipalName,Title,Department,physicalDeliveryOfficeName,Company
}
$postResults | Export-Csv -path $OUTPUT_POST -NoTypeInformation
