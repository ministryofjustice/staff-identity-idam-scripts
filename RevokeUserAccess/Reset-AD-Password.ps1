<#
    .SYNOPSIS
    A script to reset a user's AD account password.
    
    .DESCRIPTION
    Leverage Microsoft Graph API and PowerShell to reset a users AD account password to a random password. To run this script you must ensure you have Remote Server Administration Tools (RSAT) package installed. To do so, follow the steps in this article https://learn.microsoft.com/en-gb/troubleshoot/windows-server/system-management-components/remote-server-administration-tools

    .PARAMETER userUPN
    The User Principle Name of the identity to password reset
    
    .EXAMPLE
    Reset-AD-Password.ps1 -userUPN user1@domain.com
    Reset a users AD Password.
#>
[CmdletBinding(DefaultParameterSetName = 'Single')]
param(
    [Parameter(Mandatory = $true, ParameterSetName = 'Single')][ValidateScript({
            if ($_ -notmatch "(@)") {
                throw "The UPN specified must be in a valid format."
            }
            return $true
        })][string]$userUPN #User account for password reset
)

# Allows display of Write-Information output
$InformationPreference = 'Continue'

# --- Start variables
$scriptname = "Reset-AD-Password"
$requiredModules = @("ActiveDirectory")
$passwordResetLoops = 2

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
                Write-LogError "Error Installing $($requiredModule) module. To run this script you must ensure you have Remote Server Administration Tools (RSAT) package installed. To do so, follow the steps in this article https://learn.microsoft.com/en-gb/troubleshoot/windows-server/system-management-components/remote-server-administration-tools"
                Stop-Transcript
                Throw
            }
        }
    }    
}

function Reset-AD-Password() {
    
    Write-LogInfo "Resetting password for $($userUPN) $($passwordResetLoops) times"
    for (($i = 0); $i -lt $passwordResetLoops; $i++)
    {
        $randomPassword = -join ((33..126) | Get-Random -Count 16 | ForEach-Object { [char]$_ })
        Try {
            Set-ADAccountPassword -Identity $userUPN -Reset -NewPassword (ConvertTo-SecureString -AsPlainText $randomPassword -Force)}
        }
        catch {
            Write-LogError "Unable to resset user password $($userUPN). Script cannot continue."
            Stop-Transcript
            Throw
        }
        Write-LogInfo "Password rotated"
    }
}

# --- Start Script Execution
Start-Transcript -Path "$($scriptname)_$(get-date -Format "yyyy-MM-dd_HHmmss").log" -Append
Write-LogInfo "Starting execution of the $($scriptname) Script"

Write-LogInfo "Validating that all required modules are installed (this can take some time)"
Install-Required-Modules
Write-LogInfo "Modules installed"

Reset-AD-Password

if ($errorcount -gt 0) { Write-LogWarn "Script execution finished with $($errorcount) Errors and $($warncount) Warnings" }
elseif ($warncount -gt 0) { Write-LogWarn "Script execution finished with $($errorcount) Errors and $($warncount) Warnings" }
else { Write-LogInfo "Script execution finished with $($errorcount) Errors and $($warncount) Warnings" }

Stop-Transcript
