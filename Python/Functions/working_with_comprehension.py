def test_creating_lists_with_list_comprehensions():
    feast = ['lambs', 'sloths', 'orangutans', 'breakfast cereals',
        'fruit bats']

    comprehension = [delicacy.capitalize() for delicacy in feast]

    print(comprehension[0])
    print(comprehension[2])

# Remove comment below to test
#test_creating_lists_with_list_comprehensions()

