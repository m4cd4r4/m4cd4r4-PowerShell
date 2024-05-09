# PowerShell script to list all enabled user profiles with Home drives mapped in their Profile tab and write to a CSV file
Import-Module ActiveDirectory

# Fetch all enabled user profiles with HomeDirectory set
$usersWithHomeDrive = Get-ADUser -Filter {(HomeDirectory -like "*") -and (Enabled -eq $true)} -Properties HomeDirectory, HomeDrive

# Specify the path for the CSV file
$csvPath = "C:\Users\omuma\Desktop\home_drives_still_mapped_in_AD.csv"

# Output the enabled user profiles with Home drives mapped to the CSV file
$usersWithHomeDrive | Select-Object Name, SamAccountName, HomeDirectory, HomeDrive | Export-Csv -Path $csvPath -NoTypeInformation