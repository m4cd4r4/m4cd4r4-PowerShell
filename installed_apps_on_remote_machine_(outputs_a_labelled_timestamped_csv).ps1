$computerName = "SAN122248"
$timestamp = Get-Date -Format "yyyyMMddHHmmss"
$folderPath = "C:\Users\omuma\Desktop\Installed Software"
$csvFileName = "$folderPath\" + $computerName + "_" + $timestamp + ".csv"

# Check if the 'Installed Software' folder exists, if not, create it
if (-not (Test-Path -Path $folderPath)) {
    New-Item -ItemType Directory -Path $folderPath
}

Get-WmiObject -Class Win32_Product -ComputerName $computerName | 
Select-Object Name, Version, Vendor, @{Name="Installed On"; Expression={$_.ConvertToDateTime($_.InstallDate)}} | 
Export-Csv -Path $csvFileName -NoTypeInformation