# Revoke user access in Microsoft Entra ID

Jira Ticket: [IDAM-861](https://dsdmoj.atlassian.net/browse/IDAM-861)
Confluence Documentation: [IR: Revoke user access in Microsoft Entra ID](https://dsdmoj.atlassian.net/wiki/spaces/EUCS/pages/5034279003/IR+Revoke+user+access+in+Microsoft+Entra+ID)

## Description

Scenarios that could require an administrator to revoke all access for a user include compromised accounts, employee termination, and other insider threats. Depending on the complexity of the environment, administrators can take several steps to ensure access is revoked. In some scenarios, there could be a period between the initiation of access revocation and when access is effectively revoked.

For more information on this process, consult the following Microsoft Knowledge Article: [https://learn.microsoft.com/en-us/entra/identity/users/users-revoke-access#microsoft-entra-environment](https://learn.microsoft.com/en-us/entra/identity/users/users-revoke-access#microsoft-entra-environment).

The script within this directory allow you to do the following.

| Name | Description | Link |
|------|-------------|------|
| Revoke user access from Entra ID. | Disables Entra account, revokes refresh tokens and disables user's device. | [Link](./Revoke.ps1) |

## Prerequisites

- Relevant PIM roles available
    - `Global Reader`
    - `Application Administrator`
- PowerShell 7
- Administrator rights to run PowerShell

## Executing Script

* Download and save a copy of this script.
* PIM the following roles
    - `Global Reader`
    - `Application Administrator`
* Open PowerShell 7 and run the following commands
    * If this is your first run `Install-Module Microsoft.Graph.Beta`
    * If this is already installed, run `Update-Module Microsoft.Graph.Beta`
* `cd` to where you downloaded the local script
* Run the required script
* At the prompt, sign in with your Entra ID Administrator Account

The script should now run successfully. Follow the onscreen prompts.
