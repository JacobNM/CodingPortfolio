# Function for testing how iterators work
def testing_iterators():
    it = iter(range(1,6))
    
    total = 0
    
    for num in it:
        total += num
        print(total)

# Uncomment the following line to activate function
#testing_iterators()

def add_ten(item):
        return item + 10

def map_transforms_elements_of_a_list():
    seq = [1, 2, 3]
    mapped_seq = list()

    mapping = map(add_ten, seq)

    if list == mapping.__class__:
        print(f"True. mapping_class is a {mapping.__class__}")
    else:
        print(f"False. mapping_class is a {mapping.__class__}")
    # In Python 3 built in iterator funcs return iterable view objects
    # instead of lists

    for item in mapping:
        mapped_seq.append(item)
    print(mapped_seq)
       
# Uncomment the following line to activate function
#test_map_transforms_elements_of_a_list()


def filter_even_numbers_from_a_list():
    
    def is_even(item):
        return (item % 2) == 0

    seq = [1, 2, 3, 4, 5, 6]
    even_numbers = list()

    for item in filter(is_even, seq):
        even_numbers.append(item)
    print(even_numbers)

# Uncomment following line to activate func
#filter_even_numbers_from_a_list()
    
def is_odd(item):
    return (item % 2) != 0

def filter_odd_numbers_from_a_list():    
    seq = [1, 2, 3, 4, 5, 6]
    odd_numbers = list()
    
    for item in filter(is_odd, seq):
        odd_numbers.append(item)
    print(odd_numbers)

# Uncomment following line to activate func
#filter_odd_numbers_from_a_list()

def filter_returns_words_bigger_than_four_chars():
    def is_big_name(item):
            return len(item) > 4

    names = ["Jim", "Bill", "Clarence", "Doug", "Eli", "Elizabeth"]
    iterator = filter(is_big_name, names)

    print(f"{next(iterator)}")
    print(f"{next(iterator)}")

    try:
        next(iterator)
        pass
    except StopIteration:
        msg = 'Ran out of big names'

# Uncomment following line to activate func        
#filter_returns_words_bigger_than_four_chars()