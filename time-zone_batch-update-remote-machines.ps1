#Update time-zone of remote machines


# List of remote computer names or IP addresses
$computers = @("SAN122602")  # Add more computer names or IPs, separated by commas

# Dili Time Zone ID is "Tokyo Standard Time"
# WA Time Zone ID is "W. Australia Standard Time"
$newTimeZone = "W. Australia Standard Time"

# Define the script block that will change the time zone on the remote machine
$scriptBlock = {
    param($newTimeZone)
    
    # List all available time zones to check if the given time zone is valid
    $availableTimeZones = Get-TimeZone -ListAvailable
    $timezone = $availableTimeZones | Where-Object { $_.Id -eq $newTimeZone }
    
    if ($timezone) {
        Set-TimeZone -Id $newTimeZone
        Write-Host "Time zone updated to: $newTimeZone"
    } else {
        Write-Host "Invalid time zone: $newTimeZone"
    }
}

# Run the script on each remote computer
foreach ($computer in $computers) {
    Write-Host "Updating time zone on $computer"
    
    # Use Invoke-Command to run the script on the remote machine
    Invoke-Command -ComputerName $computer -ScriptBlock $scriptBlock -ArgumentList $newTimeZone -Credential (Get-Credential)
}
