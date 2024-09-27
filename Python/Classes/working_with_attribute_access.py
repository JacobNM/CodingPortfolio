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

def test_changes_to_the_getattribute_implementation_affects_getattr_function():
    catcher = CatchAllAttributeReads()
    print(getattr(catcher, 'any_attribute'))

# Remove hash below to activate function
#test_changes_to_the_getattribute_implementation_affects_getattr_function()

# ------------------------------------------------------------------

class WellBehavedFooCatcher:
    def __getattribute__(self, attr_name):
        if attr_name[:3] == "foo":
            return f"Foo to you too {attr_name}"
        else:
            return super().__getattribute__(attr_name)

def test_foo_attributes_are_caught():
    catcher = WellBehavedFooCatcher()
    print(catcher.foo)
    print(catcher.foobar)
    print(catcher.foobaz)

# Remove hash below to activate function
#test_foo_attributes_are_caught()

def test_non_foo_attributes_are_treated_normally():
    catcher = WellBehavedFooCatcher()
    try:
        print(catcher.normal_undefined_attribute)
    except AttributeError as ex:
        print(f"\n{AttributeError.__name__} has been raised. {ex}")
    

# Remove hash below to activate function
#test_non_foo_attributes_are_treated_normally()

# ------------------------------------------------------------------

global stack_depth
stack_depth = 0

class RecursiveCatcher:
    def __init__(self):
        global stack_depth
        stack_depth = 0
        self.no_of_getattribute_calls = 0
        
    def __getattribute__(self, attr_name):
        global stack_depth
        stack_depth += 1
        
        if stack_depth <=10: # Prevent stack overflow
            self.no_of_getattribute_calls += 1
            # This will cause a recursion error
            #print(self.no_of_getattribute_calls())
            #print(self.__getattribute__(attr_name))
            #return self.__getattribute__(attr_name)
        
        # Use object instead of super() to avoid recursion error
        #return super().__getattribute__(self,attr_name)
        return object.__getattribute__(self, attr_name)
    
    def my_test_method(self):
        pass
    
def test_getattribute_is_a_bit_overzealous_sometimes():
    catcher = RecursiveCatcher()
    catcher.my_test_method()
    global stack_depth
    print(stack_depth)
    print(catcher.no_of_getattribute_calls)

# Remove hash below to activate function
#test_getattribute_is_a_bit_overzealous_sometimes()
 
# ------------------------------------------------------------------

class MinimalCatcher:
    class DuffObject:
        pass
    
    def __init__(self):
        self.no_of_getattribute_calls = 0
        self._name = None
        self._attributes = []
        
    def __getattr__(self, attr_name):
        self.no_of_getattribute_calls += 1
        self._attributes.append(attr_name)
        return self.DuffObject
    
    def get_name(self):
        return self._name

    def my_test_method(self):
        pass

def test_getattr_ignores_known_attributes():
    catcher = MinimalCatcher()
    catcher.my_test_method()
    print(catcher.no_of_getattribute_calls)
    
# Remove hash below to activate function
#test_getattr_ignores_known_attributes()

def test_getattr_only_catches_unknown_attributes():
    catcher = MinimalCatcher()
    
    # Create new attributes
    catcher.purple_flamingos()
    catcher.pink_flamingos()
    catcher.blue_flamingos()
    catcher.yellow_hippos()

    # prints the type of the new attribute, produced from the __getattr__ method
    # Also creates a new attribute 
    #print(type(catcher.give_me_duff_or_give_me_death()))

    # Detects any new attributes created
    if catcher.no_of_getattribute_calls > 0:
        print(f"\n{catcher.no_of_getattribute_calls} new attributes have been detected. They are as follows:\n")
    
    new_attribute_count = 0
    # for each new attribute, print the name of each with its getattribute call count number
    while catcher.no_of_getattribute_calls > 0:
        attr_name = catcher._attributes[new_attribute_count]
        print(f"{new_attribute_count + 1} - {attr_name}")
        catcher.no_of_getattribute_calls -= 1
        new_attribute_count += 1

# Remove hash below to activate function
#test_getattr_only_catches_unknown_attributes()

# ------------------------------------------------------------------

class PossessiveSetter(object):
    # Register attributes in the class
    def __init__(self):
        self.my_comics = []
        self.my_pies = []
        self.my_other_attributes = []
    
    # Intercept attribute assignments
    def __setattr__(self, attr_name, value):
        # Create new attribute names
        if attr_name[-5:] == 'comic':
            # If not already created, create my_comics list
            if not hasattr(self, 'my_comics'):
                # Set my_comics to an empty list
                self.my_comics = []
                # Add the comic(s) to the list
            self.my_comics.append(value)
            
        # If the attribute is a pie, add it to the my_pies list
        elif attr_name[-3:] == 'pie':
            if not hasattr(self, 'my_pies'):
                self.my_pies = []
            self.my_pies.append(value)
        
        # If the attribute is not a comic or pie, add it to the my_other_attributes list
        elif attr_name not in ['my_comics', 'my_pies', 'my_other_attributes']:
            # If my_other_attributes does not exist, create it
            if not hasattr(self, 'my_other_attributes'):
                # Set my_other_attributes to an empty list
                self.my_other_attributes = []
            # Add the attribute(s) to the list
            self.my_other_attributes.append(value)
        
        # If the attribute is a comic, pie, or other attribute, set the attribute
        else:
            object.__setattr__(self, attr_name, value)

def test_setattr_intercepts_attribute_assignments():
    # Create an instance of the PossessiveSetter class
    fanboy = PossessiveSetter()
    # Assign values to the comic attribute
    fanboy.comic = 'The Laminator, issue #1'
    # Assign values to the pie attribute
    fanboy.pie = 'apple'
    # Assign values to the sandwich attribute
    fanboy.sandwich = 'ham and cheese'
    # Assign another value to the comic attribute
    fanboy.comic = 'The Laminator, issue #2'
    # Assign another value to the pie attribute
    fanboy.pie = 'blueberry'
    # Assign another value to the sandwich attribute
    fanboy.sandwich = 'turkey and swiss'

    # Print the dictionary of the fanboy object
    print(fanboy.__dict__)
    
    # Remove hashes below to print the lists of the fanboy object
    #print(fanboy.my_comics)
    #print(fanboy.my_pies)
    #print(fanboy.my_other_attributes)

# Remove hash below to activate function
#test_setattr_intercepts_attribute_assignments()

# ------------------------------------------------------------------
# Class inspired by the PossessiveSetter class
class NewAttributeSetter(object):
    # Register new attributes in the class when a new attribute is created
    def __setattr__(self, attr_name, value):
        new_attr_name = attr_name
        # If the attribute already exists, append the new value to the list
        if hasattr(self, new_attr_name):
            # Get the current value of the attribute
            current_value = getattr(self, new_attr_name)
            # If the current value is a list, append the new value to the list
            if isinstance(current_value, list):
                current_value.append(value)
            else:
                # If the current value is not a list, create a list with the current value and the new value
                setattr(self, new_attr_name, [current_value, value])
            # Return to retain the values stored in each attribute
            return
        else:
            # Value is not a list, so create a list with the value
            value = [value]
        # Set the attribute to the value
        object.__setattr__(self, attr_name, value)

def test_setattr_adds_new_attributes_to_dict():
    fanboy = NewAttributeSetter()

    fanboy.comics = 'The Laminator, issue #1'
    fanboy.pies = 'apple'
    fanboy.sandwiches = 'ham and cheese'
    fanboy.comics = 'The Laminator, issue #2'
    fanboy.pies = 'blueberry'
    fanboy.sandwiches = 'turkey and swiss'

    print(fanboy.__dict__)
    
# Remove hash below to activate function
#test_setattr_adds_new_attributes_to_dict()

# ------------------------------------------------------------------

class ScarySetter:
    def __init__(self):
        self.num_of_coconuts = 9
        self._num_of_private_coconuts = 2
    
    def __setattr__(self, attr_name, value):
        new_attr_name =  attr_name
        
        if attr_name[0] != '_':
            new_attr_name = "altered_" + new_attr_name
            
        object.__setattr__(self, new_attr_name, value)
        
def test_it_modifies_external_attribute_as_expected():
    setter = ScarySetter()
    setter.e = "mc hammer"
    print(setter.altered_e)
    
    print(setter.__dict__)
    
# Remove hash below to activate function
#test_it_modifies_external_attribute_as_expected()

def test_it_mangles_some_internal_attributes():
    setter = ScarySetter()
    
    try:
        coconuts = setter.num_of_coconuts
        print(coconuts)
    except AttributeError as ex:
        print(f"\n{AttributeError.__name__} has been raised. {ex}.")
        coconuts = setter.altered_num_of_coconuts
        print(f"\n{coconuts} is the value for the new attribute, 'altered_num_of_coconuts'.")
    
# Remove hash below to activate function
#test_it_mangles_some_internal_attributes()

def test_in_this_case_private_attributes_are_not_mangled():
    setter = ScarySetter()
    
    coconuts = setter._num_of_private_coconuts
    print(f"{coconuts} is the value for the private attribute, '_num_of_private_coconuts'.")
    
# Remove hash below to activate function
#test_in_this_case_private_attributes_are_not_mangled()