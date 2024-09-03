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