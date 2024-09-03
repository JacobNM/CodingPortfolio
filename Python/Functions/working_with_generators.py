def test_generating_values_on_the_fly():
    result = list()
    bacon_generator = (n + ' bacon' for n in ['crunchy','veggie','danish'])

    for bacon in bacon_generator:
        result.append(bacon)

    print(f"\n{(len(result))} bacon products were generated on the fly. These items are:")
    print(f"\t- {result[0]}")
    print(f"\t- {result[1]}")
    print(f"\t- {result[2]}")
    
# Remove hash below to test
#test_generating_values_on_the_fly()

