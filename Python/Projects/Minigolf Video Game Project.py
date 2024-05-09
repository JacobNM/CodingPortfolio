# imports necessary modules 'random', 'os', 'urlib.request' and 'BeautifulSoup' for use in game
import random, os, urllib.request
from bs4 import BeautifulSoup

# Asks player to type their name to start up game
userName = input ('Please enter your name here: ')
# Creates a function to introduce the player to the fundamentals of the game
def gameIntro (userName):
    print ('\nHello ' + userName)
    print ('Welcome to Minigolf!')
    print ('Here is how the game works:')
    print ('\nYou have three holes of varying diffculty before you')
    print ('Each hole is a certain number of points away from you, and your ball, at the start of each hole')
    print ('Each time you hit your ball, your distance from the cup will decrease, and a "stroke" will be added to your score')
    print ('Your goal is to get your ball into the cup of each hole with the fewest amount of strokes')
    print ('After a certain number of attempts on each hole, the hole will be completed for you, and an additional stroke will be added to your score.')
    print ('Be mindful. Some holes may have a hidden surprise...')
    input ('Press enter to continue. ')
    print ('\nYou may choose between three swing options to begin with for hitting your ball: "tap", "putt", or "whack"')
    print ('"tap" shots have a point power of 1 when hitting your ball, and are essential when you are close to the cup')
    print ('"putt" shots (2-3 point power) have more power than "tap" shots, but are not as powerful as "whack" shots (4-7)')
    print ('\nNow go out there and have fun!')
    input ('Press enter to receive a current weather update for the Barrie area.\n')

gameIntro (userName)

# Accesses weather statistics from 'weather.gc.ca' and creates parsible HTML content
barrieWeatherUrl = urllib.request.urlopen ('https://www.weather.gc.ca/city/pages/on-151_metric_e.html')
barrieWeatherHtml = barrieWeatherUrl.read ()
barrieWeatherSoup = BeautifulSoup (barrieWeatherHtml, 'html.parser')
# Extracts text from webpage and converts the text into a list type class
barrieWeatherText = barrieWeatherSoup.get_text ()
barrieWeatherTextList = barrieWeatherText.split ()
# Extracts current temperature from list using specified conditions
for word in barrieWeatherTextList:
    stringToSlice = '°C°C'
    stringToAvoid = 'km'
    if stringToSlice in word and not stringToAvoid in word:
        temperatureSlice = word
# Removes unneeded characters attached to the end of 'temperatureSlice' variable
temperature = temperatureSlice[:-2]

# Presents player with a weather-related message depending on temperature, then proceeds to first hole
# Slices out characters that don't represent numbers, then runs the leftover integer through the conditions
if int(temperature[:-2]) <= 10 and int(temperature[:-2]) > 0:
    print ('Brr, the temperature outside is ' +(temperature)+ '...A little chilly. Not ideal for outdoor Minigolf, but a great day for indoor Minigolf!')
elif int(temperature[:-2]) < 0:
    print ('The temperature outside is ' +(temperature)+ '. It is below freezing out there! Put a tuque on and settle in for some Minigolf!')
else:
    print ('The temperature outside is ' +(temperature)+ '..What in blazes are you doing inside on a beautiful day like this?! Finish your game of indoor Minigolf and head outside for some outdoor Minigolf!')
input ('Press enter to proceed to the first hole of Minigolf')

# Start of first hole. Welcomes player and asks for shot choice
# Also notifies the player that they have 4 shot attempts before the hole is completed for them
print ('\nWelcome to the the first hole ' + (userName) + '!')
print ('This one will be easy. You are only 7 points away! Good luck!')
print ('\nKeep in mind that you will have three shot attempts to complete the first hole.')
print ('After that, an additional stroke will be added to your score, and the hole will be completed for you.')
input ('Press enter to continue. \n')

holeOneShotOneDistanceFromUser = 7
strokeCounterHoleOne = 0

def userInputHoleOneShotOne (shotOptionHoleOneShotOne):
        global strokeCounterHoleOne, holeOneShotOneDistanceFromUser
        # Creates tap option. Decreases player distance from the current hole by 1
        if shotOptionHoleOneShotOne == "tap":
            strokeCounterHoleOne = strokeCounterHoleOne + 1
            holeOneShotOneDistanceFromUser = holeOneShotOneDistanceFromUser - 1
            print ( '\nYou are ' + str(holeOneShotOneDistanceFromUser) + ' points away from the cup!')

        # Creates putt option for player
        # Decreases their distance from the hole by a randomly assigned number of 2 or 3
        elif shotOptionHoleOneShotOne == "putt":
            strokeCounterHoleOne = strokeCounterHoleOne + 1
            holeOneShotOneDistanceFromUser = holeOneShotOneDistanceFromUser - random.randint(2,3)
            print ('\nYou are ' + str(holeOneShotOneDistanceFromUser) + ' points away from the cup!')

        # Creates whack option
        # Decreases their distance from the hole by a randomly assigned number from 4 to 7
        elif shotOptionHoleOneShotOne == "whack":
            strokeCounterHoleOne = strokeCounterHoleOne + 1
            holeOneShotOneDistanceFromUser = holeOneShotOneDistanceFromUser - random.randint(4,7)
            # Checks to see if player got a hole in one. If not, they play on
            if holeOneShotOneDistanceFromUser == 0:
                print ('\nHoly smokes! You got a hole in one!')
            elif holeOneShotOneDistanceFromUser == 1:
                print ('\nSo close! You are just ' + str(holeOneShotOneDistanceFromUser) + ' point away from the cup! Finish it off with "tap"')
            else:
                print ('\nYou are ' + str(holeOneShotOneDistanceFromUser) + ' points away from the cup!')

        # If player does not enter a valid shot option, they are prompted to do so
        elif shotOptionHoleOneShotOne != 'tap' or 'putt' or 'whack':
            shotOptionHoleOneShotOne = input ('\nPlease choose a valid shot option; such as "tap", "putt", or "whack", and enter it here: ')
            userInputHoleOneShotOne (shotOptionHoleOneShotOne)

# Asks player for shot selection 
# Inputs shot selection into shot one function
shotOptionHoleOneShotOne = input('\nSelect your shot option ("tap", "putt", or "whack"): ')
userInputHoleOneShotOne (shotOptionHoleOneShotOne)

# Checks if player got their ball in the cup. If not, they play on
if holeOneShotOneDistanceFromUser == 0:
    print ('\nCongratulations! You completed the first hole in ' + str(strokeCounterHoleOne) + ' stroke. On to the second hole!')
    input ('Press enter to continue. ')
else:
    holeOneShotTwoDistanceFromUser = holeOneShotOneDistanceFromUser

    def userInputHoleOneShotTwo (shotOptionHoleOneShotTwo):
        global strokeCounterHoleOne, holeOneShotTwoDistanceFromUser

        # Prompts the player to not use whack shot option if the ball is within 3 points of the cup
        if holeOneShotTwoDistanceFromUser <= 3:
            while shotOptionHoleOneShotTwo == "whack":
                print ('\nIt might be wiser to use a less powerful shot..: ')
                shotOptionHoleOneShotTwo = input('\nSelect your shot option ("tap", or "putt"): ')
        
        #As the ball will likely be closer for this shot, conditions are more defined for tap option
        if shotOptionHoleOneShotTwo == "tap":
            strokeCounterHoleOne = strokeCounterHoleOne + 1
            holeOneShotTwoDistanceFromUser = holeOneShotTwoDistanceFromUser - 1
            if holeOneShotTwoDistanceFromUser == 0:
                print ('\nGood Job! You got a birdie putt!')
            elif holeOneShotTwoDistanceFromUser == 1:
                print ('\nSo close! You are ' + str(holeOneShotTwoDistanceFromUser) + ' point away from the cup! Finish it off with "tap"')
            else:
                print ('\nYou are ' + str(holeOneShotTwoDistanceFromUser) + ' points away from the cup!')
        
        # Created more defined conditions for putt as well
        elif shotOptionHoleOneShotTwo == "putt":
            strokeCounterHoleOne = strokeCounterHoleOne + 1
            holeOneShotTwoDistanceFromUser = holeOneShotTwoDistanceFromUser - random.randint(2,3)
            if holeOneShotTwoDistanceFromUser == 0:
                print ('\nNice one! You got a birdie putt!')
            # Activates if player shot goes below zero; gives the player a positive integer distance from the cup
            elif holeOneShotTwoDistanceFromUser < 0:
                holeOneShotTwoDistanceFromUser = 1
                print ('\nJust missed the putt! You are ' + str(holeOneShotTwoDistanceFromUser) + ' point away from the cup! Finish it off with "tap"')
            else:
                print ('\nYou are ' + str(holeOneShotTwoDistanceFromUser) + ' points away from the cup!')
                
        # Player may use whack shot if farther than 3 points away from cup        
        elif shotOptionHoleOneShotTwo == "whack":
            strokeCounterHoleOne = strokeCounterHoleOne + 1
            holeOneShotTwoDistanceFromUser = holeOneShotTwoDistanceFromUser - random.randint(4,7)
            if holeOneShotTwoDistanceFromUser == 0:
                print ('\nNice one! You got a birdie!')
            # If player shoots past the cup, fate decider is activated
            elif holeOneShotTwoDistanceFromUser < 0:
                fateDecider = random.randint (1,2)
                if fateDecider == 1:
                    holeOneShotTwoDistanceFromUser = 1
                    print ('\nYou hit your ball off of the flagpole! You are ' + str(holeOneShotTwoDistanceFromUser) + ' point away from the cup! Finish it off with "tap"')
                else:
                    holeOneShotTwoDistanceFromUser = random.randint (1,2)
                    if holeOneShotTwoDistanceFromUser == 1:
                        print('\nOops! Your ball went past the cup! You are ' + str(holeOneShotTwoDistanceFromUser) + ' point away from the cup! Finish it off with "tap"')
                    else:
                        print ('\nOops! Your ball went past the cup! You are ' + str(holeOneShotTwoDistanceFromUser) + ' points away from the cup!')
            else:
                print ('\nYou are ' + str(holeOneShotTwoDistanceFromUser) + ' points away from the cup!')
        
        # If player does not enter a valid shot option, they are prompted to do so
        elif shotOptionHoleOneShotTwo != 'tap' or 'putt' or 'whack' :
            shotOptionHoleOneShotTwo = input ('\nPlease choose a valid shot option; such as "tap", "putt", or "whack", and enter it here: ')
            userInputHoleOneShotTwo (shotOptionHoleOneShotTwo)

    shotOptionHoleOneShotTwo = input('\nKeep going! Select your second shot ("tap", "putt", or "whack"): ')
    userInputHoleOneShotTwo (shotOptionHoleOneShotTwo)

    # checks player success after second shot
    if holeOneShotTwoDistanceFromUser == 0:
        print ('\nCongratulations! You completed the first hole in ' + str(strokeCounterHoleOne) + ' strokes. On to the second hole!')
        input ('Press enter to continue. ')
        
    # If second shot was not successful they receive a final shot warning and prepare for their final shot
    else:
        holeOneShotThreeDistanceFromUser = holeOneShotTwoDistanceFromUser
        print ('\nLAST SHOT!!!\n')
        
        def userInputHoleOneShotThree (shotOptionHoleOneShotThree):
            global strokeCounterHoleOne, holeOneShotThreeDistanceFromUser

            # Recommends to the player to not use whack if the ball is within 3 points of the cup
            if holeOneShotThreeDistanceFromUser <= 3:
                while shotOptionHoleOneShotThree == "whack":
                    print ('\nIt might be wiser to use a less powerful shot..')
                    shotOptionHoleOneShotThree = input('\nSelect your shot option ("tap", or "putt"): ')
                    
            #As the ball will likely be closer for this shot, conditions are more defined for tap option
            if shotOptionHoleOneShotThree == "tap":
                strokeCounterHoleOne = strokeCounterHoleOne + 1
                holeOneShotThreeDistanceFromUser = holeOneShotThreeDistanceFromUser - 1
                if holeOneShotThreeDistanceFromUser == 0:
                    print ('\nGood Job! You got a par!')
                elif holeOneShotThreeDistanceFromUser == 1:
                    print ('\nSo close! You are ' + str(holeOneShotThreeDistanceFromUser) + ' point away from the cup!')
                else:
                    print ( '\nYou are ' + str(holeOneShotThreeDistanceFromUser) + ' points away from the cup!')
            
            # Created more defined conditions for putt as well
            elif shotOptionHoleOneShotThree == "putt":
                strokeCounterHoleOne = strokeCounterHoleOne + 1
                holeOneShotThreeDistanceFromUser = holeOneShotThreeDistanceFromUser - random.randint(2,3)
                if holeOneShotThreeDistanceFromUser == 0:
                    print ('\nNice one! You got a par!')
                # Activates if player shot goes below zero; gives the player a positive integer distance from the cup
                elif holeOneShotThreeDistanceFromUser < 0:
                    holeOneShotThreeDistanceFromUser = 1
                    print ('\nJust missed the putt! You are ' + str(holeOneShotThreeDistanceFromUser) + ' point away from the cup!')
                else:
                    print ('\nYou are ' + str(holeOneShotThreeDistanceFromUser) + ' points away from the cup!')
                        
            # Player may use whack shot if farther than 3 points away from cup 
            elif shotOptionHoleOneShotThree == "whack":
                strokeCounterHoleOne = strokeCounterHoleOne + 1
                holeOneShotThreeDistanceFromUser = holeOneShotThreeDistanceFromUser - random.randint(4,7)
                if holeOneShotThreeDistanceFromUser == 0:
                    print ('\nNice one! You got your ball in the cup!')
                # Fate decider activates if player shot goes below zero; chooses a randomized instance that gives the player a positive integer distance from the cup
                elif holeOneShotThreeDistanceFromUser < 0:
                    fateDecider = random.randint (1,2)
                    if fateDecider == 1:
                        holeOneShotThreeDistanceFromUser = 1
                        print ('\nYou hit your ball off of the flagpole! You are ' + str(holeOneShotThreeDistanceFromUser) + ' point away from the cup! Finish it off with "tap"')
                    else:
                        holeOneShotThreeDistanceFromUser = random.randint (1,2)
                        if holeOneShotThreeDistanceFromUser == 1:
                            print('\nOops! Your ball went past the cup! You are ' + str(holeOneShotThreeDistanceFromUser) + ' point away from the cup! Finish it off with "tap"')
                        else:
                            print ('\nOops! Your ball went past the cup! You are ' + str(holeOneShotThreeDistanceFromUser) + ' points away from the cup!')
                else:
                    print ('\nYou are ' + str(holeOneShotThreeDistanceFromUser) + ' points away from the cup!')
            
            # If player does not enter a valid shot option, they are prompted to do so
            elif shotOptionHoleOneShotThree != 'tap' or 'putt' or 'whack':
                shotOptionHoleOneShotThree = input ('\nPlease choose a valid shot option; such as "tap", "putt", or "whack", and enter it here: ')
                userInputHoleOneShotThree (shotOptionHoleOneShotThree)

        # Prompts player for third and final shot
        shotOptionHoleOneShotThree = input('Select your final shot option ("tap", "putt", or "whack"): ')
        userInputHoleOneShotThree (shotOptionHoleOneShotThree)

        if holeOneShotThreeDistanceFromUser == 0:
            print ('\nCongratulations! You completed the first hole in ' + str(strokeCounterHoleOne) + ' strokes. On to the second hole!')
            input ('Press enter to continue. ')
        else:
            strokeCounterHoleOne = strokeCounterHoleOne + 1
            print ('\nShucks, close but no cigar. This hole will be completed for you, and a stroke will be added to your stroke total')
            print ('\nyou completed the first hole in ' + str(strokeCounterHoleOne) + ' strokes! On to the second hole!')
            input ('Press enter to continue. ')

