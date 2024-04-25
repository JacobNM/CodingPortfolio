# Midterm Assignment : Importing Users to Active Directory
# Name: Jacob Martin
# Student Number: 200536041
# Course Code: COMP2138-24W-21434 24W Windows Server and PowerShell - 02
# Date: 02/21/2024

# This script will create security groups and OUs based off of CSV information provided
# This script is intended to create Active directory users from the CSV file;
# Script will then add each AD user to their appropriate group/department


# Prompts user for path to CSV.
$CSVUserPathInput = Read-Host -Prompt "Please enter the full path to the file containing the CSV file you want to import"
# Imports CSV file using path provided by user.
$CSVUserInfo = Import-Csv "$CSVUserPathInput"
Write-Host "Syncing Active Directory.."

# Creates a variable to determine all of the OUs that need to be created.
$OUsToCreate = $CSVUserInfo.department | Select-Object -Unique

# Creates a variable to determine all of the groups that need to be created.
$GroupsToCreate = $CSVUserInfo.department | Select-Object -Unique

# Checks to see if OUs exist, and if they do not, script creates them.
Write-Host "Checking to see if OUs exist.."
$OUsToCreate.foreach({
    if (Get-ADOrganizationalUnit -Filter "Name -eq '$_'") {
        Write-Verbose -Message "The OU [$_] already exists."
    }
    else {
        New-ADOrganizationalUnit -Name $_
        Write-Host "The [$_] OU has been created."
    }
})

# Checks to see if security groups exist, and if not, creates them
Write-Host "Checking to see if groups exist.."
$GroupsToCreate.foreach({
    if (Get-ADGroup -Filter "Name -eq '$_'") {
        Write-Verbose -Message "The group [$_] already exists."
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
        Write-Verbose -Message "AD User [$_] already exists in Active Directory."
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
        Write-Host "User [$UserDisplayName] has been created."

        # Adds each user to their appropriate groups
    Add-ADGroupMember -Identity $User.department -Members $UserDisplayName
    Write-Host "User [$UserDisplayName] has been added to their appropriate group."

    }
}
