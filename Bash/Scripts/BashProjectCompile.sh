#!/bin/bash
# Script is designed to provide output of computer information in human-readable formatting

## Checks is user is root; if not, prompts them to use sudo for commands
# if [ "$(whoami)" != "root" ]; then echo "must be root (try "sudo" at beginning of script command)";exit 1; fi

# Grabs operating system release file for utilization of variables contained within
source /etc/os-release
# source /home/jacob/COMP2101/bash/reportfunctions.sh
source /home/jacob/Repositories/CodingPortfolio/Bash/Functions/reportfunctions.sh

## Variable lists

# Inspection tools
LshwOutput=$(sudo lshw)
DmidecodeOutput=$(sudo dmidecode -t 17)
# Tools are set up as arrays to be used for separate variables below
LscpuVariants=([1]="lscpu" [2]="lscpu --caches=NAME,ONE-SIZE")
LsblkOutput=$(lsblk -l)
    # Inspection tools used for variables created in sections below

# Provides current time and timezone
Current_Time=$(date +"%I:%M %p %Z")
# Searches for PC hostname 
MY_FQDN=$(hostname -f)
# Prints IP address of host (not including 127 networks)
My_IP=$(hostname -I)

# System variables - Used to obtain personal computer information
Computer_Manufacturer=$(sudo dmidecode -s system-manufacturer)
Computer_Model=$(echo "$LshwOutput" | grep -m1 -w "product" | sed 's/.*product: //')
Computer_Serial_Numer=$(echo "$LshwOutput" | grep -m1 -w "serial:" | sed 's/ *serial: //')

# CPU variables - Used to obtain information on CPU from personal computer
CPU_Manufacturer=$(echo "$LshwOutput" | grep -a2 cpu:0 | tail -n 1 | sed 's/.*product: //')
CPU_Architecture=$(hostnamectl | grep Architecture | sed 's/  *Architecture: //')
CPU_Max_Speed=$(echo "$LshwOutput" | grep -m1 capacity | sed 's/.*capacity: //')
CPU_Total_Cores=$(( $(${LscpuVariants[1]} | awk '/^Socket\(s\)/{ print $2 }') * $(lscpu | awk '/^Core\(s\) per socket/{ print $4 }') ))
CPU_L1_Cache_Size=$(${LscpuVariants[2]} | grep L1 | sed 's/K/KB/' | sed '2 s/L1/                                 L1/')
CPU_L2_Cache_Size=$(${LscpuVariants[2]} | grep L2 | sed 's/K/KB/')
CPU_L3_Cache_Size=$(${LscpuVariants[2]} | grep L3 | sed 's/M/MB/' )

# RAM/DIMM variables - Used to obtain information on installed memory components
    # If specific information is not indicated in certain variables,
        ## user is informed that output is N/A when using VMs
DIMM_Manufacturer=$(echo "$DmidecodeOutput" | grep -m1 -i manufacturer | sed 's/.*Manufacturer: //')
if [[ "${DIMM_Manufacturer}" == "Not Specified" ]]; then
    DIMM_Manufacturer="N/A with VMs"
fi

DIMM_Model=$(echo "$DmidecodeOutput" | grep -m1 -w "Serial Number" | sed 's/.*Serial Number: //')
if [[ "${DIMM_Model}" == "Not Specified" ]]; then
    DIMM_Model="N/A with VMs"
fi

DIMM_Size=$(echo "$LshwOutput" | grep -i -A9 "\*\-memory" | tail -n1 | sed 's/.*size: //')

DIMM_Speed=$(echo "$DmidecodeOutput" | grep -m1 Speed | sed 's/.*Speed: //')
if [[ "${DIMM_Speed}" == "Unknown" ]]; then
   DIMM_Speed="N/A with VMs"
fi

DIMM_Location=$(echo "$LshwOutput" | grep -m1 'slot: RAM' | sed 's/.*slot: //')
    
    # Displays total RAM available to determine if all memory components are accounted for
RAM_Total_Size=$(echo "$LshwOutput" | grep -A10 '\*\-memory' | grep -m1 size | sed 's/.*size: // ')

    # Creates a structured table to display DIMM variables & RAM total memory included above
DIMM_Table=$(paste -d ';' <(echo "$DIMM_Manufacturer") <(
    echo "$DIMM_Model") <(echo "$DIMM_Size") <(echo "$DIMM_Speed") <(
    echo "$DIMM_Location") <(echo "$RAM_Total_Size") |
    column -N Manufacturer,Model,Size,Speed,Location,'Total RAM' -s ';' -o ' | ' -t)

# Disk Storage Variables

Drive_Partition_0=$(echo "$LsblkOutput" | grep -w "sda" | awk '{print$1}')
Drive_Partition_1=$(echo "$LsblkOutput" | grep -w "sda1" | awk '{print$1}')
Drive_Partition_2=$(echo "$LsblkOutput" | grep -w "sda2" | awk '{print$1}')
Drive_Partition_3=$(echo "$LsblkOutput" | grep -w "sda3" | awk '{print$1}')

