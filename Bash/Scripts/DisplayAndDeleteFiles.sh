#!/bin/bash

# Script is designed to display and delete files older than a specified number of days in a given directory

# Check if the user has provided the path and number of days
if [ $# -ne 2 ]; then
    echo "Usage: $0 <path> <days>"
    exit 1
fi

path=$1
days=$2

# Check if the specified path exists
if [ ! -d "$path" ]; then
    echo "Error: The specified path does not exist."
    exit 1
fi

# Find files older than the specified number of days in the given path
echo "Locating Files older than $days days in $path:"

# Display files older than the specified number of days
find "$path" -type f -mtime +"$days" -exec ls -ltrah {} \;

# Confirmation before deletion of files
read -p "Do you want to delete these files? (y/n): " confirm
if [[ "$confirm" == [Yy]* ]]; then
    find "$path" -type f -mtime +"$days" -exec rm -f {} \;
    echo "Old files deleted."
else
    echo "No files were deleted."
fi

