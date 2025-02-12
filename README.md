# Staff Identity IDAM Scripts

This repo holds PowerShell scripts that are used to manage areas of Entra ID. These scripts should be kept up to date in this locations as the source of truth maintaining an audit trail of changes and detailed explanations of what each one does.

## Structure

Each script should sit within its own folder and include

- README.md
- Associated PowerShell files

The table below should be kept up to date with any additions or removals of scripts.


| Name | Description | Link |
|------|-------------|------|
| Disable M365 Group Creation Assign Security Group | Disables the default setting for allowing all users to be able to create Microsoft 365 Groups. | [Link](./DisableM365GroupCreationAssignSecurityGroup/DisableM365GroupCreationAssignSecurityGroup.ps1) |
| Per User MFA | Allows you to manage Per User MFA for users in the tenent. | [Link](./PerUserMfa) |
| Service Principle | Queries all Service Principles and outputs 4 documents with details on SPs with less than 2 owners and SAML Apps notification emails. | [Link](./SP) |
| Prison Identities | Queries every user in the tenent that belong to a Privately owned prison. Output is saved to a JSON and CSV file for later consumption. | [Link](./PrisonIdentities) |
| Get all users in tenent that are active. | Queries the tenant for all active users and outputs as a JSON and CSV file. | [Link](./AllEnabledUsers.ps1) |
| Access Token Lifetime Policies | Allows the manipulation of Access Token Lifetime Policies within Entra ID Application Registrations. | [Link](./AccessTokenLifetimePolicy) |

# PSHelperFunctions Module

This module houses reusable functions, which are to be used across other scripts. When writing scripts, if any parts could be used by others in the future. Please split the code into it's own function within PSHelperFunctions\Public. This will save us development time and will keep code consistent.

This module has been developed and tested using [PowerShell 7](https://docs.microsoft.com/en-us/powershell/scripting/install/installing-powershell),
which is cross-platform and easily installed on
[Windows](https://docs.microsoft.com/en-us/powershell/scripting/install/installing-powershell-core-on-windows),
[Linux](https://docs.microsoft.com/en-us/powershell/scripting/install/installing-powershell-core-on-linux), and
[macOS](https://docs.microsoft.com/en-us/powershell/scripting/install/installing-powershell-core-on-macos).


## Usage

Run the following commands to install and use this PowerShell module:

1. Clone this repo:

    ```powershell
    git clone git@github.com:ministryofjustice/staff-identity-idam-scripts.git
    ```

2. Import the module (from the root of the cloned repo):

    ```powershell
    Import-Module "\staff-identity-idam-scripts/PSHelperFunctions.psd1" -Verbose -Force
    ```

3. List available functions:

    ```powershell
    Get-Command -Module "PSHelperFunctions"

    CommandType     Name                                               Version    Source
    -----------     ----                                               -------    ------
    Function        Connect-MgGraphViaAppReg                           1.0.0      PSHelperFunctions
    ```

1. Show help for a specific function, eg:

    ```powershell
    # show generic help
    Get-Help "Connect-MgGraphViaAppReg"

    # show examples
    Get-Help "Connect-MgGraphViaAppReg" -Examples

    # show full / detailed help
    Get-Help "Connect-MgGraphViaAppReg" -Full
    Get-Help "Connect-MgGraphViaAppReg" -Detailed
    ```

## Functions

- [PSHelperFunctions](#pshelperfunctions)
  - [Usage](#usage)
  - [Functions](#functions)
    -[Connect-MgGraphViaAppReg](https://github.com/ministryofjustice/staff-identity-idam-scripts/tree/main/PSHelperFunctions/Public/Connect-MgGraphViaAppReg.ps1)

The current function summaries are shown below, but you can view full help by importing the module then running:

```powershell
Get-Help "<FUNCTION-NAME>" -Full
```

### Connect-MgGraphViaAppReg

The `Connect-MgGraphViaAppReg` function connects to Microsoft Graph (MG) by obtaining an access token
using application registration with client credentials flow. This function is typically used in scenarios
where you want to automate tasks that require accessing Microsoft Graph resources without user interaction.

## Example

```powershell
# Import this module
 Import-Module "\staff-identity-idam-scripts/PSHelperFunctions.psd1" -Verbose -Force


# Vars
$clientId = ""
$clientSecret = ""
$tenantId = ""

$param = @{
    ClientId = $clientId
    ClientSecret = $clientSecret
    TenantId = $tenantId
}

Connect-MgGraphViaAppReg @param

# Test obtaining all users
Get-MgUser -All | Format-List  ID, DisplayName, Mail, UserPrincipalName
```
