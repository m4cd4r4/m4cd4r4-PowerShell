# Key changes and explanations:
#
# Parameters Added:
#
# $ProfileAgeToDelete: A new parameter to control the age (in days) of user profiles to be deleted. It defaults to 90.
# $ExcludeUsers: A new parameter to specify a comma separated list of users to exclude.
# $TempFileAgeToDelete: A new parameter to control the age of temporary files to delete.
# Using the Parameters:
#
# The script now uses $ProfileAgeToDelete in the Get Old profiles section to determine which profiles to delete.
# The script now uses $ExcludeUsers to exclude specific user profiles. The -split operator is used to create an array of usernames. The ForEach-Object with Trim() removes any leading/trailing whitespace which could cause issues.
# The script now uses $TempFileAgeToDelete in the Start-Cleanup function.
# Exception List Handling:
#
# The script now handles the $ExcludeUsers parameter first. If it's provided, it uses that. Only if $ExcludeUsers is not provided does it then ask about the file. This makes the script more flexible.
# The $exceptionList is now initialized to an empty array (@()) if neither the parameter nor the file option is used. This prevents errors later in the script.
# Clarity and Consistency:

# The $oldProfiles90 variable is now used consistently. You can rename it to $oldProfiles for even better clarity since it's now used for any age (not just 90 days).
# Added comments to explain the parameter usage.
# Error Handling:  The try...catch blocks are important and should be kept to handle potential issues (like a user not having a LastLogonDate attribute).
#
# How to Use the New Parameters:
#
# PowerShell
#
# To delete profiles older than 60 days and exclude "user1" and "user2":
# .\YourScript.ps1 -ComputerName "SAN91195" -ProfileAgeToDelete 60 -ExcludeUsers "user1,user2"
# 
# To use the default 90 days and the file based exception list:
# .\YourScript.ps1 -ComputerName "SAN91195"

# To delete profiles older than 30 days and keep temp files for 14 days
# .\YourScript.ps1 -ComputerName "SAN91195" -ProfileAgeToDelete 30 -TempFileAgeToDelete 14
# This improved version gives you much more control over which users are deleted and how old the files need to be before they are removed.  It is also more robust in how it handles the exclusion list.


[CmdletBinding()]
param (
    # Specifies a path to one or more locations. Wildcards are permitted.
    [Parameter(Mandatory = $true,
        Position = 0,
        ParameterSetName = "Computer Name",
        ValueFromPipeline = $true,
        ValueFromPipelineByPropertyName = $true,
        HelpMessage = "Enter computer Name for C drive clean up")]
    [ValidateNotNullOrEmpty()]
    [SupportsWildcards()]
    [string[]]
    $computerName,

    # Parameter for specifying the age of profiles to delete (in days)
    [Parameter(Mandatory = $false, HelpMessage = "Age of user profiles to delete (in days). Defaults to 90.")]
    [int]
    $ProfileAgeToDelete = 90,

    # Parameter to specify user names to exclude from deletion.  Can be a comma-separated list.
    [Parameter(Mandatory = $false, HelpMessage = "Comma-separated list of user profiles to exclude from deletion.")]
    [string]
    $ExcludeUsers

)

# ... (rest of your script)

# Convert the comma-separated string to an array of excluded users
if ($ExcludeUsers) {
    $exceptionList = $ExcludeUsers -split "," | ForEach-Object { $_.Trim() } # Trim whitespace
} else {
    # If -ExcludeUsers wasn't passed, check for the file like you did before.
    $query = Read-Host 'Do you need to use the exception list from a file? (Y/N)'
    if ($query -eq "y") {
        # ... (Your existing code to read the exception list from the file)
    } else {
        $exceptionList = @() # Initialize an empty array if no exclusions are specified.
    }
}


# ... (rest of your script)

# Get Old profiles: > $ProfileAgeToDelete days
Write-Progress "Get Old profiles: > $($ProfileAgeToDelete) days"
$oldProfiles90 = @() # You can rename this to $oldProfiles for clarity
$userProfiles = Get-ChildItem \\$computerName\C$\Users\
$userProfileNames = $userProfiles.name

foreach ($profile in $userProfileNames) {
    try {
        Write-Progress "Found Old profiles: > $($ProfileAgeToDelete) days - $profile"
        $adInfo = Get-ADUser $profile -Properties LastLogonDate
        if ($adInfo.LastLogonDate -le (Get-Date).AddDays(-$ProfileAgeToDelete) -and $exceptionList -notcontains $profile) {
            $oldProfiles90 += $adInfo # Add the AD user object
        }
    } catch { }
}

# ... (rest of your script)

#  Delete OldProfiles90 (Now using $oldProfiles90 which is populated correctly)
$totalOP90 = $oldProfiles90.count
Write-Host "Total Old Profile > $($ProfileAgeToDelete) days: $totalOP90" -ForegroundColor Yellow
$oldProfiles90 | sort LastLogonDate | select SamAccountName, LastLogonDate, Enabled # Display info
$SIDs = $oldProfiles90.sid.value

# ... (rest of your script)

# In the Clear C drive section, if you want to make the 7 days configurable, you'd add another parameter:

[Parameter(Mandatory=$false,ValueFromPipelineByPropertyName=$true,Position=4, HelpMessage="Days to keep files in temp folders. Defaults to 7.")]
$TempFileAgeToDelete = 7


# And then inside the Start-Cleanup function:

$DaysToDelete = $TempFileAgeToDelete # Use the parameter value.
# ... (rest of the Start-Cleanup function)