Drive_Vendor_0=$(echo "$LshwOutput" | grep -A10 "\*\-disk" | grep vendor | sed 's/.*vendor: //')
Drive_Vendor_1=$(echo "$LshwOutput" | grep -m1 -A7 "\*\-volume:0" | grep vendor | sed 's/.*vendor: //')
Drive_Vendor_2=$(echo "$LshwOutput" | grep -m1 -A7 "\*\-volume:1" | grep vendor | sed 's/.*vendor: //')
Drive_Vendor_3=$(echo "$LshwOutput" | grep -m1 -A7 "\*\-volume:2" | grep vendor | sed 's/.*vendor: //')

Drive_Model_0=$(echo "$LshwOutput" | grep -A10 "\*\-disk" | grep 'product' | sed 's/.*product: //' )

Drive_Size_0=$(echo "$LsblkOutput" | grep -w 'sda' | awk '{print $4}' | sed 's/$/B/')
Drive_Size_1=$(echo "$LsblkOutput" | grep -w 'sda1' | awk '{print $4}' | sed 's/$/B/')
Drive_Size_2=$(echo "$LsblkOutput" | grep -w 'sda2' | awk '{print $4}' | sed 's/$/B/')
Drive_Size_3=$(echo "$LsblkOutput" | grep -w 'sda3' | awk '{print $4}' | sed 's/$/B/')

Drive_Filesystem_Size_sda2=$(sudo df -h | grep -w 'sda2' | awk '{print$2}' | sed 's/$/B/')
Drive_Filesystem_Size_sda3=$(sudo df -h | grep -w 'sda3' | awk '{print$2}' | sed 's/$/B/')

Drive_Free_Space_sda2=$(sudo df -h | grep -w 'sda2' | awk '{print$4}' | sed 's/$/B/') 
Drive_Free_Space_sda3=$(sudo df -h | grep -w 'sda3' | awk '{print$4}' | sed 's/$/B/') 

    # If drive mountpoint is blank/empty, user receives an N/A in drive table
Drive_Mntpt_0=$(echo "$LsblkOutput" | grep -w "sda" | awk '{print$7}')
if [[ "${Drive_Mntpt_0}" == "" ]]; then
    Drive_Mntpt_0="N/A"
fi
Drive_Mntpt_1=$(echo "$LsblkOutput" | grep -w "sda1" | awk '{print$7}')
if [[ "${Drive_Mntpt_1}" == "" ]]; then
    Drive_Mntpt_1="N/A"
fi
Drive_Mntpt_2=$(sudo df -h | grep -w 'sda2' | awk '{print$6}')
Drive_Mntpt_3=$(sudo df -ah | grep 'sda3' | tail -n1 | awk '{print$6}')

    # Creates a structured table to display Disk variables included above
        # First Column of table
Drive_Table=$(paste -d ';' <(echo "$Drive_Partition_0" ; echo "$Drive_Partition_1" ; 
    echo "$Drive_Partition_2" ; echo "$Drive_Partition_3" ) <(
        # Second column of table
    echo "$Drive_Vendor_0" ; echo "$Drive_Vendor_1" ; echo "$Drive_Vendor_2" ; echo "$Drive_Vendor_3") <(
        # Third column of table
    echo "$Drive_Model_0" ; echo N/A ; echo N/A ; echo N/A) <(
        # Fourth column of table
    echo "$Drive_Size_0" ; echo "$Drive_Size_1" ; echo "$Drive_Size_2" ; echo "$Drive_Size_3") <(
        # Fifth column of table
    echo N/A ; echo N/A ; echo "$Drive_Filesystem_Size_sda2" ; echo "$Drive_Filesystem_Size_sda3") <(
        # Sixth column of table
    echo N/A ; echo N/A ; echo "$Drive_Free_Space_sda2" ; echo "$Drive_Free_Space_sda3") <(
        # Seventh column of table
    echo "$Drive_Mntpt_0" ; echo "$Drive_Mntpt_1" ; echo "$Drive_Mntpt_2" ; echo "$Drive_Mntpt_3" ) |
        # column cmd used to create table from variables gathered above
    column -N 'Logical Name (/dev/sda)',Vendor,Model,Size,'Filesystem Size','Filesystem Free Space','Mount Point' -s ';' -o ' | ' -t)

# Information extracted is provided in human-readable format using cat command
    # Tables are created to house relevant variables from above
    # DIMM Table and Disk Storage tables are pre-made in corresponding variable sections above

cat <<EOF

System info produced by $USER at $Current_Time

Current VM Information
==================================================
FQDN:                            $MY_FQDN
IP Address:                      $My_IP
==================================================

System Description
========================================================================================

Manufacturer/Vendor:             $Computer_Manufacturer
Computer Description:            $Computer_Model
Computer Serial Number:          $Computer_Serial_Numer
========================================================================================


CPU Information
========================================================================

CPU Manufacturer/Model:          $CPU_Manufacturer
CPU Architecture:                $CPU_Architecture
CPU Core Total:                  $CPU_Total_Cores
CPU Max Speed:                   $CPU_Max_Speed
CPU L1 Cache Size:               $CPU_L1_Cache_Size
CPU L2 Cache Size:               $CPU_L2_Cache_Size
CPU L3 Cache Size:               $CPU_L3_Cache_Size
========================================================================


Operating System Information
===============================================================
Operating System:                $NAME
Version:                         $VERSION
===============================================================

RAM Information
============================================================================
                            Installed DIMMs
$DIMM_Table

============================================================================

Disk Storage Information
=================================================================================================================================================
                            Installed Drives
$Drive_Table

=================================================================================================================================================

EOF
