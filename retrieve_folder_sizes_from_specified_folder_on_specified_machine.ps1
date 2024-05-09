# PowerShell script to retrieve folder sizes from specified folder on specified machine, and list in descending order of size
param (
    [string]$computerName = "SAN103123",
    [string]$folderPath = "\\c$"
)

Invoke-Command -ComputerName $computerName -ScriptBlock {
    param($folderPath)
    Get-ChildItem -Path $folderPath -Directory | ForEach-Object {
        $folderSize = (Get-ChildItem $_.FullName -Recurse -File | Measure-Object -Property Length -Sum).Sum / 1GB
        [PSCustomObject]@{
            FolderName = $_.Name
            SizeGB = [math]::Round($folderSize, 2)
        }
    } | Sort-Object -Property SizeGB -Descending
} -ArgumentList $folderPath
