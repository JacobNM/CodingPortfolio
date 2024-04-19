# Function to create multiple files in a designated folder. Includes extension type.

function New-MultipleFilesWithExtension {
    param (
        [string]$DirectoryPath,
        [int]$NumberOfFiles,
        [string]$Extension
    )

    # Check if the directory exists
    if (-not (Test-Path -Path $DirectoryPath -PathType Container)) {
        Write-Host "Directory does not exist. Creating directory: $DirectoryPath"
        New-Item -Path $DirectoryPath -ItemType Directory
    }

    # Generate and create files
    1..$NumberOfFiles | ForEach-Object {
        $FileName = Join-Path -Path $DirectoryPath -ChildPath "File$_.$Extension"
        New-Item -Path $FileName -ItemType File
        Write-Host "Created file: $FileName"
    }
}

# Example usage:
New-MultipleFilesWithExtension -DirectoryPath "C:\File Test" -NumberOfFiles 5 -Extension "txt"
