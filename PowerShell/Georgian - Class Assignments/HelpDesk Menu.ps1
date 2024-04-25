# Final Assignment: ServiceDesk Menu
# Name: Jacob Martin
# Student Number: 200536041
# Course Code: COMP2138-24W-21434 24W Windows Server and PowerShell - 02
# Date: 04/01/2024

# This script is designed to create a menu system for the ServiceDesk team. The menu will include the following options:
        
    #**Active Directory**
        # New User
        # Remove user
        # Reset User Password
        # Change User's Phone Number
        # Change User's Department
        # New Security Group
        # Update Security Group Membership
        # Create multiple Active Directory objects from an imported CSV file.
        # Remove multiple users from Active Directory based off of an imported CSV file.
    # Folders, Permissions, and Sharing Sub-Menu
        # Create a New File Folder
        # Create one or more files for a designated folder
        # Create a new Shared folder
        # Remove inherited SMB Permissions from a folder
        # Set/Update SMB access on a folder
        # View SMB access for a folder
        # Remove NTFS inherited access on a folder
        # Set/Update NTFS Permissions to Folder
        # View Existing NTFS Permissions on a Folder
    # Server Information Sub-Menu
        # Display OS information
        # Display CPU information
        # Display Memory information
        # Display Disk information
        # Display current uptime of the machine


# Functions

        # **Active Directory Functions

# Function to create a new user in Active Directory.
function New-CustomADUser {
    # User will provide their first and last name, and will receive a simple AD account that utilizes the information provided
    $NewUserFirstName = Read-Host -Prompt "`nPlease enter your first name"
    $NewUserLastName = Read-Host -Prompt "`nPlease enter your last name"
    $NewUserPassword = Read-Host -AsSecureString "`nPlease enter your password "
    
    if (Get-ADUser -Filter "Name -eq '$NewUserFirstName $NewUserLastName'") {
        Write-Host "`nThe user [$NewUserFirstName $NewUserLastName] already exists."
        Read-Host -Prompt "`nPress enter to return to the main menu"
    }
    
    else {
        $NewADUserInfo = @{
            Name = "$NewUserFirstName $NewUserLastName"
            GivenName = "$NewUserFirstName"
            Surname = "$NewUserLastName"
            EmailAddress = "$NewUserFirstName.$NewUserLastName"
            UserPrincipalName = "$NewUserFirstName.$NewUserLastName@adatum.com"
            AccountPassword = $NewUserPassword
        }
        New-ADUser @NewADUserInfo 
        
        # Function confirms creation of account; displays new AD-user information to the user of this script.
        Write-Host "`nYour user has been created; Displaying new user information."
        Get-ADUser $NewADUserInfo.Name
        
        # Informs user they will return to the main menu when they press enter.
        Read-Host -Prompt "Press enter to return to the main menu"
    }
}

# Function to delete user from AD.
function Remove-ADAccount {
    # Function will ask for first and last name of AD user to be deleted by script user.
    $FirstNameRequest = Read-Host -Prompt "`nPlease enter the first name associated with the AD account"
    $LastNameRequest = Read-Host -Prompt "`nPlease enter the last name associated with the AD account"   

    # Uses information provided by script user to remove the specified user from AD. Script user is asked to confirm removal of account.
    Remove-ADUser "$FirstNameRequest $LastNameRequest"
    
    # User is updated with the successful removal and asked to return to the main menu.
    Read-Host -Prompt "`n$FirstNameRequest has been removed from Active Directory. Press enter to return to the main menu"
}

# Function to reset a password for a user specified by the script user.
function Reset-ADUserPassword {
    # Script user just needs to supply their first and last name
    $FirstNameRequest = Read-Host -Prompt "`nPlease enter the first name associated with the AD account"
    $LastNameRequest = Read-Host -Prompt "`nPlease enter the last name associated with the AD account"
    $UserNewPassword = Read-Host -AsSecureString "`nEnter your new password"
    Write-Host "`nResetting password for $FirstNameRequest $LastNameRequest."
    # Sets new password for user after based on password supplied in prompt
    Set-ADAccountPassword -Identity "$FirstNameRequest $LastNameRequest" -Reset -NewPassword $UserNewPassword
    # Informs user that their password has been successfully reset
    Write-Host "`n$FirstNameRequest $LastNameRequest's password has been reset."
    Read-Host -Prompt "`nPress enter to return to the main menu"
}

