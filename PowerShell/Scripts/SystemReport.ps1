#Script Provides basic information for various properties on host computer
# filters through parameters entered on the command line to generate a system report based on user input
# Information is provided by functions held in COMP2101 module 
[CmdletBinding()]
# Parameters made for "Disks", "System", and "Network" options on command line
param ([Parameter (Mandatory=$false,
                    Position=0,
                    ValueFromPipeline=$true,
                    HelpMessage="The Disks parameter provides info on host disk drives"
        )][switch]$Disks,
        [Parameter (Mandatory=$false,
                    Position=0,
                    ValueFromPipeline=$true,
                    HelpMessage="The System parameter provides info on host system properties"       
        )][switch]$System,
        [Parameter (Mandatory=$false,
                    Position=0,
                    ValueFromPipeline=$true,
                    HelpMessage="The Network parameter provides info on host network properties"       
        )][switch]$Network)

    # If Disks is specified on command line, Disk Drives info is presented
    if ($Disks) {
        Get-MyDiskDrives
    }
    # If System is specified on command line, system info is presented, including:
        # Host CPU, operating system, RAM, & video card info
    # "`n" is used to create spacing for information displayed
    if ($System) {
        Get-CPUInfo
        Get-OperatingSystem
        Get-MyRAM
        "`n"
        Get-MyVideoCardInfo
    }
    # If Network is specified on command line, IP configuration info is presented
    if ($Network) {
        Get-MyIPConfigs
    }
    # If no options are specified on command line, all information is provided in report
    # "`n" is used to create spacing for information displayed
    if ((!$Disks) -and (!$System) -and (!$Network)) {
        Get-OperatingSystem
        Get-CPUInfo
        Get-MyRAM
        "`n`n"
        Get-MyDiskDrives
        Get-MyVideoCardInfo
        "`n`n"
        Get-MyIPConfigs
    }