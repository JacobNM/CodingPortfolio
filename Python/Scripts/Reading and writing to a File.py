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

stringToWrite = (firstName + '\n' + lastName + '\n' + employeeID + '\n' + dateOfBirth)

if (os.path.exists('c:\\Python files\\subfolder\\test')==False):
    os.makedirs ('c:\\Python files\\subfolder\\test')
    testFile = open ('c:\\Python files\\subfolder\\test\\testFile.txt', 'w')
    testFile.write (stringToWrite)
    testFile.close ()
    
else:
    testFile = open ('c:\\Python files\\subfolder\\test\\testFile.txt', 'a')
    testFile.write (stringToWrite)
    testFile.close ()

fileOne = open ('c:\\Python files\\subfolder\\test\\testFile.txt')
fileContent = fileOne.read ()
fileOne.close ()
print (fileContent)