# Function to add an office phone number to an AD account specified by script user.
function Set-ADPhoneNumer {
    # Script user just needs to supply the first and last name of the designated user, and the phone number to add.
    $FirstNameRequest = Read-Host -Prompt "`nPlease enter the first name associated with the AD account"
    $LastNameRequest = Read-Host -Prompt "`nPlease enter the last name associated with the AD account"
    $PhoneNumberFromUser = Read-Host -Prompt "`nPlease enter the 10 digit phone number you would like to add (Recommended format: (###) ###-####) "
    Set-ADUser -Identity "$FirstNameRequest $LastNameRequest" -OfficePhone "$PhoneNumberFromUser"
    # Confirms script user successfully added phone number to account
    Write-Host "`nThe phone number has been added to the AD account for $FirstNameRequest $LastNameRequest. Pulling up details now...`n"
    Get-ADUser -Identity "$FirstNameRequest $LastNameRequest" -Properties GivenName,Surname,Name,DistinguishedName,EmailAddress,OfficePhone,telephoneNumber
    Read-Host -Prompt "`nPress enter to return to the main menu"
}

# Function to set/modify a specified AD user's department placement in AD by the script user.
function Set-ADUserDepartment {
    # Script user just needs to supply the first and last name of the designated user, and the department name to add.
    $FirstNameRequest = Read-Host -Prompt "`nPlease enter the first name associated with the AD account"
    $LastNameRequest = Read-Host -Prompt "`nPlease enter the last name associated with the AD account"   
    $DepartmentSelection = Read-Host -Prompt "`nPlease provide the name of the department you would like to attach to the account"
    
    Set-ADUser -Identity "$FirstNameRequest $LastNameRequest" -Department "$DepartmentSelection"
    
    Write-Host "`n$FirstNameRequest $LastNameRequest has been added to the $DepartmentSelection department."
    Read-Host -Prompt "`nPress enter to return to the main menu"
}

# Function to create a new security group for Active Directory.
function New-ADSecurityGroup {
    # Script user is asked for the name of the security group they would like to make.
    $NewSG = Read-Host -Prompt "`nPlease enter the name of the security group you would like to add to Active Directory"
    
    # Checks to see if group exists in AD or not
    if (Get-ADGroup -Filter "Name -eq '$NewSG'") {
        Write-Host "The group [$NewSG] already exists."
    }
    # New security group is created and script user is prompted to return to the main menu.
    else {
        New-ADGroup -Name "$NewSG" -GroupScope DomainLocal -GroupCategory Security
        Read-Host -Prompt "`nThe [$NewSG] security group has been created. Press enter to return to the main menu"
    }
}

# Function to place a user in a specified AD group by the script user.
function Update-ADUserGroupMembership {
    # Reqests first and last name of AD user to be modified.
    $FirstNameRequest = Read-Host -Prompt "`nPlease enter the first name associated with the AD account"
    $LastNameRequest = Read-Host -Prompt "`nPlease enter the last name associated with the AD account"       
    
    # Provides a list of the available groups the specified user can join.
    Write-Host "`nYou will be provided with a list of the available groups that $FirstNameRequest may join below.`n"
    Read-Host -Prompt "Press enter to continue"
    
    Write-Host "Available Groups to join.`n-------------------------`n" | 
    Get-ADGroup -filter * | Where-Object {$_.GroupScope  -eq "DomainLocal"} | Select-Object -Property Name | Format-Table
    
    # User is Prompted to write the name of the group they would like to join to be used for the group placement.
    $ADGroupSelection = Read-Host -Prompt "Please write down the name of the group you would like $FirstNameRequest to join exactly as it is shown above"
    
    # Specified User is added to the desired group and notified of the success.
    Add-ADGroupMember -Identity "$ADGroupSelection" -members "$FirstNameRequest $LastNameRequest"
    
    Get-ADGroup -Identity "$ADGroupSelection" -Properties Members
    
    # User is prompted to return to the main menu.
    Read-Host -Prompt "`n$FirstNameRequest has been added to the $ADGroupSelection group. Press enter to return to the main menu"
}

