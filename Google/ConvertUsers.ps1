$allResults = [System.Collections.Generic.List[Object]]::new()
$UserList = Get-Content 'user-list.csv' | Out-String | ConvertFrom-Csv

Foreach ($user in $UserList) {

    $DigitalEmailParts = $user.DigitalEmail.Split("@");
    $JusticeEmailParts = $user.JusticeEmail.Split("@");

    # Record record added
    $result = [PSCustomObject][ordered]@{
        "jdeprefix" = $DigitalEmailParts[0]
        "jdesuffix" = $DigitalEmailParts[1]
        "jeprefix" = $JusticeEmailParts[0]
        "jesuffix" = $JusticeEmailParts[1]
    }
    $allResults.Add($result)
}

$allResults | ConvertTo-Json -Depth 20 | Out-File ".\user-list.json"
