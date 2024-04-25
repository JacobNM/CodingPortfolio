#Script Provides basic information for various properties on host computer
# filters through parameters entered on the command line to generate a system report based on user input
# Information is provided by functions held in "module200536041"
function Get-MySystemReport {
    [CmdletBinding()]
    param ([Parameter ( Mandatory=$false,
                        Position=0,
                        ValueFromPipeline=$true,
                        HelpMessage="The Disk-Report parameter provides information on host disk drives"
                        )]
            [switch]$Disks,
            [Parameter( Mandatory=$false,
                        Position=0,
                        ValueFromPipeline=$true,
                        HelpMessage="The 'Network-Report' parameter provides information on host network adapters"
                        )]
            [switch]$Network,
            [Parameter( Mandatory=$false,
                        Position=0,
                        ValueFromPipeline=$true,
                        HelpMessage="The 'System-Report' parameter provides information on host network adapters"
                        )]
            [switch]$System)
    # If Disks is specified on command line, Disk Drives info is presented
    if ($Disks) {
        Get-MyDiskDrives
        }
    # If System is specified on command line, system info is presented, including:
        # Host CPU, operating system, RAM, & video card info
    # "`n" is used to create spacing for information displayed
    if ($System) {
        Get-OperatingSystem
        Get-CPUInfo
        Get-MyRAM
        Get-MyVideoCardInfo
        }
    # If Network is specified on command line, IP configuration info is presented
    if ($Network) {
        Get-MyIPConfigs
    }
    # If no options are specified on command line, all information is provided in report
    if ((!$Disks) -and (!$Network) -and (!$System)) {
        Get-OperatingSystem
        Get-CPUInfo
        Get-MyRAM
        Get-MyDiskDrives
        Get-MyVideoCardInfo
    }
}