# Function to create multiple AD objects (Users, security groups, & OUs) based on an imported CSV file.
# Function will then add each AD user to their appropriate group/department in Active Directory.
function Add-MultipleADObjects {
    
    # Prompts user for path to CSV.
    $CSVUserPathInput = Read-Host -Prompt "`nPlease enter the full path to the file containing the CSV file you want to import"
    # Imports CSV file using path provided by user.
    $CSVUserInfo = Import-Csv "$CSVUserPathInput"
    Write-Host "`nSyncing Active Directory.."
    
    # Creates a variable to determine all of the OUs that need to be created.
    $OUsToCreate = $CSVUserInfo.department | Select-Object -Unique
    
    # Creates a variable to determine all of the groups that need to be created.
    $GroupsToCreate = $CSVUserInfo.department | Select-Object -Unique
    
    # Checks to see if OUs exist, and if they do not, script creates them.
    Write-Host "`nChecking to see if OUs exist.."
    $OUsToCreate.foreach({
        if (Get-ADOrganizationalUnit -Filter "Name -eq '$_'") {
        Write-Host "The OU [$_] already exists."
    }
    else {
        New-ADOrganizationalUnit -Name $_
        Write-Host "The [$_] OU has been created."
    }
})

# Checks to see if security groups exist, and if not, creates them
Write-Host "`nChecking to see if security groups exist.."
$GroupsToCreate.foreach({
    if (Get-ADGroup -Filter "Name -eq '$_'") {
        Write-Host "The group [$_] already exists."
    }
    else {
        New-ADGroup -Name $_ -GroupScope DomainLocal -GroupCategory Security -Path "OU=$_,DC=adatum,DC=com"
        Write-Host "The [$_] group has been created."
    }
})

# for each account imported into the 'CSVUser' variable, creates a new account in AD.
foreach ($User in $CSVUserInfo) {
    
    # Creates a username for each individual using first initial of first name and last name.    
    $UserDisplayName = $($User.firstname + " " + $User.lastname)
    
    # Checks to see if user account already exists, and if not, creates them.
    if (Get-ADUser -Filter "Name -eq '$UserDisplayName'") {
        Write-Host "AD User [$_] already exists in Active Directory."
    }
    else {
       
        # Properties to be added to each user
        $NewADUserInfo = @{
            Name = $UserDisplayName
            GivenName = $User.firstname
            Surname = $User.lastname
            EmployeeID = $User.username
            Department = $User.department
            Company = $User.company
            HomePhone = $User.telephone
            EmailAddress = $User.email
            StreetAddress = $User.streetaddress
            City = $User.city
            State = $User.state
            Country = $User.country
            PostalCode = $User.zipcode
            POBox = $User.physicalDeliveryOfficeName
            UserPrincipalName = $User.email
            Path = $User.ou
            AccountPassword = $(ConvertTo-SecureString $($User.password) -AsPlainText -Force)
            ChangePasswordAtLogon = $true
            Enabled = $true
        }
        # Creates each user using their unique properties gathered from CSV file
        New-AdUser @NewADUserInfo
        Write-Host "`nUser [$UserDisplayName] has been created."
        
        # Adds each user to their appropriate groups
        Add-ADGroupMember -Identity $User.department -Members $UserDisplayName
        Write-Host "User [$UserDisplayName] has been added to their appropriate group."
        
    }
}
# Script user is informed of import completion and prompted to return to main menu.
Read-Host -Prompt "`nImport complete. Press enter to return to the main menu"
}

