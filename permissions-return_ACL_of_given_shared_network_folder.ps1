# Function to retrieve shared folder permissions
function Get-SharedFolderPermissions {
    param (
        [string]$SharedFolderPath
    )

    # Check if the folder exists
    if (-Not (Test-Path $SharedFolderPath)) {
        Write-Error "The shared folder path '$SharedFolderPath' does not exist."
        return
    }

    # Get the security descriptor of the shared folder
    $acl = Get-Acl $SharedFolderPath

    Write-Output "Permissions for Shared Folder: $SharedFolderPath"
    Write-Output "-----------------------------------------------"

    foreach ($access in $acl.Access) {
        $permission = @{
            'Identity'      = $access.IdentityReference
            'AccessType'    = $access.AccessControlType
            'Permissions'   = $access.FileSystemRights
            'IsInherited'   = $access.IsInherited
            'InheritanceFlags' = $access.InheritanceFlags
        }

        # Output the permission information
        [PSCustomObject]$permission
    }
}

# Prompt the user to enter the path to the shared folder
$sharedFolderPath = Read-Host -Prompt "Enter the path to the shared folder"

# Call the function with the provided path
Get-SharedFolderPermissions -SharedFolderPath $sharedFolderPath
