## Function Library created for sysinfo.sh script

# Function used to gather information on CPU properties
function cpureport {
    CPU_Manufacturer=$(echo "$LshwOutput" | grep -a2 cpu:0 | tail -n 1 | sed 's/.*product: //')
    CPU_Architecture=$(hostnamectl | grep Architecture | sed 's/  *Architecture: //')
    CPU_Max_Speed=$(echo "$LshwOutput" | grep -m1 capacity | sed 's/.*capacity: //')
    CPU_Total_Cores=$(( $(${LscpuVariants[1]} | awk '/^Socket\(s\)/{ print $2 }') * $(lscpu | awk '/^Core\(s\) per socket/{ print $4 }') ))
    CPU_L1_Cache_Size=$(${LscpuVariants[2]} | grep L1 | sed 's/K/KB/' | sed '2 s/L1/                                L1/')
    CPU_L2_Cache_Size=$(${LscpuVariants[2]} | grep L2 | sed 's/K/KB/')
    CPU_L3_Cache_Size=$(${LscpuVariants[2]} | grep L3 | sed 's/M/MB/' )

# Inputs data from cpureport function into human-readable template 
cat << EOF

                 **CPU Report**
                ----------------
CPU Manufacturer/Model:         $CPU_Manufacturer
CPU Architecture:               $CPU_Architecture
CPU Core Total:                 $CPU_Total_Cores
CPU Max Speed:                  $CPU_Max_Speed
CPU L1 Cache Size:              $CPU_L1_Cache_Size
CPU L2 Cache Size:              $CPU_L2_Cache_Size
CPU L3 Cache Size:              $CPU_L3_Cache_Size

EOF
}

# Function used to gather information on Computer properties
function computerreport {
    Computer_Manufacturer=$(dmidecode -s system-manufacturer)
    Computer_Model=$(echo "$LshwOutput" | grep -m1 -w "product" | sed 's/.*product: //')
    Computer_Serial_Numer=$(echo "$LshwOutput" | grep -m1 -w "serial:" | sed 's/ *serial: //')   

# Inputs data from computerreport function into human-readable template 
cat << EOF

                     **Computer Report**
                    ---------------------
Manufacturer/Vendor:            $Computer_Manufacturer
Computer Description:           $Computer_Model
Computer Serial Number:         $Computer_Serial_Numer

EOF
}

# Gathers required properties information from os-release and compiles into osreport function
function osreport {

# Inputs data to be stored in function (from os-release) into human-readable template 
cat << EOF
                 
                 **OS Report**
                ---------------
Operating System:               $NAME
Version:                        $VERSION

EOF
}

# Function used to gather information on RAM properties
function ramreport {
    DIMM_Manufacturer=$(echo "$DmidecodeOutput" | grep -m1 -i manufacturer | sed 's/.*Manufacturer: //')
    # Determines if manufacturer is specified; if not, user is informed that info is N/A in VM
    if [[ "${DIMM_Manufacturer}" == "Not Specified" ]]; then
        DIMM_Manufacturer="N/A with VMs"
    fi

    DIMM_Model=$(echo "$DmidecodeOutput" | grep -m1 -w "Serial Number" | sed 's/.*Serial Number: //')
     # Determines if Serial number is specified; if not, user is informed that info is N/A in VM
    if [[ "${DIMM_Model}" == "Not Specified" ]]; then
        DIMM_Model="N/A with VMs"
    fi

    DIMM_Size=$(echo "$LshwOutput" | grep -i -A9 "\*\-memory" | tail -n1 | sed 's/.*size: //')

    DIMM_Speed=$(echo "$DmidecodeOutput" | grep -m1 Speed | sed 's/.*Speed: //')
    # Determines if speed is known; if not, user is informed that info is N/A in VM
    if [[ "${DIMM_Speed}" == "Unknown" ]]; then
       DIMM_Speed="N/A with VMs"
    fi
    
    DIMM_Location=$(echo "$LshwOutput" | grep -m1 'slot: RAM' | sed 's/.*slot: //')

        # Displays total RAM available
    RAM_Total_Size=$(echo "$LshwOutput" | grep -A10 '\*\-memory' | grep -m1 size | sed 's/.*size: // ')

        # Creates a structured table to display DIMM & "RAM total size" variables included above
    DIMM_Table=$(paste -d ';' <(echo "$DIMM_Manufacturer") <(
        echo "$DIMM_Model") <(echo "$DIMM_Size") <(echo "$DIMM_Speed") <(
        echo "$DIMM_Location") <(echo "$RAM_Total_Size") |
        column -N Manufacturer,Model,Size,Speed,Location,'Total RAM' -s ';' -o ' | ' -t)   

# Inputs data gathered in ramreport table into human-readable template
cat << EOF

                             **RAM Report**
                            ---------------- 
                            *Installed DIMMs*
                           ------------------- 

$DIMM_Table
EOF
}