# Introduction to the wallop shot
print ('\nYou have unlocked the wallop shot!!!')
print ('The wallop shot allows you to hit the ball even harder than a whack shot!')
print ('You will recall that a tap shot has a power of 1, a putt shot has a power of 2-3, and a whack shot has a power ranging from 4-7 points.')
print ('The wallop shot has a whopping shot power ranging from 8-11 points!')
print ('Go out there and give them a walloping!')
input ('Press enter to continue. ')

#Intro to second hole
print ('\nHey ' + (userName) + '! Welcome to the the second hole of Minigolf.' )
print ('\nNow that you are getting the hang of it, this cup will be more difficult to reach\n')
print ('You are 13 points away from the cup at the start.')
print ('\nKeep in mind that you will have four shot attempts to complete the second hole.')
print ('After that, an additional stroke will be added to your score, and the hole will be completed for you.')
input ('Press enter to continue. ')
print ('\nGood luck!\n')

holeTwoShotOneDistanceFromUser = 13
strokeCounterHoleTwo = 0

def userInputHoleTwoShotOne (shotOptionHoleTwoShotOne):
    global strokeCounterHoleTwo, holeTwoShotOneDistanceFromUser

    # tap option
    if shotOptionHoleTwoShotOne == "tap":
        strokeCounterHoleTwo = strokeCounterHoleTwo + 1
        holeTwoShotOneDistanceFromUser = holeTwoShotOneDistanceFromUser - 1
        print ( '\nYou are ' + str(holeTwoShotOneDistanceFromUser) + ' points away from the cup!')

    # putt option
    elif shotOptionHoleTwoShotOne == "putt":
        strokeCounterHoleTwo = strokeCounterHoleTwo + 1
        holeTwoShotOneDistanceFromUser = holeTwoShotOneDistanceFromUser - random.randint(2,3)
        print ('\nYou are ' + str(holeTwoShotOneDistanceFromUser) + ' points away from the cup!')

    # whack option
    elif shotOptionHoleTwoShotOne == "whack":
        strokeCounterHoleTwo = strokeCounterHoleTwo + 1
        holeTwoShotOneDistanceFromUser = holeTwoShotOneDistanceFromUser - random.randint(4,7)
        print ('\nYou are ' + str(holeTwoShotOneDistanceFromUser) + ' points away from the cup!')

    # Creates the wallop option
    elif shotOptionHoleTwoShotOne == "wallop":
        strokeCounterHoleTwo = strokeCounterHoleTwo + 1
        holeTwoShotOneDistanceFromUser = holeTwoShotOneDistanceFromUser - random.randint(8,11)
        if holeTwoShotOneDistanceFromUser <= 3:
            print ('\nNice shot! You are ' + str(holeTwoShotOneDistanceFromUser) + ' points away from the cup!')
        else:
            print ('\nYou are ' + str(holeTwoShotOneDistanceFromUser) + ' points away from the cup!')

    # If player does not enter a valid shot option, they are prompted to do so
    elif shotOptionHoleTwoShotOne != 'tap' or 'putt' or 'whack' or 'wallop':
        shotOptionHoleTwoShotOne = input ('\nPlease choose a valid shot option; such as "tap", "putt", "whack" or "wallop and enter it here: ')
        userInputHoleTwoShotOne (shotOptionHoleTwoShotOne)

# Asks player for first shot selection and inputs it into shot one function 
shotOptionHoleTwoShotOne = input('\nSelect your first shot ("tap", "putt", "whack", or THE NEW "wallop"): ')
userInputHoleTwoShotOne (shotOptionHoleTwoShotOne)

# Sets up second shot
holeTwoShotTwoDistanceFromUser = holeTwoShotOneDistanceFromUser

def userInputHoleTwoShotTwo (shotOptionHoleTwoShotTwo):
    global strokeCounterHoleTwo, holeTwoShotTwoDistanceFromUser
    
    # Recommends to the player to not choose wallop if the ball is within 7 points of the cup
    if holeTwoShotTwoDistanceFromUser <= 7:
        while shotOptionHoleTwoShotTwo == "wallop":
            print ('\nIt might be wiser to use a less powerful shot... \n')
            shotOptionHoleTwoShotTwo = input('Select your shot option ("tap", "putt", or "whack"): ')

    # Recommends to the player to not use whack if the ball is within 3 points of the cup
    if holeTwoShotTwoDistanceFromUser <= 3:
        while shotOptionHoleTwoShotTwo == "whack":
            print ('\nIt might be wiser to use a less powerful shot... \n')
            shotOptionHoleTwoShotTwo = input('Select your shot option ("tap", or "putt"): ')
        
    if shotOptionHoleTwoShotTwo == "tap":
        strokeCounterHoleTwo = strokeCounterHoleTwo + 1
        holeTwoShotTwoDistanceFromUser = holeTwoShotTwoDistanceFromUser - 1
        if holeTwoShotTwoDistanceFromUser == 0:
            print ('\nNice shot! You got your ball in the cup!')
        else:
            print ( '\nYou are ' + str(holeTwoShotTwoDistanceFromUser) + ' points away from the cup!')
    
    # Created more defined conditions for putt
    elif shotOptionHoleTwoShotTwo == "putt":
        strokeCounterHoleTwo = strokeCounterHoleTwo + 1
        holeTwoShotTwoDistanceFromUser = holeTwoShotTwoDistanceFromUser - random.randint(2,3)
        if holeTwoShotTwoDistanceFromUser == 0:
            print ('\nNice one! You got your ball in the cup!')
        # Activates if player shot goes below zero; gives the player a positive integer distance from the cup
        elif holeTwoShotTwoDistanceFromUser < 0:
            holeTwoShotTwoDistanceFromUser = 1
            print ('\nJust missed the putt! You are ' + str(holeTwoShotTwoDistanceFromUser) + ' point away from the cup! Finish it off with "tap"')
        else:
            print ('\nYou are ' + str(holeTwoShotTwoDistanceFromUser) + ' points away from the cup!')

    # Player can use whack if more than 7 points away from the cup
    elif shotOptionHoleTwoShotTwo == "whack":
        strokeCounterHoleTwo = strokeCounterHoleTwo + 1
        holeTwoShotTwoDistanceFromUser = holeTwoShotTwoDistanceFromUser - random.randint(4,7)
        if holeTwoShotTwoDistanceFromUser == 0:
            print ('\nNice one! You got a birdie!')
        # Fate decider activates if player shot goes below zero; chooses a randomized instance that gives the player a positive integer distance from the cup
        elif holeTwoShotTwoDistanceFromUser < 0:
            fateDecider = random.randint (1,2)
            if fateDecider == 1:
                holeTwoShotTwoDistanceFromUser = 1
                print ('\nYou hit your ball off of the flagpole! You are ' + str(holeTwoShotTwoDistanceFromUser) + ' point away from the cup! Finish it off with "tap"')
            else:
                holeTwoShotTwoDistanceFromUser = random.randint (1,2)
                if holeTwoShotTwoDistanceFromUser == 1:
                    print('\nOops! Your ball went past the cup! You are ' + str(holeTwoShotTwoDistanceFromUser) + ' point away from the cup! Finish it off with "tap"')
                else:
                    print ('\nOops! Your ball went past the cup! You are ' + str(holeTwoShotTwoDistanceFromUser) + ' points away from the cup!')
        else:
            print ('\nYou are ' + str(holeTwoShotTwoDistanceFromUser) + ' points away from the cup!')

    # Player can use wallop if more than 7 points away from the cup
    elif shotOptionHoleTwoShotTwo == "wallop":
        strokeCounterHoleTwo = strokeCounterHoleTwo + 1
        holeTwoShotTwoDistanceFromUser = holeTwoShotTwoDistanceFromUser - random.randint(8,11)
        if holeTwoShotTwoDistanceFromUser <= 3 and holeTwoShotTwoDistanceFromUser > 0:
            print ('\nNice shot! You are ' + str(holeTwoShotTwoDistanceFromUser) + ' points away from the cup!')
        elif holeTwoShotTwoDistanceFromUser == 0:
            print ('\nWhat a shot! You got your ball in the cup!')
        # Fate decider activates if player shot goes below zero; chooses a randomized instance that gives the player a positive integer distance from the cup
        elif holeTwoShotTwoDistanceFromUser < 0:
            fateDecider = random.randint (1,2)
            if fateDecider == 1:
                holeTwoShotTwoDistanceFromUser = 1
                print ('\nYou hit your ball off of the flagpole! You are ' + str(holeTwoShotTwoDistanceFromUser) + ' point away from the cup! Finish it off with "tap"')
            else:
                holeTwoShotTwoDistanceFromUser = random.randint (1,2)
                if holeTwoShotTwoDistanceFromUser == 1:
                    print('\nOops! Your ball went past the cup! You are ' + str(holeTwoShotTwoDistanceFromUser) + ' point away from the cup! Finish it off with "tap"')
                else:
                    print ('\nOops! Your ball went past the cup! You are ' + str(holeTwoShotTwoDistanceFromUser) + ' points away from the cup!')
    # If user enters invalid shot option, they are prompted to enter a valid one
    elif shotOptionHoleTwoShotTwo != 'tap' or 'putt' or 'whack' or 'wallop':
        shotOptionHoleTwoShotTwo = input ('\nPlease choose a valid shot option; such as "tap", "putt", "whack" or "wallop and enter it here: ')
        userInputHoleTwoShotTwo (shotOptionHoleTwoShotTwo)
        
