# Script to create menu for functions from custom-made module (COMP2138-Module.psm1)
    # COMP2138-Module.psm1 is placed in Module folder that can be found by PowerShell 
    # Use command "$ENV:PSModulePath" to determine best place to place new modules.

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