# Function to remove multiple users from AD based off of an imported CSV file.
function Remove-MutipleADUsers {
    # Script user is prompted for the full path to the CSV file to be used for the operation.
    $CSVFilePath = Read-Host -Prompt "Please provide the full path to the CSV file you would like to use for the removal" 
    
    # Function uses the path provided to import the CSV.
    $CSVFileInfo = Import-Csv "$CSVFilePath"
    
    # Function cycles through each user in the CSV
    foreach ($User in $CSVFileInfo) {
        # Utilizes the firstname and lastname sections of the CSV to bulk remove users from AD.
        $UserDisplayName = $(($User.firstname) + " " + ($User.lastname))
        Remove-ADUser -Identity "$UserDisplayName" -Confirm:$false
        # Script user is informed of each user removal.
        Write-Host "`n$UserDisplayName removed from Active Directory."
    }
        
    # Script user is prompted to return to the main menu at the end of the removal process.
    Read-Host -Prompt "`nBulk removal complete. Press enter to return to the main menu"
}

        # **Folder Functions**

# Function to create a new folder from a filepath provided by the script user.
function New-FileFolder {
    # Prompts script user for the full path ending with the name of the folder to create
    $FolderNameAndDestination = Read-Host -Prompt "`nProvide the full destination path ending with the name of the folder you are making (Example: C:/****/****/Folder Name) "
    
    # Variable to Test folder name and destination to ensure it does not already exist.
    $PathTestNewFolder = Test-Path $FolderNameAndDestination
    
    # Creates new folder if it does not exist
    if (!$PathTestNewFolder) {
        Write-Host "`n[$FolderNameAndDestination] not found. Creating now." $FolderNameAndDestination
        mkdir $FolderNameAndDestination | Out-Null
        # Informs script user of successful folder creation and prompts for return to main menu.
        Read-Host -Prompt "`nFolder [$FolderNameAndDestination] created. Press enter to return to the main menu"
    }
    
    # Informs user that folder already exists and returns to the main menu.
    else {
        Read-Host -Prompt "`n[$FolderNameAndDestination] already exists. Press enter to return to main menu"
    }
}

# Function to create one or more files in a designated folder based off of choices from script user.
function New-Files {
    
    # prompts for folder path for file creation.
    [string]$DirectoryPath = Read-Host -Prompt "`nProvide the full path of the folder you are attaching the file(s) to (Example: C:/****/****/Folder Name) " 
    
    # Prompts for file name(s).
    [string]$FileNamePrompt = Read-Host -Prompt "`nProvide the name of the file(s) you would like to create (Example: My New File) " 
   
    # Prompts for extension type.
    [string]$Extension = Read-Host -Prompt "`nProvide the extension type for the file(s) you are creating (Examples: txt, pdf, csv, docx) "

    # Prompts for the number of files to be created
    [int]$NumberOfFiles = Read-Host -Prompt "`nProvide the number of files you would like to create"

    # Check if the directory exists and creates it if not
    if (-not (Test-Path -Path $DirectoryPath -PathType Container)) {
        Write-Host "Directory does not exist. Creating directory: $DirectoryPath"
        New-Item -Path $DirectoryPath -ItemType Directory
    }

    # If Only one file is requested, file does not require number at beginning of file name.
    if ($NumberOfFiles -eq 1) {
            # Attach file to parent folder and create.
            $FileFolderPath = Join-Path -Path $DirectoryPath -ChildPath "$FileNamePrompt.$Extension"
            New-Item -Path $FileFolderPath -ItemType File
            Write-Host "Created file: $FileName"
            }

    else {
        # Generate and create multiple files with number attached to each if user requires more than one file.
        1..$NumberOfFiles | ForEach-Object {
            # Format file name with space between file number and name for easier readability.
            $FileName = $([string]$_ + " " + $FileNamePrompt)
            
            # Attach files to parent folder and create.
            $FileFolderPath = Join-Path -Path $DirectoryPath -ChildPath "$FileName.$Extension"
            New-Item -Path $FileFolderPath -ItemType File
            Write-Host "Created file: $FileName.$Extension"
            }
        }
    
    # Informs script user of completed file creation and prompts for return to main menu.
    Read-Host -Prompt "`nFile creation complete. Press enter to return to the main menu"   
    }
    
