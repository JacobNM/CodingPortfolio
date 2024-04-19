# Script creates functions that will search through a folder for a file name and move files that match the name to a new designated folder.
    # Do not use the following symbols for naming new files/folders ( \ / : * ? " < > | )

function Move-SpecificFiles {
    param (
        [string]$SourceFolder,
        [string]$DestinationFolder,
        [string]$FileNames
    )

    # Get all files in the source folder
    $Files = Get-ChildItem -Path $SourceFolder -File -Recurse
    
    # If user does not specify a file to search for in this function or the search function, they will be prompted to do so.
    if ([string]::IsNullOrEmpty($FileNames)) {
        # Prompts for name of file(s) to search for
        $FileNamesPrompt = Read-Host -Prompt "Enter the name of the file you are searching for in the folder"
        $FilteredFiles = $Files | Where-Object { $_.Name -like "$FileNamesPrompt*" }
        }
        
        # Filter files based on specific file names
        $FilteredFiles = $Files | Where-Object { $_.Name -like "$FileNames*" }
        
    # Check if the directory exists
    if (-not (Test-Path -Path $DestinationFolder -PathType Container)) {
        Write-Host "`n$DestinationFolder does not exist. Creating directory.. "
        New-Item -Path $DestinationFolder -ItemType Directory
    }
    
    # Pulls up filtered files for move confirmation.
    Write-Host "`nPulling up files to be moved.."
    $FilteredFiles

    # Asks for confirmation before file move.
    $MoveConfirmation = Read-Host -Prompt "`nAre you sure you want to move the files indicated above to $($DestinationFolder)? [Y/N] "


    if ($MoveConfirmation -eq "Y") {
        # Move filtered files to the destination folder
        $FilteredFiles | ForEach-Object {
            $DestinationPath = Join-Path -Path $DestinationFolder -ChildPath $_.Name
            Move-Item -Path $_.FullName -Destination $DestinationPath
            Write-Host "`nMoved file: $($_.Name)."
            }
        }

    # Exits script if move is cancelled.
    else {
        Write-Host "`nCancelling move and exiting script";Break
    }
}

    # Example usage:
        # Pulls up source folder to search and pulls up destination folder to move files to
        # Move-SpecificFiles -SourceFolder 'C:\Users\j\Downloads\' -DestinationFolder 'C:\Users\j\Documents\TV Shows\Game of Thrones - House of The Dragon'
        # User will then be asked for name of file to search for



# Function to request information from user and plug them into file moving function.
function Search-FileRequest {
    
    # Prompts for Source folder to search.
    $SourceFolderPrompt = Read-Host -Prompt "`nPlease enter the path to the folder you want to search through"
    
    # Prompts for Source folder to search.
    $FileNamesPrompt = Read-Host -Prompt "`nPlease enter the name of the file(s) you want to search for"
    
    # Prompts for Source folder to search.
    $DestinationFolderPrompt = Read-Host -Prompt "`nPlease enter the path to the folder you want to move the files to"
    
    # Uses prompts from user to search for files in folder.
    Move-SpecificFiles -SourceFolder $SourceFolderPrompt -DestinationFolder $DestinationFolderPrompt -FileNames $FileNamesPrompt
}
