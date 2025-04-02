# Restore-WordContextMenu.ps1
# Script to restore "New Word Document" option in the right-click context menu
# 

# Author: Macdara O Murchu
# Company: Santos Ltd
# Data: 02.04.2025

# Usage:
# .\Restore-WordContextMenu.ps1 -ComputerName "RemotePC01"
# or for multiple computers:
# .\Restore-WordContextMenu.ps1 -ComputerName "RemotePC01","RemotePC02"



[CmdletBinding()]
param (
    [Parameter(Mandatory=$true, 
               ValueFromPipeline=$true,
               ValueFromPipelineByPropertyName=$true,
               HelpMessage="Enter one or more remote computer names")]
    [string[]]$ComputerName,
    
    [Parameter(Mandatory=$false,
               HelpMessage="Credentials for remote connection")]
    [System.Management.Automation.PSCredential]$Credential
)

# Function to restore Word document context menu
function Restore-WordContextMenu {
    param (
        [string]$Computer
    )
    
    Write-Verbose "Connecting to $Computer..."
    
    try {
        $scriptBlock = {
            # Define the registry paths
            $wordTemplatePath = "C:\Program Files\Microsoft Office\root\Templates\1033\Normal.dotx"
            
            # Check if Office is installed in Program Files (x86) instead
            if (-not (Test-Path $wordTemplatePath)) {
                $wordTemplatePath = "C:\Program Files (x86)\Microsoft Office\root\Templates\1033\Normal.dotx"
            }
            
            # Check for Office 365 path
            if (-not (Test-Path $wordTemplatePath)) {
                $wordTemplatePath = "C:\Program Files\Microsoft Office\root\Office16\WINWORD.EXE"
                
                # Check if Office 365 is installed in Program Files (x86)
                if (-not (Test-Path $wordTemplatePath)) {
                    $wordTemplatePath = "C:\Program Files (x86)\Microsoft Office\root\Office16\WINWORD.EXE"
                }
            }
            
            $docxKey = "HKCR:\.docx"
            $wordKey = "HKCR:\Word.Document.12"
            $shellNewKey = "$wordKey\ShellNew"
            
            # Load necessary PowerShell drives
            if (-not (Test-Path "HKCR:")) {
                New-PSDrive -Name HKCR -PSProvider Registry -Root HKEY_CLASSES_ROOT | Out-Null
            }
            
            # Step 1: Ensure Word Document file type is registered correctly
            $result = @{
                Computer = $env:COMPUTERNAME
                Success = $false
                Message = ""
            }
            
            try {
                # Check if Word is installed
                $wordPath = Get-ItemProperty "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\App Paths\WINWORD.EXE" -ErrorAction SilentlyContinue
                
                if (-not $wordPath) {
                    $result.Message = "Microsoft Word is not installed on this machine."
                    return $result
                }
                
                # Create/Update .docx registration
                if (-not (Test-Path $docxKey)) {
                    New-Item -Path $docxKey -Force | Out-Null
                }
                
                Set-ItemProperty -Path $docxKey -Name "(Default)" -Value "Word.Document.12" -Type String
                
                # Create/Update Word.Document.12 registration
                if (-not (Test-Path $wordKey)) {
                    New-Item -Path $wordKey -Force | Out-Null
                }
                
                # Create ShellNew key
                if (-not (Test-Path $shellNewKey)) {
                    New-Item -Path $shellNewKey -Force | Out-Null
                }
                
                # Set required properties for ShellNew
                if (Test-Path $wordTemplatePath) {
                    Set-ItemProperty -Path $shellNewKey -Name "FileName" -Value $wordTemplatePath -Type String
                } else {
                    # If template not found, use NullFile method
                    Set-ItemProperty -Path $shellNewKey -Name "NullFile" -Value "" -Type String
                }
                
                # Run the command to refresh the shell
                Stop-Process -Name explorer -Force -ErrorAction SilentlyContinue
                Start-Process explorer
                
                $result.Success = $true
                $result.Message = "Successfully restored 'New Word Document' option in the context menu."
            }
            catch {
                $result.Message = "Error: $($_.Exception.Message)"
            }
            
            return $result
        }
        
        # Execute remotely with or without credentials
        if ($Credential) {
            $result = Invoke-Command -ComputerName $Computer -ScriptBlock $scriptBlock -Credential $Credential
        } else {
            $result = Invoke-Command -ComputerName $Computer -ScriptBlock $scriptBlock
        }
        
        return $result
    }
    catch {
        return @{
            Computer = $Computer
            Success = $false
            Message = "Failed to connect to remote computer: $($_.Exception.Message)"
        }
    }
}

# Main script execution
$results = @()

foreach ($computer in $ComputerName) {
    Write-Host "Processing $computer..." -ForegroundColor Cyan
    
    $result = Restore-WordContextMenu -Computer $computer
    $results += $result
    
    if ($result.Success) {
        Write-Host "✓ $($result.Computer): $($result.Message)" -ForegroundColor Green
    } else {
        Write-Host "✗ $($result.Computer): $($result.Message)" -ForegroundColor Red
    }
}

# Return results
return $results