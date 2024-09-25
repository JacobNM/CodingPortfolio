class TypicalObject:
    pass

def test_calling_undefined_functions_normally_results_in_errors():
    typical = TypicalObject()
    
    try:
        print(typical.foobar())
    except AttributeError as ex:
        print(f"{AttributeError.__name__} has been raised. {ex}")

# Remove hash below to activate function
#test_calling_undefined_functions_normally_results_in_errors()
