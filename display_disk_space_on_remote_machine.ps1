# PowerShell script to retrieve disk space information from a remote machine
param (
    [string]$computerName = "SAN103123"
)

Invoke-Command -ComputerName $computerName -ScriptBlock {
    Get-PSDrive -PSProvider FileSystem | Select-Object Name, @{Name="Used";Expression={"{0:N2} GB" -f (($_.Used / 1GB))}}, @{Name="Free";Expression={"{0:N2} GB" -f (($_.Free / 1GB))}}
}