# Function to create a new shared folder
function New-SharedFolder {
    # Function requests the script user create a name for the specified folder to be shared.
    $SharedFolderName = Read-Host -Prompt "`nCreate a name for the folder you would like to share"
    
    # Prompts user for the full path to the folder they would like to share.
    $FolderPath = Read-Host -Prompt "`nProvide the full path to the shared folder (Example: C:/****/****/FolderName) "
    
    # Spaces out requests from procedure.
    Write-Host "`n"
    
    # Function creates new folder share based off of info provided.
    # New-SmbShare -Name ShareName -Path C:\LocalFolder
    $SMBShareHT = @{
        Name = "$SharedFolderName"
        Path = "$FolderPath"
        }
        New-SmbShare @SMBShareHT
        
        # Script user is informed of successful share and prompted to return to main menu
    Read-Host -Prompt "`nOperation complete. Press enter to return to the main menu"
}

# Function to disable inherited access to an SMB share.
function Remove-SMBFolderInheritedAccess {
    # Prompts script user for the name of the folder to be disabled.
    $SharedFolderName = Read-Host -Prompt "`nProvide the name of the SMB shared folder to be disabled"
    
    $RemoveSMBInheritancesHT = @{
        Name = "$SharedFolderName"
        AccountName = 'Everyone'
        Confirm = $false
    }
    # Disables inherited access to folder specified by the script user
    Revoke-SmbShareAccess @RemoveSMBInheritancesHT
    
    # Prompts user to return to the sub-menu after operation completion.
    Read-Host -Prompt "Operation complete. Press enter to return to the sub-menu"
}

# Function to modify SMB Share permissions for a folder.
function Set-SMBSharePerms {
    # Function requests name of the specified folder to be shared.
    $SharedFolderName = Read-Host -Prompt "`nProvide the name for the folder you would like to modify permissions for"
    
    # Prompts user for the type of access rights they want assigned to the folder they would like to share.
    $FolderAccessRights = Read-Host -Prompt "`nChoose the type of access rights for the shared folder (Full, Change, Read, Custom)"
    
    # Prompts user for the Account to apply the share permissions to.
    $AccountSelection = Read-Host -Prompt "`nEnter the name of the account you would like to grant these permissions to (Examples: adatum\IT, adatum\Domain Users )"
    
    # Function creates new folder share based off of info provided.
    # New-SmbShare -Name ShareName -Path C:\LocalFolder
    $SMBShareHT = @{
        Name = "$SharedFolderName"
        AccessRight = "$FolderAccessRights"
        AccountName = "$AccountSelection"
        Confirm = $false
    }
        Grant-SmbShareAccess @SMBShareHT
    
    # Script user is informed of successful share and prompted to return to main menu.
    Read-Host -Prompt "`nOperation complete. Press enter to return to the main menu"
}

# Function to view the SMB share permissions on a folder.
function Show-FolderSMBPerms {
    # Prompts user for the name of the SMB share folder to be examined for permissions.
    $SMBShareFolder = Read-Host -Prompt "`nProvide the name of the SMB share to be examined"

    # Produces share permissions for the specified share folder.
    Get-SmbShareAccess $SMBShareFolder | Format-Table -AutoSize
    
    # Prompts for return to the sub-menu after the SMB share folder is displayed.
    Read-Host -Prompt "`nPress enter to return to the sub-menu"
}

# Function to disable inherited NTFS permissions from designated folder.
function Remove-NTFSFolderInheritedAccess {
    # Prompts script user for the full path to the folder to be disabled
    $FolderPath = Read-Host -Prompt "`nProvide the full path to the folder you want NTFS inheritances disabled for (Example: C:/****/****/FolderName) "
    
    # Removes NTFS inherited access for the specified folder.
    Disable-NTFSAccessInheritance -Path "$FolderPath" -RemoveInheritedAccessRules
    
    # Script user is informed of successful inheritance removal, and prompted to return to main menu.
    Read-Host -Prompt "`nOperation complete. Press enter to return to the main menu"
}

