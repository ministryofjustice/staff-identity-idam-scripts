# Identify Private Prison and MoJ Users for F3/F5 License Migration

JIRA Ticket: [EUCSVDS-1302](https://dsdmoj.atlassian.net/browse/EUCSVDS-1302)

## Description

All private prison staff must have their Microsoft E5 licenses removed and replaced with Microsoft F3 and F5 licenses to do reduce the overall cost of Microsoft licenses.

The script gets a CSV file containing a column named UserPrincipalName and queries the user account for sign-in activity. User accounts that are enabled and show sign-in activity in the last 90 days are saved to the ActivePath CSV file. Disabled accounts or accounts showing greater that 90 days sign-in activity are put in the InactivePath CSV file. Checks whether users are in one of four groups, which should identify them as a private prison user. If they are not present in any group they are more likely to be MoJ staff.

| Group Name |
--------------
| MoJO-G-Users-AVD-Hostpool01 |
| MoJO-G-Users-AVD-Hostpool02 |
| MoJO-G-Users-AVD-Hostpool03 |
| DELG-MoJO-G-FiveWells-AVD-Access |

## Prerequisites

* Microsoft Graph PowerShell Module (at least version 2.25.0)
    * Install the module, if not present.
        * Install-Module Microsoft.Graph -Scope CurrentUser -AllowClobber
    * To update the module, if you already have it installed.
        * Update-Module Microsoft.Graph
* PowerShell.

## Execute Script

* Download the script locally.
* Activate the Global Reader PIM role for your account.
* Open PowerShell.
* Change to the script folder, for example:
    * cd $env:USERPROFILE\Downloads
* Execute the script
    * .\GetActiveInactivePrisonUsers.ps1 -Path Users.csv -ActivePath ActiveUsers.csv -InactivePath InactiveUsers.csv

The script will read in the UserPrincipalNames from User.csv, write all the active users to ActiveUsers.csv and all inactive users to InactiveUser.csv in this example.

Active and inactive users will be added with the PrivatePrisonUser column, which will be set as true if they work for a private prison and false, if they are MoJ staff.