$ComputerName = "SAN103013"  # Replace with the target computer name
$UserNames = "quadb,jorto,hutlu,rooab"  # Replace with a comma-separated list of usernames

Invoke-Command -ComputerName $ComputerName -ScriptBlock {
    param ($UserNames)

    # Convert comma-separated string to an array
    $UserList = $UserNames -split ','

    $ProfileRegPath = "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\ProfileList"

    foreach ($UserName in $UserList) {
        $UserSID = (Get-WmiObject Win32_UserProfile | Where-Object { $_.LocalPath -like "*\$UserName" }).SID
        if ($UserSID) {
            $UserProfilePath = (Get-ItemProperty "$ProfileRegPath\$UserSID").ProfileImagePath

            # Remove the profile directory
            if (Test-Path $UserProfilePath) {
                Remove-Item -Path $UserProfilePath -Recurse -Force -ErrorAction SilentlyContinue
            }

            # Remove the registry entry
            Remove-Item -Path "$ProfileRegPath\$UserSID" -Recurse -Force -ErrorAction SilentlyContinue

            Write-Output "User profile for $UserName has been deleted successfully."
        } else {
            Write-Output "User profile for $UserName not found."
        }
    }
} -ArgumentList $UserNames
