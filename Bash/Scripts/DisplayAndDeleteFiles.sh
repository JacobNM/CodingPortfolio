#!/bin/bash

# default option values to help determine script behaviour
path=false
days=false


while [ $# -gt 0 ]; do
    case ${1} in
        -path)
        path=true
        ;;
        -days)
        days=true
        ;;
        *)
        echo """Oops. Your command is not a valid one.
        Valid options are:
        - path: The path to the directory you want to check for old files.
        - days: The number of days to consider a file old. Default is 30 days."""
        exit 1
        ;;
    esac
    shift
done

# Check to see which options have been requested on command line;
# If no options have been selected, defaults will be used
if [[ $path == true ]]; then
    echo "Path to directory provided."
fi

if [[ $days == true ]]; then
    echo "Number of days provided."
fi

# Check if path provided is a valid directory
if [[ ! -d "$path" ]]; then
        echo "Error: The specified path does not exist."
        return 1
    fi

# Check if number of days is provided as an argument, otherwise use 30 days
if [ -z "$2" ]; then
    days=30
else
    days="$2"
fi

# Find files older than specified number of days in the given path
find "$path" -type f -mtime +"$days" -print

# Confirmation before deletion of files
read -p "Do you want to delete these files? (y/n): " confirm
if [[ "$confirm" == [Yy]* ]]; then
    find "$path" -type f -mtime +"$days" -exec rm -f {} \;
    echo "Old files deleted."
else
    echo "No files were deleted."
fi