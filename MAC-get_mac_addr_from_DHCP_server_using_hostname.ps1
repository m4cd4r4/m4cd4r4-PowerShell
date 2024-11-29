# Define parameters
$DHCPServer = "AUPDC014"  # Replace with your DHCP server
$TargetHost = "SAN109205"  # Replace with the hostname to search for

# Function to query DHCP leases
function Get-DHCPLease {
    param (
        [string]$Server,
        [string]$HostName
    )

    try {
        # Test connection to the DHCP server
        Write-Verbose "Testing connection to DHCP server: $Server"
        if (-not (Test-Connection -ComputerName $Server -Count 2 -Quiet)) {
            Write-Error "Cannot reach the DHCP server: $Server"
            return
        }

        # Ensure the cmdlet exists
        Write-Verbose "Checking if Get-DhcpServerv4Lease cmdlet is available"
        if (-not (Get-Command -Name Get-DhcpServerv4Lease -ErrorAction SilentlyContinue)) {
            Write-Error "The DHCP Server PowerShell module is not installed or accessible."
            return
        }

        # Query DHCP leases
        Write-Verbose "Querying DHCP leases for HostName: $HostName"
        $leases = Get-DhcpServerv4Lease -ComputerName $Server | Where-Object {
            $_.HostName -eq $HostName -or $_.ClientId -eq $HostName
        }

        if ($leases) {
            $leases | ForEach-Object {
                [PSCustomObject]@{
                    HostName     = $_.HostName
                    IPAddress    = $_.IPAddress
                    MACAddress   = $_.ClientId
                    LeaseExpires = $_.LeaseExpiryTime
                    ScopeID      = $_.ScopeID
                }
            }
        } else {
            Write-Host "No matching lease found for $HostName." -ForegroundColor Yellow
        }
    } catch {
        Write-Error "Error querying DHCP leases on $Server: $_"
    }
}

# Execute the function
$leaseInfo = Get-DHCPLease -Server $DHCPServer -HostName $TargetHost

if ($leaseInfo) {
    Write-Host "Lease Record(s) Found:" -ForegroundColor Green
    $leaseInfo | Format-Table -AutoSize
} else {
    Write-Host "No lease records found." -ForegroundColor Red
}
