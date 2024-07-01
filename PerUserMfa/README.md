# Per User MFA

Jira Ticket: [IDAM-655](https://dsdmoj.atlassian.net/browse/IDAM-655)

## Description

The Per User MFA process will be deprecated soon by Microsoft. Instead we should be moving to using Conditional Access Policies and removing all per user MFA configurations including the use of this script.

This script is a short term fix to still allow us to enable per user MFA for specific sets of users. [For more information see this Confluence article](https://dsdmoj.atlassian.net/wiki/spaces/EUCS/pages/4892033119/Legacy+MFA+Requests+Prison+Staff).

## Prerequisites

- Relevant PIM roles available
    - `Global Reader`
    - `User Administrator`
    - `Application Administrator`
    - `Authentication Policy Administrator`
- PowerShell 7
- Administrator rights to run PowerShell
- 

## Executing Script

* Download and save a copy of this script.
* PIM the following roles
    - `Global Reader`
    - `User Administrator`
    - `Application Administrator`
    - `Authentication Policy Administrator`
* Open PowerShell 7 and run the following commands
    * If this is your first run `Install-Module Microsoft.Graph.Beta`
    * If this is already installed, run `Update-Module Microsoft.Graph.Beta`
* `cd` to where you downloaded the local script
* Open the script and change in both the variable `$userId` to be the UUID of the user in the tenant you wish to update
* Run one of the following scripts `.\PerUserMfaGet.ps1` (for a dry run to check the current MFA status) or `.\PerUserMfaEnable.ps1` (to update the MFA status to enable it)
* At the prompt, sign in with your Entra ID Administrator Account

The script should now run successfully.

Resources

- [https://learn.microsoft.com/en-us/graph/api/authentication-get?view=graph-rest-beta&tabs=powershell](https://learn.microsoft.com/en-us/graph/api/authentication-get?view=graph-rest-beta&tabs=powershell)
- [https://learn.microsoft.com/en-us/graph/api/authentication-update?view=graph-rest-beta&tabs=powershell](https://learn.microsoft.com/en-us/graph/api/authentication-update?view=graph-rest-beta&tabs=powershell)
