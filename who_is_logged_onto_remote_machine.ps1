Get-WmiObject -Class Win32_ComputerSystem -ComputerName "AWSWIN10GIS06" | Select-Object -ExpandProperty UserName