shotOptionHoleTwoShotTwo = input('\nKeep going! Select your second shot ("tap", "putt", "whack", or "wallop"): ')
userInputHoleTwoShotTwo (shotOptionHoleTwoShotTwo)

# Checks player progress on the hole
# If the hole is complete, they receive a congrats message. If not, they take their third shot
if holeTwoShotTwoDistanceFromUser == 0:
    print ('\nCongratulations! You completed the second hole in ' + str(strokeCounterHoleTwo) + ' strokes. On to the third hole!')
    input ('Press enter to continue')
else:
    holeTwoShotThreeDistanceFromUser = holeTwoShotTwoDistanceFromUser
    # function for third shot of hole three
    def userInputHoleTwoShotThree (shotOptionHoleTwoShotThree):
        global strokeCounterHoleTwo, holeTwoShotThreeDistanceFromUser

        # Recommends to the player to not choose wallop if the ball is within 7 points of the cup
        if holeTwoShotThreeDistanceFromUser <= 7:
            while shotOptionHoleTwoShotThree == "wallop":
                print ('\nIt might be wiser to use a less powerful shot... \n')
                shotOptionHoleTwoShotThree = input('Select your shot option ("tap", "putt", or "whack"): ')
                userInputHoleTwoShotThree (shotOptionHoleTwoShotThree)
        
        # Recommends to the player to not use whack if the ball is within 3 points of the cup
        if holeTwoShotThreeDistanceFromUser <= 3:
            while shotOptionHoleTwoShotThree == "whack":
                print ('\nIt might be wiser to use a less powerful shot... \n')
                shotOptionHoleTwoShotThree = input('Select your shot option ("tap", or "putt",): ')
                userInputHoleTwoShotThree (shotOptionHoleTwoShotThree)
        
        # Conditions are more defined shot tap on shot three
        if shotOptionHoleTwoShotThree == "tap":
            strokeCounterHoleTwo = strokeCounterHoleTwo + 1
            holeTwoShotThreeDistanceFromUser = holeTwoShotThreeDistanceFromUser - 1
            if holeTwoShotThreeDistanceFromUser == 0:
                print ('\nNice one! You got a par!')
            elif holeTwoShotThreeDistanceFromUser == 1:
                print ( '\nYou are ' + str(holeTwoShotThreeDistanceFromUser) + ' point away from the cup!')
            else:
                print ( '\nYou are ' + str(holeTwoShotThreeDistanceFromUser) + ' points away from the cup!')
        
        # Created more defined conditions for putt
        elif shotOptionHoleTwoShotThree == "putt":
            strokeCounterHoleTwo = strokeCounterHoleTwo + 1
            holeTwoShotThreeDistanceFromUser = holeTwoShotThreeDistanceFromUser - random.randint(2,3)
            if holeTwoShotThreeDistanceFromUser == 0:
                print ('\nNice one! You got a par!')
            # Activates if player shot goes below zero; gives the player a positive integer distance from the cup
            elif holeTwoShotThreeDistanceFromUser < 0:
                holeTwoShotThreeDistanceFromUser = 1
                print ('\nJust missed the putt! You are ' + str(holeTwoShotThreeDistanceFromUser) + ' point away from the cup! Finish it off with "tap"')
            else:
                print ('\nYou are ' + str(holeTwoShotThreeDistanceFromUser) + ' points away from the cup!')
                                
        # Allows use of whack if ball is farther than 3 points away from cup
        elif shotOptionHoleTwoShotThree == "whack":
            strokeCounterHoleTwo = strokeCounterHoleTwo + 1
            holeTwoShotThreeDistanceFromUser = holeTwoShotThreeDistanceFromUser - random.randint(4,7)
            if holeTwoShotThreeDistanceFromUser == 0:
                print ('\nNice one! You got your ball in the cup!')
            # Fate decider activates if player shot goes below zero; chooses a randomized instance that gives the player a positive integer distance from the cup
            elif holeTwoShotThreeDistanceFromUser < 0:
                fateDecider = random.randint (1,2)
                if fateDecider == 1:
                    holeTwoShotThreeDistanceFromUser = 1
                    print ('\nYou hit your ball off of the flagpole! You are ' + str(holeTwoShotThreeDistanceFromUser) + ' point away from the cup! Finish it off with "tap"')
                else:
                    holeTwoShotThreeDistanceFromUser = random.randint (1,2)
                    if holeTwoShotThreeDistanceFromUser == 1:
                        print('\nOops! Your ball went past the cup! You are ' + str(holeTwoShotThreeDistanceFromUser) + ' point away from the cup! Finish it off with "tap"')
                    else:
                        print ('\nOops! Your ball went past the cup! You are ' + str(holeTwoShotThreeDistanceFromUser) + ' points away from the cup!')
            else:
                print ('\nYou are ' + str(holeTwoShotThreeDistanceFromUser) + ' points away from the cup!')
                    
        # Player may use wallop shot if farther than 7 points away from cup
        elif shotOptionHoleTwoShotThree == "wallop":
            strokeCounterHoleTwo = strokeCounterHoleTwo + 1
            holeTwoShotThreeDistanceFromUser = holeTwoShotThreeDistanceFromUser - random.randint(8,11)
            if holeTwoShotThreeDistanceFromUser <= 3 and holeTwoShotThreeDistanceFromUser > 0:
                print ('\nNice shot! You are ' + str(holeTwoShotThreeDistanceFromUser) + ' points away from the cup!')
            elif holeTwoShotThreeDistanceFromUser == 0:
                print ('\nWhat a shot! You got your ball in the cup!')
            
            # If player shoots past the cup, fate decider is activated
            elif holeTwoShotThreeDistanceFromUser < 0:
                fateDecider = random.randint (1,2)
                if fateDecider == 1:
                    holeTwoShotThreeDistanceFromUser = 1
                    print ('\nYou hit your ball off of the flagpole! You are ' + str(holeTwoShotThreeDistanceFromUser) + ' point away from the cup! Finish it off with "tap"')
                else:
                    holeTwoShotThreeDistanceFromUser = random.randint (1,2)
                    if holeTwoShotThreeDistanceFromUser == 1:
                        print('\nOops! Your ball went past the cup! You are ' + str(holeTwoShotThreeDistanceFromUser) + ' point away from the cup! Finish it off with "tap"')
                    else:
                        print ('\nOops! Your ball went past the cup! You are ' + str(holeTwoShotThreeDistanceFromUser) + ' points away from the cup!')
            else:
                print ('\nYou are ' + str(holeTwoShotThreeDistanceFromUser) + ' points away from the cup!')
            
        # Prompts player for valid input if they type an invalid shot command
        elif shotOptionHoleTwoShotThree != "tap" or 'putt' or 'whack' or 'wallop':
            shotOptionHoleTwoShotThree = input ('\nPlease choose a valid shot option; such as "tap", "putt", "whack" or "wallop and enter it here: ')
            userInputHoleTwoShotThree (shotOptionHoleTwoShotThree)

    shotOptionHoleTwoShotThree = input('\nKeep going! Select your third shot ("tap", "putt", "whack", or "wallop"): ')
    userInputHoleTwoShotThree (shotOptionHoleTwoShotThree)

    # Checks player progress on the hole
    # If the hole is complete, they receive a congrats message. If not, they take their fourth and final shot
    if holeTwoShotThreeDistanceFromUser == 0:
        print ('\nCongratulations! You completed the second hole in ' + str(strokeCounterHoleTwo) + ' strokes. On to the third hole!')
        input ('Press enter to continue. ')
    else:
        print ('\nFINAL SHOT!!!\n')

        # Setup for fourth shot
        holeTwoShotFourDistanceFromUser = holeTwoShotThreeDistanceFromUser

        def userInputHoleTwoShotFour (shotOptionHoleTwoShotFour):
            global strokeCounterHoleTwo, holeTwoShotFourDistanceFromUser

            # Recommends to the player to not choose wallop if the ball is within 7 points of the cup
            if holeTwoShotFourDistanceFromUser <= 7:
                while shotOptionHoleTwoShotFour == "wallop":
                    print ('\nIt might be wiser to use a less powerful shot... \n')
                    shotOptionHoleTwoShotFour = input('Select your shot option ("tap", "putt", or "whack"): ')
                               
            # Recommends to the player to not use whack if the ball is within 3 points of the cup
            if holeTwoShotFourDistanceFromUser <= 3:
                while shotOptionHoleTwoShotFour == "whack":
                    print ('\nIt might be wiser to use a less powerful shot... \n')
                    shotOptionHoleTwoShotFour = input('Select your shot option ("tap", or "putt",): ')
            
            # Conditions are more defined shot tap on shot three
            if shotOptionHoleTwoShotFour == "tap":
                strokeCounterHoleTwo = strokeCounterHoleTwo + 1
                holeTwoShotFourDistanceFromUser = holeTwoShotFourDistanceFromUser - 1
                if holeTwoShotFourDistanceFromUser == 0:
                    print ('\nNice one! You got your ball in the cup!!')
                elif holeTwoShotFourDistanceFromUser == 1:
                    print ( '\nYou are ' + str(holeTwoShotFourDistanceFromUser) + ' point away from the cup!')
                else:
                    print ( '\nYou are ' + str(holeTwoShotFourDistanceFromUser) + ' points away from the cup!')
            
            # Created more defined conditions for putt
            elif shotOptionHoleTwoShotFour == "putt":
                strokeCounterHoleTwo = strokeCounterHoleTwo + 1
                holeTwoShotFourDistanceFromUser = holeTwoShotFourDistanceFromUser - random.randint(2,3)
                if holeTwoShotFourDistanceFromUser == 0:
                    print ('\nNice one! You got your ball in the cup!!')
                # Activates if player shot goes below zero; gives the player a positive integer distance from the cup
                elif holeTwoShotFourDistanceFromUser < 0:
                    holeTwoShotFourDistanceFromUser = 1
                    print ('\nJust missed the putt! You are ' + str(holeTwoShotFourDistanceFromUser) + ' point away from the cup!')
                else:
                    print ('\nYou are ' + str(holeTwoShotFourDistanceFromUser) + ' points away from the cup!')
                                           
            # Allows use of whack if ball is not within 3 points of the cup
            elif shotOptionHoleTwoShotFour == "whack":
                strokeCounterHoleTwo = strokeCounterHoleTwo + 1
                holeTwoShotFourDistanceFromUser = holeTwoShotFourDistanceFromUser - random.randint(4,7)
                if holeTwoShotFourDistanceFromUser == 0:
                    print ('\nNice one! You got your ball in the cup!')
                # Fate decider activates if player shot goes below zero; chooses a randomized instance that gives the player a positive integer distance from the cup
                elif holeTwoShotFourDistanceFromUser < 0:
                    fateDecider = random.randint (1,2)
                    if fateDecider == 1:
                        holeTwoShotFourDistanceFromUser = 1
                        print ('\nYou hit your ball off of the flagpole! You are ' + str(holeTwoShotFourDistanceFromUser) + ' point away from the cup!')
                    else:
                        holeTwoShotFourDistanceFromUser = random.randint (1,2)
                        if holeTwoShotFourDistanceFromUser == 1:
                            print('\nOops! Your ball went past the cup! You are ' + str(holeTwoShotFourDistanceFromUser) + ' point away from the cup!')
                        else:
                            print ('\nOops! Your ball went past the cup! You are ' + str(holeTwoShotFourDistanceFromUser) + ' points away from the cup!')
                else:
                    print ('\nYou are ' + str(holeTwoShotFourDistanceFromUser) + ' points away from the cup!')                  

            # Allows use of wallop if ball is not within 7 points of the cup
            elif shotOptionHoleTwoShotFour == "wallop":
                strokeCounterHoleTwo = strokeCounterHoleTwo + 1
                holeTwoShotFourDistanceFromUser = holeTwoShotFourDistanceFromUser - random.randint(8,11)
                if holeTwoShotFourDistanceFromUser <= 3 and holeTwoShotFourDistanceFromUser > 0:
                    print ('\nNice shot! You are ' + str(holeTwoShotFourDistanceFromUser) + ' points away from the cup!')
                elif holeTwoShotFourDistanceFromUser == 0:
                    print ('\nWhat a shot! You got your ball in the cup!')
                # Fate decider activates if player shot goes below zero; chooses a randomized instance that gives the player a positive integer distance from the cup
                elif holeTwoShotFourDistanceFromUser < 0:
                    fateDecider = random.randint (1,2)
                    if fateDecider == 1:
                        holeTwoShotFourDistanceFromUser = 1
                        print ('\nYou hit your ball off of the flagpole! You are ' + str(holeTwoShotFourDistanceFromUser) + ' point away from the cup! Finish it off with "tap"')
                    else:
                        holeTwoShotFourDistanceFromUser = random.randint (1,2)
                        if holeTwoShotFourDistanceFromUser == 1:
                            print('\nOops! Your ball went past the cup! You are ' + str(holeTwoShotFourDistanceFromUser) + ' point away from the cup! Finish it off with "tap"')
                        else:
                            print ('\nOops! Your ball went past the cup! You are ' + str(holeTwoShotFourDistanceFromUser) + ' points away from the cup!')
                
            # Prompts player for valid input if they type an invalid shot command
            elif shotOptionHoleTwoShotFour != "tap" or 'putt' or 'whack' or 'wallop':
                shotOptionHoleTwoShotFour = input ('\nPlease choose a valid shot option; such as "tap", "putt", "whack" or "wallop and enter it here: ')
                userInputHoleTwoShotFour (shotOptionHoleTwoShotFour)
        
        # Prompts player for fourth and final shot selection, then enters choice into function ^
        shotOptionHoleTwoShotFour = input('Last Chance! Select your fourth and final shot ("tap", "putt", "whack", or "wallop"): ')
        userInputHoleTwoShotFour (shotOptionHoleTwoShotFour)

        # Checks player success on fourth shot. If they got the ball in the cup, they're congratulated
        if holeTwoShotFourDistanceFromUser == 0:
                print ('\nCongratulations! You completed the second hole in ' + str(strokeCounterHoleTwo) + ' strokes. On to the third and final hole!')
                input ('Press enter to continue')
        else:
            strokeCounterHoleTwo = strokeCounterHoleTwo + 1
            print ('\nShucks, close but no cigar. This hole will be completed for you, and a stroke will be added to your stroke total')
            print ('\nyou completed the second hole in ' + str(strokeCounterHoleTwo) + ' strokes! On to the second hole!')
            input ('Press enter to continue. ')

