def test_generating_values_on_the_fly():
    result = list()
    bacon_generator = (n + ' bacon' for n in ['crunchy','veggie','danish'])

    for bacon in bacon_generator:
        result.append(bacon)

    print(f"\n{(len(result))} bacon products were generated on the fly. These items are:")
    print(f"\t- {result[0]}")
    print(f"\t- {result[1]}")
    print(f"\t- {result[2]}")
    
    print(f"\nThis is the format of the list:\n{result}")
    
# Remove hash below to test
#test_generating_values_on_the_fly()

def test_generators_are_different_to_list_comprehensions():
    num_list = [x*2 for x in range(1,3)]
    num_generator = (x*2 for x in range(1,3))

    print(f"\nList comprehension: {num_list}")
    print(num_list[0])
    print(num_list[1])
    
    # num_generator can only be iterated through once
    print(f"\nGenerator comprehension: {(list(num_generator))}")

    # This second call will fail to generate the numbers. The generator is a one-shot deal
    print(f"\nGenerator comprehension: {(list(num_generator))}")        

    # Both list comprehensions and generators can be iterated though. However, a generator
    # function is only called on the first iteration. The values are generated on the fly
    # instead of stored.

    # Generators are more memory friendly, but less versatile

# Remove hash below to test
#test_generators_are_different_to_list_comprehensions()

def test_generator_expressions_are_a_one_shot_deal():
    dynamite = ('Boom!' for n in range(3))

    attempt1 = list(dynamite)
    attempt2 = list(dynamite)

    print(attempt1)
    print(attempt2)

# Remove hash below to test
#test_generator_expressions_are_a_one_shot_deal()

# ------------------------------------------------------------------

def simple_generator_method():
    yield 'peanut'
    yield 'butter'
    yield 'and'
    yield 'jelly'
    
def test_generator_method_will_yield_values_during_iteration():
    result = list()
    for item in simple_generator_method():
        result.append(item)
    print(f"\n{result}")

# Remove hash below to test
#test_generator_method_will_yield_values_during_iteration()

def test_generators_can_be_manually_iterated_and_closed():
    result = simple_generator_method()
    print(next(result))
    print(next(result))
    print(next(result))
    print(next(result))
    result.close()

# Remove hash below to test
#test_generators_can_be_manually_iterated_and_closed()

# ------------------------------------------------------------------

def square_me(seq):
    for x in seq:
        yield x * x

def test_generator_method_with_parameter():
    result = square_me(range(2,5))
    print(list(result))

# Remove hash below to test
#test_generator_method_with_parameter()

# ------------------------------------------------------------------

def sum_it(seq):
    value = 0
    for num in seq:
        # The local state of 'value' will be retained between iterations
        value += num
        yield value

def test_generator_keeps_track_of_local_variables():
    result = sum_it(range(2,5))
    print(list(result))

# Remove hash below to test
#test_generator_keeps_track_of_local_variables()

# ------------------------------------------------------------------

def coroutine():
    result = yield
    yield result
    
def test_generators_can_act_as_coroutines():
    generator = coroutine()
    next(generator)
    print(generator.send(1 + 2))

# Remove hash below to test
#test_generators_can_act_as_coroutines()

def test_before_sending_a_value_to_a_generator_next_must_be_called():
    generator = coroutine()

    try:
        # Uncomment the line below to deactivate the exception
        #next(generator)
        print(generator.send(1 + 2))
    except TypeError as ex:
        ex.args[0], "can't send non-None value to a just-started generator"
        print(ex)

# Remove hash below to test
#test_before_sending_a_value_to_a_generator_next_must_be_called()

# ------------------------------------------------------------------

def yield_tester():
    value = yield
    if value:
        yield value
    else:
        yield 'no value'

def test_generators_can_see_if_they_have_been_called_with_a_value():
    generator = yield_tester()
    next(generator)
    print(generator.send('with value'))

    generator2 = yield_tester()
    next(generator2)
    print(next(generator2))

# Remove hash below to test
#test_generators_can_see_if_they_have_been_called_with_a_value()

def test_send_none_is_equivalent_to_next():
    generator = yield_tester()

    next(generator)
    # 'next(generator)' is exactly equivalent to 'generator.send(None)'
    print(generator.send(None))
    
# Remove hash below to test
#test_send_none_is_equivalent_to_next()