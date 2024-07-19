# Per User MFA

Jira Ticket: [IDAM-815](https://dsdmoj.atlassian.net/browse/IDAM-815)

## Description

Provides scripts to export Service Principle reporting on Owners and Notification Emails.

The script within this directory allow you to do the following.

| Name | Description | Link |
|------|-------------|------|
| Get Owners and SAML Notifications. | Queries all Service Principles and outputs 4 documents with details on SPs with less than 2 owners and SAML Apps notification emails. | [Link](./SPGetAll.ps1) |

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

The script should now run successfully.
