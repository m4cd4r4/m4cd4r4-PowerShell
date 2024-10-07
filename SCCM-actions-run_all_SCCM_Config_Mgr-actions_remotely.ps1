# Author: Macdara O Murchu
# 03.10.2024

# This PowerShell script is used to trigger all SCCM (System Center Configuration Manager) client actions 
# and perform a Group Policy update on a remote computer. The script uses Invoke-Command to run a script block
# on a specified remote machine, which defines a list of SCCM client actions and their associated Schedule IDs.

# Each action is triggered using Invoke-WmiMethod to ensure that the SCCM client performs tasks such as policy retrieval,
# hardware/software inventory, and software updates evaluation. 



# Define the remote computer name
$RemoteComputerName = "SAN97812"  # Replace with the target machine name or IP address

# Ensure the current user has permissions to run remote commands
if (-not (Test-Connection -ComputerName $RemoteComputerName -Count 1 -Quiet)) {
    Write-Error "The remote computer $RemoteComputerName is not reachable."
    exit
}

# Ensure the current user has administrator privileges on the remote machine
$Session = New-PSSession -ComputerName $RemoteComputerName -ErrorAction SilentlyContinue
if (-not $Session) {
    Write-Error "Unable to establish a session with $RemoteComputerName. Ensure you have administrator privileges."
    exit
}

# Script block to run on the remote machine
$scriptBlock = {
    # Ensure the script is running with administrative privileges
    if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
        Write-Error "This script must be run with administrative privileges."
        exit
    }

    # Define a hashtable of SCCM Client Actions and their corresponding Schedule IDs
    $SCCMClientActions = @{
        "Machine Policy Retrieval & Evaluation Cycle"      = "{00000000-0000-0000-0000-000000000021}"
        "User Policy Retrieval & Evaluation Cycle"         = "{00000000-0000-0000-0000-000000000027}"
        "Discovery Data Collection Cycle"                  = "{00000000-0000-0000-0000-000000000003}"
        "Application Deployment Evaluation Cycle"          = "{00000000-0000-0000-0000-000000000121}"
        "Hardware Inventory Cycle"                         = "{00000000-0000-0000-0000-000000000001}"
        "Software Inventory Cycle"                         = "{00000000-0000-0000-0000-000000000002}"
        "Software Updates Deployment Evaluation Cycle"     = "{00000000-0000-0000-0000-000000000113}"
        "Software Updates Scan Cycle"                      = "{00000000-0000-0000-0000-000000000114}"
        "File Collection Cycle"                            = "{00000000-0000-0000-0000-000000000010}"
        "Software Metering Usage Report Cycle"             = "{00000000-0000-0000-0000-000000000004}"
        "Windows Installer Source List Update Cycle"       = "{00000000-0000-0000-0000-000000000032}"
    }

    # Trigger each SCCM client action based on the schedule ID
    foreach ($Action in $SCCMClientActions.GetEnumerator()) {
        $ActionName = $Action.Key
        $ScheduleID = $Action.Value

        try {
            Write-Host "Triggering action: $ActionName"
            Invoke-WmiMethod -Namespace "ROOT\CCM" -Class "SMS_Client" -Name "TriggerSchedule" -ArgumentList $ScheduleID -ErrorAction Stop
        }
        catch {
            Write-Warning "Failed to run action: $ActionName. Error: $_"
        }
    }
}

# Use Invoke-Command to execute the script block on the remote machine
try {
    Invoke-Command -Session $Session -ScriptBlock $scriptBlock -ErrorAction Stop
}
catch {
    Write-Error "An error occurred while executing the script on the remote computer $RemoteComputerName. Error: $_"
}
finally {
    # Clean up session
    if ($Session) {
        Remove-PSSession -Session $Session
    }
}
