# Define the remote machine and port
$RemoteComputer = "SAN93151" # Replace with the remote machine's name or IP address
$Port = 2701

# Test the connection
$ConnectionTest = Test-NetConnection -ComputerName $RemoteComputer -Port $Port

# Display the result
if ($ConnectionTest.TcpTestSucceeded) {
    Write-Host "Port $Port is open on $RemoteComputer." -ForegroundColor Green
} else {
    Write-Host "Port $Port is NOT open on $RemoteComputer." -ForegroundColor Red
}