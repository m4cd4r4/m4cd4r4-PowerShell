# Function to retrieve shared folder permissions based on filter
function Get-SharedFolderPermissions {
    param (
        [string]$SharedFolderPath,
        [string]$PermissionType
    )

    # Check if the folder exists
    if (-Not (Test-Path $SharedFolderPath)) {
        Write-Error "The shared folder path '$SharedFolderPath' does not exist."
        return
    }

    # Get the security descriptor of the shared folder
    $acl = Get-Acl $SharedFolderPath

    Write-Output "`nPermissions for Shared Folder: $SharedFolderPath"
    Write-Output "--------------------------------------------------"

    # Loop through permissions and filter based on the requested type
    foreach ($access in $acl.Access) {
        # Filter based on permission type
        $isMatch = switch ($PermissionType.ToUpper()) {
            "R" {
                $access.FileSystemRights -eq "ReadAndExecute" -or
                $access.FileSystemRights -eq "Read"
            }
            "RW" {
                $access.FileSystemRights -match "Write" -and
                $access.FileSystemRights -match "Read"
            }
            default { $false }
        }

        # If the permission matches the filter, output it
        if ($isMatch) {
            [PSCustomObject]@{
                Identity          = $access.IdentityReference
                AccessType        = $access.AccessControlType
                Permissions       = $access.FileSystemRights
                IsInherited       = $access.IsInherited
                InheritanceFlags  = $access.InheritanceFlags
            }
        }
    }
}

# Prompt the user to enter the path to the shared folder
$sharedFolderPath = Read-Host -Prompt "Enter the path to the shared folder"

# Prompt the user to choose Read (R) or Read/Write (RW) permissions
$permissionType = Read-Host -Prompt "Enter the type of permissions to display (R for Read, RW for Read/Write)"

# Validate input for permission type
if ($permissionType -notmatch "^(R|RW)$") {
    Write-Error "Invalid input. Please enter 'R' for Read or 'RW' for Read/Write."
    return
}

# Call the function with the provided path and permission type
Get-SharedFolderPermissions -SharedFolderPath $sharedFolderPath -PermissionType $permissionType
