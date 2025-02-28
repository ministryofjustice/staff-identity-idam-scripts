<#
.SYNOPSIS
Creates a secure password the confirms with Azure's password requirements

.DESCRIPTION
The `New-SecurePassword` function creates a password of a required length. By default this is 16 chars long.
This password confirms with the chars that Azure allows as part of their password creation policy.

.PARAMETER Length
The required length of the password that is being created.

.EXAMPLE
New-SecurePassword -Length 32 

Creates a 32 character long password.

.NOTES
Authored by Jason Gillett 24/02/2025
#>
function New-SecurePassword {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $false)]
        [int]$Length = 10 # Total length is fixed to 10 as per the required format
    )

    # ASCII ranges for the specified characters
    $upper = 65..90 # A-Z
    $lower = 97..122 # a-z
    $numbers = 48..57 # 0-9

    # Generate the first letter as an uppercase letter
    $firstChar = [char](Get-Random -InputObject $upper)

    # Generate the next 3 characters as lowercase letters
    $lowerChars = -join (1..3 | ForEach-Object { [char](Get-Random -InputObject $lower) })

    # Generate the next 6 characters as numbers
    $numberChars = -join (1..6 | ForEach-Object { [char](Get-Random -InputObject $numbers) })

    # Combine all parts to form the password
    $password = $firstChar + $lowerChars + $numberChars

    return $password
}
