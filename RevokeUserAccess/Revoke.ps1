<#
    .SYNOPSIS
    A script to disable a user's Entra account, revoke refresh tokens and disables user's device.
    
    .DESCRIPTION
    Leverage Microsoft Graph API and PowerShell to disable a user's Entra account, revoke refresh tokens and disables user's device.

    .PARAMETER userUPN
    The User Principle Name of the identity to revoke
    
    .EXAMPLE
    Revoke.ps1 -userUPN user1@domain.com
    Disable a user's Entra account, revoke refresh tokens and disables user's device.
#>
[CmdletBinding(DefaultParameterSetName = 'Single')]
param(
    [Parameter(Mandatory = $true, ParameterSetName = 'Single')][string]$userUPN #User account to be given a particular role
)

# Allows display of Write-Information output
$InformationPreference = 'Continue'

# --- Start variables 
$scriptname = "Revoke-User"
$mgGraphScopes = "User.ReadWrite.All"
$requiredModules = @("Microsoft.Graph")

$infocount = 0
$warncount = 0
$errorcount = 0

# --- Start Functions
function Write-LogInfo($logentry) {
    Write-Information "$(get-date -Format "yyyy-MM-dd HH:mm:ss K") - $($logentry)"
    $script:infocount++
}
function Write-LogWarn($logentry) {
    Write-Warning "$(get-date -Format "yyyy-MM-dd HH:mm:ss K") - $($logentry)"
    $script:warncount++
}

function Write-LogError($logentry) {
    Write-Error "$(get-date -Format "yyyy-MM-dd HH:mm:ss K") - $($logentry)"
    $script:errorcount++
}

function Install-Required-Modules() {
    foreach ($requiredModule in $requiredModules) {
        $module = Import-Module $requiredModule -PassThru -ErrorAction Ignore
        if (-not $module) {
            Write-LogInfo "$($requiredModule) module not found, Attempting to install"
            Install-Module $requiredModule -Force 
            $module = Import-Module $requiredModule -PassThru -ErrorAction Ignore
            if ($module) {
                Write-LogInfo "$($module.Name) module installed successfully"
            }
            else {
                Write-LogError "Error Installing $($requiredModule) module. Script will continue"
            }
        }
    }
}

function Connect-To-MgGraph() {
    Connect-MgGraph -Scopes $mgGraphScopes -NoWelcome

    if (-not (get-mgcontext)) {
        write-error "No graph connection detected. Cannot continue"
        Stop-Transcript
        Throw
    }
}

function Get-User-Object() {
    
    Write-LogInfo "Fetch $UserUPN details from Entra"
    $user = Get-MgUser -Filter "UserPrincipalName eq '$($UserUPN)'"  -ConsistencyLevel eventual

    if ($user.Count -eq 0) {
        Write-LogError "User $UserUPN not found. Script cannot continue"
        Stop-Transcript
        Disconnect-MgGraph
        throw
    }

    Write-LogInfo "Sucessfully got $UserUPN user details"
    return $user
}

function Revoke-User-Account() {
    
    # Get user object from Entra
    $userDetails = Get-User-Object

    Write-LogInfo "Disabling account for $($userDetails.Id)"
    #Update-MgUser -UserId $userDetails.Id -AccountEnabled:$false
    Write-LogInfo "User successfully disabled"
    
    Write-LogInfo "Revoking user sign in sessions for $($userDetails.Id)"
    #Revoke-MgUserSignInSession -UserId $userDetails.Id
    Write-LogInfo "User Sign In Sessions successfully revoked"

    Write-LogInfo "Disabling users devices."
    $Devices = Get-MgUserRegisteredDevice -UserId $userDetails.Id
    Write-LogInfo "Found $($Devices.Count) devices."
    foreach ($Device in $Devices) {
        Write-LogInfo "Disabling device $($Device.DisplayName) - $($Device.Id)"
        #Update-MgDevice -DeviceId $Device.Id -AccountEnabled:$false
        Write-LogInfo "Disabled device $($Device.DisplayName) - $($Device.Id) successfully"
    }
    Write-LogInfo "Users devices successfully revoked"
}

# --- Start Script Execution
Start-Transcript -Path "$($scriptname)_$(get-date -Format "yyyy-MM-dd_HHmmss").log" -Append
Write-LogInfo "Starting execution of the $($scriptname) Script"

Write-LogInfo "Validating that all required modules are installed"
Install-Required-Modules
Write-LogInfo "Modules installed"

# Connect to EntraID using interactive credentials
Connect-To-MgGraph

# Perform revocation
Revoke-User-Account

if ($errorcount -gt 0) { Write-LogWarn "Script execution finished with $($errorcount) Errors and $($warncount) Warnings" }
elseif ($warncount -gt 0) { Write-LogWarn "Script execution finished with $($errorcount) Errors and $($warncount) Warnings" }
else { Write-LogInfo "Script execution finished with $($errorcount) Errors and $($warncount) Warnings" }

Stop-Transcript
