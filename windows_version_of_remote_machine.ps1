# OsBuildNumber: 19044 = 21H2
# OsBuildNumber: 19045 = 22H2

Invoke-Command -ComputerName "SAN103007" -ScriptBlock { Get-ComputerInfo | Select-Object OsName, OsVersion, OsBuildNumber }