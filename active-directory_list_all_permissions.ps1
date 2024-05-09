# Hard-coded root path and output file path
$rootPath = "\\ovssantos\OVS Projects\" # Change this to the desired root path
$outputFile = "C:\Users\omuma\Desktop\ovssantos_ovsprojects.csv" # Change this to your desired output folder path

function Get-FolderPermissions {
    param (
        [string]$Path,
        $Credential
    )

    try {
        # Attempt to get ACLs with provided credential, if any
        if ($null -eq $Credential) {
            $acls = Get-Acl -Path $Path
        } else {
            $acls = Get-Acl -Path $Path -Credential $Credential
        }

        foreach ($acl in $acls.Access) {
            # Construct a line of output for the current ACL
            $line = "$Path," + "Folder," + $acl.IdentityReference + "," + $acl.FileSystemRights
            # Output the line to the CSV file
            Add-Content -Path $outputFile -Value $line
        }
    } catch {
        if ($_.Exception.Message -like "*Access to the path*is denied*") {
            # If access is denied, prompt for credentials and retry once
            $Credential = Get-Credential -Message "Access denied to $Path. Please enter your credentials to retry."
            Get-FolderPermissions -Path $Path -Credential $Credential
        } else {
            # If any other exception occurs, note it as access denied without retrying
            $line = "$Path,Access Denied,,,Failed to access with provided credentials or other error occurred."
            Add-Content -Path $outputFile -Value $line
        }
    }
}

# Create the output file and set the header
"Folder Path,Access Type,Identity,Access Rights,Access Denied Note" | Set-Content -Path $outputFile

# Recursively iterate through folders in the specified root path
Get-ChildItem -Path $rootPath -Recurse -Directory | ForEach-Object {
    $currentPath = $_.FullName

    # Attempt to get permissions with optional credential retry
    Get-FolderPermissions -Path $currentPath
}
