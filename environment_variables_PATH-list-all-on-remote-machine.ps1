$ComputerName = 'SAN109638' # Replace with the actual remote machine name
Invoke-Command -ComputerName $ComputerName -ScriptBlock {
    $EnvPath = [System.Environment]::GetEnvironmentVariable('Path', 'Machine')
    $EnvPath
}