# Function to modify NTFS permissions for a folder
function Set-FolderNTFSAccess {
    # Prompts user for the path to the folder they want modified.
    $FolderPath = Read-Host -Prompt "`nProvide the full path to the folder you want modified with NTFS access (Example: C:/****/****/FolderName) "
    
    # Requests the user Account to be modified
    $AccountSelection = Read-Host -Prompt "`nEnter the name of the account you would like to provide permissions for (Examples: adatum\IT, adatum\Domain Users) "
    
    # Requests the type of permissions to be set to the designated account
    $PermissionsSelection = Read-Host -Prompt "`nChoose the permissions you would like to set for this folder (Examples: Read, Write, Modify, FullControl) "
    
    $NTFSChoicesHT= @{
        Path        = "$FolderPath"
        Account     = "$AccountSelection"
        AccessRights = "$PermissionsSelection"
    }
    # Grant the folder access dependent on the script user's choices:
    Add-NTFSAccess @NTFSChoicesHT
    # Script user receives confirmation that the operation was successful and they are returned to the sub-menu.
    Write-Host "`n[$FolderPath] has been modified to grant $PermissionsSelection permissions to $AccountSelection."
    Read-Host -Prompt "`nPress enter to return to the sub-menu"
}

# Function to view NTFS permissions for a folder.
function Show-FolderNTFSPerms {
    # Prompts user for the path to the NTFS folder to be examined for permissions.
    $FolderPath = Read-Host -Prompt "`nProvide the full path to the folder to be examined (Example: C:/****/****/FolderName) "
    
    # Searches for folder using path provided by user, and notifies script user of the search.
    Write-Host "Searching for folder..."
    Get-NTFSAccess $FolderPath | Format-Table -AutoSize
    
    # Notifies script user that search has concluded and they are returning to the sub-menu.
    Read-Host -Prompt "Search complete. Press enter to return to the sub-menu"
}

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
    Read-Host -Prompt "`nOperation complete. Press enter to return to the sub-menu"   
}

    # **Sub-Menu Functions**
    
# Function to create a sub-menu for Active Directory
function Show-ADSubMenu {

    do {
        # Clear screen to start menu off nice and neat.
        Clear-Host
    
        Write-Host "*** Active Directory Main Menu ***"     
        Write-Host "----------------------------------`n"
        Write-Host "1. Add user to Active Directory."
        Write-Host "2. Remove user from Active Directory."
        Write-Host "3. Reset user password."
        Write-Host "4. Set/Modify user phone number in Active Directory."
        Write-Host "5. Set/Modify user department in Active Directory."
        Write-Host "6. Add new security group to Active Directory."
        Write-Host "7. Update group membership in Active Directory." 
        Write-Host "8. Create multiple Active Directory objects from an imported CSV."
        Write-Host "9. Remove multiple Active Directory users based off of an imported CSV. "
        Write-Host "10. Return to HelpDesk main menu."
        
        # Requests user interaction with the menu options to intiate an AD operation.
        $ADMenuSelection = Read-Host -Prompt "`nWelcome to the Active Directory menu! Please Enter the corresponding number for the option you would like to use"

        # Creates conditions for each valid number option in the menu, and what to do in each instance.
        switch ($ADMenuSelection) {

            #  Activates Active Directory sub-menu when script user chooses the number 1. 
            1 { New-CustomADUser }
        
            # Activates function to remove account from AD when script user chooses the number 3.
            2 { Remove-ADAccount }
            
            # Activates function to reset the password for AD user when script user chooses the number 2.
            3 { Reset-ADUserPassword }
            
            # Activates function to set AD user's phone number when script user chooses the number 4.
            4 { Set-ADPhoneNumer }
            
            # Activates function to set the department for a specified user when the script user chooses the number 5.
            5 { Set-ADUserDepartment }

            # Activates function to create a new security group in AD when the script user chooses the number 6.
            6 { New-ADSecurityGroup }
            
            # Activates funtion to place AD user in specified AD group when the script user chooses the number 7.
            7 { Update-ADUserGroupMembership }

            # Activates function to add multiple objects to AD based off of an imported CSV file.
            8 { Add-MultipleADObjects }

            # Activates function to remove multiple accounts from AD based off of an imported CSV file.
            9 { Remove-MutipleADUsers }

            # Exits Active Directory menu back to the main menu
            10 { Write-Host "`nExiting back to main menu...";Start-Sleep -Seconds 2}
            
            # If the user selects an invalid number/option, they are encouraged to use a valid one and try again.
            Default {
                Write-Host "`nOops! Your choice was not a valid one. Please select a valid option (Choose a number from 1-10)."
                Read-Host "`nPress enter to try again"
            }
        }

    # Function loops through sub-menu until script user chooses the number 10 to exit back to main menu.
    } until (
        $ADMenuSelection -eq 10
    )

}

