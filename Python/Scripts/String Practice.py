print('please enter a single word')
firstWord= input()
print('please enter a second single word')
secondWord= input ()
print ('please enter a number')
numberOne= input()
print ('the number you entered multiplied by 100 is ' + str(int(numberOne)*100))
print ('the total number of input elements is ' + str(len(firstWord) + len(secondWord) + len(numberOne)))
print ('The first word you entered will be repeated by your chosen number ' + (firstWord * int(numberOne)))