#Third and final hole
print ('\nHey ' + (userName) +  """! Welcome to the third and final hole of Minigolf!\n
Get ready for your final challenge. As mentioned at the beginning of the game,
there will be a surprise within this challenge. Be wary as you approach the cup..\n
You are 21 points away from the cup at the start.\n
You will have five shot attempts to complete this hole.
After that, an additional stroke will be added to your score, and the hole will be completed for you.""")
input ('Press enter to continue. ')
print ("""\nGood luck!\n""")

# Sets up distance, stroke counter variable and function for third hole
holeThreeShotOneDistanceFromUser = 21
strokeCounterHoleThree = 0
def userInputHoleThreeShotOne (shotOptionHoleThreeShotOne):
    global strokeCounterHoleThree, holeThreeShotOneDistanceFromUser

    # tap option
    if shotOptionHoleThreeShotOne == "tap":
        strokeCounterHoleThree = strokeCounterHoleThree + 1
        holeThreeShotOneDistanceFromUser = holeThreeShotOneDistanceFromUser - 1
        print ( '\nYou are ' + str(holeThreeShotOneDistanceFromUser) + ' points away from the cup!')

    # putt option
    elif shotOptionHoleThreeShotOne == "putt":
        strokeCounterHoleThree = strokeCounterHoleThree + 1
        holeThreeShotOneDistanceFromUser = holeThreeShotOneDistanceFromUser - random.randint(2,3)
        print ('\nYou are ' + str(holeThreeShotOneDistanceFromUser) + ' points away from the cup!')

    # whack option
    elif shotOptionHoleThreeShotOne == "whack":
        strokeCounterHoleThree = strokeCounterHoleThree + 1
        holeThreeShotOneDistanceFromUser = holeThreeShotOneDistanceFromUser - random.randint(4,7)
        print ('\nYou are ' + str(holeThreeShotOneDistanceFromUser) + ' points away from the cup!')

    # wallop option
    elif shotOptionHoleThreeShotOne == "wallop":
        strokeCounterHoleThree = strokeCounterHoleThree + 1
        holeThreeShotOneDistanceFromUser = holeThreeShotOneDistanceFromUser - random.randint(8,11)
        print ('\nYou are ' + str(holeThreeShotOneDistanceFromUser) + ' points away from the cup!\n')
    
    # Prompts player for valid input if they type an invalid shot command
    elif shotOptionHoleThreeShotOne != "tap" or 'putt' or 'whack' or 'wallop':
        shotOptionHoleThreeShotOne = input ('\nPlease choose a valid shot option; such as "tap", "putt", "whack" or "wallop and enter it here: ')
        userInputHoleThreeShotOne (shotOptionHoleThreeShotOne)

# Asks player for shot selection and inputs shot selection into shot one function
shotOptionHoleThreeShotOne = input('Select your first shot ("tap", "putt", "whack", or "wallop"): ')
userInputHoleThreeShotOne (shotOptionHoleThreeShotOne)

# Ominous message before second shot attempt
if holeThreeShotOneDistanceFromUser <= 13:
    print ("""You notice something that looks like a tower looming in front of the cup.
The tower appears to have some moving parts to it, but you can't quite tell what it is...""")
    input ('Press enter to continue. \n')

