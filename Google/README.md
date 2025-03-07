# Google Decommissioning Scripts

This folder contains the scripts required for the Google migration of Justice Digital users.

## Prerequisites

The PowerShell script uses the new `Microsoft.Entra` API for fetching users and adding them to Groups. This should be installed before running.

`Install-Module -Name Microsoft.Entra -Repository PSGallery -Scope CurrentUser -Force -AllowClobber`

## PowerShell

Script to move users into the Group google-cloud-allowed which will allow users to authenticate against Entra and be provisioned.

## Google App Script

Scripts that will be used to

* Update Google account UPN to match Entra UPN
* Move Google account to new OU to allow Authentication against Entra ID
* Remove Workspace licence

These should be run in the Google App Scripts Developer environment and run under a Super Admin account.
