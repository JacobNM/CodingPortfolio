# Module for commonly-used file management-based functions
   # Use command "$ENV:PSModulePath" to determine best place to place new modules

  # **Folder Functions**

# Function to create a new folder from a filepath provided by the script user.
function New-FileFolder {
    # Prompts script user for the full path ending with the name of the folder to create
    $FolderNameAndDestination = Read-Host -Prompt "`nProvide the full destination path ending with the name of the folder you are making (Example: C:/****/****/Folder Name) "
    
    # Variable to Test folder name and destination to ensure it does not already exist.
    $PathTestNewFolder = Test-Path $FolderNameAndDestination
    
    # Creates new folder if it does not exist
    if (!$PathTestNewFolder) {
        Write-Host "`n[$FolderNameAndDestination] not found. Creating now." $FolderNameAndDestination
        mkdir $FolderNameAndDestination | Out-Null
        # Informs script user of successful folder creation and prompts for return to main menu.
        Read-Host -Prompt "`nFolder [$FolderNameAndDestination] created. Press enter to return to the main menu"
    }
    
    # Informs user that folder already exists and returns to the main menu.
    else {
        Read-Host -Prompt "`n[$FolderNameAndDestination] already exists. Press enter to return to main menu"
    }
}

# Function to create one or more files in a designated folder based off of choices from script user.
function New-Files {
    param (
        [string]$DirectoryPath,
        [int]$NumberOfFiles,
        [string]$Extension
    )

    # Check if the directory exists and creates it if not
    if (-not (Test-Path -Path $DirectoryPath -PathType Container)) {
        Write-Host "`nDirectory does not exist. Creating directory: $DirectoryPath"
        New-Item -Path $DirectoryPath -ItemType Directory
    }

    # If Only one file is requested, file does not require number at beginning of file name.
    if ($NumberOfFiles -eq 1) {
            # Attach file to parent folder and create.
            $FileFolderPath = Join-Path -Path $DirectoryPath -ChildPath "$FileNamePrompt.$Extension"
            New-Item -Path $FileFolderPath -ItemType File
            Write-Host "`nCreated file: $FileName"
    }
            
    else {
        # Generate and create multiple files with number attached to each if user requires more than one file.
        1..$NumberOfFiles | ForEach-Object {
            # Format file name with space between file number and name for easier readability.
            $FileName = $([string]$_ + " " + $FileNamePrompt)
            
            # Attach files to parent folder and create.
            $FileFolderPath = Join-Path -Path $DirectoryPath -ChildPath "$FileName.$Extension"
            New-Item -Path $FileFolderPath -ItemType File
            Write-Host "`nCreated file: $FileName.$Extension"
        }
    }    
}
        
# Creates a function that will search through a folder for a file name and move files that match the name to a new designated folder.
    # Do not use the following symbols for file names ( \ / : * ? " < > | )
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

# Function to search for multiple files with different names in a folder, and move those files to a designated folder.
    # Example usage of function.
    # Move-FilesByPatterns -SourceFolder "C:\Users\j\Downloads" -DestinationFolder "C:\Users\j\Documents\Movies" -FilePatterns "Elvis","Barbie"
