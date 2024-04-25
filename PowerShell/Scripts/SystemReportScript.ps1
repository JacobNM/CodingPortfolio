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

    if ($Disks) {
        Get-MyDiskDrives
        }

    if ($System) {
        Get-OperatingSystem
        Get-CPUInfo
        Get-MyRAM
        Get-MyVideoCardInfo
        }

    if ($Network) {
        Get-MyIPConfigs
    }

    if ((!$Disks) -and (!$Network) -and (!$System)) {
        Get-OperatingSystem
        Get-CPUInfo
        Get-MyRAM
        Get-MyDiskDrives
        Get-MyVideoCardInfo
    }
}
