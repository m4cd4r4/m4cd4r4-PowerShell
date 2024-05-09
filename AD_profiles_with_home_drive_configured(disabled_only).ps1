# PowerShell script to list all disabled user profiles with Home drives mapped in their Profile tab and write to a CSV file
Import-Module ActiveDirectory

# Fetch all disabled user profiles with HomeDirectory set
$disabledUsersWithHomeDrive = Get-ADUser -Filter {(HomeDirectory -like "*") -and (Enabled -eq $false)} -Properties HomeDirectory, HomeDrive

# Specify the path for the CSV file
$csvPath = "C:\Users\omuma\Desktop\home_drives_still_mapped_in_AD(disabled_only).csv"

# Output the disabled user profiles with Home drives mapped to the CSV file
$disabledUsersWithHomeDrive | Select-Object Name, SamAccountName, HomeDirectory, HomeDrive | Export-Csv -Path $csvPath -NoTypeInformation