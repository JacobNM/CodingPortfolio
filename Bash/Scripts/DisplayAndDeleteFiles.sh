#!/bin/bash

# Check if path is provided as an argument, otherwise use current directory
if [ -z "$1" ]; then
    path="."
else
    path="$1"
fi

if [[ ! -d "$path" ]]; then
        echo "Error: The specified path does not exist."
        return 1
    fi

# Check if number of days is provided as an argument, otherwise use 7 days
if [ -z "$2" ]; then
    days=7
else
    days="$2"
fi

# Find files older than specified number of days in the given path
find "$path" -type f -mtime +"$days" -print