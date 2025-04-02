# Restore-AdobePDFPrinter.ps1
# Script to restore the Adobe PDF printer functionality in Acrobat Reader DC
# For use on Windows machines where the Print-to-PDF option is missing
#
# Usage:
# .\Restore-AdobePDFPrinter.ps1 
# or for a remote computer:
# .\Restore-AdobePDFPrinter.ps1 -ComputerName "RemotePC01"

[CmdletBinding()]
param (
    [Parameter(Mandatory=$false, 
               ValueFromPipeline=$true,
               ValueFromPipelineByPropertyName=$true,
               HelpMessage="Enter a remote computer name (leave empty for local machine)")]
    [string]$ComputerName,
    
    [Parameter(Mandatory=$false,
               HelpMessage="Credentials for remote connection")]
    [System.Management.Automation.PSCredential]$Credential
)

# Prompt for computer name if not provided
if (-not $ComputerName) {
    $useLocal = Read-Host "Do you want to run this script on the local machine? (Y/N)"
    if ($useLocal.ToUpper() -eq "Y") {
        $ComputerName = $env:COMPUTERNAME
        Write-Host "Using local computer: $ComputerName" -ForegroundColor Cyan
    } else {
        $ComputerName = Read-Host "Enter the name of the remote computer"
        
        # Prompt for credentials if running against a remote computer
        $promptCred = Read-Host "Do you want to use different credentials for the remote connection? (Y/N)"
        if ($promptCred.ToUpper() -eq "Y") {
            $Credential = Get-Credential -Message "Enter credentials for $ComputerName"
        }
    }
}

