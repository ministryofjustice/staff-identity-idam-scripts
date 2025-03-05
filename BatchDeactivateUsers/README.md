# Batch deactivate users

JIRA Ticket: [IDAM-2252](https://dsdmoj.atlassian.net/browse/IDAM-2252)

## Description

This script is intended to assist with batch deactivations of accounts in Active Directory. The script is split in two sections, the initial deactivation, and a backout section.

It utilises an input file which should contain a list of targeted UPNs (one per line), these users will then be disabled, have a "Deactivated" description added, and moved to a "TO_BE_DELETED" OU (this needs to exist in the root of the domain before running the script).

The script also exports a PRE and POST report of the targeted users to $env:userprofile\scripts

## Execute Script
### Deactivate users

* Download the script locally / copy into PowerShell ISE or similar
* Populate the `$file` variable on line 12 with the path to the file containing your targeted users
* Run through the script until line 65, this completes the deactivation

### Backout / restore users

The backout reuses a lot of the same variables, so if you have closed the window since, you may need to reload these from the variables section

* Run the script from line 67 down
* You will be prompted to select the PRE file containing the logs from the initial deactivation (this will then restore all users to Enabled, their previous OU and previous description)
* If individual users need to be restored, it is likely easiest to simply do this manually referring to the PRE deactivation log

