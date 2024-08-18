#!/bin/bash

# Function will list the files in the specified path that are older than the specified threshold and prompt you for confirmation before deleting them. 
# If the specified path doesn't exist, it will display an error message.
check_and_delete_files() {
    local target_path="$1"
    local days_threshold="$2"

    if [[ ! -d "$target_path" ]]; then
        echo "Error: The specified path does not exist."
        return 1
    fi

    find "$target_path" -type f -mtime +"$days_threshold" -exec ls -ltrah {} \;
    read -p "Do you want to delete these files? (y/n): " confirm
    if [[ "$confirm" == [Yy]* ]]; then
        find "$target_path" -type f -mtime +"$days_threshold" -exec rm -f {} \;
        echo "Old files deleted."
    else
        echo "No files were deleted."
    fi
}

# Usage example:
# ./check_and_delete.sh "/path/to/your/folder" 30

# Replace `"/path/to/your/folder"` with the actual path you want to check.
# and provide the desired number of days as the second argument. 
