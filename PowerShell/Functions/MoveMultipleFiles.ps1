# Function to search for multiple files with different names in a folder, and move those files to a designated folder.
function Move-FilesByPatterns {
    param (
        [string]$SourceFolder,
        [string]$DestinationFolder,
        [string[]]$FilePatterns
    )

    # Example usage:
        # $SourceFolder = "C:\Users\j\Downloads"
        # $DestinationFolder = "C:\Users\j\Documents\Movies"
        # $FilePatterns = @("Elvis","Migration","Barbie")
    
    # Get all files in the source folder
    $Files = Get-ChildItem -Path $SourceFolder -File -Recurse

    # If user does not specify a file to search for in this function or the search function, they will be prompted to do so.
    if ([string]::IsNullOrEmpty($FilePatterns)) {
        # Prompts for name of file(s) to search for
        $FilePatterns = Read-Host -Prompt "`nEnter the name(s) of the file you are searching for in the folder"
    }
    
    # Acquire each of the files specified
    foreach ($FilePattern in $FilePatterns){
        
        $PathToFiles = Join-Path -Path $SourceFolder -ChildPath "*$FilePattern*"
        
        if (Test-Path -Path $PathToFiles -PathType Leaf){
            Write-Host "`n$FilePattern found at $PathToFiles"
        
            # Asks for confirmation before file move.
            $MoveConfirmation = Read-Host -Prompt "`nDo you want to move $FilePattern to $($DestinationFolder)? [Y/N] "
            if ($MoveConfirmation -eq "Y") {
                
                # Check if the directory exists
                if (-not (Test-Path -Path $DestinationFolder -PathType Container)) {
                    Write-Host "`n$DestinationFolder does not exist. Creating directory.. "
                    New-Item -Path $DestinationFolder -ItemType Directory
                    }

                    # Filter through folder for each file pattern
                    $FilteredFile = $Files | Where-Object {$_.Name -like "*$FilePattern*"}
                    # Get the file extension for each file.
                    $FileExtension = [System.IO.Path]::GetExtension($PathToFiles)
                    # Path to destination folder; moves file afterwards.
                    $DestinationPath = Join-Path -Path $DestinationFolder -ChildPath $FilteredFile.$FileExtension
                        Move-Item -Path $PathToFiles -Destination $DestinationPath
                        Write-Host "`nMoved $FilePattern to $DestinationPath`n"
                    }
                    
                    else {
                        Write-Host "`nCancelling move and exiting script`n";Break
                        }
                }
                
                else {
                    Write-Host "`n$FilePattern not found."
                }
            
            }

    }
        
# Example usage of function.
#Move-FilesByPatterns -SourceFolder $SourceFolder -DestinationFolder $DestinationFolder -FilePatterns $FilePatterns