# Function to provide a Folders, Permissions, and sharing sub-menu.
function Show-FoldersSubMenu {

    do {
        # Clear screen to start menu off nice and neat.
        Clear-Host

        Write-Host "*** Folders, Permissions, and Sharing Main Menu ***"     
        Write-Host "---------------------------------------------------`n"
        Write-Host "1. Create a new file folder."
        Write-Host "2. Create one or more new files for a designated folder."
        Write-Host "3. Create a new shared folder."
        Write-Host "4. Remove SMB inherited access for a folder."
        Write-Host "5. Set/Update SMB Share access on a folder."
        Write-Host "6. View SMB Share permissions on a folder."
        Write-Host "7. Remove NTFS inherited access for a folder. "
        Write-Host "8. Set/Update NTFS permissions on a folder."
        Write-Host "9. View NTFS permissions on a folder."
        Write-Host "10. Return to HelpDesk main menu."

        # Requests user interaction with the menu options to intiate a folder operation.
        $FolderMenuSelection = Read-Host -Prompt "`nWelcome to the Folders, Permissions, and Sharing menu! Please Enter the corresponding number for the option you would like to use"

        # Creates conditions for each valid number option in the menu, and what to do in each instance.
        switch ($FolderMenuSelection) {

            #  Activates new folder function when script user chooses the number 1. 
            1 { New-FileFolder }
            
            # Activates function to create a new file in a folder when script user chooses the number 2.
            2 { New-Files }

            # Activates new shared folder function when script user chooses the number 3.
            3 { New-SharedFolder }
                
            # Activates function to remove SMB inheritances from a folder when user chooses the number 4.
            4 { Remove-SMBFolderInheritedAccess }
            
            # Activates function to update the SMB share for a folder when script user chooses the number 5.
            5 { Set-SMBSharePerms }

            # Activates function to view the SMB share for a folder when script user chooses the number 6.
            6 { Show-FolderSMBPerms }
            
            # Activates function to disable the NTFS inherited access for a folder when the script user chooses the number 7.
            7 { Remove-NTFSFolderInheritedAccess }
            
            # Activates function to update the NTFS permissions for a folder when the script user chooses the number 8.
            8 { Set-FolderNTFSAccess }
            
            # Activates funtion to view the NTFS permissions for a folder when the script user chooses the number 9.
            9 { Show-FolderNTFSPerms }
            
            # Returns to the main menu when the script user chooses the number 10.
            10 { Write-Host "`nExiting back to main menu...";Start-Sleep -Seconds 2 }

            # If the user selects an invalid number/option, they are encouraged to use a valid one and try again.
            Default {
                Write-Host "`nOops! Your choice was not a valid one. Please select a valid option (Choose a number from 1-10)."
                Read-Host "`nPress enter to try again"
            }
        }

    # Function loops through sub-menu until script user chooses the number 10 to exit back to main menu.
    } until (
        $FolderMenuSelection -eq 10
    )

}

# Function to create a sub-menu to display information about various computer components
function Show-CompInfoSubMenu {
  
    do {
        # Clear screen to start menu off nice and neat.
        Clear-Host
    
        Write-Host "*** Hardware & Software Main Menu ***"     
        Write-Host "-------------------------------------`n"
        Write-Host "1. Display Operating System information."
        Write-Host "2. Display CPU information."
        Write-Host "3. Display Memory information."
        Write-Host "4. Display Disk information."
        Write-Host "5. Display current uptime."
        Write-Host "6. Return to HelpDesk main menu."   

        # Requests user interaction with the menu options to intiate an operation.
        $CompInfoMenuSelection = Read-Host -Prompt "`nWelcome to the Hardware & Software Information menu! Please Enter the corresponding number for the option you would like to use"

        # Creates conditions for each valid number option in the menu, and what to do in each instance.
        switch ($CompInfoMenuSelection) {

            # Activates function to display OS info when script user chooses the number 1. 
            1 { Show-OSInfo }
        
            # Activates function to display CPU info when script user chooses the number 2.
            2 { Show-CPUInfo }
            
            # Activates function to display Memory info when script user chooses the number 3.
            3 { Show-MemoryInfo }

            # Activates function to display Disk info  when script user chooses the number 4.
            4 { Show-DiskInfo }

            # Activates function to display current uptime for machine when script user chooses the number 5.
            5 { Show-CurrentUptime }           
            
            # Exits back to the main menu when script user chooses the number 6.
            6 { Write-Host "`nExiting back to main menu...";Start-Sleep -Seconds 2}
            
            # If the user selects an invalid number/option, they are encouraged to use a valid one and try again.
            Default {
                Write-Host "`nOops! Your choice was not a valid one. Please select a valid option (Choose a number from 1-6)."
                Read-Host "`nPress enter to try again"
            }
        }
    
    # Function loops through sub-menu until script user chooses the number 6 to exit back to main menu.   
    } until (
        $CompInfoMenuSelection -eq 6
    )

}

