# Module for commonly-used Active Directory-based functions
   # Use command "$ENV:PSModulePath" to determine best place to place new modules

   #**Functions**

# Function to create a new user in Active Directory.
function New-CustomADUser {
    # User will provide their first and last name, and will receive a simple AD account that utilizes the information provided
    $NewUserFirstName = Read-Host -Prompt "`nPlease enter your first name"
    $NewUserLastName = Read-Host -Prompt "`nPlease enter your last name"
    
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
    Write-Host "`nResetting password for $FirstNameRequest $LastNameRequest."
    # Advises user to create a complex password with at least 10 characters, a capital letter, a number, etc
    Write-Host ""
    Set-ADAccountPassword -Identity "$FirstNameRequest $LastNameRequest"
    # Informs user that their password has been successfully reset
    Write-Host "`n $FirstNameRequest $LastNameRequest's password has been reset."
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
