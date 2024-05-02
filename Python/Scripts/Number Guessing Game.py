# Asks the user to enter a number between 1 and 9 until they guess the right number
# proves error handling for incorrect inputs by user
# Script ends once user guesses the right number.
# Script provides the user with the number of attempts they needed to guess the number

import random

number = random.randint(1, 9)
numberOfGuesses = 0
while True:
	while True:
		try:
			guess = int(input("Guess a number between 1 and 9: "))
			if guess >= 1 and guess <= 9:
				break
			else:
				print("Your input must be a number between 1 and 9 inclusive")
		except ValueError:
			print("You must enter a number")
	numberOfGuesses += 1
	if guess == number:
		break
print(f"You needed {numberOfGuesses} guesses to guess the number {number}")