# Function to provide guidance on how to navigate the menus to perform the various tasks.
function Show-HelpMessage {
    
    # Clear screen for easier readability
    Clear-Host
    
    # Introduction to help section
    Write-Host "`nWelcome to the Help menu! Here you will find guidance on how to navigate the various menu options available in this script."
    
    # Guidance for script usage
    Write-Host "`nThis script is structured like a menu system that navigates to various sub-menus depending on your choice."
    Write-Host "`nTo select an option, simply enter the number that corresponds with each menu choice."
    Write-Host "`nTo perform various common Active Directory operations, enter the number 1 at the menu screen."
    Write-Host "`nTo perform various Folder operations, enter the number 2 at the menu screen."
    Write-Host "`nTo inspect various computer hardware components for your machine, enter the number 3 at the menu screen."
    Write-Host "`nUpon selection of one of the three options, you will be guided to a similar menu that corresponds with the option you select."
    Write-Host "`nEach of these subsections will host various operations that you can perform by following the instructions for each option choice."
    Write-Host "`nEach sub-menu also provides an option to return to the main menu at any time."
    
    # Prompt for return to the main menu
    Read-Host -Prompt "`nPress enter to return to the option selection menu"
}

# Function to create a main menu for script. 
    # Provides access to various options including creating a new user
function Show-MainMenu {
# Clear screen to start menu off nice and neat.
Clear-Host
Write-Host "*** HelpDesk Main Menu ***"     
Write-Host "--------------------------`n"
Write-Host "1. Active Directory"
Write-Host "2. Folders, Permissions, and Sharing."
Write-Host "3. Display server information (CPU, OS, Memory, Disk, Uptime)."
Write-Host "4. Help information for menu use."
Write-Host "5. Exit script."

}

                                # ***Execution***

    # **Main Menu loop**
do {
    
    # Opens main menu in a continous loop until user explcitly request to exit script
    Show-MainMenu
    
    # Requests user interaction by asking for a number corresponding to the menu options.
    $UserMenuSelection = Read-Host -Prompt "`nWelcome to the HelpDesk menu! Please Enter the corresponding number for the option you would like to use"
    
    # Creates conditions for each valid number option in the menu, and what to do in each instance.
    switch ($UserMenuSelection) {
        
        # Activates Active Directory sub-menu when script user chooses the number 1. 
        1 { Show-ADSubMenu }
    
        # Activates Folders, shares, and perms sub-menu when script user chooses the number 2.
        2 { Show-FoldersSubMenu }
        
        # Activates the Computer Info sub-menu when the script user chooses the number 3.
        3 { Show-CompInfoSubMenu }

        # Displays help for using the script and navigating the menus.
        4 { Show-HelpMessage }
        
        # Exits script when script user selects the number 5.
        5 { Write-Host "`nExiting script..."; break }
            
        # If the user selects an invalid number/option, they are encouraged to use a valid one and try again.
        Default {
            Write-Host "`nOops! Your choice was not a valid one. Please select a valid option (Choose a number from 1-5)."
            Read-Host "`nPress enter to proceed back to the main menu"
            }
        
        }   
    
    # Script continues to loop back through to the main menu until the script user selects the number 5 to end script.
    } until ($UserMenuSelection -eq 5) 
