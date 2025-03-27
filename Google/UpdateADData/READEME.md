# Batch update user details in AD

JIRA Ticket: [IDAM-2212](https://dsdmoj.atlassian.net/browse/IDAM-2212)

## Description

This script is intended to assist with batch updateing of user attributes in Active Directory. The script is split in two sections, the initial adjustment, and a backout section.

It utilises an input file which should be a csv contain a list of targeted UPNs and intended Job Title (in this case using a Google workspaces export as the source). The headings should be as follows:
| UserPrincipalName	| CSVJobTitle | 
|-|-|
| UserPrincipalName (target user on AD) | Job Title from Google |

These user details in AD will then be checked to see if a job title already exists and if so, it will not be overwritten, if not, the job title from the CSV will be written to the user.
The script WILL overwrite the Company and PhysicalDeliveryOffice attributes to the hardcoded values in the variables section.

The script also exports a PRE and POST report of the targeted users to $env:userprofile\scripts

## Execute Script
### Deactivate users

* Download the scripts locally / copy into PowerShell ISE or similar
* Start with UpdateJobTitles.ps1
* Populate the `$Users` variable on line 14 with the path to the file containing your targeted users
* Run the script then examine the output

### Backout / restore users

* Download the scripts locally / copy into PowerShell ISE or similar
* To backout, use Revert-UpdateJobTitles.ps1
* Populate the `$Users` variable on line 14 with OUTPUT_PRE file from the run you wish to backout
* Run the script then examine the output

If individual users need to be restored or adjusted, it is likely easiest to simply do this manually referring to the PRE adjustments file
