# Per User MFA

Jira Ticket: [IDAM-655](https://dsdmoj.atlassian.net/browse/IDAM-655)

## Description

The Per User MFA process will be deprecated soon by Microsoft. Instead we should be moving to using Conditional Access Policies and removing all per user MFA configurations including the use of this script.

The scripts within this directory allow you to do the following.

| Name | Description | Link |
|------|-------------|------|
| Get all users in tenent with MFA State. | Queries every user in the tenent fetching this id, name and mfa status. Output is saved to a JSON file for later consumption. | [Link](./PerUserMfaGetAll.ps1) |
| Disable Per User MFA for all enabled users. | Read from the output of PerUserMfaGetAll JSON file, finds enabled users and disables each. | [Link](./PerUserMfaDisable.ps1) |
| Gets single user MFA State. | Queries an individual user by user id for Per User MFA status. | [Link](./PerUserMfaGet) |

## Prerequisites

- Relevant PIM roles available
    - `Global Reader`
    - `User Administrator`
    - `Application Administrator`
- PowerShell 7
- Administrator rights to run PowerShell 

## Executing Script

* Download and save a copy of this script.
* PIM the following roles
    - `Global Reader`
    - `User Administrator`
    - `Application Administrator`
* Open PowerShell 7 and run the following commands
    * If this is your first run `Install-Module Microsoft.Graph.Beta`
    * If this is already installed, run `Update-Module Microsoft.Graph.Beta`
* `cd` to where you downloaded the local script
* Run the required script
* At the prompt, sign in with your Entra ID Administrator Account

The script should now run successfully.

Resources

- [https://learn.microsoft.com/en-us/graph/api/authentication-get?view=graph-rest-beta&tabs=powershell](https://learn.microsoft.com/en-us/graph/api/authentication-get?view=graph-rest-beta&tabs=powershell)
- [https://learn.microsoft.com/en-us/graph/api/authentication-update?view=graph-rest-beta&tabs=powershell](https://learn.microsoft.com/en-us/graph/api/authentication-update?view=graph-rest-beta&tabs=powershell)