function Move-FilesByPatterns {
    param (
        [string]$SourceFolder,
        [string]$DestinationFolder,
        [string[]]$FilePatterns
    )

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
        

# Function to copy contents of folder to new destination
    # Function also sorts each file in destination folder by each of their associated extensions; creates a folder for each
    # Fields to be entered as specified in example below, following the function call:
    #'C:\users\j\downloads' 'C:\users\j\Documents\Downloaded files'

    function Copy-FilesAndSortByExtension{

        # Parameters
        
        Param([string]$source = "", [string] $destination = "")
        
        # Nested Functions
        
        #Function used to find specified folders - and create them - if they do not exist.
        function Search-Folder ([string]$path, [switch]$create) {
            $FolderExists = Test-Path $path
            
            if(!$FolderExists -and $create){
                #creates the directory if it does not exist
                write-host "`nFolder does not exist ($ExtDestinationDir). Creating now.`n"
                mkdir $path | Out-Null
                $FolderExists = Test-Path $path
            }
            return $FolderExists
        }
        
        #Function provides brief stats on specified folder - Folder path name;including extension, number of files in folder, and size (GB) - of folder
        function Get-FolderStats ([string]$path){
            $files = Get-ChildItem $path -Recurse | Where-Object {!$_.PSIsContainer}
            $TotalFiles = $files | Measure-Object -Property Length -Sum
            $FileStats = "" | Select-Object path,count,
                                    @{Name = "Size (MB)"; Expression = {[math]::Round($TotalFiles.sum/1mb,2)}}
                $FileStats.path = $path
                $FileStats.count = $TotalFiles.Count
                return $FileStats
        }
        
        # Main processing
        
        # Tests for existence of the source folder with search-folder function.
        $SourceExists = Search-Folder $source
        if (!$SourceExists){
            Write-Host "The source directory does not exist. Script cannot continue."
            Exit
        }
        
        # Tests for the existence of the destination folder using the search-folder function
        # If the folder is not found, it can be created with the -create parameter attached to the search-folder function
        $DestinationExists = Search-Folder $destination -create
        if (!$DestinationExists){
            Write-Host "the destination folder does not exist. Creating folder."
            exit
        }
        
        # Copy files to their appropriate destination
        $files = Get-ChildItem $source -Recurse | Where-Object {!$_.PSIsContainer}
        
        foreach ($file in $files){
            $Extension = $file.Extension.replace(".","")
            $ExtDestinationDir = "$destination\$extension"
            $ExtDestinationDir
            $ExtDestinationDirExists = Search-Folder $ExtDestinationDir -create
            if (!$ExtDestinationDirExists){
                Write-Host "The destination directory ($extdestinationdir) can't be created. Exiting script."
                exit
            }
            
            # Copy files
            Copy-Item $file.FullName $ExtDestinationDir
        }
        # Notifies user of successful file copy and provides brief info on the transfer.
        "`n"; Get-FolderStats $destination; "`n"
        
        $dirs = Get-ChildItem $destination | Where-Object {$_.PSIsContainer}
        foreach ($dir in $dirs){
            Get-FolderStats $dir.FullName
        }
        "`nFiles copied successfully."
}
        
# Function to rename a portion of multiple files in a designated folder
    # Note: Cannot use certain symbols in the renaming of files (e.g. \ / : * ? " < > | )
function Rename-Files {
    param (
        [string]$FolderPath,
        [string]$SearchPattern,
        [string]$ReplacePattern
    )
    
    # Places designated folder and objects into variable for easy access ;)
    $Files = Get-ChildItem -Path $FolderPath -File

    # Sort through files in folder for a pattern in the name of each file.
        # Replaces pattern in name with something else that is designated by function user
    $Files | ForEach-Object {
        $NewName = $_.Name -replace $SearchPattern, $ReplacePattern
        Rename-Item -Path $_.FullName -NewName $NewName
    }
}
# Example usage of function:
    # Rename-Files -FolderPath 'C:\Users\j\Documents\TV Shows\Game of Thrones - House of The Dragon\' -SearchPattern 'House.of.the.Dragon.' -ReplacePattern 'House Of The Dragon - '

    
# Function to create a new shared folder
function New-SharedFolder {
    # Function requests the script user create a name for the specified folder to be shared.
    $SharedFolderName = Read-Host -Prompt "`nCreate a name for the folder you would like to share"
    
    # Prompts user for the full path to the folder they would like to share.
    $FolderPath = Read-Host -Prompt "`nProvide the full path to the shared folder (Example: C:/****/****/FolderName) "
    
    # Spaces out requests from procedure.
    Write-Host "`n"
    
    # Function creates new folder share based off of info provided.
    # New-SmbShare -Name ShareName -Path C:\LocalFolder
    $SMBShareHT = @{
        Name = "$SharedFolderName"
        Path = "$FolderPath"
        }
        New-SmbShare @SMBShareHT
        
        # Script user is informed of successful share and prompted to return to main menu
    Read-Host -Prompt "`nOperation complete. Press enter to return to the main menu"
}

# Function to disable inherited access to an SMB share.
function Remove-SMBFolderInheritedAccess {
    # Prompts script user for the name of the folder to be disabled.
    $SharedFolderName = Read-Host -Prompt "`nProvide the name of the SMB shared folder to be disabled"
    
    $RemoveSMBInheritancesHT = @{
        Name = "$SharedFolderName"
        AccountName = 'Everyone'
        Confirm = $false
    }
    # Disables inherited access to folder specified by the script user
    Revoke-SmbShareAccess @RemoveSMBInheritancesHT
    
    # Prompts user to return to the sub-menu after operation completion.
    Read-Host -Prompt "Operation complete. Press enter to return to the sub-menu"
}

# Function to modify SMB Share permissions for a folder.
function Set-SMBSharePerms {
    # Function requests name of the specified folder to be shared.
    $SharedFolderName = Read-Host -Prompt "`nProvide the name for the folder you would like to modify permissions for"
    
    # Prompts user for the type of access rights they want assigned to the folder they would like to share.
    $FolderAccessRights = Read-Host -Prompt "`nChoose the type of access rights for the shared folder (Full, Change, Read, Custom)"
    
    # Prompts user for the Account to apply the share permissions to.
    $AccountSelection = Read-Host -Prompt "`nEnter the name of the account you would like to grant these permissions to (Examples: adatum\IT, adatum\Domain Users )"
    
    # Function creates new folder share based off of info provided.
    # New-SmbShare -Name ShareName -Path C:\LocalFolder
    $SMBShareHT = @{
        Name = "$SharedFolderName"
        AccessRight = "$FolderAccessRights"
        AccountName = "$AccountSelection"
        Confirm = $false
    }
        Grant-SmbShareAccess @SMBShareHT
    
    # Script user is informed of successful share and prompted to return to main menu.
    Read-Host -Prompt "`nOperation complete. Press enter to return to the main menu"
}

# Function to view the SMB share permissions on a folder.
function Show-FolderSMBPerms {
    # Prompts user for the name of the SMB share folder to be examined for permissions.
    $SMBShareFolder = Read-Host -Prompt "`nProvide the name of the SMB share to be examined"

    # Produces share permissions for the specified share folder.
    Get-SmbShareAccess $SMBShareFolder | Format-Table -AutoSize
    
    # Prompts for return to the sub-menu after the SMB share folder is displayed.
    Read-Host -Prompt "`nPress enter to return to the sub-menu"
}
