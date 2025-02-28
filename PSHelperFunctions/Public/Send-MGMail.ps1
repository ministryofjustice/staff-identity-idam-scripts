<#
.SYNOPSIS
Connects to MS Graph and sends an email to a recipient.

.DESCRIPTION
This script uses the Microsoft Graph API in order to send an email to a recipient. There are extended options not used in this script.
Such as cc'ing recipient and adding attachments. You will need an app reg with the following API permissions.

Permission Type                         Permission
Application	                            Mail.Send

You will need to install the MS Graph module 'Install-Module -Name Microsoft.Graph' in your script calling this function.
You will also need to import the following module 'Import-Module -Name Microsoft.Graph.Users.Actions'.
You MUST be logged in to Azure MG Graph (With Connect-MgGraph) before running this function

.PARAMETER SendFrom
This is the email addres in which you want to send the email from.

.PARAMETER Subject
This is the subject of the email that you are sending.

.PARAMETER ContentBody
This is the content of the body of the email that you wish to send.

.PARAMETER ToRecipient
This is the recipients address, who you want to send the email to.

.OUTPUTS
Sends an email to a recipient.

.NOTES
Authored by Jason Gillett 29/06/2023
#>
function Send-MGMail {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $false)]
        [ValidateNotNullOrEmpty()]
        [String]$SendFrom = "IDAMTestUser1@devl.justice.gov.uk",

        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [String]$Subject,

        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [String]$ContentBody,

        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [String]$ToRecipient
    )

    try {
        # Setting up the params for the email that we are sending
        $params = @{
            message         = @{
                subject      = $Subject
                body         = @{
                    contentType = "text"
                    content     = $ContentBody
                }
                toRecipients = @(
                    @{
                        emailAddress = @{
                            address = $ToRecipient
                        }
                    }
                )
            }
            saveToSentItems = "true"
        }

        # A UPN can also be used as -UserId.
        Send-MgUserMail -UserId $SendFrom -BodyParameter $params
    }
    catch {
        Write-Error -Message "ERROR: Email failed to send" -ErrorAction "Continue"
        throw
    }
}
