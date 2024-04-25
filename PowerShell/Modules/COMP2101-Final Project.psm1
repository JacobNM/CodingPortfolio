# Functions from profile

# Todays date formatted as:
# Day of the week (full name)
# Month of the year (full name) 
# Day of the month  (integer)
# Year (integer)
$todaysDate = $(get-date -UFormat "%A %B %d %Y")

# Function to create a welcome message that delivers a salutation and the date to the user
function welcome {

if ((Get-Date).DayOfWeek -eq "Sunday") {
    $Salutation = "Sir"
}

elseif ((Get-Date).DayOfWeek -eq "Monday") {
    $Salutation = "Private"
}

elseif ((Get-Date).DayOfWeek -eq "Tuesday") {
    $Salutation = "Master Chief"
}

elseif ((Get-Date).DayOfWeek -eq "Wednesday") {
    $Salutation = "Monsieur"
}

elseif ((Get-Date).DayOfWeek -eq "Thursday") {
    $Salutation = "Commander"
}

elseif ((Get-Date).DayOfWeek -eq "Friday") {
    $Salutation = "Colonel"
}

elseif ((Get-Date).DayOfWeek -eq "Saturday") {
    $Salutation = "Wingman"
}

Write-Host "Hello $($Salutation)! Todays date is $($todaysDate)"

}

# Function to produce specified info about host processor
function get-mycpuinfo {

get-ciminstance cim_processor | Format-List Manufacturer,Name,CurrentClockSpeed,MaxClockSpeed,NumberOfCores

}

# Function to produce specified info about host disks
function get-mydisks {
    Get-Disk | Format-Table -AutoSize Manufacturer,Model,SerialNumber,FirmwareVersion,@{Name="Size (GB)"; Expression={[int]($_.Size/1GB)}}
    
}

# Functions from Lab 4 script

#Function to produce info about host system hardware
function Get-SystemHardware {
    $ComputerSystemProperties=Get-WmiObject win32_computersystem
    
    $ComputerSystemList=$ComputerSystemProperties | 
    Select-Object Name,Manufacturer,Model,Description | 
    Format-List Name,Manufacturer,Model,Description
    
    "---------------------------"
    "       System Hardware     "
    "---------------------------"
    $ComputerSystemList
    
}

# Function to produce info about host operating system
function Get-OperatingSystem {
    $OperatingSystemProperties=Get-CimInstance win32_operatingsystem
    
    $OperatingSystemList=$OperatingSystemProperties | 
    Select-Object Name,Version | 
    Format-List Name,Version
    
    "---------------------------"
    "       OS Information      "
    "---------------------------"
    $OperatingSystemList
}

# Function to produce info about host CPU
function Get-CPUInfo {
    $CPUInfo=get-ciminstance win32_processor
    $CPUAttributes=$CPUInfo |
    # Section checks to see if specified objects are empty
    # If object is empty, "N/A" is placed in object, otherwise object remains the same
    ForEach-Object {
        if ($null -eq $_.DeviceID) {$CPU_DeviceID="N/A"} else {$CPU_DeviceID=$_.DeviceID}
        if ($null -eq $_.Manufacturer) {$CPU_Manufacturer="N/A"} else {$CPU_Manufacturer=$_.Manufacturer}
        if ($null -eq $_.Name) {$CPU_DeviceName="N/A"} else {$CPU_DeviceName=$_.Name}
        if ($null -eq $_.CurrentClockSpeed) {$CPU_CurrrentClockSpeed="N/A"} else {$CPU_CurrrentClockSpeed=$_.CurrentClockSpeed}
        if ($null -eq $_.MaxClockSpeed) {$CPU_MaxClockSpeed="N/A"} else {$CPU_MaxClockSpeed=$_.MaxClockSpeed}
        if ($null -eq $_.NumberOfCores) {$CPU_CoreCount="N/A"} else {$CPU_CoreCount=$_.NumberOfCores}
        if ($null -eq $_.L2CacheSize) {$CPU_L2CacheSize="N/A"} else {$CPU_L2CacheSize=$_.L2CacheSize}
        if ($null -eq $_.L3CacheSize -or $_.L3CacheSize -eq 0) {$CPU_L3CacheSize="N/A"} else {$CPU_L3CacheSize=$_.L3CacheSize}
        # Section takes variables from above and assigns them to custom objects
        new-object -TypeName psobject -Property @{
                "Device ID" = $CPU_DeviceID
                Manufacturer = $CPU_Manufacturer
                Name = $CPU_DeviceName
                "Current Clock Speed" = $CPU_CurrrentClockSpeed
                "Max Clock Speed" = $CPU_MaxClockSpeed
                "Number Of Cores" = $CPU_CoreCount
                "L2 Cache Size" = $CPU_L2CacheSize
                "L3 Cache Size" = $CPU_L3CacheSize     
        }
        # Custom objects are formatted into a list for human-friendly output
    } | Format-List "Device ID",Manufacturer,Name,"Current Clock Speed","Max Clock Speed","Number Of Cores","L2 Cache Size","L3 Cache Size"
    
"---------------------------"
"       Processor Info      "
"---------------------------"
$CPUAttributes 

}

