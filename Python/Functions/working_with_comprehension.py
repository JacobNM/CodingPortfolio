def test_creating_lists_with_list_comprehensions():
    feast = ['lambs', 'sloths', 'orangutans', 'breakfast cereals',
        'fruit bats']

    comprehension = [delicacy.capitalize() for delicacy in feast]

    print(comprehension[0])
    print(comprehension[2])

# Remove hash below to test
#test_creating_lists_with_list_comprehensions()

def test_filtering_lists_with_list_comprehensions():
    feast = ['spam', 'sloths', 'orangutans', 'breakfast cereals',
        'fruit bats']

    comprehension = [delicacy for delicacy in feast if len(delicacy) > 6]

    print(f"There are {(len(feast))} items in the feast list. These items are:")
    print(feast)
    print(f"There are {(len(comprehension))} items in the comprehension list. These items are:")
    print(comprehension)

# Remove hash below to test
#test_filtering_lists_with_list_comprehensions()

def test_unpacking_tuples_in_list_comprehensions():
    list_of_tuples = [(1, 'lumberjack'), (2, 'inquisition'), (4, 'spam')]
    comprehension = [skit.capitalize() for number, skit in list_of_tuples ]

    print(f"{(comprehension[0])} is number {list_of_tuples[0][0]} in the list of tuples.")
    print(f"{(comprehension[2])} is number {list_of_tuples[2][0]} in the list of tuples.")

# Remove hash below to test
#test_unpacking_tuples_in_list_comprehensions()

def test_double_list_comprehension():
    list_of_eggs = ['poached egg', 'fried egg']
    list_of_meats = ['lite spam', 'ham spam', 'fried spam']

    comprehension = [ '{0} and {1}'.format(egg, meat) for egg in list_of_eggs for meat in list_of_meats]

    print(f"\nThere are {(len(comprehension))} items in the comprehension list. These items are:")
    print(f"\t- {(comprehension[0])}")
    print(f"\t- {(comprehension[1])}")
    print(f"\t- {(comprehension[2])}")
    print(f"\t- {(comprehension[3])}")
    print(f"\t- {(comprehension[4])}")
    print(f"\t- {(comprehension[5])}")

# Remove hash below to test
#test_double_list_comprehension()

def test_creating_a_set_with_set_comprehension():
    comprehension = { x for x in 'aabbbcccc'}

    print(comprehension)  # remember that set members are unique

# Remove hash below to test
#˚test_creating_a_set_with_set_comprehension()

def test_creating_a_dictionary_with_dictionary_comprehension():
    dict_of_weapons = {'first': 'fear', 'second': 'surprise',
                        'third':'ruthless efficiency', 'fourth':'fanatical devotion',
                        'fifth': None}

    dict_comprehension = { k.upper(): weapon for k, weapon in dict_of_weapons.items() if weapon}

    print(f"\nThere are {(len(dict_of_weapons))} items in the dict_of_weapons dictionary. These items are:")
    print(f"\t- {(dict_of_weapons['first'])}")
    print(f"\t- {(dict_of_weapons['second'])}")
    print(f"\t- {(dict_of_weapons['third'])}")
    print(f"\t- {(dict_of_weapons['fourth'])}")
    print(f"\t- {(dict_of_weapons['fifth'])}")
    
    print(f"\nThere are {(len(dict_comprehension))} items in the dict_comprehension dictionary. These items are:")
    print(f"\t- {(dict_comprehension['FIRST'])}")
    print(f"\t- {(dict_comprehension['SECOND'])}")
    print(f"\t- {(dict_comprehension['THIRD'])}")
    print(f"\t- {(dict_comprehension['FOURTH'])}")
    
# Remove hash below to test
test_creating_a_dictionary_with_dictionary_comprehension()

