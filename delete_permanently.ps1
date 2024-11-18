# Define the path to the folder or file you want to delete
$PathToDelete = "file:\\San105336\c$\Users\cuiwe"

# Ensure the path exists
if (Test-Path $PathToDelete) {
    try {
        # Remove the folder or file recursively without using the Recycle Bin
        Remove-Item -Path $PathToDelete -Recurse -Force -ErrorAction Stop
        Write-Host "Successfully deleted: $PathToDelete" -ForegroundColor Green
    } catch {
        Write-Host "An error occurred while deleting: $PathToDelete" -ForegroundColor Red
        Write-Host $_.Exception.Message -ForegroundColor Yellow
    }
} else {
    Write-Host "The specified path does not exist: $PathToDelete" -ForegroundColor Red
}