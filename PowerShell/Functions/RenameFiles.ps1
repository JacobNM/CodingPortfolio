# Script to rename a portion of multiple files in a designated folder
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