function Restore-AdobePDFPrinter {
    param (
        [string]$Computer
    )
    
    Write-Verbose "Working on $Computer..."
    
    try {
        $scriptBlock = {
            $result = @{
                Computer = $env:COMPUTERNAME
                Success = $false
                Message = ""
                Steps = @()
            }

            # Function to add log entries
            function Add-LogStep {
                param([string]$Message)
                $result.Steps += $Message
                Write-Verbose $Message
            }

            try {
                # Step 1: Check if Acrobat Reader DC is installed
                Add-LogStep "Checking for Acrobat Reader DC installation..."
                $acrobatPath = Get-ItemProperty "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\App Paths\AcroRd32.exe" -ErrorAction SilentlyContinue
                
                if (-not $acrobatPath) {
                    $acrobatPath = Get-ItemProperty "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\App Paths\Acrobat.exe" -ErrorAction SilentlyContinue
                }
                
                if (-not $acrobatPath) {
                    $result.Message = "Acrobat Reader DC is not found on this machine."
                    return $result
                }
                
                Add-LogStep "Acrobat installation found at: $($acrobatPath.'(Default)')"
                
                # Step 2: Check Adobe PDF Converter registry settings
                Add-LogStep "Checking Adobe PDF Converter registry settings..."
                $pdfConverterKey = "HKLM:\SOFTWARE\Adobe\Adobe PDF"
                
                if (-not (Test-Path $pdfConverterKey)) {
                    Add-LogStep "Adobe PDF registry key not found. Creating it..."
                    New-Item -Path $pdfConverterKey -Force | Out-Null
                }
                
                # Step 3: Reinstall the Adobe PDF printer
                Add-LogStep "Reinstalling the Adobe PDF printer..."
                
                # First, remove any existing corrupted Adobe PDF printer
                $existingPrinter = Get-Printer | Where-Object { $_.Name -like "*Adobe PDF*" } -ErrorAction SilentlyContinue
                if ($existingPrinter) {
                    Add-LogStep "Removing existing Adobe PDF printer..."
                    Remove-Printer -Name $existingPrinter.Name -ErrorAction SilentlyContinue
                }
                
                # Step 4: Find Adobe PDF port
                Add-LogStep "Checking Adobe PDF ports..."
                $pdfPort = Get-PrinterPort | Where-Object { $_.Name -like "*AdobePDF*" } -ErrorAction SilentlyContinue
                
                if (-not $pdfPort) {
                    Add-LogStep "Adobe PDF port not found. Creating it..."
                    Add-PrinterPort -Name "AdobePDF:" -PrinterHostAddress "AdobePDF:" -ErrorAction SilentlyContinue
                }
                
                # Step 5: Find Adobe PDF driver
                Add-LogStep "Checking for Adobe PDF driver..."
                $pdfDriver = Get-PrinterDriver | Where-Object { $_.Name -like "*Adobe PDF*" } -ErrorAction SilentlyContinue
                
                if (-not $pdfDriver) {
                    # Need to find the driver files
                    Add-LogStep "Adobe PDF driver not found. Searching for driver files..."
                    
                    # Check common Acrobat installation locations for the driver
                    $possibleDriverPaths = @(
                        "${env:ProgramFiles}\Adobe\Acrobat DC\Acrobat\Xtras\AdobePDF",
                        "${env:ProgramFiles(x86)}\Adobe\Acrobat DC\Acrobat\Xtras\AdobePDF",
                        "${env:ProgramFiles}\Adobe\Acrobat Reader DC\Reader\Xtras\AdobePDF",
                        "${env:ProgramFiles(x86)}\Adobe\Acrobat Reader DC\Reader\Xtras\AdobePDF"
                    )
                    
                    $driverPath = $null
                    foreach ($path in $possibleDriverPaths) {
                        if (Test-Path "$path\AdobePDF.inf") {
                            $driverPath = $path
                            break
                        }
                    }
                    
                    if ($driverPath) {
                        Add-LogStep "Found Adobe PDF driver at: $driverPath"
                        
                        # Add printer driver
                        try {
                            Add-LogStep "Installing printer driver from: $driverPath\AdobePDF.inf"
                            $null = pnputil.exe -i -a "$driverPath\AdobePDF.inf" 2>&1
                            Start-Sleep -Seconds 2
                            Add-PrinterDriver -Name "Adobe PDF Converter" -ErrorAction Stop
                            Add-LogStep "Printer driver installed successfully"
                        } 
                        catch {
                            $errorMsg = $_.Exception.Message
                            Add-LogStep "Error installing printer driver: $errorMsg"
                            
                            # Try with exact driver name from inf file
                            try {
                                Add-LogStep "Attempting alternate driver installation method..."
                                $infContent = Get-Content "$driverPath\AdobePDF.inf" -ErrorAction SilentlyContinue
                                if ($infContent) {
                                    $driverNameLine = $infContent | Where-Object { $_ -like "*DriverName*=*" } | Select-Object -First 1
                                    if ($driverNameLine) {
                                        $driverName = ($driverNameLine -split "=")[1].Trim(' "')
                                        Add-LogStep "Found driver name in INF: $driverName"
                                        Add-PrinterDriver -Name $driverName -ErrorAction SilentlyContinue
                                    }
                                }
                            }
                            catch {
                                $errorMsg = $_.Exception.Message
                                Add-LogStep "Alternate driver installation failed: $errorMsg"
                            }
                        }
                    }
                    else {
                        Add-LogStep "Adobe PDF driver files not found in common locations."
                        
                        # Try using Windows built-in PDF driver as fallback
                        Add-LogStep "Falling back to using Microsoft Print to PDF driver..."
                        try {
                            Add-Printer -Name "Adobe PDF" -DriverName "Microsoft Print to PDF" -PortName "PORTPROMPT:" -ErrorAction SilentlyContinue
                            Add-LogStep "Added Microsoft Print to PDF printer as 'Adobe PDF'"
                        }
                        catch {
                            $errorMsg = $_.Exception.Message
                            Add-LogStep "Failed to add Microsoft Print to PDF printer: $errorMsg"
                        }
                    }
                }
                else {
                    Add-LogStep "Adobe PDF driver found: $($pdfDriver.Name)"
                }
                
                # Step 6: Add Adobe PDF printer using the driver
                Add-LogStep "Adding Adobe PDF printer..."
                try {
                    $driverName = (Get-PrinterDriver | Where-Object { $_.Name -like "*Adobe PDF*" } | Select-Object -First 1).Name
                    if (-not $driverName) {
                        $driverName = "Microsoft Print to PDF"
                    }
                    
                    Add-LogStep "Using driver: $driverName"
                    Add-Printer -Name "Adobe PDF" -DriverName $driverName -PortName "AdobePDF:" -ErrorAction Stop
                    Add-LogStep "Adobe PDF printer added successfully"
                }
                catch {
                    $errorMsg = $_.Exception.Message
                    Add-LogStep "Error adding printer: $errorMsg"
                    
                    # Try different potential driver names
                    $possibleDriverNames = @("Adobe PDF Converter", "Adobe PDF", "Adobe PDF Creator")
                    foreach ($name in $possibleDriverNames) {
                        try {
                            Add-LogStep "Trying alternate driver name: $name"
                            Add-Printer -Name "Adobe PDF" -DriverName $name -PortName "AdobePDF:" -ErrorAction Stop
                            Add-LogStep "Adobe PDF printer added successfully with driver: $name"
                            break
                        }
                        catch {
                            $errorMsg = $_.Exception.Message
                            Add-LogStep "Failed with driver name $name`: $errorMsg"
                        }
                    }
                }
                
                # Step 7: Set as default printer (optional)
                Add-LogStep "Checking if Adobe PDF printer was added..."
                $addedPrinter = Get-Printer | Where-Object { $_.Name -like "*Adobe PDF*" } -ErrorAction SilentlyContinue
                
                if ($addedPrinter) {
                    Add-LogStep "Adobe PDF printer was successfully added."
                    $result.Success = $true
                    $result.Message = "Successfully restored Adobe PDF printer functionality."
                }
                else {
                    Add-LogStep "Failed to add Adobe PDF printer. Checking Microsoft Print to PDF..."
                    
                    # Check if Microsoft Print to PDF exists and is working
                    $msPdfPrinter = Get-Printer | Where-Object { $_.Name -like "*Microsoft Print to PDF*" } -ErrorAction SilentlyContinue
                    
                    if (-not $msPdfPrinter) {
                        Add-LogStep "Microsoft Print to PDF not found. Attempting to add it..."
                        try {
                            Add-Printer -Name "Microsoft Print to PDF" -DriverName "Microsoft Print to PDF" -PortName "PORTPROMPT:" -ErrorAction Stop
                            Add-LogStep "Microsoft Print to PDF printer added as fallback"
                            $result.Success = $true
                            $result.Message = "Adobe PDF printer couldn't be restored, but Microsoft Print to PDF was added as a fallback."
                        }
                        catch {
                            Add-LogStep "Failed to add Microsoft Print to PDF: $($_.Exception.Message)"
                            $result.Success = $false
                            $result.Message = "Failed to restore PDF printing capability."
                        }
                    }
                    else {
                        Add-LogStep "Microsoft Print to PDF exists and can be used as an alternative."
                        $result.Success = $true
                        $result.Message = "Adobe PDF printer couldn't be restored, but Microsoft Print to PDF is available."
                    }
                }
                
                # Step 8: Restart the Spooler service to apply changes
                Add-LogStep "Restarting Print Spooler service..."
                Restart-Service -Name Spooler -Force
                Add-LogStep "Print Spooler service restarted"
            }
            catch {
                Add-LogStep "Error: $($_.Exception.Message)"
                $result.Success = $false
                $result.Message = "Error: $($_.Exception.Message)"
            }
            
            return $result
        }
        
        # Execute remotely or locally
        if ($Computer -eq $env:COMPUTERNAME) {
            $result = & $scriptBlock
        } 
        else {
            # Execute remotely with or without credentials
            if ($Credential) {
                $result = Invoke-Command -ComputerName $Computer -ScriptBlock $scriptBlock -Credential $Credential
            } 
            else {
                $result = Invoke-Command -ComputerName $Computer -ScriptBlock $scriptBlock
            }
        }
        
        return $result
    }
    catch {
        return @{
            Computer = $Computer
            Success = $false
            Message = "Failed to execute script: $($_.Exception.Message)"
            Steps = @("Script execution failed")
        }
    }
}

