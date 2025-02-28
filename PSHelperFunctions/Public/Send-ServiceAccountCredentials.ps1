<#
.SYNOPSIS
    Sends service account credentials via email.

.DESCRIPTION
    The Send-ServiceAccountCredentials function sends emails containing 
    service account credentials. It constructs and sends two emails: 
    one with the username and another with the password.

.PARAMETER DemandNumber
    The demand number associated with the service account.

.PARAMETER UserPrincipalName
    The user principal name of the service account.

.PARAMETER UserPW
    The password of the service account.

.PARAMETER ToRecipient
    The email address of the recipient.

.EXAMPLE
    Send-ServiceAccountCredentials -DemandNumber "12345" -UserPrincipalName "user@example.com" -UserPW "P@ssw0rd" -ToRecipient "recipient@example.com"

.NOTES
    This function requires the Send-MGMail cmdlet to send emails.
    Ensure the Send-MGMail cmdlet is available and properly configured.
#>
function Send-ServiceAccountCredentials {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $false)]
        [ValidateNotNullOrEmpty()]
        [String]$DemandNumber,

        [Parameter(Mandatory = $false)]
        [ValidateNotNullOrEmpty()]
        [String]$UserPrincipalName,

        [Parameter(Mandatory = $false)]
        [ValidateNotNullOrEmpty()]
        [String]$UserPW,

        [Parameter(Mandatory = $false)]
        [ValidateNotNullOrEmpty()]
        [String]$ToRecipient
    )

    try {
        # Construct the email subject
        $date = Get-Date -Format "yyyyMMdd"
        $subject = "$($date)-$($DemandNumber)-ServiceAccount"

        # Construct mail message body for username and group info

$messageBodyUsername = @"
Hello,

The Service Account for Demand: $DemandNumber has been created

Please find the Username below (Password to follow in a separate email):
Username: $UserPrincipalName

Kind Regards
IdAM
"@

        # Construct mail message body for password
$messageBodyPass = @"
Hello,
The user's password is: $UserPW

Kind Regards,
IdAM
"@

        #Send email to user
        Write-Verbose "`e[95mSending Emails to user`e[0m"

        $emailBodies = @($messageBodyUsername, $messageBodyPass)
        foreach ($emailBody in $emailBodies) {
            $count++
            # Params for email module
            $emailDefaultParams = @{
                'ToRecipient'  = $ToRecipient
                'Subject'      = $Subject
                'ContentBody'  = $emailBody
            }
            Write-Verbose "`e[95mSending Email [$count/$($emailBodies.count)] with Username, Group, and Password info`e[0m"
            Send-MGMail @emailDefaultParams -ErrorAction 'Stop'

            Start-Sleep 15
        }
    }
    catch {
        Write-Error "ERROR: Sending email" -ErrorAction Continue
        throw
    }
}