# Setup for second shot attempt
holeThreeShotTwoDistanceFromUser = holeThreeShotOneDistanceFromUser
def userInputHoleThreeShotTwo (shotOptionHoleThreeShotTwo):
    global strokeCounterHoleThree, holeThreeShotTwoDistanceFromUser
        
    # tap option
    if shotOptionHoleThreeShotTwo == "tap":
        strokeCounterHoleThree = strokeCounterHoleThree + 1
        holeThreeShotTwoDistanceFromUser = holeThreeShotTwoDistanceFromUser - 1
        print ( '\nYou are ' + str(holeThreeShotTwoDistanceFromUser) + ' points away from the cup!')
    
    # putt option
    elif shotOptionHoleThreeShotTwo == "putt":
        strokeCounterHoleThree = strokeCounterHoleThree + 1
        holeThreeShotTwoDistanceFromUser = holeThreeShotTwoDistanceFromUser - random.randint(2,3)
        print ('\nYou are ' + str(holeThreeShotTwoDistanceFromUser) + ' points away from the cup!')
        
    # Whack option
    elif shotOptionHoleThreeShotTwo == "whack":
        strokeCounterHoleThree = strokeCounterHoleThree + 1
        holeThreeShotTwoDistanceFromUser = holeThreeShotTwoDistanceFromUser - random.randint(4,7)
        print ('\nYou are ' + str(holeThreeShotTwoDistanceFromUser) + ' points away from the cup!')

    # Warning message if player is within striking distance of the windmill. 
    # Asks player with "yes" or "no" if they want to proceed with chosen shot   
    elif shotOptionHoleThreeShotTwo == "wallop":
            print ("""\nThat tower is still out on the green. It might be wise to approach with caution.\nAre you sure you want to use the wallop option?\n""")
            wallopConfirmation = input ('Type "yes" if you would like to proceed, or "no" to choose another shot option: ')
            if wallopConfirmation == "yes":
                strokeCounterHoleThree = strokeCounterHoleThree + 1
                holeThreeShotTwoDistanceFromUser = holeThreeShotTwoDistanceFromUser - random.randint(8,11)
                if holeThreeShotTwoDistanceFromUser >= 4:
                    print ('\nNice shot! You are ' + str(holeThreeShotTwoDistanceFromUser) + ' points away from the cup!')
                
                # Creation of windmill fate decider. Determines if user will successfully make it through the windmill or not
                # Only activates if player is within 3 points of the cup
                elif holeThreeShotTwoDistanceFromUser <= 3:
                    windMillFateDecider = random.randint (1,4)
                    if windMillFateDecider == 1:
                        if holeThreeShotTwoDistanceFromUser == 0:
                            print ('Goodness gracious! You made a birdie! What an amazing shot!!!')
                        # Fate decider in case player hits the ball past the cup
                        elif holeThreeShotTwoDistanceFromUser < 0:
                            fateDecider = random.randint (1,2)
                            if fateDecider == 1:
                                holeThreeShotTwoDistanceFromUser = 1
                                print ('\nYou hit your ball off of the flagpole! You are ' + str(holeThreeShotTwoDistanceFromUser) + ' point away from the cup! Finish it off with "tap"')
                            else:
                                holeThreeShotTwoDistanceFromUser = random.randint (1,2)
                                if holeThreeShotTwoDistanceFromUser == 1:
                                    print('\nOops! Your ball went past the cup! You are ' + str(holeThreeShotTwoDistanceFromUser) + ' point away from the cup! Finish it off with "tap"')
                                else:
                                    print ('\nOops! Your ball went past the cup! You are ' + str(holeThreeShotTwoDistanceFromUser) + ' points away from the cup!')
                            print ('\nWhoa! That tower in the distance was a windmill, and you made it past! Well done! You are ' + str(holeThreeShotTwoDistanceFromUser) + ' point away from the cup! Finish it off with "tap"')
                        elif holeThreeShotTwoDistanceFromUser == 1:
                            print ('\nWhoa! That tower in the distance was a windmill, and you made it past! Well done! You are ' + str(holeThreeShotTwoDistanceFromUser) + ' point away from the cup! Finish it off with "tap"')
                        else:
                            print ('\nWhoa! That tower in the distance was a windmill, and you made it past! Well done! You are ' + str(holeThreeShotTwoDistanceFromUser) + ' points away from the cup!')
                    else:
                        holeThreeShotTwoDistanceFromUser = random.randint (4, 7)
                        print ("""\nAs you approach the tower, you realize it is a windmill and the moving parts were the arms for the fan.\nYou see your ball not far away. It must have bounced off part of the tower.""")
                        print ('\nYou judge the distance of your ball. You are ' + str(holeThreeShotTwoDistanceFromUser) + ' points away from the cup.')
            elif wallopConfirmation == "no":
                shotOptionHoleThreeShotTwoReshot = input('\nPlease choose a shot option to restart the shot ("tap", "putt", "whack" or "wallop"): ')
                shotOptionHoleThreeShotTwo = shotOptionHoleThreeShotTwoReshot
                userInputHoleThreeShotTwo (shotOptionHoleThreeShotTwo)
            # Player must retake shot if invalid option is given
            elif wallopConfirmation != 'yes' or 'no':
                print ('\nYour choice was not a valid choice. You need to type "yes" or "no"')
                shotOptionHoleThreeShotTwo = input('\nPlease choose a shot option to restart the shot ("tap", "putt", "whack" or "wallop"): ')
                userInputHoleThreeShotTwo (shotOptionHoleThreeShotTwo)
    
    # Prompts player for valid input if they type an invalid shot command
    elif shotOptionHoleThreeShotTwo != "tap" or 'putt' or 'whack' or 'wallop':
        shotOptionHoleThreeShotTwo = input ('\nPlease choose a valid shot option; such as "tap", "putt", "whack" or "wallop and enter it here: ')
        userInputHoleThreeShotTwo (shotOptionHoleThreeShotTwo)

# Prompts second shot and enters shot option into shot two function above
shotOptionHoleThreeShotTwo = input('Keep going! Select your second shot ("tap", "putt", "whack", or "wallop"): ')
userInputHoleThreeShotTwo (shotOptionHoleThreeShotTwo)

# Checks progress on hole after second shot
if holeThreeShotTwoDistanceFromUser == 0:
    print ('\nCongratulations! You completed the third hole in ' + str(strokeCounterHoleThree) + ' strokes!')
    input ('Press enter to continue')
