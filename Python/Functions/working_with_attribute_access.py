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

def test_calling_getattribute_causes_an_attribute_error():
    typical = TypicalObject()
    
    try:
        print(typical.__getattribute__('foobar'))
    except AttributeError as ex:
        print(f"{AttributeError.__name__} has been raised. {ex}")

# If the method __getattribute__() causes the AttributeError, then
# what would happen if we redefine __getattribute__()?

# Remove hash below to activate function
#test_calling_getattribute_causes_an_attribute_error()

# ------------------------------------------------------------------

class CatchAllAttributeReads:
    def __getattribute__(self, attr_name):
        return f"Someone called '{attr_name}' and it could not be found"

def test_all_attribute_reads_are_caught():
    catcher = CatchAllAttributeReads()
    print(catcher.foobar)

# Remove hash below to activate function
#test_all_attribute_reads_are_caught()

def test_intercepting_return_values_can_disrupt_the_call_chain():
    catcher = CatchAllAttributeReads()
    print(catcher.foobaz)
    
    try:
        print(catcher.foobaz(1))
    except TypeError as ex:
        print(f"{TypeError.__name__} has been raised. {ex}")

    # foobaz returns a string. What happens to the '(1)' part?
    # Try entering this into a python console to reproduce the issue:
    #
    #     "foobaz"(1)

# Remove hash below to activate function
#test_intercepting_return_values_can_disrupt_the_call_chain()

