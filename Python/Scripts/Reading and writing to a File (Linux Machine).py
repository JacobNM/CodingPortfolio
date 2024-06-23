import os

firstName = ""
lastName = ""
employeeID = ""
dateOfBirth = ""

def captureInput():
    global firstName, lastName, employeeID, dateOfBirth
    print ('Please provide your first name')
    firstName = input ()
    print ('Please provide your last name')
    lastName = input ()
    print ('Please provide your Employee ID')
    employeeID = input ()
    print ('Please provide your date of birth')
    dateOfBirth = input ()

captureInput ()

stringToWrite = (firstName + '\n' + lastName + '\n' + employeeID + '\n' + dateOfBirth + '\n')

# Creates a path to the file and folder, starting from home in the folder menu.
folderPath = os.path.join(os.path.expanduser('~'), 'Python Files', 'Subfolder', 'Test Folder')
filePath = os.path.join(folderPath, 'Test.txt')

# Checks to see if path already exists, and creates it if not.
if not os.path.exists(folderPath):
    os.makedirs (folderPath)
    print(f"Directory '{folderPath}' created successfully.\n" )
# Creates a new text file and writes the content recorded from user to the last folder on the Path.
    with open(filePath, 'a') as file:
        file.write(stringToWrite)
else:
    with open(filePath, 'a') as file:
        file.write(stringToWrite)

# Opens file afterwards and displays current content to terminal.
print ("Displaying current file contents below:\n")
fileOne = open (filePath)
fileContent = fileOne.read ()
fileOne.close ()
print (fileContent)