else:
    holeThreeShotThreeDistanceFromUser = holeThreeShotTwoDistanceFromUser

    # Function for third shot
    def userInputHoleThreeShotThree (shotOptionHoleThreeShotThree):
        global strokeCounterHoleThree, holeThreeShotThreeDistanceFromUser

        # Recommends to the player to not choose wallop if the ball is within 7 points of the cup
        if holeThreeShotThreeDistanceFromUser <= 7:
            while shotOptionHoleThreeShotThree == "wallop":
                print ('\nIt might be wiser to use a less powerful shot... \n')
                shotOptionHoleThreeShotThree = input('Select your shot option ("tap", "putt", or "whack"): ')
        
        # Recommends to the player to not use whack if the ball is within 3 points of the cup
        if holeThreeShotThreeDistanceFromUser <= 3:
            while shotOptionHoleThreeShotThree == "whack":
                print ('\nIt might be wiser to use a less powerful shot... \n')
                shotOptionHoleThreeShotThree = input('Select your shot option ("tap", or "putt",): ')

        # Conditions are more defined for tap on shot three
        if shotOptionHoleThreeShotThree == "tap":
            strokeCounterHoleThree = strokeCounterHoleThree + 1
            holeThreeShotThreeDistanceFromUser = holeThreeShotThreeDistanceFromUser - 1
            if holeThreeShotThreeDistanceFromUser == 0:
                print ('\nNice one! You got a par!')
            elif holeThreeShotThreeDistanceFromUser == 1:
                print ( '\nYou are ' + str(holeThreeShotThreeDistanceFromUser) + ' point away from the cup!')
            else:
                print ( '\nYou are ' + str(holeThreeShotThreeDistanceFromUser) + ' points away from the cup!')
        
        # Created more defined conditions for putt
        elif shotOptionHoleThreeShotThree == "putt":
            strokeCounterHoleThree = strokeCounterHoleThree + 1
            holeThreeShotThreeDistanceFromUser = holeThreeShotThreeDistanceFromUser - random.randint(2,3)
            if holeThreeShotThreeDistanceFromUser == 0:
                print ('\nNice one! You got a par!')
            # Activates if player shot goes below zero; gives the player a positive integer distance from the cup
            elif holeThreeShotThreeDistanceFromUser < 0:
                holeThreeShotThreeDistanceFromUser = 1
                print ('\nJust missed the putt! You are ' + str(holeThreeShotThreeDistanceFromUser) + ' point away from the cup! Finish it off with "tap"')
            else:
                print ('\nYou are ' + str(holeThreeShotThreeDistanceFromUser) + ' points away from the cup!')
                          
        # Allows use of whack if ball is not within 3 points of the cup
        elif shotOptionHoleThreeShotThree == "whack":
            if holeThreeShotThreeDistanceFromUser <= 10:
                if shotOptionHoleThreeShotThree == "whack":
                    print ("""\nA windmill has come into view, It might be wise to approach with caution.\nAre you sure you want to use the whack option?""")
                    whackConfirmation = input ('Type "yes" if you would like to proceed, or "no" to choose another shot option: ')
                    if whackConfirmation == "yes":
                        strokeCounterHoleThree = strokeCounterHoleThree + 1
                        holeThreeShotThreeDistanceFromUser = holeThreeShotThreeDistanceFromUser - random.randint(4,7)
                        if holeThreeShotThreeDistanceFromUser >= 4:
                            print ('\nNice shot! You are ' + str(holeThreeShotThreeDistanceFromUser) + ' points away from the cup!')
                        # Creation of windmill fate decider; Determines if user will successfully make it through the windmill or not
                        # Only activates if player is within within 3 points of the cup
                        elif holeThreeShotThreeDistanceFromUser <= 3:
                            # 'windmill fate decider' easier to succeed for whack option compared to wallop option
                            windMillFateDecider = random.randint (1,2)
                            if windMillFateDecider == 1:
                                if holeThreeShotThreeDistanceFromUser == 0:
                                    print ('\nWhat a shot! You got a par!')
                                # Fate decider activates if player shot goes below zero; chooses a randomized instance that gives the player a positive integer distance from the cup
                                elif holeThreeShotThreeDistanceFromUser < 0:
                                    fateDecider = random.randint (1,2)
                                    if fateDecider == 1:
                                        holeThreeShotThreeDistanceFromUser = 1
                                        print ('\nYou hit your ball off of the flagpole! You are ' + str(holeThreeShotThreeDistanceFromUser) + ' point away from the cup! Finish it off with "tap"')
                                    else:
                                        holeThreeShotThreeDistanceFromUser = random.randint (1,2)
                                        if holeThreeShotThreeDistanceFromUser == 1:
                                            print('\nOops! Your ball went past the cup! You are ' + str(holeThreeShotThreeDistanceFromUser) + ' point away from the cup! Finish it off with "tap"')
                                        else:
                                            print ('\nOops! Your ball went past the cup! You are ' + str(holeThreeShotThreeDistanceFromUser) + ' points away from the cup!')
                                elif holeThreeShotThreeDistanceFromUser == 1:
                                    print ('\nNice shot! you made it past the windmill. Well done! You are ' + str(holeThreeShotThreeDistanceFromUser) + ' point away from the cup! Finish it off with "tap"')
                                # Elif statements directly above and below announce that you successfully passed the windmill
                                elif holeThreeShotThreeDistanceFromUser > 1 and holeThreeShotThreeDistanceFromUser <= 3:
                                    print ('Well done! You made it past the windmill blades. You are ' + str(holeThreeShotThreeDistanceFromUser) + ' points away from the cup!')
                                elif holeThreeShotThreeDistanceFromUser < 0:
                                    fateDecider = random.randint (1,2)
                                    if fateDecider == 1:
                                        holeThreeShotThreeDistanceFromUser = 1
                                        print ('Well done! You made it past the windmill! It looks like you hit your ball off of the flagpole!\n You are ' + str(holeThreeShotThreeDistanceFromUser) + ' point away from the cup!')
                                    else:
                                        holeThreeShotThreeDistanceFromUser = 2
                                        print ('Oops! Your ball went past the cup! You are ' + str(holeThreeShotThreeDistanceFromUser) + ' points away from the cup!')
                            else:
                                holeThreeShotThreeDistanceFromUser = random.randint (4, 5)
                                print ("""\nIt looks like your ball hit part of the windmill.\nYou see your ball not far away. It must have bounced off part of the tower.\n""")
                                print ('\nYou judge the distance of your ball. You are ' + str(holeThreeShotThreeDistanceFromUser) + ' points away from the cup.')
                    elif whackConfirmation == "no":
                        shotOptionHoleThreeShotThreeReshot = input('\nSelect your third shot ("tap", or "putt"): ')
                        shotOptionHoleThreeShotThree = shotOptionHoleThreeShotThreeReshot
                        userInputHoleThreeShotThree (shotOptionHoleThreeShotThree)
                    # Player must reshoot if invalid choice is entered
                    elif whackConfirmation != 'yes' or 'no':
                        print ('\nYour choice was not a valid choice. You need to type "yes" or "no"')
                        shotOptionHoleThreeShotThree = input('\nPlease choose a shot option to restart the shot ("tap", "putt", "whack" or "wallop"): ')
                        userInputHoleThreeShotThree (shotOptionHoleThreeShotThree)
            # Allows for normal whack function if far enough away from windmill
            else:
                strokeCounterHoleThree = strokeCounterHoleThree + 1
                holeThreeShotThreeDistanceFromUser = holeThreeShotThreeDistanceFromUser - random.randint(4,7)
                print ('\nYou are ' + str(holeThreeShotThreeDistanceFromUser) + ' points away from the cup!')
        # allows use of wallop if not within 7 points of the cup
        elif shotOptionHoleThreeShotThree == "wallop":
            if holeThreeShotThreeDistanceFromUser >= 8:
                if shotOptionHoleThreeShotThree == "wallop":
                    print ("""\nA windmill has come into view. It might be wise to approach with caution.\nAre you sure you want to use the wallop option?""")
                    wallopConfirmation = input ('Type "yes" if you would like to proceed, or "no" to choose another shot option: ')
                    if wallopConfirmation == "yes":
                        strokeCounterHoleThree = strokeCounterHoleThree + 1
                        holeThreeShotThreeDistanceFromUser = holeThreeShotThreeDistanceFromUser - random.randint(8,11)
                        if holeThreeShotThreeDistanceFromUser >= 4:
                            print ('\nNice shot! You are ' + str(holeThreeShotThreeDistanceFromUser) + ' points away from the cup!')
                        # Creation of windmill fate decider. Determines if user will successfully make it through the windmill or not
                        # Only activates if player is within 3 points of the cup
                        elif holeThreeShotThreeDistanceFromUser <= 3:
                            windMillFateDecider = random.randint (1,4)
                            if windMillFateDecider == 1:
                                if holeThreeShotThreeDistanceFromUser == 0:
                                    print ('\nWhat a shot! You got a par!')
                                elif holeThreeShotThreeDistanceFromUser == 1:
                                    print ('\nNice! you made it past the windmill! You are ' + str(holeThreeShotThreeDistanceFromUser) + ' point away from the cup! Finish it off with "tap"')
                                elif holeThreeShotThreeDistanceFromUser > 1 and holeThreeShotThreeDistanceFromUser <= 3:
                                    print ('\nWell done! You made it past the windmill blades. You are ' + str(holeThreeShotThreeDistanceFromUser) + ' points away from the cup!')
                                # Fate decider activates if player shot goes below zero; chooses a randomized instance that gives the player a positive integer distance from the cup
                                elif holeThreeShotThreeDistanceFromUser < 0:
                                    fateDecider = random.randint (1,2)
                                    if fateDecider == 1:
                                        holeThreeShotThreeDistanceFromUser = 1
                                        print ('\nYou hit your ball off of the flagpole! You are ' + str(holeThreeShotThreeDistanceFromUser) + ' point away from the cup!')
                                    else:
                                        holeThreeShotThreeDistanceFromUser = random.randint (2,3)
                                        print ('\nOops! Your ball went past the cup! You are ' + str(holeThreeShotThreeDistanceFromUser) + ' points away from the cup!')
                            else:
                                holeThreeShotThreeDistanceFromUser = random.randint (4, 7)
                                print ("""\nAs you approach the tower, you realize it is a windmill and the moving parts were the arms for the fan.\nYou see your ball not far away. It must have bounced off part of the tower.""")
                                print ('\nYou judge the distance of your ball. You are ' + str(holeThreeShotThreeDistanceFromUser) + ' points away from the cup.')
                    elif wallopConfirmation == "no":
                        shotOptionHoleThreeShotThreeReshot = input('\nSelect your third shot ("tap", "putt", or "whack"): ')
                        shotOptionHoleThreeShotThree = shotOptionHoleThreeShotThreeReshot
                        userInputHoleThreeShotThree (shotOptionHoleThreeShotThree)
                    # Player must retake shot if invalid option is given
                    elif wallopConfirmation != 'yes' or 'no':
                        print ('\nYour choice was not a valid choice. You need to type "yes" or "no"')
                        shotOptionHoleThreeShotThree = input('\nPlease choose a shot option to restart the shot ("tap", "putt", "whack" or "wallop"): ')
                        userInputHoleThreeShotThree (shotOptionHoleThreeShotThree)
            # Normal function of wallop if far enough away from windmill
            else:
                strokeCounterHoleThree = strokeCounterHoleThree + 1
                holeThreeShotThreeDistanceFromUser = holeThreeShotThreeDistanceFromUser - random.randint(8,11)
                if holeThreeShotThreeDistanceFromUser >= 4:
                    print ('\nNice shot! You are ' + str(holeThreeShotThreeDistanceFromUser) + ' points away from the cup!')
        # Prompts player for valid input if they type an invalid shot command
        elif shotOptionHoleThreeShotThree != "tap" or 'putt' or 'whack' or 'wallop':
            shotOptionHoleThreeShotThree = input ('\nPlease choose a valid shot option; such as "tap", "putt", "whack" or "wallop and enter it here: ')
            userInputHoleThreeShotThree (shotOptionHoleThreeShotThree) 

    shotOptionHoleThreeShotThree = input('\nKeep going! Select your third shot ("tap", "putt", "whack", or "wallop"): ')
    userInputHoleThreeShotThree (shotOptionHoleThreeShotThree)
    # Checks player progress after third shot
    if holeThreeShotThreeDistanceFromUser == 0:
        print ('\nCongratulations! You completed the third hole in ' + str(strokeCounterHoleThree) + ' strokes!')
        input ('Press enter to continue')
    else:
        holeThreeShotFourDistanceFromUser = holeThreeShotThreeDistanceFromUser

        # Function for fourth shot
        def userInputHoleThreeShotFour (shotOptionHoleThreeShotFour):
            global strokeCounterHoleThree, holeThreeShotFourDistanceFromUser

            # Recommends to the player to not choose wallop if the ball is within 7 points of the cup
            if holeThreeShotFourDistanceFromUser <= 7:
                while shotOptionHoleThreeShotFour == "wallop":
                    print ('\nIt might be wiser to use a less powerful shot... \n')
                    shotOptionHoleThreeShotFour = input('Select your shot option ("tap", "putt", or "whack"): ')
            
            # Recommends to the player to not use whack if the ball is within 3 points of the cup
            if holeThreeShotFourDistanceFromUser <= 3:
                while shotOptionHoleThreeShotFour == "whack":
                    print ('\nIt might be wiser to use a less powerful shot... \n')
                    shotOptionHoleThreeShotFour = input('Select your shot option ("tap", or "putt",): ')
            
            # Conditions are more defined for tap on shot three
            if shotOptionHoleThreeShotFour == "tap":
                strokeCounterHoleThree = strokeCounterHoleThree + 1
                holeThreeShotFourDistanceFromUser = holeThreeShotFourDistanceFromUser - 1
                if holeThreeShotFourDistanceFromUser == 0:
                    print ('\nNice one! You got your ball in the cup!')
                elif holeThreeShotFourDistanceFromUser == 1:
                    print ( '\nYou are ' + str(holeThreeShotFourDistanceFromUser) + ' point away from the cup!')
                else:
                    print ( '\nYou are ' + str(holeThreeShotFourDistanceFromUser) + ' points away from the cup!')
            
            # Created more defined conditions for putt
            elif shotOptionHoleThreeShotFour == "putt":
                strokeCounterHoleThree = strokeCounterHoleThree + 1
                holeThreeShotFourDistanceFromUser = holeThreeShotFourDistanceFromUser - random.randint(2,3)
                if holeThreeShotFourDistanceFromUser == 0:
                    print ('\nNice one! You got your ball in the cup!')
                # Activates if player shot goes below zero; gives the player a positive integer distance from the cup
                elif holeThreeShotFourDistanceFromUser < 0:
                    holeThreeShotFourDistanceFromUser = 1
                    print ('\nJust missed the putt! You are ' + str(holeThreeShotFourDistanceFromUser) + ' point away from the cup! Finish it off with "tap"')
                else:
                    print ('\nYou are ' + str(holeThreeShotFourDistanceFromUser) + ' points away from the cup!')
                       
            # Allows use of whack if ball is not within 3 points of the cup
            elif shotOptionHoleThreeShotFour == "whack":
                if holeThreeShotFourDistanceFromUser <= 10:
                    if shotOptionHoleThreeShotFour == "whack":
                        print ("""\nA windmill has come into view, It might be wise to approach with caution.\nAre you sure you want to use the whack option?""")
                        whackConfirmation = input ('Type "yes" if you would like to proceed, or "no" to choose another shot option: ')
                        if whackConfirmation == "yes":
                            strokeCounterHoleThree = strokeCounterHoleThree + 1
                            holeThreeShotFourDistanceFromUser = holeThreeShotFourDistanceFromUser - random.randint(4,7)
                            if holeThreeShotFourDistanceFromUser >= 4:
                                print ('\nNice shot! You are ' + str(holeThreeShotFourDistanceFromUser) + ' points away from the cup!')
                            # Creation of windmill fate decider; Determines if user will successfully make it through the windmill or not
                            # Only activates if player is within within 3 points of the cup
                            elif holeThreeShotFourDistanceFromUser <= 3:
                                # 'windmill fate decider' easier to succeed for whack option compared to wallop option
                                windMillFateDecider = random.randint (1,2)
                                if windMillFateDecider == 1:
                                    if holeThreeShotFourDistanceFromUser == 0:
                                        print ('\nWhat a shot! You got your ball in the cup!')
                                    # Fate decider activates if player shot goes below zero; chooses a randomized instance that gives the player a positive integer distance from the cup
                                    elif holeThreeShotFourDistanceFromUser < 0:
                                        fateDecider = random.randint (1,2)
                                        if fateDecider == 1:
                                            holeThreeShotFourDistanceFromUser = 1
                                            print ('\nYou hit your ball off of the flagpole! You are ' + str(holeThreeShotFourDistanceFromUser) + ' point away from the cup! Finish it off with "tap"')
                                        else:
                                            holeThreeShotFourDistanceFromUser = random.randint (1,2)
                                            if holeThreeShotFourDistanceFromUser == 1:
                                                print('\nOops! Your ball went past the cup! You are ' + str(holeThreeShotFourDistanceFromUser) + ' point away from the cup! Finish it off with "tap"')
                                            else:
                                                print ('\nOops! Your ball went past the cup! You are ' + str(holeThreeShotFourDistanceFromUser) + ' points away from the cup!')
                                    elif holeThreeShotFourDistanceFromUser == 1:
                                        print ('\nNice shot! you made it past the windmill. Well done! You are ' + str(holeThreeShotFourDistanceFromUser) + ' point away from the cup! Finish it off with "tap"')
                                    # Elif statements directly above and below announce that you successfully passed the windmill
                                    elif holeThreeShotFourDistanceFromUser > 1 and holeThreeShotFourDistanceFromUser <= 3:
                                        print ('Well done! You made it past the windmill blades. You are ' + str(holeThreeShotFourDistanceFromUser) + ' points away from the cup!')
                                    # Fate decider activates if player shot goes below zero; chooses a randomized instance that gives the player a positive integer distance from the cup
                                    elif holeThreeShotFourDistanceFromUser < 0:
                                        fateDecider = random.randint (1,2)
                                        if fateDecider == 1:
                                            holeThreeShotFourDistanceFromUser = 1
                                            print ('Well done! You made it past the windmill! It looks like you hit your ball off of the flagpole!\n You are ' + str(holeThreeShotFourDistanceFromUser) + ' point away from the cup!')
                                        else:
                                            holeThreeShotFourDistanceFromUser = 2
                                            print ('Oops! Your ball went past the cup! You are ' + str(holeThreeShotFourDistanceFromUser) + ' points away from the cup!')
                                
                                else:
                                    holeThreeShotFourDistanceFromUser = random.randint (4, 5)
                                    print ("""\nIt looks like your ball hit part of the windmill.\nYou see your ball not far away. It must have bounced off part of the tower.\n""")
                                    print ('\nYou judge the distance of your ball. You are ' + str(holeThreeShotFourDistanceFromUser) + ' points away from the cup.')
                        elif whackConfirmation == "no":
                            shotOptionHoleThreeShotFourReshot = input('\nSelect your shot option ("tap", or "putt"): ')
                            shotOptionHoleThreeShotFour = shotOptionHoleThreeShotFourReshot
                            userInputHoleThreeShotFour (shotOptionHoleThreeShotFour)
                        # Player must reshoot if invalid choice is entered
                        elif whackConfirmation != 'yes' or 'no':
                            print ('\nYour choice was not a valid choice. You need to type "yes" or "no"')
                            shotOptionHoleThreeShotFour = input('\nPlease choose a shot option to restart the shot ("tap", "putt", "whack" or "wallop"): ')
                            userInputHoleThreeShotFour (shotOptionHoleThreeShotFour)
                # Allows for normal whack function if far enough away from windmill
                else:
                    strokeCounterHoleThree = strokeCounterHoleThree + 1
                    holeThreeShotFourDistanceFromUser = holeThreeShotFourDistanceFromUser - random.randint(4,7)
                    print ('\nYou are ' + str(holeThreeShotFourDistanceFromUser) + ' points away from the cup!')                           
                                                                                                                                        
            # allows use of wallop if not within 7 points of the cup
            elif shotOptionHoleThreeShotFour == "wallop":
                if holeThreeShotFourDistanceFromUser >= 8:
                    if shotOptionHoleThreeShotFour == "wallop":
                        print ("""\nA windmill has come into view. It might be wise to approach with caution.\nAre you sure you want to use the wallop option?""")
                        wallopConfirmation = input ('Type "yes" if you would like to proceed, or "no" to choose another shot option: ')
                        if wallopConfirmation == "yes":
                            strokeCounterHoleThree = strokeCounterHoleThree + 1
                            holeThreeShotFourDistanceFromUser = holeThreeShotFourDistanceFromUser - random.randint(8,11)
                            if holeThreeShotFourDistanceFromUser >= 4:
                                print ('\nNice shot! You are ' + str(holeThreeShotFourDistanceFromUser) + ' points away from the cup!')
                            # Creation of windmill fate decider. Determines if user will successfully make it through the windmill or not
                            # Only activates if player is within 3 points of the cup
                            elif holeThreeShotFourDistanceFromUser <= 3:
                                windMillFateDecider = random.randint (1,4)
                                if windMillFateDecider == 1:
                                    if holeThreeShotFourDistanceFromUser == 0:
                                        print ('\nNice shot! You got your ball in the cup!')
                                    elif holeThreeShotFourDistanceFromUser == 1:
                                        print ('\nNice! you made it past the windmill! You are ' + str(holeThreeShotFourDistanceFromUser) + ' point away from the cup! Finish it off with "tap"')
                                    elif holeThreeShotFourDistanceFromUser > 1 and holeThreeShotFourDistanceFromUser <= 3:
                                        print ('\nWell done! You made it past the windmill blades. You are ' + str(holeThreeShotFourDistanceFromUser) + ' points away from the cup!')
                                    # Fate decider activates if player shot goes below zero; chooses a randomized instance that gives the player a positive integer distance from the cup
                                    elif holeThreeShotFourDistanceFromUser < 0:
                                        fateDecider = random.randint (1,2)
                                        if fateDecider == 1:
                                            holeThreeShotFourDistanceFromUser = 1
                                            print ('\nYou hit your ball off of the flagpole! You are ' + str(holeThreeShotFourDistanceFromUser) + ' point away from the cup!')
                                        else:
                                            holeThreeShotFourDistanceFromUser = random.randint (2,3)
                                            print ('\nOops! Your ball went past the cup! You are ' + str(holeThreeShotFourDistanceFromUser) + ' points away from the cup!')
                                else:
                                    holeThreeShotFourDistanceFromUser = random.randint (4, 7)
                                    print ("""\nAs you approach the tower, you realize it is a windmill and the moving parts were the arms for the fan.\nYou see your ball not far away. It must have bounced off part of the tower.""")
                                    print ('\nYou judge the distance of your ball. You are ' + str(holeThreeShotFourDistanceFromUser) + ' points away from the cup.')
                        elif wallopConfirmation == "no":
                            shotOptionHoleThreeShotFourReshot = input('\nSelect your shot option ("tap", "putt", or "whack"): ')
                            shotOptionHoleThreeShotFour = shotOptionHoleThreeShotFourReshot
                            userInputHoleThreeShotFour (shotOptionHoleThreeShotFour)
                        # Player must retake shot if invalid option is given
                        elif wallopConfirmation != 'yes' or 'no':
                            print ('\nYour choice was not a valid choice. You need to type "yes" or "no"')
                            shotOptionHoleThreeShotFour = input('\nPlease choose a shot option to restart the shot ("tap", "putt", "whack" or "wallop"): ')
                            userInputHoleThreeShotFour (shotOptionHoleThreeShotFour)
                # Normal function of wallop if far enough away from windmill
                else:
                    strokeCounterHoleThree = strokeCounterHoleThree + 1
                    holeThreeShotFourDistanceFromUser = holeThreeShotFourDistanceFromUser - random.randint(8,11)
                    if holeThreeShotFourDistanceFromUser >= 4:
                        print ('\nNice shot! You are ' + str(holeThreeShotFourDistanceFromUser) + ' points away from the cup!')  
            
            # Prompts player for valid input if they type an invalid shot command
            elif shotOptionHoleThreeShotFour != "tap" or 'putt' or 'whack' or 'wallop':
                shotOptionHoleThreeShotFour = input ('\nPlease choose a valid shot option; such as "tap", "putt", "whack" or "wallop and enter it here: ')
                userInputHoleThreeShotFour (shotOptionHoleThreeShotFour) 

        shotOptionHoleThreeShotFour = input('\nKeep going! Select your fourth shot ("tap", "putt", "whack", or "wallop"): ')
        userInputHoleThreeShotFour (shotOptionHoleThreeShotFour)

        # Checks player progress on hole after fourth shot; if their ball is in the cup they're done. If not, they take their fifth and final shot
        if holeThreeShotFourDistanceFromUser == 0:
            print ('\nCongratulations! You completed the third hole in ' + str(strokeCounterHoleThree) + ' strokes!')
            input ('Press enter to continue')
        else:
            holeThreeShotFiveDistanceFromUser = holeThreeShotFourDistanceFromUser
            print ('\nFINAL SHOT!!!\n')

            # Function for final shot
            def userInputHoleThreeShotFive (shotOptionHoleThreeShotFive):
                global strokeCounterHoleThree, holeThreeShotFiveDistanceFromUser

                # Recommends to the player to not choose wallop if the ball is within 7 points of the cup
                if holeThreeShotFiveDistanceFromUser <= 7:
                    while shotOptionHoleThreeShotFive == "wallop":
                        print ('\nIt might be wiser to use a less powerful shot... \n')
                        shotOptionHoleThreeShotFive = input('Select your shot option ("tap", "putt", or "whack"): ')
                
                # Recommends to the player to not use whack if the ball is within 3 points of the cup
                if holeThreeShotFiveDistanceFromUser <= 3:
                    while shotOptionHoleThreeShotFive == "whack":
                        print ('\nIt might be wiser to use a less powerful shot... \n')
                        shotOptionHoleThreeShotFive = input('Select your shot option ("tap", or "putt",): ')
                
                # Conditions are more defined for tap on shot three
                if shotOptionHoleThreeShotFive == "tap":
                    strokeCounterHoleThree = strokeCounterHoleThree + 1
                    holeThreeShotFiveDistanceFromUser = holeThreeShotFiveDistanceFromUser - 1
                    if holeThreeShotFiveDistanceFromUser == 0:
                        print ('\nNice one! You got your ball in the cup!')
                    elif holeThreeShotFiveDistanceFromUser == 1:
                        print ( '\nYou are ' + str(holeThreeShotFiveDistanceFromUser) + ' point away from the cup!')
                    else:
                        print ( '\nYou are ' + str(holeThreeShotFiveDistanceFromUser) + ' points away from the cup!')
                
                # Created more defined conditions for putt
                elif shotOptionHoleThreeShotFive == "putt":
                    strokeCounterHoleThree = strokeCounterHoleThree + 1
                    holeThreeShotFiveDistanceFromUser = holeThreeShotFiveDistanceFromUser - random.randint(2,3)
                    if holeThreeShotFiveDistanceFromUser == 0:
                        print ('\nNice one! You got your ball in the cup!')
                    # Activates if player shot goes below zero; gives the player a positive integer distance from the cup
                    elif holeThreeShotFiveDistanceFromUser < 0:
                        holeThreeShotFiveDistanceFromUser = 1
                        print ('\nJust missed the putt! You are ' + str(holeThreeShotFiveDistanceFromUser) + ' point away from the cup! Finish it off with "tap"')
                    else:
                        print ('\nYou are ' + str(holeThreeShotFiveDistanceFromUser) + ' points away from the cup!')
                                                                       
                # Allows use of whack if ball is not within 3 points of the cup
                elif shotOptionHoleThreeShotFive == "whack":
                    if holeThreeShotFiveDistanceFromUser <= 10:
                        if shotOptionHoleThreeShotFive == "whack":
                            print ("""\nA windmill has come into view, It might be wise to approach with caution.\nAre you sure you want to use the whack option?""")
                            whackConfirmation = input ('Type "yes" if you would like to proceed, or "no" to choose another shot option: ')
                            if whackConfirmation == "yes":
                                strokeCounterHoleThree = strokeCounterHoleThree + 1
                                holeThreeShotFiveDistanceFromUser = holeThreeShotFiveDistanceFromUser - random.randint(4,7)
                                if holeThreeShotFiveDistanceFromUser >= 4:
                                    print ('\nNice shot! You are ' + str(holeThreeShotFiveDistanceFromUser) + ' points away from the cup!')
                                # Creation of windmill fate decider; Determines if user will successfully make it through the windmill or not
                                # Only activates if player is within within 3 points of the cup
                                elif holeThreeShotFiveDistanceFromUser <= 3:
                                    # 'windmill fate decider' easier to succeed for whack option compared to wallop option
                                    windMillFateDecider = random.randint (1,2)
                                    if windMillFateDecider == 1:
                                        if holeThreeShotFiveDistanceFromUser == 0:
                                            print ('\nWhat a shot! You got your ball in the cup!')
                                        # Fate decider activates if player shot goes below zero; chooses a randomized instance that gives the player a positive integer distance from the cup
                                        elif holeThreeShotFiveDistanceFromUser < 0:
                                            fateDecider = random.randint (1,2)
                                            if fateDecider == 1:
                                                holeThreeShotFiveDistanceFromUser = 1
                                                print ('\nYou hit your ball off of the flagpole! You are ' + str(holeThreeShotFiveDistanceFromUser) + ' point away from the cup! Finish it off with "tap"')
                                            else:
                                                holeThreeShotFiveDistanceFromUser = random.randint (1,2)
                                                if holeThreeShotFiveDistanceFromUser == 1:
                                                    print('\nOops! Your ball went past the cup! You are ' + str(holeThreeShotFiveDistanceFromUser) + ' point away from the cup! Finish it off with "tap"')
                                                else:
                                                    print ('\nOops! Your ball went past the cup! You are ' + str(holeThreeShotFiveDistanceFromUser) + ' points away from the cup!')
                                        elif holeThreeShotFiveDistanceFromUser == 1:
                                            print ('\nNice shot! you made it past the windmill. Well done! You are ' + str(holeThreeShotFiveDistanceFromUser) + ' point away from the cup! Finish it off with "tap"')
                                        # Elif statements directly above and below announce that you successfully passed the windmill
                                        elif holeThreeShotFiveDistanceFromUser > 1 and holeThreeShotFiveDistanceFromUser <= 3:
                                            print ('Well done! You made it past the windmill blades. You are ' + str(holeThreeShotFiveDistanceFromUser) + ' points away from the cup!')
                                        # Fate decider activates if player shot goes below zero; chooses a randomized instance that gives the player a positive integer distance from the cup
                                        elif holeThreeShotFiveDistanceFromUser < 0:
                                            fateDecider = random.randint (1,2)
                                            if fateDecider == 1:
                                                holeThreeShotFiveDistanceFromUser = 1
                                                print ('Well done! You made it past the windmill! It looks like you hit your ball off of the flagpole!\n You are ' + str(holeThreeShotFiveDistanceFromUser) + ' point away from the cup!')
                                            else:
                                                holeThreeShotFiveDistanceFromUser = 2
                                                print ('Oops! Your ball went past the cup! You are ' + str(holeThreeShotFiveDistanceFromUser) + ' points away from the cup!')
                                    else:
                                        holeThreeShotFiveDistanceFromUser = random.randint (4, 5)
                                        print ("""\nIt looks like your ball hit part of the windmill.\nYou see your ball not far away. It must have bounced off part of the tower.\n""")
                                        print ('\nYou judge the distance of your ball. You are ' + str(holeThreeShotFiveDistanceFromUser) + ' points away from the cup.')
                            elif whackConfirmation == "no":
                                shotOptionHoleThreeShotFiveReshot = input('\nSelect your shot option ("tap", or "putt"): ')
                                shotOptionHoleThreeShotFive = shotOptionHoleThreeShotFiveReshot
                                userInputHoleThreeShotFive (shotOptionHoleThreeShotFive)
                            # Player must reshoot if invalid choice is entered
                            elif whackConfirmation != 'yes' or 'no':
                                print ('\nYour choice was not a valid choice. You need to type "yes" or "no"')
                                shotOptionHoleThreeShotFive = input('\nPlease choose a shot option to restart the shot ("tap", "putt", "whack" or "wallop"): ')
                                userInputHoleThreeShotFive (shotOptionHoleThreeShotFive)
                    # Allows for normal whack function if far enough away from windmill
                    else:
                        strokeCounterHoleThree = strokeCounterHoleThree + 1
                        holeThreeShotFiveDistanceFromUser = holeThreeShotFiveDistanceFromUser - random.randint(4,7)
                        print ('\nYou are ' + str(holeThreeShotFiveDistanceFromUser) + ' points away from the cup!')
            
                # allows use of wallop if not within 7 points of the cup
                elif shotOptionHoleThreeShotFive == "wallop":
                    if holeThreeShotFiveDistanceFromUser >= 8:
                        if shotOptionHoleThreeShotFive == "wallop":
                            print ("""\nA windmill has come into view. It might be wise to approach with caution.\nAre you sure you want to use the wallop option?""")
                            wallopConfirmation = input ('Type "yes" if you would like to proceed, or "no" to choose another shot option: ')
                            if wallopConfirmation == "yes":
                                strokeCounterHoleThree = strokeCounterHoleThree + 1
                                holeThreeShotFiveDistanceFromUser = holeThreeShotFiveDistanceFromUser - random.randint(8,11)
                                if holeThreeShotFiveDistanceFromUser >= 4:
                                    print ('\nNice shot! You are ' + str(holeThreeShotFiveDistanceFromUser) + ' points away from the cup!')
                                # Creation of windmill fate decider. Determines if user will successfully make it through the windmill or not
                                # Only activates if player is within 3 points of the cup
                                elif holeThreeShotFiveDistanceFromUser <= 3:
                                    windMillFateDecider = random.randint (1,4)
                                    if windMillFateDecider == 1:
                                        if holeThreeShotFiveDistanceFromUser == 0:
                                            print ('\nNice shot! You got your ball in the cup!')
                                        elif holeThreeShotFiveDistanceFromUser == 1:
                                            print ('\nNice! you made it past the windmill! You are ' + str(holeThreeShotFiveDistanceFromUser) + ' point away from the cup! Finish it off with "tap"')
                                        elif holeThreeShotFiveDistanceFromUser > 1 and holeThreeShotFiveDistanceFromUser <= 3:
                                            print ('\nWell done! You made it past the windmill blades. You are ' + str(holeThreeShotFiveDistanceFromUser) + ' points away from the cup!')
                                        # Fate decider activates if player shot goes below zero; chooses a randomized instance that gives the player a positive integer distance from the cup
                                        elif holeThreeShotFiveDistanceFromUser < 0:
                                            fateDecider = random.randint (1,2)
                                            if fateDecider == 1:
                                                holeThreeShotFiveDistanceFromUser = 1
                                                print ('\nYou hit your ball off of the flagpole! You are ' + str(holeThreeShotFiveDistanceFromUser) + ' point away from the cup!')
                                            else:
                                                holeThreeShotFiveDistanceFromUser = random.randint (2,3)
                                                print ('\nOops! Your ball went past the cup! You are ' + str(holeThreeShotFiveDistanceFromUser) + ' points away from the cup!')
                                    else:
                                        holeThreeShotFiveDistanceFromUser = random.randint (4, 7)
                                        print ("""\nAs you approach the tower, you realize it is a windmill and the moving parts were the arms for the fan.\nYou see your ball not far away. It must have bounced off part of the tower.""")
                                        print ('\nYou judge the distance of your ball. You are ' + str(holeThreeShotFiveDistanceFromUser) + ' points away from the cup.')
                            elif wallopConfirmation == "no":
                                shotOptionHoleThreeShotFiveReshot = input('\nSelect your shot option ("tap", "putt", or "whack"): ')
                                shotOptionHoleThreeShotFive = shotOptionHoleThreeShotFiveReshot
                                userInputHoleThreeShotFive (shotOptionHoleThreeShotFive)
                            # Player must retake shot if invalid option is given
                            elif wallopConfirmation != 'yes' or 'no':
                                print ('\nYour choice was not a valid choice. You need to type "yes" or "no"')
                                shotOptionHoleThreeShotFive = input('\nPlease choose a shot option to restart the shot ("tap", "putt", "whack" or "wallop"): ')
                                userInputHoleThreeShotFive (shotOptionHoleThreeShotFive)
                    # Normal function of wallop if far enough away from windmill
                    else:
                        strokeCounterHoleThree = strokeCounterHoleThree + 1
                        holeThreeShotFiveDistanceFromUser = holeThreeShotFiveDistanceFromUser - random.randint(8,11)
                        if holeThreeShotFiveDistanceFromUser >= 4:
                            print ('\nNice shot! You are ' + str(holeThreeShotFiveDistanceFromUser) + ' points away from the cup!')
                
                # Prompts player for valid input if they type an invalid shot command
                elif shotOptionHoleThreeShotFive != "tap" or 'putt' or 'whack' or 'wallop':
                    shotOptionHoleThreeShotFive = input ('\nPlease choose a valid shot option; such as "tap", "putt", "whack" or "wallop and enter it here: ')
                    userInputHoleThreeShotFive (shotOptionHoleThreeShotFive)     

            shotOptionHoleThreeShotFive = input('\nKeep going! Select your final shot ("tap", "putt", "whack", or "wallop"): ')
            userInputHoleThreeShotFive (shotOptionHoleThreeShotFive)

        # Checks player progress after final shot chance
        # If they did not get the ball in the cup, the hole is completed for them and they receive an additional stroke
            if holeThreeShotFiveDistanceFromUser == 0:
                print ('\nCongratulations! You completed the third hole in ' + str(strokeCounterHoleThree) + ' strokes!')
                input ('Press enter to continue. ')
            else:
                strokeCounterHoleThree = strokeCounterHoleThree + 1
                print ('\nShucks, close but no cigar. This hole will be completed for you, and a stroke will be added to your stroke total')
                print ('\nyou completed the third hole in ' + str(strokeCounterHoleThree) + ' strokes!')
                input ('Press enter to continue. ')
                
