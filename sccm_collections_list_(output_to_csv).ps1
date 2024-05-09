# Define the path to the ConfigurationManager module
$modulePath = "C:\Program Files (x86)\Microsoft Endpoint Manager\AdminConsole\bin\ConfigurationManager.psd1"

# Import the ConfigurationManager module
Import-Module $modulePath

# Change to SCCM site code
$siteCode = "ADE"

# Set the location to the SCCM site
Set-Location "$siteCode`:"

# Get all collections and their descriptions
$collections = Get-CMCollection | Select-Object Name, CollectionID, Comment

# Define the output file path (change file extension to .csv)
$outputFilePath = "C:\Users\omuma\Desktop\PowerShell Output\sccm_collections.csv"

# Export the collections to the CSV file
$collections | Export-Csv $outputFilePath -NoTypeInformation

# Reset the location
Set-Location C: