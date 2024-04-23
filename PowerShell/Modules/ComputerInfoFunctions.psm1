# Module for commonly used functions to find and display computer info for user
 
    # **Hardware/Software Functions**

# Function to view information on the associated operating system of the machine
function Show-OSInfo {
    
    # Clear screen for easier readability
    Clear-Host
    
    # List of OS details
    $OSInfoToDisplay = Get-CimInstance -ClassName Win32_OperatingSystem |
    Select-Object  Caption,CimClass,CSName,Description,Name,NumberOfUsers,OSType,RegisteredUser,Status,SerialNumber,Version |
    Format-List
    
    # Display operating system Info
    Write-Host "`nPulling up OS information..."
    Write-Host "`nOperating System Info:"
    Write-Host "----------------------"
    $OSInfoToDisplay

    # Notifies script user that search has concluded and they are returning to the sub-menu.
    Read-Host -Prompt "`nOperation complete. Press enter to return to the sub-menu"
}

# Function to display information on CPU information for machine.
function Show-CPUInfo {
    
    # Clear screen for easier readability
    Clear-Host
    
    # Collect CPU details
    $CPUInfo = Get-CimInstance Win32_Processor
    
    # Select info to display
    $CPUInfotoDisplay = $CPUInfo |
    Select-Object DeviceID,Name,Description,Status,Manufacturer,NumberOfCores,NumberOfLogicalProcessors,ProcessorId |
    Format-List

    # variable to produce current CPU utilization
    $CPUUtilization = ( $CPUInfo | Measure-Object -Property LoadPercentage -Average).Average

    # Display CPU Info
    Write-Host "`nPulling up CPU information..."
    Write-Host "`nCPU Info:"
    Write-Host "---------"
    $CPUInfotoDisplay
    
    Write-Host "`nCPU utilization:"
    Write-Host "----------------"
    $CPUUtilization

    # Notifies script user that search has concluded and they are returning to the sub-menu.
    Read-Host -Prompt "`nOperation complete. Press enter to return to the sub-menu"   
}

 # Function to display information on memory for the machine.
 function Show-MemoryInfo {
    
    # Clear screen for easier readability
    Clear-Host

    # OS details for memory utilization
    $OSInfo = Get-CimInstance -ClassName Win32_OperatingSystem

    # Variable to display total available memory for computer
    $TotalMemory = (Get-CimInstance Win32_PhysicalMemory | Measure-Object -Property Capacity -Sum).Sum / 1GB
    
    # Variable to display available memory as a percentage
    $AvailableMemoryPercentage = (($OSInfo.TotalVisibleMemorySize - $OSInfo.FreePhysicalMemory) * 100) / $OSInfo.TotalVisibleMemorySize

    # Display memory info including total memory and memory usage as a percentage
    Write-Host "`nPulling up Memory information..."   
    Write-Host "`nTotal memory available: $($TotalMemory)GB"
    Write-Host "Memory usage in Percentage: $([System.Math]::Round($AvailableMemoryPercentage,2))%"
    
    # Notifies script user that search has concluded and they are returning to the sub-menu.
    Read-Host -Prompt "`nOperation complete. Press enter to return to the sub-menu"   
 }

# Function to display Disk information for the machine.
function Show-DiskInfo {
    
    # Clear screen for easier readability
    Clear-Host

    # Collect information for Disks
    $DiskInfo = Get-CIMInstance CIM_diskdrive

    # Display disk info to user
    Write-Host "`nPulling up Disk information..."
    Write-Host "`nDisk Information:"
    Write-Host "-----------------"
    foreach ($Disk in $DiskInfo) {
        $Partitions = $Disk|get-cimassociatedinstance -resultclassname CIM_diskpartition
        foreach ($Partition in $Partitions) {
            $LogicalDisks = $Partition | get-cimassociatedinstance -resultclassname CIM_logicaldisk
            foreach ($LogicalDisk in $LogicalDisks) {
                    new-object -typename psobject -property @{
                                                                Drive = $LogicalDisk.deviceid
                                                                "Size(GB)" = $([System.Math]::Round($LogicalDisk.size / 1gb -as [double],2))
                                                                "Free(GB)" = $([System.Math]::Round($LogicalDisk.FreeSpace/1GB -as [double],2))
                                                                "Space Remaining(%)" = $([System.Math]::Round(100*$LogicalDisk.FreeSpace/$LogicalDisk.size -as [double],2))
                                                                } | Format-Table Drive,'Size(GB)','Free(GB)','Space Remaining(%)'
                    }
            }
    }

    # Notifies script user that search has concluded and they are returning to the sub-menu.
    Read-Host -Prompt "`nOperation complete. Press enter to return to the sub-menu"   
}

# Function to display the current uptime of the machine.
function Show-CurrentUptime {
 
    # Clear screen for easier readability
    Clear-Host   

    # OS details for uptime utilization.
    $OSInfo = Get-CimInstance -ClassName Win32_OperatingSystem

    # Collect Uptime details
    $Uptime = (Get-Date) - $osInfo.LastBootUpTime

    # Display uptime to script user
    # Display uptime
    Write-Host "`nUptime: $($Uptime.Days) days, $($Uptime.Hours) hours, $($Uptime.Minutes) minutes`n"

    # Notifies script user that search has concluded and they are returning to the sub-menu.
    Read-Host -Prompt "`nOperation complete. Press enter to return to main menu"
}
