# PowerShell script to retrieve folder sizes from specified folder on specified machine, and list in descending order of size
param (
    [string]$computerName = "COMPUTERNAME",
    [string]$folderPath = "C$\Users"
)

Invoke-Command -ComputerName $computerName -ScriptBlock {
    param($folderPath)
    
    # Ensure the folder path is correctly formed for remote access
    $remoteFolderPath = "\\$using:computerName\$folderPath"
    
    if (Test-Path $remoteFolderPath) {
        Get-ChildItem -Path $remoteFolderPath -Directory | ForEach-Object {
            $folderSize = (Get-ChildItem $_.FullName -Recurse -File | Measure-Object -Property Length -Sum).Sum / 1GB
            [PSCustomObject]@{
                FolderName = $_.Name
                SizeGB = [math]::Round($folderSize, 2)
            }
        } | Sort-Object -Property SizeGB -Descending
    } else {
        Write-Error "Cannot access folder path: $remoteFolderPath"
    }
    
} -ArgumentList $folderPath
