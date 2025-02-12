<#
    .SYNOPSIS
    A script to deactivate user accounts
     
    .DESCRIPTION
    Utilises an input file which should contain a list of targeted UPNs, these users will then be deactivated, have a description added, and moved to a "TO_BE_DELETED" OU.
#>

# --- Start variables

# Test user, you can add a test user
$user = ""

# Enter the path for your input file here, it should contain 1 UPN per line with no headers
$file = #put file path here
$domain = Get-ADDomain | select DistinguishedName
$OUPath = "OU=TO_BE_DELETED,"+$domain.DistinguishedName

$users = get-content $file
$date = get-date -Format dd-MM-yyyy-HHmm
$testpath = Test-Path $env:userprofile\scripts\
    if ($testpath -ne $true){
        new-item -Path $env:userprofile -Name scripts -ItemType Directory
        $testpath = Test-Path $env:userprofile\scripts\
        if ($testpath -ne $true){
            write-host "failed to create log path, investigate before proceeding" -ForegroundColor Red
            pause
            exit
            }
        }
$outputPre = "$env:userprofile\scripts\DeactivateUsersPre$date.csv"
$outputPost = "$env:userprofile\scripts\DeactivateUsersPost$date.csv"

# --- Start script execution

$preResults = foreach ($user in $users){
    get-aduser -filter 'UserPrincipalName -like $user' -Properties Description | Select Name,UserPrincipalName,Enabled,Description,DistinguishedName,@{n='OU';e={$_.DistinguishedName -replace '^.*?,(?=[A-Z]{2}=)'}}
    }
$preResults | Export-Csv -path $outputPre -NoTypeInformation

$preResults | select Name
$check = read-host "Are you ready to proceed with deactivation of the above users? Type YES and press Enter"
if ($check -ne "YES"){
    write-host "exiting" -ForegroundColor Yellow
    Start-Sleep -seconds 2
    exit}

write-host "proceeding in 10 seconds..." -ForegroundColor Cyan
Start-Sleep -Seconds 10

foreach ($user in $users){
    set-aduser $user.Split("@")[0] -Description "Deactivated - DualRunner" -Enabled $false
    get-aduser $user.Split("@")[0] | Move-ADObject -TargetPath $OUPath
}

$postResults = foreach ($user in $users){
    get-aduser -filter 'UserPrincipalName -like $user' -Properties Description | Select Name,UserPrincipalName,Enabled,Description,DistinguishedName,@{n='OU';e={$_.DistinguishedName -replace '^.*?,(?=[A-Z]{2}=)'}}
    }
$postResults | Export-Csv -path $outputPost -NoTypeInformation