# Main script execution
Write-Host "Restoring Adobe PDF printer on $ComputerName..." -ForegroundColor Cyan
$result = Restore-AdobePDFPrinter -Computer $ComputerName

# Display detailed log if verbose
if ($PSCmdlet.MyInvocation.BoundParameters["Verbose"].IsPresent) {
    Write-Host "`nDetailed log:" -ForegroundColor Cyan
    foreach ($step in $result.Steps) {
        Write-Host "  - $step" -ForegroundColor Gray
    }
    Write-Host ""
}

# Display final result
if ($result.Success) {
    Write-Host "✓ $($result.Computer): $($result.Message)" -ForegroundColor Green
} 
else {
    Write-Host "✗ $($result.Computer): $($result.Message)" -ForegroundColor Red
    
    # Provide troubleshooting advice
    Write-Host "`nTroubleshooting suggestions:" -ForegroundColor Yellow
    Write-Host "1. Verify that Acrobat Reader DC is properly installed" -ForegroundColor Yellow
    Write-Host "2. Try repairing Acrobat Reader DC installation through Programs and Features" -ForegroundColor Yellow
    Write-Host "3. Check if the Microsoft Print to PDF option works as an alternative" -ForegroundColor Yellow
    Write-Host "4. Run the script with -Verbose parameter for detailed logging" -ForegroundColor Yellow
}

# Return result object for potential further use
return $result