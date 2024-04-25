# Assignment 9: Storage Management
# Name: Jacob Martin
# Student Number: 200536041
# Course Code: COMP2138-24W-21434 24W Windows Server and PowerShell - 02
# Date: 03/14/2023

# This script is designed to find the available RAW 60 GB disk that was added to the VM.
# The script will initialize the disk, create the following partitions, and format them.

# Script is to include hashtables.
# The last volume size cannot be specified. 
    # It should be calculated to use the remaining amount left to ensure there is no space left unutilized.

#   Partition       Drive Letter        Size        File System     Volume Label

#   Partition 1         V               1GB             FAT          v-fat-6041
#   Partition 2         W               10GB         Exteneded FAT   w-exfat-6041
#   Partition 3         X               20GB           FAT 32        x-fat32-6041
#   Partition 4         Y           Remaining space     NTFS         y-ntfs-6041

# Assuming that the new raw disk has not yet been initialized, it is important to take care of that.
$NewRawDisk = Get-Disk |
Where-Object PartitionStyle -eq Raw |
Select-Object -First 1

$NewRawDisk | Initialize-Disk -PartitionStyle MBR

    ## Partition Creation ##

# Partition 1: Drive letter V, 1GB size, FAT file system, volume label v-fat-6041
$PartitionOneInfo = @{
    DiskNumber = $NewRawDisk.DiskNumber
    Size = 1GB
    DriveLetter = 'V'
    }
New-Partition @PartitionOneInfo

# Format Partition 1 with volume info
$PartitionOneVolume = @{
    DriveLetter = 'V'
    FileSystem = 'FAT'
    NewFileSystemLabel = "v-fat-6041"
    }
Format-Volume @PartitionOneVolume

# Partition 2: Drive letter W, 10GB size, ExFAT file system, volume label w-exfat-6041
$PartitionTwoInfo = @{
    DiskNumber = $NewRawDisk.DiskNumber
    Size = 10GB
    DriveLetter = 'W'
    }
New-Partition @PartitionTwoInfo

# Format Partition 2 with volume info
$PartitionTwoVolume = @{
    DriveLetter = 'W'
    FileSystem = 'ExFAT'
    NewFileSystemLabel = "w-exfat-6041"
    }
Format-Volume @PartitionTwoVolume

# Partition 3: Drive letter X, 20GB size, FAT32 file system, volume label x-fat32-6041
$PartitionThreeInfo = @{
    DiskNumber = $NewRawDisk.DiskNumber
    Size = 20GB
    DriveLetter = 'X'
}
New-Partition @PartitionThreeInfo

# Format Partition 3 with volume info
$PartitionThreeVolume = @{
    DriveLetter = 'X'
    FileSystem = 'FAT32'
    NewFileSystemLabel = "x-fat32-6041"
    }
Format-Volume @PartitionThreeVolume

# Partition 4: Drive letter Y, Remaining size to be allocated, NTFS file system, volume label y-ntfs-6041
$PartitionFourInfo = @{
    DiskNumber = $NewRawDisk.DiskNumber
    UseMaximumSize = $True
    DriveLetter = 'Y'
    }
New-Partition @PartitionFourInfo

# Format Partition 4 with volume info
$PartitionFourVolume = @{
    DriveLetter = 'Y'
    FileSystem = 'NTFS'
    NewFileSystemLabel = "y-ntfs-6041"
    }
Format-Volume @PartitionFourVolume