print ('\nWell done!!! You have completed the three courses for Minigolf!\n\nYour record for each hole is as follows:')
input ('Press enter to get results for each hole. \n')

# Uses for in range loop to give the player stroke totals for each hole
# 'hole' variable is used to determine which hole on the course is being evaluated
# 'hole' variable then slices from 'strokeTotalPerHole' list for each course total contained within the 'strokeCounter' variables
strokeTotalPerHole = [strokeCounterHoleOne, strokeCounterHoleTwo, strokeCounterHoleThree]
for hole in range(3):
    print ('Hole ' + str(hole + 1) + ': ' + str(strokeTotalPerHole[hole]) + ' stroke(s)')

# Let's the player know how many shots it took to complete the game 
strokeFinalTotal = strokeCounterHoleOne + strokeCounterHoleTwo + strokeCounterHoleThree
print ('Great job! You completed the game in ' + str(strokeFinalTotal) + ' strokes!')   

# Creates completion info for players that finish the game and uses a function (gameFinishFile) to put the info into a text document
# player name is stored, along with stroke count for each hole and their overall total
# Text document is then called and displayed to player to review other players' results
gameFinishInfo = ('Your Game completion stats: '+userName+'\nHole One: '+str(strokeTotalPerHole[0])+'\nHole Two: '+str(strokeTotalPerHole[1])+'\nHole Three: '+str(strokeTotalPerHole[2])+'\nStroke total: '+str(strokeFinalTotal)+'\n\n')

