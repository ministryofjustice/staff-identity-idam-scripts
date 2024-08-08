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
    [Parameter(Mandatory = $true, ParameterSetName = 'Single')][ValidateScript({
            if ($_ -notmatch "(@)") {
                throw "The UPN specified must be in a valid format."
            }
            return $true
        })][string]$userUPN #User account to be revoked
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

    if (-not (Get-MgContext)) {
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
        Throw
    }

    Write-LogInfo "Sucessfully got $UserUPN user details"
    return $user
}

function Revoke-User-Disable-Account($userDetails) {    
    Write-LogInfo "Disabling account for $($userDetails.Id)"
    Try {
        Update-MgUser -UserId $userId -AccountEnabled:$false
    }
    catch {
        Write-LogError "Unable to disable user account $($userDetails.DisplayName) - $($userDetails.Id). Script cannot continue."
        Stop-Transcript
        Disconnect-MgGraph
        Throw
    }
    Write-LogInfo "User successfully disabled"
}

function Revoke-User-Sessions($userDetails) {
    Write-LogInfo "Revoking user sign in sessions for $($userDetails.Id)"
    Try {
        Revoke-MgUserSignInSession -UserId $userId
        Write-LogInfo "User Sign In Sessions successfully revoked"
    }
    catch {
        Write-LogError "Unable to revoke user sessions for $($userDetails.DisplayName) - $($userDetails.Id)."
    }    
}

function Revoke-User-Devices($userDetails) {
    Write-LogInfo "Disabling users devices."

    $Devices = $null
    Try {
        Write-LogInfo "Get all users devices."
        $Devices = Get-MgUserRegisteredDevice -UserId $userDetails.Id
    }
    catch {
        Write-LogError "Unable to fetch registered devices for $($userDetails.DisplayName) - $($userDetails.Id)."
    }   
    Write-LogInfo "Found $($Devices.Count) devices."
    if ($Devices.Count -gt 0) {
        foreach ($Device in $Devices) {
            Write-LogInfo "Disabling device $($Device.DisplayName) - $($Device.Id)"
            Try {
                Update-MgDevice -DeviceId $Device.Id -AccountEnabled:$false
                Write-LogInfo "Disabled device $($Device.DisplayName) - $($Device.Id) successfully"
            }
            catch {
                Write-LogError "Unable to disable device  $($Device.DisplayName) - $($Device.Id)."
            }   
        }
        Write-LogInfo "Users devices successfully revoked"
    }
    else {
        Write-LogWarn "No user devices available to be revoked."
    }
}

# --- Start Script Execution
Start-Transcript -Path "$($scriptname)_$(get-date -Format "yyyy-MM-dd_HHmmss").log" -Append
Write-LogInfo "Starting execution of the $($scriptname) Script"

Write-LogInfo "Validating that all required modules are installed (this can take some time)"
Install-Required-Modules
Write-LogInfo "Modules installed"

# Connect to EntraID using interactive credentials
Connect-To-MgGraph

# Get user object from Entra
$userDetails = Get-User-Object

# Perform User Disablement
Revoke-User-Disable-Account($userDetails)

# Perform User Session Disablement
Revoke-User-Sessions($userDetails)

# Perform revocation
Revoke-User-Devices($userDetails)

if ($errorcount -gt 0) { Write-LogWarn "Script execution finished with $($errorcount) Errors and $($warncount) Warnings" }
elseif ($warncount -gt 0) { Write-LogWarn "Script execution finished with $($errorcount) Errors and $($warncount) Warnings" }
else { Write-LogInfo "Script execution finished with $($errorcount) Errors and $($warncount) Warnings" }

Stop-Transcript