# Function used to gather information on video card manufacturer and model
function videoreport {
    Videocard_Manufacturer=$(echo "$LshwOutput" | grep -A12 display | grep vendor | sed 's/.*vendor: //')
    Videocard_Model=$(echo "$LshwOutput" | grep -A12 display | grep product | sed 's/.*product: //')

# Inputs data from videoreport function into human-readable template
cat << EOF

                     **Video Report**
                    ------------------
Video Card Manufacturer:        $Videocard_Manufacturer  
Video Card Model:               $Videocard_Model  
EOF
}

# Function used to gather information on available disk drive properties
function diskreport { 
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

    Drive_Filesystem_Size_sda2=$(df -h | grep -w 'sda2' | awk '{print$2}' | sed 's/$/B/')
    Drive_Filesystem_Size_sda3=$(df -h | grep -w 'sda3' | awk '{print$2}' | sed 's/$/B/')

    Drive_Free_Space_sda2=$(df -h | grep -w 'sda2' | awk '{print$4}' | sed 's/$/B/') 
    Drive_Free_Space_sda3=$(df -h | grep -w 'sda3' | awk '{print$4}' | sed 's/$/B/') 

        # If any drive mountpoints are blank/empty, user receives an N/A in drive table
    Drive_Mntpt_0=$(echo "$LsblkOutput" | grep -w "sda" | awk '{print$7}')
    if [[ "${Drive_Mntpt_0}" == "" ]]; then
        Drive_Mntpt_0="N/A"
    fi
    Drive_Mntpt_1=$(echo "$LsblkOutput" | grep -w "sda1" | awk '{print$7}')
    if [[ "${Drive_Mntpt_1}" == "" ]]; then
        Drive_Mntpt_1="N/A"
    fi
    Drive_Mntpt_2=$(df -h | grep -w 'sda2' | awk '{print$6}')
    Drive_Mntpt_3=$(df -ah | grep 'sda3' | tail -n1 | awk '{print$6}')

        # Creates a structured table to display Disk variables from diskreport function
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

# Places disk report table info into a readable template form
cat << EOF
                                   
                                                  **Disk Report**
                                                 -----------------
                                                *Installed Drives*
                                               -------------------- 

$Drive_Table
EOF
}

# Function used to gather information on network properties
function networkreport {
    Interface_Manufacturer=$(echo "$LshwOutput" | grep -A12 network | grep vendor | sed 's/.*vendor: //' )
    Interface_Model=$(echo "$LshwOutput" | grep -A12 network | grep product | sed 's/.*product: //')
    Interface_Linkstate=$(ip a | grep "^2:" | sed 's/.*state//' | awk '{print$1}')
    Interface_Speed=$(ethtool "*" | grep -m1 Speed | sed 's/.*Speed: //')
    Interface_IP=$(ip a | grep -A6 "^2: " | grep -w inet | awk '{print$2}')

# Inputs data from networkreport function into human-readable template
cat << EOF

                 **Network Report**
                --------------------
Interface Manufacturer:         $Interface_Manufacturer 
Interface Model:                $Interface_Model
Interface Linkstate:            $Interface_Linkstate
Interface Speed:                $Interface_Speed
Interface IP:                   $Interface_IP

EOF
}

# Function to offer assistance to script users
function displayhelp {

# Inputs information for help function into human-readable template
    cat << EOF

    **sysinfo.sh Help**
   ---------------------
Usage: systeminfo.sh [Options]
Valid Arguments for script: 
    -h (Provides help to user)
    -v (run script verbosely, showing errors to user)
    -system (runs computer, os, cpu, ram, and video reports)
    -disk (runs disk report only)
    -network (runs network report only)
EOF
}

# Function to create error message and append to /var/log/syslog file
# If verbose option is indicated in script, user receives error message instead
function error-message {
    local timestamp 
    timestamp=$(date +"%Y-%m-%d %H:%M %p")
    local message
    message="$1"

    echo "Error has occurred at [$timestamp] for invalid option: $message ; Refer to help section (sysinfo.sh -h)"|logger -t "$(basename "$0")" -i -p user.warning

    if [[ "$verbose" == true ]]; then
        >&2 echo "Error has occurred at [$timestamp] for invalid option: $message ; Refer to help section (sysinfo.sh -h)"
    fi
}
