# Define the UNC path to the folder or file you want to delete
$UNCPathToDelete = "\\Sanxxxxxx\c$\Users\xxxxx"

# Check if the path exists
if (Test-Path $UNCPathToDelete) {
    try {
        # Measure folder size before deletion
        Write-Host "Analyzing folder size and contents..." -ForegroundColor Cyan
        $itemCount = (Get-ChildItem -Path $UNCPathToDelete -Recurse | Measure-Object).Count
        Write-Host "Items in folder: $itemCount" -ForegroundColor Cyan

        # Remove the folder or file recursively
        Write-Host "Starting deletion process..." -ForegroundColor Yellow
        Remove-Item -Path $UNCPathToDelete -Recurse -Force -Verbose -ErrorAction Stop
        Write-Host "Successfully deleted: $UNCPathToDelete" -ForegroundColor Green
    } catch {
        Write-Host "An error occurred while deleting: $UNCPathToDelete" -ForegroundColor Red
        Write-Host $_.Exception.Message -ForegroundColor Yellow
    }
} else {
    Write-Host "The specified path does not exist: $UNCPathToDelete" -ForegroundColor Red
}
