# Disable M365 Group Creation Assign Security Group

Original Microsoft Article: [Manage who can create Microsoft 365 Groups](https://learn.microsoft.com/en-us/microsoft-365/solutions/manage-creation-of-groups?view=o365-worldwide)

Jira Ticket: [IDAM-661](https://dsdmoj.atlassian.net/browse/IDAM-661)

## Description

This script does two things.

1. Disables the default setting for allowing all users to be able to create Microsoft 365 Groups
2. Allows a single Entra Security Group called `MoJO-M365-Group-Creators` to still create Microsoft 365 Groups

## Prerequisites

- Relevant PIM roles available
    - `Global Reader`
    - `Groups Administrator`
    - `Application Administrator`
- PowerShell 7
- Administrator rights to run PowerShell

## Executing Script

* Download and save a copy of this script.
* PIM the following roles
    * `Global Reader`
    * `Groups Administrator`
    * `Application Administrator`
* Open PowerShell 7 and run the following commands
    * If this is your first run `Install-Module Microsoft.Graph.Beta`
    * If this is already installed, run `Update-Module Microsoft.Graph.Beta`
* `cd` to where you downloaded the local script
* Type the following command `.\DisableM365GroupCreationAssignSecurityGroup.ps1`
* At the prompt, sign in with your Entra ID Administrator Account

The script should now run successfully.
