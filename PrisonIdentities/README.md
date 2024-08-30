# Prison Identities

Jira Ticket: [IDAM-1097](https://dsdmoj.atlassian.net/browse/IDAM-1097)

## Description

Queries every user in the tenent that belong to a Privately owned prison. Output is saved to a JSON and CSV file for later consumption.

The scripts within this directory allow you to do the following.

| Name | Description | Link |
|------|-------------|------|
| Get all users in tenent that are part of a Private Prison. | Queries every user in the tenent that belong to a Privately owned prison. Output is saved to a JSON and CSV file for later consumption. | [Link](./PrisonIdentities.ps1) |

## Prerequisites

- Relevant PIM roles available
    - `Application Administrator`
- PowerShell 7
- Administrator rights to run PowerShell 

## Executing Script

* Download and save a copy of this script.
* PIM the following roles
    - `Application Administrator`
* Open PowerShell 7 and run the following commands
    * If this is your first run `Install-Module Microsoft.Graph`
    * If this is already installed, run `Update-Module Microsoft.Graph`
* `cd` to where you downloaded the local script
* Run the required script
* At the prompt, sign in with your Entra ID Administrator Account

The script should now run successfully.
