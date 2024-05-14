#!/bin/bash

# Script is designed to provide output of computer information in human-readable formatting

## Checks is user is root; if not, prompts them to use sudo for commands
if [ "$(whoami)" != "root" ]; then echo "must be root (try 'sudo' at beginning of script command)";exit 1; fi

# Grabs operating system release file and function list script for utilization of variables contained within;
source /etc/os-release
source reportfunctions.sh

# Inspection tools
    # Inspection tools used for variables created in function library
LshwOutput=$(lshw)
DmidecodeOutput=$(dmidecode -t 17)
LsblkOutput=$(lsblk -l)
# Tool is set up as array to be used for separate variables in function library
LscpuVariants=([1]="lscpu" [2]="lscpu --caches=NAME,ONE-SIZE")

# default option values to help determine script behaviour
verbose=false
System_Report=false
Disk_Report=false
Network_Report=false
Full_Report=true

# loop created to filter through any extra commands on command line
# Loop activates any valid options for script designated from user, and notifies user if they enter an invalid option
while [ $# -gt 0 ]; do
    case ${1} in
        -h)
        displayhelp
        exit 0
        ;;
        -v)
        verbose=true
        ;;
        -system)
        System_Report=true
        ;;
        -disk)
        Disk_Report=true
        ;;
        -network)
        Network_Report=true
        ;;
        *)
        echo "Oops. Your command is not a valid one. Refer to the help section below"
        error-message "$@"
        displayhelp
        exit 1
        ;;
    esac
    shift
done

# Check to see which reports have been requested on command line;
# If no additional arguments selected, run full report
    # Script uses a series of if conditional statements, instead of if/elif/else
    # Allows for multiple valid options to be enterred by user on command line
if [[ $verbose == true ]]; then
   Full_Report=false
   error-message 
fi

if [[ "$System_Report" == true ]]; then
    Full_Report=false
    computerreport
    osreport
    cpureport
    ramreport
    videoreport
fi

if [[ "$Disk_Report" == true ]]; then
    Full_Report=false
    diskreport
fi

if [[ "$Network_Report" == true ]]; then
    Full_Report=false
    networkreport
fi

if [[ "$Full_Report" == true ]]; then
    computerreport
    osreport
    cpureport
    ramreport
    videoreport
    diskreport
    networkreport
fi
# Provides information on who accessed the system information, and the time of day
Current_Time=$(date +"%I:%M %p %Z")
echo "System info produced by $USER at $Current_Time"