# Function to produce info about host RAM
function Get-MyRAM {
    $totalcapacity = 0
    $RAM_Attributes=get-wmiobject -class win32_physicalmemory |
        # Section checks to see if specified objects are empty
        # If object is empty, "N/A" is placed in object, otherwise object remains the same           
        ForEach-Object {
            
            if ($null -eq $_.speed) {$RamSpeed="N/A"} else {$RamSpeed=$_.speed}
            # Section takes variables from above and assigns them to custom objects
            new-object -TypeName psobject -Property @{
                Manufacturer = $_.manufacturer
                Description = $_.Description
                "Speed(MHz)" =$RamSpeed
                "Size(MB)" = $_.capacity/1mb
                Bank = $_.banklabel
                Slot = $_.devicelocator   
                }

# Creates a human-friendly variable to display available RAM capacity of host system
$totalcapacity += $_.capacity/1GB
} 
# Custom objects are formatted into a table for human-friendly output
$RAM_Output=$RAM_Attributes | Format-Table -auto Manufacturer,Description, "Size(MB)", "Speed(MHz)", Bank, Slot
 # "`n" is used to create spacing for information displayed

"---------------------------"
"       RAM Information     "
"---------------------------`n"
$RAM_Output

# Provides info on Total available RAM on system
"Total RAM: ${totalcapacity}GB "
"--------------"
}

# Function to produce info about host disk drives
# Uses nested loops to cycle through for specified objects 
function Get-MyDiskDrives {
        $diskdrives = Get-CIMInstance CIM_diskdrive
    $DiskDrivesOutput=
  foreach ($disk in $diskdrives) {
      $partitions = $disk|get-cimassociatedinstance -resultclassname CIM_diskpartition
      foreach ($partition in $partitions) {
            $logicaldisks = $partition | get-cimassociatedinstance -resultclassname CIM_logicaldisk
            foreach ($logicaldisk in $logicaldisks) {
                # Creates custom objects pulled from logicaldisks loop     
                new-object -typename psobject -property @{Manufacturer=$disk.Manufacturer
                                                              Model=$disk.Model
                                                              Location=$partition.deviceid
                                                              Drive=$logicaldisk.deviceid
                                                              "Size(GB)"=$logicaldisk.size / 1gb -as [int]
                                                              "Free(GB)"=$logicaldisk.FreeSpace/1GB -as [int]
                                                              "Space Remaining(%)"=100*$logicaldisk.FreeSpace/$logicaldisk.size -as [int]
                                                              } | Format-Table -AutoSize Drive,Manufacturer,Model,Location,'Size(GB)','Free(GB)','Space Remaining(%)'
           }
      }
  }
  # "`n" is used to create spacing for information displayed
  "---------------------------"
  "   Disk-Drive Information  "
  "---------------------------`n"
  $DiskDrivesOutput
}

## Creates a function to produce information about IP-enabled configurations
# Initial cmd (Get-ciminstance) produces all enabled network adapters
# Where-Object cmd determines if any information resides in the specified properties
# Requests IP information using Select-Object cmd
# Sorts information into table using Format-Table
function Get-MyIPConfigs {
    $IP_Attributes=get-ciminstance win32_networkadapterconfiguration | 
        Where-Object  {$_.IPEnabled -eq "true" } |
    Select-Object  Index,Description,IPAddress,IPSubnet,DNSDomain,DNSServerSearchOrder 
    
    $IP_TableOutput=$IP_Attributes | Format-Table -AutoSize Index,Description,IPAddress,IPSubnet,DNSDomain,DNSServerSearchOrder

    "---------------------------"
    "   IP Configuration Info   "
    "---------------------------"
    $IP_TableOutput
}

# Function to produce info about host video card
function Get-MyVideoCardInfo {
    $VideoCardOutput=Get-CimInstance Win32_VideoController |
    Select-Object AdapterCompatibility,Description,@{
        # Custom object made to present screen's horizontal and vertical resolution under one "width by height" object
        Name="CurrentResolution(W X H)"; Expression={$_.CurrentHorizontalResolution, "X",  $_.CurrentVerticalResolution -as [string]}
    }
    # "`n" is used to create spacing for information displayed
    "`n---------------------------"
    "     Video Card Info       "
    "---------------------------`n"
    $VideoCardOutput
}