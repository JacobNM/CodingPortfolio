# write a function that takes two string arguments in which the legnth of 
#the second string is four times longer than the first string
# the purpose of the function is to generate 4 random numbers from x to y
# where x is the number of characters in the first string and
# y is the number of characters in the second string
#print out all 4 random numbers with a '&' symbol between each number using the sep argument
#test the function by asking the user for two strings in which
# the length of the second string is four times longer than the first string
# use a while loop along with the not statement (negative logic)
# to keep asking until the user provides the correct strings
#once the strings are provided pass them to the function as arguments to test the function

import random
def numberGenerator (wordEntry1,wordEntry2):
    randompick1 = (random.randint(stringOne, stringTwo,))
    randompick2 = (random.randint(stringOne, stringTwo,))
    randompick3 = (random.randint(stringOne, stringTwo,))
    randompick4 = (random.randint(stringOne, stringTwo,))
    print (randompick1, randompick2, randompick3, randompick4, sep = '&')

print ('Please provide a word here')
wordEntry1 = len(input())

print ('Please provide a word with 4 times the amount of characters as your first word')
wordEntry2 = len(input())
while not (wordEntry2 / wordEntry1 == 4):
    print ('Please enter a word 4 times the length of your first word')
    wordEntry2 = len(input())
if (wordEntry2 / wordEntry1 == 4):
    print ('thank you')
stringOne = wordEntry1
stringTwo = wordEntry2
numberGenerator (wordEntry1, wordEntry2)