# Function will append game results to 'Game stats' folder
# if 'Game stats' and associated folders do not exist, they are created and written to
def gameFinishFile ():
    global gameFinishInfo
    try:
        gameFinishStats = open ('c:\\Python files\\Minigolf\\Game stats.txt', 'a')
        gameFinishStats.write (gameFinishInfo)
        gameFinishStats.close ()
    except FileNotFoundError:
        if (os.path.exists ('c:\\Python files\\Minigolf') == False):
            os.makedirs ('c:\\Python files\\Minigolf')
            gameFinishStats = open ('c:\\Python files\\Minigolf\\Game stats.txt', 'w')
            gameFinishStats.write (gameFinishInfo)
            gameFinishStats.close () 

    finally:
        print ('\nSplendiferous! Your game record is stored!')

# Prompts player to call 'gameFinishFile' function
input ("""\nPress enter to post your results in the game completion sheet!
\nThis will allow you to share your results for other players to see, and check your past results against new ones.\nGo ahead and press enter!""")
gameFinishFile ()

# Presents player with results from past players, and says goodbye afterwards
input ('\nBefore you go, why not take a look at the record sheet so far?\nPress enter to open the record.\n')

resultsPage = open ('c:\\Python files\\Minigolf\\Game stats.txt')
resultsPageContent = resultsPage.read ()
resultsPage.close ()
print (resultsPageContent)
# End of game message
print ("That's it, that's all! Thanks for playing, " + (userName) + "!")