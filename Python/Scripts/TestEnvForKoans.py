# Function for testing how iterators work
def testing_iterators():
    it = iter(range(1,6))
    
    total = 0
    
    for num in it:
        total += num
        print(total)

# Uncomment the following line to activate function
#testing_iterators()